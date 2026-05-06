# PingIt — Architecture

High-level system architecture, data flows, and component relationships.
Infrastructure diagram lives in `project_spec.md` Section 2.2.

---

## iOS App Architecture

**Pattern:** MVVM (Model–View–ViewModel)

```
┌──────────────────────────────────────────────────┐
│                     Views (SwiftUI)               │
│  Declarative UI only. No business logic.          │
│  Observes ViewModels via @Observable.             │
└──────────────────┬───────────────────────────────┘
                   │ reads/binds
┌──────────────────▼───────────────────────────────┐
│                   ViewModels                      │
│  Own UI state. Call Services for data.            │
│  Transform data for display. @MainActor.          │
└──────────────────┬───────────────────────────────┘
                   │ async calls
┌──────────────────▼───────────────────────────────┐
│                   Services                        │
│  Firebase SDK abstraction. Single responsibility. │
│  AuthService, PingService, ChatService, etc.      │
└──────────────────┬───────────────────────────────┘
                   │ network
┌──────────────────▼───────────────────────────────┐
│              Firebase / External APIs             │
│  Firestore, Auth, Storage, FCM, Analytics,        │
│  Crashlytics, Vision API                          │
└──────────────────────────────────────────────────┘
```

**Key rule:** Views never call Services directly. ViewModels never call Firebase SDK directly.

> **Note (2026-03-29):** During foundation setup, `LoginView` and placeholder views access `AuthService` directly via `@Environment` for the auth-gated skeleton. Once ViewModels are implemented for each feature, views will be refactored to observe ViewModels instead.
> **Update (2026-04-13):** Auth screens now follow the full MVVM pattern — `AuthenticationCoordinatorView` owns navigation, each screen has its own ViewModel. The temporary direct-service access note above no longer applies to Authentication.

---

## Folder Structure

```
PingIt/
├── App/                     Entry point, app lifecycle
├── Core/
│   ├── Models/              Firestore data mappings (User, Ping, Chat, etc.)
│   ├── Protocols/           Service protocol abstractions (AuthServicing, PingServicing, etc.)
│   ├── Services/            Firebase SDK wrappers (one per domain), each conforming to a protocol
│   └── Utilities/           Extensions, constants, helpers
├── Features/                One folder per feature, each containing:
│   ├── Authentication/      ViewModels/ + Views/
│   ├── Map/
│   ├── Ping/
│   ├── Chat/
│   ├── Profile/
│   └── Settings/
└── Resources/               Assets, GeoJSON, config files
```

**Naming:** Feature folders are self-contained. Each has `Views/` subfolders (and `ViewModels/` when needed). Shared UI components go under the feature that owns them.

### Actual File Listing (as of 2026-05-06)

