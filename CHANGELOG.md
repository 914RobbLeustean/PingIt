# Changelog

All notable changes to PingIt are documented here. Updated after every implementation session.

Format: `[YYYY-MM-DD] — Summary of changes`

---

## [2026-06-12] — Launch-audit fixes (branch `final-fixes`)

Fixes from the App Store launch audit. Full per-issue detail in `bug-fixing/final-fixes/CHANGELOG.md`.

### Fixed — Recap & notifications
- **Recap ghost markers now use server time.** `PingRecapService.observeActiveRecaps` filtered `ghostExpiresAt` against `Date.now`; switched to `ServerTime.now` so markers appear/expire consistently across devices with clock skew.
- **Recap invite notifications route correctly.** Tapping the `recap_invite` push (sent by `expirePings` when a ping ends) now opens the recap instead of the expired ping. `NotificationService.didReceive` switches on `type` and routes both `recap_invite` and `followed_recap_photo` to `PingItOpenRecap`.

### Fixed — Push notification registration
- **FCM token re-registers on account change.** Token registration moved into `onChange(of: authService.currentUser?.uid)` (was only in the one-time launch `.task`), so after sign-out/sign-in the token follows the current account. Permission prompt stays one-time.
- **FCM token write no longer silently dropped on fresh accounts.** `registerFCMToken` uses `setData(merge:)` instead of `updateData`, which threw NOT_FOUND (swallowed by `try?`) when the token arrived before the user doc existed.

### Fixed — Security rules
- **Block relationships are now private.** `firestore.rules` restricts `blocks` reads to the blocker or blocked party (was any signed-in user). All client block queries are already filtered to satisfy the rule. *(Deploy: `firebase deploy --only firestore:rules`.)*

### Fixed — Cloud Functions
- **moderateImage trigger binds to the default bucket.** Removed the hardcoded `pingit-dev.firebasestorage.app` bucket from the trigger config so it works across projects/environments.
- **Suspension timestamps are Firestore Timestamps.** `removeContent` writes `suspensionExpiresAt` via `Timestamp.fromDate` and the audit `timestamp` via `serverTimestamp()` (were plain JS `Date`s).

### UX
- **RSVP and Boost buttons show a loading spinner** while the call is in flight (Ping Detail), replacing the icon with a `ProgressView` instead of just disabling the button.

### Notes
- Intentionally **not** changed: `pingRecaps` read rule stays `signedIn()`. Tightening it would break the map's unfiltered recap listener (Firestore fails the whole list query on any rule-violating doc) and thus the public ghost-marker feature. Recap docs are low-sensitivity. Revisit with a client-query + index change.

---

## [2026-06-11] — Deep links, RSVP + recaps, Social tab, heatmap, ping editing, launch experience

### Added — Deep Link Sharing
- `Core/Utilities/DeepLink.swift`: parses `pingit://ping/{id}` and `https://pingit-dev.web.app/ping/{id}`; `shareURL(forPingId:)` builds share links.
- Share button on Ping Detail via `ShareLink(item: url.absoluteString)` — shared as a plain String because URL items hit a pasteboard quirk that yields binary-plist garbage on "Copy".
- `public/ping/index.html` + `public/index.html`: dark-themed hosted fallback page ("Open in PingIt" fires the custom scheme); `firebase.json` hosting block with `/ping/**` rewrite.
- `Info.plist`: `CFBundleURLTypes` registers the `pingit` scheme; `.onOpenURL` in `PingItApp` routes to the ping.

### Added — RSVP System
- `rsvps/{pingId}_{userId}` collection (deterministic IDs, like boosts); `rsvpPing` callable toggles attendance with suspension/block/active checks and `FieldValue.increment` counter sync.
- `Ping.rsvpCount` (optional for backward compat) + `attendingCount`; "I'm Going" capsule on Ping Detail, "N going" counts on map sheet and feed cards — all live via existing listeners.
- RSVP cleanup wired into `pingCleanup.ts` and `deleteAccount.ts`.

### Added — Post-Event Story Recaps
- `expirePings.ts` now creates `pingRecaps/{pingId}` from RSVPs at expiry (`attendeeIds`), notifies attendees, and GCs expired recaps (`cleanupRecaps.ts`: docs + photos subcollection + Storage files after `ghostExpiresAt`).
- `Features/Recap/`: ghost 📸 map annotation (24h), `RecapStorySheet` photo carousel, `PhotosPicker` submission (max 3/user, 2h window), `RecapStoryViewModel`.
- `recapTriggers.ts`: `onRecapPhotoCreated` maintains `photoCount`; `moderateImage.ts` extended to recap photos (transactional flag + counter decrement).
- Empty recaps are hidden from non-attendees (`PingRecap.isVisibleOnMap(to:)`) so the map never shows hollow ghosts.

### Added — Social Tab (follow system)
- New 5th tab: debounced username search (500ms), follow/unfollow pills, Following list, read-only `UserProfileView` (stats, follow button, report/block).
- `socialCallables.ts`: `toggleFollow` (transactional edge + counters, rejects private targets), `searchUsers` (prefix query on `usernameLowercase`, public profiles only, composite index in new `firestore.indexes.json`).
- `followNotifications.ts`: 4 push triggers (new follower / ping created / RSVP / recap photo), all respecting `notifyFollowActivity`, privacy dormancy, and bidirectional blocks.
- `blockTriggers.ts`: `severFollowsOnBlock` deletes both follow edges and fixes all four counters.
- Going private = dormant follows (hidden from search, muted notifications, "Gone private" rows); `deleteAccount.ts` cleans follow edges both directions.
- Live follower count on own Profile tab via `observeUser` listener; `notifyFollowActivity` toggle in Settings.

### Added — Map Heatmap Overlay
- Flame toggle in map header renders 7-day activity blobs (`MapCircle` core + halo per cell), amber→red by intensity.
- `Features/Map/Models/HeatCell.swift`: ~130m grid bucketing, weight = recency factor (1.0→0.25 over 7d) × boost multiplier, normalized; 30-min cache in `MapViewModel`.

### Added — Ping Editing (creator-only, live)
- `updatePing` callable mirrors the boost/rsvp transaction pattern (auth, suspension, active, creator checks; length + category whitelist validation; `editedAt` stamp; clearing description deletes the field).
- Pencil button in Ping Detail nav bar (owner only) opens `EditPingView` reusing the create-flow text/description/category sections; `EditPingViewModel` mirrors create validation incl. moderation wordlist; Save gated on actual changes.
- "· edited" marker in the detail author row; `Ping.==` now includes `category`/`editedAt` so category-only edits propagate through map-sheet sync and detail listeners.

### Added — Image caching
- `Core/Utilities/ImageCache.swift`: 50MB `NSCache` keyed by URL; `CachedAsyncImage.swift`: drop-in `AsyncImage` replacement that checks the cache synchronously in `body` — cached avatars render on the first frame with zero placeholder flash.
- All 7 avatar sites converted (social rows, map sheet, detail, feed, chat bubbles, profile, blocked users); `RetryableAsyncImage` rewritten on the same cache for ping/recap photos (3-attempt retry kept). `URLSession` `.returnCacheDataElseLoad` adds disk persistence across launches.

### Added — Launch experience
- `LaunchScreen.storyboard` rebuilt: brand amber ping dot as a pre-rendered `LaunchDot` imageset (launch storyboards render neither custom fonts nor runtime attributes — the old Syne wordmark silently fell back to system font).
- `App/SplashView.swift`: animated splash whose first frame matches the storyboard pixel-for-pixel; radar rings (single-shot — repeatForever popped a bright ring mid-fade), wordmark + tagline reveal, then a 0.55s fade with 1.08× scale into the already-loaded app. Honors Reduce Motion.

### Fixed
- `Ping.hotScore` now uses `ServerTime.now` instead of the device clock, matching every other time computation.
- Live updates: RSVP/boost/participant counters update live on Ping Detail (full ping merge in `startObservingPing`), map sheet syncs with the listener (`syncSheetPing`), follower count ticks live on Profile.
- Anonymous identity leak: private creators' real avatars no longer flash on the map sheet, feed cards, or Social Following rows (components receive `nil` creator when identity is hidden).
- Blocked users vanish live from Social search results, the Following list, and recap photo carousels (`applyBlockFilter` driven by `BlockService.blockedUserIds` — both block directions); in-flight fetches are filtered on arrival. Map/feed/chat already live-filtered.
- Chat "query requires an index": added `chatMessages (chatId, createdAt)` composite indexes (both sort orders) to `firestore.indexes.json`.
- Map alert chips (empty state, location off, connection issue) are now dismissable with an X and stay dismissed for the session; a new error re-surfaces the connection chip. Fixes the empty-state chip overlapping the heatmap toggle.
- Shared scheme `TestAction` build configuration corrected Release → Debug so `@testable import PingIt` resolves.

### Security/Rules
- New rules: `rsvps`, `follows` (own outgoing edges readable), `pingRecaps` + nested `photos` (attendee-gated submission window); `safeUserUpdate` allows `notifyFollowActivity`; `safePingCreate` allows `rsvpCount` (must be 0). Ping updates remain client-forbidden — edits go through the callable.
- Ops note: newly created v2 callables may deploy without public invoker permission (clients see `UNAUTHENTICATED`); fix via `gcloud functions add-invoker-policy-binding`.

### Tests
- 192 → 262 tests; new suites: `EditPingViewModelTests` (13), `DeepLinkTests` (11), `PingRecapTests` (11), `SocialViewModelTests` (10), `HeatCellTests` (10), `UserProfileViewModelTests` (7), `ImageCacheTests` (4); new mocks: `MockFollowService`, `MockPingRecapService`.

---

## [2026-06-01] — Stability fixes: empty chat crash, onboarding loop, missing user doc

### Fixed
- `Features/Chat/ViewModels/ChatViewModel.swift`: empty chats no longer crash on entry. The live-reactions cursor fell back to `Date.distantPast` when no messages were loaded; Firebase `Timestamp(date:)` overflows on that value (`-62135769600` seconds) and throws an uncaught `NSException` ("Invalid timestamp: Timestamp seconds out of range"), freezing the app on the map → chat transition. Fall back to `Date.now` instead.
- `Features/Chat/Views/ChatView.swift`: `leaveChat` in `onDisappear` previously hopped back to `MainActor` for a Cloud Function call, which could block app termination on slow networks and trigger a SIGKILL watchdog kill (`0x8BADF00D`). Now runs as a background-priority detached task wrapped in a 5-second `TaskGroup` timeout, so the OS can reclaim the process cleanly even if the call hangs.
- `Features/Chat/Views/Components/ChatBubbleShape.swift`: returns an empty path for zero-sized rects and clamps every corner radius to a non-negative cap, eliminating invalid `addArc` parameters during transient layout passes.
- `Features/Ping/Views/PingDetailView.swift`: the ping-unavailable auto-dismiss task no longer fires when `navigateToChat` is true. Previously it could pop `PingDetailView` while the user was inside the pushed `ChatView`, tearing both screens down at once.

### Changed (onboarding resilience)
- `Features/Onboarding/ViewModels/OnboardingViewModel.swift`: errors from the completion write now surface to the UI instead of being silently swallowed. Adds `isSubmitting`, `errorMessage`, and `forceLocalComplete()` for a "Continue Anyway" escape hatch.
- `Features/Onboarding/Views/OnboardingView.swift`: shows a red `OnboardingErrorCard` with a "Continue Anyway" pill when the completion write fails. Primary button shows a `ProgressView` while submitting and disables Skip during the write.
- `Core/Protocols/UserServicing.swift` + `Core/Services/UserService.swift`: added `mergeUser(id:data:)` using `setData(merge: true)` (creates the doc if missing) and `ensureUserProfileExists(uid:email:)` which atomically backfills a placeholder user doc (`user_<uid-prefix>`) + username reservation when the Auth user exists but the Firestore doc does not.
- `App/RootView.swift`: when `fetchUser` fails (e.g. orphan Auth account from a partially-failed signup), now falls through to `ensureUserProfileExists` so any broken account self-heals on the next launch.
- `Features/Onboarding/ViewModels/OnboardingViewModel.swift`: now writes via `mergeUser` instead of `updateUser` so the flag write succeeds whether the doc exists or not.

### Added
- `Features/Feed/Views/PingFeedCardView.swift`: `CreatorAvatar` now loads `profileImageUrl` via `AsyncImage` with the colored-initial circle as the fallback. Previously it ignored the URL entirely, so feed cards never showed real profile photos.

### Files significantly modified
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`
- `PingIt/Features/Chat/Views/Components/ChatBubbleShape.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingIt/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- `PingIt/Features/Onboarding/Views/OnboardingView.swift`
- `PingIt/Core/Protocols/UserServicing.swift`
- `PingIt/Core/Services/UserService.swift`
- `PingIt/App/RootView.swift`
- `PingIt/Features/Feed/Views/PingFeedCardView.swift`
- `PingItTests/Mocks/MockUserService.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Audit sweep: SuspendedAccountView, PasswordStrengthView, Ping Unavailable toasts

### Changed
- `Features/Authentication/Views/SuspendedAccountView.swift`: full redesign. Dark `pingBackground`, an exclamation hero with two concentric `pingHot` rings + glow, Syne ExtraBold 26pt title, DM Sans body on `pingTextPrimary` and a contact line on `pingTextSecondary`. Sign Out is now a 52pt surface capsule with a hairline border instead of `.borderedProminent`.
- `Features/Authentication/Views/Components/PasswordStrengthView.swift`: strength bar segments now use `pingHot` (weak), `pingAccent` (moderate), `pingLive` (strong) with `pingBorder` for empty slots. Rule list switched to DM Sans on `pingTextPrimary` / `pingTextSecondary`, with a `pingLive` checkmark on satisfied rules.
- `Features/Map/Views/MapView.swift`: removed the system `.alert("Ping Unavailable")`. The state now drives a `MapAlertChip` (error severity, `mappin.slash` icon) inserted into the alert stack and auto-dismisses after 3 seconds.
- `Features/Ping/Views/PingDetailView.swift`: same alert replaced with a top-overlay `MapAlertChip` that animates in with spring + opacity transition, then pops the screen back after 2 seconds via a `task(id:)` driven by `viewModel.pingUnavailable`.

### Files significantly modified
- `PingIt/Features/Authentication/Views/SuspendedAccountView.swift`
- `PingIt/Features/Authentication/Views/Components/PasswordStrengthView.swift`
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Chat reactions overlay + smoother location bubble

### Added
- `Features/Chat/Views/Components/MessageActionOverlay.swift`: long-press overlay for chat bubbles. Translucent backdrop (`black` 55% over `.ultraThinMaterial`), an amber-bordered reaction pill with the 8 emoji reactions (each bouncing in with a stagger via spring), and a stacked action card (Report / Block, only for other users' messages). Spring entrance + ease-out dismiss, both gated on `accessibilityReduceMotion`.

### Changed
- `Features/Chat/Views/MessageBubbleView.swift`: dropped the system `.contextMenu`. Bubbles now use `.onLongPressGesture(minimumDuration: 0.35)` and fire a medium `UIImpactFeedbackGenerator` haptic before calling an `onLongPress` callback. The bubble's `onReport` / `onBlock` parameters collapsed into a single `onLongPress` since the overlay handles those actions itself. `ChatLocationBubble` was rewritten to fill the bubble edge-to-edge: the inner `clipShape(.rect)` and 4pt padding are gone, the `Map` now sits directly inside the bubble's `ChatBubbleShape`, the location name floats on a dark gradient overlay at the bottom, and the preview matches the main Map screen's style (`pointsOfInterest: .excludingAll`, flat elevation).
- `Features/Chat/Views/ChatView.swift`: owns `actionOverlayMessage` state so the overlay can sit above the whole chat screen, not just the bubble. Bubble `onLongPress` sets the message; the overlay routes Report → `handleReportTap`, Block → `handleBlockTap`, react → `handleReaction`. Backdrop tap clears the state. Animation gated on `actionOverlayMessage?.id`.

### Files created
- `PingIt/Features/Chat/Views/Components/MessageActionOverlay.swift`

### Files significantly modified
- `PingIt/Features/Chat/Views/MessageBubbleView.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Chat screen UI overhaul

