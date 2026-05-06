import { onSchedule } from "firebase-functions/v2/scheduler";
import { getFirestore } from "firebase-admin/firestore";
import { cleanupPing } from "./pingCleanup";

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

  for (const pingDoc of expiredPingsSnapshot.docs) {
    await cleanupPing(db, pingDoc, { status: "expired" });
  }

  console.log(`Expired ${expiredPingsSnapshot.size} pings successfully.`);
});
