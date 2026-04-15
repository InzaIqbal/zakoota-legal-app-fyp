# Getting Started with Enhanced Consultation Model

## 🎯 Getting Started Guide

This guide will help you adopt the enhanced consultation model features in your code.

## 📦 Step 1: Review What Was Added

The consultation model has been enhanced with:
- ✅ Complete description and purpose fields
- ✅ Duration and meeting details management
- ✅ Counter-proposal negotiation system
- ✅ Comprehensive status tracking
- ✅ Timestamps for all state changes
- ✅ Utility functions for common operations

**No existing code needs to change!** These are additive enhancements.

## 🚀 Step 2: Use Immediately (No UI Changes Needed)

You can start using new features right now with your existing UI:

### Add Required Imports
```dart
// Add to your files
import 'package:your_app/features/cases/models/consultation_enums.dart';
import 'package:your_app/features/cases/services/consultation_utils.dart';
```

### Create Better Consultations
```dart
// Old way (still works)
final consultation = ConsultationModel(
  id: id,
  caseId: caseId,
  requesterId: userId,
  targetId: targetId,
  type: 'video',
  status: 'pending',
  scheduledAt: date,
  createdAt: DateTime.now(),
);

// New way (with all details)
final consultation = ConsultationModel(
  id: id,
  caseId: caseId,
  requesterId: userId,
  targetId: targetId,
  type: 'video',
  description: 'Discuss case strategy',      // NEW
  durationMinutes: 60,                        // NEW
  meetingLink: 'https://zoom.us/j/12345',   // NEW
  meetingPlatform: 'zoom',                   // NEW
  notes: 'Please have documents ready',      // NEW
  status: 'pending',
  scheduledAt: date,
  createdAt: DateTime.now(),
);

await ConsultationService().requestConsultation(consultation);
```

### Use Helper Functions
```dart
// Format dates nicely
final formatted = ConsultationUtils.formatDateTime(
  consultation.scheduledAt
); // "Mar 25, 2024 • 02:00 PM"

// Get remaining time text
final timeLeft = ConsultationUtils.getRemainingDaysText(
  consultation.scheduledAt
); // "In 3 days", "Tomorrow", etc.

// Check permissions
if (ConsultationUtils.canAccept(consultation, userId)) {
  // Show accept button
}

// Format duration
final duration = ConsultationUtils.getDurationText(90); // "1h 30m"
```

## 📝 Step 3: Enhance Consultation Requests (Optional)

**If you want to improve the request form:**

Replace your current request sheet with the new one:

```dart
// Old way
showModalBottomSheet(
  context: context,
  builder: (context) => _RequestConsultationSheet(
    caseId: caseId,
    targetId: targetId,
  ),
);

// New way (with all features)
import 'package:your_app/features/cases/presentation/widgets/advanced_consultation_request_sheet.dart';

showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => AdvancedConsultationRequestSheet(
    caseId: caseId,
    targetId: targetId,
    caseTitle: 'Case: Contract Dispute',
  ),
);
```

**The new sheet includes:**
- ✅ Description/purpose field
- ✅ Duration slider (15-240 minutes)
- ✅ Conditional meeting details based on type
- ✅ Additional notes field
- ✅ Comprehensive validation

## 🎨 Step 4: Display Consultations with Full Features (Optional)

Replace consultation cards with enhanced versions:

```dart
// Old way
_buildConsultationCard(consultation)

// New way
import 'package:your_app/features/cases/presentation/widgets/enhanced_consultation_card.dart';

EnhancedConsultationCard(
  consultation: consultation,
  isClient: true,
  currentUserId: userId,
  onRefresh: () => setState(() {}),
)
```

**The new card shows:**
- ✅ Type with appropriate icon
- ✅ Description of consultation
- ✅ Duration and platform
- ✅ Counter-proposals with action buttons
- ✅ Time remaining / past due status
- ✅ Context-aware action buttons
- ✅ Notes and completion details

## 🔄 Step 5: Use Counter-Proposals (New Feature)

Enable date/time negotiation:

```dart
final service = ConsultationService();

// User proposes alternative time
final counterProposal = CounterProposal(
  proposedBy: userId,
  proposedDate: DateTime(2024, 3, 26, 15, 0),
  proposedType: 'video',
  proposedMeetingLink: 'https://meet.google.com/...',
  reason: 'Original time conflicts with court date',
  createdAt: DateTime.now(),
);

await service.addCounterProposal(
  caseId,
  consultationId,
  counterProposal,
);

// Later, accept the proposal
await service.acceptCounterProposal(
  caseId,
  consultationId,
  0, // proposal index
);

// Or reject it
await service.rejectCounterProposal(
  caseId,
  consultationId,
  0,
);
```

## 📊 Step 6: Advanced Queries

Use new querying methods:

```dart
final service = ConsultationService();

// Get pending consultations for current user
final awaiting = service.getPendingConsultationsForUser(userId);

// Get upcoming accepted consultations
final upcoming = service.getUpcomingConsultationsForUser(userId);

// Get consultation statistics
final stats = await service.getConsultationStats(caseId);
print(stats); // {total: 10, pending: 2, accepted: 5, ...}

// Search with filters
final results = await service.searchConsultations(
  caseId: caseId,
  status: 'accepted',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
);
```

