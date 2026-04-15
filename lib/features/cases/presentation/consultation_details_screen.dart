import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../models/consultation_model.dart';
import '../services/consultation_service.dart';

class ConsultationDetailsScreen extends StatefulWidget {
  final String caseId;
  final String consultationId;

  const ConsultationDetailsScreen({
    super.key,
    required this.caseId,
    required this.consultationId,
  });

  @override
  State<ConsultationDetailsScreen> createState() => _ConsultationDetailsScreenState();
}

class _ConsultationDetailsScreenState extends State<ConsultationDetailsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final bool _isEditing = false;
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConsultationModel?>(
      stream: _consultationService.getConsultationStream(widget.caseId, widget.consultationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Consultation Details')),
            body: const Center(child: Text('Consultation not found')),
          );
        }

        final consultation = snapshot.data!;
        final user = FirebaseAuth.instance.currentUser;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, consultation),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainInfoCard(context, consultation),
                const SizedBox(height: AppSpacing.lg),
                _buildActivityLog(context, consultation),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActions(context, consultation, user),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConsultationModel consult) {
    return AppBar(
      title: const Text('Consultation Details'),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (consult.status == 'pending' || consult.status == 'accepted')
          IconButton(
            icon: Icon(_isEditing ? PhosphorIconsRegular.check : PhosphorIconsRegular.pencilSimple),
            onPressed: () {
              // Toggle edit mode or show edit sheet
              _showEditSheet(context, consult);
            },
          ),
      ],
    );
  }

  Widget _buildMainInfoCard(BuildContext context, ConsultationModel consult) {
    final statusColor = _getStatusColor(consult.status);
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  consult.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'ID: ${consult.id.substring(consult.id.length - 6).toUpperCase()}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            consult.caseTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                consult.type == 'video' ? PhosphorIconsRegular.videoCamera : PhosphorIconsRegular.usersThree,
                size: 20,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                consult.type == 'video' ? 'Online Video Consultation' : 'In-Person Consultation',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildNameInfo('Client', consult.clientName, PhosphorIconsRegular.user),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildNameInfo('Lawyer', consult.lawyerName, PhosphorIconsRegular.gavel),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(PhosphorIconsRegular.calendar, 'Date', 
            '${consult.scheduledAt.day}/${consult.scheduledAt.month}/${consult.scheduledAt.year}'),
          const SizedBox(height: 12),
          _buildInfoRow(PhosphorIconsRegular.clock, 'Time', 
            '${consult.scheduledAt.hour.toString().padLeft(2, '0')}:${consult.scheduledAt.minute.toString().padLeft(2, '0')}'),
          const SizedBox(height: 12),
          _buildInfoRow(PhosphorIconsRegular.hourglass, 'Duration', '${consult.durationMinutes} Minutes'),
          if (consult.type == 'in_person' && consult.location != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(PhosphorIconsRegular.mapPin, 'Location', consult.location!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textLight),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildNameInfo(String label, String name, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog(BuildContext context, ConsultationModel consult) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Action to Consultation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (consult.activityLog.isEmpty)
          const Center(child: Text('No activity recorded yet'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: consult.activityLog.length,
            itemBuilder: (context, index) {
              final activity = consult.activityLog[consult.activityLog.length - 1 - index];
              return _buildActivityItem(activity);
            },
          ),
      ],
    );
  }

  Widget _buildActivityItem(ConsultationActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    activity.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (activity.userRole.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activity.userRole.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${activity.timestamp.day}/${activity.timestamp.month} ${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _mapActionToLabel(activity.action),
            style: TextStyle(
              color: _getActivityColor(activity.action),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          if (activity.previousValue != null || activity.newValue != null) ...[
            const SizedBox(height: 8),
            Text(
              'Changed from "${activity.previousValue ?? 'None'}" to "${activity.newValue ?? 'None'}"',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          if (activity.notes != null) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${activity.notes}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  String _mapActionToLabel(String action) {
    switch (action.toLowerCase()) {
      case 'created': return 'CONSULTATION REQUESTED';
      case 'accepted': return 'CONSULTATION ACCEPTED';
      case 'rejected': return 'CONSULTATION REJECTED';
      case 'cancelled': return 'CONSULTATION CANCELLED';
      case 'completed': return 'CONSULTATION COMPLETED';
      case 'updated_time': return 'TIME UPDATED';
      case 'updated_location': return 'LOCATION UPDATED';
      case 'updated_type': return 'CONSULTATION TYPE UPDATED';
      case 'updated': return 'DETAILS UPDATED';
      default: return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget? _buildBottomActions(BuildContext context, ConsultationModel consult, User? user) {
    if (consult.status != 'pending' && consult.status != 'accepted' && consult.status != 'cancellation_requested') return null;

    final isTarget = consult.targetId == user?.uid;
    final userRole = user?.uid == consult.clientId ? 'Client' : 'Lawyer';
    
    // Cancellation Requested UI
    if (consult.status == 'cancellation_requested') {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.grey100)),
        ),
        child: SafeArea(
          child: userRole == 'Lawyer'
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isActionLoading ? null : () => _resolveCancellation(context, consult, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text('Reject Refund'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isActionLoading ? null : () => _resolveCancellation(context, consult, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          minimumSize: const Size(0, 48),
                        ),
                        child: _isActionLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Approve Cancel'),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Cancellation pending lawyer approval...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.warning),
                  ),
                ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey100)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (consult.status == 'pending' && isTarget) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(context, consult, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => _updateStatus(context, consult, 'accepted'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ] else ...[
              if (consult.status != 'cancellation_requested' && consult.status != 'cancelled')
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isActionLoading ? null : () => _showCancelDialog(context, consult),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(0, 48),
                    ),
                    child: Text(userRole == 'Client' ? 'Request Cancellation' : 'Cancel Now'),
                  ),
                ),
              if (consult.status == 'accepted' || consult.status == 'cancellation_requested') ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _isActionLoading ? null : () => _markCompleted(context, consult),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(0, 48),
                    ),
                    child: _isActionLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Mark Completed'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _updateStatus(BuildContext context, ConsultationModel consult, String status) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userRole = user?.uid == consult.clientId ? 'Client' : 'Lawyer';
      
      if (status == 'accepted') {
        await _consultationService.acceptConsultation(
          consult.caseId, 
          consult.id, 
          user?.uid ?? '', 
          user?.displayName ?? 'User',
          userRole
        );
      } else {
        await _consultationService.rejectConsultation(
          consult.caseId, 
          consult.id, 
          user?.uid ?? '', 
          user?.displayName ?? 'User',
          userRole,
          'Rejected via Details'
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _resolveCancellation(BuildContext context, ConsultationModel consult, bool accept) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _consultationService.resolveClientCancellation(
        consult,
        user?.uid ?? '',
        user?.displayName ?? 'Lawyer',
        accept,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accept ? 'Cancellation Approved' : 'Cancellation Rejected')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  void _markCompleted(BuildContext context, ConsultationModel consult) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userRole = user?.uid == consult.clientId ? 'Client' : 'Lawyer';

      await _consultationService.completeConsultation(
        consult.caseId,
        consult.id,
        user?.uid ?? '',
        user?.displayName ?? 'User',
        userRole,
        'Completed via details'
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation completed')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCancelDialog(BuildContext context, ConsultationModel consult) {
    if (consult.status == 'cancellation_requested') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation already requested. Awaiting lawyer response.')));
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    final userRole = user?.uid == consult.clientId ? 'Client' : 'Lawyer';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(userRole == 'Client' ? 'Request Cancellation' : 'Cancel Consultation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userRole == 'Client')
              const Text('Requesting cancellation requires the lawyer to approve it. If approved, you will receive a refund.')
            else
              const Text(
                'Are you sure you want to cancel? Doing so directly will immediately refund the client, insert a negative automated review, and drop your job completion status.',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final reason = reasonController.text.trim().isEmpty ? null : reasonController.text.trim();
                
                if (userRole == 'Client') {
                  await _consultationService.requestCancellation(
                    consult,
                    user?.uid ?? '',
                    user?.displayName ?? 'Client',
                    reason,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancellation requested. Awaiting lawyer response.')));
                } else {
                  await _consultationService.lawyerDirectCancellation(
                    consult,
                    user?.uid ?? '',
                    user?.displayName ?? 'Lawyer',
                    reason,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation cancelled successfully.')));
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(userRole == 'Client' ? 'Send Request' : 'Accept Penalty & Cancel', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, ConsultationModel consult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditConsultationSheet(consultation: consult),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.warning;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'cancelled': return Colors.grey;
      case 'completed': return AppColors.primary;
      default: return AppColors.textLight;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'created': return AppColors.primary;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      case 'updated': return AppColors.secondary;
      case 'cancelled': return Colors.grey;
      case 'completed': return Colors.black;
      default: return AppColors.textLight;
    }
  }
}

class _EditConsultationSheet extends StatefulWidget {
  final ConsultationModel consultation;

  const _EditConsultationSheet({required this.consultation});

  @override
  State<_EditConsultationSheet> createState() => _EditConsultationSheetState();
}

class _EditConsultationSheetState extends State<_EditConsultationSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _type;
  final TextEditingController _locationController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.consultation.scheduledAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.consultation.scheduledAt);
    _type = widget.consultation.type;
    _locationController.text = widget.consultation.location ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Consultation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          
          const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('video', 'Video Call', PhosphorIconsRegular.videoCamera),
              const SizedBox(width: 12),
              _buildTypeChip('in_person', 'In-Person', PhosphorIconsRegular.usersThree),
            ],
          ),
          
          if (_type == 'in_person') ...[
            const SizedBox(height: AppSpacing.md),
            const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter meeting location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(PhosphorIconsRegular.mapPin),
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.md),
          const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(PhosphorIconsRegular.calendar),
                  label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(PhosphorIconsRegular.clock),
                  label: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _isSubmitting ? null : _submitEdits,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Update Consultation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _type == value;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _type = value);
      },
      label: Text(label),
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitEdits() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final newScheduledAt = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute,
      );
      
      final updated = widget.consultation.copyWith(
        type: _type,
        location: _type == 'in_person' ? _locationController.text : null,
        scheduledAt: newScheduledAt,
      );
      
      final userRole = user?.uid == widget.consultation.clientId ? 'Client' : 'Lawyer';

      await ConsultationService().updateConsultation(
        updated, 
        user?.uid ?? '', 
        user?.displayName ?? 'User',
        userRole
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation updated and changes logged')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
