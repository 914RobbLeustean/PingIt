# Backend / Firebase Deploy Reference

Quick "if you touched **X**, run **Y**" guide for the Firebase backend. Keep this
current whenever deploy steps change. Project: **`pingit-dev`**.

> **asdf / Node version note (this repo):** the `firebase` and `npm`/`node`
> commands need Node 24.11.1. If you hit `No version is set for command firebase`
> or an asdf error, prefix the command (or export it for the shell session):
> ```bash
> export ASDF_NODEJS_VERSION=24.11.1
> ```
> The `firebase` CLI is already authenticated on the dev machine.

> **Deploys are outward-facing.** Rules changes take effect immediately and can
> lock out the installed app. When a rule depends on a client change (e.g.
> "members-only chat reads" needs the app to join before reading), ship the rule
> in lockstep with the app build that satisfies it.

---

## What to run when you touch…

| You changed… | File(s) | Run |
| --- | --- | --- |
| **Firestore security rules** | `firestore.rules` | `firebase deploy --only firestore:rules --project pingit-dev` |
| **Firestore indexes** | `firestore.indexes.json` | `firebase deploy --only firestore:indexes --project pingit-dev` |
| **Cloud Storage rules** | `storage.rules` | `firebase deploy --only storage --project pingit-dev` |
| **Cloud Functions** (TS) | `functions/src/**` | build first, then deploy (see below) |
| **Deep-link web fallback** | `public/**` | `firebase deploy --only hosting --project pingit-dev` |

### Cloud Functions (always build before deploy)

```bash
npm --prefix functions run build      # compiles TypeScript → functions/lib (required)
firebase deploy --only functions --project pingit-dev
```

Combined rules + functions deploy (matches the project convention for
server-authoritative changes):

```bash
npm --prefix functions run build
firebase deploy --only functions,firestore:rules --project pingit-dev
```

---

## Before you write a new query or rule

- **Composite index check:** any Firestore query that combines multiple
  `whereField` clauses, or a `whereField` with `order(by:)` on a *different*
  field, needs a composite index. Missing indexes fail at **runtime** with
  `FAILED_PRECONDITION` (not at compile time). Add it to `firestore.indexes.json`
  and deploy indexes, or follow the auto-create URL printed in the error / Firebase
  console → Firestore → Indexes.

- **Dry-run a rules change** before the real deploy (compiles only, doesn't
  release):
  ```bash
  firebase deploy --only firestore:rules --project pingit-dev --dry-run
  ```

- **Server-authoritative writes:** the client must never directly own destructive
  writes or shared counters. These go through Cloud Functions, and rules + the
  function must change together:
  - Ping deletion → `deletePing`
  - Boost creation / `pings.boostCount` → `boostPing`
  - Chat join/leave + participant counters → `joinChat` / `leaveChat`
  - Report creation / duplicate prevention → `submitReport`
  - Username availability → `usernames/{normalizedUsername}` reservation docs

---

## Gotchas

- **New callable returns `UNAUTHENTICATED`:** brand-new callable functions
  occasionally deploy without the public invoker binding. Fix:
  ```bash
  gcloud functions add-invoker-policy-binding <name> \
    --region=europe-west3 --member=allUsers
  ```
- **Functions region:** callables/triggers are deployed to `europe-west3`.
- **Never commit secrets:** `functions/.env.pingit-dev` and
  `PingIt/GoogleService-Info.plist` are gitignored — keep them out of commits.
- **Admin SDK bypasses rules:** Cloud Functions using the Admin SDK (e.g.
  `moderateImage` reading Storage) are not subject to Firestore/Storage security
  rules. Don't rely on rules to constrain server-side code.

---

## After deploying, also update

- `CHANGELOG.md` (top-level) and the relevant `bug-fixing/<branch>/CHANGELOG.md`.
- `docs/FIREBASE.md` (if it exists) — composite index table for new indexes.
- `ARCHITECTURE.md` — if data flows / services changed.
- `project_status.md` — milestone tracker, if a feature completed.
