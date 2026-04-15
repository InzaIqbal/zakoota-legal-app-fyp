import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/consultation_model.dart';
import '../../models/consultation_enums.dart';
import '../../services/consultation_service.dart';
import '../../services/consultation_utils.dart';
import '../../../../core/constants/app_constants.dart';

/// Enhanced Consultation Card Widget
/// Displays consultation with all new features including counter-proposals
class EnhancedConsultationCard extends StatefulWidget {
  final ConsultationModel consultation;
  final bool isClient; // true if current user is client
  final String? currentUserId;
  final VoidCallback? onRefresh;

  const EnhancedConsultationCard({
    required this.consultation,
    required this.isClient,
    this.currentUserId,
    this.onRefresh,
    super.key,
  });

  @override
  State<EnhancedConsultationCard> createState() =>
      _EnhancedConsultationCardState();
}

class _EnhancedConsultationCardState extends State<EnhancedConsultationCard> {
  late ConsultationService _service;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _service = ConsultationService();
  }

  @override
  Widget build(BuildContext context) {
    final statusEnum = stringToConsultationStatus(widget.consultation.status);
    final typeEnum = stringToConsultationType(widget.consultation.type);
    final currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: statusEnum.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type, date, and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: typeEnum.icon == Icons.videocam
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Icon(
                    typeEnum.icon,
                    size: 16,
                    color: typeEnum.icon == Icons.videocam
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeEnum.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ConsultationUtils.formatDateTime(
                            widget.consultation.scheduledAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: statusEnum.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusEnum.icon,
                        size: 12,
                        color: statusEnum.color,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        statusEnum.displayName,
                        style: TextStyle(
                          color: statusEnum.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            if (widget.consultation.description.isNotEmpty) ...[
              const Text(
                'Topic',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.consultation.description,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Duration and additional info
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.schedule,
                    ConsultationUtils.getDurationText(
                        widget.consultation.durationMinutes),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (widget.consultation.type == 'video' &&
                    widget.consultation.meetingLink != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.video_call,
                      widget.consultation.meetingPlatform ?? 'Video',
                    ),
                  ),
                if (widget.consultation.type == 'in_person' &&
                    widget.consultation.location != null)
                  Expanded(
                    child: _buildInfoChip(
                      Icons.location_on,
                      'In-Person',
                    ),
                  ),
              ],
            ),

            // Notes section
            if (widget.consultation.notes != null &&
                widget.consultation.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Colors.amber[700]),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.consultation.notes!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],

            // Counter proposals section
            if (widget.consultation.counterProposals.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _buildCounterProposalsSection(currentUserId),
            ],

            // Time remaining / Past due
            const SizedBox(height: AppSpacing.md),
            _buildStatusInfoRow(),

            // Action Buttons
            const SizedBox(height: AppSpacing.md),
            _buildActionButtons(currentUserId, context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterProposalsSection(String? currentUserId) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sync_alt,
                  size: 14, color: Colors.purple[700]),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Alternative Proposals',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...widget.consultation.counterProposals.asMap().entries.map((entry) {
            final index = entry.key;
            final proposal = entry.value;
            return _buildCounterProposalItem(index, proposal, currentUserId);
          }),
        ],
      ),
    );
  }

  Widget _buildCounterProposalItem(
      int index, CounterProposal proposal, String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ConsultationUtils.formatDateTime(proposal.proposedDate),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      proposal.reason,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (proposal.isAccepted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'Accepted',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (!proposal.isAccepted &&
              widget.consultation.requesterId == currentUserId) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _rejectProposal(index),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: _isLoading ? null : () => _acceptProposal(index),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfoRow() {
    if (widget.consultation.status == 'pending') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline,
                size: 13, color: AppColors.warning),
            SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Awaiting approval',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (widget.consultation.status == 'accepted') {
      if (widget.consultation.scheduledAt.isAfter(DateTime.now())) {
        final remainingText = ConsultationUtils.getRemainingDaysText(
            widget.consultation.scheduledAt);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available,
                  size: 13, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  remainingText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } else if (widget.consultation.status == 'completed' &&
        widget.consultation.completionNotes != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.done_all,
                    size: 13, color: Colors.green[700]),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            if (widget.consultation.completionNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.consultation.completionNotes!,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(String? currentUserId, BuildContext context) {
    final canAccept = ConsultationUtils.canAccept(
        widget.consultation, currentUserId ?? '');
    final canReject = ConsultationUtils.canReject(
        widget.consultation, currentUserId ?? '');
    final canCancel =
        ConsultationUtils.canCancel(widget.consultation);

    if (canAccept || canReject) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (canReject)
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => _rejectConsultation(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Reject', style: TextStyle(fontSize: 12)),
              ),
            ),
          if (canReject) const SizedBox(width: AppSpacing.sm),
          if (canAccept)
            SizedBox(
              height: 36,
              child: FilledButton(
                onPressed: _isLoading ? null : _acceptConsultation,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Accept', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      );
    } else if (canCancel) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _cancelConsultation(context),
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Cancel', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _acceptConsultation() async {
    String? location;
    if (widget.consultation.type == 'in_person') {
       if (!mounted) return;
       location = await _showLocationDialog(context);
       if (location == null) return; // Cancelled
    }

    setState(() => _isLoading = true);
    
    // Get current user info for tracking
    final currentUser = FirebaseAuth.instance.currentUser;
    final userDoc = currentUser != null 
        ? await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get()
        : null;
    
    if (!mounted) return;
        
    final userName = userDoc?.data()?['fullName'] ?? 'User';
    final userRole = userDoc?.data()?['role'] ?? 'lawyer';

    try {
      await _service.acceptConsultation(
        widget.consultation.caseId,
        widget.consultation.id,
        currentUser?.uid ?? '',
        userName,
        userRole,
        location: location,
      );
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation accepted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Error accepting consultation');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectConsultation(BuildContext context) async {
    final reason = await _showReasonDialog(context, 'Reject');
    if (!mounted || reason == null) return;

    setState(() => _isLoading = true);
    try {
      final currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final userName = widget.isClient ? widget.consultation.clientName : widget.consultation.lawyerName;
      final userRole = widget.isClient ? 'Client' : 'Lawyer';

      await _service.rejectConsultation(
        widget.consultation.caseId,
        widget.consultation.id,
        currentUserId,
        userName,
        userRole,
        reason.isEmpty ? null : reason,
      );
      widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation rejected'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      _showError('Error rejecting consultation');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelConsultation(BuildContext context) async {
    final reason = await _showReasonDialog(context, 'Cancel');
    if (!mounted || reason == null) return;

    setState(() => _isLoading = true);
    try {
      final currentUserId = widget.currentUserId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      final userName = widget.isClient ? widget.consultation.clientName : widget.consultation.lawyerName;
      
      if (widget.isClient) {
        await _service.requestCancellation(
          widget.consultation,
          currentUserId,
          userName,
          reason.isEmpty ? null : reason,
        );
      } else {
        await _service.lawyerDirectCancellation(
          widget.consultation,
          currentUserId,
          userName,
          reason.isEmpty ? null : reason,
        );
      }

      widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consultation cancelled'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      _showError('Error cancelling consultation');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptProposal(int index) async {
    setState(() => _isLoading = true);
    try {
      await _service.acceptCounterProposal(
        widget.consultation.caseId,
        widget.consultation.id,
        index,
      );
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal accepted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError('Error accepting proposal');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectProposal(int index) async {
    setState(() => _isLoading = true);
    try {
      await _service.rejectCounterProposal(
        widget.consultation.caseId,
        widget.consultation.id,
        index,
      );
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal declined'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      _showError('Error declining proposal');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showReasonDialog(BuildContext context, String action) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Consultation'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Optional reason...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<String?> _showLocationDialog(BuildContext context) async {
    final controller = TextEditingController(text: widget.consultation.location);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Meeting Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide the address or location for this in-person consultation.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter complete address...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Accept & Set Location'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

// Helper functions
ConsultationStatus stringToConsultationStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return ConsultationStatus.pending;
    case 'accepted':
      return ConsultationStatus.accepted;
    case 'rejected':
      return ConsultationStatus.rejected;
    case 'cancelled':
      return ConsultationStatus.cancelled;
    case 'completed':
      return ConsultationStatus.completed;
    case 'no_show':
      return ConsultationStatus.noShow;
    default:
      return ConsultationStatus.pending;
  }
}

ConsultationType stringToConsultationType(String type) {
  return type.toLowerCase() == 'video'
      ? ConsultationType.video
      : ConsultationType.inPerson;
}
