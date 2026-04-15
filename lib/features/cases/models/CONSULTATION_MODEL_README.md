# Consultation Model Documentation

## Overview

The Consultation Model represents a meeting between a lawyer and a client (or vice versa) within a case. It supports various features including:
- Online (video) and in-person meeting types
- Request and approval workflow
- Counter-proposal negotiations for scheduling conflicts
- Comprehensive meeting details management
- Consultation completion and follow-up notes

## Model Structure

### Core Fields

```dart
- id: String - Unique consultation identifier
- caseId: String - Associated case ID
- requesterId: String - User ID who requested the consultation
- targetId: String - User ID who needs to approve
- createdAt: DateTime - When the consultation was requested
- updatedAt: DateTime - Last update timestamp
```

### Consultation Details

```dart
- type: String - 'video' or 'in_person'
- description: String - Purpose/topic of consultation
- durationMinutes: int - Expected duration
- status: String - Current status (see Status section)
- scheduledAt: DateTime - Scheduled date and time
```

### Meeting Information

```dart
// For video consultations
- meetingLink: String? - Video call URL (Zoom, Google Meet, etc.)
- meetingPlatform: String? - Platform name ('zoom', 'google_meet', 'teams')

// For in-person consultations
- location: String? - Physical address
```

### Additional Details

```dart
- notes: String? - Additional instructions/details from requester
- attachmentIds: List<String> - References to attached documents
- completionNotes: String? - Notes after consultation is completed
- completedAt: DateTime? - When consultation was actually held
- reminderSentAt: DateTime? - Track if reminder notification was sent
```

### Status Management

```dart
- rejectionReason: String? - Why consultation was rejected
- cancellationReason: String? - Why consultation was cancelled
- acceptedAt: DateTime? - When the other party accepted
```

### Counter-Proposals

```dart
- counterProposals: List<CounterProposal> - List of proposed alternatives
- hasUnresolvedProposal: bool - Flag indicating pending counter-proposal
```

## Consultation Status Workflow

### Status Transitions

```
1. pending
   ↓ (by targetId)
   ├→ accepted → completed or no_show
   └→ rejected

2. pending
   ↓ (by anyone)
   → cancelled

3. in_person or video
   ↓ (by anyone)
   → cancelled
```

### Status Descriptions

| Status | Description | Who Can Action | Next Statuses |
|--------|-------------|----------------|---------------|
| pending | Awaiting approval from target user | Target user | accepted, rejected, cancelled |
| accepted | Approved by target user | Both | completed, no_show, cancelled |
| rejected | Declined by target user | - | - |
| cancelled | Cancelled by either party | - | - |
| completed | Successfully held | Both | - |
| no_show | Scheduled but no one participated | - | - |

## Counter-Proposal Mechanism

When the target user wants to suggest a different time, date, type, or location:

1. Target user creates a `CounterProposal` with:
   - `proposedDate`: Alternative date/time
   - `proposedType`: Alternative type (video/in-person)
   - `proposedLocation` or `proposedMeetingLink`: Alternative meeting details
   - `reason`: Why they're proposing an alternative

2. Consultation's `hasUnresolvedProposal` flag is set to `true`

3. Requester can:
   - `acceptCounterProposal()` - Updates consultation with new details
   - `rejectCounterProposal()` - Removes counter-proposal from list

4. Once any proposal is accepted:
   - Status changes to `accepted`
   - `hasUnresolvedProposal` becomes `false`
   - All proposal details update the main consultation record

## Usage Examples

### Creating a Consultation Request

```dart
final consultation = ConsultationModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  caseId: 'case_123',
  requesterId: currentUserId,
  targetId: lawyerId,
  type: 'video',
  description: 'Discuss case strategy and next steps',
  durationMinutes: 60,
  status: 'pending',
  scheduledAt: DateTime(2024, 3, 25, 14, 0),
  createdAt: DateTime.now(),
  notes: 'Please have case documents ready',
  meetingLink: 'https://zoom.us/j/...',
  meetingPlatform: 'zoom',
);

await ConsultationService().requestConsultation(consultation);
```

### Accepting a Consultation

```dart
await ConsultationService().acceptConsultation(
  caseId,
  consultationId,
);
```

### Proposing an Alternative Time

```dart
final counterProposal = CounterProposal(
  proposedBy: currentUserId,
  proposedDate: DateTime(2024, 3, 26, 15, 0),
  proposedType: 'video',
  proposedMeetingLink: 'https://meet.google.com/...',
  reason: 'Original time conflicts with court appearance',
  createdAt: DateTime.now(),
);

await ConsultationService().addCounterProposal(
  caseId,
  consultationId,
  counterProposal,
);
```

### Accepting a Counter-Proposal

```dart
await ConsultationService().acceptCounterProposal(
  caseId,
  consultationId,
  proposalIndex, // Index in counterProposals list
);
```

## Available Methods in ConsultationService

### CRUD Operations
- `requestConsultation(ConsultationModel)` - Create new consultation
- `getConsultation(caseId, consultationId)` - Fetch single consultation
- `updateConsultation(ConsultationModel)` - Update entire consultation
- `deleteConsultation(caseId, consultationId)` - Delete consultation

