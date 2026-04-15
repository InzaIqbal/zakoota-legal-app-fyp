import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentType;
  final String type; // e.g., 'text', 'consultation_booking'
  final Map<String, dynamic>? metadata; // Extra data for custom messages

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
    this.type = 'text',
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'type': type,
      'metadata': metadata,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrl: map['attachmentUrl'],
      attachmentType: map['attachmentType'],
      type: map['type'] ?? 'text',
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }
}