### Added
- `Features/Chat/Views/Components/ChatHeader.swift`: dark custom chat header with `AuthBackButton`, ping emoji + title (Syne ExtraBold 16pt), `TimelineView`-driven LIVE pulse + label, and a `ChatUrgencyPill` that derives its color/copy from `PingUrgency`.
- `Features/Chat/Views/Components/MessageInputBar.swift`: capsule `TextField` with a custom placeholder helper, a 44pt share-location pill on the left, and an amber 44pt paperplane send button that flips to `pingSurface` + secondary text when the field is empty. Shows a black `ProgressView` while a message is sending.
- `Features/Chat/Views/Components/ChatDateSeparator.swift`: Today / Yesterday / abbreviated-date label between hairline rules. Inserted at the start of each new day in the message list.
- `Features/Chat/Views/Components/ChatBubbleShape.swift`: per-corner-radius `Shape` used to give one bubble corner a 4pt tail while the others stay at 18pt.

### Changed
- `Features/Chat/ViewModels/ChatViewModel.swift`: stores `currentPing` from the ping document listener so the header can show emoji, title, and expiry. No service-call changes.
- `Features/Chat/Views/MessageBubbleView.swift`: full rewrite. Own messages are `pingAccent` on black text with a bottom-right tail; other messages are `pingSurface` with `pingTextPrimary` and a white-7% hairline border, tail on the top-left. Avatars (28pt) still render on the first message of a contiguous sender block, with the anonymous variant using a `person.fill` glyph on a surface circle. Timestamps and `@username` labels use DM Sans on `pingTextSecondary`. Reactions and the report/block context menu are preserved. Location messages are rendered inline as `ChatLocationBubble` (mini Map preview + `mappin.circle.fill` name row), replacing the old `LocationMessageView`.
- `Features/Chat/Views/ReactionSummaryView.swift`: reactions now use surface capsules with `pingBorder` and switch to a 18% amber tint + amber-border when the current user reacted.
- `Features/Chat/Views/ChatView.swift`: drops the system navigation title and `.accentColor` send button. New layout is a vertical stack of `ChatHeader` + `ScrollView` (day-grouped `LazyVStack` of `ChatDateSeparator` + `MessageBubbleView`) with `MessageInputBar` pinned via `.safeAreaInset(.bottom)`. Loading / error / empty states use a new `ChatStateView` (SF Symbol + Syne title + DM Sans body). `Load earlier messages` pagination is a capsule pill. Scroll uses `.scrollDismissesKeyboard(.interactively)` and `.scrollIndicators(.hidden)`.

### Removed
- `Features/Chat/Views/LocationMessageView.swift`: replaced by the inline `ChatLocationBubble` inside `MessageBubbleView`.

### Files created
- `PingIt/Features/Chat/Views/Components/ChatBubbleShape.swift`
- `PingIt/Features/Chat/Views/Components/ChatHeader.swift`
- `PingIt/Features/Chat/Views/Components/ChatDateSeparator.swift`
- `PingIt/Features/Chat/Views/Components/MessageInputBar.swift`

### Files significantly modified
- `PingIt/Features/Chat/Views/ChatView.swift`
- `PingIt/Features/Chat/Views/MessageBubbleView.swift`
- `PingIt/Features/Chat/Views/ReactionSummaryView.swift`
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Onboarding flow redesign + Report keyboard dismiss

### Changed
- `Features/Onboarding/Views/OnboardingView.swift`: full rewrite. Drops the default `TabView(.page)` indicator and `.borderedProminent` button. New layout: `pingBackground` ignoresSafeArea, an `OnboardingTopBar` with a Skip pill (surface + hairline border) that hides on the last page, a swipeable `TabView` with the system indicator hidden, a custom `OnboardingPageIndicator` (capsules that grow the active dot from 8pt to 28pt with a spring), and an `OnboardingPrimaryButton` — a 56pt amber capsule CTA with `pingAccent` glow that shows "Next →" or "Get Started" depending on page. Page content moved into a small `OnboardingPageContent` struct array so copy lives in one place.
- `Features/Onboarding/Views/OnboardingPageView.swift`: full rewrite. Drops the SF Symbol hero. New `OnboardingHero` renders a 156pt `pingSurface` plate with hairline border + amber glow shadow, a 76pt category-style emoji centered, an amber 44pt accent badge at the top-right (different SF Symbol per page: `sparkles` / `plus` / `bolt.fill`), and twin `TimelineView`-driven pulse rings behind the plate (Reduce Motion replaces them with a static thin ring). Title is Syne ExtraBold 28pt, subtitle is DM Sans 15pt on `pingTextSecondary` with 4pt line spacing.

### Fixed
- `Features/Report/Views/ReportView.swift`: added `.scrollDismissesKeyboard(.interactively)` so the details `TextEditor` keyboard can be dismissed by swiping the scroll view, matching the pattern already used in the auth screens.

### Files significantly modified
- `PingIt/Features/Onboarding/Views/OnboardingView.swift`
- `PingIt/Features/Onboarding/Views/OnboardingPageView.swift`
- `PingIt/Features/Report/Views/ReportView.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Report and Block UI overhaul

### Changed
- `Features/Ping/Views/PingDetailView.swift`: `DetailActionLinks` no longer renders as inline text links. Report and Block are now side-by-side equal-width capsule pills with `pingSurface` fill and hairline borders. Block uses `pingHot` foreground and a 35% red border so the destructive intent reads at a glance.
- `Features/Report/Views/ReportView.swift`: full rewrite. Replaces the system `Form` with a dark sheet matching the rest of the design system:
  - `ReportSheetHeader`: drag handle + centered Syne ExtraBold 18pt title + 38pt close X.
  - `ReportReasonCard`: one card per `Report.ReportReason` with an SF Symbol icon (`megaphone` / `exclamationmark.bubble` / `eye.slash` / `ellipsis.circle`), DM Sans SemiBold label, and an amber-filled radio indicator on the right. Selected state uses an amber border + accent icon.
  - `ReportDetailsSection`: styled `TextEditor` on `pingSurfaceElevated` with placeholder and 500-char counter (matches `CreatePingDescriptionSection`).
  - `ReportSubmitButton`: full-width amber capsule with `pingAccent` glow shadow. Shows a black `ProgressView` while submitting. Disabled state drops opacity to 35%.
  - `ReportErrorChip`: design-token red-tinted chip with icon for validation errors.
  - `ReportSubmittedCard`: green checkmark + Syne ExtraBold title + DM Sans subtitle on a surface card.
  - `ReportBlockOfferCard`: surface card prompting the reporter to also block, with "No thanks" secondary pill and red `Block` pill (with shadow).
- Sheet presentation uses `.presentationDetents([.large])`, hidden drag indicator, and 28pt corner radius for visual parity with the Create Ping sheet.

### Files significantly modified
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingIt/Features/Report/Views/ReportView.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Map screen UI overhaul

### Added
- `Features/Map/Views/MapAlertChip.swift`: new floating glass-pill alert component with `info` / `warning` / `error` severities. 3pt animated accent stripe (`pingAccent` or `pingHot`) with breathing shadow, SF Symbol icon, title + optional subtitle, optional inline action capsule, optional dismiss button. Layered background of `pingSurface 85%` over `.ultraThinMaterial` with a `.plusLighter` accent gradient overlay. Slides in from above with spring animation; respects `accessibilityReduceMotion`.

### Changed
- `Features/Map/Views/PingAnnotationView.swift`: full rewrite. Renders the ping's category emoji inside a `pingSurface` dot with a 2.5pt accent border (`pingAccent` default, `pingHot` when hot or critical). Two SwiftUI pulse rings (`scaleEffect` 0.7→2.4 + opacity 0.55→0, `repeatForever`, 2.8s normal / 1.8s critical, second ring delayed by half a cycle). Boost-count capsule badge (`pingAccent` with `pingBackground` border) overlaid top-right. Continuous horizontal shake on critical urgency. All animations gated on `accessibilityReduceMotion`.
- `Features/Map/Views/PingClusterAnnotationView.swift`: rebuilt with the same surface treatment as the marker. Diameter scales 46 / 52 / 58pt at <10 / <100 / ≥100 members; label uses Syne ExtraBold 16 / 14pt and inherits the border accent. Border + label flip to `pingHot` when any member is hot or critical. Displays `999+` for very large clusters.
- `Features/Map/Views/MapView.swift`: hidden the system navigation bar in favor of a floating Syne ExtraBold 28pt "Map" title, a glass `pingAccent` recenter button (`.ultraThinMaterial` 42pt circle) that flies the camera to the user's location, and a top gradient overlay (`pingBackground 92%` → clear, 160pt) for legibility. Map style is `.standard(elevation: .flat, pointsOfInterest: .excludingAll)` with `.mapControlVisibility(.hidden)`. Error / location-denied / email-verification / empty-state notifications now render through the new `MapAlertChip` stack below the title with spring transitions. The amber FAB now lives in a private `MapCreatePingFAB` view with its own breathing glow and hides itself while the ping sheet is presented.
- `Features/Map/Views/EmailVerificationBannerView.swift`: reduced to a thin wrapper that configures `MapAlertChip` (warning severity, envelope icon, Resend action, Dismiss button).
- `App/MainTabView.swift`: added `.tint(Color.pingAccent)` so selected tabs render amber instead of the system blue.

### Files created
- `PingIt/Features/Map/Views/MapAlertChip.swift`

### Files significantly modified
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Map/Views/PingAnnotationView.swift`
- `PingIt/Features/Map/Views/PingClusterAnnotationView.swift`
- `PingIt/Features/Map/Views/EmailVerificationBannerView.swift`
- `PingIt/App/MainTabView.swift`
- `ARCHITECTURE.md`
- `project_status.md`

---

## [2026-06-01] — Ping Detail + Map Ping Sheet UI overhaul + description field

### Added
- `Core/Models/Ping.swift`: added optional `description: String?` field for longer ping details (500 char limit), separate from the title.
- `Core/Utilities/Constants.swift`: added `Ping.maxDescriptionLength = 500`.
- `Features/Map/Views/MapPingSheet.swift`: new custom bottom overlay card for map marker taps. Shows author avatar, urgency label, category emoji + title, optional description, boost/member stats, JOIN CHAT + Details capsule buttons. Spring-animated slide-up with `ultraThinMaterial` backdrop.
- `Features/Ping/Views/Components/CreatePingDescriptionSection.swift`: optional "Add more details" TextEditor with 500 char limit, matching the title section's styling.
- `Features/Ping/ViewModels/PingDetailViewModel.swift`: added `pingCategory` and `urgency` computed properties for display layer use.

### Changed
- `Features/Ping/Views/PingDetailView.swift`: full rewrite. Custom nav bar (38pt dark circle back button + "Ping Details" Syne ExtraBold title), author+timer row (40pt avatar, @username, relative date, urgency pill), category emoji title (Syne ExtraBold 26pt), optional description, stats card with boost button (spring animation, amber boosted state) + member count, FeedHotBadge, full-width amber JOIN CHAT capsule with glow, red delete pill (creator), report/block links (non-creator). Delete and Block use PingItConfirmationDialog instead of system .alert().
- `Features/Map/Views/MapView.swift`: marker taps now show MapPingSheet overlay instead of pushing PingDetailView directly. Added `UserService` dependency for creator loading. Added `chatPing` navigation destination for direct JOIN CHAT from sheet. Added helper methods: `showPingSheet`, `dismissPingSheet`, `handleSheetJoinChat`, `handleSheetViewDetails`.
- `Features/Feed/Views/PingFeedCardView.swift`: TitleRow now shows optional description as a single-line preview below the title when present.
- `Features/Ping/Views/CreatePingView.swift`: added CreatePingDescriptionSection between title and photo sections.
- `Features/Ping/ViewModels/CreatePingViewModel.swift`: added `descriptionText`, `descriptionCharacterCount`, `isDescriptionOverLimit`. Description is content-moderated and passed to Ping model on creation.

### Removed
- `Features/Ping/Views/PingDetailCreatorSection.swift`: replaced by inline DetailAuthorTimerRow in PingDetailView.
- `Features/Ping/Views/PingDetailActionSection.swift`: replaced by inline DetailJoinChatButton + DetailDeleteButton in PingDetailView.
- `Features/Ping/Views/PingPhotoSectionView.swift`: legacy file, unused since Create Ping overhaul.

---

## [2026-06-01] — Create Ping flow UI overhaul

### Added
- `Features/Ping/Models/PingCategory.swift`: enum with 9 categories (sports, study, social, music, food, skate, chill, gaming, art) plus label and emoji computed properties.
- `Features/Ping/Views/Components/FlowLayout.swift`: custom `Layout` protocol implementation for wrapping chip grids.
- `Features/Ping/Views/Components/CategoryChip.swift`: capsule chip with emoji + label; selected state uses amber 15% fill + amber border.
- `Features/Ping/Views/Components/ExpiryPill.swift`: equal-width capsule duration pill (6h / 24h / 48h / Custom).
- `Features/Ping/Views/Components/CreatePingHeader.swift`: drag handle (36×4pt, white 12% opacity) + "New Ping" Syne ExtraBold 22pt + ✕ dismiss button.
- `Features/Ping/Views/Components/CreatePingSectionLabel.swift`: reusable ALL CAPS DM Sans SemiBold 11pt section header with 0.8pt tracking.
- `Features/Ping/Views/Components/CreatePingButton.swift`: fixed-bottom CTA with dynamic label ("Fill in the details" disabled → "⚡ PING IT" enabled), amber glow shadow, scale-on-press.
- `Features/Ping/Views/Components/CreatePingCategorySection.swift`: FlowLayout of 9 CategoryChips with toggle selection.
- `Features/Ping/Views/Components/CreatePingTextSection.swift`: TextEditor with custom placeholder overlay + character count (280 max).
- `Features/Ping/Views/Components/CreatePingPhotoSection.swift`: dashed-border add button, image preview (180pt, rounded 16), red ✕ remove button.
- `Features/Ping/Views/Components/CreatePingExpirySection.swift`: 4 ExpiryPills in HStack + collapsible graphical DatePicker for Custom.
- `Features/Ping/Views/Components/CreatePingLocationSection.swift`: tappable row with pin icon, location text, and chevron.
- `Features/Ping/Views/Components/CreatePingErrorBanner.swift`: warning icon + error text in pingHot.
- `Ping` model: added optional `category: String?` field.

