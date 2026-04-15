import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../cases/models/case_model.dart';
import '../../dashboard/models/recent_update_model.dart';
import '../../dashboard/services/recent_update_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';
import '../services/ad_booking_service.dart';
import '../services/lawyer_ad_service.dart';

class SetupWorkspaceScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? formData;

  const SetupWorkspaceScreen({
    super.key,
    required this.bookingId,
    this.formData,
  });

  @override
  State<SetupWorkspaceScreen> createState() => _SetupWorkspaceScreenState();
}

class _SetupWorkspaceScreenState extends State<SetupWorkspaceScreen> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _cityController = TextEditingController();
  final _milestonesController = TextEditingController();

  final AdBookingService _bookingService = AdBookingService();
  final LawyerAdService _adService = LawyerAdService();
  final NotificationService _notificationService = NotificationService();
  final RecentUpdateService _recentUpdateService = RecentUpdateService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _prefillFormIfDataProvided();
  }

  void _prefillFormIfDataProvided() {
    if (widget.formData != null) {
      _titleController.text = widget.formData?['title'] ?? '';
      _detailsController.text = widget.formData?['details'] ?? '';
      _cityController.text = widget.formData?['city'] ?? '';
      _milestonesController.text = widget.formData?['milestones'] ?? '';

      // Auto-submit if all required fields are provided
      if (_titleController.text.isNotEmpty &&
          _detailsController.text.isNotEmpty &&
          _cityController.text.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _createWorkspace();
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _cityController.dispose();
    _milestonesController.dispose();
    super.dispose();
  }

  Future<void> _createWorkspace() async {
    if (_titleController.text.trim().isEmpty || _detailsController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required details'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login first');

      final booking = await _bookingService.getBookingById(widget.bookingId);
      if (booking == null) throw Exception('Booking not found');

      final ad = await _adService.getAdById(booking.adId);
      if (ad == null) throw Exception('Ad not found');

      final caseRef = FirebaseFirestore.instance.collection('cases').doc();
      final now = DateTime.now();

      final caseModel = CaseModel(
        caseId: caseRef.id,
        clientId: user.uid,
        title: _titleController.text.trim(),
        description: '${_detailsController.text.trim()}\n\nMilestones:\n${_milestonesController.text.trim()}',
        category: ad.category,
        city: _cityController.text.trim(),
        budgetMin: ad.price,
        budgetMax: ad.price,
        meetingPreference: ad.locationMode == 'Remote' ? 'virtual' : 'in_person',
        attachments: const [],
        status: 'active',
        proposalCount: 0,
        createdAt: now,
        acceptedLawyerId: ad.lawyerId,
        agreedBudget: ad.price,
        budgetSource: 'lawyer',
      );

      await caseRef.set(caseModel.toMap());
      await _bookingService.markSetupCompleted(widget.bookingId, caseRef.id);

      await _notificationService.createBatchNotifications([
        AppNotification(
          id: '',
          userId: booking.clientId,
          actorId: booking.clientId,
          type: NotificationType.caseAssigned,
          title: 'Workspace created',
          message: 'Your ad booking workspace is now active.',
          referenceType: 'case',
          referenceId: caseRef.id,
          payload: {'caseId': caseRef.id, 'bookingId': booking.id},
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '',
          userId: booking.lawyerId,
          actorId: booking.clientId,
          type: NotificationType.caseAssigned,
          title: 'Client completed setup',
          message: 'A new active workspace has been created from your ad.',
          referenceType: 'case',
          referenceId: caseRef.id,
          payload: {'caseId': caseRef.id, 'bookingId': booking.id},
          createdAt: DateTime.now(),
        ),
      ]);

      await _recentUpdateService.addRecentUpdate(
        RecentUpdate(
          id: '',
          userId: booking.clientId,
          type: UpdateType.casePosted,
          title: 'Workspace ready',
          message: 'You can now collaborate in a clean workspace.',
          relatedId: caseRef.id,
          timestamp: DateTime.now(),
        ),
      );

      await _recentUpdateService.addRecentUpdate(
        RecentUpdate(
          id: '',
          userId: booking.lawyerId,
          type: UpdateType.proposalAccepted,
          title: 'New ad workspace started',
          message: 'Client setup is complete and workspace is active.',
          relatedId: caseRef.id,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;
      context.go(
        '/case-workspace?caseId=${caseRef.id}&isClient=true',
        extra: {
          'caseModel': caseModel,
          'isClient': true,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Workspace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/client-home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const Text('Complete setup details before entering workspace', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Workspace Title'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Case Details / Goals'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _milestonesController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Milestones / Tasks'),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _createWorkspace,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Workspace'),
            ),
          ),
        ],
      ),
    );
  }
}
