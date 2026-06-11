import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { cleanupPing } from "./pingCleanup";
import { cleanupExpiredRecaps } from "./cleanupRecaps";

const RECAP_WINDOW_HOURS = 2;
const GHOST_WINDOW_HOURS = 24;

export const expirePings = onSchedule({ schedule: "every 5 minutes", region: "europe-west3" }, async () => {
  const db = getFirestore();
  const now = new Date();

  const expiredPingsSnapshot = await db
    .collection("pings")
    .where("status", "==", "active")
    .where("expiresAt", "<=", now)
    .get();

  if (!expiredPingsSnapshot.empty) {
    console.log(`Found ${expiredPingsSnapshot.size} expired pings.`);

    for (const pingDoc of expiredPingsSnapshot.docs) {
      // RSVPs are deleted by cleanupPing, so snapshot them first — the
      // recap doc is the only post-expiry record of who was attending.
      await createRecapIfEligible(db, pingDoc);
      await cleanupPing(db, pingDoc, { status: "expired" });
    }

    console.log(`Expired ${expiredPingsSnapshot.size} pings successfully.`);
  } else {
    console.log("No expired pings found.");
  }

  const removedRecaps = await cleanupExpiredRecaps(db, now);
  if (removedRecaps > 0) {
    console.log(`Cleaned up ${removedRecaps} expired recaps.`);
  }
});

async function createRecapIfEligible(
  db: FirebaseFirestore.Firestore,
  pingDoc: FirebaseFirestore.QueryDocumentSnapshot
): Promise<void> {
  const pingData = pingDoc.data();

  try {
    // A recap exists only when someone committed to attending. RSVP is the
    // attendance signal — chat membership is not (joining a chat does not
    // mean showing up).
    const rsvpsSnapshot = await db
      .collection("rsvps")
      .where("pingId", "==", pingDoc.id)
      .get();

    if (rsvpsSnapshot.empty) {
      return;
    }

    const attendeeIds = new Set<string>();
    for (const rsvpDoc of rsvpsSnapshot.docs) {
      const userId = rsvpDoc.data().userId;
      if (typeof userId === "string" && userId.length > 0) {
        attendeeIds.add(userId);
      }
    }
    if (typeof pingData.creatorId === "string" && pingData.creatorId.length > 0) {
      attendeeIds.add(pingData.creatorId);
    }

    if (attendeeIds.size === 0) {
      return;
    }

    const expiresAt: Date = pingData.expiresAt.toDate();
    const recapWindowClosesAt = new Date(expiresAt.getTime() + RECAP_WINDOW_HOURS * 3600 * 1000);
    const ghostExpiresAt = new Date(expiresAt.getTime() + GHOST_WINDOW_HOURS * 3600 * 1000);

    await db.collection("pingRecaps").doc(pingDoc.id).set({
      pingId: pingDoc.id,
      title: pingData.text ?? "",
      category: pingData.category ?? null,
      location: pingData.location,
      attendeeIds: Array.from(attendeeIds),
      photoCount: 0,
      expiresAt,
      recapWindowClosesAt,
      ghostExpiresAt,
      createdAt: new Date(),
    });

    await notifyRecapParticipants(db, pingDoc.id, pingData.text ?? "", attendeeIds);
  } catch (error) {
    // Recap creation must never block ping expiration.
    console.error(`Failed to create recap for ping ${pingDoc.id}:`, error);
  }
}

async function notifyRecapParticipants(
  db: FirebaseFirestore.Firestore,
  pingId: string,
  pingTitle: string,
  attendeeIds: Set<string>
): Promise<void> {
  const tokens: string[] = [];

  for (const userId of attendeeIds) {
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (typeof fcmToken === "string" && fcmToken.length > 0) {
      tokens.push(fcmToken);
    }
  }

  if (tokens.length === 0) {
    return;
  }

  const messaging = getMessaging();
  const title = pingTitle.substring(0, 50);
  const batchSize = 500;

  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    await messaging.sendEachForMulticast({
      tokens: batch,
      notification: {
        title: "Share what happened!",
        body: `${title} just ended — add your photos.`,
      },
      data: {
        pingId,
        type: "recap_invite",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
  }

  console.log(`Sent recap notifications to ${tokens.length} participants of ping ${pingId}.`);
}