### Changed
- `Features/Ping/Views/CreatePingView.swift`: full rewrite. Replaced NavigationStack + Form + toolbar with modal bottom sheet (VStack: custom header → ScrollView with sections → fixed bottom CTA). No system Form/List styling.
- `Features/Ping/ViewModels/CreatePingViewModel.swift`: added `selectedCategory: PingCategory?`; `canCreate` now requires category instead of location; Ping creation includes category field.
- `Features/Ping/Views/LocationPickerView.swift`: full rewrite. Now a sheet with drag handle, custom header, 3-option card (Use Current Location / Set Location on Map / Search Address) using SettingsRowButtonStyle, and inline search with autocomplete results.
- `Features/Ping/Views/MapPinPickerView.swift`: restyled with amber pin icon, dark bottom panel with coordinates + Cancel/Confirm capsule buttons, presentation detents.
- `Features/Map/Views/MapView.swift`: replaced toolbar "Create Ping" button with a floating 60pt amber circle FAB (bottom-trailing, dual shadow). Added presentation modifiers to CreatePingView sheet.

---

## [2026-06-01] — Feed screen UI overhaul

### Added
- `Features/Feed/Views/Components/FeedSortChip.swift`: capsule toggle chip with selected (amber 13% fill + amber border) and unselected (pingSurface + pingBorder) states. DM Sans Medium 12pt label.
- `Features/Feed/Views/Components/FeedHotBadge.swift`: red capsule "HOT" badge, DM Sans Bold 10pt white on pingHot, 0.8pt tracking.
- `Features/Feed/Views/Components/FeedLivePulse.swift`: pulsing green dot (7pt, scale 1→1.3, opacity 1→0.6, 1.5s infinite) + "LIVE" label in DM Sans SemiBold 11pt pingLive.
- `Features/Feed/Views/Components/FeedEmptyState.swift`: pin emoji (40pt) + "Nothing happening yet." (Syne Bold 18pt) + "Drop one and start something." (DM Sans 14pt secondary).
- `Features/Feed/ViewModels/FeedViewModel.swift`: added `PingUrgency` enum (`.critical` <1.5h, `.urgent` <6h, `.normal`) with color property; `visiblePings` computed property filtering expired pings; `urgency(for:)` method; `removeExpiredPings()` for the 60s timer; `chipLabel` on `FeedSortOption`.

### Changed
- `Features/Feed/Views/FeedView.swift`: full rewrite. Replaced system `NavigationTitle`, toolbar `Menu` sort picker, `ContentUnavailableView`, and `ProgressView` with custom dark header (Syne ExtraBold 28pt "Feed" + FeedLivePulse), 3 sort chips (Hot/New/Expiring), lazy card list on pingBackground, custom empty state, and a 60-second expiry timer. Header uses flat HStack(spacing: 8) with fixedSize on title and chips to prevent wrapping.
- `Features/Feed/Views/PingFeedCardView.swift`: full rewrite. Urgency edge bar (4pt red/amber/clear), creator avatar circle (26pt with initial letter), @username, FeedHotBadge, Syne Bold 17pt title, urgency-colored countdown label, boost count (amber when >0), participant count, optional media indicator icon. Hot cards get bold red treatment: pingHot 35% border (1.5pt), 18% shadow. Critical cards (<1.5h) get a `phaseAnimator`-driven breathing pulse (scale 0.985↔1.0 + red overlay fade + pulsing red border). Urgent cards (<6h) get an amber shimmer sweeping down the edge bar. All animations respect `accessibilityReduceMotion`.
- `Features/Feed/Views/Components/FeedSortChip.swift`: text uses `fixedSize()` to prevent truncation of "Expiring" label.
- `Features/Feed/ViewModels/FeedViewModel.swift`: dropped `.nearest` sort option. Changed default sort to `.hottest`. Added expiry filtering to `sortedPings` via `visiblePings`.

### Removed
- `FeedSortOption.nearest` / `.displayName` — replaced by `.chipLabel` and the 3 prototype sort options.

---

## [2026-06-01] — Profile screen UI overhaul

### Added
- `Features/Profile/Views/Components/ProfileAvatarBlock.swift`: 86pt avatar circle (initial letter Syne ExtraBold 36pt on pingAccent background, or AsyncImage when a profile photo URL exists). 3pt pingAccent 40% stroke, 12pt amber glow shadow. 28pt edit-pencil circle at bottom-right triggers the photo source picker.
- `Features/Profile/Views/Components/ProfileStatsCard.swift`: 3-column HStack (Pings / Boosts / Member age) in a pingSurface card. Values in Syne ExtraBold 22pt amber, labels in DM Sans Regular 11pt uppercase secondary.
- `Features/Profile/Views/Components/ProfileInfoCard.swift`: 3-row info card (Username / Email / Member since) with inline-editable username TextField. Error text shown below the username row when editing.
- `Features/Profile/Views/Components/PhotoSourcePicker.swift`: bottom sheet with drag handle, "Profile Photo" Syne title, and action rows (Choose from Library / Take Photo / Remove Photo) using SettingsRowButtonStyle.
- `Core/Protocols/PingServicing.swift`: added `fetchPings(byCreatorId:)` to the protocol.
- `Core/Services/PingService.swift`: implemented `fetchPings(byCreatorId:)` — Firestore query on `creatorId` field.

### Changed
- `Features/Profile/Views/ProfileView.swift`: full rewrite. Removed `NavigationStack` / `Form` / `ScrollView` with system toolbar. Replaced with dark background, custom "Profile" header with edit/save/cancel buttons, ProfileAvatarBlock, ProfileStatsCard, ProfileInfoCard, photo source sheet overlay, and PingItConfirmationDialog for remove photo confirmation.
- `Features/Profile/ViewModels/ProfileViewModel.swift`: added PingService dependency, stats computation (pingCount, totalBoosts, memberAge, memberSinceFormatted, avatarInitial), edit-mode state (beginEditingUsername, cancelEditingUsername). Photo-related methods retained and unchanged.
- `Features/Settings/Views/Components/SettingsRow.swift`: promoted `SettingsRowButtonStyle` from private to internal for cross-feature reuse (consumed by PhotoSourcePicker).

### Removed
- `Features/Profile/Views/ProfileImageSection.swift`: replaced by ProfileAvatarBlock + PhotoSourcePicker.

---

## [2026-06-01] — Settings tab UI overhaul (Settings, Blocked Users, Sign Out, Delete Account)

### Added
- `Features/Settings/Models/SettingsRoute.swift`: navigation route enum for the Settings tab (`blockedUsers`, `termsOfService`, `privacyPolicy`).
- `Features/Settings/ViewModels/DeleteAccountViewModel.swift`: `@Observable @MainActor` view model orchestrating the two-step delete-account flow (`confirmIntent` → `reauthenticate` → `farewell`). Splits the reauth + Cloud Function call from the final sign-out so the UI can show a farewell state before the auth listener tears down `SettingsView`.
- `Features/Settings/Views/Components/SettingsSection.swift`: rounded `pingSurface` card with optional uppercase section label; `isDestructive` variant tints the hairline border `pingHot @ 0.2` (used by the Delete Account container).
- `Features/Settings/Views/Components/SettingsRow.swift`: generic 52pt-min row with `DM Sans Medium 15pt` label, optional `labelColor` override, optional tap action, and a `ViewBuilder` trailing slot. A convenience initializer renders a `SettingsChevron` when no trailing view is supplied.
- `Features/Settings/Views/Components/SettingsRowDivider.swift`: 1pt `pingBorder` hairline inset 18pt from the leading edge.
- `Features/Settings/Views/Components/PingItToggle.swift`: custom 48×28 capsule toggle. Off-state uses `pingSurfaceElevated`, on-state uses `pingLive`. Sliding white thumb animated with `spring(response: 0.25, dampingFraction: 0.7)`. Exposes an accessibility label/value to VoiceOver.
- `Features/Settings/Views/Components/PingItConfirmationDialog.swift`: generic modal overlay with a dimmed backdrop, a centered `pingSurfaceElevated` card, spring scale + opacity transition, and tap-to-dismiss on the backdrop. Also adds `DialogTitleBlock`, `DialogButtonRow`, `DialogSecondaryButtonStyle`, `DialogDestructiveButtonStyle`. The app must use this instead of system `.alert()` / `.confirmationDialog()`.
- `Features/Settings/Views/Components/HoldToConfirmButton.swift`: destructive press-and-hold pill (default 7.5s, ease-out cubic — fast start, slow finish). Eight persuasion labels cycle as progress advances (`Keep holding...` → `Goodbye.`). Light haptic ticks fire on every 10% of progress (medium past 80%, heavy on completion). The pill shakes increasingly past 55% of progress. Cancellation collapses the fill in 0.25s.
- `Features/Settings/Views/Components/AccountFarewellCard.swift`: animated sad-face card shown for ~4s after deletion — amber gradient face, blinking eyes (every ~2.8s), endlessly-falling teardrop, sad-mouth quadratic curve, plus copy "We're sad to see you go. / Your account is gone, your pings have faded. Thanks for being part of PingIt."
- `Features/Settings/Views/Components/BlockedUserRow.swift`: avatar (40pt circle with placeholder glyph) + username + amber-tinted `Unblock` capsule pill on a 64pt-min row.
- `Features/Settings/Views/Components/BlockedUsersEmptyState.swift`: 88pt circular glyph + Syne bold title + DM Sans regular body. Used for both the "no blocks" and the "error loading blocks" states.

### Changed
- `Features/Settings/Views/SettingsView.swift`: full rewrite. Removed `List` / `Form` / `Toggle` / `.alert()` / `Section`; replaced with `SettingsSection` cards, `SettingsRow`, `PingItToggle`, custom Sign Out + two-step Delete Account modals. Added `NavigationStack(path: $path)` driving `SettingsRoute`. Title now uses `Syne ExtraBold 30pt`. Delete Account section is its own destructive-bordered card outside the Legal section.
- `Features/Settings/Views/BlockedUsersView.swift`: full rewrite. Removed system `List` / `.alert()` / `ContentUnavailableView`. Uses `AuthScreenHeader` for the back button + title, a single rounded card holding `BlockedUserRow` entries separated by `SettingsRowDivider`, `BlockedUsersEmptyState` for no-blocks/error states, and `PingItConfirmationDialog` for unblock confirmation. The dialog's confirm button is amber (`UnblockConfirmButtonStyle`), not destructive — unblocking is recoverable.
- `Core/Services/AuthService.swift`: split `deleteAccount()` into `deleteAccountRecord()` (Cloud Function only) and a follow-up `signOut()`. The original `deleteAccount()` is preserved and chains the two so existing callers are unaffected. The split exists so `AccountFarewellCard` can render before the auth state listener navigates back to Welcome.

---

## [2026-06-01] — Authentication screens UI overhaul (Sign In, Create Account, Forgot Password, Terms, Privacy)

### Added
- `Features/Authentication/Views/Components/AuthBackButton.swift`: 38pt dark circle back button with `chevron.left` glyph and hairline border.
- `Features/Authentication/Views/Components/AuthScreenHeader.swift`: shared Syne ExtraBold 22pt title row with back button.
- `Features/Authentication/Views/Components/AuthInputField.swift`: custom 52pt surface-elevated input field with leading SF Symbol icon and trailing accessory slot; matches the prototype's `AuthInput` component.
- `Features/Authentication/Views/Components/AuthPasswordField.swift`: secure-field variant with eye/eye.slash visibility toggle.
- `Features/Authentication/Views/Components/AuthCheckbox.swift`: 20×20pt rounded square checkbox with amber fill when checked and a bold white SF Symbol checkmark.
- `Features/Authentication/Views/Components/AuthCTAButtonStyle.swift`: amber pill CTA with `easeInOut(0.2)` colour transition between enabled (amber fill / black text / glow) and disabled (surface fill / secondary text) states.
- `Features/Authentication/Views/Components/AuthFieldHint.swift`: 12pt DM Sans helper text with `error` / `soft` / `success` tone variants.
- `Features/Authentication/Models/LegalDocument.swift`: lightweight HTML parser that turns the bundled `terms.html` / `privacy.html` into native `heading / sectionHeading / updated / paragraph / bullets` blocks.
- `Features/Authentication/Views/LegalDocumentView.swift`: shared scrollable renderer for `LegalDocument`, using Syne for headings and DM Sans for body.

### Changed
- `Features/Authentication/Views/LoginView.swift`: full rewrite using `AuthScreenHeader`, `AuthInputField`, `AuthPasswordField`, `AuthCTAButtonStyle`. Focus chain between email → password, custom dark back button (system chrome hidden), Forgot Password link uses `pingTextSecondary`.
- `Features/Authentication/Views/RegisterView.swift`: full rewrite with the new components. Terms / Privacy inline links in amber, four-field focus chain, password strength view retained, inline username availability hints preserved with new typography.
- `Features/Authentication/Views/ForgotPasswordView.swift`: full rewrite. Form state mirrors Sign In; success state shows a haloed amber `envelope.badge.fill` mark with a "Back to Sign In" CTA that pops the screen.
- `Features/Authentication/Views/TermsOfServiceView.swift` / `PrivacyPolicyView.swift`: now load `LegalDocument` and render natively via `LegalDocumentView` instead of `WKWebView`.

### Removed
- `Features/Authentication/Views/Components/AuthTextField.swift` and `AuthSecureField.swift`: superseded by `AuthInputField` / `AuthPasswordField`.
- `Features/Authentication/Views/WebContentView.swift`: legal screens render natively now, so the `WKWebView` wrapper is no longer used.

---

## [2026-06-01] — Welcome screen UI overhaul

### Added
- `Core/Theme/Color+Tokens.swift`: dark-mode color palette (`Color.pingBackground`, `pingSurface`, `pingSurfaceElevated`, `pingBorder`, `pingTextPrimary`, `pingTextSecondary`, `pingAccent`, `pingHot`, `pingLive`).
- `Core/Theme/Font+Tokens.swift`: typed `Font.syne(_:size:relativeTo:)` and `Font.dmSans(_:size:relativeTo:)` helpers backed by `SyneWeight` / `DMSansWeight` enums.
- `Core/Theme/FontRegistrationCheck.swift`: DEBUG-only assertion that every custom font weight loads at app launch.
- `Features/Authentication/Views/Components/PrimaryPillButtonStyle.swift`: amber pill `ButtonStyle` with glow shadow and press-scale animation.
- `Features/Authentication/Views/Components/SecondaryPillButtonStyle.swift`: surface pill `ButtonStyle` with hairline border.
- `Features/Authentication/Views/Components/RadarBackground.swift`: 3 concentric pulsing rings + 8 blinking dots; respects `accessibilityReduceMotion`.
- `Features/Authentication/Views/Components/PingItLogoMark.swift`: 18pt amber core with two halo layers and a 2s breathing pulse.
- `Features/Authentication/Views/Components/PingItWordmark.swift`: logo mark composed with the "PINGIT" Syne ExtraBold wordmark; VoiceOver reads "PingIt" as a header.

### Changed
- `Features/Authentication/Views/WelcomeView.swift`: full rewrite to compose the new components (radar background + custom typography + custom pill buttons), replacing the previous stock-SwiftUI implementation.
- `App/PingItApp.swift`: enforces `.preferredColorScheme(.dark)` on the root `WindowGroup` and runs `FontRegistrationCheck.run()` inside `.task`.
- `Info.plist`: declares 7 custom fonts (3 Syne + 4 DM Sans weights) under `UIAppFonts`.
- `PingIt.xcodeproj/project.pbxproj`: 7 font `.ttf` files added as bundle resources; duplicate `OFL.txt` / `README.txt` entries removed to fix a "multiple commands produce" build collision.

