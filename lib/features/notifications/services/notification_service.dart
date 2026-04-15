import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notificationCollection(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Stream<List<AppNotification>> streamNotifications(String userId, {int limit = 50}) {
    return _notificationCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<int> streamUnreadCount(String userId) {
    return _notificationCollection(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> createNotification(AppNotification notification) async {
    final now = DateTime.now();
    await _notificationCollection(notification.userId).add(
      notification.copyWith(createdAt: now).toMap(),
    );
  }

  Future<void> createForUser({
    required String userId,
    String? actorId,
    required NotificationType type,
    required String title,
    required String message,
    String? referenceType,
    String? referenceId,
    String? route,
    Map<String, dynamic> payload = const {},
    String priority = 'normal',
  }) async {
    final notification = AppNotification(
      id: '',
      userId: userId,
      actorId: actorId,
      type: type,
      title: title,
      message: message,
      referenceType: referenceType,
      referenceId: referenceId,
      route: route,
      payload: payload,
      createdAt: DateTime.now(),
      isRead: false,
      priority: priority,
    );

    await createNotification(notification);
  }

  Future<void> createBatchNotifications(List<AppNotification> notifications) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final notification in notifications) {
      final docRef = _notificationCollection(notification.userId).doc();
      batch.set(
        docRef,
        notification.copyWith(createdAt: now).toMap(),
      );
    }

    await batch.commit();
  }

  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationCollection(userId).doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationCollection(userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> dismissNotification(String userId, String notificationId) async {
    await _notificationCollection(userId).doc(notificationId).delete();
  }
}
