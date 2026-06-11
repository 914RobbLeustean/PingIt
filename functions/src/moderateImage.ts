import { onObjectFinalized } from "firebase-functions/v2/storage";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import vision from "@google-cloud/vision";

const client = new vision.ImageAnnotatorClient();

export const moderateImage = onObjectFinalized(
  { region: "europe-west3", bucket: "pingit-dev.firebasestorage.app" },
  async (event) => {
    const filePath = event.data.name;
    if (!filePath) return;

    // Only moderate profile pictures, ping images, and recap photos
    const isProfilePic = filePath.startsWith("profile_pictures/");
    const isPingImage = filePath.startsWith("ping_images/");
    const isRecapPhoto = filePath.startsWith("recap_photos/");

    if (!isProfilePic && !isPingImage && !isRecapPhoto) return;

    const db = getFirestore();
    const storage = getStorage();
    const bucket = storage.bucket(event.data.bucket);
    const file = bucket.file(filePath);

    try {
      // Use gs:// URI directly — avoids signBlob permission requirement
      const gcsUri = `gs://${event.data.bucket}/${filePath}`;

      // Call Vision API SafeSearch
      const [result] = await client.safeSearchDetection(gcsUri);
      const safeSearch = result.safeSearchAnnotation;

      if (!safeSearch) {
        console.log(`No SafeSearch result for ${filePath}`);
        return;
      }

      console.log(`SafeSearch for ${filePath}:`, {
        adult: safeSearch.adult,
        violence: safeSearch.violence,
        racy: safeSearch.racy,
      });

      const isVeryLikely = (level: unknown): boolean =>
        String(level) === "VERY_LIKELY" || level === "VERY_LIKELY";

      const isLikely = (level: unknown): boolean =>
        String(level) === "LIKELY" || level === "LIKELY";

      const shouldAutoRemove = (
        isVeryLikely(safeSearch.adult) ||
        isVeryLikely(safeSearch.violence) ||
        isVeryLikely(safeSearch.racy)
      );

      const shouldFlagForReview = (
        isLikely(safeSearch.adult) ||
        isLikely(safeSearch.violence) ||
        isLikely(safeSearch.racy)
      );

      if (shouldAutoRemove) {
        console.log(`Auto-removing ${filePath} — flagged as inappropriate.`);

        // Delete the file
        await file.delete();

        if (isProfilePic) {
          // Extract userId from path: profile_pictures/{userId}/filename
          const userId = filePath.split("/")[1];
          if (userId) {
            await db.collection("users").doc(userId).update({
              profileImageUrl: null,
            });
          }
        }

        if (isPingImage) {
          // Extract pingId from path: ping_images/{pingId}/filename
          const pingId = filePath.split("/")[1];
          if (pingId) {
            await db.collection("pings").doc(pingId).update({
              status: "removed",
            });
          }
        }

        if (isRecapPhoto) {
          // Path: recap_photos/{pingId}/{photoId}.jpg — file name is the
          // Firestore photo doc id. Set-merge so the flag survives the race
          // where this trigger fires before the client writes the photo doc
          // (the client's subsequent create then fails, rejecting the photo).
          const pingId = filePath.split("/")[1];
          const photoId = filePath.split("/")[2]?.replace(/\.[^.]+$/, "");
          if (pingId && photoId) {
            const recapRef = db.collection("pingRecaps").doc(pingId);
            const photoRef = recapRef.collection("photos").doc(photoId);
            await db.runTransaction(async (transaction) => {
              const photoDoc = await transaction.get(photoRef);
              const wasCounted = photoDoc.exists && photoDoc.data()?.isModerated !== true;
              transaction.set(photoRef, { isModerated: true }, { merge: true });
              if (wasCounted) {
                transaction.update(recapRef, { photoCount: FieldValue.increment(-1) });
              }
            });
          }
        }

        // Create audit trail
        await db.collection("moderationActions").add({
          targetType: isProfilePic
            ? "profile_image"
            : isPingImage
              ? "ping_image"
              : "recap_photo",
          targetPath: filePath,
          action: "auto_removed",
          reason: `SafeSearch: adult=${safeSearch.adult}, violence=${safeSearch.violence}, racy=${safeSearch.racy}`,
          moderatorId: "system",
          timestamp: new Date(),
        });
      } else if (shouldFlagForReview) {
        console.log(`Flagging ${filePath} for manual review.`);

        // Create a report for manual review
        await db.collection("reports").add({
          reporterId: "system",
          targetType: isProfilePic
            ? "profile_image"
            : isPingImage
              ? "ping_image"
              : "recap_photo",
          targetId: filePath,
          targetOwnerId: filePath.split("/")[1] || "unknown",
          reason: "Automated moderation flag",
          details: `SafeSearch: adult=${safeSearch.adult}, violence=${safeSearch.violence}, racy=${safeSearch.racy}`,
          status: "pending",
          createdAt: new Date(),
        });
      }
    } catch (error) {
      console.error(`Error moderating image ${filePath}:`, error);
    }
  }
);
