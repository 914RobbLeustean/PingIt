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
│  Firestore, Auth, Storage, FCM, Vision API        │
└──────────────────────────────────────────────────┘
```

**Key rule:** Views never call Services directly. ViewModels never call Firebase SDK directly.

> **Note (2026-03-29):** During foundation setup, `LoginView` and placeholder views access `AuthService` directly via `@Environment` for the auth-gated skeleton. Once ViewModels are implemented for each feature, views will be refactored to observe ViewModels instead.

---

## Folder Structure

```
PingIt/
├── App/                     Entry point, app lifecycle
├── Core/
│   ├── Models/              Firestore data mappings (User, Ping, Chat, etc.)
│   ├── Services/            Firebase SDK wrappers (one per domain)
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

### Actual File Listing (as of 2026-03-29)

```
PingIt/
├── App/
│   ├── PingItApp.swift              @main, FirebaseApp.configure(), environment injection
│   ├── RootView.swift               Auth gate: LoginView or MainTabView
│   └── MainTabView.swift            Tab bar (Map, Profile, Settings)
├── Core/
│   ├── Models/
│   │   ├── User.swift               Firestore: users collection
│   │   ├── Ping.swift               Firestore: pings collection (+ PingStatus enum)
│   │   ├── Chat.swift               Firestore: chats collection
│   │   ├── ChatMessage.swift        Firestore: chatMessages collection
│   │   └── ChatParticipant.swift    Firestore: chatParticipants collection
│   ├── Services/
│   │   ├── AuthService.swift        Firebase Auth wrapper, auth state listener
│   │   ├── PingService.swift        Ping CRUD, real-time snapshot listener
│   │   ├── ChatService.swift        Messages, participants, snapshot listener
│   │   ├── UserService.swift        User profile CRUD
│   │   └── LocationService.swift    CLLocationManager, GeoJSON boundary check
│   └── Utilities/
│       ├── Constants.swift          Cluj coords, limits, Firestore collection names
│       ├── PingItError.swift        Typed error enum
│       ├── Date+Extensions.swift    Countdown, relative formatting
│       └── GeoJSONBoundaryValidator.swift  Ray casting point-in-polygon
├── Features/
│   ├── Authentication/Views/
│   │   └── LoginView.swift          Functional login/signup form
│   ├── Map/
│   │   ├── ViewModels/
│   │   │   └── MapViewModel.swift   Ping listener lifecycle, map state
│   │   └── Views/
│   │       ├── MapView.swift        MapKit map with annotations
│   │       └── PingAnnotationView.swift  Custom ping marker
│   ├── Ping/
│   │   ├── ViewModels/
│   │   │   ├── CreatePingViewModel.swift   Validation, location, Firestore write
│   │   │   └── PingDetailViewModel.swift   Creator loading, countdown, delete
│   │   └── Views/
│   │       ├── CreatePingView.swift        Form: text, location picker, expiration
│   │       ├── PingDetailView.swift        Detail with creator, countdown, actions
│   │       ├── LocationPickerView.swift    GPS / search / map pin selection
│   │       └── MapPinPickerView.swift      Drag-pin-on-map picker
│   ├── Chat/Views/
│   │   └── ChatPlaceholderView.swift
│   ├── Profile/Views/
│   │   └── ProfilePlaceholderView.swift
│   └── Settings/Views/
│       └── SettingsPlaceholderView.swift
└── Resources/
    └── ClujNapoca.geojson           Cluj-Napoca admin boundary (OSM)
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

### 2. Real-Time Chat
```
User opens ping detail → taps "Join Chat"
  → ChatViewModel attaches Firestore snapshot listener
  → New messages appear instantly (push-based, not polling)
  → User sends message → ChatService writes to Firestore
  → User leaves chat → listener detached (critical for cost/memory)
```

### 3. Ping Expiration
```
Cloud Function runs every 5 minutes (cron)
  → Queries pings where expiresAt <= now AND status == active
  → Updates status to "expired", deletes associated chat
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

PingDetailView ──observes──▶ PingDetailViewModel ──calls──▶ PingService
                                                            ChatService

ChatView ──observes──▶ ChatViewModel ──calls──▶ ChatService ──listens──▶ Firestore (chatMessages)

ProfileView ──observes──▶ ProfileViewModel ──calls──▶ UserService ──reads/writes──▶ Firestore (users)
                                                      AuthService ──calls──▶ Firebase Auth

LoginView ──observes──▶ LoginViewModel ──calls──▶ AuthService ──calls──▶ Firebase Auth
```

---

## Services Overview

| Service | Responsibility | Status |
|---------|---------------|--------|
| **AuthService** | Sign up, sign in, sign out, session state | Implemented (stub) |
| **PingService** | Ping CRUD, geospatial queries, real-time listener | Implemented (stub) |
| **ChatService** | Messages, snapshot listeners, participant tracking | Implemented (stub) |
| **UserService** | Profile read/write | Implemented (stub) |
| **LocationService** | CLLocationManager wrapper, boundary check | Implemented (stub) |
| **NotificationService** | FCM token registration, notification handling | Not yet created (Phase 1+) |

### Service Injection Pattern

Services are created as `@State` in `PingItApp` and injected via `.environment()`. Views access them with `@Environment(ServiceType.self)`. ViewModels will receive services via init parameters for testability.

---

_This document will be updated as features are implemented and architecture evolves._