---

## [2026-05-31] — Tech Debt Remediation: Privacy Descriptions, Image Storage Protocol, Location Updates, GDPR Data Export

### Summary
Fixed App Store submission blockers (missing privacy descriptions), extracted `ImageStorageServicing` protocol for testability, improved location tracking for notifications, and implemented GDPR Article 20 data portability via Cloud Function + iOS UI.

### Fixed — App Store Privacy Descriptions (Critical)
- Added `NSPhotoLibraryUsageDescription` to Xcode build settings (was missing — Apple auto-rejects without it)
- Updated `NSCameraUsageDescription` to cover both profile pictures and ping photos (was profile-only)

### Changed — ImageStorageServicing Protocol (Item 7)
- Extracted `ImageStorageServicing` protocol from direct `FirebaseStorage` calls in `ProfileViewModel`
- Created `ImageStorageService` (`@MainActor @Observable`) wrapping Firebase Storage upload/delete
- Created `MockImageStorageService` for test assertions
- `ProfileViewModel` now accepts `ImageStorageServicing` via `configure()` — fully testable without Firebase
- Removed `import FirebaseStorage` from `ProfileViewModel`
- `ImageStorageService` injected via `.environment()` from `PingItApp`

### Changed — Location Update Frequency (Item 8)
- `lastKnownLocation` now updates on every significant location change (500m+ movement), not just first map load
- Added `lastUploadedLocation` tracking in `MapView` with distance threshold
- Nearby push notifications now target current user positions instead of stale first-load coordinates

### Added — GDPR Data Export (Item 10)
- `exportUserData` Cloud Function: collects all user data (profile, pings, messages, boosts, blocks, reports, chat participations) and returns JSON
- `DataExportServicing` protocol + `DataExportService` wrapping the callable
- "Export My Data" button in Settings → Privacy & Safety section
- Exports as `PingIt-data-export.json` via iOS share sheet (`UIActivityViewController`)
- `DataExportService` injected via `.environment()` from `PingItApp`

### Noted for Future PRs (Post-Apple Release)
- Node.js 20 → 22 upgrade (decommission 2026-10-30)
- `firebase-functions` package upgrade (breaking changes)
- Server-side rate limiting (current client-side only)
- Offline mode UI indicators

### Files Created
- `PingIt/Core/Protocols/ImageStorageServicing.swift`
- `PingIt/Core/Services/ImageStorageService.swift`
- `PingIt/Core/Protocols/DataExportServicing.swift`
- `PingIt/Core/Services/DataExportService.swift`
- `PingIt/Core/Utilities/ActivityViewRepresentable.swift`
- `PingItTests/Mocks/MockImageStorageService.swift`
- `functions/src/exportUserData.ts`

### Files Modified
- `PingIt.xcodeproj/project.pbxproj` — Added NSPhotoLibraryUsageDescription, updated NSCameraUsageDescription
- `PingIt/Features/Profile/ViewModels/ProfileViewModel.swift` — Uses ImageStorageServicing, added @MainActor, removed FirebaseStorage import
- `PingIt/Features/Profile/Views/ProfileView.swift` — Injects ImageStorageService
- `PingIt/Features/Map/Views/MapView.swift` — Periodic location upload on 500m+ movement
- `PingIt/Features/Settings/Views/SettingsView.swift` — Export My Data button + share sheet
- `PingIt/App/PingItApp.swift` — Added ImageStorageService + DataExportService to environment
- `PingItTests/ViewModelTests/ProfileViewModelTests.swift` — Updated for ImageStorageServicing parameter
- `functions/src/index.ts` — Added exportUserData export

---

## [2026-05-26] — Bonus Feature Bug Fixes & Audit Remediation

### Summary
Comprehensive audit and fix session for the 4 bonus features (media attachments, discovery feed, message reactions, location sharing). 9 issues fixed across backend, iOS client, and concurrency correctness.

### Fixed — Cascading Deletion (Critical)
- `pingCleanup.ts`: Added Firebase Storage cleanup — deletes `ping_images/{pingId}/` when pings are deleted or expired
- `deleteAccount` flow now inherits ping image cleanup via updated `cleanupPing`

### Fixed — Real-Time Reactions (High)
- `ChatViewModel.observeNewMessages` listener now merges updated messages into `allMessages` instead of only appending new unique messages
- Reaction changes, moderation flags, and any field updates on existing messages now reflect in real time

### Fixed — Discovery Feed Live Updates (High)
- Removed `FeedView.onDisappear { stopObserving() }` which killed the Firestore listener when navigating to PingDetailView within the NavigationStack
- Listener cleanup is now handled by `FeedViewModel.deinit` when the view is truly destroyed
- Fixed `Ping.Equatable` to compare all relevant fields (`boostCount`, `participantCount`, `status`, `imageUrl`, `expiresAt`) — was only comparing `id`, so SwiftUI's `ForEach` never re-rendered feed cards when counts changed
- Added `FeedView.onChange(of: blockService.blockedUserIds)` to re-apply filters when user blocks someone from within the feed

### Fixed — Media Attachment UI (High)
- Extracted photo section into `PingPhotoSectionView` (new file) — fixes compiler type-checking timeout in `CreatePingView.body`
- Image preview is now non-interactive — tapping the image no longer triggers removal
- Remove button replaced with red X icon overlay on image corner (`.symbolRenderingMode(.palette)` with white/red)
- Added camera option: `Menu` with "Choose from Library" and "Take Photo" (reuses `CameraPickerView`)
- Added `CreatePingViewModel.handleCameraImage(_:)` for camera-captured images
- Fixed photo picker dismissal on scroll: moved `.photosPicker` modifier to NavigationStack level (away from conditional Section content that caused SwiftUI re-renders)
- Decoupled `pickerItem` state to View level to prevent sheet dismissal from `@Observable` ViewModel re-renders

### Fixed — Concurrency Correctness (Medium)
- Added `@MainActor` to `CreatePingViewModel`, `ChatViewModel`, `FeedViewModel`
- Changed `deinit` to `isolated deinit` in `ChatViewModel` and `FeedViewModel` for safe listener cleanup

### Fixed — Location Sharing (Low)
- `ChatView.handleShareLocation()` now performs reverse geocoding via `CLGeocoder` before sending
- Location messages display actual address (e.g., "Strada Napoca, Cluj-Napoca") instead of "Shared location"

### Fixed — Constant Naming (Low)
- Renamed `Constants.Storage.maxProfileImageSizeBytes` → `maxImageSizeBytes` (used for both profile and ping images)
- Updated all references in `CreatePingViewModel`, `ProfileViewModel`

### Files Modified
- `functions/src/pingCleanup.ts` — Storage import, image deletion after Firestore cleanup
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift` — Reaction merge logic, @MainActor, isolated deinit
- `PingIt/Features/Feed/Views/FeedView.swift` — Removed aggressive onDisappear listener teardown
- `PingIt/Features/Feed/ViewModels/FeedViewModel.swift` — @MainActor, isolated deinit
- `PingIt/Features/Ping/Views/CreatePingView.swift` — Body broken into sections, .photosPicker at NavigationStack level
- `PingIt/Features/Ping/Views/PingPhotoSectionView.swift` — **NEW**: Extracted photo section (image preview, X overlay, Menu with Library/Camera)
- `PingIt/Core/Models/Ping.swift` — Equatable expanded to compare boostCount, participantCount, status, imageUrl, expiresAt
- `PingIt/Features/Ping/ViewModels/CreatePingViewModel.swift` — @MainActor, handleCameraImage, constant rename
- `PingIt/Features/Chat/Views/ChatView.swift` — Reverse geocoding in location share
- `PingIt/Core/Utilities/Constants.swift` — Renamed maxProfileImageSizeBytes → maxImageSizeBytes
- `PingIt/Features/Profile/ViewModels/ProfileViewModel.swift` — Constant rename

---

## [2026-05-21] — Message Reactions, Location Sharing, Media Attachments, Discovery Feed

### Summary
Four new features added: message reactions in chat, location sharing in chat, optional image attachments on pings, and a scrollable discovery feed tab.

### Added — Message Reactions (Feature 1)
- `ChatMessage.reactions` field (optional `[String: [String]]` — emoji key → user IDs)
- `Constants.Reaction.available` — 8 emoji reactions (👍 ❤️ 😂 😮 😢 🔥 👎 🎉)
- `PingItError.reactionFailed(underlying:)` error case
- `ChatServicing.toggleReaction(messageId:emoji:userId:)` protocol method
- `ChatService.toggleReaction` implementation (Firestore arrayUnion/arrayRemove)
- `ChatViewModel.toggleReaction(on:emoji:)` with analytics logging
- `ReactionSummaryView` — tappable emoji capsules below message bubbles
- `MessageBubbleView` updated: `currentUserId`, `onReaction` params; reactions in context menu
- `AnalyticsService.EventName.reactionToggled`
- `MockChatService` updated with toggle tracking
- 2 new tests: `toggleReactionCallsService`, `toggleReactionSetsErrorOnFailure`
- Firestore rule: `safeReactionUpdate()` — only `reactions` field modifiable

### Added — Location Sharing in Chat (Feature 2)
- `ChatMessage.messageType`, `latitude`, `longitude`, `locationName` fields
- `Constants.MessageType` enum (`text`, `location`)
- `PingItError.locationSharingFailed` error case
- `ChatViewModel.sendLocationMessage(latitude:longitude:locationName:)` and `setError()`
- `LocationMessageView` — inline mini-map with Marker, tap to open Apple Maps
- `MessageBubbleView` refactored: `messageBubbleContent` routes text vs location
- `ChatView` — location share button + `LocationService` environment
- `AnalyticsService.EventName.locationShared`
- Firestore rule: `safeMessageCreate()` updated with location fields and type validation
- 2 new tests: `sendLocationMessageSucceeds`, `sendLocationMessageBlockedWhenUnverified`

### Added — Media Attachments on Pings (Feature 3)
- `Ping.imageUrl` optional field
- `Constants.Storage.pingImagesPath`, `pingImageMaxDimension`
- `PingItError.pingImageTooLarge`, `pingImageUploadFailed(underlying:)` error cases
- `PingServicing.createPingWithChat(_:pingId:)` overload and `uploadPingImage(pingId:imageData:)`
- `PingService` implementations: pre-generated ping ID batch write, Firebase Storage upload
- `CreatePingViewModel`: PhotosPicker handling, image compression/resize, upload-before-create flow
- `CreatePingView`: Photo section with PhotosPicker, thumbnail preview, remove button
- `PingDetailView`: AsyncImage display for ping images
- `AnalyticsService.ParameterName.hasImage`
- Firestore rule: `safePingCreate()` updated with `imageUrl` whitelist
- `MockPingService` updated with upload tracking
- 2 new tests: `createPingWithImageCallsUpload`, `createPingWithoutImageSkipsUpload`

### Added — Discovery Feed (Feature 4)
- `FeedSortOption` enum (newest, hottest, nearest, expiringSoon)
- `FeedViewModel` — independent Firestore listener, block/expiry filtering, creator cache, distance formatting
- `FeedView` — NavigationStack with sort menu, lazy card list, empty state
- `PingFeedCardView` — card with text, creator, countdown, distance, boost/participant counts, hot badge, image thumbnail
- `MainTabView` updated: 4th "Feed" tab with `FeedView`
- `AnalyticsService.EventName.feedViewed`, `feedSortChanged`
- 4 new tests: `sortedPingsByNewest`, `sortedPingsByHottest`, `filtersExpiredPings`, `filtersBlockedCreators`

### New Files
- `PingIt/Features/Chat/Views/ReactionSummaryView.swift`
- `PingIt/Features/Chat/Views/LocationMessageView.swift`
- `PingIt/Features/Feed/ViewModels/FeedViewModel.swift`
- `PingIt/Features/Feed/Views/FeedView.swift`
- `PingIt/Features/Feed/Views/PingFeedCardView.swift`
- `PingItTests/ViewModelTests/FeedViewModelTests.swift`

### Modified Files
- `PingIt/Core/Models/ChatMessage.swift`, `Ping.swift`
- `PingIt/Core/Utilities/Constants.swift`, `PingItError.swift`
- `PingIt/Core/Protocols/ChatServicing.swift`, `PingServicing.swift`
- `PingIt/Core/Services/ChatService.swift`, `PingService.swift`, `AnalyticsService.swift`
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`, `MessageBubbleView.swift`
- `PingIt/Features/Ping/ViewModels/CreatePingViewModel.swift`
- `PingIt/Features/Ping/Views/CreatePingView.swift`, `PingDetailView.swift`
- `PingIt/App/MainTabView.swift`
- `firestore.rules`
- `PingItTests/Mocks/MockChatService.swift`, `MockPingService.swift`
- `PingItTests/ViewModelTests/ChatViewModelTests.swift`, `CreatePingViewModelTests.swift`

---

## [2026-05-07] — App Icon, Performance Monitoring, Beta Testing Docs, Spec Alignment

### Summary
Phase 2 Session 3: Added app icon, Firebase Performance Monitoring, Beta Testing guide, and aligned project spec with actual implementation.

### Added — App Icon
- Resized `logo.png` (1254x1254) to 1024x1024 `AppIcon.png` in `AppIcon.appiconset`.
- Updated `Contents.json` with `"filename": "AppIcon.png"` for light, dark, and tinted slots (same image for all three; can be replaced with distinct variants later).

### Added — Firebase Performance Monitoring
- `PerformanceServicing` protocol with `startTrace(name:)` and `PerformanceTrace` protocol for custom traces.
- `PerformanceService`: `@Observable @MainActor` wrapper around `FirebasePerformance`. `startTrace()` is `nonisolated` for use from any context. `FirebasePerformanceTrace` struct bridges to the SDK's `Trace` type.
- `MockPerformanceService` + `MockPerformanceTrace` for test assertions.
- `FirebasePerformance` SPM product added to Xcode project.
- `PerformanceService` wired into `PingItApp.swift` via `@State` + `.environment()`.
- Firebase Performance automatically captures app startup time, network request metrics, and screen rendering traces once linked.

### Added — Beta Testing Documentation
- `docs/BETA_TESTING.md`: Full guide covering Apple Developer enrollment prerequisites, APNs Auth Key setup, Xcode signing configuration, App Store Connect setup, TestFlight archive/upload workflow, ExportOptions.plist template, internal/external tester management, tester onboarding template, feedback collection process, and timeline estimate.

### Changed — Project Spec Alignment
- Updated `project_spec.md` data model to reflect actual Firestore collections (removed unimplemented `userPreferences`, `cities`, `notifications`, `pingMedia`, `follows`; added implementation notes explaining each decision).
- Updated tech stack: GeoFirestore deferred (single Firestore listener at thesis scale), FirebasePerformance added.
- Content Review Queue description updated to reflect Firebase Console + runbook approach.
- Performance Monitoring added as 11th Phase 2 feature (total: 41 features).
- Clarified Apple Developer enrollment blockers on APNs, TestFlight, and App Store submission.

### Blocker
- Beta Testing implementation requires Apple Developer Program enrollment ($99/yr, 2-5 day approval). Not yet enrolled.

