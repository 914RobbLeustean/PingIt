import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

/**
 * Blocking severs any follow relationship in both directions. A blocked
 * person should silently stop receiving your activity and vice versa.
 */
export const severFollowsOnBlock = onDocumentCreated(
  { document: "blocks/{blockId}", region: "europe-west3" },
  async (event) => {
    const blockData = event.data?.data();
    if (!blockData) return;

    const blockerId = blockData.blockerId as string;
    const blockedId = blockData.blockedUserId as string;
    if (!blockerId || !blockedId) return;

    const db = getFirestore();

    await db.runTransaction(async (transaction) => {
      const forwardRef = db.collection("follows").doc(`${blockerId}_${blockedId}`);
      const reverseRef = db.collection("follows").doc(`${blockedId}_${blockerId}`);
      const blockerRef = db.collection("users").doc(blockerId);
      const blockedRef = db.collection("users").doc(blockedId);

      const [forwardDoc, reverseDoc] = await Promise.all([
        transaction.get(forwardRef),
        transaction.get(reverseRef),
      ]);

      if (forwardDoc.exists) {
        transaction.delete(forwardRef);
        transaction.update(blockerRef, { followingCount: FieldValue.increment(-1) });
        transaction.update(blockedRef, { followerCount: FieldValue.increment(-1) });
      }

      if (reverseDoc.exists) {
        transaction.delete(reverseRef);
        transaction.update(blockedRef, { followingCount: FieldValue.increment(-1) });
        transaction.update(blockerRef, { followerCount: FieldValue.increment(-1) });
      }
    });
  }
);
