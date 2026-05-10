import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../dashboard/models/recent_update_model.dart';
import '../../dashboard/services/recent_update_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';
import '../models/lawyer_ad_model.dart';
import '../services/ad_booking_service.dart';
import '../services/lawyer_ad_service.dart';

class BookLawyerAdScreen extends StatefulWidget {
  final String adId;

  const BookLawyerAdScreen({super.key, required this.adId});

  @override
  State<BookLawyerAdScreen> createState() => _BookLawyerAdScreenState();
}

class _BookLawyerAdScreenState extends State<BookLawyerAdScreen> {
  final LawyerAdService _adService = LawyerAdService();
  final AdBookingService _bookingService = AdBookingService();
  final NotificationService _notificationService = NotificationService();
  final RecentUpdateService _recentUpdateService = RecentUpdateService();
  bool _isPaying = false;
  int _currentStep = 0; // 0: ad details, 1: case details form, 2: payment confirmation

  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  final _cityController = TextEditingController();
  final _milestonesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _cityController.dispose();
    _milestonesController.dispose();
    super.dispose();
  }

  Future<void> _bookAd(LawyerAdModel ad) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final balance = (userDoc.data()?['walletBalance'] ?? 0).toDouble();
    if (balance < ad.price) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance. Please add funds to continue.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isPaying = true);
    try {
      final bookingId = await _bookingService.holdAdBookingPayment(
        adId: ad.id,
        lawyerId: ad.lawyerId,
        clientId: user.uid,
        amount: ad.price,
      );

      await _notificationService.createBatchNotifications([
        AppNotification(
          id: '',
          userId: user.uid,
          actorId: ad.lawyerId,
          type: NotificationType.paymentSuccess,
          title: 'Ad booked - payment held',
          message: 'Payment held for ${ad.title}. Complete setup to proceed.',
          referenceType: 'ad_booking',
          referenceId: bookingId,
          payload: {'bookingId': bookingId, 'adId': ad.id},
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: '',
          userId: ad.lawyerId,
          actorId: user.uid,
          type: NotificationType.paymentSuccess,
          title: 'New ad booking awaiting setup',
          message: 'A client booked ${ad.title}. Payment is held in escrow.',
          referenceType: 'ad_booking',
          referenceId: bookingId,
          payload: {'bookingId': bookingId, 'adId': ad.id},
          createdAt: DateTime.now(),
        ),
      ]);

      await _recentUpdateService.addRecentUpdate(
        RecentUpdate(
          id: '',
          userId: user.uid,
          type: UpdateType.paymentAccepted,
          title: 'Ad booking held',
          message: 'Payment held for ${ad.title}. Complete setup to confirm.',
          relatedId: bookingId,
          timestamp: DateTime.now(),
        ),
      );

      await _recentUpdateService.addRecentUpdate(
        RecentUpdate(
          id: '',
          userId: ad.lawyerId,
          type: UpdateType.paymentAccepted,
          title: 'New booking awaiting setup',
          message: '${ad.title} has a new booking with payment held in escrow.',
          relatedId: bookingId,
          timestamp: DateTime.now(),
        ),
      );

      if (!mounted) return;
      // Pass form data to setup-workspace so it can auto-submit
      context.go(
        '/setup-workspace/$bookingId',
        extra: {
          'title': _titleController.text.trim(),
          'details': _detailsController.text.trim(),
          'city': _cityController.text.trim(),
          'milestones': _milestonesController.text.trim(),
        },
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.toLowerCase().contains('insufficient')
                ? 'Insufficient balance. Please add funds to continue.'
                : msg,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Lawyer Ad'),
        leading: _currentStep == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _currentStep = _currentStep - 1);
                },
              ),
      ),
      body: FutureBuilder<LawyerAdModel?>(
        future: _adService.getAdById(widget.adId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ad = snapshot.data;
          if (ad == null) {
            return const Center(child: Text('Ad not found'));
          }

          if (_currentStep == 0) {
            return _buildAdDetailsStep(ad);
          } else if (_currentStep == 1) {
            return _buildCaseDetailsStep(ad);
          } else {
            return _buildPaymentConfirmationStep(ad);
          }
        },
      ),
    );
  }

  Widget _buildAdDetailsStep(LawyerAdModel ad) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ad.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          Text(ad.description, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text('Lawyer: ${ad.lawyerName}'),
          Text('Category: ${ad.category}'),
          Text('Duration: ${ad.duration}'),
          Text('Mode: ${ad.locationMode}'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Charge Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('PKR ${ad.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                setState(() => _currentStep = 1);
              },
              child: const Text('Proceed To Details'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDetailsStep(LawyerAdModel ad) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter Case Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Case Title',
              hintText: 'e.g., Business Contract Review',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _detailsController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Case Details',
              hintText: 'Describe your case in detail...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City',
              hintText: 'e.g., Karachi',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _milestonesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Milestones (Optional)',
              hintText: 'Break down the work into milestones...',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () {
                final title = _titleController.text.trim();
                final details = _detailsController.text.trim();
                final city = _cityController.text.trim();

                if (title.isEmpty || details.isEmpty || city.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.error),
                  );
                  return;
                }

                setState(() => _currentStep = 2);
              },
              child: const Text('Continue To Payment'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirmationStep(LawyerAdModel ad) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey200),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ad Details', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Lawyer', ad.lawyerName),
                _buildDetailRow('Service', ad.title),
                _buildDetailRow('Category', ad.category),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey200),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Case', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDetailRow('Title', _titleController.text),
                _buildDetailRow('City', _cityController.text),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('PKR ${ad.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isPaying ? null : () => _bookAd(ad),
              child: _isPaying
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Pay Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
