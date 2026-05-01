# Project Status

## Current Phase
**Phase 1 — Safety & Discovery** — Sprint 3 complete (13/16 features). Cloud Functions deployed, push notifications, GDPR account deletion. E2E tested — Firestore rules deployed, stale state on account switch fixed, report content snapshots, pin overlap separation improved.

## Completed
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
- Atomic Firestore batch writes for ping+chat creation and deletion
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
  - **Boost Ping:** Boost model (`boosts` collection), denormalized `boostCount` on Ping, double-boost prevention (query before UI enable). PingDetailView shows boost button for non-creators with "Boosted" filled state. Boost count visible to all users (including ping creators).
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
  - **User Reporting:** `ReportService` writes to Firestore `reports` collection with duplicate prevention (queries before writing, throws `reportAlreadySubmitted`). `ReportView` accepts services via init (not @Environment — fixes blank sheet in navigation stacks). `ReportViewModel` with reason picker, details field, block offer after success. `onDidBlock` callback auto-dismisses parent views.
  - **Spam Detection (Client-Side):** `RateLimitService` with UserDefaults-backed hourly (5/hr) + daily (10/day) ping limits, per-10-seconds (6) message limit. `#if DEBUG` bypass for testing.
  - **Expired Ping Filtering:** MapViewModel filters pings where `expiresAt <= ServerTime.now` client-side.
  - **Server Time Sync:** `ServerTime` utility using Firebase Realtime Database `.info/serverTimeOffset` for consistent cross-device clocks. All countdown, expiration, and ping creation logic uses `ServerTime.now`.
  - **Ping Lifecycle Awareness:** PingDetailView and ChatView observe the ping document via Firestore listener. Deleted or expired pings show "Ping Unavailable" alert and dismiss viewers back to map. Creator's own deletes skip the alert.
  - **Chat Sender Identity:** MessageBubbleView shows sender avatar (AsyncImage + initial-letter fallback) and username. Consecutive messages from same sender grouped (avatar/name on first only). ChatViewModel caches User profiles per sender ID.

## In Progress
_Nothing actively in progress._

## Up Next (choose one or more)
- **Phase 1 Sprint 4:** Moderation Pipeline (automated image/video filtering, content review queue, emergency content removal)
- **Phase 2: Polish & Launch** (10 features): Custom ping duration, onboarding flow, empty/error states, performance optimization, analytics, crash reporting, app icon/splash, privacy policy, beta testing

## Known Technical Debt
- Push notifications cannot be tested — requires personal Apple Developer Program membership ($99/yr) to generate APNs key for Firebase Console. Corporate developer account is restricted. All other Sprint 3 features can be tested without it.
- Geohash field is empty string (geospatial radius queries need GeoFirestore for production scale)
- No offline mode handling (Firestore caches automatically but no explicit UI for offline state)
- Simulator networking blocked by Netskope (corporate SSL interception) — must test on physical iPhone
- ProfileViewModel directly calls Firebase Storage — should be extracted to `ImageStorageServicing` protocol for full testability
- Notification tap navigation (`PingItOpenPing`) not yet wired to deep-link to ping detail
- `lastKnownLocation` only updated on first map load; could be stale if user moves significantly

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
- [ ] Automated Image/Video Filtering
- [x] Text Content Moderation
- [x] User Report System
- [ ] Content Review Queue
- [ ] Emergency Content Removal
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

### Phase 2: Polish & Launch (10 features)
- [ ] Custom Ping Duration
- [ ] Onboarding Flow
- [ ] Empty States
- [ ] Error States
- [ ] Performance Optimization
- [ ] Firebase Analytics
- [ ] Crash Reporting
- [ ] App Icon & Splash Screen
- [ ] Privacy Policy & Terms
- [ ] Beta Testing

---

_Updated after each major feature or bugfix._
