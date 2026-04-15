import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String type; // 'consultation', 'hearing', 'deadline', etc.
  final String title; // E.g., 'Consultation with John Doe'
  final String subtitle; // E.g., 'Case #204 vs State'
  final String? location; // Optional location for case events
  final String? caseId; // Case ID for workspace navigation
  final String referenceId; // The ID of the original case or consultation doc
  final List<String> participants; // [clientId, lawyerId]
  final DateTime scheduledAt;
  final String status; // 'upcoming', 'completed', 'cancelled'
  final String? createdBy; // User ID who created the event

  EventModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.location,
    this.caseId,
    required this.referenceId,
    required this.participants,
    required this.scheduledAt,
    required this.status,
    this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'location': location,
      'caseId': caseId,
      'referenceId': referenceId,
      'participants': participants,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'status': status,
      'createdBy': createdBy,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      type: map['type'] as String? ?? 'event',
      title: map['title'] as String? ?? 'Untitled Event',
      subtitle: map['subtitle'] as String? ?? '',
      location: map['location'] as String?,
      caseId: map['caseId'] as String?,
      referenceId: map['referenceId'] as String? ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      scheduledAt: (map['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'upcoming',
      createdBy: map['createdBy'] as String?,
    );
  }
}