```
PingIt/
├── App/
│   ├── PingItApp.swift              @main, FirebaseApp.configure(), environment injection, notification routing, analytics + crashlytics user tracking
│   ├── RootView.swift               Auth gate with suspension check: LoginView or SuspendedAccountView or MainTabView
│   ├── MainTabView.swift            Tab bar (Map, Profile, Settings) with tab selection for notification navigation
│   └── NavigationRouter.swift       @Observable router for push notification → ping navigation
├── Core/
│   ├── Models/
│   │   ├── User.swift               Firestore: users collection
│   │   ├── Ping.swift               Firestore: pings collection (+ PingStatus enum)
│   │   ├── Chat.swift               Firestore: chats collection
│   │   ├── ChatMessage.swift        Firestore: chatMessages collection
│   │   ├── ChatParticipant.swift    Firestore: chatParticipants collection
│   │   ├── Block.swift              Firestore: blocks collection
│   │   ├── Boost.swift             Firestore: boosts collection
│   │   └── Report.swift             Firestore: reports collection (+ ReportTargetType, ReportReason, ReportStatus enums)
│   ├── Protocols/
│   │   ├── ListenerRemovable.swift                      ListenerHandle wrapping ListenerRegistration
│   │   ├── AuthUserRepresentable.swift                  Minimal user identity (uid, isEmailVerified)
│   │   ├── FirebaseUser+AuthUserRepresentable.swift     Firebase conformance
│   │   ├── AuthServicing.swift                          Auth service contract (+ isEmailVerified, sendEmailVerification, reloadUser)
│   │   ├── PingServicing.swift                          Ping service contract (+ callable-backed delete/boost)
│   │   ├── ChatServicing.swift                          Chat service contract (+ callable-backed join/leave)
│   │   ├── UserServicing.swift                          User profile + username reservation contract
│   │   ├── LocationServicing.swift                      Location service contract
│   │   ├── BlockServicing.swift                         Block/unblock, real-time bidirectional listeners
│   │   ├── ContentModeratingServicing.swift             Text moderation (check → .allowed/.blocked)
│   │   ├── RateLimitServicing.swift                     Ping + message rate limiting
│   │   ├── ReportServicing.swift                        Submit report via callable
│   │   ├── NotificationServicing.swift                  FCM token + location update contract
│   │   ├── AnalyticsServicing.swift                     Event logging + user ID tracking
│   │   └── CrashReportingServicing.swift                Crash/error reporting + user ID
│   ├── Services/
│   │   ├── AuthService.swift            Firebase Auth wrapper, auth state listener, email verification
│   │   ├── PingService.swift            Ping creation/read/listen, callable delete and boost
│   │   ├── ChatService.swift            Messages, callable join/leave, snapshot listener
│   │   ├── UserService.swift            User profile CRUD + usernames reservation documents
│   │   ├── LocationService.swift        CLLocationManager, GeoJSON boundary check
│   │   ├── BlockService.swift           @Observable @MainActor; two Firestore snapshot listeners for real-time bidirectional blocking
│   │   ├── ContentModerationService.swift  Bundle wordlist, localizedStandardContains matching
│   │   ├── RateLimitService.swift       UserDefaults-backed limits; #if DEBUG bypass
│   │   ├── ReportService.swift          Calls submitReport callable and maps duplicate report errors
│   │   ├── NotificationService.swift   FCM token registration, APNs permission, foreground banners, location update
│   │   ├── AnalyticsService.swift       Wraps FirebaseAnalytics event logging and user ID
│   │   └── CrashReportingService.swift  Wraps FirebaseCrashlytics crash/error reporting and user ID
│   └── Utilities/
│       ├── Constants.swift              Cluj coords, limits, Firestore collection names (+ blocks, reports, boosts, usernames)
│       ├── PingItError.swift            Typed error enum (+ emailNotVerified, contentModerated, blockFailed, reportFailed, rateLimited, etc.)
│       ├── Date+Extensions.swift        Countdown (ServerTime-corrected), relative formatting
│       ├── ServerTime.swift             Firebase RTDB .info/serverTimeOffset for clock sync
│       └── GeoJSONBoundaryValidator.swift  Ray casting point-in-polygon
├── Features/
│   ├── Authentication/
│   │   ├── Models/
│   │   │   ├── AuthRoute.swift             Navigation route enum
│   │   │   └── PasswordValidator.swift     Pure password strength/rule validation
│   │   ├── ViewModels/
│   │   │   ├── LoginViewModel.swift        Sign-in form state, email validation
│   │   │   ├── RegisterViewModel.swift     Registration: email/username/password/ToS, uniqueness check
│   │   │   └── ForgotPasswordViewModel.swift  Password reset request
│   │   └── Views/
│   │       ├── AuthenticationCoordinatorView.swift  NavigationStack with AuthRoute routing
│   │       ├── WelcomeView.swift           Landing screen with Sign In / Create Account
│   │       ├── LoginView.swift             Email + password sign-in
│   │       ├── RegisterView.swift          Full registration form with strength indicator
│   │       ├── ForgotPasswordView.swift    Password reset request
│   │       ├── SuspendedAccountView.swift   Full-screen suspension gate (shows expiry, contact, sign-out)
│   │       ├── TermsOfServiceView.swift    Placeholder (Phase 2: WebView)
│   │       └── Components/
│   │           ├── AuthTextField.swift         Styled field with icon + validation indicator
│   │           ├── AuthSecureField.swift        Password field with show/hide toggle
│   │           └── PasswordStrengthView.swift   Segmented strength bar + rule checklist
│   ├── Map/
│   │   ├── Models/
│   │   │   └── PingCluster.swift    Cluster model: grouped pings, center, containsHotPing
│   │   ├── ViewModels/
│   │   │   └── MapViewModel.swift   Ping listener lifecycle, map state; filters expired + blocked; hotPingIds; manual clustering; overlapping pin offset
│   │   └── Views/
│   │       ├── MapView.swift              MapKit map with annotations, email verification banner
│   │       ├── PingAnnotationView.swift   Custom ping marker with hot ping visual treatment
│   │       ├── PingClusterAnnotationView.swift  Cluster annotation with count and hot-ping indicator
│   │       └── EmailVerificationBannerView.swift  Dismissable banner for unverified users
│   ├── Ping/
│   │   ├── ViewModels/
│   │   │   ├── CreatePingViewModel.swift   Validation, moderation, rate limit, location, Firestore write
│   │   │   └── PingDetailViewModel.swift   Creator loading, countdown, delete, ping document listener, boost
│   │   └── Views/
│   │       ├── CreatePingView.swift        Form: text, location picker, expiration
│   │       ├── PingDetailView.swift        Detail with creator, countdown, actions, report/block buttons
│   │       ├── LocationPickerView.swift    GPS / search / map pin selection
│   │       ├── MapPinPickerView.swift      Drag-pin-on-map picker
│   │       ├── PingDetailCreatorSection.swift  Creator info + profile picture
│   │       └── PingDetailActionSection.swift   Join chat + delete buttons
│   ├── Chat/
│   │   ├── ViewModels/
│   │   │   └── ChatViewModel.swift         Message listener, send (with moderation + rate limit), join; filters blocked; ping doc listener; user profile cache
│   │   └── Views/
│   │       ├── ChatView.swift              Real-time message list + input, report sheet, ping unavailable dismiss
│   │       └── MessageBubbleView.swift     Sender avatar + username, grouped bubbles, report/block context menu
│   ├── Report/
│   │   ├── ViewModels/
│   │   │   └── ReportViewModel.swift       Reason selection, submit, block offer after success
│   │   └── Views/
│   │       └── ReportView.swift            Form: reason picker, details text field, block offer
│   ├── Profile/
│   │   ├── ViewModels/
│   │   │   └── ProfileViewModel.swift      Profile CRUD, Storage upload
│   │   └── Views/
│   │       ├── ProfileView.swift           Username edit, photo management
│   │       ├── ProfileImageSection.swift   AsyncImage + PhotosPicker + camera
│   │       └── CameraPickerView.swift      UIKit camera wrapper
│   └── Settings/
│       ├── ViewModels/
│       │   └── BlockedUsersViewModel.swift  Loads blocked users with profiles, unblock action
│       └── Views/
│           ├── SettingsView.swift           Sign out, notifications + privacy toggles, Privacy & Safety
│           └── BlockedUsersView.swift       List of blocked users with unblock confirmation

└── Resources/
    ├── ClujNapoca.geojson           Cluj-Napoca admin boundary (OSM)
    └── moderation_wordlist.txt      Client-side profanity filter wordlist (one word per line)

PingItTests/
├── Mocks/
│   ├── MockAuthUser.swift                    Stub AuthUserRepresentable (+ isEmailVerified)
│   ├── MockAuthService.swift                 @Observable @MainActor mock (+ isEmailVerified, sendEmailVerification, reloadUser)
│   ├── MockPingService.swift                 Stores activePingsCallback, simulates updates, boost tracking
│   ├── MockChatService.swift                 Stores messagesCallback, simulates updates
│   ├── MockUserService.swift                 Returns preset User, tracks calls
│   ├── MockLocationService.swift             Settable location/auth/boundary result
│   ├── MockBlockService.swift                Settable blockedUserIds, tracks blockUser/unblockUser calls
│   ├── MockContentModerationService.swift    Settable result (.allowed/.blocked), tracks check calls
│   ├── MockRateLimitService.swift            Settable ping/message results, tracks record calls
│   ├── MockReportService.swift               Tracks submitReport calls, injectable error
│   ├── MockNotificationService.swift         Tracks permission/token/location calls
│   ├── MockAnalyticsService.swift            Records logged events for test assertions
│   └── MockCrashReportingService.swift       Records reported errors for test assertions
├── ViewModelTests/
│   ├── CreatePingViewModelTests.swift        (+ email verification, moderation, rate limit tests)
│   ├── ChatViewModelTests.swift              (+ email verification, blocking, moderation tests)
│   ├── MapViewModelTests.swift               (+ expired ping filter, blocked creator filter tests)
│   ├── BlockedUsersViewModelTests.swift
│   ├── ReportViewModelTests.swift
│   ├── PingDetailViewModelTests.swift
│   ├── LoginViewModelTests.swift
│   ├── RegisterViewModelTests.swift
│   ├── ForgotPasswordViewModelTests.swift
│   ├── PasswordValidatorTests.swift
│   └── ProfileViewModelTests.swift
└── PingItTests.swift                         Boundary, dates, constants, models
```

