import { initializeApp } from "firebase-admin/app";
import { onRequest } from "firebase-functions/v2/https";

initializeApp();

export const healthCheck = onRequest({ region: "europe-west3" }, (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

export { expirePings } from "./expirePings";
export { deleteAccount } from "./deleteAccount";
export { sendNearbyNotification } from "./sendNearbyNotification";
export {
  sendHotPingNotificationOnBoost,
  sendHotPingNotificationOnJoin,
} from "./sendHotPingNotification";
export { moderateImage } from "./moderateImage";
export { removeContent } from "./removeContent";
