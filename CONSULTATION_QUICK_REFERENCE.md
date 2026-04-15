# Consultation Model - Quick Reference Guide

## 🚀 Quick Start

### Import What You Need
```dart
import 'features/cases/models/consultation_model.dart';
import 'features/cases/models/consultation_enums.dart';
import 'features/cases/services/consultation_service.dart';
import 'features/cases/services/consultation_utils.dart';
```

## 📋 Create Consultation Request

```dart
final consultation = ConsultationModel(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  caseId: 'case_123',
  requesterId: currentUserId,
  targetId: lawyerId,
  type: 'video', // or 'in_person'
  description: 'Discuss case strategy',
  durationMinutes: 60,
  status: 'pending',
  scheduledAt: DateTime(2024, 3, 25, 14, 0),
  createdAt: DateTime.now(),
  meetingLink: 'https://zoom.us/...',
  meetingPlatform: 'zoom',
  notes: 'Bring case documents',
);

await ConsultationService().requestConsultation(consultation);
```

## ✅ Accept/Reject Consultation

```dart
// Accept
await ConsultationService().acceptConsultation(caseId, consultationId);

// Reject with reason
await ConsultationService().rejectConsultation(
  caseId,
  consultationId,
  'Scheduling conflict',
);
```

## 🔄 Counter-Proposal Workflow

```dart
// Step 1: Propose alternative
final proposal = CounterProposal(
  proposedBy: userId,
  proposedDate: DateTime(2024, 3, 26, 15, 0),
  proposedType: 'video',
  proposedMeetingLink: 'https://meet.google.com/...',
  reason: 'Original time conflict',
  createdAt: DateTime.now(),
);

await ConsultationService().addCounterProposal(
  caseId,
  consultationId,
  proposal,
);

// Step 2: Accept or reject counter-proposal
// Accept:
await ConsultationService().acceptCounterProposal(
  caseId,
  consultationId,
  0, // index in counterProposals list
);

// Reject:
await ConsultationService().rejectCounterProposal(
  caseId,
  consultationId,
  0,
);
```

## 📅 Query Consultations

```dart
// Get all consultations for a case
final service = ConsultationService();

// Streaming
final allConsultations = service.getConsultationsForCase(caseId);
final pending = service.getPendingConsultationsForCase(caseId);
final accepted = service.getAcceptedConsultationsForCase(caseId);

// For user
final userConsultations = service.getConsultationsForUser(userId);
final awaitingResponse = service.getPendingConsultationsForUser(userId);
final upcoming = service.getUpcomingConsultationsForUser(userId);
final completed = service.getCompletedConsultationsForUser(userId);

// Search with filters
final results = await service.searchConsultations(
  caseId: caseId,
  status: 'accepted',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
);

// Statistics
final stats = await service.getConsultationStats(caseId);
print(stats); // {total: 10, pending: 2, accepted: 5, ...}
```

## 🎯 Status Management

```dart
// Complete consultation with notes
await ConsultationService().completeConsultation(
  caseId,
  consultationId,
  'Discussion was productive. Agreed on next steps.',
);

// Mark as no-show
await ConsultationService().markAsNoShow(caseId, consultationId);

// Cancel with reason
await ConsultationService().cancelConsultation(
  caseId,
  consultationId,
  'Client unable to attend',
);
```

## 🔗 Meeting Details

```dart
// Update video meeting link
await ConsultationService().updateMeetingLink(
  caseId,
  consultationId,
  'https://zoom.us/j/12345',
  'zoom',
);

// Update in-person location
await ConsultationService().updateLocation(
  caseId,
  consultationId,
  '123 Main St, Law Office Building',
);

// Add attachments
await ConsultationService().addAttachments(
  caseId,
  consultationId,
  ['file_id_1', 'file_id_2'],
);

// Remove attachment
await ConsultationService().removeAttachment(
  caseId,
  consultationId,
  'file_id_1',
);
```

## 🛠️ Utility Functions

```dart
// Formatting
ConsultationUtils.formatDateTime(consultation.scheduledAt);
ConsultationUtils.formatDate(consultation.scheduledAt);
ConsultationUtils.formatTime(consultation.scheduledAt);
ConsultationUtils.getRemainingDaysText(consultation.scheduledAt);
ConsultationUtils.getDurationText(60); // "1h"

// Validation
final error = ConsultationUtils.validateMeetingDetails(
  ConsultationType.video,
  'https://zoom.us/...',
  null,
);

// Checks
ConsultationUtils.isUpcoming(consultation);
ConsultationUtils.isPastDue(consultation);
ConsultationUtils.canAccept(consultation, userId);
ConsultationUtils.canReject(consultation, userId);
ConsultationUtils.canCancel(consultation);
ConsultationUtils.canProposeCounterTime(consultation, userId);
ConsultationUtils.canMarkAsCompleted(consultation);
ConsultationUtils.needsAttention(consultation, userId);

// UI Text
ConsultationUtils.getNextActionText(consultation, userId);
ConsultationUtils.getSummaryText(consultation);
```

## 🎨 Use in UI

