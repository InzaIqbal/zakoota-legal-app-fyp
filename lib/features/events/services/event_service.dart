import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Streams all active events for a user ordered by schedule.
  Stream<List<EventModel>> streamUserEvents(String userId) {
    return _firestore
        .collection('events')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((event) {
            final status = event.status.toLowerCase();
            return status != 'cancelled' && status != 'completed';
          })
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return events;
    });
  }

  /// Streams events for a specific case reference
  Stream<List<EventModel>> streamCaseEvents(String caseId) {
    return _firestore
        .collection('events')
        .where('referenceId', isEqualTo: caseId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
      events.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return events;
    });
  }

  /// Fetches the nearest upcoming event for a given user (either client or lawyer)
  Stream<EventModel?> getNextUpcomingEvent(String userId) {
    return _firestore
        .collection('events')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .where((event) {
            final status = event.status.toLowerCase();
            // Keep agenda clean: exclude closed/cancelled items.
            return status != 'cancelled' && status != 'completed';
          })
          .toList();

      if (events.isEmpty) return null;

      // First preference: today's consultation/event (what user expects under Today's Agenda).
      final todaysEvents = events
          .where((event) =>
              !event.scheduledAt.isBefore(startOfToday) &&
              event.scheduledAt.isBefore(endOfToday))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      if (todaysEvents.isNotEmpty) {
        return todaysEvents.first;
      }

      // Fallback: nearest future event.
      final futureEvents = events
          .where((event) => !event.scheduledAt.isBefore(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      if (futureEvents.isNotEmpty) {
        return futureEvents.first;
      }

      return null;
    });
  }

  /// Creates a new event centrally
  Future<void> createEvent(EventModel event) async {
    try {
      await _firestore.collection('events').doc(event.id).set(event.toMap());
    } catch (e) {
      print('Failed to create event: $e');
      rethrow;
    }
  }

  /// Updates an existing event
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('events').doc(eventId).update(data);
    } catch (e) {
      print('Failed to update event: $e');
      rethrow;
    }
  }
}
