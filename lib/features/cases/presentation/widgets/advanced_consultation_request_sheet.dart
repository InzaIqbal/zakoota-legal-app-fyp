import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/consultation_model.dart';
import '../../models/consultation_enums.dart';
import '../../services/consultation_service.dart';
import '../../services/consultation_utils.dart';
import '../../../lawyer_auth/services/lawyer_availability_service.dart';
import '../../../lawyer_auth/models/lawyer_availability_model.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:zakoota/l10n/app_localizations.dart';

/// Advanced Consultation Request Sheet with all new features
/// This shows how to use the enhanced ConsultationModel with additional fields
class AdvancedConsultationRequestSheet extends StatefulWidget {
  final String caseId;
  final String targetId;
  final String caseTitle;
  final String lawyerName;
  final String clientName;
  final String clientId;
  final String lawyerId;
  final bool isClientRequester;

  const AdvancedConsultationRequestSheet({
    required this.caseId,
    required this.targetId,
    required this.caseTitle,
    required this.lawyerName,
    required this.clientName,
    required this.clientId,
    required this.lawyerId,
    this.isClientRequester = true,
    super.key,
  });

  @override
  State<AdvancedConsultationRequestSheet> createState() =>
      _AdvancedConsultationRequestSheetState();
}

class _AdvancedConsultationRequestSheetState
    extends State<AdvancedConsultationRequestSheet> {
  // Form state
  late ConsultationType _type;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  late String _description;
  late String? _meetingLink;
  late String? _location;
  late String? _meetingPlatform;
  late String? _notes;
  bool _isSubmitting = false;
  bool _isLoadingSlots = false;
  List<TimeSlot> _availableSlots = [];
  final LawyerAvailabilityService _availabilityService = LawyerAvailabilityService();

  // Controllers
  late TextEditingController _descriptionController;
  late TextEditingController _meetingLinkController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _type = ConsultationType.video;
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _durationMinutes = 60;
    _description = '';
    _meetingLink = null;
    _location = null;
    _meetingPlatform = null;
    _notes = null;

    _descriptionController = TextEditingController();
    _meetingLinkController = TextEditingController();
    _locationController = TextEditingController();
    _notesController = TextEditingController();

    _refreshAvailableSlots();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _meetingLinkController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _refreshAvailableSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      final slots = await _availabilityService.getAvailableSlots(
        widget.lawyerId,
        _selectedDate,
        _durationMinutes,
      );
      if (!mounted) return;
      setState(() {
        _availableSlots = slots;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        final loc = AppLocalizations.of(context);
        return SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.requestConsultation,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),

              // Case title display
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, color: AppColors.primary, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.caseTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Consultation Type Selection
              Text(
                loc.meetingPreference,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeChip(ConsultationType.video),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildTypeChip(ConsultationType.inPerson),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              Text(
                loc.topicBriefDescription,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: loc.consultationHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                ),
                maxLines: 2,
                onChanged: (value) => setState(() => _description = value),
              ),
              const SizedBox(height: AppSpacing.md),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.selectDate,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            ConsultationUtils.formatDate(_selectedDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.selectTime,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (_isLoadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: LinearProgressIndicator(),
                )
              else if (_availableSlots.isNotEmpty) ...[
                Text(
                  loc.availableSlotsForDate(ConsultationUtils.formatDate(_selectedDate)),
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final label = slot.displayTime;
                    final selected = _selectedTime.hour == slot.startTime.hour &&
                        _selectedTime.minute == slot.startTime.minute;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(label),
                      onSelected: (_) {
                        setState(() {
                          _selectedTime = TimeOfDay(
                            hour: slot.startTime.hour,
                            minute: slot.startTime.minute,
                          );
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else ...[
                Text(
                  loc.noAvailableSlotsMessage,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Duration
              Text(
                loc.duration,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _durationMinutes.toDouble(),
                      min: 15,
                      max: 240,
                      divisions: 15,
                      label: ConsultationUtils.getDurationText(_durationMinutes),
                      onChanged: (value) {
                        setState(() => _durationMinutes = value.toInt());
                        _refreshAvailableSlots();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      ConsultationUtils.getDurationText(_durationMinutes),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Meeting Details (conditional based on type)
              if (_type == ConsultationType.video) ...[
                Text(
                  loc.videoMeetingDetails,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _meetingLinkController,
                    decoration: InputDecoration(
                    hintText: loc.meetingLinkHint,
                    prefixIcon: const Icon(Icons.link, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                  onChanged: (value) => setState(() => _meetingLink = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _meetingPlatform ?? 'zoom',
                  items: ['Zoom', 'Google Meet', 'Teams', 'Other']
                      .map((platform) => DropdownMenuItem(
                            value: platform.toLowerCase().replaceAll(' ', '_'),
                            child: Text(platform),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _meetingPlatform = value),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                ),
              ] else ...[
                Text(
                  loc.meetingLocation,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _locationController,
                    decoration: InputDecoration(
                    hintText: loc.meetingLocationHint,
                    prefixIcon: const Icon(Icons.location_on, size: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  ),
                  onChanged: (value) => setState(() => _location = value),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Additional Notes
              Text(
                loc.additionalNotesOptional,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: loc.additionalNotesHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                ),
                maxLines: 3,
                onChanged: (value) => setState(() => _notes = value),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Submit Button
              FilledButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(loc.sendRequest),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ConsultationType type) {
    final isSelected = _type == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == ConsultationType.video ? Icons.videocam : Icons.people,
            size: 16,
            color: isSelected ? Colors.white : Colors.black,
          ),
          const SizedBox(width: 4),
          Text(type.displayName),
        ],
      ),
      onSelected: (bool selected) {
        if (selected) setState(() => _type = type);
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      checkmarkColor: Colors.white,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _refreshAvailableSlots();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitRequest() async {
    // Validate inputs
    if (_description.isEmpty) {
      _showError(loc.pleaseEnterConsultationTopic);
      return;
    }

    // Validate meeting details
    final validationError = ConsultationUtils.validateMeetingDetails(
      _type,
      _meetingLink,
      _location,
    );
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Combine Date and Time
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final withinAvailability = await _availabilityService.isTimeWithinAvailability(
        widget.lawyerId,
        scheduledAt,
        _durationMinutes,
      );
      if (!withinAvailability) {
        _showError(loc.lawyerNotAvailable);
        return;
      }

      final hasConflict = await ConsultationService().checkTimeSlotConflict(
        widget.lawyerId,
        scheduledAt,
        _durationMinutes,
      );
      if (hasConflict) {
        _showError(loc.timeSlotConflictMessage);
        return;
      }

      // Create consultation with all new fields
      final consultation = ConsultationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        caseId: widget.caseId,
        requesterId: user.uid,
        targetId: widget.targetId,
        caseTitle: widget.caseTitle,
        clientName: widget.clientName,
        lawyerName: widget.lawyerName,
        clientId: widget.clientId,
        lawyerId: widget.lawyerId,
        type: _type.value,
        description: _description,
        durationMinutes: _durationMinutes,
        status: 'pending',
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
        meetingLink: _meetingLink,
        meetingPlatform: _meetingPlatform,
        location: _location,
        notes: _notes,
      );

      await ConsultationService().requestConsultation(
        consultation,
        widget.isClientRequester ? widget.clientName : widget.lawyerName,
        widget.isClientRequester ? 'Client' : 'Lawyer',
      );
      
      if (!context.mounted) return;

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.consultationRequestSent),
            backgroundColor: AppColors.success,
          ),
        );
    } catch (e) {
      if (!context.mounted) return;
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
