# Admin Moderation Runbook

## Overview

Content moderation for PingIt uses a combination of automated systems and manual review via Firebase Console. This document covers the manual review workflow.

## Automated Moderation

These run without admin intervention:

1. **Image moderation** (`moderateImage` Cloud Function): Scans all uploaded images via Vision API SafeSearch. Auto-removes VERY_LIKELY inappropriate content. Flags LIKELY content for manual review.

2. **Text moderation** (client-side): Blocks profanity/hate speech before submission. Word list at `PingIt/Resources/moderation_wordlist.txt`.

3. **Rate limiting** (client-side): Prevents spam (5 pings/hour, 6 messages/10 seconds). Server-side spam rate limiting is still planned.

4. **Report intake** (`submitReport` Cloud Function): Creates deterministic report documents and rejects duplicates before they reach the review queue.

## Manual Review Workflow

### Step 1: Check Pending Reports

Go to Firebase Console -> Firestore -> `reports` collection.

Filter: `status == "pending"`, sort by `createdAt` descending.

Report document IDs are deterministic:

```text
{reporterId}_{targetId}
```

If a user reports the same ping/message twice, the callable returns `already-exists`; the app shows "You have already reported this content." and no new report document is created.

Each report contains:
- `reporterId`: Who reported it
- `targetType`: "ping" or "message"
- `targetId`: Document ID of the reported content
- `targetOwnerId`: User who created the reported content
- `reason`: Spam / Harassment / Inappropriate Content / Other
- `details`: Optional additional context

### Step 2: Review the Content

Based on `targetType`:
- **Ping**: Go to `pings` collection -> find document by `targetId` -> read `text` field
- **Message**: Go to `chatMessages` collection -> find by `targetId` -> read `text` field

### Step 3: Take Action

**Option A: Dismiss the report**
- Update the report document: `status` -> "dismissed", add `reviewedAt` timestamp

**Option B: Remove the content**
- Use a deployed admin client or callable invocation to call the `removeContent` function. The legacy `firebase functions:shell` flow is unreliable for v2 callables, so prefer testing deployed callables from an authenticated admin context.

```bash
# Deploy latest callable implementation and rules first
npm --prefix functions run build
firebase deploy --only functions,firestore:rules --project pingit-dev
```

- Update the report: `status` -> "reviewed", add `reviewedAt`

### Step 4: Verify

- Check `moderationActions` collection for the audit trail
- If content was removed, verify in the respective collection
- For ping removals, verify the ping `status` is `removed` and related chat/messages/participants/boosts were cleaned by shared backend cleanup

## SLA Targets

| Priority | Response Time | Criteria |
|----------|--------------|----------|
| Critical | <2 hours | Illegal content, safety threats |
| High | <24 hours | Harassment, explicit content |
| Standard | <72 hours | Spam, minor violations |

## Moderation Audit Trail

All actions are logged in the `moderationActions` collection:
- `moderatorId`: Admin who took action (or "system" for automated)
- `targetType`: What was moderated
- `targetId`: Document/file path
- `action`: "auto_removed", "emergency_removal", etc.
- `reason`: Human-readable explanation
- `timestamp`: When the action was taken

## Updating the Word List

The text moderation word list is bundled in the iOS app at `PingIt/Resources/moderation_wordlist.txt`. To update:

1. Edit the file (one word per line)
2. Build and release a new version
3. Future improvement: Move to Firebase Remote Config for real-time updates without app release
