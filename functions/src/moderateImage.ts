import { onObjectFinalized } from "firebase-functions/v2/storage";
import { getFirestore } from "firebase-admin/firestore";
import { getStorage } from "firebase-admin/storage";
import vision from "@google-cloud/vision";

const client = new vision.ImageAnnotatorClient();

export const moderateImage = onObjectFinalized(async (event) => {
  const filePath = event.data.name;
  if (!filePath) return;

  // Only moderate profile pictures and ping images
  const isProfilePic = filePath.startsWith("profile_pictures/");
  const isPingImage = filePath.startsWith("ping_images/");

  if (!isProfilePic && !isPingImage) return;

  const db = getFirestore();
  const storage = getStorage();
  const bucket = storage.bucket(event.data.bucket);
  const file = bucket.file(filePath);

  try {
    // Get a signed URL for Vision API
    const [url] = await file.getSignedUrl({
      action: "read",
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
    });

    // Call Vision API SafeSearch
    const [result] = await client.safeSearchDetection(url);
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

    const shouldAutoRemove =
      isVeryLikely(safeSearch.adult) ||
      isVeryLikely(safeSearch.violence) ||
      isVeryLikely(safeSearch.racy);

    const shouldFlagForReview =
      isLikely(safeSearch.adult) ||
      isLikely(safeSearch.violence) ||
      isLikely(safeSearch.racy);

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

      // Create audit trail
      await db.collection("moderationActions").add({
        targetType: isProfilePic ? "profile_image" : "ping_image",
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
        targetType: isProfilePic ? "profile_image" : "ping_image",
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
});
