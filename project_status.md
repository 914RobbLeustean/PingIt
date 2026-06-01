# Project Status

## Current Phase
**Phase 2 — Polish & Launch** — Code complete (10/11 features). All code features shipped across 3 sessions: Custom Ping Duration, Firebase Analytics, Crashlytics, Privacy Policy & Terms, Onboarding Flow, App Icon, Performance Monitoring. Only **Beta Testing** remains, blocked on Apple Developer Program enrollment ($99/yr). See `docs/BETA_TESTING.md` for the full setup checklist.

## Completed
- 2026-06-01 — UI overhaul (Authentication screens): redesigned Sign In, Create Account, Forgot Password, Terms of Service, and Privacy Policy to match the prototype's visual language. Adds shared auth components (`AuthInputField`, `AuthPasswordField`, `AuthCheckbox`, `AuthCTAButtonStyle`, `AuthBackButton`, `AuthScreenHeader`, `AuthFieldHint`). Terms / Privacy now render natively via `LegalDocumentView` + `LegalDocumentLoader` (HTML → typed blocks) instead of `WKWebView`; the old `AuthTextField` / `AuthSecureField` / `WebContentView` were removed.
- 2026-06-01 — UI overhaul (Welcome screen): full rewrite of `WelcomeView` to match the HTML prototype, plus design-system foundation (dark-mode color tokens, Syne + DM Sans font helpers, primary/secondary pill button styles, animated RadarBackground, PingItLogoMark, PingItWordmark). Dark color scheme is now enforced app-wide.
- Project specification and documentation setup
- Foundation setup: folder structure, Firebase SDK (Auth, Firestore, Storage) via SPM
- Core models: User, Ping, Chat, ChatMessage, ChatParticipant
- Core services (stubs): AuthService, PingService, ChatService, UserService, LocationService
- Core utilities: Constants, PingItError, Date+Extensions
- App entry point with Firebase initialization and auth-gated root navigation
- Cluj-Napoca administrative boundary GeoJSON (from OpenStreetMap)
- GoogleService-Info.plist configured
- Map & Location: Real-Time Map Display, Boundary Detection, Location Permission Management
- GeoJSONBoundaryValidator with ray casting point-in-polygon algorithm
- MapViewModel with Firestore real-time listener lifecycle
- Ping Core: Create Text Ping, Set Expiration, View Details, Delete Own Ping, Live Visualization
- CreatePingViewModel/View with validation, ChatService/PingService enhancements
- PingDetailViewModel/View with creator loading, countdown timer, cascade delete
- Location Picker (Uber-style): current GPS, address search with autocomplete, drag-pin-on-map
- Atomic Firestore batch writes for ping+chat creation; backend callable cascade for ping deletion
- Search results filtered to Cluj-Napoca (title + subtitle)
- 19 unit tests (at Map & Location phase): boundary validator, date extensions, constants, ping model
- Authentication: User Registration with username, Login with session management, Profile Management
- LoginViewModel with username validation, ProfileViewModel with Firebase Storage upload
- ProfileView with photo picker, username editing, AsyncImage display
- SettingsView with sign-out confirmation
- ViewModel refactor: configure() pattern, zero Binding(get:set:), @Bindable throughout
- Chat Core: Join Chat, Send Message, Real-Time Message Updates
- ChatViewModel with Firestore listener, ChatView with auto-scroll
- Launch screen with branded logo
- 27 unit tests (foundation + validation)
- Protocol abstractions: `AuthServicing`, `PingServicing`, `ChatServicing`, `UserServicing`, `LocationServicing`, `ListenerRemovable`, `AuthUserRepresentable`
- 7 `@Observable @MainActor` mock implementations for all services
- ~40 ViewModel unit tests across 6 suites (CreatePing, Chat, PingDetail, Login, Map, Profile)

## Completed (Polish — Testability)
- **Testability refactor (2026-04-13):** Protocol abstractions for all 5 services, supporting protocols (`ListenerRemovable`, `AuthUserRepresentable`), 7 mock implementations, ~40 new ViewModel unit tests across 6 test suites

