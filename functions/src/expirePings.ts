import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";

export const expirePings = onSchedule({ schedule: "every 5 minutes", region: "europe-west3" }, async () => {
  const db = getFirestore();
  const now = new Date();

  const expiredPingsSnapshot = await db
    .collection("pings")
    .where("status", "==", "active")
    .where("expiresAt", "<=", now)
    .get();

  if (expiredPingsSnapshot.empty) {
    console.log("No expired pings found.");
    return;
  }

  console.log(`Found ${expiredPingsSnapshot.size} expired pings.`);

  const batchSize = 500;
  let operationCount = 0;
  let batch = db.batch();

  for (const pingDoc of expiredPingsSnapshot.docs) {
    const pingData = pingDoc.data();

    batch.update(pingDoc.ref, { status: "expired" });
    operationCount++;

    if (pingData.chatId) {
      const chatRef = db.collection("chats").doc(pingData.chatId);
      batch.delete(chatRef);
      operationCount++;

      const messagesSnapshot = await db
        .collection("chatMessages")
        .where("chatId", "==", pingData.chatId)
        .get();

      for (const msgDoc of messagesSnapshot.docs) {
        batch.delete(msgDoc.ref);
        operationCount++;

        if (operationCount >= batchSize) {
          await batch.commit();
          batch = db.batch();
          operationCount = 0;
        }
      }

      const participantsSnapshot = await db
        .collection("chatParticipants")
        .where("chatId", "==", pingData.chatId)
        .get();

      for (const partDoc of participantsSnapshot.docs) {
        batch.delete(partDoc.ref);
        operationCount++;

        if (operationCount >= batchSize) {
          await batch.commit();
          batch = db.batch();
          operationCount = 0;
        }
      }
    }

    const boostsSnapshot = await db
      .collection("boosts")
      .where("pingId", "==", pingDoc.id)
      .get();

    for (const boostDoc of boostsSnapshot.docs) {
      batch.delete(boostDoc.ref);
      operationCount++;

      if (operationCount >= batchSize) {
        await batch.commit();
        batch = db.batch();
        operationCount = 0;
      }
    }

    if (operationCount >= batchSize) {
      await batch.commit();
      batch = db.batch();
      operationCount = 0;
    }
  }

  if (operationCount > 0) {
    await batch.commit();
  }

  console.log(`Expired ${expiredPingsSnapshot.size} pings successfully.`);
});
