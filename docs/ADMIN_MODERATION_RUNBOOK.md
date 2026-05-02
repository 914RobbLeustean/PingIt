# Admin Moderation Runbook

## Overview

Content moderation for PingIt uses a combination of automated systems and manual review via Firebase Console. This document covers the manual review workflow.

## Automated Moderation

These run without admin intervention:

1. **Image moderation** (`moderateImage` Cloud Function): Scans all uploaded images via Vision API SafeSearch. Auto-removes VERY_LIKELY inappropriate content. Flags LIKELY content for manual review.

2. **Text moderation** (client-side): Blocks profanity/hate speech before submission. Word list at `PingIt/Resources/moderation_wordlist.txt`.

3. **Rate limiting** (client-side + planned server-side): Prevents spam (5 pings/hour, 6 messages/10 seconds).

## Manual Review Workflow

### Step 1: Check Pending Reports

Go to Firebase Console -> Firestore -> `reports` collection.

Filter: `status == "pending"`, sort by `createdAt` descending.

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
- Use the Firebase CLI to call the `removeContent` function:

```bash
# Remove a ping
firebase functions:shell
> removeContent({ targetType: "ping", targetId: "PING_DOC_ID", reason: "Violated community guidelines" })

# Remove a message
> removeContent({ targetType: "message", targetId: "MESSAGE_DOC_ID", reason: "Harassment" })

# Suspend a user (24hr)
> removeContent({ targetType: "user", targetId: "USER_DOC_ID", reason: "Repeated violations" })
```

- Update the report: `status` -> "reviewed", add `reviewedAt`

### Step 4: Verify

- Check `moderationActions` collection for the audit trail
- If content was removed, verify in the respective collection

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
