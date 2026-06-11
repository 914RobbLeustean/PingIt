import { getStorage } from "firebase-admin/storage";
import { ChunkedWriteBatch } from "./pingCleanup";

/**
 * Deletes recap documents whose ghost window has passed, including their
 * photos subcollection and Storage files. Called from the expirePings cron.
 */
export async function cleanupExpiredRecaps(
  db: FirebaseFirestore.Firestore,
  now: Date
): Promise<number> {
  const expiredRecapsSnapshot = await db
    .collection("pingRecaps")
    .where("ghostExpiresAt", "<=", now)
    .get();

  if (expiredRecapsSnapshot.empty) {
    return 0;
  }

  for (const recapDoc of expiredRecapsSnapshot.docs) {
    const writer = new ChunkedWriteBatch(db);

    const photosSnapshot = await recapDoc.ref.collection("photos").get();
    for (const photoDoc of photosSnapshot.docs) {
      await writer.delete(photoDoc.ref);
    }

    await writer.delete(recapDoc.ref);
    await writer.commit();

    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `recap_photos/${recapDoc.id}/` });
    } catch (error) {
      console.warn(`Failed to delete recap photos for ${recapDoc.id}:`, error);
    }
  }

  return expiredRecapsSnapshot.size;
}
