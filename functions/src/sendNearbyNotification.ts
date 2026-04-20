import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const NEARBY_RADIUS_KM = 2;

function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

async function getBlockedPairs(db: FirebaseFirestore.Firestore, userId: string): Promise<Set<string>> {
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

export const sendNearbyNotification = onDocumentCreated(
  "pings/{pingId}",
  async (event) => {
    const pingData = event.data?.data();
    if (!pingData) return;

    const db = getFirestore();
    const messaging = getMessaging();

    const creatorId = pingData.creatorId as string;
    const pingText = (pingData.text as string).substring(0, 50);
    const pingLocation = pingData.location;

    if (!pingLocation || !pingLocation.latitude || !pingLocation.longitude) {
      console.log("Ping has no location, skipping notification.");
      return;
    }

    const blockedUsers = await getBlockedPairs(db, creatorId);

    const usersSnapshot = await db
      .collection("users")
      .where("fcmToken", "!=", null)
      .get();

    const tokens: string[] = [];

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      if (userId === creatorId) continue;
      if (userData.notifyNearbyPings === false) continue;
      if (blockedUsers.has(userId)) continue;

      const userLocation = userData.lastKnownLocation;
      if (!userLocation || !userLocation.latitude || !userLocation.longitude) continue;

      const distance = haversineDistance(
        pingLocation.latitude,
        pingLocation.longitude,
        userLocation.latitude,
        userLocation.longitude
      );

      if (distance > NEARBY_RADIUS_KM) continue;

      if (userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    }

    if (tokens.length === 0) {
      console.log("No nearby users to notify.");
      return;
    }

    const batchSize = 500;
    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      await messaging.sendEachForMulticast({
        tokens: batch,
        notification: {
          title: "New ping nearby!",
          body: pingText,
        },
        data: {
          pingId: event.params.pingId,
          type: "nearby_ping",
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

    console.log(`Sent nearby notifications to ${tokens.length} users.`);
  }
);
