# Project Status

## Current Phase
**Phase 0 — Foundation** — Core project structure, models, services, and navigation in place.

## Completed
- Project specification and documentation setup
- Foundation setup: folder structure, Firebase SDK (Auth, Firestore, Storage) via SPM
- Core models: User, Ping, Chat, ChatMessage, ChatParticipant
- Core services (stubs): AuthService, PingService, ChatService, UserService, LocationService
- Core utilities: Constants, PingItError, Date+Extensions
- App entry point with Firebase initialization and auth-gated root navigation
- Placeholder views for all feature areas (Auth, Map, Ping, Chat, Profile, Settings)
- Cluj-Napoca administrative boundary GeoJSON (from OpenStreetMap)
- GoogleService-Info.plist configured

## In Progress
- Phase 0 MVP feature implementation

## Up Next
- Authentication features (Registration, Login, Profile Management)
- Map & Location features (Real-Time Map, Boundary Detection, Location Permissions)

---

## Milestone Tracker

### Phase 0: MVP (14 features)
- [ ] User Registration
- [ ] User Login
- [ ] Basic Profile Management
- [ ] Real-Time Map Display
- [ ] Cluj-Napoca Boundary Detection
- [ ] Location Permission Management
- [ ] Create Text Ping
- [ ] Set Ping Expiration
- [ ] View Ping Details
- [ ] Delete Own Ping
- [ ] Live Ping Visualization
- [ ] Join Ping Chat
- [ ] Send Text Message
- [ ] Real-Time Message Updates

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
