import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { defineString } from "firebase-functions/params";
import { cleanupPing } from "./pingCleanup";

const adminEmails = defineString("ADMIN_EMAILS", {
  default: "",
  description: "Comma-separated list of admin email addresses",
});

export const removeContent = onCall({ region: "europe-west3" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const db = getFirestore();

  // Verify caller is admin
  const callerDoc = await db.collection("users").doc(uid).get();
  const callerEmail = callerDoc.data()?.email;

  const allowedEmails = adminEmails
    .value()
    .split(",")
    .map((e: string) => e.trim());

  if (!callerEmail || !allowedEmails.includes(callerEmail)) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const { targetType, targetId, reason } = request.data;

  if (!targetType || !targetId) {
    throw new HttpsError(
      "invalid-argument",
      "targetType and targetId are required."
    );
  }

  try {
    switch (targetType) {
    case "ping": {
      const pingRef = db.collection("pings").doc(targetId);
      const pingDoc = await pingRef.get();
      if (!pingDoc.exists) {
        throw new HttpsError("not-found", "Ping not found.");
      }

      await cleanupPing(db, pingDoc, { status: "removed" });
      break;
    }

    case "message": {
      await db.collection("chatMessages").doc(targetId).delete();
      break;
    }

    case "user": {
      await db.collection("users").doc(targetId).update({
        suspensionStatus: "suspended",
        suspensionExpiresAt: new Date(
          Date.now() + 24 * 60 * 60 * 1000
        ), // 24hr default
      });
      break;
    }

    default:
      throw new HttpsError(
        "invalid-argument",
        `Unknown targetType: ${targetType}`
      );
    }

    // Create audit trail
    await db.collection("moderationActions").add({
      moderatorId: uid,
      targetType,
      targetId,
      action: "emergency_removal",
      reason: reason || "No reason provided",
      timestamp: new Date(),
    });

    return { success: true, targetType, targetId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error("Content removal failed:", error);
    throw new HttpsError("internal", "Failed to remove content.");
  }
});