---

## Core Data Flows

### 1. Ping Creation
```
User taps "Create Ping"
  → LocationPickerView lets user choose location:
      Option A: "Use Current Location" (GPS)
      Option B: Search address (MapKit MKLocalSearchCompleter autocomplete)
      Option C: Drag pin on map (interactive Map with draggable annotation)
      Future: Saved Places (Phase 2+)
  → CreatePingViewModel validates input (text, location, expiration)
  → CreatePingViewModel checks Cluj boundary (local GeoJSON)
  → PingService.createPingWithChat() writes ping + chat atomically (Firestore batch)
  → Firestore listener on MapViewModel fires → new pin appears on map
```

### 1.1 Ping Deletion
```
Creator taps "Delete"
  → PingDetailViewModel calls PingService.deletePing(id:)
  → PingService calls deletePing({ pingId })
  → Cloud Function verifies auth + creator ownership
  → Shared cleanup marks ping status="removed"
  → Shared cleanup deletes associated chat, messages, participants, and boosts in chunked batches
  → Firestore listeners remove the ping from map/detail/chat screens
```

### 2. Real-Time Chat
```
User opens ping detail → taps "Join Chat"
  → ChatService calls joinChat({ chatId })
  → Cloud Function validates user, active ping, suspension state, and block relationship
  → Deterministic chatParticipants/{chatId}_{uid} is created/reactivated
  → chats.participantCount and pings.participantCount increment only on active transition
  → ChatViewModel attaches Firestore snapshot listener
  → New messages appear instantly (push-based, not polling)
  → User sends message → ChatService writes to Firestore
  → User leaves chat → ChatService calls leaveChat({ chatId }) idempotently, then listener detached
```

