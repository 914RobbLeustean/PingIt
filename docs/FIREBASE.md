# Firebase Reference

## Project Setup

```bash
npm install -g firebase-tools
firebase login
firebase init  # Select: Firestore, Functions, Storage, Hosting as needed
npm --prefix functions install
```

## Deploy

Build Functions before deploying:

```bash
npm --prefix functions run build
firebase deploy --only functions,firestore:rules --project pingit-dev
```

Deploy only Functions:

```bash
firebase deploy --only functions --project pingit-dev
```

Deploy only Firestore rules:

```bash
firebase deploy --only firestore:rules --project pingit-dev
```

## Firestore Security Rules

See `firestore.rules` in the project root.

**Current posture:** The iOS client can create/read the data it owns, but destructive operations, counters, duplicate report prevention, and chat participant transitions are server-authoritative through Cloud Functions.

| Collection | Client read | Client create | Client update | Client delete | Notes |
|---|---|---|---|---|---|
| `users` | Authenticated `get`; no `list` | Owner only, requires username reservation | Owner only for safe profile/preference fields | Denied | Client cannot edit `email`, `createdAt`, `suspensionStatus`, or `suspensionExpiresAt`. Safe fields include `hasCompletedOnboarding`. |
| `usernames` | Public `get`; no `list` | Signed-in owner only | Denied | Owner can delete old reservation during rename | Used for username availability without public user listing. |
| `pings` | Authenticated | Creator only, active status, zero counters, valid expiry, optional `imageUrl` string, optional `category` string | Denied | Denied | Delete and counter changes use callables. `imageUrl` and `category` validated as string if present. |
| `chats` | Authenticated | Valid ping creation flow only | Denied | Denied | Participant counts are server-owned. |
| `chatMessages` | Authenticated | Sender only, active ping, moderation flag false or absent, optional location fields | `safeReactionUpdate()`: only `reactions` field modifiable by any signed-in non-suspended user | Denied | Message sends remain client-side. Location messages validated: `messageType`, `latitude`, `longitude`, `locationName` allowed in create. |
| `chatParticipants` | Denied | Denied | Denied | Denied | `joinChat` / `leaveChat` own this collection. |
| `boosts` | Current user's own boost state only | Denied | Denied | Denied | `boostPing` owns boost creation and `pings.boostCount`. |
| `blocks` | Authenticated | Blocker only | Denied | Blocker only | Used for bidirectional filtering and server validation. |
| `reports` | Denied | Denied | Denied | Denied | `submitReport` callable owns report creation and duplicate checks. |
| `moderationActions` | Denied | Denied | Denied | Denied | Admin SDK writes audit records. |

## Username Reservations

Username availability is backed by `usernames/{normalizedUsername}` documents:

```json
{
  "userId": "firebase-auth-uid",
  "createdAt": "<server timestamp>"
}
```

New signup and profile rename flows write the reservation and the `users/{uid}` profile in the same batch. Existing production users created before this collection existed need a one-time backfill so their usernames are reserved before strict rules are deployed to all clients.

Migration outline:

1. Export or query all `users` documents that have `usernameLowercase`.
2. For each user, create `usernames/{usernameLowercase}` with `{ userId, createdAt }` if missing.
3. If a reservation already exists for a different `userId`, resolve the duplicate manually before allowing renames.
4. Deploy rules after the backfill is complete.

## Reports

Report submissions use the `submitReport` callable, not direct Firestore writes. Report IDs are deterministic:

```text
reports/{reporterId}_{targetId}
```

Submitting the same target twice returns Firebase Functions `already-exists`, which iOS maps to `PingItError.reportAlreadySubmitted` so the user sees "You have already reported this content."

## Required Firestore Composite Indexes

Firestore requires composite indexes for queries that filter on multiple fields or combine `where` with `orderBy`. Single-field queries are auto-indexed.

**Current required indexes:**

| Collection | Fields | Used by |
|---|---|---|
| `pings` | `status` ASC, `expiresAt` ASC | `expirePings` scheduled cleanup |
| `boosts` | `pingId` ASC, `userId` ASC | `PingService.hasUserBoostedPing` |
| `blocks` | `blockerId` ASC, `blockedUserId` ASC | `BlockService.blockUser`, `boostPing`, `joinChat` |
| `chatMessages` | `chatId` ASC, `createdAt` DESC | `ChatService.fetchMessages` pagination |
| `chatMessages` | `chatId` ASC, `createdAt` ASC | `ChatService.observeNewMessages` realtime tail listener |

