import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String clientId;
  final String lawyerId;
  final String clientName;
  final String lawyerName;
  final String? clientAvatar;
  final String? lawyerAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts; // Per-user unread count
  final bool isActive;

  ChatModel({
    required this.id,
    required this.clientId,
    required this.lawyerId,
    required this.clientName,
    required this.lawyerName,
    this.clientAvatar,
    this.lawyerAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'clientName': clientName,
      'lawyerName': lawyerName,
      'clientAvatar': clientAvatar,
      'lawyerAvatar': lawyerAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'isActive': isActive,
      'participants': [clientId, lawyerId],
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      clientId: map['clientId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      clientName: map['clientName'] ?? '',
      lawyerName: map['lawyerName'] ?? '',
      clientAvatar: map['clientAvatar'],
      lawyerAvatar: map['lawyerAvatar'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      isActive: map['isActive'] ?? true,
    );
  }
}
