import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

/**
 * Maintains the denormalized photoCount on the parent recap document.
 * The map only shows ghost markers to non-attendees once photoCount > 0,
 * so empty recaps don't clutter the map.
 */
export const onRecapPhotoCreated = onDocumentCreated(
  { document: "pingRecaps/{recapId}/photos/{photoId}", region: "europe-west3" },
  async (event) => {
    const photoData = event.data?.data();
    if (!photoData) return;

    // The moderation trigger can create a placeholder doc (isModerated only)
    // before the client write lands — those never become visible photos.
    if (photoData.isModerated === true) return;

    const db = getFirestore();
    await db
      .collection("pingRecaps")
      .doc(event.params.recapId)
      .update({ photoCount: FieldValue.increment(1) });
  }
);
