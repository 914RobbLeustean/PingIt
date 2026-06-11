<p align="center">
  <img src="logofinal.png" alt="PingIt Logo" width="120" />
</p>

<h1 align="center">PingIt</h1>

<p align="center">
  <strong>A full-stack iOS social platform for facilitating real-time local meetups and spontaneous social gatherings.</strong>
</p>

<p align="center">
  Built with SwiftUI · Firebase · MapKit · Cloud Functions
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" />
  <img src="https://img.shields.io/badge/Platform-iOS_17+-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Architecture-MVVM-green" />
  <img src="https://img.shields.io/badge/Backend-Firebase-yellow?logo=firebase" />
  <img src="https://img.shields.io/badge/Tests-262-brightgreen" />
</p>

---

## Demo
https://github.com/user-attachments/assets/51387cbc-c8b5-41bd-909d-b50b83c537df

---

## Overview

PingIt lets users create location-based "pings" — short-lived posts tied to a place and time — that nearby people can discover on a live map, join group chats around, and boost to trending status. Think of it as ephemeral, hyperlocal social networking: every ping expires, every conversation is temporary, and everything happens within walking distance.

The app is geofenced to Cluj-Napoca, Romania using a GeoJSON boundary polygon validated with a ray-casting algorithm.

### Key Features