### Files Created
- `PingIt/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
- `PingIt/Core/Protocols/PerformanceServicing.swift`
- `PingIt/Core/Services/PerformanceService.swift`
- `PingItTests/Mocks/MockPerformanceService.swift`
- `docs/BETA_TESTING.md`

### Files Modified
- `PingIt/Assets.xcassets/AppIcon.appiconset/Contents.json`
- `PingIt/App/PingItApp.swift`
- `PingIt.xcodeproj/project.pbxproj` (added FirebasePerformance SPM product)
- `project_spec.md` (v1.2 — spec-to-implementation alignment)
- `ARCHITECTURE.md`

---

## [2026-05-06] — Privacy Policy, Terms of Service, and Onboarding Flow

### Summary
Phase 2 Session 2: Added Privacy Policy and Terms of Service views (bundled HTML in WKWebView), and a 3-page onboarding tutorial flow gated before first app use.

### Added — Privacy Policy & Terms of Service
- `WebContentView`: `UIViewRepresentable` wrapper around `WKWebView` for loading bundled HTML files. Supports dark mode, external link handling.
- `PrivacyPolicyView`: Displays `privacy.html` with navigation title.
- `TermsOfServiceView`: Replaced "Coming Soon" placeholder with `WebContentView` loading `terms.html`.
- `terms.html`: Terms of Service covering eligibility, acceptable use, content moderation, location data, account termination, liability.
- `privacy.html`: Privacy Policy with GDPR compliance, data collection table, Firebase services disclosure, data retention, user rights, contact info.
- `AuthRoute.privacyPolicy` case added to auth navigation.
- `RegisterView`: TOS section now includes both "Terms of Service" and "Privacy Policy" links.
- `SettingsView`: Added "Legal" section with NavigationLinks to Terms and Privacy Policy.

### Added — Onboarding Flow
- `OnboardingViewModel`: `@Observable @MainActor` class managing 3-page tutorial. `advance()`, `skip()`, `completeOnboarding()` — updates `hasCompletedOnboarding` on Firestore user doc and logs `onboarding_completed` analytics event.
- `OnboardingPageView`: Reusable page with SF Symbol icon, title, and subtitle.
- `OnboardingView`: `TabView(.page)` container with Skip/Next/Get Started buttons. Shows once per user.
- `User.hasCompletedOnboarding: Bool` field added to User model.
- `RootView`: Onboarding gate between suspension check and MainTabView — shows `OnboardingView` when `hasCompletedOnboarding == false`.
- `firestore.rules`: Added `hasCompletedOnboarding` to both `safeUserCreate` and `safeUserUpdate` allowed fields.

### Added — Tests
- `OnboardingViewModelTests`: 8 tests covering page navigation, skip, completion, analytics logging, error handling, and initial state.

### Files Created
- `PingIt/Features/Authentication/Views/WebContentView.swift`
- `PingIt/Features/Authentication/Views/PrivacyPolicyView.swift`
- `PingIt/Resources/terms.html`
- `PingIt/Resources/privacy.html`
- `PingIt/Features/Onboarding/ViewModels/OnboardingViewModel.swift`
- `PingIt/Features/Onboarding/Views/OnboardingView.swift`
- `PingIt/Features/Onboarding/Views/OnboardingPageView.swift`
- `PingItTests/ViewModelTests/OnboardingViewModelTests.swift`

### Files Modified
- `PingIt/Features/Authentication/Views/TermsOfServiceView.swift`
- `PingIt/Features/Authentication/Models/AuthRoute.swift`
- `PingIt/Features/Authentication/Views/AuthenticationCoordinatorView.swift`
- `PingIt/Features/Authentication/Views/RegisterView.swift`
- `PingIt/Features/Settings/Views/SettingsView.swift`
- `PingIt/Core/Models/User.swift`
- `PingIt/App/RootView.swift`
- `firestore.rules`

---

## [2026-05-06] — Custom Ping Duration + Firebase Analytics + Crashlytics

### Summary
Phase 2 Session 1: Added custom ping duration selection, Firebase Analytics event tracking, and Firebase Crashlytics crash reporting.

### Added — Custom Ping Duration
- `Constants.Ping.customDurationMin` / `customDurationMax` for custom range (1–48 hours).
- `CreatePingViewModel`: `isCustomDuration` and `customDurationHours` properties with clamped boundary validation.
- `CreatePingView`: 4th "Custom" segment in expiration Picker, `Stepper` for hour selection with accessibility labels.
- 4 new unit tests: preset returns correct duration, custom duration returns correct seconds, boundary clamping at 1h and 48h.

### Added — Firebase Analytics
- `AnalyticsServicing` protocol with `logEvent()` and `setUserId()`.
- `AnalyticsService` wrapping `FirebaseAnalytics.Analytics`. Event constants: `ping_created`, `chat_joined`, `boost_used`, `onboarding_completed`.
- `MockAnalyticsService` for test assertions.
- Events logged after: successful ping creation (with duration type/hours), chat join, and boost.
- User ID set on auth state change, cleared on sign-out.
- `AnalyticsService` injected into environment from `PingItApp` and passed to `CreatePingViewModel`, `ChatViewModel`, `PingDetailViewModel`.

### Added — Firebase Crashlytics
- `CrashReportingServicing` protocol with `setUserId()` and `record(error:)`.
- `CrashReportingService` wrapping `Crashlytics.crashlytics()`.
- `MockCrashReportingService` for test assertions.
- User ID set on auth state change, cleared on sign-out.
- `CrashReportingService` injected into environment from `PingItApp`.

### Changed — SPM Dependencies
- Added `FirebaseAnalytics` and `FirebaseCrashlytics` products from existing `firebase-ios-sdk` package.

### Files Created
- `PingIt/Core/Protocols/AnalyticsServicing.swift`
- `PingIt/Core/Protocols/CrashReportingServicing.swift`
- `PingIt/Core/Services/AnalyticsService.swift`
- `PingIt/Core/Services/CrashReportingService.swift`
- `PingItTests/Mocks/MockAnalyticsService.swift`
- `PingItTests/Mocks/MockCrashReportingService.swift`

### Files Modified
- `PingIt/Core/Utilities/Constants.swift`
- `PingIt/App/PingItApp.swift`
- `PingIt/Features/Ping/ViewModels/CreatePingViewModel.swift`
- `PingIt/Features/Ping/Views/CreatePingView.swift`
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingItTests/ViewModelTests/CreatePingViewModelTests.swift`
- `PingIt.xcodeproj/project.pbxproj`

---

## [2026-05-06] — Server-Authoritative Firestore Writes + Duplicate Report Fix

### Summary
Moved destructive ping cleanup, boost counters, chat participant counters, username availability, and report duplicate prevention behind server-authoritative flows. The iOS client now requests intent through callables while Cloud Functions validate ownership, suspension state, active ping state, block relationships, and duplicate state before writing with Admin SDK privileges.

### Added — Cloud Functions (`functions/src/`)
- **`pingCleanup.ts`** — Shared chunked cleanup helper for ping-related data. Deletes associated chats, messages, participants, and boosts while keeping batches under Firestore write limits.
- **`pingCallables.ts`** — `deletePing`, `boostPing`, `joinChat`, and `leaveChat` callables.
- **`reportCallables.ts`** — `submitReport` callable with deterministic report IDs and `already-exists` duplicate response.

### Changed — Cloud Functions
- **`expirePings.ts`**, **`removeContent.ts`**, and **`deleteAccount.ts`** now share `pingCleanup` for consistent cascade behavior.
- **`sendHotPingNotification.ts`** now uses a participant write trigger so rejoin transitions can re-check hot status.
- **`deleteAccount.ts`** also removes username reservation documents.

### Changed — Firestore Rules
- Direct client updates/deletes for `pings` and `chats` are denied.
- Direct client creates/updates/deletes for `boosts`, `chatParticipants`, and `reports` are denied.
- `users` no longer allows unauthenticated listing; owner updates are restricted to safe profile/preference fields.
- Added `usernames/{normalizedUsername}` reservation documents for public username availability `get` without public `users` queries.
- `reports` are now server-created only through `submitReport`.

### Changed — iOS
- **`PingService`** calls `deletePing` and `boostPing`; boost UI uses the server-returned count.
- **`ChatService`** calls `joinChat` and `leaveChat`; `ChatViewModel` stores `chatId` as the leave key.
- **`ReportService`** calls `submitReport` and maps Firebase Functions `already-exists` to `PingItError.reportAlreadySubmitted`.
- **`AuthService`** and **`UserService`** create/delete username reservation documents during signup and username rename.

### Added — Tests
- Added duplicate report regression coverage ensuring repeated reports show the existing "You have already reported this content." UI error instead of a false success.

### Documentation
- Updated architecture, Firebase, security, risk, project status, E2E, audit, runbook, and spec docs for the server-authoritative design.

### Files Created
- `functions/src/pingCallables.ts`
- `functions/src/pingCleanup.ts`
- `functions/src/reportCallables.ts`

### Files Significantly Modified
- `firestore.rules`
- `functions/src/index.ts`
- `functions/src/deleteAccount.ts`
- `functions/src/expirePings.ts`
- `functions/src/removeContent.ts`
- `functions/src/sendHotPingNotification.ts`
- `PingIt/Core/Services/PingService.swift`
- `PingIt/Core/Services/ChatService.swift`
- `PingIt/Core/Services/ReportService.swift`
- `PingIt/Core/Services/AuthService.swift`
- `PingIt/Core/Services/UserService.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingItTests/ViewModelTests/ReportViewModelTests.swift`

---

## [2026-05-02] — Audit Remediation: Security, Privacy, Polish, Accessibility

### Summary
Addressed 9 critical/high/medium audit findings: hardened Firestore rules, enforced suspension and privacy settings, expanded moderation, wired notification navigation, added empty/error states, paginated chat messages, and added accessibility labels across the app.

### Changed — Firestore Rules (`firestore.rules`)
- **Pings update rule hardened:** Restricted client-side update to `boostCount` increment-by-1 from non-creators only (Cloud Functions bypass via admin SDK)
- **`moderationActions` collection:** Added explicit deny-all rule for client reads/writes

### Added — Suspension Enforcement
- **`User.swift`** — Added `suspensionStatus: String?` and `suspensionExpiresAt: Date?` fields
- **`SuspendedAccountView.swift`** — Full-screen suspension gate: expiry date, contact email, sign-out
- **`RootView.swift`** — Suspension check on login: fetches user profile, shows SuspendedAccountView for suspended/banned users

### Added — Privacy Profile Enforcement
- **`PingDetailViewModel.swift`** — `shouldHideCreatorIdentity` computed property: hides creator username/photo for private profiles (non-creators)
- **`PingDetailView.swift`** — Passes "Anonymous" + nil image URL when creator has private profile

### Changed — Moderation
- **`moderation_wordlist.txt`** — Expanded from 10 to ~150 words (English profanity, slurs, hate speech, Romanian profanity)

### Added — Notification Tap Navigation
- **`NavigationRouter.swift`** — `@Observable` router with `pendingPingId` for deep linking from push notifications
- **`PingItApp.swift`** — Observes `PingItOpenPing` notification, sets `navigationRouter.pendingPingId`
- **`MainTabView.swift`** — Switches to Map tab on pending notification; uses `AppTab` enum for tab selection
- **`MapView.swift`** — Fetches and navigates to ping from `pendingPingId`; shows alert if ping unavailable

### Added — Empty & Error States
- **`MapView.swift`** — Empty state overlay ("No pings nearby"), location denied banner with Settings link
- **`BlockedUsersView.swift`** — Error state display using `ContentUnavailableView`

### Changed — Chat Pagination
- **`ChatServicing.swift`** — Added `fetchMessages(chatId:before:limit:)` and `observeNewMessages(chatId:after:onUpdate:)` protocol methods
- **`ChatService.swift`** — Implemented paginated fetch (50 per page, ordered by createdAt) and real-time listener for new messages only
- **`ChatViewModel.swift`** — `loadInitialMessages()` + `loadMoreMessages()` replace unlimited snapshot listener; tracks `isLoadingMore`/`hasMoreMessages`
- **`ChatView.swift`** — "Load earlier messages" button at top of chat when more messages available

### Added — Accessibility
- Labels, hints, and element grouping across 10+ view files: PingDetailCreatorSection, PingDetailView, PingDetailActionSection, CreatePingView, ChatView, MessageBubbleView, MapView, EmailVerificationBannerView, ProfileImageSection, BlockedUsersView

### Added — Tests
- **`SuspensionTests.swift`** — 7 tests covering suspension logic (active, expired, permanent, banned, unknown status)
- **`PrivacyProfileTests.swift`** — 4 tests for private profile enforcement on PingDetailViewModel
- **`ContentModerationTests.swift`** — 4 tests for expanded wordlist (profanity, clean text, case insensitive, Romanian)

### Files Created
- `PingIt/Features/Authentication/Views/SuspendedAccountView.swift`
- `PingIt/App/NavigationRouter.swift`
- `PingItTests/SuspensionTests.swift`
- `PingItTests/ViewModelTests/PrivacyProfileTests.swift`
- `PingItTests/ContentModerationTests.swift`

