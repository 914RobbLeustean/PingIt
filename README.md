<p align="center">
  <img src="logo.png" alt="PingIt Logo" width="120" />
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
  <img src="https://img.shields.io/badge/Tests-192-brightgreen" />
</p>

---

## Demo

https://github.com/user-attachments/assets/7d8afd71-2ce4-4578-a978-8b5fdb884d44

---

## Overview

PingIt lets users create location-based "pings" — short-lived posts tied to a place and time — that nearby people can discover on a live map, join group chats around, and boost to trending status. Think of it as ephemeral, hyperlocal social networking: every ping expires, every conversation is temporary, and everything happens within walking distance.

The app is geofenced to Cluj-Napoca, Romania using a GeoJSON boundary polygon validated with a ray-casting algorithm.

### Key Features

- **Live Map** — Interactive MapKit map with custom annotations, pin clustering, and de-overlapping algorithm for dense areas
- **Real-Time Group Chat** — Firestore snapshot listeners powering live messaging with reactions, location sharing, and date separators
- **Proximity Notifications** — Server-side push notifications triggered when a new ping is created within 2km of a user (haversine distance)
- **Trending System** — Algorithm-driven "hot" detection (`score = boostCount × 2 + participantCount + timeContribution`) with server-triggered notifications for top-10 trending pings
- **Content Moderation** — Client-side text filtering + server-side Google Cloud Vision SafeSearch for image moderation with auto-removal and audit trails
- **Trust & Safety** — User blocking (bidirectional, real-time enforcement), reporting, rate limiting, account suspension (temporary + permanent), email verification gates
- **GDPR Compliance** — Full user data export, cascading account deletion across 7 Firestore collections, privacy profiles
- **Observability** — Firebase Crashlytics, Analytics (structured events), and Performance monitoring with custom traces

---

## Architecture

```
PingIt/
├── App/                          # App entry point, root routing, navigation
│   ├── PingItApp.swift           # Service initialization, auth state, deep link handling
│   ├── RootView.swift            # Auth/suspension gate
│   ├── NavigationRouter.swift    # Observable navigation state
│   └── MainTabView.swift         # Tab bar (Map, Feed, Profile, Settings)
│
├── Core/
│   ├── Models/                   # 8 Codable/Sendable data models
│   ├── Services/                 # 15 service implementations
│   ├── Protocols/                # 18 protocol abstractions
│   ├── Utilities/                # Constants, error types, extensions
│   └── Theme/                    # Design tokens (colors, typography)
│
├── Features/                     # 9 feature modules
│   ├── Authentication/           # Login, register, password reset, coordinator
│   ├── Chat/                     # Real-time messaging, reactions, overlays
│   ├── Feed/                     # Chronological + trending feed with sorting
│   ├── Map/                      # Live map, clustering, annotations
│   ├── Onboarding/               # First-launch walkthrough
│   ├── Ping/                     # Create ping, detail view, location picker
│   ├── Profile/                  # User profile, avatar upload, stats
│   ├── Report/                   # Content reporting flow
│   └── Settings/                 # Preferences, blocked users, account deletion
│
└── functions/src/                # 12 Firebase Cloud Functions (TypeScript)
    ├── pingCallables.ts          # joinChat, leaveChat, boostPing, deletePing
    ├── reportCallables.ts        # Server-side report submission
    ├── moderateImage.ts          # Google Cloud Vision SafeSearch
    ├── sendNearbyNotification.ts # Proximity-based push notifications
    ├── sendHotPingNotification.ts# Trending ping notifications
    ├── expirePings.ts            # Scheduled ping expiration (every 5 min)
    ├── deleteAccount.ts          # Cascading account deletion
    ├── exportUserData.ts         # GDPR data export
    ├── removeContent.ts          # Admin content removal
    └── pingCleanup.ts            # Shared cleanup utilities + ChunkedWriteBatch
```

### Design Principles

- **MVVM** — Every view backed by an `@Observable` ViewModel with `@MainActor` isolation
- **Protocol-Oriented** — 15 services abstracted behind 18 protocols; zero Firebase imports in any ViewModel
- **Dependency Injection** — All ViewModels accept `any ProtocolName` dependencies via `configure(...)`, enabling full mock substitution
- **Server-Authoritative** — Security-sensitive operations (join/leave chat, boost, report, delete) run as Cloud Functions with Firestore transactions, not client-side writes
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
| **Testing** | Swift Testing framework (192 tests), 15 mock implementations |
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

**192 unit tests** using the Swift Testing framework (`@Test`, `@Suite`, `#expect`) with **15 mock implementations** covering every service boundary.

```
PingItTests/
├── ViewModelTests/
│   ├── ChatViewModelTests.swift          # 16 tests
│   ├── CreatePingViewModelTests.swift    # 14 tests
│   ├── RegisterViewModelTests.swift      # 12 tests
│   ├── PingDetailViewModelTests.swift    # 11 tests
│   ├── MapViewModelTests.swift           # 9 tests
│   ├── OnboardingViewModelTests.swift    # 7 tests
│   ├── ProfileViewModelTests.swift       # 6 tests
│   ├── LoginViewModelTests.swift         # 6 tests
│   ├── FeedViewModelTests.swift          # 4 tests
│   ├── ForgotPasswordViewModelTests.swift# 4 tests
│   ├── ReportViewModelTests.swift        # 4 tests
│   ├── BlockedUsersViewModelTests.swift  # 2 tests
│   ├── PasswordValidatorTests.swift      # 11 tests
│   └── PrivacyProfileTests.swift         # 4 tests
├── ContentModerationTests.swift          # 4 tests (incl. Romanian language)
├── SuspensionTests.swift                 # 7 tests
├── PingItTests.swift                     # Model, boundary, hot score, date tests
└── Mocks/                               # 15 protocol-conforming mock services
```

All mocks are `@Observable` and `@MainActor`-isolated, support injectable errors via `errorToThrow`, capture call flags and last-called parameters, and simulate real-time updates (e.g., `MockChatService.simulateNewMessage`).

---

## Cloud Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `joinChat` | Callable | Server-authoritative chat join with participant counting, block checking, and Firestore transaction |
| `leaveChat` | Callable | Atomic participant decrement with ping count sync |
| `boostPing` | Callable | Idempotent boost with suspension/block/expiry validation |
| `deletePing` | Callable | Creator-only ping deletion with full cascade cleanup |
| `submitReport` | Callable | Duplicate-safe report creation with suspension check |
| `moderateImage` | Storage trigger | Google Cloud Vision SafeSearch on uploaded images |
| `sendNearbyNotification` | Firestore trigger | Push to users within 2km (haversine), respecting blocks and preferences |
| `sendHotPingNotification` | Firestore trigger | Trending notifications on boost/join, top-10 ranking, deduplication |
| `expirePings` | Scheduled (5 min) | Automatic expiration of active pings past their `expiresAt` |
| `deleteAccount` | Callable | Full cascade deletion across 7 collections + Storage + Auth |
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

3. Deploy Firestore Security Rules
   ```bash
   firebase deploy --only firestore:rules
   ```

4. Deploy Cloud Functions
   ```bash
   cd functions
   npm install
   firebase deploy --only functions
   ```

5. Open `PingIt.xcodeproj` in Xcode, select your team, and run

---

## License

This project was developed as a thesis project for the B.S. Computer Science program at Babeș-Bolyai University, Cluj-Napoca.