### Using StreamBuilder
```dart
StreamBuilder<List<ConsultationModel>>(
  stream: ConsultationService().getConsultationsForCase(caseId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          return EnhancedConsultationCard(
            consultation: snapshot.data![index],
            isClient: true,
            currentUserId: userId,
            onRefresh: () => setState(() {}),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Show Request Sheet
```dart
// Using the provided widget
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => AdvancedConsultationRequestSheet(
    caseId: caseId,
    targetId: lawyerId,
    caseTitle: 'Contract Dispute with ABC Corp',
  ),
);
```

## 📊 Status Flow

```
┌─────────┐
│ pending │
└────┬────┘
     ├──→ accepted → completed
     │              ↘ no_show
     ├──→ rejected
     └──→ cancelled
```

## 🔐 Permission Checks

```dart
// Check what current user can do
if (ConsultationUtils.canAccept(consultation, userId)) {
  // Show Accept button
}

if (ConsultationUtils.canReject(consultation, userId)) {
  // Show Reject button
}

if (ConsultationUtils.canProposeCounterTime(consultation, userId)) {
  // Show Propose Alternative button
}

if (ConsultationUtils.canCancelConsultation(consultation)) {
  // Show Cancel button
}
```

## 💾 Working with Timestamps

```dart
// All timestamps are automatic:
consultation.createdAt;      // When request was made
consultation.acceptedAt;     // When accepted (if accepted)
consultation.completedAt;    // When marked complete (if done)
consultation.reminderSentAt; // When reminder was sent (if applicable)
consultation.updatedAt;      // Last modification time

// Coming from Firestore, these are converted to DateTime
// Going to Firestore, they're converted to Timestamp
```

## 🏗️ Model Structure

```dart
ConsultationModel(
  // Identifiers
  id, caseId, requesterId, targetId,
  
  // Basic Details
  type,        // 'video' or 'in_person'
  description, // topic/purpose
  duration,    // in minutes
  
  // Meeting Info
  meetingLink,      // for video
  meetingPlatform,  // zoom, google_meet, teams
  location,         // for in-person
  
  // Status
  status,              // pending, accepted, rejected, etc.
  rejectionReason,     // if rejected
  cancellationReason,  // if cancelled
  
  // Negotiation
  counterProposals,        // list of alternatives
  hasUnresolvedProposal,   // flag for UI
  
  // Additional
  notes,           // special instructions
  attachmentIds,   // document references
  completionNotes, // feedback after completion
  
  // Timestamps
  createdAt, acceptedAt, completedAt,
  updatedAt, reminderSentAt
)
```

## 🔗 Related Collections

```
Firestore Structure:
cases/{caseId}/
  └─ consultations/{id}/
     ├─ all consultation data
     └─ counterProposals (embedded list)
```

## 📚 Key Enums

```dart
// ConsultationStatus
pending, accepted, rejected, cancelled, completed, noShow

// ConsultationType  
video, inPerson

// MeetingPlatform
zoom, googleMeet, teams, other

// Access with extensions:
status.displayName  // "Pending"
status.color        // Color value
status.icon         // Icon data
```

## ⚡ Common Patterns

### Pattern 1: Request and Get Response
```dart
// User 1 requests
final consult = ConsultationModel(...);
await service.requestConsultation(consult);

// User 2 sees pending
final pending = service.getPendingConsultationsForUser(user2Id);

// User 2 accepts
await service.acceptConsultation(caseId, consultId);
```

### Pattern 2: Schedule Negotiation
```dart
// User 1 requests time X
final consult = ConsultationModel(scheduledAt: timeX, ...);
await service.requestConsultation(consult);

// User 2 proposes time Y
const proposal = CounterProposal(proposedDate: timeY, ...);
await service.addCounterProposal(caseId, consultId, proposal);

// User 1 accepts time Y
await service.acceptCounterProposal(caseId, consultId, 0);
```

### Pattern 3: Complete Meeting
```dart
// After consultation happens
await service.completeConsultation(
  caseId,
  consultId,
  'Discussed strategy and next steps',
);
```

## 🚫 Common Mistakes to Avoid

```dart
// ❌ Don't forget to set meeting details
type: 'video', // but no meetingLink!

// ✅ Validate before creating
if (type == 'video' && meetingLink.isEmpty) {
  throw Exception('Meeting link required');
}

// ❌ Don't assume timestamps exist
print(consultation.acceptedAt); // might be null!

// ✅ Check for null
if (consultation.acceptedAt != null) {
  print(consultation.acceptedAt);
}

// ❌ Don't query without proper filtering
final all = consultation.all; // Could be thousands!

// ✅ Use status filters
final pending = service.getPendingConsultationsForUser(userId);
```

## 📞 Support Functions

```dart
// Need formatted output?
ConsultationUtils.formatDateTime(date)    // "Mar 25, 2024 • 02:00 PM"
ConsultationUtils.getSummaryText(consult) // "Video • Mar 25, 2024 at..."

// Need to show remaining time?
ConsultationUtils.getRemainingDaysText(date)  // "Tomorrow", "In 3 days"

// Need to update UI?
ConsultationUtils.getNextActionText(consult, userId)  // "Awaiting Your Response"

// Need validation?
ConsultationUtils.needsAttention(consult, userId) // true/false
```

## 📖 Full Documentation

See `lib/features/cases/models/CONSULTATION_MODEL_README.md` for:
- Complete field descriptions
- Detailed method documentation
- Firestore structure
- Best practices
- Future enhancements

---

**Ready to use? Start with a simple request and build from there!** 🎉
