import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/recent_update_model.dart';

class RecentUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch recent updates for a user
  Future<List<RecentUpdate>> getRecentUpdates(String userId, {int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentUpdates')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Firestore query timeout for recent updates');
              throw Exception('Database query timeout');
            },
          );

      final List<RecentUpdate> updates = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final update = RecentUpdate.fromMap(data, doc.id);
          updates.add(update);
        } catch (e) {
          debugPrint('Error parsing recent update document ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('Fetched ${updates.length} recent updates for user $userId');
      return updates;
    } catch (e) {
      debugPrint('Error fetching recent updates: $e');
      rethrow;
    }
  }

  /// Stream recent updates for real-time updates
  Stream<List<RecentUpdate>> streamRecentUpdates(String userId, {int limit = 10}) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('recentUpdates')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            final updates = <RecentUpdate>[];
            for (var doc in snapshot.docs) {
              try {
                final data = doc.data();
                final update = RecentUpdate.fromMap(data, doc.id);
                updates.add(update);
              } catch (e) {
                debugPrint('Error parsing recent update: $e');
                continue;
              }
            }
            return updates;
          });
    } catch (e) {
      debugPrint('Error streaming recent updates: $e');
      rethrow;
    }
  }

  /// Add a new recent update (typically called from other services)
  Future<void> addRecentUpdate(RecentUpdate update) async {
    try {
      await _firestore
          .collection('users')
          .doc(update.userId)
          .collection('recentUpdates')
          .add(update.toMap());

      debugPrint('Added recent update for user ${update.userId}');
    } catch (e) {
      debugPrint('Error adding recent update: $e');
      rethrow;
    }
  }

  /// Mark update as read
  Future<void> markAsRead(String userId, String updateId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentUpdates')
          .doc(updateId)
          .update({'isRead': true});

      debugPrint('Marked update $updateId as read');
    } catch (e) {
      debugPrint('Error marking update as read: $e');
      rethrow;
    }
  }

  /// Delete old updates (optional cleanup)
  Future<void> deleteUpdate(String userId, String updateId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentUpdates')
          .doc(updateId)
          .delete();

      debugPrint('Deleted update $updateId');
    } catch (e) {
      debugPrint('Error deleting update: $e');
      rethrow;
    }
  }

  /// Clear all updates for a user (optional)
  Future<void> clearAllUpdates(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recentUpdates')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('Cleared all updates for user $userId');
    } catch (e) {
      debugPrint('Error clearing updates: $e');
      rethrow;
    }
  }
}
