# Bug-fixing Changelog — branch `final-fixes`

Fixes from the investor-demo / App Store launch audit. Each entry: issue, root cause, fix, verification.

---

## #1 — Recap ghost markers used device clock instead of server time
- **Severity:** showstopper (visual, on map)
- **File:** `PingIt/Core/Services/PingRecapService.swift:13`
- **Root cause:** `observeActiveRecaps` filtered `ghostExpiresAt > Date.now`. The rest of the app uses `ServerTime.now` (RTDB server-offset corrected). On a device with clock skew, recap 📸 markers appear/disappear at the wrong time.
- **Fix:** `Date.now` → `ServerTime.now`. (Same module, no import needed.)
- **Verified:** app builds + launches; matches `MapViewModel.applyRecapFilter` which already uses `ServerTime.now`.

## #2 — Block relationships world-readable
- **Severity:** major (security)
- **File:** `firestore.rules` (`match /blocks/{blockId}`)
- **Root cause:** `allow read: if signedIn()` let any authed user read every block, leaking the social graph.
- **Fix:** restrict read to the two parties: `blockerId == uid || blockedUserId == uid`.
- **Verified:** every `blocks` read in `BlockService.swift` is filtered by `blockerId == me` or `blockedUserId == me`, so each satisfies one rule branch — no client query breaks. (Not yet deployed; deploy with `firebase deploy --only firestore:rules`.)

## #3 — Recap reads world-readable — INTENTIONALLY SKIPPED
- **Decision:** left `pingRecaps` read as `signedIn()`.
- **Why:** the map's recap listener queries ALL recaps with no attendee/photo filter. Firestore fails the whole `list` query if any returned doc violates a read rule, so an "attendees-or-photoCount>0" rule would break ghost markers for non-attendees — the exact "view what RSVPers uploaded" feature. Recap docs are low-sensitivity (title, location, attendeeIds, counts). Tightening requires a client-query change + index; deferred.

## #4 — Hardcoded Storage bucket in moderateImage trigger
- **Severity:** major (config / portability)
- **File:** `functions/src/moderateImage.ts:9`
- **Root cause:** `bucket: "pingit-dev.firebasestorage.app"` in the trigger config; the trigger silently never fires if deployed to a project with a different bucket.
- **Fix:** removed the `bucket` param so it binds to the project default. Handler already reads `event.data.bucket` for the file path.
- **Verified:** `tsc` build passes (exit 0).

## #5 — Suspension wrote plain Date instead of Timestamp
- **Severity:** minor (data consistency)
- **File:** `functions/src/removeContent.ts`
- **Root cause:** `suspensionExpiresAt: new Date(...)` and audit `timestamp: new Date()` wrote JS Dates, inconsistent with the rest of the codebase.
- **Fix:** `suspensionExpiresAt` → `Timestamp.fromDate(...)`; audit `timestamp` → `FieldValue.serverTimestamp()`. Added imports.
- **Verified:** `tsc` build passes.

## #6 — RSVP & Boost buttons had no loading indicator
- **Severity:** minor (UX polish, very visible)
- **File:** `PingIt/Features/Ping/Views/PingDetailView.swift`
- **Root cause:** buttons disabled during the async call but showed no spinner — felt unresponsive.
- **Fix:** threaded `isBoosting` (DetailStatsCard → DetailBoostButton) and `isTogglingRSVP` (→ DetailRSVPButton). Each shows a `ProgressView` in place of its icon while in flight. VM already exposed both flags.
- **Verified:** app builds + launches.

## #7 — Recap notification opened the wrong screen
- **Severity:** showstopper (breaks recap flow end-to-end)
- **File:** `PingIt/Core/Services/NotificationService.swift`
- **Root cause:** backend sends `type: "recap_invite"` (expirePings.ts) on ping expiry, but `didReceive` only special-cased `followed_recap_photo` — `recap_invite` fell through to "open ping", trying to open an expired/unavailable ping.
- **Fix:** `switch` on type; both `recap_invite` and `followed_recap_photo` post `PingItOpenRecap` with `recapId: pingId` (recap doc id == ping id).
- **Verified:** app builds + launches.

## #8 — FCM token not re-registered on re-login
- **Severity:** major
- **File:** `PingIt/App/PingItApp.swift`
- **Root cause:** token registration lived only in the launch `.task` (runs once). After sign-out/sign-in, the token still pointed at the old uid → notifications routed to the wrong/old account.
- **Fix:** re-register the token in the existing `onChange(of: authService.currentUser?.uid)` when a new uid appears. Left the permission prompt in the one-time `.task` so it doesn't re-prompt.
- **Verified:** app builds + launches.

## #9 — FCM token write could silently fail on a fresh account
- **Severity:** major (mitigated)
- **File:** `PingIt/Core/Services/NotificationService.swift`
- **Root cause:** `updateData(["fcmToken": ...])` throws NOT_FOUND if the user doc doesn't exist yet (token-refresh race during fresh sign-up), swallowed by `try?` → token dropped.
- **Fix:** `updateData` → `setData(["fcmToken": token], merge: true)` — upserts instead of failing.
- **Verified:** app builds + launches.

