# Project Status

## Current Phase
**Phase 0 — MVP** — 14/14 features complete. All core features implemented.

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
- 19 unit tests: boundary validator, date extensions, constants, ping model
- Authentication: User Registration with username, Login with session management, Profile Management
- LoginViewModel with username validation, ProfileViewModel with Firebase Storage upload
- ProfileView with photo picker, username editing, AsyncImage display
- SettingsView with sign-out confirmation
- ViewModel refactor: configure() pattern, zero Binding(get:set:), @Bindable throughout
- Chat Core: Join Chat, Send Message, Real-Time Message Updates
- ChatViewModel with Firestore listener, ChatView with auto-scroll
- Launch screen with branded logo
- 35 unit tests total

## In Progress
_Nothing actively in progress._

## Up Next (choose one or more)
- **Polish MVP:** Protocol abstractions for testability, ViewModel unit tests with mocks, UI/UX refinements
- **Phase 1: Safety & Discovery** (16 features): Content moderation, user reporting, blocking, boost pings, hot pings algorithm, push notifications, GDPR account deletion, email verification, spam detection, notification/privacy preferences
- **Phase 2: Polish & Launch** (10 features): Custom ping duration, onboarding flow, empty/error states, performance optimization, analytics, crash reporting, app icon/splash, privacy policy, beta testing

## Known Technical Debt
- No protocol abstractions for services → ViewModels can't be unit tested in isolation
- Cloud Functions not deployed (ping expiration cron, rate limiting, push notifications)
- Geohash field is empty string (geospatial radius queries need GeoFirestore for Phase 1)
- No offline mode handling (Firestore caches automatically but no explicit UI for offline state)
- Launch screen may not display on first install (iOS caching — requires device restart)
- Simulator networking blocked by Netskope (corporate SSL interception) — must test on physical iPhone

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
- [ ] Text Content Moderation
- [ ] User Report System
- [ ] Content Review Queue
- [ ] Emergency Content Removal
- [ ] Boost Ping
- [ ] Hot Pings Algorithm
- [ ] Nearby Ping Notifications
- [ ] Hot Ping Notifications
- [ ] User Blocking
- [ ] Account Deletion (GDPR)
- [ ] Email Verification
- [ ] Spam Detection
- [ ] Notification Preferences
- [ ] Privacy Settings
- [ ] Blocked Users Management

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
