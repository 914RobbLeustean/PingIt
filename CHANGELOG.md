# Changelog

All notable changes to PingIt are documented here. Updated after every implementation session.

Format: `[YYYY-MM-DD] — Summary of changes`

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