### 2.1 Boost And Report
```
User taps "Boost"
  → PingService calls boostPing({ pingId })
  → Cloud Function validates auth, suspension, active ping, creator mismatch, and blocks
  → Deterministic boosts/{pingId}_{uid} is created once
  → pings.boostCount increments in the same transaction
  → iOS uses returned boostCount instead of optimistic +1

User submits report
  → ReportService calls submitReport({ targetType, targetId, targetOwnerId, reason, ... })
  → Cloud Function validates auth, suspension, allowed target/reason, and non-self-report
  → Deterministic reports/{reporterId}_{targetId} is created
  → Duplicate submit returns already-exists, shown as "You have already reported this content."
```

### 3. Ping Expiration
```
Cloud Function runs every 5 minutes (cron)
  → Queries pings where expiresAt <= now AND status == active
  → Updates status to "expired"
  → Shared cleanup deletes associated chat, chatMessages, chatParticipants, and boosts
  → Firestore listener on MapViewModel fires → pin removed from map
```

### 4. Content Moderation (Phase 1+)
```
User creates ping with image
  → Ping visible on map immediately (optimistic)
  → Image uploaded to Firebase Storage (background)
  → Storage trigger fires Cloud Function
  → Cloud Function calls Vision API SafeSearch
  → If flagged (VERY_LIKELY): status set to "removed", image deleted
  → Firestore listener fires → pin disappears from map
```

### 5. Push Notifications (Phase 1+)
```
New ping created in Firestore
  → Firestore trigger fires Cloud Function
  → Function queries nearby users (geohash proximity)
  → Sends FCM notification to matching users
  → User taps notification → app opens to ping detail
```

---

## Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Local persistence | Firestore offline (no Core Data) | Built-in caching, no sync conflicts |
| Geospatial queries | GeoHash via GeoFirestore | Firestore has no native radius queries |
| Chat delivery | Firestore onSnapshot (real-time) | Sub-second latency, battery-efficient |
| Content moderation | Optimistic publish + async review | Zero perceived latency for users |
| City boundary | Client-side GeoJSON polygon check | Lightweight, no server round-trip |
| State management | @Observable classes | Modern Swift, no ObservableObject/Combine |

---

## Component Relationships

