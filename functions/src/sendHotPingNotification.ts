import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

const HOT_SCORE_THRESHOLD = 8.0;
const BOOST_COUNT_GATE = 3;
const TOP_N = 10;

function calculateHotScore(
  boostCount: number,
  participantCount: number,
  expiresAt: Date
): number {
  const hoursRemaining = Math.max(
    0,
    (expiresAt.getTime() - Date.now()) / (1000 * 60 * 60)
  );
  const timeContribution = Math.min(hoursRemaining * 0.1, 2.0);
  return boostCount * 2.0 + participantCount + timeContribution;
}

function isHot(boostCount: number, hotScore: number): boolean {
  return boostCount >= BOOST_COUNT_GATE && hotScore >= HOT_SCORE_THRESHOLD;
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

async function checkAndNotifyHotPing(pingId: string | undefined): Promise<void> {
  if (!pingId) return;

  const db = getFirestore();
  const messaging = getMessaging();

  const pingDoc = await db.collection("pings").doc(pingId).get();
  if (!pingDoc.exists) return;

  const pingData = pingDoc.data()!;
  if (pingData.status !== "active") return;

  const boostCount = pingData.boostCount || 0;
  const participantCount = pingData.participantCount || 0;
  const pingScore = calculateHotScore(
    boostCount,
    participantCount,
    pingData.expiresAt.toDate()
  );

  if (!isHot(boostCount, pingScore)) return;

  // Check if it's in the top N active pings by score
  const allActivePings = await db
    .collection("pings")
    .where("status", "==", "active")
    .get();

  const scores = allActivePings.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      score: calculateHotScore(
        data.boostCount || 0,
        data.participantCount || 0,
        data.expiresAt.toDate()
      ),
    };
  });

  scores.sort((a, b) => b.score - a.score);
  const topN = scores.slice(0, TOP_N);
  const isInTopN = topN.some((p) => p.id === pingId);

  if (!isInTopN) return;

  // Prevent duplicate hot notifications for the same ping
  if (pingData.hotNotificationSent) return;

  await db.collection("pings").doc(pingId).update({ hotNotificationSent: true });

  const creatorId = pingData.creatorId as string;
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
    if (userData.notifyHotPings === false) continue;
    if (blockedUsers.has(userId)) continue;

    if (userData.fcmToken) {
      tokens.push(userData.fcmToken);
    }
  }

  if (tokens.length === 0) return;

  const pingText = (pingData.text as string).substring(0, 50);

  const batchSize = 500;
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batch = tokens.slice(i, i + batchSize);
    await messaging.sendEachForMulticast({
      tokens: batch,
      notification: {
        title: "Trending ping!",
        body: pingText,
      },
      data: {
        pingId: pingId,
        type: "hot_ping",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });
  }

  console.log(`Sent hot ping notification for ${pingId} to ${tokens.length} users.`);
}

export const sendHotPingNotificationOnBoost = onDocumentCreated(
  { document: "boosts/{boostId}", region: "europe-west3" },
  async (event) => {
    await checkAndNotifyHotPing(event.data?.data()?.pingId);
  }
);

export const sendHotPingNotificationOnJoin = onDocumentCreated(
  { document: "chatParticipants/{participantId}", region: "europe-west3" },
  async (event) => {
    const participantData = event.data?.data();
    if (!participantData?.chatId) return;

    const db = getFirestore();
    const pingsSnapshot = await db
      .collection("pings")
      .where("chatId", "==", participantData.chatId)
      .limit(1)
      .get();

    if (pingsSnapshot.empty) return;
    await checkAndNotifyHotPing(pingsSnapshot.docs[0].id);
  }
);
