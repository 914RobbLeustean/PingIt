# PingIt — Product & Engineering Specification

**Version:** 1.0
**Last Updated:** May 6, 2026
**Target Launch:** July 1, 2026 (Cluj-Napoca, Romania)
**Thesis Submission:** July 1, 2026

---

## 1. Product Vision

### 1.1 What We Are Building

PingIt is a native iOS application for real-time, ephemeral, location-based social discovery. Users create time-limited geo-tagged posts called **pings** on a city map. Each ping announces a spontaneous activity — a pickup game, a study session, a bar crawl — and automatically generates a public group chat. Any user in the city can see all active pings on the map, tap one, and join the conversation. No friend request, no prior relationship, no social graph required. The entry point is curiosity about what is happening nearby.

The application is scoped to **Cluj-Napoca, Romania**, a city of 308,000 with roughly 100,000 students, 78% of whom relocate from outside the region. The target demographic is **18-25 year old university students** without an established local network.

### 1.2 Why It Exists

Existing platforms fail this user in one of two ways. Ephemeral platforms like Snapchat and BeReal lower participation pressure but keep content inside closed friend networks. Location-based platforms like Foursquare, Nextdoor, Happn, and Bump anchor geography to a pre-existing social context — venue documentation, verified residency, romantic matching, or an existing friend graph. None supports open, real-time, activity-based discovery among strangers in a shared urban space. **PingIt occupies that gap.**

The theoretical foundation comes from three frameworks:
- **Temporal relevance theory** justifies ping expiration as a mechanism for keeping map content actionable
- **Spatial self framework** justifies the map-centered interface where location communicates intent
- **Social capital theory** justifies open stranger interaction as the mechanism through which new local connections can begin to form

---

## 2. Technical Architecture

### 2.1 Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Swift + SwiftUI | Native iOS UI, lifecycle management |
| **Maps** | Apple MapKit | City map rendering, annotations |
| **Local Cache** | Firestore offline persistence | Automatic local data caching |
| **Authentication** | Firebase Auth | Email/password, session management |
| **Database** | Cloud Firestore | Real-time sync, geospatial queries |
| **Media Storage** | Firebase Storage | Profile pictures, ping images (Phase 2+) |
| **Server Logic** | Cloud Functions (Node.js) | Server-authoritative ping cleanup, boosts, chat participants, reports, moderation triggers, push notifications |
| **Content Moderation** | Google Cloud Vision API | Image safety analysis (SafeSearch) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) | Hot ping alerts, chat notifications |
| **Geospatial** | GeoFirestore library | Geohash-based location queries |

**Key Architectural Principle:** Single source of truth (Firestore). No Core Data sync layer.

### 2.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                       iOS Client (Swift)                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ SwiftUI  │  │ MapKit   │  │ Firebase │  │ Firestore│     │
│  │   Views  │  │  Render  │  │   Auth   │  │  Offline │     │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘     │
└─────────────────────────────────────────────────────────────┘
                            ▲ ▼
                    Network Boundary
                            ▲ ▼
┌────────────────────────────────────────────────────────────┐
│                  Firebase Cloud Infrastructure             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Firestore   │  │   Storage    │  │     Auth     │      │
│  │  (Database)  │  │  (Media)     │  │  (Sessions)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Cloud Functions (Server-Side Logic)          │  │
│  │  • Server-authoritative ping cleanup/counters        │  │
│  │  • Scheduled ping expiration (cron)                  │  │
│  │  • Content moderation triggers (Storage onCreate)    │  │
│  │  • Push notification dispatch (Firestore onWrite)    │  │
│  │  • Callable report duplicate prevention              │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                            ▲ ▼
                   External Services
                            ▲ ▼
                ┌────────────────────────┐
                │ Google Cloud Vision API│
                │  (SafeSearch Detection)│
                └────────────────────────┘
