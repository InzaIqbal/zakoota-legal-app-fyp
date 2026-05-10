import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum DayOfWeek {
  monday(1, 'Monday'),
  tuesday(2, 'Tuesday'),
  wednesday(3, 'Wednesday'),
  thursday(4, 'Thursday'),
  friday(5, 'Friday'),
  saturday(6, 'Saturday'),
  sunday(7, 'Sunday');

  final int value;
  final String displayName;
  const DayOfWeek(this.value, this.displayName);

  factory DayOfWeek.fromValue(int value) {
    return DayOfWeek.values.firstWhere((e) => e.value == value);
  }
}

class DayAvailability {
  final DayOfWeek dayOfWeek;
  final String startTime;  // HH:mm format, e.g., "09:00"
  final String endTime;    // HH:mm format, e.g., "17:00"
  final bool isAvailable;

  DayAvailability({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  // Convert to TimeOfDay for UI
  TimeOfDay get startTimeOfDay {
    final parts = startTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  TimeOfDay get endTimeOfDay {
    final parts = endTime.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Convert to minutes since midnight
  int get startMinutes {
    final parts = startTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int get endMinutes {
    final parts = endTime.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek.value,
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }

  factory DayAvailability.fromMap(Map<String, dynamic> map) {
    return DayAvailability(
      dayOfWeek: DayOfWeek.fromValue(map['dayOfWeek']),
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '17:00',
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  DayAvailability copyWith({
    DayOfWeek? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) {
    return DayAvailability(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

class LawyerAvailability {
  final String lawyerId;
  final List<DayAvailability> dayAvailabilities;
  final String availabilityVersionId;  // Format: "2026-05-07_v1_abc123"
  final DateTime createdAt;
  final DateTime updatedAt;

  LawyerAvailability({
    required this.lawyerId,
    required this.dayAvailabilities,
    required this.availabilityVersionId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get availability for a specific day
  DayAvailability? getAvailabilityForDay(DayOfWeek dayOfWeek) {
    try {
      return dayAvailabilities.firstWhere((day) => day.dayOfWeek == dayOfWeek);
    } catch (e) {
      return null;
    }
  }

  /// Check if lawyer is available on a specific day
  bool isAvailableOnDay(DayOfWeek dayOfWeek) {
    final day = getAvailabilityForDay(dayOfWeek);
    return day?.isAvailable ?? false;
  }

  /// Generate new availability version ID
  static String generateVersionId() {
    final now = DateTime.now();
    final date = now.toString().split(' ')[0]; // YYYY-MM-DD
    final hash = now.millisecondsSinceEpoch.toString().substring(5, 13);
    return '${date}_v1_$hash';
  }

  /// Create default availability (Mon-Fri, 9 AM - 5 PM)
  factory LawyerAvailability.createDefaults(String lawyerId) {
    final now = DateTime.now();
    return LawyerAvailability(
      lawyerId: lawyerId,
      dayAvailabilities: [
        DayAvailability(
          dayOfWeek: DayOfWeek.monday,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.tuesday,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.wednesday,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.thursday,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.friday,
          startTime: '09:00',
          endTime: '17:00',
          isAvailable: true,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.saturday,
          startTime: '00:00',
          endTime: '00:00',
          isAvailable: false,
        ),
        DayAvailability(
          dayOfWeek: DayOfWeek.sunday,
          startTime: '00:00',
          endTime: '00:00',
          isAvailable: false,
        ),
      ],
      availabilityVersionId: generateVersionId(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'dayAvailabilities': dayAvailabilities.map((day) => day.toMap()).toList(),
      'availabilityVersionId': availabilityVersionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LawyerAvailability.fromMap(Map<String, dynamic> map) {
    return LawyerAvailability(
      lawyerId: map['lawyerId'] ?? '',
      dayAvailabilities: List<DayAvailability>.from(
        (map['dayAvailabilities'] as List).map((day) => DayAvailability.fromMap(day)),
      ),
      availabilityVersionId: map['availabilityVersionId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  LawyerAvailability copyWith({
    String? lawyerId,
    List<DayAvailability>? dayAvailabilities,
    String? availabilityVersionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LawyerAvailability(
      lawyerId: lawyerId ?? this.lawyerId,
      dayAvailabilities: dayAvailabilities ?? this.dayAvailabilities,
      availabilityVersionId: availabilityVersionId ?? this.availabilityVersionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;

  TimeSlot({required this.startTime, required this.endTime});

  String get displayTime {
    final startStr = startTime.toString().substring(11, 16);
    final endStr = endTime.toString().substring(11, 16);
    return '$startStr - $endStr';
  }
}
