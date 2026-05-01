import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";

export const deleteAccount = onCall({ region: "europe-west3" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const db = getFirestore();
  const auth = getAuth();
  const storage = getStorage();

  try {
    // 1. Delete all pings created by user (and their chats/messages)
    const userPings = await db
      .collection("pings")
      .where("creatorId", "==", uid)
      .get();

    for (const pingDoc of userPings.docs) {
      const pingData = pingDoc.data();
      if (pingData.chatId) {
        const messages = await db
          .collection("chatMessages")
          .where("chatId", "==", pingData.chatId)
          .get();
        for (const msg of messages.docs) {
          await msg.ref.delete();
        }
        const participants = await db
          .collection("chatParticipants")
          .where("chatId", "==", pingData.chatId)
          .get();
        for (const part of participants.docs) {
          await part.ref.delete();
        }
        await db.collection("chats").doc(pingData.chatId).delete();
      }
      await pingDoc.ref.delete();
    }

    // 2. Delete all chat messages sent by user (in other people's chats)
    const userMessages = await db
      .collection("chatMessages")
      .where("senderId", "==", uid)
      .get();
    for (const msg of userMessages.docs) {
      await msg.ref.delete();
    }

    // 3. Delete all chat participant records
    const userParticipations = await db
      .collection("chatParticipants")
      .where("userId", "==", uid)
      .get();
    for (const part of userParticipations.docs) {
      await part.ref.delete();
    }

    // 4. Delete all boosts by user
    const userBoosts = await db
      .collection("boosts")
      .where("userId", "==", uid)
      .get();
    for (const boost of userBoosts.docs) {
      await boost.ref.delete();
    }

    // 5. Delete all blocks by/against user
    const blocksAsBlocker = await db
      .collection("blocks")
      .where("blockerId", "==", uid)
      .get();
    for (const block of blocksAsBlocker.docs) {
      await block.ref.delete();
    }

    const blocksAsBlocked = await db
      .collection("blocks")
      .where("blockedUserId", "==", uid)
      .get();
    for (const block of blocksAsBlocked.docs) {
      await block.ref.delete();
    }

    // 6. Delete all reports by user
    const userReports = await db
      .collection("reports")
      .where("reporterId", "==", uid)
      .get();
    for (const report of userReports.docs) {
      await report.ref.delete();
    }

    // 7. Delete profile image from Storage
    try {
      const bucket = storage.bucket();
      await bucket.deleteFiles({ prefix: `profile_pictures/${uid}/` });
    } catch {
      // Storage file may not exist
    }

    // 8. Delete user document from Firestore
    await db.collection("users").doc(uid).delete();

    // 9. Delete Firebase Auth account
    await auth.deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error("Account deletion failed:", error);
    throw new HttpsError("internal", "Failed to delete account.");
  }
});
