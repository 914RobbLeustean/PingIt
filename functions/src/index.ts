import { initializeApp } from "firebase-admin/app";
import { onRequest } from "firebase-functions/v2/https";

initializeApp();

export const healthCheck = onRequest((req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});