No composite index is required for duplicate reports anymore because `submitReport` uses deterministic report document IDs. Existing old indexes can be kept, but they are no longer required for the current code.

> IMPORTANT for AI agents: Any new Firestore query that uses multiple `whereField` clauses, or combines `whereField` with `order(by:)` on a different field, requires a composite index. After implementing such a query:
> 1. Add the required index to this table.
> 2. Tell the user to create it in Firebase Console -> Firestore -> Indexes, or provide the auto-create URL from the Firestore error.
> 3. Deploy via `firebase deploy --only firestore:indexes` if using `firestore.indexes.json`, or create it manually in Console.

## Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId && request.resource.size < 5 * 1024 * 1024;
    }
    match /ping_images/{pingId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 10 * 1024 * 1024;
    }
  }
}
```

## Cloud Functions

All callable Functions are in `europe-west3`.

| Function | Type | Responsibility |
|---|---|---|
| `healthCheck` | HTTP | Deployment sanity check. |
| `expirePings` | Scheduled | Marks expired pings and cleans chats, messages, participants, and boosts. |
| `deletePing` | Callable | Creator-only ping removal with backend cascade cleanup. |
| `boostPing` | Callable | Validates user/ping/block state, creates deterministic boost, increments `boostCount`. |
| `joinChat` | Callable | Validates chat/ping/user/block state, creates or reactivates deterministic participant, increments counts once. |
| `leaveChat` | Callable | Idempotently marks participant left and decrements chat/ping counts once. |
| `submitReport` | Callable | Creates deterministic report, rejects duplicates with `already-exists`. |
| `deleteAccount` | Callable | Cascading GDPR delete of user data, username reservation, profile image, and Auth account. |
| `removeContent` | Callable | Admin-only emergency removal/suspension with audit trail. |
| `sendNearbyNotification` | Firestore trigger | Sends nearby ping notifications, respecting preferences and blocks. |
| `sendHotPingNotificationOnBoost` | Firestore trigger | Rechecks hot status after boost creation. |
| `sendHotPingNotificationOnJoin` | Firestore trigger | Rechecks hot status after participant creation/reactivation. |
| `moderateImage` | Storage trigger | Vision API SafeSearch moderation for profile and ping images. |
| `exportUserData` | Callable | GDPR data export — collects all user data and returns JSON. |

Shared cleanup logic lives in `functions/src/pingCleanup.ts` and is used by ping deletion, expiration, moderation removal, and account deletion paths.

## iOS SPM Dependencies (from firebase-ios-sdk v12.11.0)

| Product | Purpose |
|---------|---------|
| FirebaseAuth | Authentication |
| FirebaseFirestore | Cloud Firestore data layer |
| FirebaseStorage | Profile image uploads |
| FirebaseDatabase | Server time offset (`.info/serverTimeOffset`) |
| FirebaseFunctions | Callable functions (delete, boost, join/leave, report) |
| FirebaseMessaging | FCM push notifications |
| FirebaseAnalytics | Event logging (ping_created, chat_joined, boost_used, onboarding_completed) |
| FirebaseCrashlytics | Crash and non-fatal error reporting |
| FirebasePerformance | App startup, network request, and custom trace metrics |

## Rate Limiting

- **Client-side:** `RateLimitService` checks timestamps in UserDefaults and shows an error before server calls.
- **Server-side:** Not implemented yet for ping/message spam. Server callables do enforce auth, suspension, active ping state, ownership, duplicate prevention, and block relationships where relevant.
- **Limits:** 5 pings/hour, 10 pings/day, 6 messages/10sec.

## Monitoring

- Firestore usage: Firebase Console -> Usage (set alert at $20/month)
- Function logs: `firebase functions:log --only expirePings --project pingit-dev`
- Performance: Firebase Console -> Performance

## Emulators

```bash
firebase emulators:start
# Firestore: localhost:8080, Auth: localhost:9099, Functions: localhost:5001
```

## Environment Variables

```bash
firebase functions:config:set vision.api_key="YOUR_KEY"
firebase functions:config:set admin.emails="admin@example.com"
```
