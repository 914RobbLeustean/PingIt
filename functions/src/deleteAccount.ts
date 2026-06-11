import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getStorage } from "firebase-admin/storage";
import { ChunkedWriteBatch, cleanupPing } from "./pingCleanup";

export const deleteAccount = onCall({ region: "europe-west3" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const db = getFirestore();
  const auth = getAuth();
  const storage = getStorage();

  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const usernameLowercase = userDoc.data()?.usernameLowercase;

    // 1. Delete all pings created by user (and their chats/messages)
    const userPings = await db
      .collection("pings")
      .where("creatorId", "==", uid)
      .get();

    for (const pingDoc of userPings.docs) {
      await cleanupPing(db, pingDoc, { deletePing: true });
    }

    const writer = new ChunkedWriteBatch(db);

    // 2. Delete all chat messages sent by user (in other people's chats)
    const userMessages = await db
      .collection("chatMessages")
      .where("senderId", "==", uid)
      .get();
    for (const msg of userMessages.docs) {
      await writer.delete(msg.ref);
    }

    // 3. Delete all chat participant records and decrement active counters
    const userParticipations = await db
      .collection("chatParticipants")
      .where("userId", "==", uid)
      .get();
    for (const part of userParticipations.docs) {
      const partData = part.data();
      if (partData.leftAt === undefined && typeof partData.chatId === "string") {
        const chatRef = db.collection("chats").doc(partData.chatId);
        const chatDoc = await chatRef.get();
        if (chatDoc.exists) {
          const pingId = chatDoc.data()?.pingId;
          await writer.update(chatRef, { participantCount: FieldValue.increment(-1) });
          if (typeof pingId === "string") {
            const pingRef = db.collection("pings").doc(pingId);
            const pingDoc = await pingRef.get();
            if (pingDoc.exists) {
              await writer.update(pingRef, { participantCount: FieldValue.increment(-1) });
            }
          }
        }
      }
      await writer.delete(part.ref);
    }

    // 4. Delete all boosts by user and decrement ping counters
    const userBoosts = await db
      .collection("boosts")
      .where("userId", "==", uid)
      .get();
    for (const boost of userBoosts.docs) {
      const pingId = boost.data().pingId;
      if (typeof pingId === "string") {
        const pingRef = db.collection("pings").doc(pingId);
        const pingDoc = await pingRef.get();
        if (pingDoc.exists) {
          await writer.update(pingRef, { boostCount: FieldValue.increment(-1) });
        }
      }
      await writer.delete(boost.ref);
    }

    // 4b. Delete all RSVPs by user and decrement ping counters
    const userRsvps = await db
      .collection("rsvps")
      .where("userId", "==", uid)
      .get();
    for (const rsvp of userRsvps.docs) {
      const pingId = rsvp.data().pingId;
      if (typeof pingId === "string") {
        const pingRef = db.collection("pings").doc(pingId);
        const pingDoc = await pingRef.get();
        if (pingDoc.exists) {
          await writer.update(pingRef, { rsvpCount: FieldValue.increment(-1) });
        }
      }
      await writer.delete(rsvp.ref);
    }

    // 4c. Delete all follow edges (both directions) and fix counterparties' counters
    const followsAsFollower = await db
      .collection("follows")
      .where("followerId", "==", uid)
      .get();
    for (const follow of followsAsFollower.docs) {
      const followedId = follow.data().followedId;
      if (typeof followedId === "string") {
        const followedRef = db.collection("users").doc(followedId);
        const followedDoc = await followedRef.get();
        if (followedDoc.exists) {
          await writer.update(followedRef, { followerCount: FieldValue.increment(-1) });
        }
      }
      await writer.delete(follow.ref);
    }

    const followsAsFollowed = await db
      .collection("follows")
      .where("followedId", "==", uid)
      .get();
    for (const follow of followsAsFollowed.docs) {
      const followerId = follow.data().followerId;
      if (typeof followerId === "string") {
        const followerRef = db.collection("users").doc(followerId);
        const followerDoc = await followerRef.get();
        if (followerDoc.exists) {
          await writer.update(followerRef, { followingCount: FieldValue.increment(-1) });
        }
      }
      await writer.delete(follow.ref);
    }

    // 5. Delete all blocks by/against user
    const blocksAsBlocker = await db
      .collection("blocks")
      .where("blockerId", "==", uid)
      .get();
    for (const block of blocksAsBlocker.docs) {
      await writer.delete(block.ref);
    }

    const blocksAsBlocked = await db
      .collection("blocks")
      .where("blockedUserId", "==", uid)
      .get();
    for (const block of blocksAsBlocked.docs) {
      await writer.delete(block.ref);
    }

    // 6. Delete all reports by user
    const userReports = await db
      .collection("reports")
      .where("reporterId", "==", uid)
      .get();
    for (const report of userReports.docs) {
      await writer.delete(report.ref);
    }

    if (typeof usernameLowercase === "string" && usernameLowercase.length > 0) {
      await writer.delete(db.collection("usernames").doc(usernameLowercase));
    }

    // 7. Delete profile image from Storage
    try {
      const bucket = storage.bucket();
      await bucket.deleteFiles({ prefix: `profile_pictures/${uid}/` });
    } catch {
      // Storage file may not exist
    }

    // 8. Delete user document from Firestore
    await writer.delete(db.collection("users").doc(uid));
    await writer.commit();

    // 9. Delete Firebase Auth account
    await auth.deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error("Account deletion failed:", error);
    throw new HttpsError("internal", "Failed to delete account.");
  }
});
