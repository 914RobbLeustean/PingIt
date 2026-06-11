import { getStorage } from "firebase-admin/storage";

const MAX_BATCH_WRITES = 450;

export class ChunkedWriteBatch {
  private batch: FirebaseFirestore.WriteBatch;
  private operationCount = 0;

  constructor(private readonly db: FirebaseFirestore.Firestore) {
    this.batch = db.batch();
  }

  async update(
    ref: FirebaseFirestore.DocumentReference,
    data: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>
  ): Promise<void> {
    this.batch.update(ref, data);
    await this.recordOperation();
  }

  async delete(ref: FirebaseFirestore.DocumentReference): Promise<void> {
    this.batch.delete(ref);
    await this.recordOperation();
  }

  async commit(): Promise<void> {
    if (this.operationCount === 0) {
      return;
    }

    await this.batch.commit();
    this.batch = this.db.batch();
    this.operationCount = 0;
  }

  private async recordOperation(): Promise<void> {
    this.operationCount += 1;
    if (this.operationCount >= MAX_BATCH_WRITES) {
      await this.commit();
    }
  }
}

export interface PingCleanupOptions {
  status?: "expired" | "removed";
  deletePing?: boolean;
}

export async function cleanupPing(
  db: FirebaseFirestore.Firestore,
  pingDoc: FirebaseFirestore.DocumentSnapshot,
  options: PingCleanupOptions
): Promise<void> {
  const pingData = pingDoc.data();
  if (!pingDoc.exists || !pingData) {
    return;
  }

  const writer = new ChunkedWriteBatch(db);
  const pingRef = pingDoc.ref;

  if (options.deletePing === true) {
    await writer.delete(pingRef);
  } else if (options.status) {
    await writer.update(pingRef, { status: options.status });
  }

  const chatIds = new Set<string>();
  const storedChatId = pingData.chatId;
  if (typeof storedChatId === "string" && storedChatId.length > 0) {
    chatIds.add(storedChatId);
  }

  const chatsSnapshot = await db
    .collection("chats")
    .where("pingId", "==", pingDoc.id)
    .get();

  for (const chatDoc of chatsSnapshot.docs) {
    chatIds.add(chatDoc.id);
  }

  for (const chatId of chatIds) {
    await deleteChatChildren(db, writer, chatId);
    await writer.delete(db.collection("chats").doc(chatId));
  }

  const boostsSnapshot = await db
    .collection("boosts")
    .where("pingId", "==", pingDoc.id)
    .get();

  for (const boostDoc of boostsSnapshot.docs) {
    await writer.delete(boostDoc.ref);
  }

  const rsvpsSnapshot = await db
    .collection("rsvps")
    .where("pingId", "==", pingDoc.id)
    .get();

  for (const rsvpDoc of rsvpsSnapshot.docs) {
    await writer.delete(rsvpDoc.ref);
  }

  await writer.commit();

  if (typeof pingData.imageUrl === "string" && pingData.imageUrl.length > 0) {
    try {
      const bucket = getStorage().bucket();
      await bucket.deleteFiles({ prefix: `ping_images/${pingDoc.id}/` });
    } catch (error) {
      console.warn(`Failed to delete ping images for ${pingDoc.id}:`, error);
    }
  }
}

async function deleteChatChildren(
  db: FirebaseFirestore.Firestore,
  writer: ChunkedWriteBatch,
  chatId: string
): Promise<void> {
  const messagesSnapshot = await db
    .collection("chatMessages")
    .where("chatId", "==", chatId)
    .get();

  for (const messageDoc of messagesSnapshot.docs) {
    await writer.delete(messageDoc.ref);
  }

  const participantsSnapshot = await db
    .collection("chatParticipants")
    .where("chatId", "==", chatId)
    .get();

  for (const participantDoc of participantsSnapshot.docs) {
    await writer.delete(participantDoc.ref);
  }
}