```
MapView ──observes──▶ MapViewModel ──calls──▶ PingService ──reads──▶ Firestore (pings)
                                              LocationService ──reads──▶ CLLocationManager
                                              BlockService (filters blocked creators + expired pings)
                     └─ renders unclusteredPings + clusters (manual client-side clustering)
                     └─ uses displayCoordinates (offset for overlapping pins)

PingDetailView ──observes──▶ PingDetailViewModel ──calls──▶ PingService (callable delete/boost, boost check)
                                                            ChatService
                                                            AnalyticsService (logs boost_used)
             └─ report/block buttons ──▶ ReportView / BlockService

SettingsView ──calls──▶ UserService (fetch + update preferences)
             └─ loads isPrivateProfile, notifyNearbyPings, notifyHotPings from Firestore
             └─ dual-write: UserDefaults cache + Firestore (eliminates toggle flash on restart)

ChatView ──observes──▶ ChatViewModel ──calls──▶ ChatService ──listens──▶ Firestore (chatMessages)
                                               └─ joins/leaves via Cloud Functions
                                               ContentModerationService (outbound text check)
                                               RateLimitService (outbound message throttle)
                                               BlockService (filters incoming messages)
                                               AnalyticsService (logs chat_joined)
         └─ message context menu ──▶ ReportView / BlockService

CreatePingView ──observes──▶ CreatePingViewModel ──calls──▶ PingService
                                                            ContentModerationService
                                                            RateLimitService
                                                            LocationService
                                                            AnalyticsService (logs ping_created)

ProfileView ──observes──▶ ProfileViewModel ──calls──▶ UserService ──reads/writes──▶ Firestore (users + usernames)
                                                      AuthService ──calls──▶ Firebase Auth

ReportView ──observes──▶ ReportViewModel ──calls──▶ ReportService ──calls──▶ submitReport Cloud Function

SettingsView ──▶ BlockedUsersView ──observes──▶ BlockedUsersViewModel ──calls──▶ BlockService + UserService

MapView ── uses ──▶ NotificationService.updateLastKnownLocation (on first location fix)

SettingsView ── deleteAccount ──▶ AuthService.reauthenticate + AuthService.deleteAccount ──▶ Cloud Function

PingItApp ── .task ──▶ NotificationService.requestPermission + registerFCMToken
          └─ sets UNUserNotificationCenter.delegate + Messaging.delegate
          └─ .onReceive(PingItOpenPing) ──▶ NavigationRouter.pendingPingId
          └─ .onChange(of: auth.uid) ──▶ AnalyticsService.setUserId + CrashReportingService.setUserId

RootView ── checks ──▶ UserService.fetchUser (suspension gate)
         └─ if suspended ──▶ SuspendedAccountView
         └─ if not suspended ──▶ MainTabView

NavigationRouter ──observed by──▶ MainTabView (tab switch) + MapView (ping navigation)

AuthenticationCoordinatorView ──routes──▶ LoginView / RegisterView / ForgotPasswordView
LoginView ──observes──▶ LoginViewModel ──calls──▶ AuthService ──calls──▶ Firebase Auth
RegisterView ──observes──▶ RegisterViewModel ──calls──▶ AuthService + UserService (username check)
ForgotPasswordView ──observes──▶ ForgotPasswordViewModel ──calls──▶ AuthService.sendPasswordReset
```

---

## Services Overview

| Service | Responsibility | Status |
|---------|---------------|--------|
| **AuthService** | Sign up, sign in, sign out, password reset, session state, email verification | Implemented |
| **PingService** | Client-side ping creation/read/listen, callable-backed delete and boost, boost-state lookup | Implemented |
| **ChatService** | Messages, snapshot listeners, callable-backed join/leave participant tracking | Implemented |
| **UserService** | Profile read/write, username reservation get/create/delete during signup and rename | Implemented |
| **LocationService** | CLLocationManager wrapper, boundary check | Implemented |
| **BlockService** | Real-time bidirectional blocking via two Firestore snapshot listeners, optimistic local updates | Implemented |
| **ContentModerationService** | Bundle wordlist check, returns `.allowed`/`.blocked(reason:)` | Implemented |
| **RateLimitService** | UserDefaults-backed ping + message rate limiting, `#if DEBUG` bypass | Implemented |
| **ReportService** | Calls `submitReport`, maps duplicate report callable error to user-visible `reportAlreadySubmitted` | Implemented |
| **ServerTime** | Firebase RTDB `.info/serverTimeOffset` for clock-skew correction; `ServerTime.now` | Implemented (utility enum) |
| **NotificationService** | FCM token registration, APNs permission, foreground notification display, lastKnownLocation update | Implemented |
| **AnalyticsService** | Wraps FirebaseAnalytics for event logging (`ping_created`, `chat_joined`, `boost_used`, `onboarding_completed`) and user ID tracking | Implemented |
| **CrashReportingService** | Wraps FirebaseCrashlytics for crash/non-fatal error reporting and user ID tracking | Implemented |

### Service Injection Pattern