### Files Modified
- `firestore.rules`, `docs/FIREBASE.md`
- `PingIt/Core/Models/User.swift`
- `PingIt/App/PingItApp.swift`, `RootView.swift`, `MainTabView.swift`
- `PingIt/Core/Protocols/ChatServicing.swift`
- `PingIt/Core/Services/ChatService.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`, `PingDetailCreatorSection.swift`, `PingDetailActionSection.swift`, `CreatePingView.swift`
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`, `MessageBubbleView.swift`
- `PingIt/Features/Map/Views/MapView.swift`, `EmailVerificationBannerView.swift`
- `PingIt/Features/Profile/Views/ProfileImageSection.swift`
- `PingIt/Features/Settings/Views/BlockedUsersView.swift`
- `PingIt/Resources/moderation_wordlist.txt`
- `PingItTests/Mocks/MockChatService.swift`

---

## [2026-05-01] — Phase 1 Sprint 4: Moderation Pipeline (Phase 1 Complete)

### Summary
Final sprint of Phase 1: deployed automated image moderation via Vision API SafeSearch and admin emergency content removal Cloud Function. Added admin moderation runbook. All 16 Phase 1 features now complete.

### Added — Cloud Functions (`functions/src/`)
- **`moderateImage`** — Storage trigger (`onObjectFinalized`): scans uploads in `profile_pictures/` and `ping_images/` via Vision API SafeSearch. `VERY_LIKELY` inappropriate content is auto-deleted (file removed, Firestore updated: `profileImageUrl` nullified or ping `status` set to "removed"). `LIKELY` content creates a `reports` document for manual review. All auto-removals logged to `moderationActions` collection.
- **`removeContent`** — Callable function for admin emergency content removal. Verifies caller email against `ADMIN_EMAILS` environment param. Supports three target types: `ping` (status="removed" + cascade delete chat/messages/participants), `message` (delete), `user` (24hr suspension). All actions logged to `moderationActions` audit trail.

### Added — Documentation
- **`docs/ADMIN_MODERATION_RUNBOOK.md`** — Manual review workflow for Firebase Console: pending reports, content review steps, `removeContent` CLI usage, SLA targets, audit trail reference, word list update process.

### Changed
- **`.gitignore`** — Changed `docs/` to `docs/*` with `!docs/ADMIN_MODERATION_RUNBOOK.md` negation to track the runbook in version control while keeping other docs local.
- **`functions/src/index.ts`** — Added exports for `moderateImage` and `removeContent`
- **`functions/package.json`** — Added `@google-cloud/vision` dependency

---

## [2026-05-01] — Sprint 3 E2E fixes: Firestore rules, report snapshots, stale state, pin overlap

### Summary
Bug fixes discovered during E2E testing. Added Firestore security rules, fixed chat participant rejoin duplicates, added content snapshots to reports for audit trail, added boost cleanup to ping expiration, fixed stale block/rate-limit state surviving account switches, and improved pin overlap separation for nearby pings.

### Added
- **`firestore.rules`** — Security rules for all 8 collections (users, pings, chats, chatMessages, chatParticipants, boosts, blocks, reports). Owner-gated writes, unauthenticated list on users for username availability check during registration.
- **`Report` model** — Added `targetContent: String?` and `targetImageURL: String?` fields to snapshot reported content at report time (survives ping expiration/deletion)

### Fixed
- **Stale state on account switch** — `BlockService.stopObserving()` and `RateLimitService.resetForSignOut()` now called from `PingItApp.onChange` when auth state becomes nil. Previously, blocked user IDs and rate limit timestamps from a deleted/signed-out account persisted in memory and affected the next logged-in user.
- **Pin overlap** — `computeDisplayCoordinates()` now groups pings within ~5m proximity (instead of exact coordinate match), so pins created from the same GPS fix are properly fanned out when zoomed in. Separation reduced to ~9m for tighter visual grouping.

### Changed
- **`firebase.json`** — Added `firestore.rules` reference
- **`PingItApp.swift`** — Added `.onChange` watching auth state to reset `BlockService` and `RateLimitService` on sign-out/account deletion
- **`RateLimitService.swift`** — Added `resetForSignOut()` to clear UserDefaults timestamps
- **`MapViewModel.swift`** — Proximity-based pin grouping (~5m threshold) replaces exact coordinate string matching; offset distance reduced to ~9m
- **`ChatService.swift`** — Fixed `joinChatIfNeeded`: removed `leftAt == NSNull()` filter (didn't match absent fields), now queries by `chatId + userId` only and clears `leftAt` on rejoin instead of creating duplicate participant docs
- **`ChatView.swift`** — Fixed `leaveChat` in `onDisappear` using `Task.detached` so it survives view teardown; passes `message.text` as `targetContent` when reporting
- **`PingDetailView.swift`** — Passes `ping.text` as `targetContent` when reporting
- **`ReportServicing.swift`** — Added `targetContent` and `targetImageURL` parameters
- **`ReportService.swift`** — Passes new content fields through to Report creation
- **`ReportViewModel.swift`** — Accepts and forwards `targetContent` and `targetImageURL`
- **`ReportView.swift`** — Accepts `targetContent` and `targetImageURL` in init
- **`MockReportService.swift`** — Updated to match new protocol signature
- **`expirePings.ts`** — Now deletes associated `boosts` docs when expiring a ping
- **`docs/FIREBASE.md`** — Replaced outdated inline rules with pointer to `firestore.rules`, updated composite index table with all 5 required indexes
- **`docs/SECURITY.md`** — Corrected blocking docs from `users.blockedUsers[]` to `blocks` collection with bidirectional filtering
- **`CLAUDE.md`** — Added Firestore indexes section requiring index updates after multi-field query implementations
- **`project_status.md`** — Updated tech debt re: Apple Developer membership blocker for push notifications

---

## [2026-04-20] — Phase 1 Sprint 3: Cloud Functions + Notifications

### Summary
First backend work for PingIt: deployed TypeScript Cloud Functions for ping expiration (cron), GDPR account deletion (callable), nearby ping notifications (Firestore trigger), and hot ping notifications (boost/join triggers). iOS side adds NotificationService for FCM token management and push notification handling, plus account deletion UI in Settings.

### Added — Cloud Functions (`functions/src/`)
- **`healthCheck`** — HTTP endpoint for deployment verification
- **`expirePings`** — Scheduled function (every 5 minutes): queries active pings where `expiresAt <= now`, sets status to "expired", cascading deletes chat + messages + participants in batched writes (500 ops max per batch)
- **`deleteAccount`** — Callable function: cascading delete of all user data (pings, chats, messages, participants, boosts, blocks, reports, profile image, user document, Auth account). Requires authentication.
- **`sendNearbyNotification`** — Firestore trigger on `pings/{pingId}` creation: queries users with FCM tokens, filters by 2km Haversine distance from `lastKnownLocation`, respects `notifyNearbyPings` preference, queries `blocks` collection for bidirectional blocking, sends FCM push notification
- **`sendHotPingNotificationOnBoost`** — Firestore trigger on `boosts/{boostId}` creation: checks if boosted ping meets hot criteria (aligned with client: `boostCount >= 3 && hotScore >= 8.0`, formula `boostCount × 2.0 + participantCount + min(hoursRemaining × 0.1, 2.0)`), must be in top 10 active pings, sends once per ping via `hotNotificationSent` flag
- **`sendHotPingNotificationOnJoin`** — Firestore trigger on `chatParticipants/{participantId}` creation: resolves ping from chatId, delegates to shared hot-check logic

### Added — iOS
- **`NotificationServicing.swift`** — Protocol: `requestPermission()`, `registerFCMToken()`, `updateLastKnownLocation(latitude:longitude:)`
- **`NotificationService.swift`** — `@Observable NSObject` subclass: UNUserNotificationCenterDelegate (foreground banners, notification tap → posts `PingItOpenPing` NotificationCenter event), MessagingDelegate (FCM token refresh → Firestore update), location update to Firestore
- **`MockNotificationService.swift`** — Test mock with call tracking
- **Delete Account UI** in SettingsView — two-step confirmation (alert → password re-auth → Cloud Function call → sign out)
- **`reauthenticate(password:)`** and **`deleteAccount()`** on AuthServicing/AuthService — re-auth via EmailAuthProvider, deleteAccount calls Cloud Function via `FirebaseFunctions` SDK

### Changed
- **`User.swift`** — Added `fcmToken: String?` and `lastKnownLocation: [String: Double]?`
- **`PingItError.swift`** — Added `accountDeletionFailed(underlying:)` case
- **`AuthServicing.swift`** — Added `reauthenticate(password:)` and `deleteAccount()` protocol requirements
- **`AuthService.swift`** — Implemented re-auth + Cloud Function-backed deletion; added `import FirebaseFunctions`
- **`MockAuthService.swift`** — Added `reauthenticateCalled`, `deleteAccountCalled` tracking
- **`PingItApp.swift`** — Added `NotificationService` as `@State`, injected via `.environment()`, sets up UNUserNotificationCenter/Messaging delegates, requests permission + registers FCM token on launch
- **`MapView.swift`** — Added `@Environment(NotificationService.self)`, updates `lastKnownLocation` on Firestore when user location is first determined
- **`SettingsView.swift`** — Added delete account section with two-step confirmation flow (initial alert → password re-auth alert → deletion)
- **`project.pbxproj`** — Added `FirebaseFunctions` and `FirebaseMessaging` SPM dependencies

### Files created
- `functions/package.json`, `functions/tsconfig.json`, `functions/.eslintrc.js`
- `functions/src/index.ts`, `functions/src/expirePings.ts`, `functions/src/deleteAccount.ts`
- `functions/src/sendNearbyNotification.ts`, `functions/src/sendHotPingNotification.ts`
- `firebase.json`, `.firebaserc`
- `PingIt/Core/Protocols/NotificationServicing.swift`
- `PingIt/Core/Services/NotificationService.swift`
- `PingItTests/Mocks/MockNotificationService.swift`

### Files significantly modified
- `PingIt/Core/Protocols/AuthServicing.swift`
- `PingIt/Core/Services/AuthService.swift`
- `PingIt/Core/Models/User.swift`
- `PingIt/Core/Utilities/PingItError.swift`
- `PingIt/App/PingItApp.swift`
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Settings/Views/SettingsView.swift`
- `PingItTests/Mocks/MockAuthService.swift`
- `PingIt.xcodeproj/project.pbxproj`
- `.gitignore`

---

## [2026-04-20] — Sprint 2 Device Testing Fixes

### Summary
Comprehensive bugfix pass after device testing of all Sprint 2 engagement features. Refined hot score formula, implemented manual clustering, fixed boost UX issues, and eliminated settings toggle flash.

### Fixed
- **Hot score formula too aggressive** — Original formula (0.5× time weight, threshold ≥5.0) caused pings to appear hot with zero boosts. Refined through 3 iterations to final: `boostCount × 2.0 + participantCount + min(hoursRemaining × 0.1, 2.0)`, gate `boostCount >= 3 && hotScore >= 8.0`. Time contribution capped at 2.0.
- **Boost count not updating in UI** — `ping` was `let` in PingDetailViewModel; changed to `private(set) var` with local `ping.boostCount += 1` after successful Firestore write.
- **Boost button race condition** — `canBoost` was momentarily `true` before async `checkBoostStatus()` completed. Added `isCheckingBoostStatus` flag defaulting to `true`; `canBoost` requires `!isCheckingBoostStatus`.
- **Overlapping pins not tappable** — Pings at identical coordinates stacked invisibly. Added `computeDisplayCoordinates()` in MapViewModel: groups pings by coordinate, offsets them in circular pattern (~0.00015° ≈ 15m).
- **Boost count hidden from ping creators** — Boost count label was inside `!isCreator` guard. Moved outside so creators can see how many boosts their ping received.
- **Settings toggles flash default values on restart** — `@State` initialized with hardcoded defaults before async Firestore fetch. Fixed with UserDefaults caching: `savePreference()` writes to both UserDefaults and Firestore; initial `@State` reads from UserDefaults; `hasLoadedPreferences` flag gates `onChange` to prevent spurious writes during load.
- **No visible clustering on map** — SwiftUI `Map` doesn't support native `MKClusterAnnotation`. Implemented manual client-side clustering algorithm in MapViewModel.
- **Cluster threshold too aggressive** — Reduced from `0.08` to `0.03` of visible region span. Added minimum span gate (`< 0.005`) to disable clustering at close zoom.

### Added
- **`PingCluster.swift`** — `PingCluster` model under `Features/Map/Models/` with `Identifiable`, center calculation, and `containsHotPing` flag.
- **`computeDisplayCoordinates()`** — MapViewModel method for offsetting overlapping pins in circular pattern.
- **`displayCoordinates` dictionary** — Maps ping IDs to offset coordinates; used by MapView `Annotation` content builder.
- **`visibleRegion` tracking** — MapViewModel stores visible region via `onMapCameraChange(frequency: .onEnd)`.
- **`updateClusters()`** — MapViewModel method: distance-based grouping → `clusters` + `unclusteredPings` arrays.
- **`zoomToCluster()`** — MapView method: calculates bounding rect with padding and animates camera.
- **Boost status tests** — `cannotBoostWhileCheckingStatus`, `canBoostAfterCheckCompletes`, `cannotBoostAfterCheckConfirmsBoosted`.
- **Hot score tests** — 7-test `PingHotScoreTests` suite covering all threshold scenarios.

### Changed
- **`Ping.swift`** — `hotScore` time weight reduced from 0.5 to 0.1, capped at 2.0. `isHot` requires `boostCount >= 3` (was no minimum).
- **`PingDetailViewModel.swift`** — `ping` changed from `let` to `private(set) var`; added `isCheckingBoostStatus` (defaults `true`); `canBoost` gated on `!isCheckingBoostStatus`.
- **`PingDetailView.swift`** — Boost count label moved outside `!isCreator` guard.
- **`MapViewModel.swift`** — Added `clusters`, `unclusteredPings`, `displayCoordinates`, `visibleRegion`; `applyBlockFilter()` calls `computeDisplayCoordinates()` + `updateClusters()`.
- **`MapView.swift`** — Renders `unclusteredPings` and `clusters` separately; uses `displayCoordinates` for annotation positions; added `onMapCameraChange` and `zoomToCluster()`.
- **`PingAnnotationView.swift`** — Extracted `pinGradient: AnyGradient` computed property to fix gradient type mismatch.
- **`SettingsView.swift`** — `@State` reads from UserDefaults (`pref_` prefix); `savePreference()` dual-writes; `cachePreferences()` after Firestore fetch; `hasLoadedPreferences` guard on `onChange`.
- **`User.swift`** — Added `isPrivateProfile`, `notifyNearbyPings`, `notifyHotPings` defaults.

### Files created
- `PingIt/Features/Map/Models/PingCluster.swift`

### Files significantly modified
- `PingIt/Core/Models/Ping.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingIt/Features/Map/ViewModels/MapViewModel.swift`
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Map/Views/PingAnnotationView.swift`
- `PingIt/Features/Settings/Views/SettingsView.swift`
- `PingItTests/ViewModelTests/PingDetailViewModelTests.swift`
- `PingItTests/PingItTests.swift`

---

## [2026-04-19] — Phase 1 Sprint 2: Engagement + Map Polish

### Summary
Implemented engagement features (boost, hot pings algorithm, ping clustering) and settings toggles (privacy, notification preferences) to make the map more compelling.

### Added
- **`Boost.swift`** — `Boost` model for `boosts` Firestore collection (pingId, userId, createdAt)
- **`PingClusterAnnotationView.swift`** — Cluster annotation showing count badge with hot-ping awareness (red vs orange gradient)
- **Boost button** in PingDetailView — non-creators can boost once; shows "Boosted" filled state with orange tint
- **Hot pings visual treatment** — flame icon (`flame.circle.fill`) with red glow for top-10 pings with hotScore ≥ 5.0
- **Notification preferences** — "Nearby Pings" and "Hot Pings" toggles in SettingsView, persisted to Firestore
- **Privacy settings** — "Private Profile" toggle in SettingsView, persisted to Firestore
- **Boost tests** — `boostPingSucceeds` and `cannotBoostOwnPing` in PingDetailViewModelTests

### Changed
- **`Ping.swift`** — Added `boostCount: Int`, `participantCount: Int`, computed `hotScore: Double` and `isHot: Bool`
- **`PingServicing.swift`** — Added `boostPing(pingId:)` and `hasUserBoostedPing(pingId:userId:)` methods
- **`PingService.swift`** — Implemented boost with batched write (boost doc + increment denormalized count)
- **`PingDetailViewModel.swift`** — Added `hasUserBoosted`, `isBoosting`, `canBoost`, `checkBoostStatus()`, `boostPing()`
- **`PingDetailView.swift`** — Added boost button section, `checkBoostStatus()` in `.task`
- **`MapViewModel.swift`** — Added `hotPingIds` computed property (top-10 by hotScore ≥ 5.0)
- **`PingAnnotationView.swift`** — Added `isHot` parameter; flame icon, red gradient, shadow for hot pings
- **`MapView.swift`** — Passes `isHot` to annotations; `.annotationTitles(.hidden)` and `.tag` for clustering
- **`User.swift`** — Added `isPrivateProfile`, `notifyNearbyPings`, `notifyHotPings` preference fields
- **`SettingsView.swift`** — Added UserService environment, notification/privacy toggle sections, Firestore persistence
- **`MockPingService.swift`** — Added boost tracking properties and methods

### Files created
- `PingIt/Core/Models/Boost.swift`
- `PingIt/Features/Map/Views/PingClusterAnnotationView.swift`

### Files significantly modified
- `PingIt/Core/Models/Ping.swift`
- `PingIt/Core/Models/User.swift`
- `PingIt/Core/Protocols/PingServicing.swift`
- `PingIt/Core/Services/PingService.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingIt/Features/Map/ViewModels/MapViewModel.swift`
- `PingIt/Features/Map/Views/PingAnnotationView.swift`
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Settings/Views/SettingsView.swift`
- `PingItTests/Mocks/MockPingService.swift`
- `PingItTests/ViewModelTests/PingDetailViewModelTests.swift`

---

## [2026-04-15] — Sprint 1 Bugfixes, Polish & Chat Sender Identity

### Summary
Comprehensive bugfix pass on all Sprint 1 safety features after device testing. Added Firebase RTDB server time sync, real-time bidirectional block enforcement, ping lifecycle awareness (deleted/expired ping detection), and chat sender identity (avatar + username on messages).

### Fixed
- **Email verification banner** now polls `reloadUser()` every 5s and auto-hides when email is verified (no sign-out/in needed)
- **Block persistence across relaunch**: MapViewModel stores `allPings` and re-filters reactively via `onChange(of: blockService.blockedUserIds)` — no longer depends on load ordering
- **Duplicate block entries**: `blockUser()` is idempotent (skips write if already in `blockedUserIds`)
- **Chat block instant update**: ChatViewModel stores `allMessages` + `applyBlockFilter()` called after blocking
- **Chat block auto-dismiss**: ChatView observes `blockedUserIds` and dismisses when ping creator is blocked; PingDetailView also observes and pops via `navigateToChat = false` + `dismiss()`
- **ReportView blank white screen**: Refactored to accept `reportService` + `blockService` via init (not `@Environment` which doesn't propagate into `.sheet`). ChatView uses `sheet(item:)` with single `ReportTarget` struct instead of three optional `@State` vars
- **Auto-dismiss PingDetailView after report+block**: `ReportView` accepts `onDidBlock` callback
- **Duplicate reports prevented**: `ReportService` queries Firestore before writing, throws `reportAlreadySubmitted`
- **Server time consistency**: Added `ServerTime` utility using Firebase RTDB `.info/serverTimeOffset`. All countdowns, expiration filters, and ping creation use `ServerTime.now` instead of `Date.now`
- **Ping deletion — creator no longer sees "unavailable" alert**: `didDeletePing` set before Firestore delete to avoid race with snapshot listener
- **Ping deletion — chat participant alerted**: ChatViewModel observes ping document; shows "Ping Unavailable" alert in ChatView, silently dismisses to PingDetailView which shows single alert then pops to map

### Added
- **`ServerTime.swift`** — Firebase RTDB `.info/serverTimeOffset` observer; `ServerTime.now` corrected current time
- **`PingServicing.observePing(id:onUpdate:)`** — Single-document Firestore snapshot listener
- **Real-time bidirectional block enforcement** — BlockService uses two Firestore snapshot listeners (`blockerId == me`, `blockedUserId == me`). When UserA blocks UserB, UserB's listener fires immediately.
- **Ping lifecycle observation** — PingDetailViewModel and ChatViewModel observe the ping document; detect deletion/expiration in real-time
- **Chat sender identity** — MessageBubbleView shows circular avatar (AsyncImage + initial-letter fallback) and bold username for other users. Consecutive same-sender messages grouped (avatar/name on first only). ChatViewModel caches User profiles per sender ID.

### Changed
- **`BlockService`** — Replaced one-time `loadBlockedUsers()` with `startObserving()`/`stopObserving()` using two Firestore snapshot listeners; `isolated deinit` for Swift 6.2 compatibility
- **`BlockServicing` protocol** — `loadBlockedUsers()` → `startObserving()`/`stopObserving()`
- **`MainTabView`** — Calls `blockService.startObserving()` instead of `loadBlockedUsers()`
- **`ChatViewModel`** — Added `pingService`, `userService`, `pingListener`, `userCache`, `pingUnavailable`, `isFirstInGroup()`, `fetchMissingUsers()`
- **`ChatView`** — Accepts `pingCreatorId`; observes `blockedUserIds` and `pingUnavailable` for auto-dismiss
- **`PingDetailView`** — Observes `blockedUserIds` (pops on block) and `pingUnavailable` (alert + dismiss); uses `@Bindable`
- **`PingDetailViewModel`** — Added `pingListener`, `pingUnavailable`, `startObservingPing()`, `stopObservingPing()`
- **`MapViewModel`** — Stores `allPings`, derives `pings` via `applyBlockFilter()`; `onChange` in MapView triggers re-filter
- **`MessageBubbleView`** — Complete rewrite: sender avatar, username, grouped messages, alignment with invisible spacers
- **`PingItApp`** — Calls `ServerTime.startObserving()` at launch; added `FirebaseDatabase` SPM dependency
- **`Date+Extensions`** — `countdownDescription` uses `ServerTime.now`; `relativeDescription` corrects for clock offset

### Files created
- `PingIt/Core/Utilities/ServerTime.swift`

### Files significantly modified
- `PingIt/Core/Services/BlockService.swift` (rewritten: snapshot listeners)
- `PingIt/Core/Protocols/BlockServicing.swift`
- `PingIt/Core/Services/ReportService.swift` (duplicate prevention)
- `PingIt/Core/Services/PingService.swift` (+ observePing)
- `PingIt/Core/Protocols/PingServicing.swift`
- `PingIt/Features/Chat/Views/ChatView.swift`
- `PingIt/Features/Chat/Views/MessageBubbleView.swift` (rewritten)
- `PingIt/Features/Chat/ViewModels/ChatViewModel.swift`
- `PingIt/Features/Ping/Views/PingDetailView.swift`
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift`
- `PingIt/Features/Map/Views/MapView.swift`
- `PingIt/Features/Map/ViewModels/MapViewModel.swift`
- `PingIt/Features/Report/Views/ReportView.swift`
- `PingIt/App/PingItApp.swift`
- `PingIt/App/MainTabView.swift`
- `PingItTests/Mocks/MockBlockService.swift`
- `PingItTests/Mocks/MockPingService.swift`

---

## [2026-04-14] — Phase 1 Sprint 1: Client-Side Safety Layer

### Summary
Implemented all client-side safety features required for App Store submission without Cloud Functions. Covers email verification gates, text content moderation, user blocking (bidirectional), user reporting, spam detection (rate limiting), and client-side expired ping filtering.

### Added
- **`Block.swift`** — `Block` model (`blockerId`, `blockedUserId`, `@ServerTimestamp createdAt`)
- **`Report.swift`** — `Report` model with nested `ReportTargetType` (.ping, .message), `ReportReason` (CaseIterable), `ReportStatus` enums
- **`BlockServicing.swift`** — Protocol: `blockedUserIds`, `blockUser`, `unblockUser`, `fetchBlockedUsers`, `isBlocked`, `loadBlockedUsers`
- **`ContentModeratingServicing.swift`** — Protocol + `ContentModerationResult` enum (.allowed / .blocked(reason:))
- **`RateLimitServicing.swift`** — Protocol + `RateLimitResult` enum (.allowed / .limited(retryAfter:))
- **`ReportServicing.swift`** — `submitReport(targetType:targetId:targetOwnerId:reason:details:) async throws`
- **`BlockService.swift`** — `@Observable @MainActor`; bidirectional Firestore blocking; updates `users` blockedUsers array; in-memory `Set<String>` for O(1) lookup
- **`ContentModerationService.swift`** — Loads `moderation_wordlist.txt` from bundle; `localizedStandardContains()` case-insensitive matching
- **`RateLimitService.swift`** — UserDefaults-backed limits: 5 pings/hr + 10/day, 6 messages/10s; `#if DEBUG return .allowed` bypass
- **`ReportService.swift`** — Writes `Report` to Firestore `reports` collection
- **`moderation_wordlist.txt`** — Bundle resource: profanity wordlist (one word per line)
- **`EmailVerificationBannerView.swift`** — Dismissable banner shown in MapView for unverified users with resend action
- **`BlockedUsersViewModel.swift`** — `configure(blockService:userService:)`, loads blocks with user profiles, `unblockUser(userId:)`
- **`BlockedUsersView.swift`** — Settings screen: list of blocked users with avatar/username, unblock confirmation alert
- **`ReportViewModel.swift`** — Reason selection, submit, `showBlockOffer = true` after success
- **`ReportView.swift`** — `NavigationStack` + `Form`: reason picker (checkmark), details field, submitted state with block offer
- **`MockBlockService.swift`**, **`MockContentModerationService.swift`**, **`MockRateLimitService.swift`**, **`MockReportService.swift`** — Test mocks with call tracking and injectable results
- **`BlockedUsersViewModelTests.swift`** (2 tests), **`ReportViewModelTests.swift`** (3 tests)
- New tests in existing suites: expired ping filter, blocked creator filter (Map), email verification gate, blocked message filter, moderation gate (Chat), email verification gate, moderation gate, rate limit gate (CreatePing)

### Changed
- **`AuthServicing.swift`** — Added `isEmailVerified: Bool`, `sendEmailVerification() async throws`, `reloadUser() async throws`
- **`AuthUserRepresentable.swift`** — Added `isEmailVerified: Bool`
- **`AuthService.swift`** — Implemented new protocol requirements; `signUp()` now calls `sendEmailVerification()` after account creation
- **`PingItError.swift`** — Added: `emailVerificationFailed`, `emailNotVerified`, `contentModerated(reason:)`, `blockFailed`, `unblockFailed`, `cannotBlockSelf`, `reportFailed`, `reportAlreadySubmitted`, `rateLimited(retryAfterMinutes:)`
- **`Constants.swift`** — Added `Firestore.blocksCollection`, `Firestore.reportsCollection`, `Firestore.boostsCollection`
- **`MapViewModel.swift`** — Added `blockService` property; filters pings where `expiresAt <= Date.now` and `blockService.isBlocked(ping.creatorId)`
- **`CreatePingViewModel.swift`** — Added `contentModerationService` + `rateLimitService`; `createPing()` gates: email verification → rate limit → text validation → moderation → location → write → `recordPingCreation()`
- **`ChatViewModel.swift`** — Added `contentModerationService`, `blockService`, `rateLimitService`; `startObserving()` filters blocked senders; `sendMessage()` gates: email verification → moderation → rate limit → write → `recordMessageSent()`
- **`MapView.swift`** — Added `@Environment(BlockService.self)`, email verification banner (ZStack overlay), `handleResendVerification()`
- **`ChatView.swift`** — Added `@Environment(BlockService.self)`, `@Environment(RateLimitService.self)`, report state vars, ReportView sheet, context menu block action
- **`CreatePingView.swift`** — Added `@Environment(RateLimitService.self)`, passes to `viewModel.configure()`
- **`PingDetailView.swift`** — Added block confirmation alert, report sheet; non-creator users see report/block buttons
- **`MessageBubbleView.swift`** — Added `onReport` and `onBlock` closures; `.contextMenu` for other-user messages
- **`SettingsView.swift`** — Added "Privacy & Safety" section with `BlockedUsersView` navigation link
- **`PingItApp.swift`** — Added `contentModerationService`, `blockService`, `reportService`, `rateLimitService` as `@State` properties; all injected via `.environment()`
- **`MainTabView.swift`** — Added `@Environment(BlockService.self)`; `blockService.loadBlockedUsers()` on launch
- **`MockAuthUser.swift`** — Added `isEmailVerified: Bool = false`
- **`MockAuthService.swift`** — Added `isEmailVerified`, `sendEmailVerificationCalled`, `reloadUserCalled`
- **`MockPingService.swift`** — Added missing `import Foundation` and `import FirebaseFirestore`

### Files created
- `PingIt/Core/Models/Block.swift`
- `PingIt/Core/Models/Report.swift`
- `PingIt/Core/Protocols/BlockServicing.swift`
- `PingIt/Core/Protocols/ContentModeratingServicing.swift`
- `PingIt/Core/Protocols/RateLimitServicing.swift`
- `PingIt/Core/Protocols/ReportServicing.swift`
- `PingIt/Core/Services/BlockService.swift`
- `PingIt/Core/Services/ContentModerationService.swift`
- `PingIt/Core/Services/RateLimitService.swift`
- `PingIt/Core/Services/ReportService.swift`
- `PingIt/Resources/moderation_wordlist.txt`
- `PingIt/Features/Map/Views/EmailVerificationBannerView.swift`
- `PingIt/Features/Settings/ViewModels/BlockedUsersViewModel.swift`
- `PingIt/Features/Settings/Views/BlockedUsersView.swift`
- `PingIt/Features/Report/ViewModels/ReportViewModel.swift`
- `PingIt/Features/Report/Views/ReportView.swift`
- `PingItTests/Mocks/MockBlockService.swift`
- `PingItTests/Mocks/MockContentModerationService.swift`
- `PingItTests/Mocks/MockRateLimitService.swift`
- `PingItTests/Mocks/MockReportService.swift`
- `PingItTests/ViewModelTests/BlockedUsersViewModelTests.swift`
- `PingItTests/ViewModelTests/ReportViewModelTests.swift`

---

## [2026-04-14] — Auth Screen Bug Fixes & Polish

### Fixed
- **Firebase error mapping:** Added `AuthErrorCode.invalidCredential` (code 17995) mapping to `.wrongPassword` and `.tooManyRequests` to `.networkError` in `PingItError.from(authError:)`. Updated `.wrongPassword` message to "Incorrect email or password." to cover both wrong password and invalid credential cases.
- **Forgot password error suppression:** `AuthService.sendPasswordReset` now silently suppresses all errors (uses `try?`) to prevent email enumeration — success state is always shown. Message updated to "If an account exists for **[email]**, a reset link has been sent." so users can spot typos.
- **Terms of Service link:** Replaced invisible `EmptyView` overlay with `NavigationLink("Terms of Service", value: AuthRoute.termsOfService)` in an `HStack` — the link is now actually tappable.
- **`ForgotPasswordViewModel`:** Added missing `emailValidationMessage` computed property.
- **`PingItTests.swift`:** Removed stale `UsernameValidationTests` struct referencing removed `LoginViewModel` properties (`username`, `isSignUp`, `isUsernameValid`).

### Changed
- **Scroll-to-dismiss keyboard:** Added `.scrollDismissesKeyboard(.immediately)` to `LoginView`, `RegisterView`, and `ForgotPasswordView` — consistent with `ChatView`, `ProfileView`, and `CreatePingView`.
- **Email enumeration protection disabled** in Firebase console — `userNotFound` now returns a distinct error code, enabling the "No account found with this email." message on login.

### Files modified
- `PingIt/Core/Utilities/PingItError.swift`
- `PingIt/Core/Services/AuthService.swift`
- `PingIt/Features/Authentication/ViewModels/ForgotPasswordViewModel.swift`
- `PingIt/Features/Authentication/Views/LoginView.swift`
- `PingIt/Features/Authentication/Views/RegisterView.swift`
- `PingIt/Features/Authentication/Views/ForgotPasswordView.swift`
- `PingItTests/PingItTests.swift`

---

## [2026-04-13] — Production-Ready Authentication Screens

### Summary
Replaced the minimal single-screen auth UI with a full Welcome → Login / Register / ForgotPassword flow. Added client-side validation, password strength, unique username checking, and user-friendly Firebase error messages.

### Added
- `AuthenticationCoordinatorView` — `NavigationStack` with type-safe `AuthRoute` routing
- `WelcomeView` — landing screen with Sign In / Create Account buttons
- `RegisterView` — registration form with email, username availability, password strength, confirm password, ToS
- `ForgotPasswordView` — password reset via Firebase, success confirmation state
- `TermsOfServiceView` — placeholder screen (Phase 2: WebView on Firebase Hosting)
- `AuthTextField` — shared field component with icon, validation state indicator
- `AuthSecureField` — password field with show/hide toggle
- `PasswordStrengthView` — 4-segment strength bar + rule checklist
- `PasswordValidator` — pure `Sendable` struct: min 8 chars, uppercase, lowercase, digit rules
- `RegisterViewModel` — full registration logic with debounced (500ms) Firestore username uniqueness check
- `ForgotPasswordViewModel` — password reset request state
- `AuthRoute` enum for type-safe navigation
- `AuthServicing.sendPasswordReset(email:)` — Firebase password reset
- `UserServicing.isUsernameTaken(_:)` — Firestore query on `usernameLowercase` field
- `User.usernameLowercase` — lowercase username field for case-insensitive uniqueness queries
- `PingItError` new cases: `emailAlreadyInUse`, `invalidEmail`, `weakPassword`, `userNotFound`, `wrongPassword`, `networkError`, `passwordResetFailed`, `passwordsDoNotMatch`, `termsNotAccepted`, `passwordTooShort`, `passwordMissingUppercase`, `passwordMissingLowercase`, `passwordMissingDigit`, `usernameAlreadyTaken`
- `PingItError.from(authError:)` — maps `AuthErrorCode` to user-friendly errors
- `Constants.Email.validationPattern`, `Constants.Password.minLength`, `Constants.Username.uniquenessCheckDebounceMilliseconds`
- ~25 new unit tests: `PasswordValidatorTests`, `RegisterViewModelTests`, `ForgotPasswordViewModelTests`

### Changed
- `LoginView` — replaced entirely; now sign-in only with `AuthTextField`, `AuthSecureField`, `AuthRoute` navigation
- `LoginViewModel` — stripped of sign-up logic; added `@MainActor`, email validation, `isPasswordVisible`
- `LoginViewModelTests` — removed sign-up tests; added email validation tests
- `RootView` — swapped `LoginView()` for `AuthenticationCoordinatorView()`
- `AuthService` — error mapper applied to `signIn`/`signUp`; `sendPasswordReset` added; writes `usernameLowercase` on sign-up
- `UserService` — `isUsernameTaken` added
- `MockAuthService` / `MockUserService` — updated for new protocol methods
- All existing test files using `User(username:email:)` updated to include `usernameLowercase`

### Files created or significantly modified
- `PingIt/Features/Authentication/Models/AuthRoute.swift` *(new)*
- `PingIt/Features/Authentication/Models/PasswordValidator.swift` *(new)*
- `PingIt/Features/Authentication/ViewModels/RegisterViewModel.swift` *(new)*
- `PingIt/Features/Authentication/ViewModels/ForgotPasswordViewModel.swift` *(new)*
- `PingIt/Features/Authentication/ViewModels/LoginViewModel.swift` *(modified)*
- `PingIt/Features/Authentication/Views/AuthenticationCoordinatorView.swift` *(new)*
- `PingIt/Features/Authentication/Views/WelcomeView.swift` *(new)*
- `PingIt/Features/Authentication/Views/LoginView.swift` *(replaced)*
- `PingIt/Features/Authentication/Views/RegisterView.swift` *(new)*
- `PingIt/Features/Authentication/Views/ForgotPasswordView.swift` *(new)*
- `PingIt/Features/Authentication/Views/TermsOfServiceView.swift` *(new)*
- `PingIt/Features/Authentication/Views/Components/AuthTextField.swift` *(new)*
- `PingIt/Features/Authentication/Views/Components/AuthSecureField.swift` *(new)*
- `PingIt/Features/Authentication/Views/Components/PasswordStrengthView.swift` *(new)*
- `PingIt/Core/Models/User.swift` *(modified — added usernameLowercase)*
- `PingIt/Core/Utilities/Constants.swift` *(modified)*
- `PingIt/Core/Utilities/PingItError.swift` *(modified)*
- `PingIt/Core/Protocols/AuthServicing.swift` *(modified)*
- `PingIt/Core/Protocols/UserServicing.swift` *(modified)*
- `PingIt/Core/Services/AuthService.swift` *(modified)*
- `PingIt/Core/Services/UserService.swift` *(modified)*
- `PingIt/App/RootView.swift` *(modified)*
- `PingItTests/Mocks/MockAuthService.swift` *(modified)*
- `PingItTests/Mocks/MockUserService.swift` *(modified)*
- `PingItTests/ViewModelTests/PasswordValidatorTests.swift` *(new)*
- `PingItTests/ViewModelTests/RegisterViewModelTests.swift` *(new)*
- `PingItTests/ViewModelTests/ForgotPasswordViewModelTests.swift` *(new)*
- `PingItTests/ViewModelTests/LoginViewModelTests.swift` *(modified)*

---

## [2026-04-13] — Testability Refactor: Protocol Abstractions + ViewModel Unit Tests

### Added
- **`PingIt/Core/Protocols/`** — New directory containing all service protocol abstractions
  - `ListenerRemovable.swift` — `ListenerHandle` concrete class wrapping `ListenerRegistration` (Firebase's `ListenerRegistration` is an ObjC protocol and can't retroactively conform to a Swift protocol)
  - `AuthUserRepresentable.swift` — Minimal user identity protocol (`.uid` only)
  - `FirebaseUser+AuthUserRepresentable.swift` — Conformance extension for `FirebaseAuth.User`
  - `AuthServicing.swift`, `PingServicing.swift`, `ChatServicing.swift`, `UserServicing.swift`, `LocationServicing.swift`
- **`PingItTests/Mocks/`** — Mock implementations for all 5 services + helpers
  - `MockListenerRemovable`, `MockAuthUser`, `MockAuthService`, `MockPingService`, `MockChatService`, `MockUserService`, `MockLocationService`
  - All mocks are `@Observable @MainActor final class` types with call-tracking and injectable errors
- **`PingItTests/ViewModelTests/`** — 6 ViewModel test suites (~40 new tests)
  - `CreatePingViewModelTests`, `ChatViewModelTests`, `PingDetailViewModelTests`, `LoginViewModelTests`, `MapViewModelTests`, `ProfileViewModelTests`

### Changed
- **`AuthService`** — Conforms to `AuthServicing`; `currentUser` type changed from `FirebaseAuth.User?` to `(any AuthUserRepresentable)?`
- **`PingService`** — Conforms to `PingServicing`; `createPingWithChat` drops unused `chatService` parameter; `observeActivePings` returns `any ListenerRemovable`
- **`ChatService`** — Conforms to `ChatServicing`; `observeMessages` returns `any ListenerRemovable`
- **`UserService`** — Conforms to `UserServicing`
- **`LocationService`** — Conforms to `LocationServicing`
- **All 6 ViewModels** — Service stored properties and `configure()` parameters changed from concrete types to protocol existentials (`any AuthServicing`, etc.); `listenerRegistration` changed to `(any ListenerRemovable)?`
- **`MapViewModel`, `ChatViewModel`, `PingDetailViewModel`** — Removed now-unnecessary `FirebaseAuth`/`FirebaseFirestore` imports

---

## [2026-03-29] — Chat Core + Launch Screen (Phase 0 MVP Complete)

### Added
- **ChatViewModel** — Real-time message listener, join chat, send messages
- **ChatView** — Message list with LazyVStack, auto-scroll on new messages, text input with send button
- **MessageBubbleView** — Sender-aligned bubbles with timestamps
- **LaunchScreen.storyboard** — Branded launch screen with logo
- **App Icon** — Custom PingIt icon in asset catalog

### Changed
- ChatService.observeMessages updated to Result pattern, client-side sorting (fixes @ServerTimestamp ordering)
- PingDetailView "Join Chat" wired to navigate to ChatView
- MapView: fixed pings not loading on first launch (configure before startObserving in .task)
- Chat auto-scrolls to bottom via ScrollPosition on new messages
- Keyboard dismiss on scroll in ChatView

### Removed
- `ChatPlaceholderView.swift` — Replaced by ChatView

---

## [2026-03-29] — Authentication Features + ViewModel Refactor

### Added
- **LoginViewModel** — Username validation (3-20 chars, alphanumeric + underscore), form state management
- **LoginView** — Username TextField during sign-up, real-time validation feedback
- **ProfileViewModel** — Profile loading, username editing, Firebase Storage photo upload/remove
- **ProfileView** — Form with AsyncImage profile picture, PhotosPicker, username editor, account info
- **ProfileImageSection** — Extracted subview for profile picture display and management
- **SettingsView** — Renamed from placeholder, added sign-out confirmation dialog
- **Constants.Username** — minLength, maxLength, allowedCharacterPattern
- **Constants.Storage** — profilePicturesPath, maxProfileImageSizeBytes, imageCompressionQuality
- **PingItError** — Added 6 profile-related error cases
- **PingDetailCreatorSection/ActionSection** — Extracted from PingDetailView to separate files
- **17 new tests** — Username validation (parameterized + individual), constants (35 total)

### Changed
- **ViewModel pattern refactored** — All ViewModels now use parameterless init + `configure()` method instead of service injection via init. Views use `@State private var viewModel = SomeVM()` (non-optional) with `@Bindable` for direct `$viewModel.property` bindings.
- **Zero `Binding(get:set:)` in view bodies** — Eliminated from CreatePingView and all other views per swiftui-pro rules
- **MapViewModel, CreatePingViewModel, PingDetailViewModel** — Refactored to configure pattern
- **MapView, CreatePingView, PingDetailView** — Updated to use @Bindable and .task for configuration

### Removed
- `ProfilePlaceholderView.swift` — Replaced by ProfileView
- All `Binding(get:set:)` usage from view bodies

---

## [2026-03-29] — Location Picker for Ping Creation

### Changed
- **project_spec.md** — Feature #7 updated: ping location is user-selected (current GPS, search address, or drag pin on map), not auto-populated. Saved Places deferred to Phase 2+.
- **ARCHITECTURE.md** — Ping creation flow updated to include LocationPickerView with three location selection modes

---

## [2026-03-29] — Ping Core Features

### Added
- **CreatePingViewModel** — Ping creation with text validation (280 char limit), expiration picker, location boundary check, Firestore write with auto-created chat
- **CreatePingView** — Form with TextField (vertical axis), segmented expiration picker (6h/24h/48h), character counter, presented as sheet from map
- **PingDetailViewModel** — Loads creator profile, countdown timer via Task.sleep, cascade delete (ping + chat)
- **PingDetailView** — Full detail with creator info, countdown, join chat button, delete with confirmation dialog (creator only)
- **ChatService.createChat/deleteChat** — Chat document CRUD for ping lifecycle
- **PingService.createPingWithChat** — Atomic-ish ping + chat creation with chatId backlink
- **Ping model** — Added Hashable conformance for navigationDestination
- **MapView** — "Create Ping" toolbar button (sheet), annotation tap → PingDetailView navigation
- **UserService + ChatService** added to environment injection (5 total services)

### Changed
- MapView annotation tap wired to PingDetailView via `.navigationDestination(item:)`

### Removed
- `PingPlaceholderView.swift` — Replaced by CreatePingView and PingDetailView

### Files created or modified
- `PingIt/Features/Ping/ViewModels/CreatePingViewModel.swift` (new)
- `PingIt/Features/Ping/Views/CreatePingView.swift` (new)
- `PingIt/Features/Ping/ViewModels/PingDetailViewModel.swift` (new)
- `PingIt/Features/Ping/Views/PingDetailView.swift` (new)
- `PingIt/Core/Models/Ping.swift` (modified)
- `PingIt/Core/Services/ChatService.swift` (modified)
- `PingIt/Core/Services/PingService.swift` (modified)
- `PingIt/App/PingItApp.swift` (modified)
- `PingIt/Features/Map/Views/MapView.swift` (modified)

---

## [2026-03-29] — Map & Location Features

### Added
- **GeoJSONBoundaryValidator** — Parses ClujNapoca.geojson, implements ray casting point-in-polygon algorithm with bounding-box fast rejection
- **MapViewModel** — Manages Firestore real-time ping listener lifecycle, exposes location state
- **MapView** — Interactive MapKit map centered on Cluj-Napoca with ping annotations, user location blue dot, map controls (compass, scale, user location button)
- **PingAnnotationView** — Custom map annotation showing ping marker with expiration countdown
- **PingService** added to environment injection in PingItApp

### Changed
- **LocationService** — Upgraded `isWithinClujBoundary` from 15km radius check to proper GeoJSON polygon containment
- **MainTabView** — Map tab now shows real MapView instead of placeholder

### Removed
- `MapPlaceholderView.swift` — Replaced by MapView

### Files created or modified
- `PingIt/Core/Utilities/GeoJSONBoundaryValidator.swift` (new)
- `PingIt/Features/Map/ViewModels/MapViewModel.swift` (new)
- `PingIt/Features/Map/Views/MapView.swift` (new)
- `PingIt/Features/Map/Views/PingAnnotationView.swift` (new)
- `PingIt/Core/Services/LocationService.swift` (modified)
- `PingIt/App/PingItApp.swift` (modified)
- `PingIt/App/MainTabView.swift` (modified)

---

## [2026-03-29] — Foundation Setup

### Added
- **Folder structure:** `App/`, `Core/Models/`, `Core/Services/`, `Core/Utilities/`, `Features/{Authentication,Map,Ping,Chat,Profile,Settings}/Views/`, `Resources/`
- **Firebase SDK** integrated via SPM (FirebaseAuth, FirebaseFirestore, FirebaseStorage)
- **Core models:** `User`, `Ping`, `Chat`, `ChatMessage`, `ChatParticipant` — all Codable/Identifiable/Sendable with `@DocumentID` and `@ServerTimestamp`
- **Core services (stubs):** `AuthService` (auth state listener, sign up/in/out), `PingService` (CRUD, real-time listener), `ChatService` (messages, participants, listener), `UserService` (profile CRUD), `LocationService` (CLLocationManager, boundary check)
- **Core utilities:** `Constants` (Cluj coords, rate limits, collection names), `PingItError` (typed errors), `Date+Extensions` (countdown, relative formatting)
- **App entry point:** `PingItApp` with `FirebaseApp.configure()`, services injected via `@Environment`
- **Root navigation:** `RootView` (auth gate), `MainTabView` (Map, Profile, Settings tabs)
- **Feature views:** `LoginView` (functional sign up/in form), placeholder views for Map, Ping, Chat, Profile, Settings
- **GeoJSON:** Cluj-Napoca administrative boundary from OpenStreetMap (657 coordinate pairs)
- **Info.plist:** `NSLocationWhenInUseUsageDescription` configured

### Files created or modified
- `PingIt/App/PingItApp.swift`, `RootView.swift`, `MainTabView.swift`
- `PingIt/Core/Models/User.swift`, `Ping.swift`, `Chat.swift`, `ChatMessage.swift`, `ChatParticipant.swift`
- `PingIt/Core/Services/AuthService.swift`, `PingService.swift`, `ChatService.swift`, `UserService.swift`, `LocationService.swift`
- `PingIt/Core/Utilities/Constants.swift`, `PingItError.swift`, `Date+Extensions.swift`
- `PingIt/Features/*/Views/*.swift` (6 view files)
- `PingIt/Resources/ClujNapoca.geojson`

---
