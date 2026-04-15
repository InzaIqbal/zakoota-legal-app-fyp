import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: userId == null
          ? const Center(child: Text('Please log in again'))
          : StreamBuilder<List<EventModel>>(
              stream: EventService().streamUserEvents(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allEvents = snapshot.data ?? [];
                final selectedDayEvents = allEvents
                    .where((e) => _isSameDate(e.scheduledAt, _selectedDate))
                    .toList();

                final appointments = selectedDayEvents
                    .where((e) => e.type == 'consultation' || e.type == 'hearing')
                    .toList();
                final tasks = selectedDayEvents
                    .where((e) => e.type != 'consultation' && e.type != 'hearing')
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.grey200),
                      ),
                      child: CalendarDatePicker(
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateChanged: (date) {
                          setState(() => _selectedDate = date);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        _summaryChip('Appointments', appointments.length, AppColors.primary),
                        const SizedBox(width: 8),
                        _summaryChip('Tasks', tasks.length, AppColors.info),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      DateFormat('EEEE, d MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (selectedDayEvents.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: const Text('No appointments or tasks for this day.'),
                      ),
                    ...selectedDayEvents.map((event) {
                      final isAppointment = event.type == 'consultation' || event.type == 'hearing';
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: (isAppointment ? AppColors.primary : AppColors.info).withValues(alpha: 0.12),
                            child: PhosphorIcon(
                              isAppointment ? PhosphorIconsRegular.users : PhosphorIconsRegular.checkSquare,
                              color: isAppointment ? AppColors.primary : AppColors.info,
                            ),
                          ),
                          title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            '${DateFormat('hh:mm a').format(event.scheduledAt)}  •  ${event.subtitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAppointment ? AppColors.primary.withValues(alpha: 0.1) : AppColors.info.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAppointment ? 'Appointment' : 'Task',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isAppointment ? AppColors.primary : AppColors.info,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