Services are created as `@State` in `PingItApp` and injected via `.environment()`. Views access them with `@Environment(ServiceType.self)`. ViewModels will receive services via init parameters for testability.

---

---

## Cloud Functions Architecture

**Runtime:** TypeScript, Firebase Cloud Functions v2, Node 20

```
functions/src/
├── index.ts                      App initialization, exports all functions
├── expirePings.ts                Scheduled: every 5 minutes, batch-expires pings via shared cleanup
├── pingCleanup.ts                Shared chunked cleanup for ping chat/messages/participants/boosts
├── pingCallables.ts              Callable: deletePing, boostPing, joinChat, leaveChat
├── reportCallables.ts            Callable: submitReport with deterministic report IDs
├── deleteAccount.ts              Callable: GDPR cascading delete (pings, chats, messages, boosts, blocks, reports, storage, auth)
├── sendNearbyNotification.ts     Firestore trigger: pings onCreate → 2km Haversine filter → FCM push
├── sendHotPingNotification.ts    Firestore triggers: boosts onCreate + chatParticipants onWrite → hot score check → FCM push
├── moderateImage.ts              Storage trigger: onObjectFinalized → Vision API SafeSearch → auto-remove or flag for review
└── removeContent.ts              Callable: admin emergency content removal (ping, message, user suspension) with audit trail
```

### Cloud Function Data Flows

```
Ping Expiration (cron every 5min):
  expirePings → query pings where status=="active" AND expiresAt<=now
    → batch update status="expired"
    → shared cleanup deletes: chat, chatMessages, chatParticipants, boosts

Ping Deletion (callable):
  deletePing({ pingId })
    → require auth
    → verify caller owns the ping
    → ignore client-supplied related IDs
    → shared cleanup sets status="removed"
    → delete related chat, chatMessages, chatParticipants, boosts in chunked batches

Boost (callable):
  boostPing({ pingId })
    → require auth, non-suspended user, active ping, non-creator, no bidirectional block
    → create deterministic boosts/{pingId}_{uid}
    → increment pings/{pingId}.boostCount in one transaction
    → return { boostCount, didBoost }

Chat Participants (callable):
  joinChat({ chatId }) / leaveChat({ chatId })
    → deterministic chatParticipants/{chatId}_{uid}
    → validate active ping and block state on join
    → increment/decrement chats.participantCount and pings.participantCount only on state transitions
    → leave is idempotent

Reports (callable):
  submitReport({ targetType, targetId, targetOwnerId, reason, ... })
    → require auth and non-suspended user
    → create deterministic reports/{reporterId}_{targetId}
    → duplicate reports return already-exists for visible UI feedback

Account Deletion (callable):
  deleteAccount(auth.uid)
    → delete user's pings + their chats/messages/participants
    → delete user's messages in others' chats
    → delete user's chat participations, boosts, blocks, reports, username reservation
    → delete profile image from Storage
    → delete user document from Firestore
    → delete Firebase Auth account

Nearby Notification (pings onCreate):
  sendNearbyNotification
    → read ping location
    → query users with fcmToken != null
    → filter: !creator, notifyNearbyPings != false, not blocked (blocks collection query)
    → filter: lastKnownLocation within 2km (Haversine)
    → send FCM multicast

Hot Ping Notification (boosts/chatParticipants onCreate):
  sendHotPingNotificationOnBoost / sendHotPingNotificationOnJoin
    → resolve pingId
    → check: boostCount >= 3 AND hotScore >= 8.0 (aligned with client formula)
    → check: ping is in top 10 by score
    → check: hotNotificationSent flag (prevent duplicates)
    → query blocks collection for bidirectional filtering
    → send FCM multicast

Image Moderation (Storage onObjectFinalized):
  moderateImage
    → filter: only profile_pictures/ and ping_images/ paths
    → generate signed URL → Vision API SafeSearch
    → VERY_LIKELY: auto-delete file, update Firestore (nullify profileImageUrl or set ping status="removed"), create moderationActions audit doc
    → LIKELY: create reports doc for manual review
    → below LIKELY: no action

Emergency Content Removal (callable):
  removeContent(auth.uid)
    → verify caller email in ADMIN_EMAILS param
    → targetType "ping": set status="removed", cascade delete chat + messages + participants
    → targetType "message": delete chatMessages doc
    → targetType "user": set suspensionStatus="suspended", 24hr expiry
    → create moderationActions audit doc
```

---

_This document will be updated as features are implemented and architecture evolves._
