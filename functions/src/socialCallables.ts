import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import {
  requireAuthUid,
  requireString,
  requireData,
  numberValue,
  assertNotSuspended,
  hasBlockingRelationshipInTransaction,
} from "./pingCallables";

const SEARCH_RESULT_LIMIT = 15;

export const toggleFollow = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const targetUserId = requireString(requireData(request.data), "targetUserId");
  const db = getFirestore();

  if (targetUserId === uid) {
    throw new HttpsError("failed-precondition", "You cannot follow yourself.");
  }

  return db.runTransaction(async (transaction) => {
    const followerRef = db.collection("users").doc(uid);
    const followedRef = db.collection("users").doc(targetUserId);
    const followRef = db.collection("follows").doc(`${uid}_${targetUserId}`);

    const [followerDoc, followedDoc, followDoc] = await Promise.all([
      transaction.get(followerRef),
      transaction.get(followedRef),
      transaction.get(followRef),
    ]);

    assertNotSuspended(followerDoc);

    const followedData = followedDoc.data();
    if (!followedDoc.exists || !followedData) {
      throw new HttpsError("not-found", "User not found.");
    }

    const currentFollowerCount = numberValue(followedData.followerCount);

    // Toggle: an existing follow is removed, otherwise one is created.
    if (followDoc.exists) {
      transaction.delete(followRef);
      transaction.update(followedRef, { followerCount: FieldValue.increment(-1) });
      transaction.update(followerRef, { followingCount: FieldValue.increment(-1) });
      return {
        isFollowing: false,
        followerCount: Math.max(currentFollowerCount - 1, 0),
      };
    }

    if (followedData.isPrivateProfile === true) {
      throw new HttpsError("failed-precondition", "This profile is private.");
    }

    const isBlocked = await hasBlockingRelationshipInTransaction(transaction, db, uid, targetUserId);
    if (isBlocked) {
      throw new HttpsError("permission-denied", "Cannot follow this user.");
    }

    transaction.create(followRef, {
      followerId: uid,
      followedId: targetUserId,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(followedRef, { followerCount: FieldValue.increment(1) });
    transaction.update(followerRef, { followingCount: FieldValue.increment(1) });

    return {
      isFollowing: true,
      followerCount: currentFollowerCount + 1,
    };
  });
});

export const searchUsers = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const rawQuery = requireString(requireData(request.data), "query");
  const db = getFirestore();

  const normalized = rawQuery.toLowerCase().replace(/[^a-z0-9_]/g, "");
  if (normalized.length < 2) {
    return { results: [] };
  }

  // Prefix search over public profiles only. Private users never appear.
  const snapshot = await db
    .collection("users")
    .where("isPrivateProfile", "==", false)
    .where("usernameLowercase", ">=", normalized)
    .where("usernameLowercase", "<", normalized + "")
    .limit(SEARCH_RESULT_LIMIT)
    .get();

  const blockedIds = await blockedUserIds(db, uid);

  const results = snapshot.docs
    .filter((doc) => doc.id !== uid && !blockedIds.has(doc.id))
    .map((doc) => {
      const data = doc.data();
      return {
        userId: doc.id,
        username: data.username ?? "",
        profileImageUrl: data.profileImageUrl ?? null,
        followerCount: numberValue(data.followerCount),
      };
    });

  return { results };
});

async function blockedUserIds(
  db: FirebaseFirestore.Firestore,
  userId: string
): Promise<Set<string>> {
  const blocked = new Set<string>();
  const [asBlocker, asBlocked] = await Promise.all([
    db.collection("blocks").where("blockerId", "==", userId).get(),
    db.collection("blocks").where("blockedUserId", "==", userId).get(),
  ]);
  for (const doc of asBlocker.docs) {
    blocked.add(doc.data().blockedUserId);
  }
  for (const doc of asBlocked.docs) {
    blocked.add(doc.data().blockerId);
  }
  return blocked;
}