- **Live Map** — Interactive MapKit map with custom annotations, pin clustering, de-overlapping algorithm for dense areas, and a toggleable **activity heatmap** showing 7-day hotspots (recency × boost weighted grid cells)
- **Real-Time Group Chat** — Firestore snapshot listeners powering live messaging with reactions, location sharing, and date separators
- **RSVP System** — "I'm Going" commitments with live attendance counts on the map, feed, and detail screens; server-authoritative toggle with deterministic document IDs
- **Post-Event Story Recaps** — After a ping expires, attendees (RSVP'd users) can submit photos for 2 hours; a ghost 📸 marker lingers on the map for 24 hours with a photo carousel, then everything is garbage-collected server-side
- **Social Graph** — Username search (prefix-indexed, public profiles only), follow/unfollow with live follower counts, read-only user profiles, and four follow-driven push notifications (new follower, new ping, RSVP, recap photo); going private makes follows dormant, blocking severs them both ways
- **Ping Editing** — Creators edit title/details/category from the detail screen; changes propagate live to every open screen with an "edited" marker
- **Deep Link Sharing** — Share pings via `https://` links with a hosted web fallback page and custom URL scheme handoff into the app
- **Proximity Notifications** — Server-side push notifications triggered when a new ping is created within 2km of a user (haversine distance)
- **Trending System** — Algorithm-driven "hot" detection (`score = boostCount × 2 + participantCount + timeContribution`) with server-triggered notifications for top-10 trending pings
- **Content Moderation** — Client-side text filtering + server-side Google Cloud Vision SafeSearch for image moderation with auto-removal and audit trails
- **Trust & Safety** — User blocking (bidirectional, real-time enforcement everywhere including search results and recap photos), reporting (pings, messages, users), rate limiting, account suspension (temporary + permanent), email verification gates
- **GDPR Compliance** — Full user data export, cascading account deletion across 9 Firestore collections, privacy profiles with anonymous identity preserved at every entry point
- **Performance** — `NSCache`-backed image caching renders previously-seen avatars and photos with zero flicker; animated launch splash hands off frame-perfectly from the static launch screen
- **Observability** — Firebase Crashlytics, Analytics (structured events), and Performance monitoring with custom traces

---

## Architecture

```
PingIt/
├── App/                          # App entry point, root routing, navigation
│   ├── PingItApp.swift           # Service initialization, auth state, deep link handling
│   ├── SplashView.swift          # Animated launch splash (radar rings, wordmark reveal)
│   ├── RootView.swift            # Auth/suspension gate
│   ├── NavigationRouter.swift    # Observable navigation state
│   └── MainTabView.swift         # Tab bar (Map, Feed, Social, Profile, Settings)
│
├── Core/
│   ├── Models/                   # 10 Codable/Sendable data models
│   ├── Services/                 # 17 service implementations
│   ├── Protocols/                # 20 protocol abstractions
│   ├── Utilities/                # Constants, errors, DeepLink, ImageCache, CachedAsyncImage
│   └── Theme/                    # Design tokens (colors, typography)
│
├── Features/                     # 11 feature modules
│   ├── Authentication/           # Login, register, password reset, coordinator
│   ├── Chat/                     # Real-time messaging, reactions, overlays
│   ├── Feed/                     # Chronological + trending feed with sorting
│   ├── Map/                      # Live map, clustering, annotations, heatmap overlay
│   ├── Onboarding/               # First-launch walkthrough
│   ├── Ping/                     # Create/edit ping, detail view, location picker
│   ├── Profile/                  # User profile, avatar upload, stats, live follower count
│   ├── Recap/                    # Post-event story recaps (photo carousel, ghost markers)
│   ├── Report/                   # Content reporting flow (pings, messages, users)
│   ├── Settings/                 # Preferences, blocked users, account deletion
│   └── Social/                   # User search, follow system, user profiles
│
└── functions/src/                # 23 Firebase Cloud Functions (TypeScript)
    ├── pingCallables.ts          # joinChat, leaveChat, boostPing, rsvpPing, updatePing, deletePing
    ├── socialCallables.ts        # toggleFollow, searchUsers
    ├── followNotifications.ts    # 4 follow-activity push triggers
    ├── blockTriggers.ts          # severFollowsOnBlock
    ├── recapTriggers.ts          # Recap photo counters
    ├── cleanupRecaps.ts          # Expired recap GC (docs + photos + Storage)
    ├── reportCallables.ts        # Server-side report submission
    ├── moderateImage.ts          # Google Cloud Vision SafeSearch (ping + recap photos)
    ├── sendNearbyNotification.ts # Proximity-based push notifications
    ├── sendHotPingNotification.ts# Trending ping notifications
    ├── expirePings.ts            # Scheduled expiration + recap creation (every 5 min)
    ├── deleteAccount.ts          # Cascading account deletion
    ├── exportUserData.ts         # GDPR data export
    ├── removeContent.ts          # Admin content removal
    └── pingCleanup.ts            # Shared cleanup utilities + ChunkedWriteBatch
```

### Design Principles

- **MVVM** — Every view backed by an `@Observable` ViewModel with `@MainActor` isolation
- **Protocol-Oriented** — 17 services abstracted behind 20 protocols; zero Firebase imports in any ViewModel
- **Dependency Injection** — All ViewModels accept `any ProtocolName` dependencies via `configure(...)`, enabling full mock substitution
- **Server-Authoritative** — Security-sensitive operations (join/leave chat, boost, RSVP, edit, follow, report, delete) run as Cloud Functions with Firestore transactions, not client-side writes
- **Strict Concurrency** — `async/await` throughout, `nonisolated` delegate methods, `isolated deinit` for listener cleanup, cooperative cancellation

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | SwiftUI, MapKit, Custom Design System (Syne/DMSans typography, color tokens) |
| **Architecture** | MVVM, Protocol-Oriented Design, Dependency Injection, Coordinator Pattern |
| **Concurrency** | Swift Concurrency (async/await, @MainActor, nonisolated, Task, isolated deinit) |
| **Backend** | Firebase (Firestore, Auth, Cloud Functions v2, FCM, Storage, Crashlytics, Analytics, Performance, Realtime Database) |
| **Cloud Functions** | TypeScript, Google Cloud Vision API |
| **Maps** | MapKit, CoreLocation, GeoJSON boundary validation (ray-casting algorithm) |
| **Testing** | Swift Testing framework (262 tests), 17 mock implementations |
| **Security** | Firestore Security Rules (field-level validation), server-side auth enforcement, content moderation |

---

## Security

PingIt implements defense-in-depth security:

- **Firestore Security Rules** — Field-level write validation, suspension checks, cross-document consistency verification (ping ↔ chat atomicity), and strict schema enforcement
- **Server-Side Enforcement** — All mutating operations that affect other users (boost, join, leave, report, delete) go through Cloud Functions with auth verification and blocking checks
- **Content Moderation** — Dual-layer: client-side wordlist filtering before submission + server-side Google Cloud Vision SafeSearch on uploaded images with auto-removal for `VERY_LIKELY` violations and flagging for `LIKELY`
- **Rate Limiting** — Client-side throttling (5 pings/hour, 10/day, 6 messages/10 seconds) with server-side idempotency guards
- **Email Enumeration Prevention** — Password reset suppresses errors to prevent email discovery attacks
- **Auth Rollback** — Sign-up uses batched writes; if Firestore write fails, the Firebase Auth user is automatically deleted
- **Server Time Sync** — Firebase Realtime Database clock offset correction ensures consistent expiration across devices

---

## Testing

**262 unit tests** using the Swift Testing framework (`@Test`, `@Suite`, `#expect`) with **17 mock implementations** covering every service boundary.

```
PingItTests/
├── ViewModelTests/
│   ├── ChatViewModelTests.swift          # 16 tests
│   ├── CreatePingViewModelTests.swift    # 14 tests
│   ├── EditPingViewModelTests.swift      # 13 tests
│   ├── RegisterViewModelTests.swift      # 12 tests
│   ├── PingDetailViewModelTests.swift    # 11 tests
│   ├── PasswordValidatorTests.swift      # 11 tests
│   ├── SocialViewModelTests.swift        # 10 tests
│   ├── MapViewModelTests.swift           # 9 tests
│   ├── OnboardingViewModelTests.swift    # 7 tests
│   ├── UserProfileViewModelTests.swift   # 7 tests
│   ├── ProfileViewModelTests.swift       # 6 tests
│   ├── LoginViewModelTests.swift         # 6 tests
│   ├── FeedViewModelTests.swift          # 4 tests
│   ├── ForgotPasswordViewModelTests.swift# 4 tests
│   ├── ReportViewModelTests.swift        # 4 tests
│   ├── BlockedUsersViewModelTests.swift  # 2 tests
│   └── PrivacyProfileTests.swift         # 4 tests
├── DeepLinkTests.swift                   # 11 tests (URL parsing, share links)
├── PingRecapTests.swift                  # 11 tests (eligibility windows, visibility)
├── HeatCellTests.swift                   # 10 tests (weighting, bucketing, normalization)
├── ContentModerationTests.swift          # 4 tests (incl. Romanian language)
├── ImageCacheTests.swift                 # 4 tests
├── SuspensionTests.swift                 # 7 tests
├── PingItTests.swift                     # Model, boundary, hot score, date tests
└── Mocks/                               # 17 protocol-conforming mock services
```

All mocks are `@Observable` and `@MainActor`-isolated, support injectable errors via `errorToThrow`, capture call flags and last-called parameters, and simulate real-time updates (e.g., `MockChatService.simulateNewMessage`).

---

## Cloud Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `joinChat` | Callable | Server-authoritative chat join with participant counting, block checking, and Firestore transaction |
| `leaveChat` | Callable | Atomic participant decrement with ping count sync |
| `boostPing` | Callable | Idempotent boost with suspension/block/expiry validation |
| `rsvpPing` | Callable | Toggleable "I'm Going" with deterministic doc IDs and live counter sync |
| `updatePing` | Callable | Creator-only edit (text/description/category) with server-side validation + `editedAt` stamp |
| `deletePing` | Callable | Creator-only ping deletion with full cascade cleanup |
| `toggleFollow` | Callable | Transactional follow/unfollow with counter sync; rejects private targets |
| `searchUsers` | Callable | Prefix search over public usernames (composite-indexed), filters self + blocks |
| `notifyOnNewFollower` | Firestore trigger | "X started following you" push |
| `notifyFollowersOnPingCreated` | Firestore trigger | Push to followers when a followed user drops a ping |
| `notifyFollowersOnRSVP` | Firestore trigger | Push to followers when a followed user RSVPs |
| `notifyFollowersOnRecapPhoto` | Firestore trigger | Push to followers on recap photo submission |
| `severFollowsOnBlock` | Firestore trigger | Blocking deletes both follow edges and fixes all four counters |
| `onRecapPhotoCreated` | Firestore trigger | Maintains recap `photoCount` (skips moderated photos) |
| `submitReport` | Callable | Duplicate-safe report creation (pings, messages, users) with suspension check |
| `moderateImage` | Storage trigger | Google Cloud Vision SafeSearch on ping + recap photos |
| `sendNearbyNotification` | Firestore trigger | Push to users within 2km (haversine), respecting blocks and preferences |
| `sendHotPingNotification` | Firestore trigger | Trending notifications on boost/join, top-10 ranking, deduplication |
| `expirePings` | Scheduled (5 min) | Expiration + recap creation from RSVPs + expired-recap GC |
| `deleteAccount` | Callable | Full cascade deletion across 9 collections + Storage + Auth |
| `exportUserData` | Callable | GDPR data export (profile, pings, messages, boosts, blocks, reports) |
| `removeContent` | Callable | Admin-only emergency content removal with audit trail |

---

## Requirements

- iOS 17.0+
- Xcode 16.0+
- Swift 6.0
- Firebase project with Firestore, Auth, Storage, Cloud Messaging, Crashlytics, Analytics, Performance
- Node.js 18+ (for Cloud Functions)

---

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/your-username/PingIt.git
   cd PingIt
   ```

2. Set up Firebase
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add an iOS app and download `GoogleService-Info.plist` into the `PingIt/` directory
   - Enable Authentication (Email/Password), Firestore, Storage, Cloud Messaging, Crashlytics, Analytics, and Performance

3. Deploy Firestore Security Rules and indexes
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```

4. Deploy Cloud Functions and the deep-link web fallback
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions,hosting
   ```
   > Note: brand-new callable functions occasionally deploy without the public
   > invoker permission (clients then see `UNAUTHENTICATED`). Fix with
   > `gcloud functions add-invoker-policy-binding <name> --region=europe-west3 --member=allUsers`.

5. Open `PingIt.xcodeproj` in Xcode, select your team, and run

---

## License

This project was developed as a thesis project for the B.S. Computer Science program at Babeș-Bolyai University, Cluj-Napoca.
