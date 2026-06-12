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

---

## Build/verification status
- Swift app: **BUILD SUCCEEDED** (iPhone 17 simulator, Xcode 26.2); launches clean, welcome screen renders, notification prompt fires.
- Cloud Functions: `npm run build` (tsc) **exit 0**.
- **Not yet deployed:** `firestore.rules` (#2) and functions (#4, #5) — deploy before relying on them:
  - `firebase deploy --only firestore:rules`
  - `cd functions && npm run build && cd .. && firebase deploy --only functions`