## Completed (Polish — Production Auth Screens)
- **Auth screens production-ready (2026-04-13):** Welcome + Login + Register + ForgotPassword screens with full navigation (AuthRoute + NavigationStack). Password strength indicator (PasswordValidator), client-side email & password validation, unique username check (debounced Firestore query), confirm password, ToS checkbox, show/hide password, Firebase error mapping to user-friendly messages. Shared components: AuthTextField, AuthSecureField, PasswordStrengthView. New VMs: RegisterViewModel, ForgotPasswordViewModel. ~25 new ViewModel + validator unit tests.

## Completed (Phase 1 — Sprint 3: Cloud Functions + Notifications)
- **Phase 1 Sprint 3 (2026-04-20):** First backend work — Cloud Functions + push notifications.
  - **Cloud Functions Setup:** TypeScript Cloud Functions with Firebase Admin SDK, health check endpoint.
  - **Ping Expiration Cron:** `expirePings` runs every 5 minutes — queries active pings where `expiresAt <= now`, sets status to "expired", cascading deletes chat + messages + participants.
  - **GDPR Account Deletion:** `deleteAccount` callable function — cascading delete of all user data (pings, chats, messages, participants, boosts, blocks, reports, profile image, Auth account). iOS: re-auth flow with password confirmation, Cloud Function call via `FirebaseFunctions` SDK. Settings UI with two-step confirmation.
  - **Push Notifications:** `NotificationService` with APNs/FCM token management, `UNUserNotificationCenterDelegate` for foreground banners and tap handling. `lastKnownLocation` persisted to Firestore on map load.
  - **Nearby Ping Notifications:** `sendNearbyNotification` Firestore trigger — 2km Haversine distance filter using `lastKnownLocation`, blocks collection query for bidirectional filtering, respects `notifyNearbyPings` preference.
  - **Hot Ping Notifications:** `sendHotPingNotificationOnBoost` + `sendHotPingNotificationOnJoin` — aligned with client formula (`boostCount >= 3 && hotScore >= 8.0`), top-10 check, one-time notification per ping via `hotNotificationSent` flag.
  - **SPM Dependencies:** Added `FirebaseFunctions` and `FirebaseMessaging`.

