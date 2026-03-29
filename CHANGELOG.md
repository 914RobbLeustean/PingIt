# Changelog

All notable changes to PingIt are documented here. Updated after every implementation session.

Format: `[YYYY-MM-DD] — Summary of changes`

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
