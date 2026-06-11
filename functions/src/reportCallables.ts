import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

type CallableData = Record<string, unknown>;

const allowedTargetTypes = new Set(["ping", "message", "user"]);
const allowedReasons = new Set([
  "Spam",
  "Harassment",
  "Inappropriate Content",
  "Other",
]);

function requireAuthUid(request: { auth?: { uid?: string } }): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  return uid;
}

function requireData(data: unknown): CallableData {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Request data is required.");
  }
  return data as CallableData;
}

function requireString(data: CallableData, key: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${key} is required.`);
  }
  const trimmed = value.trim();
  if (trimmed.includes("/")) {
    throw new HttpsError("invalid-argument", `${key} cannot contain '/'.`);
  }
  return trimmed;
}

function optionalString(data: CallableData, key: string): string | undefined {
  const value = data[key];
  if (value === undefined || value === null) {
    return undefined;
  }
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${key} must be a string.`);
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function timestampMillis(value: unknown): number | undefined {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  const maybeTimestamp = value as { toMillis?: unknown };
  if (typeof maybeTimestamp?.toMillis === "function") {
    return maybeTimestamp.toMillis();
  }

  return undefined;
}

function isSuspended(userData: FirebaseFirestore.DocumentData): boolean {
  if (userData.suspensionStatus === "banned") {
    return true;
  }

  if (userData.suspensionStatus !== "suspended") {
    return false;
  }

  const expiresAtMillis = timestampMillis(userData.suspensionExpiresAt);
  return expiresAtMillis === undefined || expiresAtMillis > Date.now();
}

function assertNotSuspended(userDoc: FirebaseFirestore.DocumentSnapshot): void {
  const userData = userDoc.data();
  if (!userDoc.exists || !userData) {
    throw new HttpsError("failed-precondition", "User profile not found.");
  }

  if (isSuspended(userData)) {
    throw new HttpsError("permission-denied", "Suspended users cannot perform this action.");
  }
}

export const submitReport = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const data = requireData(request.data);

  const targetType = requireString(data, "targetType");
  const targetId = requireString(data, "targetId");
  const targetOwnerId = requireString(data, "targetOwnerId");
  const reason = requireString(data, "reason");

  if (!allowedTargetTypes.has(targetType)) {
    throw new HttpsError("invalid-argument", "Invalid report target type.");
  }

  if (!allowedReasons.has(reason)) {
    throw new HttpsError("invalid-argument", "Invalid report reason.");
  }

  if (targetOwnerId === uid) {
    throw new HttpsError("failed-precondition", "You cannot report your own content.");
  }

  const db = getFirestore();
  const reportRef = db.collection("reports").doc(`${uid}_${targetId}`);
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const [userDoc, reportDoc] = await Promise.all([
      transaction.get(userRef),
      transaction.get(reportRef),
    ]);

    assertNotSuspended(userDoc);

    if (reportDoc.exists) {
      throw new HttpsError("already-exists", "You have already reported this content.");
    }

    const report: FirebaseFirestore.DocumentData = {
      reporterId: uid,
      targetType,
      targetId,
      targetOwnerId,
      reason,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    };

    const details = optionalString(data, "details");
    if (details) {
      report.details = details;
    }

    const targetContent = optionalString(data, "targetContent");
    if (targetContent) {
      report.targetContent = targetContent;
    }

    const targetImageURL = optionalString(data, "targetImageURL");
    if (targetImageURL) {
      report.targetImageURL = targetImageURL;
    }

    transaction.create(reportRef, report);
  });

  return { success: true };
});
