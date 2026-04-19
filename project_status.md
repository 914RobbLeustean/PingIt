# Project Status

## Current Phase
**Phase 1 — Safety & Discovery** — Sprint 2 complete (11/16 features). Engagement features and settings implemented.

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

## Completed (Phase 1 — Sprint 2: Engagement + Map Polish)
- **Phase 1 Sprint 2 (2026-04-19):** Engagement features and settings toggles.
  - **Boost Ping:** Boost model (`boosts` collection), denormalized `boostCount` on Ping, double-boost prevention (query before UI enable). PingDetailView shows boost button for non-creators with "Boosted" filled state.
  - **Hot Pings Algorithm:** Client-side `hotScore` computed property (2×boosts + participants + 0.5×hoursRemaining). Top 10 pings with score ≥5.0 shown with flame icon and red glow on map.
  - **Ping Clustering:** `PingClusterAnnotationView` for clustered pins with hot-ping awareness. Map annotations use `.annotationTitles(.hidden)` and anchor positioning.
  - **Notification Preferences:** `notifyNearbyPings` and `notifyHotPings` toggles in SettingsView, persisted to Firestore user document.
  - **Privacy Settings:** `isPrivateProfile` toggle in SettingsView, persisted to Firestore user document.

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
- **Phase 1 Sprint 3:** Cloud Functions (ping expiration cron, push notifications, server-side rate limiting)
- **Phase 1 Sprint 4:** Moderation Pipeline (automated image/video filtering, content review queue, emergency content removal)
- **Phase 2: Polish & Launch** (10 features): Custom ping duration, onboarding flow, empty/error states, performance optimization, analytics, crash reporting, app icon/splash, privacy policy, beta testing

## Known Technical Debt
- Cloud Functions not deployed (ping expiration cron, rate limiting, push notifications)
- Geohash field is empty string (geospatial radius queries need GeoFirestore for Phase 1)
- No offline mode handling (Firestore caches automatically but no explicit UI for offline state)
- Simulator networking blocked by Netskope (corporate SSL interception) — must test on physical iPhone
- ProfileViewModel directly calls Firebase Storage — should be extracted to `ImageStorageServicing` protocol for full testability

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
- [ ] Nearby Ping Notifications
- [ ] Hot Ping Notifications
- [x] User Blocking
- [ ] Account Deletion (GDPR)
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
