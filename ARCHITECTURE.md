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

**Naming:** Feature folders are self-contained. Each has `ViewModels/` and `Views/` subfolders. Shared UI components go under the feature that owns them.

---

## Core Data Flows

### 1. Ping Creation
```
User taps "Create Ping"
  → CreatePingViewModel validates input (text, location, expiration)
  → CreatePingViewModel checks Cluj boundary (local GeoJSON)
  → PingService creates Firestore document (status: active)
  → PingService creates associated Chat document
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

| Service | Responsibility |
|---------|---------------|
| **AuthService** | Sign up, sign in, sign out, session state |
| **PingService** | Ping CRUD, geospatial queries, boost |
| **ChatService** | Messages, snapshot listeners, participant tracking |
| **UserService** | Profile read/write, block/unblock |
| **LocationService** | CLLocationManager wrapper, permission handling |
| **NotificationService** | FCM token registration, notification handling |

---

_This document will be updated as features are implemented and architecture evolves._