## #10 — Missing Cloud Storage security rules
- **Severity:** showstopper (security) — App Store launch blocker
- **Files:** `storage.rules` (new), `firebase.json`
- **Root cause:** no `storage.rules` file and no `"storage"` block in `firebase.json` — the bucket had zero access control. Any authenticated user could read, overwrite, or delete any file (other users' profile pictures, ping images, recap photos).
- **Fix:** added `storage.rules` (rules_version 2, deny-by-default) and wired `"storage": { "rules": "storage.rules" }` into `firebase.json`. Scoped writes:
  - `profile_pictures/{userId}/{file}` — write only if `request.auth.uid == userId`.
  - `ping_images/{pingId}/{file}` — write requires auth (ping ownership enforced on the Firestore ping doc).
  - `recap_photos/{recapId}/{file}` — write requires auth (attendee + submission-window enforced on the Firestore recap-photo doc).
  - All writes constrained to `contentType` `image/.*` and size < 10 MB. Reads are public (app shows images to all users via tokenized download URLs, which bypass rules anyway). Everything else denied.
- **Note:** Storage rules can't cheaply query Firestore, so per-ping/per-attendee ownership stays on the existing Firestore document write rules. The `moderateImage` Cloud Function uses the Admin SDK and bypasses Storage rules — unaffected.
- **Verified:** `firebase deploy --only storage --project pingit-dev` → rules compiled and released successfully. All four upload/delete paths in `ImageStorageService`, `PingService.uploadPingImage`, and `PingRecapService.submitRecapPhoto` (all `image/jpeg`, signed in, owner-scoped where applicable) satisfy the rules — no legitimate upload locked out.

## #12 — Chats & messages world-readable
- **Severity:** major (security/privacy) — App Store launch concern
- **Files:** `firestore.rules`, `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`, `PingIt/Features/Chat/Views/ChatView.swift`
- **Root cause:** `chats` and `chatMessages` had `allow read: if signedIn()` — any authenticated user could read every chat and message in the app, not just chats they had joined.
- **Fix:**
  - Added a `isActiveChatMember(chatId)` rules helper that checks the deterministic membership doc `chatParticipants/{chatId}_{uid}` exists with no `leftAt` (active member). `joinChat` creates this doc and clears `leftAt` on rejoin; `leaveChat` sets `leftAt` (never deletes), so a returning user is re-activated and still sees full history.
  - `chats` read → `isActiveChatMember(chatId)`; `chatMessages` read → `isActiveChatMember(resource.data.chatId)` (evaluated per returned doc for `where chatId ==` list queries).
  - **Client reorder:** `ChatView.task` now `joinChat()` **before** `loadInitialMessages()` — the read rule rejects non-members, so membership must exist first. `joinChat()` returns `Bool`; messages load only if the join succeeded. The loading spinner now covers the join round-trip so opening a chat doesn't flash the empty state.
- **Why active-member (not ever-joined):** tightest rule, and because rejoin clears `leftAt`, users who reopen a chat are re-activated and see all past messages — no user-visible difference, strictly better privacy. The only blocked window is while the chat screen is closed (when the user isn't looking anyway).
- **Note:** `chatMessages` list rules do an `exists()`/`get()` per returned doc (billed as reads) — modest at 50 msgs/page.
- **Verified:** `firebase deploy --only firestore:rules --project pingit-dev --dry-run` compiled; deployed to pingit-dev; app target **BUILD SUCCEEDED** (iPhone 17 simulator). On-device chat open/send verification pending (test target VPN-blocked locally).

---

## Feature — Recap markers: toggle + zoom gating
- **File:** `PingIt/Features/Map/ViewModels/MapViewModel.swift`, `PingIt/Features/Map/Views/MapView.swift`
- **What:** Recap (📸) ghost markers are now a user toggle (`MapRecapsButton` in `MapHeader`, photo icon, same styling as the heatmap button), **on by default**. They render only when zoomed in close (`visibleRegion.span.latitudeDelta < 0.02`) so they stop overlapping active ping pins at wider zoom.
- **How:** `isRecapsEnabled` (default true, in-memory — resets ON each launch, matching the heatmap toggle) + `toggleRecaps()`. `applyRecapFilter()` now early-returns empty unless enabled AND zoomed in. `visibleRegion` got a `didSet { applyRecapFilter() }` so panning/zooming re-evaluates the gate.
- **Zoomed-out behavior:** markers simply hidden (no hint pill). Toggle OFF hides regardless of zoom.
- **No backend impact:** pure client render/filter; no new Firestore reads or indexes.
- **Tests:** `PingItTests/ViewModelTests/MapViewModelTests.swift` — 3 cases (visible when on+zoomed-in, hidden when zoomed out, toggle off/on). NOT run locally (test target blocked by VPN on this machine); app target builds clean.

## Build/verification status
- Swift app: **BUILD SUCCEEDED** (iPhone 17 simulator, Xcode 26.2); launches clean, welcome screen renders, notification prompt fires.
- Cloud Functions: `npm run build` (tsc) **exit 0**.
- **Not yet deployed:** `firestore.rules` (#2) and functions (#4, #5) — deploy before relying on them:
  - `firebase deploy --only firestore:rules`
  - `cd functions && npm run build && cd .. && firebase deploy --only functions`
- **Deployed:** Cloud Storage rules (#10) — `firebase deploy --only storage --project pingit-dev` (released to pingit-dev).