```

---

## 3. Data Model

### 3.1 Core Firestore Collections

The application uses the following Firestore collections. Each ping has a one-to-one relationship with a chat. When a ping expires or is removed, Cloud Functions mark the ping inactive and clean related chat, participant, message, and boost data.

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| **users** | User profiles, preferences, engagement metrics | userId, username, email, profileImageUrl, createdAt, blockedUsers[] |
| **usernames** | Username reservation and public availability checks | normalizedUsername, userId, createdAt |
| **userPreferences** | Privacy, UI, notification, discovery settings | userId, theme, language, notificationPrefs{}, privacySettings{} |
| **cities** | Geographic boundaries (GeoJSON), active ping/user counts | cityId, name, boundary (GeoJSON), activePingCount, activeUserCount |
| **pings** | Content, location (geohash), timing, moderation status, denormalized counts | pingId, creatorId, text, location, geohash, expiresAt, status, boostCount, participantCount, chatId |
| **pingMedia** | Images/videos with moderation scores (Phase 2+) | mediaId, pingId, storageUrl, moderationScore, status |
| **chats** | One-to-one with ping, metrics, settings | chatId, pingId, participantCount, lastMessageAt, createdAt |
| **chatMessages** | Text, reactions, location sharing, moderation | messageId, chatId, senderId, text, createdAt, isModerated |
| **chatParticipants** | Join/leave tracking, permissions | participantId `{chatId}_{userId}`, chatId, userId, joinedAt, leftAt |
| **follows** | Per-relationship notification preferences (Phase 2+) | followId, followerId, followedUserId, notifyOnPing, createdAt |
| **boosts** | Ping engagement tracking | boostId `{pingId}_{userId}`, pingId, userId, createdAt |
| **blocks** | User safety | blockId, blockerId, blockedUserId, createdAt |
| **reports** | Status tracking, comprehensive reporting | reportId `{reporterId}_{targetId}`, reporterId, targetType, targetId, reason, status, reviewedAt |
| **notifications** | Delivery tracking, action data | notificationId, userId, type, data{}, isRead, createdAt |
| **moderationActions** | Audit trail for all moderation decisions | actionId, moderatorId, targetType, targetId, action, reason, timestamp |

---

## 4. Feature Roadmap

### Phase 0: MVP
**Goal:** Working proof-of-concept demonstrating core user loop

**14 Features:**

#### Authentication (3 features)
1. **User Registration** — Email/password sign-up with username selection
2. **User Login** — Session management with Keychain token storage
3. **Basic Profile Management** — Username, profile picture upload to Firebase Storage

#### Map & Location (3 features)
4. **Real-Time Map Display** — MapKit integration with Cluj-Napoca centered view
5. **Cluj-Napoca Boundary Detection** — GeoJSON polygon check on ping creation
6. **Location Permission Management** — iOS location authorization flow

#### Ping Core (5 features)
7. **Create Text Ping** — Text input (max 280 chars), user-selected location via: (a) current GPS location, (b) search address with autocomplete, or (c) drag pin on map. Must be within Cluj-Napoca boundary. Future: Saved Places (Phase 2+)
8. **Set Ping Expiration** — 3 preset options: 6hr, 24hr, 48hr (simple picker UI)
9. **View Ping Details** — Full-screen detail view with text, creator, expiration countdown
10. **Delete Own Ping** — Creator can delete before expiration through `deletePing` callable (server-side cascading cleanup)
11. **Live Ping Visualization** — Map annotations update in real-time via Firestore listener

#### Chat Core (3 features)
12. **Join Ping Chat** — Tap ping → enter chat (`joinChat` callable creates/reactivates deterministic ChatParticipant)
13. **Send Text Message** — Text input, stored in Firestore, rate-limited (6 msgs/10sec)
14. **Real-Time Message Updates** — Firestore onSnapshot listener for instant message delivery

**Technical Deliverables:**
- Firebase project configured (Auth, Firestore, Storage, Functions)
- Cloud Function: `expirePings` (cron job, runs every 5 minutes)
- Cloud Functions: `deletePing`, `joinChat`, and `leaveChat` for server-owned destructive cleanup and participant counters
- GeoFirestore library integrated for spatial queries
- Cluj-Napoca GeoJSON boundary loaded from app bundle
- Firestore security rules with authenticated reads, strict client-owned creates, and server-owned counters/destructive writes

**Success Criteria:**
- Can create account, log in, see map, create ping, join chat, send message
- Pings expire automatically (tested with 5-minute expiration for validation)
- Offline mode: cached pings visible, messages queue for send when reconnected

---

### Phase 1: Safety & Discovery
**Goal:** App Store-ready with content moderation, engagement features, GDPR compliance

**16 Features:**

#### Content Moderation (5 features)
15. **Automated Image/Video Filtering** — Cloud Function calls Vision API on Storage upload
16. **Text Content Moderation** — Client-side keyword filter for profanity/hate speech
17. **User Report System** — Report ping or chat message (reason: spam, harassment, inappropriate)
18. **Content Review Queue** — Admin dashboard (web app, simple Firebase Hosting site)
19. **Emergency Content Removal** — Cloud Function: `removeContent` (callable, admin-only)

#### Discovery & Engagement (4 features)
20. **Boost Ping** — Any non-creator can boost any active unblocked ping once through `boostPing`
21. **Hot Pings Algorithm** — `hotScore = boostCount * 2 + participantCount + min(hoursRemaining * 0.1, 2.0)`, gated by `boostCount >= 3` and score `>= 8.0`
22. **Nearby Ping Notifications** — Push notification when new ping created within 2km
23. **Hot Ping Notifications** — Push notification when ping enters top 10 hot pings

#### Safety & Compliance (4 features)
24. **User Blocking** — Block user → hide their pings/messages, prevent chat interaction
25. **Account Deletion (GDPR)** — Cloud Function: cascading delete of user data
26. **Email Verification** — Firebase Auth email verification flow (required before creating first ping)
27. **Spam Detection** — Rate limiting enforcement (error messages, temporary cooldown UI)

#### Settings & Preferences (3 features)
28. **Notification Preferences** — Toggle nearby/hot ping notifications
29. **Privacy Settings** — Hide profile from non-chat participants
30. **Blocked Users Management** — View and unblock users

**Technical Deliverables:**
- Cloud Function: `moderateImage` (Storage trigger, Vision API integration)
- Cloud Function: `sendNearbyNotification` (Firestore trigger on ping create, FCM dispatch)
- Cloud Functions: `boostPing`, `submitReport`, `removeContent`, and hot ping notification triggers
- Cloud Function: `deleteAccount` (callable, cascading delete using shared cleanup)
- Admin review workflow (Firebase Console + runbook; React dashboard remains a future enhancement)
- Firestore security rules updated (block rules, report rules, username reservations, server-owned counters/cleanup)
- APNs certificate configured for push notifications

**Success Criteria:**
- Image with nudity auto-flagged and removed within 30 seconds
- Report submitted → appears in admin dashboard
- Account deletion → all user pings/messages removed
- Push notification received when ping created nearby (tested with TestFlight)

---

### Phase 2: Polish & Launch
**Goal:** Production-ready for App Store launch and thesis evaluation

**10 Features:**

#### UX Enhancements (4 features)
31. **Custom Ping Duration** — "Custom" button opens time picker (1-48hr range)
32. **Onboarding Flow** — 3-screen tutorial (map intro, ping creation, chat join)
33. **Empty States** — No pings nearby, no chat messages, no notifications
34. **Error States** — Network errors, location denied, rate limit exceeded

#### Performance & Analytics (3 features)
35. **Performance Optimization** — Image caching, pagination for chat messages (50 msgs/load)
36. **Firebase Analytics** — Track: ping_created, chat_joined, boost_used, session_duration
37. **Crash Reporting** — Firebase Crashlytics integration

#### Launch Prep (3 features)
38. **App Icon & Splash Screen** — Designed in Figma, exported to Xcode asset catalog
39. **Privacy Policy & Terms** — In-app WebView, hosted on Firebase Hosting
40. **Beta Testing** — TestFlight release to 10 Cluj students (feedback loop)

**Technical Deliverables:**
- App Store Connect submission (screenshots, description, keywords)
- Privacy policy drafted (GDPR-compliant, covers location, chat, analytics)
- TestFlight beta testing period (1 week, 10 users)
- Performance profiling (Instruments: Time Profiler, Allocations)
- App Store review preparation (demo video, reviewer notes)

**Success Criteria:**
- App Store approval (no rejections)
- TestFlight feedback: 4+ star average, no critical UX issues
- Crash-free rate >99%
- 95th percentile cold start time <3 seconds

---

### Out of Scope (v2 Features — Post-Thesis)


- ❌ **Social Login** (Apple Sign-In, Google Sign-In) — Email/password sufficient for MVP
- ❌ **Media Attachments** (photos/videos on pings) — Text-only pings for Phase 0-1
- ❌ **Follow Users** — Discovery via map only, no social graph
- ❌ **Message Reactions** — Core chat functionality enough
- ❌ **Location Sharing in Chat** — Not required for MVP
- ❌ **Custom Map Layers** — Standard MapKit styling sufficient
- ❌ **Discovery Feed** — Map is the primary discovery interface
- ❌ **Multi-City Support** — Cluj-only for thesis scope
- ❌ **Advanced Analytics Dashboard** — Firebase Analytics console sufficient
- ❌ **In-App Purchases** — Boost is free, no monetization in v1

---

## 5. Cost Estimates

### 5.1 Firebase Costs (Monthly)

**Assumptions:**
- 500 registered users
- 20% daily active users (100 DAU)
- 25 pings created/day
- 500 chat messages/day
- 50 image uploads/day (Phase 2+)

| Service | Usage | Cost |
|---------|-------|------|
| **Firestore** | 30K reads/day, 750 writes/day | $0.15/month |
| **Storage** | 500 MB stored, 5 GB egress | $0.10/month |
| **Cloud Functions** | 50K invocations/day | Free tier |
| **Authentication** | 500 MAU | Free tier |
| **Cloud Messaging** | 3K notifications/day | Free |
| **Hosting** (admin dashboard) | 1 GB bandwidth | Free tier |
| **Total** | | **~$0.25/month** |

**At 5,000 users (post-launch scale):** ~$25-40/month depending on chat activity.

**Firebase Free Tier Coverage:**
- 50K Firestore reads/day (covers MVP easily)
- 20K Firestore writes/day (covers MVP + Phase 1)
- 1 GB Storage (covers 5,000 profile pictures)
- 10 GB Hosting bandwidth

**Verdict:** Firebase costs are negligible for thesis scope. Even at 5K users, monthly cost <$50.

### 5.2 Google Cloud Vision API Costs

**Assumptions (Phase 2+):**
- 50 image uploads/day = 1,500/month

| Tier | Cost |
|------|------|
| First 1,000 images/month | Free |
| Next 500 images | $0.75 |
| **Total** | **$0.75/month** |

**At 5,000 users (250 images/day = 7,500/month):** ~$10/month.

**Verdict:** Vision API costs are minimal. Budget <$15/month even at scale.

### 5.3 Total Infrastructure Cost

| Phase | Monthly Cost |
|-------|--------------|
| **Phase 0 (MVP)** | $0 (free tier) |
| **Phase 1 (Launch)** | $1-5 (minimal usage) |
| **Post-Launch (1K users)** | $5-10 |
| **Scale (5K users)** | $30-50 |

**Thesis Budget:** Estimated **<$20 total** for 3-month development + 1-month launch period.

---

## 6. Success Metrics (Thesis Evaluation)

### 6.1 Quantitative Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Registered Users** | 100+ | Firebase Auth user count |
| **Pings Created** | 50+ in Week 1 | Firestore `pings` collection count |
| **Chat Participation Rate** | >40% | (users who joined chat) / (users who viewed ping) |
| **Session Duration** | >5 minutes | Firebase Analytics average session duration |
| **Weekly Retention** | >30% | Week 2 active users / Week 1 active users |

### 6.2 Qualitative Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Social Connection** | 3+ users report "met someone new" | Post-launch survey (Google Form) |
| **UX Feedback** | 4+ star average | TestFlight feedback, App Store reviews |
| **Feature Requests** | Identify top 3 requested features | Survey open-ended question |

### 6.3 Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Crash-Free Rate** | >99% | Firebase Crashlytics |
| **Response Time (p95)** | <2 seconds | Firebase Performance Monitoring |
| **Offline Functionality** | 100% (read cached data) | Manual testing checklist |
| **Zero Critical Bugs** | 0 bugs | Production monitoring |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.1 | May 6, 2026 | Robert Leustean + Codex | Updated for server-authoritative ping cleanup, boosts, chat participants, reports, username reservations, and hardened Firestore rules |
| 1.0 | March 28, 2026 | Robert Leustean | Initial specification (MVP, Phase 1-2, tech stack finalized) |

---

**End of Specification**

For questions or clarifications, contact: leustean.robertgeorge@gmail.com
