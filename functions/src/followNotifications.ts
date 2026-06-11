import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const TOKEN_BATCH_SIZE = 500;

interface FollowerNotification {
  title: string;
  body: string;
  data: Record<string, string>;
}

/**
 * Notifies the followed user when someone follows them.
 */
export const notifyOnNewFollower = onDocumentCreated(
  { document: "follows/{followId}", region: "europe-west3" },
  async (event) => {
    const followData = event.data?.data();
    if (!followData) return;

    const db = getFirestore();
    const followerId = followData.followerId as string;
    const followedId = followData.followedId as string;
    if (!followerId || !followedId) return;

    const [followerDoc, followedDoc] = await Promise.all([
      db.collection("users").doc(followerId).get(),
      db.collection("users").doc(followedId).get(),
    ]);

    const followerName = followerDoc.data()?.username;
    const followedData = followedDoc.data();
    if (!followerName || !followedData) return;
    if (followedData.notifyFollowActivity === false) return;

    const token = followedData.fcmToken;
    if (typeof token !== "string" || token.length === 0) return;

    await getMessaging().sendEachForMulticast({
      tokens: [token],
      notification: {
        title: "New follower",
        body: `@${followerName} started following you.`,
      },
      data: { type: "new_follower", followerId },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  }
);

/**
 * Notifies an actor's followers when they create a ping.
 */
export const notifyFollowersOnPingCreated = onDocumentCreated(
  { document: "pings/{pingId}", region: "europe-west3" },
  async (event) => {
    const pingData = event.data?.data();
    if (!pingData) return;

    const creatorId = pingData.creatorId as string;
    const title = ((pingData.text as string) ?? "").substring(0, 50);

    await notifyFollowers(creatorId, {
      title: "New ping from someone you follow",
      body: (username) => `@${username} dropped a ping: ${title}`,
      data: { pingId: event.params.pingId, type: "followed_ping" },
    });
  }
);

/**
 * Notifies an actor's followers when they RSVP to a ping.
 */
export const notifyFollowersOnRSVP = onDocumentCreated(
  { document: "rsvps/{rsvpId}", region: "europe-west3" },
  async (event) => {
    const rsvpData = event.data?.data();
    if (!rsvpData) return;

    const userId = rsvpData.userId as string;
    const pingId = rsvpData.pingId as string;
    if (!userId || !pingId) return;

    const db = getFirestore();
    const pingDoc = await db.collection("pings").doc(pingId).get();
    const pingTitle = ((pingDoc.data()?.text as string) ?? "a ping").substring(0, 50);

    await notifyFollowers(userId, {
      title: "Someone you follow is going",
      body: (username) => `@${username} is going to: ${pingTitle}`,
      data: { pingId, type: "followed_rsvp" },
    });
  }
);

/**
 * Notifies an actor's followers when they add a photo to a recap.
 */
export const notifyFollowersOnRecapPhoto = onDocumentCreated(
  { document: "pingRecaps/{recapId}/photos/{photoId}", region: "europe-west3" },
  async (event) => {
    const photoData = event.data?.data();
    if (!photoData) return;
    if (photoData.isModerated === true) return;

    const submitterId = photoData.submitterId as string;
    if (!submitterId) return;

    const db = getFirestore();
    const recapDoc = await db.collection("pingRecaps").doc(event.params.recapId).get();
    const recapTitle = ((recapDoc.data()?.title as string) ?? "a ping").substring(0, 50);

    await notifyFollowers(submitterId, {
      title: "New recap photo",
      body: (username) => `@${username} added a photo from: ${recapTitle}`,
      data: { pingId: event.params.recapId, type: "followed_recap_photo" },
    });
  }
);

/**
 * Shared dispatch: finds the actor's followers, filters out muted users
 * and blocking relationships, suppresses everything if the actor has gone
 * private (dormant follows), then sends FCM in batches.
 */
async function notifyFollowers(
  actorId: string,
  message: {
    title: string;
    body: (actorUsername: string) => string;
    data: Record<string, string>;
  }
): Promise<void> {
  if (!actorId) return;

  const db = getFirestore();
  const actorDoc = await db.collection("users").doc(actorId).get();
  const actorData = actorDoc.data();
  if (!actorData) return;

  // Dormancy: a private actor generates no follow activity.
  if (actorData.isPrivateProfile === true) return;

  const username = actorData.username as string;
  if (!username) return;

  const followsSnapshot = await db
    .collection("follows")
    .where("followedId", "==", actorId)
    .get();

  if (followsSnapshot.empty) return;

  const blockedIds = await blockedUserIds(db, actorId);
  const tokens: string[] = [];

  for (const followDoc of followsSnapshot.docs) {
    const followerId = followDoc.data().followerId as string;
    if (!followerId || blockedIds.has(followerId)) continue;

    const followerDoc = await db.collection("users").doc(followerId).get();
    const followerData = followerDoc.data();
    if (!followerData) continue;
    if (followerData.notifyFollowActivity === false) continue;

    const token = followerData.fcmToken;
    if (typeof token === "string" && token.length > 0) {
      tokens.push(token);
    }
  }

  if (tokens.length === 0) return;

  const messaging = getMessaging();
  const payload: FollowerNotification = {
    title: message.title,
    body: message.body(username),
    data: message.data,
  };

  for (let i = 0; i < tokens.length; i += TOKEN_BATCH_SIZE) {
    await messaging.sendEachForMulticast({
      tokens: tokens.slice(i, i + TOKEN_BATCH_SIZE),
      notification: { title: payload.title, body: payload.body },
      data: payload.data,
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  }

  console.log(`Sent ${payload.data.type} notifications to ${tokens.length} followers of ${actorId}.`);
}

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
