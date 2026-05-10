import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:zakoota/l10n/app_localizations.dart';
import '../../../core/constants/app_constants.dart';
import '../../lawyers/data/lawyer_mock_data.dart';
import '../../lawyers/services/lawyer_service.dart';

/// Booking Screen - Select date and time for consultation
class BookingScreen extends StatefulWidget {
  final String lawyerId;

  const BookingScreen({
    super.key,
    required this.lawyerId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  LawyerProfile? _lawyer;
  bool _isLoading = true;
  String _meetingType = 'online';
  final _topicController = TextEditingController();

  // Mock available dates (next 7 days)
  final List<DateTime> _availableDates = List.generate(
    7,
    (index) => DateTime.now().add(Duration(days: index + 1)),
  );

  // Mock time slots
  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];

  // Mock unavailable slots (for demo)
  final List<String> _unavailableSlots = ['11:00 AM', '03:00 PM'];

  @override
  void initState() {
    super.initState();
    _loadLawyer();
  }

  Future<void> _loadLawyer() async {
    try {
      final lawyer = await LawyerService().getLawyerById(widget.lawyerId);
      if (mounted) {
        setState(() {
          _lawyer = lawyer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lawyer = _lawyer;

    if (lawyer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text(loc.lawyerNotFound)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsRegular.arrowLeft),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/client-home');
            }
          },
        ),
        title: Text(
          loc.bookConsultation,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lawyer Info Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(lawyer.photoUrl),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lawyer.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                lawyer.specializations.isNotEmpty ? lawyer.specializations.first : loc.lawyerFocus,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${loc.currencyPKR} ${lawyer.pricePerConsultation}',
                          style: textTheme.titleMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Consultation Topic
                  Text(
                    loc.topicBriefDescription,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      hintText: loc.consultationHint,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: AppColors.grey300),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (v) => setState(() {}),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Meeting Type
                  Text(
                    loc.meetingPreference,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _MeetingTypeButton(
                          title: loc.videoCall,
                          icon: PhosphorIconsRegular.videoCamera,
                          isSelected: _meetingType == 'online',
                          onTap: () => setState(() => _meetingType = 'online'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MeetingTypeButton(
                          title: loc.inPerson,
                          icon: PhosphorIconsRegular.users,
                          isSelected: _meetingType == 'in_person',
                          onTap: () => setState(() => _meetingType = 'in_person'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Select Date Section
                  Text(
                    loc.selectDate,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Horizontal Date List
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableDates.length,
                      itemBuilder: (context, index) {
                        final date = _availableDates[index];
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.day == date.day &&
                            _selectedDate!.month == date.month;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                              _selectedTimeSlot = null; // Reset time
                            });
                          },
                          child: Container(
                            width: 70,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.grey300,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getWeekday(date),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _getMonth(date),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Select Time Section
                  Text(
                    loc.selectTime,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Time Slots Grid
                  if (_selectedDate == null)
                    Center(
                      child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            loc.pleaseSelectDateFirst,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: _timeSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _timeSlots[index];
                        final isSelected = _selectedTimeSlot == slot;
                        final isUnavailable = _unavailableSlots.contains(slot);

                        return GestureDetector(
                          onTap: isUnavailable
                              ? null
                              : () {
                                  setState(() => _selectedTimeSlot = slot);
                                },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isUnavailable
                                  ? AppColors.grey200
                                  : isSelected
                                      ? AppColors.secondary
                                      : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: isUnavailable
                                    ? AppColors.grey300
                                    : isSelected
                                        ? AppColors.secondary
                                        : AppColors.grey300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                slot,
                                style: textTheme.bodySmall?.copyWith(
                                  color: isUnavailable
                                      ? AppColors.textLight
                                      : isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  decoration: isUnavailable
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.totalLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'PKR ${lawyer.pricePerConsultation}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedDate != null &&
                              _selectedTimeSlot != null &&
                              _topicController.text.trim().isNotEmpty
                          ? () {
                              context.push(
                                '/booking-summary',
                                extra: {
                                  'lawyerId': widget.lawyerId,
                                  'lawyerName': lawyer.name,
                                  'lawyerAvatar': lawyer.photoUrl,
                                  'lawyerSpecialization': lawyer.specializations.isNotEmpty ? lawyer.specializations.first : 'Lawyer Focus',
                                  'date': _selectedDate,
                                  'time': _selectedTimeSlot,
                                  'price': lawyer.pricePerConsultation,
                                  'topic': _topicController.text.trim(),
                                  'meetingType': _meetingType,
                                },
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        disabledBackgroundColor: AppColors.grey300,
                      ),
                      child: Text(loc.reviewAndPay),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      return DateFormat('EEE', locale).format(date);
    } catch (_) {
      return DateFormat('EEE').format(date);
    }
  }

  String _getMonth(DateTime date) {
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      return DateFormat('MMM', locale).format(date);
    } catch (_) {
      return DateFormat('MMM').format(date);
    }
  }
}

/// Meeting Type Button Widget
class _MeetingTypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MeetingTypeButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            PhosphorIcon(
              icon as PhosphorIconData,
              color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
