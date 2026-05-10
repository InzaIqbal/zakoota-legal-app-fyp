import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lawyer_availability_model.dart';

class LawyerAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionName = 'lawyer_availabilities';

  /// Get lawyer's availability (custom or default)
  Future<LawyerAvailability> getAvailability(String lawyerId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(lawyerId).get();

      if (doc.exists) {
        return LawyerAvailability.fromMap(doc.data()!);
      } else {
        // Return default availability
        return LawyerAvailability.createDefaults(lawyerId);
      }
    } catch (e) {
      print('Error fetching availability: $e');
      return LawyerAvailability.createDefaults(lawyerId);
    }
  }

  /// Save custom availability
  Future<void> setAvailability(
    String lawyerId,
    List<DayAvailability> dayAvailabilities,
  ) async {
    try {
      // Validate availability
      for (var day in dayAvailabilities) {
        if (!_validateDayAvailability(day)) {
          throw Exception('Invalid day availability: ${day.dayOfWeek.displayName}');
        }
      }

      final availability = LawyerAvailability(
        lawyerId: lawyerId,
        dayAvailabilities: dayAvailabilities,
        availabilityVersionId: LawyerAvailability.generateVersionId(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collectionName)
          .doc(lawyerId)
          .set(availability.toMap());
    } catch (e) {
      print('Error setting availability: $e');
      rethrow;
    }
  }

  /// Reset to default availability
  Future<void> resetToDefaultAvailability(String lawyerId) async {
    try {
      final defaultAvailability = LawyerAvailability.createDefaults(lawyerId);
      await _firestore
          .collection(_collectionName)
          .doc(lawyerId)
          .set(defaultAvailability.toMap());
    } catch (e) {
      print('Error resetting availability: $e');
      rethrow;
    }
  }

  /// Check if time is within lawyer's availability window.
  /// Returns true if the lawyer has no custom availability configured
  /// (falls back to the conflict-check-only path).
  Future<bool> isTimeWithinAvailability(
    String lawyerId,
    DateTime scheduledTime,
    int durationMinutes,
  ) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(lawyerId).get();

      // No custom availability set — allow the booking; conflict check is the guard.
      if (!doc.exists) return true;

      final availability = LawyerAvailability.fromMap(doc.data()!);

      // Get day of week (1=Monday, 7=Sunday)
      int dayOfWeek = scheduledTime.weekday;
      final dayOfWeekEnum = DayOfWeek.fromValue(dayOfWeek);

      // Check if available on this day
      final dayAvail = availability.getAvailabilityForDay(dayOfWeekEnum);
      if (dayAvail == null || !dayAvail.isAvailable) {
        return false;
      }

      // Check if time is within range
      final scheduledMinutes = scheduledTime.hour * 60 + scheduledTime.minute;
      final endTime = scheduledMinutes + durationMinutes;

      return scheduledMinutes >= dayAvail.startMinutes &&
          endTime <= dayAvail.endMinutes;
    } catch (e) {
      print('Error checking availability: $e');
      // On error, allow the booking to proceed (conflict check still guards).
      return true;
    }
  }

  /// Get available time slots for a date
  Future<List<TimeSlot>> getAvailableSlots(
    String lawyerId,
    DateTime date,
    int slotDurationMinutes,
  ) async {
    try {
      final availability = await getAvailability(lawyerId);
      final dayOfWeekEnum = DayOfWeek.fromValue(date.weekday);

      final dayAvail = availability.getAvailabilityForDay(dayOfWeekEnum);
      if (dayAvail == null || !dayAvail.isAvailable) {
        return [];
      }

      // Get all consultations for this lawyer on this day
      final consultations = await _getConsultationsForDate(lawyerId, date);

      final slots = <TimeSlot>[];
      int currentMinutes = dayAvail.startMinutes;

      while (currentMinutes + slotDurationMinutes <= dayAvail.endMinutes) {
        final slotStart = DateTime(
          date.year,
          date.month,
          date.day,
          currentMinutes ~/ 60,
          currentMinutes % 60,
        );
        final slotEnd = slotStart.add(Duration(minutes: slotDurationMinutes));

        // Check if slot conflicts with any consultation
        final hasConflict = consultations.any((consultation) {
          final consultStart = consultation['scheduledAt'] as DateTime;
          final consultEnd = consultStart.add(
            Duration(minutes: consultation['durationMinutes'] as int),
          );
          return !(slotEnd.isBefore(consultStart) || slotStart.isAfter(consultEnd));
        });

        if (!hasConflict) {
          slots.add(TimeSlot(startTime: slotStart, endTime: slotEnd));
        }

        currentMinutes += 30; // 30-minute intervals
      }

      return slots;
    } catch (e) {
      print('Error getting available slots: $e');
      return [];
    }
  }

  /// Validate day availability settings
  bool _validateDayAvailability(DayAvailability day) {
    if (!day.isAvailable) {
      return true; // If not available, no validation needed
    }

    // Parse times
    final startParts = day.startTime.split(':');
    final endParts = day.endTime.split(':');

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;

    // Validate: start < end
    if (startTotal >= endTotal) {
      return false;
    }

    // Validate: within reasonable hours (6 AM - 11 PM)
    if (startHour < 6 || endHour > 23) {
      return false;
    }

    return true;
  }

  /// Get consultations for a specific date
  Future<List<Map<String, dynamic>>> _getConsultationsForDate(
    String lawyerId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Query consultations where lawyerId matches and date falls on consultation date
      final snapshot = await _firestore
          .collectionGroup('consultations')
          .where('lawyerId', isEqualTo: lawyerId)
          .where('status', whereIn: ['pending', 'accepted', 'in-progress'])
          .get();

      final consultations = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final scheduledAt = (data['scheduledAt'] as Timestamp).toDate();

        // Check if consultation is on the requested date
        if (scheduledAt.year == date.year &&
            scheduledAt.month == date.month &&
            scheduledAt.day == date.day) {
          consultations.add({
            'scheduledAt': scheduledAt,
            'durationMinutes': data['durationMinutes'] ?? 30,
          });
        }
      }

      return consultations;
    } catch (e) {
      print('Error getting consultations for date: $e');
      return [];
    }
  }

  /// Listen to availability changes
  Stream<LawyerAvailability> streamAvailability(String lawyerId) {
    return _firestore
        .collection(_collectionName)
        .doc(lawyerId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return LawyerAvailability.fromMap(doc.data()!);
      } else {
        return LawyerAvailability.createDefaults(lawyerId);
      }
    });
  }
}