## Completed (Phase 1 — Sprint 2: Engagement + Map Polish)
- **Phase 1 Sprint 2 (2026-04-19 to 2026-04-20):** Engagement features, settings toggles, and device-testing fixes.
  - **Boost Ping:** Boost model (`boosts` collection), denormalized `boostCount` on Ping, double-boost prevention, server-authoritative `boostPing` callable for boost creation and counter updates. PingDetailView shows boost button for non-creators with "Boosted" filled state. Boost count visible to all users (including ping creators).
  - **Hot Pings Algorithm:** Client-side `hotScore` computed property: `boostCount × 2.0 + participantCount + min(hoursRemaining × 0.1, 2.0)`. Gate: `boostCount >= 3 && hotScore >= 8.0`. Top 10 qualifying pings shown with flame icon and red glow on map. Formula refined through 3 iterations during device testing to prevent pings from appearing hot too easily.
  - **Ping Clustering:** Manual client-side clustering in MapViewModel (SwiftUI `Map` doesn't support native `MKClusterAnnotation`). `PingCluster` model with center calculation and hot-ping awareness. Threshold: `region.span.latitudeDelta × 0.03`, disabled at close zoom (`< 0.005`). `PingClusterAnnotationView` for clustered pins. Tap-to-zoom on clusters.
  - **Overlapping Pin Offset:** Pings at identical coordinates arranged in circular pattern (~15m offset) to remain individually tappable.
  - **Notification Preferences:** `notifyNearbyPings` and `notifyHotPings` toggles in SettingsView, persisted to Firestore user document. UserDefaults caching eliminates toggle flash on app restart.
  - **Privacy Settings:** `isPrivateProfile` toggle in SettingsView, persisted to Firestore user document. UserDefaults caching eliminates toggle flash on app restart.
  - **Boost Race Condition Fix:** `isCheckingBoostStatus` flag (defaults `true`) prevents boost button from being briefly enabled before async boost check completes.

## Completed (Phase 1 — Sprint 1: Client-Side Safety)
- **Phase 1 Sprint 1 (2026-04-14 to 2026-04-15):** Full client-side safety layer without Cloud Functions.
  - **Email Verification:** `AuthServicing` extended with `isEmailVerified`, `sendEmailVerification()`, `reloadUser()`. CreatePingViewModel and ChatViewModel gate actions behind email verification. MapView shows dismissable `EmailVerificationBannerView` for unverified users with resend action. Banner polls `reloadUser()` every 5s and auto-hides when verified.
  - **Text Content Moderation:** `ContentModerationService` with bundle-loaded wordlist (`moderation_wordlist.txt`), `localizedStandardContains()` matching. Blocks ping creation and message sending.
  - **User Blocking:** `BlockService` with real-time bidirectional Firestore listeners (two snapshot listeners: `blockerId == me` and `blockedUserId == me`). Enforcement is instant — when UserA blocks UserB, UserB's listener fires and UserA's pings/messages disappear within seconds. MapViewModel and ChatViewModel re-filter reactively via `onChange(of: blockedUserIds)`. Blocking from chat auto-dismisses ChatView + PingDetailView back to map. Duplicate blocks prevented (idempotent). `BlockedUsersView` + `BlockedUsersViewModel` in Settings.
  - **User Reporting:** `ReportService` calls the `submitReport` callable. Reports use deterministic IDs for duplicate prevention; duplicate submits return `reportAlreadySubmitted` for visible UI feedback. `ReportView` accepts services via init (not @Environment — fixes blank sheet in navigation stacks). `ReportViewModel` with reason picker, details field, block offer after success. `onDidBlock` callback auto-dismisses parent views.
  - **Spam Detection (Client-Side):** `RateLimitService` with UserDefaults-backed hourly (5/hr) + daily (10/day) ping limits, per-10-seconds (6) message limit. `#if DEBUG` bypass for testing.
  - **Expired Ping Filtering:** MapViewModel filters pings where `expiresAt <= ServerTime.now` client-side.
  - **Server Time Sync:** `ServerTime` utility using Firebase Realtime Database `.info/serverTimeOffset` for consistent cross-device clocks. All countdown, expiration, and ping creation logic uses `ServerTime.now`.
  - **Ping Lifecycle Awareness:** PingDetailView and ChatView observe the ping document via Firestore listener. Deleted or expired pings show "Ping Unavailable" alert and dismiss viewers back to map. Creator's own deletes skip the alert.
  - **Chat Sender Identity:** MessageBubbleView shows sender avatar (AsyncImage + initial-letter fallback) and username. Consecutive messages from same sender grouped (avatar/name on first only). ChatViewModel caches User profiles per sender ID.

## Completed (Phase 2 — Session 1: Custom Ping Duration + Analytics + Crashlytics)
- **Phase 2 Session 1 (2026-05-06):** Custom Ping Duration, Firebase Analytics, Crashlytics — code complete and verified.

## Completed (Phase 2 — Session 2: Privacy Policy + Onboarding)
- **Phase 2 Session 2 (2026-05-06):** Privacy Policy & Terms of Service, Onboarding Flow — code complete and verified (196 tests, 0 failures).
  - **Privacy Policy & Terms:** Bundled HTML content (`terms.html`, `privacy.html`) displayed in WKWebView via `WebContentView`. `TermsOfServiceView` placeholder replaced. `PrivacyPolicyView` added. `AuthRoute.privacyPolicy` case. RegisterView now links both Terms and Privacy Policy. SettingsView has "Legal" section.
  - **Onboarding Flow:** 3-page `TabView(.page)` tutorial (OnboardingView + OnboardingPageView). `OnboardingViewModel` manages page state, completion, skip. Writes `hasCompletedOnboarding = true` to Firestore user doc. Logs `onboarding_completed` analytics event. RootView gates onboarding between suspension check and MainTabView.
  - **Firestore rules:** `hasCompletedOnboarding` added to `safeUserCreate` and `safeUserUpdate` allowed fields.

## Completed (Phase 2 — Audit Remediation)
- **Audit remediation (2026-05-02):** Addressed critical, high, and medium audit findings across 9 implementation units.
  - **Firestore rules hardened:** Pings update restricted to boostCount increment-by-1 from non-creators. `moderationActions` collection explicitly denied for all client access.
  - **Suspension enforcement:** User model extended with `suspensionStatus`/`suspensionExpiresAt`. RootView gates access — suspended users see full-screen `SuspendedAccountView` with expiry info and sign-out.
  - **Privacy profile enforcement:** `isPrivateProfile` now enforced — PingDetailView shows "Anonymous" + default icon for private-profile creators (unless viewer is the creator).
  - **Moderation wordlist expanded:** From 10 to ~150 words covering English profanity, slurs, hate speech, and Romanian profanity.
  - **Notification tap navigation:** `NavigationRouter` wired through PingItApp → MainTabView → MapView. Tapping a push notification now switches to Map tab and navigates to the ping.
  - **Empty states:** MapView shows "No pings nearby" overlay. Location denied banner with Settings link added.
  - **Error states:** BlockedUsersView now displays error messages. Location denied state with "Open Settings" button.
  - **Chat pagination:** Messages loaded in pages of 50. Real-time listener for new messages only. "Load earlier messages" button at top of chat.
  - **Accessibility:** Labels, hints, and element grouping added across 10+ view files (PingDetail, Chat, Map, Profile, Settings, Auth).

## Completed (Post-Audit Server-Authoritative Hardening)
- **Server-authoritative backend rewrite (2026-05-06):** Moved destructive writes, engagement counters, participant counters, and report duplicate checks out of direct client ownership.
  - **Ping deletion:** `deletePing` callable verifies creator ownership and uses shared `pingCleanup` to mark status `removed` and delete related chat, messages, participants, and boosts in chunked batches.
  - **Shared cleanup:** `pingCleanup` is reused by `deletePing`, `expirePings`, `removeContent`, and `deleteAccount`.
  - **Boosts:** `boostPing` callable validates auth, suspension, active ping state, non-creator, and bidirectional blocks; uses deterministic `boosts/{pingId}_{uid}` and increments `pings.boostCount` transactionally.
  - **Chat participants:** `joinChat` and `leaveChat` callables use deterministic `chatParticipants/{chatId}_{uid}` and update both chat and ping participant counts only on active/left transitions.
  - **Reports:** `submitReport` callable creates deterministic `reports/{reporterId}_{targetId}` and maps duplicates to visible `reportAlreadySubmitted` UI errors.
  - **Firestore rules:** Direct client updates/deletes for `pings`, `chats`, `boosts`, `chatParticipants`, and `reports` are denied. User updates are restricted to safe profile/preference fields.
  - **Username reservations:** Added `usernames/{normalizedUsername}` documents for public username availability checks without listing `users`.
  - **Hot notifications:** Participant trigger now listens to writes so rejoin transitions can re-check hot status while preserving `hotNotificationSent`.

## Completed (Phase 2 — Session 3: App Icon + Performance Monitoring + Beta Testing Docs)
- **Phase 2 Session 3 (2026-05-07):** App icon configured, Firebase Performance Monitoring integrated, Beta Testing guide created, project spec aligned with implementation.
  - **App Icon:** Resized `logo.png` to 1024x1024 `AppIcon.png`. Configured `AppIcon.appiconset/Contents.json` with filename references for light, dark, and tinted slots.
  - **Firebase Performance Monitoring:** `PerformanceServicing` protocol, `PerformanceService` wrapping `FirebasePerformance`, `MockPerformanceService` for tests. Automatic app startup, network, and screen rendering traces. SPM dependency added.
  - **Beta Testing Guide:** `docs/BETA_TESTING.md` — Apple Developer enrollment prerequisites, APNs setup, Xcode signing, TestFlight workflow, tester onboarding, feedback process, timeline.
  - **Spec Alignment:** `project_spec.md` v1.2 — data model updated to reflect actual collections, tech stack corrected, feature count updated to 41.

## Completed (Post-Phase 2 — Bonus Features)
- **4 Bonus Features (2026-05-21):** Message reactions, location sharing, media attachments, and discovery feed.
  - **Message Reactions:** 8-emoji reaction system on chat messages with tappable capsules, context menu, Firestore `safeReactionUpdate()` rule.
  - **Location Sharing in Chat:** Share current location as inline mini-map card, tap to open Apple Maps. Firestore message type validation.
  - **Media Attachments on Pings:** Optional image on ping creation via PhotosPicker. Upload to Firebase Storage before batch write. Moderated by existing `moderateImage` Cloud Function.
  - **Discovery Feed:** New "Feed" tab with scrollable ping cards sorted by newest/hottest/nearest/expiring soon. Independent Firestore listener, block/expiry filtering, creator cache.

## Completed (Post-Phase 2 — Bonus Feature Bug Fixes)
- **9 Bug Fixes (2026-05-26):** Comprehensive audit and remediation of all 4 bonus features.
  - **Ping image Storage cleanup:** `pingCleanup.ts` now deletes `ping_images/{pingId}/` from Storage on delete/expire/account-delete.
  - **Real-time reactions:** Chat listener merges updated messages instead of dropping reaction changes.
  - **Feed listener lifecycle:** Removed aggressive `onDisappear` that killed Firestore listener during NavigationStack push.
  - **Media attachment UI:** Image preview non-interactive, red X overlay for removal, Menu with Library + Camera options.
  - **Concurrency:** `@MainActor` on `CreatePingViewModel`, `ChatViewModel`, `FeedViewModel`; `isolated deinit` for listener cleanup.
  - **Location share reverse geocoding:** Shared locations now display actual addresses.
  - **Constant naming:** `maxProfileImageSizeBytes` → `maxImageSizeBytes`.

## Up Next
- **Beta Testing implementation:** Blocked on Apple Developer Program enrollment ($99/yr, 2-5 day approval). See `docs/BETA_TESTING.md` for full checklist.

## Known Technical Debt
- Push notifications cannot be tested — requires personal Apple Developer Program membership ($99/yr) to generate APNs key for Firebase Console. Corporate developer account is restricted.
- Geohash field is empty string (geospatial radius queries need GeoFirestore for production scale)
- No offline mode handling (Firestore caches automatically but no explicit UI for offline state) — noted for post-release PR
- Simulator networking blocked by Netskope (corporate SSL interception) — must test on physical iPhone
- `moderateImage` uses `gs://` URI instead of signed URLs due to missing `iam.serviceAccounts.signBlob` permission on default compute service account
- Node.js 20 runtime deprecated (2026-04-30) — upgrade to Node 22 before decommission (2026-10-30) — noted for post-release PR
- `firebase-functions` package is outdated — upgrade has breaking changes, needs dedicated PR — noted for post-release
- No server-side rate limiting (client-side only — can be bypassed) — noted for post-release PR
- No admin web dashboard (Firebase Console + runbook only)

---

## Milestone Tracker

### Phase 0: MVP (14 features)
- [x] User Registration
- [x] User Login
- [x] Basic Profile Management
- [x] Real-Time Map Display
- [x] Cluj-Napoca Boundary Detection
- [x] Location Permission Management
- [x] Create Text Ping
- [x] Set Ping Expiration
- [x] View Ping Details
- [x] Delete Own Ping
- [x] Live Ping Visualization
- [x] Join Ping Chat
- [x] Send Text Message
- [x] Real-Time Message Updates

### Phase 1: Safety & Discovery (16 features)
- [x] Automated Image/Video Filtering
- [x] Text Content Moderation
- [x] User Report System
- [x] Content Review Queue
- [x] Emergency Content Removal
- [x] Boost Ping
- [x] Hot Pings Algorithm
- [x] Nearby Ping Notifications
- [x] Hot Ping Notifications
- [x] User Blocking
- [x] Account Deletion (GDPR)
- [x] Email Verification
- [x] Spam Detection
- [x] Notification Preferences
- [x] Privacy Settings
- [x] Blocked Users Management

### Phase 2: Polish & Launch (11 features)
- [x] Custom Ping Duration
- [x] Onboarding Flow
- [x] Empty States
- [x] Error States
- [x] Performance Optimization
- [x] Firebase Analytics
- [x] Crash Reporting
- [x] Performance Monitoring
- [x] App Icon & Splash Screen
- [x] Privacy Policy & Terms
- [ ] Beta Testing

### Post-Phase 2: Bonus Features (4 features)
- [x] Message Reactions
- [x] Location Sharing in Chat
- [x] Media Attachments on Pings
- [x] Discovery Feed

---

_Updated after each major feature or bugfix._