## 🎯 Step 7: Use in Your Dashboard

Example of using in a lawyer's dashboard:

```dart
class LawyerConsultationsWidget extends StatelessWidget {
  final String lawyerId;

  const LawyerConsultationsWidget({required this.lawyerId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section 1: Pending (needs action)
        StreamBuilder<List<ConsultationModel>>(
          stream: ConsultationService()
              .getPendingConsultationsForUser(lawyerId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Awaiting Your Response'),
                ...snapshot.data!.map((c) {
                  return EnhancedConsultationCard(
                    consultation: c,
                    isClient: false,
                    currentUserId: lawyerId,
                  );
                }).toList(),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Section 2: Upcoming (accepted)
        StreamBuilder<List<ConsultationModel>>(
          stream: ConsultationService()
              .getUpcomingConsultationsForUser(lawyerId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upcoming Consultations'),
                ...snapshot.data!.map((c) {
                  return EnhancedConsultationCard(
                    consultation: c,
                    isClient: false,
                    currentUserId: lawyerId,
                  );
                }).toList(),
              ],
            );
          },
        ),
      ],
    );
  }
}
```

## 🔐 Step 8: Handle Error Cases

Always include error handling:

```dart
try {
  // Validate input
  if (description.isEmpty) {
    throw 'Description is required';
  }

  // Validate meeting details
  final error = ConsultationUtils.validateMeetingDetails(
    type == 'video' ? ConsultationType.video : ConsultationType.inPerson,
    meetingLink,
    location,
  );
  
  if (error != null) {
    throw error;
  }

  // Proceed with creation
  final consultation = ConsultationModel(...);
  await ConsultationService().requestConsultation(consultation);
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Request sent!')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $e'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## 📅 Step 9: Complete Consultations

After meeting:

```dart
await ConsultationService().completeConsultation(
  caseId,
  consultationId,
  'Discussed case details. Client agreed to strategy. Next steps: gather evidence.',
);
```

## 🆘 Step 10: Cancel When Needed

```dart
await ConsultationService().cancelConsultation(
  caseId,
  consultationId,
  'Client requested postponement',
);
```

## 📋 Migration Checklist

Use this to gradually adopt new features:

### Phase 1: Immediate (No UI Changes)
- [ ] Read CONSULTATION_QUICK_REFERENCE.md
- [ ] Add imports to your files
- [ ] Start creating consultations with all fields
- [ ] Use utility functions for formatting
- [ ] Test new methods in existing UI

### Phase 2: Forms & Input (Update Request Sheet)
- [ ] Replace request sheet with AdvancedConsultationRequestSheet
- [ ] Test form validation
- [ ] Verify all fields save correctly
- [ ] Update success/error messages

### Phase 3: Display (Update Consultation Lists)
- [ ] Replace consultation cards with EnhancedConsultationCard
- [ ] Update any consultation detail views
- [ ] Test action buttons
- [ ] Verify permissions work correctly

### Phase 4: Features (Add Counter-Proposals)
- [ ] Add UI to propose alternatives
- [ ] Add UI to respond to proposals
- [ ] Test full negotiation flow
- [ ] Update notifications

### Phase 5: Advanced Features (Dashboard Integration)
- [ ] Use new query methods
- [ ] Create consultation statistics
- [ ] Add filters and search
- [ ] Integrate with notifications/calendar

## 🐛 Debugging Tips

**If consultations aren't showing:**
```dart
// Check Firestore structure
// Should be: cases/{caseId}/consultations/{consultationId}

// Print to console
final consultations = await service.getConsultation(caseId, id);
print('Consultation: $consultations');
```

**If status update doesn't work:**
```dart
// Make sure status is valid string
// Valid: 'pending', 'accepted', 'rejected', 'cancelled', 'completed', 'no_show'

// Or use enum
await service.updateStatus(
  caseId,
  id,
  ConsultationStatus.accepted.value,
);
```

**If counter-proposal not showing:**
```dart
// Check hasUnresolvedProposal flag
if (consultation.hasUnresolvedProposal) {
  // Show counter-proposals
  for (var proposal in consultation.counterProposals) {
    print('Proposal: ${proposal.proposedDate}');
  }
}
```

## 📞 Common Questions

**Q: Will this break my existing code?**
A: No! All changes are backward compatible. Existing code continues working.

**Q: Do I have to use all new features?**
A: No! Use only what you need. Features are optional.

**Q: Can I use old and new features together?**
A: Yes! Mix old and new as you adopt gradually.

**Q: What if I don't set all new fields?**
A: The model has sensible defaults. Only required fields must be set.

**Q: How do I know what changed?**
A: See CONSULTATION_FILE_STRUCTURE.md for detailed file-by-file changes.

## 🚀 Next Steps

1. **Read** the quick reference (5 min)
2. **Review** one example file (10 min)
3. **Try** creating a consultation with new fields (15 min)
4. **Test** in your app (20 min)
5. **Integrate** widgets one at a time (30 min per widget)

**You're ready to go!** Start small and build up. Enjoy the new features! 🎉

---

**Need help?** Check:
- CONSULTATION_QUICK_REFERENCE.md - Code examples
- CONSULTATION_MODEL_README.md - Detailed docs
- CONSULTATION_IMPLEMENTATION_SUMMARY.md - Overview
- Example widgets - Real implementation
