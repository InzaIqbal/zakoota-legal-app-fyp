import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Stream conversations for a specific user
  Stream<List<ChatModel>> streamConversations(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort in memory to avoid index requirements
          chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return chats;
        });
  }

  /// Stream messages for a specific conversation with limit for pagination
  Stream<List<MessageModel>> streamMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Send a message with atomic unread count increment
  Future<void> sendMessage(String chatId, MessageModel message, bool isLawyer) async {
    // SECURITY RULE CHECK: Lawyers cannot initiate chat
    if (isLawyer) {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        throw Exception('Lawyer cannot initiate a new conversation. Protection Error.');
      }
      
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .limit(1)
          .get();
          
      if (messagesQuery.docs.isEmpty) {
        throw Exception('Lawyer cannot send the first message in a conversation.');
      }
    }

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) return;

    final data = chatDoc.data() as Map<String, dynamic>;
    final clientId = data['clientId'] as String;
    final lawyerId = data['lawyerId'] as String;
    
    // Determine whose unread count to increment
    final receiverId = message.senderId == clientId ? lawyerId : clientId;

    final batch = _firestore.batch();
    
    final messageRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(messageRef, message.toMap());
    
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': message.text,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'unreadCounts.$receiverId': FieldValue.increment(1),
    });
    
    await batch.commit();

    await _notificationService.createForUser(
      userId: receiverId,
      actorId: message.senderId,
      type: NotificationType.messageReceived,
      title: 'New message',
      message: message.text,
      referenceType: 'chat',
      referenceId: chatId,
      route: '/chat/$chatId',
      payload: {
        'clientId': clientId,
        'lawyerId': lawyerId,
      },
    );
  }

  /// Reset unread count for a user in a specific chat
  Future<void> markAsRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts.$userId': 0,
    });
  }

  /// Streams the total unread message count for a specific user across all chats
  Stream<int> streamTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final unreadCounts = doc.data()['unreadCounts'] as Map<String, dynamic>? ?? {};
        total += (unreadCounts[userId] as num? ?? 0).toInt();
      }
      return total;
    });
  }

  /// Find or create a chat (Initiated by Client)
  Future<ChatModel> getOrCreateChat({
    required String clientId,
    required String lawyerId,
    required String clientName,
    required String lawyerName,
    String? clientAvatar,
    String? lawyerAvatar,
  }) async {
    // Check if chat already exists
    final query = await _firestore
        .collection('chats')
        .where('clientId', isEqualTo: clientId)
        .where('lawyerId', isEqualTo: lawyerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final data = doc.data();
      if (!data.containsKey('participants')) {
        await doc.reference.update({
          'participants': [clientId, lawyerId],
        });
      }
      return ChatModel.fromMap(data, doc.id);
    }

    // Create new virtual chat (DO NOT SAVE to Firestore yet)
    // It will be saved when the first message is actually sent.
    final docRef = _firestore.collection('chats').doc();
    final chat = ChatModel(
      id: docRef.id,
      clientId: clientId,
      lawyerId: lawyerId,
      clientName: clientName,
      lawyerName: lawyerName,
      clientAvatar: clientAvatar,
      lawyerAvatar: lawyerAvatar,
      lastMessage: 'Chat started',
      lastMessageTime: DateTime.now(),
    );

    return chat;
  }
}
