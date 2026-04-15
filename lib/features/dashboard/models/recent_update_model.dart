import 'package:cloud_firestore/cloud_firestore.dart';

/// Recent Update Types for Client Dashboard
enum UpdateType {
  casePosted,           // Client posted a new case
  proposalReceived,     // Client received a proposal from lawyer
  proposalAccepted,     // Client accepted a proposal
  proposalRejected,     // Client rejected a proposal
  paymentAccepted,      // Payment accepted/completed
  paymentRejected,      // Payment rejected/failed
  caseCompleted,        // Case marked as completed
  consultationScheduled, // Consultation scheduled
  documentUploaded,     // Document uploaded to case
  documentVerified,     // Document verified/approved
  messageReceived,      // New message from lawyer
  hearingScheduled,     // Hearing scheduled
  unknown,              // Unknown update type
}

class RecentUpdate {
  final String id;
  final String userId;
  final UpdateType type;
  final String title;
  final String message;
  final String? relatedId; // Case ID, Consultation ID, etc.
  final String? relatedData; // Additional info like case title
  final DateTime timestamp;
  final bool isRead;

  RecentUpdate({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedData,
    required this.timestamp,
    this.isRead = false,
  });

  /// Convert UpdateType enum to string
  String get typeString => type.toString().split('.').last;

  /// Get icon identifier based on type
  String get iconType {
    switch (type) {
      case UpdateType.casePosted:
        return 'briefcase';
      case UpdateType.proposalReceived:
        return 'fileText';
      case UpdateType.proposalAccepted:
        return 'check';
      case UpdateType.proposalRejected:
        return 'x';
      case UpdateType.paymentAccepted:
        return 'creditCard';
      case UpdateType.paymentRejected:
        return 'prohibit';
      case UpdateType.caseCompleted:
        return 'checkCircle';
      case UpdateType.consultationScheduled:
        return 'calendar';
      case UpdateType.documentUploaded:
        return 'upload';
      case UpdateType.documentVerified:
        return 'checkDouble';
      case UpdateType.messageReceived:
        return 'chatCircle';
      case UpdateType.hearingScheduled:
        return 'calendar';
      case UpdateType.unknown:
        return 'info';
    }
  }

  /// Get color identifier based on type
  String get colorType {
    switch (type) {
      case UpdateType.casePosted:
      case UpdateType.proposalReceived:
      case UpdateType.consultationScheduled:
      case UpdateType.hearingScheduled:
        return 'info';
      case UpdateType.proposalAccepted:
      case UpdateType.paymentAccepted:
      case UpdateType.documentVerified:
      case UpdateType.caseCompleted:
        return 'success';
      case UpdateType.proposalRejected:
      case UpdateType.paymentRejected:
        return 'error';
      case UpdateType.documentUploaded:
      case UpdateType.messageReceived:
        return 'secondary';
      case UpdateType.unknown:
        return 'textSecondary';
    }
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': typeString,
      'title': title,
      'message': message,
      'relatedId': relatedId,
      'relatedData': relatedData,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  /// Create from Firestore document
  factory RecentUpdate.fromMap(Map<String, dynamic> map, String documentId) {
    return RecentUpdate(
      id: documentId,
      userId: map['userId'] ?? '',
      type: _parseUpdateType(map['type']),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      relatedId: map['relatedId'],
      relatedData: map['relatedData'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  /// Parse string to UpdateType enum
  static UpdateType _parseUpdateType(String? typeString) {
    switch (typeString) {
      case 'casePosted':
        return UpdateType.casePosted;
      case 'proposalReceived':
        return UpdateType.proposalReceived;
      case 'proposalAccepted':
        return UpdateType.proposalAccepted;
      case 'proposalRejected':
        return UpdateType.proposalRejected;
      case 'paymentAccepted':
        return UpdateType.paymentAccepted;
      case 'paymentRejected':
        return UpdateType.paymentRejected;
      case 'caseCompleted':
        return UpdateType.caseCompleted;
      case 'consultationScheduled':
        return UpdateType.consultationScheduled;
      case 'documentUploaded':
        return UpdateType.documentUploaded;
      case 'documentVerified':
        return UpdateType.documentVerified;
      case 'messageReceived':
        return UpdateType.messageReceived;
      case 'hearingScheduled':
        return UpdateType.hearingScheduled;
      default:
        return UpdateType.unknown;
    }
  }

  /// Copy with method
  RecentUpdate copyWith({
    String? id,
    String? userId,
    UpdateType? type,
    String? title,
    String? message,
    String? relatedId,
    String? relatedData,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return RecentUpdate(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      relatedData: relatedData ?? this.relatedData,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