### Status Management
- `acceptConsultation(caseId, consultationId)`
- `rejectConsultation(caseId, consultationId, reason)`
- `cancelConsultation(caseId, consultationId, reason)`
- `completeConsultation(caseId, consultationId, notes)`
- `markAsNoShow(caseId, consultationId)`
- `updateStatus(caseId, consultationId, status)` - Generic status update

### Counter-Proposals
- `addCounterProposal(caseId, consultationId, counterProposal)`
- `acceptCounterProposal(caseId, consultationId, proposalIndex)`
- `rejectCounterProposal(caseId, consultationId, proposalIndex)`

### Meeting Details
- `updateMeetingLink(caseId, consultationId, link, platform)`
- `updateLocation(caseId, consultationId, location)`
- `addAttachments(caseId, consultationId, attachmentIds)`
- `removeAttachment(caseId, consultationId, attachmentId)`

### Querying
- `getConsultationsForCase(caseId)` - Stream all consultations for case
- `getPendingConsultationsForCase(caseId)` - Stream pending only
- `getAcceptedConsultationsForCase(caseId)` - Stream accepted only
- `getConsultationsForUser(userId)` - Stream all consultations for user
- `getPendingConsultationsForUser(userId)` - Consultations awaiting user's response
- `getUpcomingConsultationsForUser(userId)` - Future accepted consultations
- `getCompletedConsultationsForUser(userId)` - Past completed consultations
- `searchConsultations(caseId, status, startDate, endDate)`
- `getConsultationStats(caseId)` - Get count of consultations by status

## Consultation Enums

### ConsultationStatus
- pending
- accepted
- rejected
- cancelled
- completed
- noShow

### ConsultationType
- video
- inPerson

### MeetingPlatform
- zoom
- googleMeet
- teams
- other

All enums have extensions providing:
- `value` - String value for storage
- `displayName` - User-friendly display text
- `color` - UI color representation
- `icon` - Icon representation (where applicable)

## Utility Functions

See `consultation_utils.dart` for helper functions:

- `formatDateTime(dateTime)` - Format date and time for display
- `formatDate(date)` - Format date only
- `formatTime(dateTime)` - Format time only
- `getRemainingDaysText(scheduledAt)` - Get "In X days" text
- `isUpcoming(consultation)` - Check if consultation is upcoming
- `isPastDue(consultation)` - Check if past scheduled time
- `canCancel(consultation)` - Check if can be cancelled
- `canAccept(consultation, userId)` - Check if user can accept
- `canReject(consultation, userId)` - Check if user can reject
- `canProposeCounterTime(consultation, userId)` - Check if can propose alternative
- `canMarkAsCompleted(consultation)` - Check if can be marked done
- `validateMeetingDetails(type, link, location)` - Validate meeting info
- `getSummaryText(consultation)` - Get formatted summary
- `getDurationText(minutes)` - Format duration (e.g., "1h 30m")
- `needsAttention(consultation, userId)` - Check if needs immediate action

## Firestore Collection Structure

```
cases/{caseId}/consultations/{consultationId}
{
  id: string,
  caseId: string,
  requesterId: string,
  targetId: string,
  type: 'video' | 'in_person',
  description: string,
  durationMinutes: number,
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled' | 'completed' | 'no_show',
  scheduledAt: timestamp,
  createdAt: timestamp,
  updatedAt: timestamp,
  acceptedAt: timestamp,
  completedAt: timestamp,
  reminderSentAt: timestamp,
  location: string (optional),
  meetingLink: string (optional),
  meetingPlatform: string (optional),
  notes: string (optional),
  rejectionReason: string (optional),
  cancellationReason: string (optional),
  completionNotes: string (optional),
  attachmentIds: string[],
  counterProposals: CounterProposal[],
  hasUnresolvedProposal: boolean
}

CounterProposal structure:
{
  proposedBy: string,
  proposedDate: timestamp,
  proposedType: 'video' | 'in_person',
  proposedLocation: string (optional),
  proposedMeetingLink: string (optional),
  reason: string,
  createdAt: timestamp,
  isAccepted: boolean
}
```

## Best Practices

1. **Always set type and duration** before requesting consultation
2. **Validate meeting details** before accepting (use `validateMeetingDetails()`)
3. **Use the service methods** rather than direct Firestore calls
4. **Check user permissions** using `canAccept()`, `canReject()`, etc.
5. **Add timestamps** for auditing (updatedAt, acceptedAt, etc.)
6. **Include descriptive notes** for context
7. **Handle counter-proposals** gracefully with UI feedback
8. **Track completions** with `completionNotes` for future reference
9. **Set reminders** by updating `reminderSentAt` timestamp
10. **Handle no-shows** appropriately for accountability

## Future Enhancements

- Recurring consultations
- Timezone awareness
- Automatic reminder system
- Integration with calendar services
- Video recording capabilities
- Consultation rating/feedback
- Payment/billing integration
- Consultation templates for common case types
