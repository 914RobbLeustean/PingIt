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
│  Crashlytics, Performance, Vision API             │
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
│   ├── Map/                 (incl. heatmap overlay: HeatCell model + MapCircle rendering)
│   ├── Ping/                (create, detail, edit)
│   ├── Chat/
│   ├── Feed/
│   ├── Onboarding/
│   ├── Profile/
│   ├── Recap/               Post-event story recaps (ghost markers, photo carousel)
│   ├── Report/
│   ├── Settings/
│   └── Social/              User search, follow system, read-only user profiles
└── Resources/               Assets, GeoJSON, config files
```

**Naming:** Feature folders are self-contained. Each has `Views/` subfolders (and `ViewModels/` when needed). Shared UI components go under the feature that owns them.

### Design system

All UI code in the app MUST use the tokens and components defined under `PingIt/Core/Theme/` and the per-feature component folders.

**Color tokens (`Core/Theme/Color+Tokens.swift`):** A dark-only palette exposed as `Color` extensions. Hard-coded hex colors and system colors are not allowed.

| Token | Use |
| --- | --- |
| `Color.pingBackground` (`#090912`) | App background |
| `Color.pingSurface` (`#12121C`) | Cards, secondary button fill |
| `Color.pingSurfaceElevated` (`#1A1A28`) | Elevated surfaces |
| `Color.pingBorder` (white α=0.07) | Hairline borders |
| `Color.pingTextPrimary` (`#F0F0F8`) | Headlines and body text |
| `Color.pingTextSecondary` (`#6B6B84`) | Captions, placeholders |
| `Color.pingAccent` (`#F5A623`) | Primary CTAs, decorative accents |
| `Color.pingHot` / `Color.pingLive` | Reserved for status indicators |

