import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { cleanupPing } from "./pingCleanup";

type CallableData = Record<string, unknown>;

export function requireAuthUid(request: { auth?: { uid?: string } }): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated.");
  }
  return uid;
}

export function requireString(data: CallableData, key: string): string {
  const value = data[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${key} is required.`);
  }
  return value.trim();
}

export function requireData(data: unknown): CallableData {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Request data is required.");
  }
  return data as CallableData;
}

export function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function timestampMillis(value: unknown): number | undefined {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  const maybeTimestamp = value as { toMillis?: unknown };
  if (typeof maybeTimestamp?.toMillis === "function") {
    return maybeTimestamp.toMillis();
  }

  return undefined;
}

function isSuspended(userData: FirebaseFirestore.DocumentData): boolean {
  if (userData.suspensionStatus === "banned") {
    return true;
  }

  if (userData.suspensionStatus !== "suspended") {
    return false;
  }

  const expiresAtMillis = timestampMillis(userData.suspensionExpiresAt);
  return expiresAtMillis === undefined || expiresAtMillis > Date.now();
}

export function assertNotSuspended(userDoc: FirebaseFirestore.DocumentSnapshot): void {
  const userData = userDoc.data();
  if (!userDoc.exists || !userData) {
    throw new HttpsError("failed-precondition", "User profile not found.");
  }

  if (isSuspended(userData)) {
    throw new HttpsError("permission-denied", "Suspended users cannot perform this action.");
  }
}

function assertActivePing(pingData: FirebaseFirestore.DocumentData): void {
  const expiresAtMillis = timestampMillis(pingData.expiresAt);
  if (pingData.status !== "active" || expiresAtMillis === undefined || expiresAtMillis <= Date.now()) {
    throw new HttpsError("failed-precondition", "Ping is no longer active.");
  }
}

export async function hasBlockingRelationshipInTransaction(
  transaction: FirebaseFirestore.Transaction,
  db: FirebaseFirestore.Firestore,
  userId: string,
  otherUserId: string
): Promise<boolean> {
  if (userId === otherUserId) {
    return false;
  }

  const [blockedByUser, blockedByOther] = await Promise.all([
    transaction.get(
      db
        .collection("blocks")
        .where("blockerId", "==", userId)
        .where("blockedUserId", "==", otherUserId)
        .limit(1)
    ),
    transaction.get(
      db
        .collection("blocks")
        .where("blockerId", "==", otherUserId)
        .where("blockedUserId", "==", userId)
        .limit(1)
    ),
  ]);

  return !blockedByUser.empty || !blockedByOther.empty;
}

export const deletePing = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const pingId = requireString(requireData(request.data), "pingId");
  const db = getFirestore();
  const pingDoc = await db.collection("pings").doc(pingId).get();
  const pingData = pingDoc.data();

  if (!pingDoc.exists || !pingData) {
    throw new HttpsError("not-found", "Ping not found.");
  }

  if (pingData.creatorId !== uid) {
    throw new HttpsError("permission-denied", "Only the creator can delete this ping.");
  }

  await cleanupPing(db, pingDoc, { status: "removed" });
  return { success: true };
});

export const boostPing = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const pingId = requireString(requireData(request.data), "pingId");
  const db = getFirestore();

  return db.runTransaction(async (transaction) => {
    const pingRef = db.collection("pings").doc(pingId);
    const userRef = db.collection("users").doc(uid);
    const boostRef = db.collection("boosts").doc(`${pingId}_${uid}`);

    const [pingDoc, userDoc, boostDoc] = await Promise.all([
      transaction.get(pingRef),
      transaction.get(userRef),
      transaction.get(boostRef),
    ]);

    const pingData = pingDoc.data();
    if (!pingDoc.exists || !pingData) {
      throw new HttpsError("not-found", "Ping not found.");
    }

    assertNotSuspended(userDoc);
    assertActivePing(pingData);

    const creatorId = pingData.creatorId as string | undefined;
    if (!creatorId) {
      throw new HttpsError("failed-precondition", "Ping creator is missing.");
    }

    if (creatorId === uid) {
      throw new HttpsError("failed-precondition", "Creators cannot boost their own pings.");
    }

    const isBlocked = await hasBlockingRelationshipInTransaction(transaction, db, uid, creatorId);
    if (isBlocked) {
      throw new HttpsError("permission-denied", "Cannot boost this ping.");
    }

    const currentBoostCount = numberValue(pingData.boostCount);
    if (boostDoc.exists) {
      return {
        boostCount: currentBoostCount,
        didBoost: true,
      };
    }

    const nextBoostCount = currentBoostCount + 1;
    transaction.create(boostRef, {
      pingId,
      userId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(pingRef, {
      boostCount: FieldValue.increment(1),
    });

    return {
      boostCount: nextBoostCount,
      didBoost: true,
    };
  });
});

export const rsvpPing = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const pingId = requireString(requireData(request.data), "pingId");
  const db = getFirestore();

  return db.runTransaction(async (transaction) => {
    const pingRef = db.collection("pings").doc(pingId);
    const userRef = db.collection("users").doc(uid);
    const rsvpRef = db.collection("rsvps").doc(`${pingId}_${uid}`);

    const [pingDoc, userDoc, rsvpDoc] = await Promise.all([
      transaction.get(pingRef),
      transaction.get(userRef),
      transaction.get(rsvpRef),
    ]);

    const pingData = pingDoc.data();
    if (!pingDoc.exists || !pingData) {
      throw new HttpsError("not-found", "Ping not found.");
    }

    assertNotSuspended(userDoc);
    assertActivePing(pingData);

    const creatorId = pingData.creatorId as string | undefined;
    if (!creatorId) {
      throw new HttpsError("failed-precondition", "Ping creator is missing.");
    }

    if (creatorId === uid) {
      throw new HttpsError("failed-precondition", "Creators are already attending their own pings.");
    }

    const isBlocked = await hasBlockingRelationshipInTransaction(transaction, db, uid, creatorId);
    if (isBlocked) {
      throw new HttpsError("permission-denied", "Cannot RSVP to this ping.");
    }

    const currentRsvpCount = numberValue(pingData.rsvpCount);

    // Toggle: an existing RSVP is withdrawn, otherwise one is created.
    if (rsvpDoc.exists) {
      transaction.delete(rsvpRef);
      transaction.update(pingRef, {
        rsvpCount: FieldValue.increment(-1),
      });
      return {
        rsvpCount: Math.max(currentRsvpCount - 1, 0),
        isAttending: false,
      };
    }

    transaction.create(rsvpRef, {
      pingId,
      userId: uid,
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(pingRef, {
      rsvpCount: FieldValue.increment(1),
    });

    return {
      rsvpCount: currentRsvpCount + 1,
      isAttending: true,
    };
  });
});

export const joinChat = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const chatId = requireString(requireData(request.data), "chatId");
  const db = getFirestore();

  return db.runTransaction(async (transaction) => {
    const chatRef = db.collection("chats").doc(chatId);
    const userRef = db.collection("users").doc(uid);
    const participantRef = db.collection("chatParticipants").doc(`${chatId}_${uid}`);

    const [chatDoc, userDoc, participantDoc] = await Promise.all([
      transaction.get(chatRef),
      transaction.get(userRef),
      transaction.get(participantRef),
    ]);

    const chatData = chatDoc.data();
    if (!chatDoc.exists || !chatData) {
      throw new HttpsError("not-found", "Chat not found.");
    }

    const pingId = chatData.pingId as string | undefined;
    if (!pingId) {
      throw new HttpsError("failed-precondition", "Chat ping is missing.");
    }

    const pingRef = db.collection("pings").doc(pingId);
    const pingDoc = await transaction.get(pingRef);
    const pingData = pingDoc.data();
    if (!pingDoc.exists || !pingData) {
      throw new HttpsError("not-found", "Ping not found.");
    }

    assertNotSuspended(userDoc);
    assertActivePing(pingData);

    const creatorId = pingData.creatorId as string | undefined;
    if (!creatorId) {
      throw new HttpsError("failed-precondition", "Ping creator is missing.");
    }

    const isBlocked = await hasBlockingRelationshipInTransaction(transaction, db, uid, creatorId);
    if (isBlocked) {
      throw new HttpsError("permission-denied", "Cannot join this chat.");
    }

    const currentChatCount = numberValue(chatData.participantCount);
    const participantData = participantDoc.data();
    const participantIsActive = participantDoc.exists && participantData?.leftAt === undefined;
    if (participantIsActive) {
      return {
        participantId: participantRef.id,
        participantCount: currentChatCount,
      };
    }

    const currentPingCount = numberValue(pingData.participantCount);
    const nextChatCount = currentChatCount + 1;
    const nextPingCount = currentPingCount + 1;

    if (participantDoc.exists) {
      transaction.update(participantRef, {
        joinedAt: FieldValue.serverTimestamp(),
        leftAt: FieldValue.delete(),
      });
    } else {
      transaction.create(participantRef, {
        chatId,
        userId: uid,
        joinedAt: FieldValue.serverTimestamp(),
      });
    }

    transaction.update(chatRef, { participantCount: nextChatCount });
    transaction.update(pingRef, { participantCount: nextPingCount });

    return {
      participantId: participantRef.id,
      participantCount: nextChatCount,
    };
  });
});

export const leaveChat = onCall({ region: "europe-west3" }, async (request) => {
  const uid = requireAuthUid(request);
  const chatId = requireString(requireData(request.data), "chatId");
  const db = getFirestore();

  return db.runTransaction(async (transaction) => {
    const chatRef = db.collection("chats").doc(chatId);
    const participantRef = db.collection("chatParticipants").doc(`${chatId}_${uid}`);

    const [chatDoc, participantDoc] = await Promise.all([
      transaction.get(chatRef),
      transaction.get(participantRef),
    ]);

    const chatData = chatDoc.data();
    if (!chatDoc.exists || !chatData) {
      return { participantCount: 0 };
    }

    const currentChatCount = numberValue(chatData.participantCount);
    const participantData = participantDoc.data();
    const participantIsActive = participantDoc.exists && participantData?.leftAt === undefined;
    if (!participantIsActive) {
      return { participantCount: currentChatCount };
    }

    const pingId = chatData.pingId as string | undefined;
    const pingRef = pingId ? db.collection("pings").doc(pingId) : undefined;
    const pingDoc = pingRef ? await transaction.get(pingRef) : undefined;
    const pingData = pingDoc?.data();

    const nextChatCount = Math.max(currentChatCount - 1, 0);
    transaction.update(participantRef, { leftAt: FieldValue.serverTimestamp() });
    transaction.update(chatRef, { participantCount: nextChatCount });

    if (pingRef && pingDoc?.exists && pingData) {
      const nextPingCount = Math.max(numberValue(pingData.participantCount) - 1, 0);
      transaction.update(pingRef, { participantCount: nextPingCount });
    }

    return { participantCount: nextChatCount };
  });
});
