import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const exportUserData = onCall({ region: "europe-west3" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }

  const db = getFirestore();

  try {
    const userDoc = await db.collection("users").doc(uid).get();
    const userData = userDoc.exists ? userDoc.data() : null;

    const pingsSnapshot = await db
      .collection("pings")
      .where("creatorId", "==", uid)
      .get();
    const pings = pingsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const messagesSnapshot = await db
      .collection("chatMessages")
      .where("senderId", "==", uid)
      .get();
    const messages = messagesSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const boostsSnapshot = await db
      .collection("boosts")
      .where("userId", "==", uid)
      .get();
    const boosts = boostsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const blocksSnapshot = await db
      .collection("blocks")
      .where("blockerId", "==", uid)
      .get();
    const blocks = blocksSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const reportsSnapshot = await db
      .collection("reports")
      .where("reporterId", "==", uid)
      .get();
    const reports = reportsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    const participationsSnapshot = await db
      .collection("chatParticipants")
      .where("userId", "==", uid)
      .get();
    const participations = participationsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));

    return {
      exportedAt: new Date().toISOString(),
      profile: userData,
      pings,
      messages,
      boosts,
      blocks,
      reports,
      chatParticipations: participations,
    };
  } catch (error) {
    console.error("Data export failed:", error);
    throw new HttpsError("internal", "Failed to export user data.");
  }
});