**Font tokens (`Core/Theme/Font+Tokens.swift`):** Typed helpers `Font.syne(_:size:relativeTo:)` and `Font.dmSans(_:size:relativeTo:)`. The underlying fonts (Syne Regular/Bold/ExtraBold + DM Sans Regular/Medium/SemiBold/Bold) are bundled as `.ttf` resources and declared in `Info.plist` under `UIAppFonts`. A DEBUG assertion in `FontRegistrationCheck.run()` (invoked from `PingItApp`'s `.task`) catches font-registration regressions on first launch.

**Dark mode enforcement:** `.preferredColorScheme(.dark)` is applied at the `WindowGroup` root in `PingItApp.swift`. Light mode is not supported.

**Reusable components live under feature-scoped `Views/Components/` folders.** As of 2026-06-01, the authentication feature owns:
- `PrimaryPillButtonStyle` / `SecondaryPillButtonStyle` — `ButtonStyle`s for the Welcome screen's amber and surface pill CTAs.
- `AuthCTAButtonStyle` — auth-form CTA with enabled/disabled state colour transition (amber fill → surface fill) and glow.
- `RadarBackground` — animated decorative background; respects `accessibilityReduceMotion`.
- `PingItLogoMark` / `PingItWordmark` — the brand-mark composition used on the Welcome screen.
- `AuthBackButton` / `AuthScreenHeader` — shared 38pt dark-circle back button and title row used on every non-Welcome auth screen (also consumed by `BlockedUsersView`).
- `AuthInputField` / `AuthPasswordField` — 52pt rounded surface inputs with leading SF Symbol icon, optional trailing slot, and (for passwords) an eye toggle.
- `AuthCheckbox` — 20pt rounded square checkbox with amber fill + bold white SF Symbol checkmark when checked.
- `AuthFieldHint` — 12pt DM Sans helper text with `error` / `soft` / `success` tone variants.

The Settings feature owns (added 2026-06-01):
- `SettingsSection` — rounded `pingSurface` card with optional uppercase section label; `isDestructive` variant swaps the hairline border for a 20% `pingHot` tint (used by the Delete Account container).
- `SettingsRow` — generic 52pt-min row with `DM Sans Medium 15pt` label, optional `labelColor` override, optional tap action, and a `ViewBuilder` trailing slot. Convenience initializer renders a `SettingsChevron` when no trailing view is supplied.
- `SettingsRowDivider` — 1pt `pingBorder` hairline inset 18pt from the leading edge.
- `PingItToggle` — custom 48×28 capsule toggle; off-state uses `pingSurfaceElevated`, on-state uses `pingLive`; sliding white thumb animated with `spring(response: 0.25, dampingFraction: 0.7)`.
- `PingItConfirmationDialog` — generic ZStack overlay with a dimmed backdrop, a centered `pingSurfaceElevated` card, spring scale + opacity transition, and tap-to-dismiss on the backdrop. Auxiliary primitives: `DialogTitleBlock`, `DialogButtonRow`, `DialogSecondaryButtonStyle`, `DialogDestructiveButtonStyle`. Use this instead of system `.alert()` / `.confirmationDialog()`.
- `HoldToConfirmButton` — destructive press-and-hold pill (default 7.5s, ease-out cubic). Fill ramps left-to-right; eight persuasion labels cycle as progress advances; the pill shakes increasingly past 55%; light haptic taps fire every 10% of progress (medium past 80%, heavy on completion). Cancellation collapses the fill in 0.25s.
- `AccountFarewellCard` — animated sad-face card (amber gradient face, blinking eyes, repeating teardrop, sad mouth) shown for ~4s after account deletion before sign-out is finalized.
- `BlockedUserRow` — avatar + username + amber-tinted `Unblock` pill on a single 64pt-min row.
- `BlockedUsersEmptyState` — circular glyph + Syne title + DM Sans body; replaces `ContentUnavailableView` for the no-blocks / error states.

The Profile feature owns (added 2026-06-01):
- `ProfileAvatarBlock` — 86pt avatar circle with the user's initial letter (Syne ExtraBold 36pt white on `pingAccent`) or `AsyncImage` if a profile photo URL exists; 3pt `pingAccent` 40% stroke, 12pt amber glow shadow; 28pt `pingAccent` circle at bottom-right with SF Symbol pencil for photo editing.
- `ProfileStatsCard` — 3-column HStack in a rounded `pingSurface` card with `pingBorder` stroke; each column shows a Syne ExtraBold 22pt amber value + DM Sans Regular 11pt uppercase label. Displays ping count, total boosts received, and relative member age.
- `ProfileInfoCard` — 3-row information card (Username, Email, Member since) in a `pingSurface` card. Username row supports inline editing: the text swaps to a `TextField` when `isEditing` is true, with optional error text below.
- `PhotoSourcePicker` — Bottom sheet with drag handle, "Profile Photo" title, and action rows (Choose from Library, Take Photo, Remove Photo) in a `pingSurface` card. Uses `SettingsRowButtonStyle` and `SettingsRowDivider` for consistent row styling.
- `SettingsRowButtonStyle` — Shared `ButtonStyle` for tappable rows; white 3% highlight on press with 0.12s ease-out animation. Promoted from Settings (was private) for cross-feature reuse.

The Map feature owns (added 2026-06-01):
- `MapPingSheet` — Native `.sheet` (presentation detents `[280, .medium, .large]`) presenting a compact ping preview when tapping a map marker. Author avatar, urgency label, title (with category emoji), optional description, boost/member stats, and JOIN CHAT + Details capsule buttons.
- `PingAnnotationView` — Map marker built from `Color.pingSurface` dot with an accent-colored border (amber default, `pingHot` for hot or critical), category emoji content, dual SwiftUI pulse rings (`scaleEffect` + `opacity` via `Task`-scheduled `repeatForever` animation, faster cadence when critical), boost-count capsule badge (`pingAccent` background, `pingBackground` border), and a continuous horizontal shake when urgency is `.critical`. All animations respect `accessibilityReduceMotion`.
- `PingClusterAnnotationView` — Same surface treatment as the individual marker. Diameter scales with count (46 / 52 / 58 pt at <10 / <100 / ≥100). Accent + border + label color flip to `pingHot` if any member is hot or critical.
- `MapAlertChip` — Glass alert pill used for transient map-level notifications. 3pt animated accent stripe (capsule with breathing shadow), SF Symbol icon, title + optional subtitle, optional inline action capsule, optional dismiss button. Background blends `pingSurface 85%` over `.ultraThinMaterial` with a leading accent gradient overlay (`.plusLighter`). Slides in from above on first appearance.
- `EmailVerificationBannerView` — Now a thin wrapper that configures `MapAlertChip` with the email-verification copy and Resend/Dismiss actions.

The Feed feature owns (added 2026-06-01):
- `FeedSortChip` — Capsule toggle chip; selected state uses `pingAccent` 13% background fill + amber border; unselected uses `pingSurface` + `pingBorder`. DM Sans Medium 12pt label.
- `FeedHotBadge` — Red capsule badge ("HOT") with DM Sans Bold 10pt white text on `pingHot` background, 0.8pt letter tracking.
- `FeedLivePulse` — 7pt pulsing green dot (scale 1→1.3, opacity 1→0.6 on 1.5s infinite animation) + "LIVE" label in DM Sans SemiBold 11pt `pingLive`.
- `FeedEmptyState` — Pin emoji (40pt) + Syne Bold 18pt title + DM Sans Regular 14pt subtitle for zero-ping state.
- `PingFeedCardView` — Composite card with: urgency edge bar (4pt red <1.5h / amber <6h), avatar circle with initial letter, `@username` label, hot badge, Syne Bold 17pt title, urgency-colored countdown label, boost/member counts, optional media indicator. Hot cards: `pingHot` 35% border (1.5pt) + 18% shadow. Critical cards: `phaseAnimator` breathing pulse (scale + red overlay + pulsing border). Urgent cards: amber shimmer sweeps down edge bar. All animations respect `accessibilityReduceMotion`.
- `PingUrgency` — Enum (`.critical` / `.urgent` / `.normal`) derived from time remaining; used by card edge bar, countdown label color, and card animations.

**Legal screens render natively.** `Features/Authentication/Models/LegalDocument.swift` parses the bundled `terms.html` / `privacy.html` resources into a small `LegalDocument` block model (`heading`, `sectionHeading`, `updated`, `paragraph`, `bullets`), and `Features/Authentication/Views/LegalDocumentView.swift` renders those blocks with the design tokens. The previous `WKWebView`-based `WebContentView` was removed.

### Actual File Listing (as of 2026-05-07)

```
PingIt/
├── App/
│   ├── PingItApp.swift              @main, FirebaseApp.configure(), environment injection, notification routing, analytics + crashlytics + performance user tracking
│   ├── RootView.swift               Auth gate with suspension + onboarding checks: Auth or Suspended or Onboarding or MainTabView
│   ├── MainTabView.swift            Tab bar (Map, Feed, Profile, Settings) tinted `pingAccent` for selected tab; handles notification navigation
│   └── NavigationRouter.swift       @Observable router for push notification → ping navigation
├── Core/
│   ├── Models/
│   │   ├── User.swift               Firestore: users collection
│   │   ├── Ping.swift               Firestore: pings collection (+ PingStatus enum, imageUrl, description)
│   │   ├── Chat.swift               Firestore: chats collection
│   │   ├── ChatMessage.swift        Firestore: chatMessages collection (+ reactions, messageType, latitude, longitude, locationName)
│   │   ├── ChatParticipant.swift    Firestore: chatParticipants collection
│   │   ├── Block.swift              Firestore: blocks collection
│   │   ├── Boost.swift             Firestore: boosts collection
│   │   └── Report.swift             Firestore: reports collection (+ ReportTargetType, ReportReason, ReportStatus enums)
│   ├── Protocols/
│   │   ├── ListenerRemovable.swift                      ListenerHandle wrapping ListenerRegistration
│   │   ├── AuthUserRepresentable.swift                  Minimal user identity (uid, isEmailVerified)
│   │   ├── FirebaseUser+AuthUserRepresentable.swift     Firebase conformance
│   │   ├── AuthServicing.swift                          Auth service contract (+ isEmailVerified, sendEmailVerification, reloadUser)
│   │   ├── PingServicing.swift                          Ping service contract (+ callable-backed delete/boost, image upload, pre-ID create)
│   │   ├── ChatServicing.swift                          Chat service contract (+ callable-backed join/leave, toggleReaction)
│   │   ├── UserServicing.swift                          User profile + username reservation contract (+ mergeUser, ensureUserProfileExists for orphan-account recovery)
│   │   ├── LocationServicing.swift                      Location service contract
│   │   ├── BlockServicing.swift                         Block/unblock, real-time bidirectional listeners
│   │   ├── ContentModeratingServicing.swift             Text moderation (check → .allowed/.blocked)
│   │   ├── RateLimitServicing.swift                     Ping + message rate limiting
│   │   ├── ReportServicing.swift                        Submit report via callable
│   │   ├── NotificationServicing.swift                  FCM token + location update contract
│   │   ├── AnalyticsServicing.swift                     Event logging + user ID tracking
│   │   ├── CrashReportingServicing.swift                Crash/error reporting + user ID
│   │   ├── PerformanceServicing.swift                   Custom trace creation + metrics
│   │   ├── ImageStorageServicing.swift                  Profile image upload/delete
│   │   └── DataExportServicing.swift                    GDPR data export via callable
│   ├── Services/
│   │   ├── AuthService.swift            Firebase Auth wrapper, auth state listener, email verification
│   │   ├── PingService.swift            Ping creation/read/listen, callable delete and boost, image upload
│   │   ├── ChatService.swift            Messages, callable join/leave, snapshot listener, toggleReaction
│   │   ├── UserService.swift            User profile CRUD + usernames reservation documents (+ mergeUser uses setData(merge: true); ensureUserProfileExists backfills a placeholder doc when an Auth user has no Firestore doc)
│   │   ├── LocationService.swift        CLLocationManager, GeoJSON boundary check
│   │   ├── BlockService.swift           @Observable @MainActor; two Firestore snapshot listeners for real-time bidirectional blocking
│   │   ├── ContentModerationService.swift  Bundle wordlist, localizedStandardContains matching
│   │   ├── RateLimitService.swift       UserDefaults-backed limits; #if DEBUG bypass
│   │   ├── ReportService.swift          Calls submitReport callable and maps duplicate report errors
│   │   ├── NotificationService.swift   FCM token registration, APNs permission, foreground banners, location update
│   │   ├── AnalyticsService.swift       Wraps FirebaseAnalytics event logging and user ID
│   │   ├── CrashReportingService.swift  Wraps FirebaseCrashlytics crash/error reporting and user ID
│   │   ├── PerformanceService.swift    Wraps FirebasePerformance custom traces and metrics
│   │   ├── ImageStorageService.swift    Wraps Firebase Storage for profile image upload/delete
│   │   └── DataExportService.swift      Calls exportUserData callable, returns JSON data
│   └── Utilities/
│       ├── Constants.swift              Cluj coords, limits, Firestore collection names (+ blocks, reports, boosts, usernames, Reaction, MessageType, Storage additions)
│       ├── PingItError.swift            Typed error enum (+ reactionFailed, locationSharingFailed, pingImageTooLarge, pingImageUploadFailed, etc.)
│       ├── Date+Extensions.swift        Countdown (ServerTime-corrected), relative formatting
│       ├── ActivityViewRepresentable.swift  UIActivityViewController wrapper for share sheet
│       ├── ServerTime.swift             Firebase RTDB .info/serverTimeOffset for clock sync
│       └── GeoJSONBoundaryValidator.swift  Ray casting point-in-polygon
│   └── Theme/
│       ├── Color+Tokens.swift           Dark-mode palette as Color extensions (pingBackground, pingSurface, pingSurfaceElevated, pingBorder, pingTextPrimary, pingTextSecondary, pingAccent, pingHot, pingLive)
│       ├── Font+Tokens.swift            SyneWeight + DMSansWeight enums; Font.syne(_:size:relativeTo:) and Font.dmSans(_:size:relativeTo:) helpers
│       └── FontRegistrationCheck.swift  DEBUG-only assertion verifying every custom font weight loads at launch
├── Features/
│   ├── Authentication/
│   │   ├── Models/
│   │   │   ├── AuthRoute.swift             Navigation route enum (+ privacyPolicy)
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
│   │       ├── TermsOfServiceView.swift    Terms of Service (WKWebView loading terms.html)
│   │       ├── PrivacyPolicyView.swift    Privacy Policy (WKWebView loading privacy.html)
│   │       ├── WebContentView.swift       UIViewRepresentable WKWebView wrapper for bundled HTML
│   │       └── Components/
│   │           ├── AuthTextField.swift             Styled field with icon + validation indicator
│   │           ├── AuthSecureField.swift            Password field with show/hide toggle
│   │           ├── PasswordStrengthView.swift       Segmented strength bar + rule checklist
│   │           ├── PrimaryPillButtonStyle.swift     Amber pill ButtonStyle with glow shadow
│   │           ├── SecondaryPillButtonStyle.swift   Surface pill ButtonStyle with hairline border
│   │           ├── RadarBackground.swift            3 concentric pulsing rings + 8 blinking dots; respects accessibilityReduceMotion
│   │           ├── PingItLogoMark.swift             18pt amber core with two halo layers and breathing pulse
│   │           └── PingItWordmark.swift             Logo mark + "PINGIT" Syne ExtraBold wordmark; VoiceOver reads "PingIt" as a header
│   ├── Map/
│   │   ├── Models/
│   │   │   └── PingCluster.swift    Cluster model: grouped pings, center, containsHotPing
│   │   ├── ViewModels/
│   │   │   └── MapViewModel.swift   Ping listener lifecycle, map state; filters expired + blocked; hotPingIds; manual clustering; overlapping pin offset
│   │   └── Views/
│   │       ├── MapView.swift              SwiftUI Map: floating "Map" title, glass recenter button, top gradient, amber FAB, MapAlertChip stack, MapPingSheet sheet; POIs hidden, flat elevation
│   │       ├── MapPingSheet.swift         Native .sheet with presentation detents for compact ping preview
│   │       ├── PingAnnotationView.swift   Emoji-in-dot marker with dual SwiftUI pulse rings, boost badge, accent border, critical shake
│   │       ├── PingClusterAnnotationView.swift  Surface-styled cluster, count label, size scales with member count, hot/critical border
│   │       ├── MapAlertChip.swift         Glass alert pill with animated accent stripe (warning, error, info severities)
│   │       └── EmailVerificationBannerView.swift  Configures MapAlertChip with verify-email copy + resend/dismiss
│   ├── Ping/
│   │   ├── Models/
│   │   │   └── PingCategory.swift         Enum with 9 categories (sports, study, social, music, food, skate, chill, gaming, art) + label + emoji
│   │   ├── ViewModels/
│   │   │   ├── CreatePingViewModel.swift   Validation, moderation, rate limit, location, category, description, Firestore write
│   │   │   └── PingDetailViewModel.swift   Creator loading, countdown, delete, ping document listener, boost, urgency, category display
│   │   └── Views/
│   │       ├── CreatePingView.swift        Modal bottom sheet: header + ScrollView sections + fixed CTA button
│   │       ├── PingDetailView.swift        Full-screen detail: custom nav bar, author+timer row, urgency pill, title, description, stats card with boost, join chat, delete, report/block
│   │       ├── LocationPickerView.swift    Sheet: 3-option card (GPS / map pin / search) with dark styling
│   │       ├── MapPinPickerView.swift      Full-screen map with centered amber pin + dark bottom bar
│   │       └── Components/
│   │           ├── FlowLayout.swift              Custom Layout protocol wrapping chip grid
│   │           ├── CategoryChip.swift             Capsule chip with emoji + label (selected = amber 15% fill + amber border)
│   │           ├── ExpiryPill.swift               Equal-width capsule duration pill (6h / 24h / 48h / Custom)
│   │           ├── CreatePingHeader.swift          Drag handle + "New Ping" title + ✕ dismiss button
│   │           ├── CreatePingSectionLabel.swift    ALL CAPS DM Sans SemiBold 11pt section header
│   │           ├── CreatePingButton.swift          Fixed-bottom CTA with dynamic label ("Fill in the details" → "⚡ PING IT")
│   │           ├── CreatePingCategorySection.swift FlowLayout of 9 CategoryChips with toggle selection
│   │           ├── CreatePingTextSection.swift     TextEditor with custom placeholder + char count (title, 280 max)
│   │           ├── CreatePingDescriptionSection.swift  Optional description TextEditor + char count (500 max)
│   │           ├── CreatePingPhotoSection.swift    Dashed add button / image preview with red ✕ remove
│   │           ├── CreatePingExpirySection.swift   4 ExpiryPills + collapsible DatePicker for custom
│   │           ├── CreatePingLocationSection.swift Styled row with pin icon + chevron
│   │           └── CreatePingErrorBanner.swift     Warning icon + error text in pingHot
│   ├── Chat/
│   │   ├── ViewModels/
│   │   │   └── ChatViewModel.swift         Message listener, send (with moderation + rate limit), join; filters blocked; ping doc listener (also stores currentPing for the header); user profile cache; toggleReaction; sendLocationMessage
│   │   └── Views/
│   │       ├── ChatView.swift              Custom dark screen: ChatHeader on top, ScrollView with day-grouped LazyVStack, MessageInputBar via safeAreaInset, ChatStateView overlays for loading/error/empty
│   │       ├── MessageBubbleView.swift     ChatBubbleShape tail bubbles, design-token colors, avatar on first-of-burst (28pt), anonymous label, long-press fires haptic + onLongPress callback, routes location messages to inline ChatLocationBubble (map fills bubble, name on gradient overlay)
│   │       ├── ReactionSummaryView.swift   Surface-capsule emoji badges with amber selection state
│   │       └── Components/
│   │           ├── ChatHeader.swift         Back button + ping emoji/title + TimelineView LIVE pulse + ChatUrgencyPill (color from PingUrgency)
│   │           ├── MessageInputBar.swift    Capsule TextField w/ custom placeholder, share-location pill, amber paperplane send button w/ shadow & loading state
│   │           ├── ChatDateSeparator.swift  Today / Yesterday / date label with hairlines on either side
│   │           ├── ChatBubbleShape.swift    Per-corner-radius `Shape` used to give one bubble corner a 4pt tail
│   │           └── MessageActionOverlay.swift  Long-press overlay: amber-bordered reaction pill (8 emoji, staggered bounce-in), Report/Block action card, ultraThinMaterial backdrop
│   ├── Feed/
│   │   ├── ViewModels/
│   │   │   └── FeedViewModel.swift      Ping listener, sort/filter, creator cache, distance, urgency + expiry timer
│   │   └── Views/
│   │       ├── FeedView.swift           Custom header with live pulse, sort chips (Hot/New/Expiring), card list, empty state
│   │       ├── PingFeedCardView.swift   Urgency edge bar, avatar, hot badge, urgency-colored countdown, media indicator
│   │       └── Components/
│   │           ├── FeedSortChip.swift       Capsule toggle chip (selected = amber fill + border)
│   │           ├── FeedHotBadge.swift        Red capsule "HOT" badge for high-engagement pings
│   │           ├── FeedLivePulse.swift       Pulsing green dot + "LIVE" label for feed header
│   │           └── FeedEmptyState.swift      Pin emoji + copy for zero-ping state
│   ├── Onboarding/
│   │   ├── ViewModels/
│   │   │   └── OnboardingViewModel.swift  3-page tutorial state, completes via UserService + Analytics
│   │   └── Views/
│   │       ├── OnboardingView.swift       Design-system 3-page tutorial: dark background, Skip pill, hidden-indicator TabView for swipe, custom capsule page indicator, amber Get Started / Next CTA
│   │       └── OnboardingPageView.swift   Emoji hero in pingSurface plate with TimelineView pulse rings + amber accent badge, Syne ExtraBold title, DM Sans subtitle
│   ├── Report/
│   │   ├── ViewModels/
│   │   │   └── ReportViewModel.swift       Reason selection, submit, block offer after success
│   │   └── Views/
│   │       └── ReportView.swift            Design-system sheet: drag-handle header, reason cards w/ amber radio, styled TextEditor for details, capsule submit, success + block-offer cards
│   ├── Profile/
│   │   ├── ViewModels/
│   │   │   └── ProfileViewModel.swift      Profile CRUD, stats computation, username edit mode, Storage upload
│   │   └── Views/
│   │       ├── ProfileView.swift           Redesigned profile screen: avatar block, stats card, info card, photo source sheet
│   │       ├── CameraPickerView.swift      UIKit camera wrapper
│   │       └── Components/
│   │           ├── ProfileAvatarBlock.swift     86pt avatar circle (initial letter or AsyncImage), amber glow, edit pencil overlay
│   │           ├── ProfileStatsCard.swift       3-column HStack (Pings / Boosts / Member age) in pingSurface card
│   │           ├── ProfileInfoCard.swift        Username (inline-editable) / Email / Member since rows in pingSurface card
│   │           └── PhotoSourcePicker.swift      Bottom sheet: Choose from Library / Take Photo / Remove Photo
│   └── Settings/
│       ├── Models/
│       │   └── SettingsRoute.swift              Navigation route enum (blockedUsers, termsOfService, privacyPolicy)
│       ├── ViewModels/
│       │   ├── BlockedUsersViewModel.swift      Loads blocked users with profiles, unblock action
│       │   └── DeleteAccountViewModel.swift     @Observable @MainActor; tracks delete-flow step (confirmIntent → reauthenticate → farewell), password input, loading + error state; splits reauth + deleteAccountRecord from finalizeSignOut
│       └── Views/
│           ├── SettingsView.swift               Custom Settings tab: SettingsSection cards, PingItToggle, custom Sign Out + Delete Account modals (hold-to-confirm + farewell card), NavigationStack driving SettingsRoute
│           ├── BlockedUsersView.swift           Custom Blocked Users list with AuthScreenHeader, BlockedUserRow cards, and PingItConfirmationDialog for unblock
│           └── Components/
│               ├── SettingsSection.swift            Rounded card container with optional uppercase label; isDestructive variant tints border with pingHot
│               ├── SettingsRow.swift                Generic settings row with label color override and trailing ViewBuilder slot; default trailing renders SettingsChevron
│               ├── SettingsRowDivider.swift         1pt pingBorder hairline divider, inset 18pt leading
│               ├── PingItToggle.swift               Custom 48×28 capsule toggle with spring-animated thumb
│               ├── PingItConfirmationDialog.swift   Custom modal overlay with dimmed backdrop; includes DialogTitleBlock, DialogButtonRow, DialogSecondaryButtonStyle, DialogDestructiveButtonStyle
│               ├── HoldToConfirmButton.swift        Destructive press-and-hold pill (7.5s ease-out fill, cycling labels, haptic ticks, shake past 55%)
│               ├── AccountFarewellCard.swift        Animated sad-face card shown after account deletion before sign-out
│               ├── BlockedUserRow.swift             Avatar + username + amber Unblock pill row
│               └── BlockedUsersEmptyState.swift     Circular glyph + Syne title + DM Sans body for empty/error states

└── Resources/
    ├── ClujNapoca.geojson           Cluj-Napoca admin boundary (OSM)
    ├── moderation_wordlist.txt      Client-side profanity filter wordlist (one word per line)
    ├── terms.html                   Terms of Service (bundled HTML, loaded by WebContentView)
    └── privacy.html                 Privacy Policy (bundled HTML, loaded by WebContentView)

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
│   ├── MockCrashReportingService.swift       Records reported errors for test assertions
│   ├── MockPerformanceService.swift          Stub traces for test assertions
│   └── MockImageStorageService.swift         Tracks upload/delete calls for test assertions
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
│   ├── ProfileViewModelTests.swift
│   ├── OnboardingViewModelTests.swift
│   └── FeedViewModelTests.swift
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
  → Shared cleanup deletes ping images from Firebase Storage (ping_images/{pingId}/)
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
  → Shared cleanup deletes associated chat, chatMessages, chatParticipants, boosts, and ping images from Storage
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
                     └─ marker tap ──▶ MapPingSheet (overlay) ──▶ JOIN CHAT → ChatView / Details → PingDetailView

PingDetailView ──observes──▶ PingDetailViewModel ──calls──▶ PingService (callable delete/boost, boost check)
                                                            ChatService
                                                            AnalyticsService (logs boost_used)
             └─ custom nav bar, urgency pill, stats card (boost + member count)
             └─ join chat button ──▶ ChatView
             └─ delete button ──▶ PingItConfirmationDialog
             └─ report/block buttons ──▶ ReportView / PingItConfirmationDialog + BlockService

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
                                                      ImageStorageService ──calls──▶ Firebase Storage
                                                      PingService.fetchPings(byCreatorId:) ──reads──▶ Firestore (pings)
                                                      AuthService ──calls──▶ Firebase Auth
             └─ PhotoSourcePicker ──▶ PhotosPicker / CameraPickerView / PingItConfirmationDialog (remove photo)

ReportView ──observes──▶ ReportViewModel ──calls──▶ ReportService ──calls──▶ submitReport Cloud Function

SettingsView ──▶ BlockedUsersView ──observes──▶ BlockedUsersViewModel ──calls──▶ BlockService + UserService

MapView ── uses ──▶ NotificationService.updateLastKnownLocation (on first location fix)

SettingsView ── deleteAccount ──▶ DeleteAccountViewModel
   ├─ AuthService.reauthenticate(password:)
   ├─ AuthService.deleteAccountRecord() ──▶ deleteAccount Cloud Function
   ├─ AccountFarewellCard shown for ~4s
   └─ AuthService.signOut() ──▶ auth listener routes to Welcome
The split exists so the farewell card can render before the auth state flips and SettingsView is unmounted; AuthService.deleteAccount() (the legacy combined method) is preserved and just chains the two steps.

PingItApp ── .task ──▶ NotificationService.requestPermission (one-time) + registerFCMToken
          └─ sets UNUserNotificationCenter.delegate + Messaging.delegate
          └─ .onReceive(PingItOpenPing) ──▶ NavigationRouter.pendingPingId
          └─ .onReceive(PingItOpenRecap) ──▶ NavigationRouter.pendingRecapId
              (recap_invite + followed_recap_photo pushes route here)
          └─ .onChange(of: auth.uid) ──▶ AnalyticsService.setUserId + CrashReportingService.setUserId
                                       + registerFCMToken (re-register on account change)
              registerFCMToken uses setData(merge:) so a pre-user-doc token write upserts

RootView ── checks ──▶ UserService.fetchUser (suspension + onboarding gate); falls through to UserService.ensureUserProfileExists if the Firestore doc is missing
         └─ if suspended ──▶ SuspendedAccountView
         └─ if not onboarded ──▶ OnboardingView ──observes──▶ OnboardingViewModel ──calls──▶ UserService + AnalyticsService
         └─ if onboarded ──▶ MainTabView

FeedView ──observes──▶ FeedViewModel ──calls──▶ PingService (real-time active pings listener)
                                                  LocationService (distance calculation)
                                                  BlockService (filters blocked creators)
                                                  UserService (creator profile cache)
                                                  AnalyticsService (logs feed_viewed, feed_sort_changed)
         └─ 60s expiry timer removes stale pings from feed in real time
         └─ sort chips: Hot (hotScore), New (createdAt), Expiring (expiresAt)
         └─ urgency signals: red edge (<1.5h), amber edge (<6h), red border+badge (isHot)
         └─ navigates to PingDetailView on card tap

NavigationRouter ──observed by──▶ MainTabView (tab switch) + MapView (ping navigation)

AuthenticationCoordinatorView ──routes──▶ LoginView / RegisterView / ForgotPasswordView / TermsOfServiceView / PrivacyPolicyView

SettingsView ── Legal section ──▶ TermsOfServiceView / PrivacyPolicyView (WebContentView + bundled HTML)
LoginView ──observes──▶ LoginViewModel ──calls──▶ AuthService ──calls──▶ Firebase Auth
RegisterView ──observes──▶ RegisterViewModel ──calls──▶ AuthService + UserService (username check)
ForgotPasswordView ──observes──▶ ForgotPasswordViewModel ──calls──▶ AuthService.sendPasswordReset
```

---

## Services Overview

| Service | Responsibility | Status |
|---------|---------------|--------|
| **AuthService** | Sign up, sign in, sign out, password reset, session state, email verification | Implemented |
| **PingService** | Client-side ping creation/read/listen, callable-backed delete/boost/RSVP/update, boost+RSVP state lookup, 7-day fetch for heatmap | Implemented |
| **FollowService** | Callable-backed user search + follow toggle; direct Firestore reads for follow state and Following list | Implemented |
| **PingRecapService** | Recap listeners (active recaps, photos subcollection), recap photo upload (Storage + Firestore) | Implemented |
| **ChatService** | Messages, snapshot listeners, callable-backed join/leave participant tracking | Implemented |
| **UserService** | Profile read/write, username reservation get/create/delete during signup and rename | Implemented |
| **LocationService** | CLLocationManager wrapper, boundary check | Implemented |
| **BlockService** | Real-time bidirectional blocking via two Firestore snapshot listeners, optimistic local updates | Implemented |
| **ContentModerationService** | Bundle wordlist check, returns `.allowed`/`.blocked(reason:)` | Implemented |
| **RateLimitService** | UserDefaults-backed ping + message rate limiting, `#if DEBUG` bypass | Implemented |
| **ReportService** | Calls `submitReport`, maps duplicate report callable error to user-visible `reportAlreadySubmitted` | Implemented |
| **ServerTime** | Firebase RTDB `.info/serverTimeOffset` for clock-skew correction; `ServerTime.now` | Implemented (utility enum) |
| **NotificationService** | FCM token registration, APNs permission, foreground notification display, lastKnownLocation update | Implemented |
| **AnalyticsService** | Wraps FirebaseAnalytics for event logging (`ping_created`, `ping_edited`, `ping_shared`, `rsvp_toggled`, `chat_joined`, `boost_used`, `onboarding_completed`, `reaction_toggled`, `location_shared`, `feed_viewed`, `feed_sort_changed`) and user ID tracking | Implemented |
| **CrashReportingService** | Wraps FirebaseCrashlytics for crash/non-fatal error reporting and user ID tracking | Implemented |
| **ImageStorageService** | Wraps Firebase Storage for profile image upload/delete; protocol-abstracted for testability | Implemented |
| **DataExportService** | Calls `exportUserData` callable, returns JSON data for GDPR Article 20 portability | Implemented |

### Service Injection Pattern

Services are created as `@State` in `PingItApp` and injected via `.environment()`. Views access them with `@Environment(ServiceType.self)`. ViewModels will receive services via init parameters for testability.

---

---

## Cloud Functions Architecture

**Runtime:** TypeScript, Firebase Cloud Functions v2, Node 20

```
functions/src/
├── index.ts                      App initialization, exports all functions
├── expirePings.ts                Scheduled: every 5 minutes, batch-expires pings, creates recaps from RSVPs, GCs expired recaps
├── pingCleanup.ts                Shared chunked cleanup for ping chat/messages/participants/boosts/rsvps
├── pingCallables.ts              Callable: deletePing, updatePing, boostPing, rsvpPing, joinChat, leaveChat
├── socialCallables.ts            Callable: toggleFollow, searchUsers
├── followNotifications.ts        Firestore triggers: 4 follow-activity pushes (new follower, ping, RSVP, recap photo)
├── blockTriggers.ts              Firestore trigger: severFollowsOnBlock — block deletes both follow edges + counters
├── recapTriggers.ts              Firestore trigger: onRecapPhotoCreated maintains recap photoCount
├── cleanupRecaps.ts              Shared: deletes expired recap docs + photos subcollection + Storage files
├── reportCallables.ts            Callable: submitReport with deterministic report IDs (pings, messages, users)
├── deleteAccount.ts              Callable: GDPR cascading delete (pings, chats, messages, boosts, rsvps, follows, blocks, reports, storage, auth)
├── sendNearbyNotification.ts     Firestore trigger: pings onCreate → 2km Haversine filter → FCM push
├── sendHotPingNotification.ts    Firestore triggers: boosts onCreate + chatParticipants onWrite → hot score check → FCM push
├── moderateImage.ts              Storage trigger: onObjectFinalized → Vision API SafeSearch → auto-remove or flag (ping + recap photos)
├── removeContent.ts              Callable: admin emergency content removal (ping, message, user suspension) with audit trail
└── exportUserData.ts             Callable: GDPR data export — collects all user data and returns JSON
```

### Cloud Function Data Flows

```
Ping Expiration (cron every 5min):
  expirePings → query pings where status=="active" AND expiresAt<=now
    → batch update status="expired"
    → shared cleanup deletes: chat, chatMessages, chatParticipants, boosts, ping images from Storage

Ping Deletion (callable):
  deletePing({ pingId })
    → require auth
    → verify caller owns the ping
    → ignore client-supplied related IDs
    → shared cleanup sets status="removed"
    → delete related chat, chatMessages, chatParticipants, boosts in chunked batches
    → delete ping images from Storage (ping_images/{pingId}/)

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

Data Export (callable):
  exportUserData(auth.uid)
    → require auth
    → collect: user profile, pings, messages, boosts, blocks, reports, chat participations
    → return JSON object with all user data (GDPR Article 20 portability)

RSVP (callable):
  rsvpPing({ pingId })
    → require auth, non-suspended user, active ping, non-creator, no bidirectional block
    → toggle deterministic rsvps/{pingId}_{uid} + FieldValue.increment(±1) on pings.rsvpCount
    → return { rsvpCount, isAttending }

Ping Edit (callable):
  updatePing({ pingId, text, description?, category })
    → require auth, non-suspended user, active ping, creator-only
    → validate: text ≤280, description ≤500, category in whitelist
    → update text/category, set/delete description, stamp editedAt (serverTimestamp)
    → clients receive the change live via existing ping listeners

Recap Lifecycle:
  expirePings (cron) → for each expiring ping with RSVPs:
    → create pingRecaps/{pingId} { attendeeIds (from rsvps), location, title,
      recapWindowClosesAt (+2h), ghostExpiresAt (+24h), photoCount: 0 }
    → FCM to attendees → cleanupPing (also deletes rsvps)
  onRecapPhotoCreated → increment photoCount (skips isModerated docs)
  moderateImage (recap_photos/) → transactional isModerated flag + photoCount decrement
  expirePings (cron) → cleanupExpiredRecaps: delete recap docs + photos + Storage after ghostExpiresAt

Follow System (callables + triggers):
  toggleFollow({ targetUserId })
    → require auth, non-suspended, not-self, target exists
    → new follows rejected if target isPrivateProfile or bidirectional block
    → transaction: create/delete follows/{followerId}_{followedId} + increment/decrement
      followerCount/followingCount on both user docs
  searchUsers({ query })
    → prefix query on usernameLowercase where isPrivateProfile == false (composite index)
    → filters self + bidirectional blocks; returns safe fields only
  followNotifications (4 onDocumentCreated triggers)
    → follows → "X started following you"; pings/rsvps/recap photos → pushes to actor's followers
    → all suppressed if actor went private (dormancy), recipient disabled notifyFollowActivity,
      or a bidirectional block exists
  severFollowsOnBlock (blocks onCreate)
    → transactionally delete both follow edges + fix all four counters
```

---

_This document will be updated as features are implemented and architecture evolves._
