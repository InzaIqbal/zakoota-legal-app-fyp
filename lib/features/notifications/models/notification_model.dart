import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  consultationRequested,
  consultationAccepted,
  consultationRejected,
  consultationCompleted,
  consultationRescheduled,
  paymentSuccess,
  paymentFailed,
  withdrawalRequested,
  withdrawalApproved,
  withdrawalRejected,
  casePosted,
  proposalReceived,
  proposalSubmitted,
  proposalAccepted,
  proposalRejected,
  caseAssigned,
  caseClosed,
  documentUploaded,
  documentVerified,
  documentRejected,
  messageReceived,
  profileVerificationUpdated,
  generic,
}

class AppNotification {
  final String id;
  final String userId;
  final String? actorId;
  final NotificationType type;
  final String title;
  final String message;
  final String? referenceType;
  final String? referenceId;
  final String? route;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final String priority;

  const AppNotification({
    required this.id,
    required this.userId,
    this.actorId,
    required this.type,
    required this.title,
    required this.message,
    this.referenceType,
    this.referenceId,
    this.route,
    this.payload = const {},
    required this.createdAt,
    this.isRead = false,
    this.readAt,
    this.priority = 'normal',
  });

  String get typeKey {
    switch (type) {
      case NotificationType.consultationRequested:
        return 'consultation_requested';
      case NotificationType.consultationAccepted:
        return 'consultation_accepted';
      case NotificationType.consultationRejected:
        return 'consultation_rejected';
      case NotificationType.consultationCompleted:
        return 'consultation_completed';
      case NotificationType.consultationRescheduled:
        return 'consultation_rescheduled';
      case NotificationType.paymentSuccess:
        return 'payment_success';
      case NotificationType.paymentFailed:
        return 'payment_failed';
      case NotificationType.withdrawalRequested:
        return 'withdrawal_requested';
      case NotificationType.withdrawalApproved:
        return 'withdrawal_approved';
      case NotificationType.withdrawalRejected:
        return 'withdrawal_rejected';
      case NotificationType.casePosted:
        return 'case_posted';
      case NotificationType.proposalReceived:
        return 'proposal_received';
      case NotificationType.proposalSubmitted:
        return 'proposal_submitted';
      case NotificationType.proposalAccepted:
        return 'proposal_accepted';
      case NotificationType.proposalRejected:
        return 'proposal_rejected';
      case NotificationType.caseAssigned:
        return 'case_assigned';
      case NotificationType.caseClosed:
        return 'case_closed';
      case NotificationType.documentUploaded:
        return 'document_uploaded';
      case NotificationType.documentVerified:
        return 'document_verified';
      case NotificationType.documentRejected:
        return 'document_rejected';
      case NotificationType.messageReceived:
        return 'message_received';
      case NotificationType.profileVerificationUpdated:
        return 'profile_verification_updated';
      case NotificationType.generic:
        return 'generic';
    }
  }

  static NotificationType parseType(String? type) {
    switch (type) {
      case 'consultation_requested':
        return NotificationType.consultationRequested;
      case 'consultation_accepted':
        return NotificationType.consultationAccepted;
      case 'consultation_rejected':
        return NotificationType.consultationRejected;
      case 'consultation_completed':
        return NotificationType.consultationCompleted;
      case 'consultation_rescheduled':
        return NotificationType.consultationRescheduled;
      case 'payment_success':
        return NotificationType.paymentSuccess;
      case 'payment_failed':
        return NotificationType.paymentFailed;
      case 'withdrawal_requested':
        return NotificationType.withdrawalRequested;
      case 'withdrawal_approved':
        return NotificationType.withdrawalApproved;
      case 'withdrawal_rejected':
        return NotificationType.withdrawalRejected;
      case 'case_posted':
        return NotificationType.casePosted;
      case 'proposal_received':
        return NotificationType.proposalReceived;
      case 'proposal_submitted':
        return NotificationType.proposalSubmitted;
      case 'proposal_accepted':
        return NotificationType.proposalAccepted;
      case 'proposal_rejected':
        return NotificationType.proposalRejected;
      case 'case_assigned':
        return NotificationType.caseAssigned;
      case 'case_closed':
        return NotificationType.caseClosed;
      case 'document_uploaded':
        return NotificationType.documentUploaded;
      case 'document_verified':
        return NotificationType.documentVerified;
      case 'document_rejected':
        return NotificationType.documentRejected;
      case 'message_received':
        return NotificationType.messageReceived;
      case 'profile_verification_updated':
        return NotificationType.profileVerificationUpdated;
      default:
        return NotificationType.generic;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actorId': actorId,
      'type': typeKey,
      'title': title,
      'message': message,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'route': route,
      'payload': payload,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'priority': priority,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    final dynamic rawPayload = map['payload'];
    final Map<String, dynamic> safePayload = rawPayload is Map
        ? rawPayload.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    final dynamic rawCreatedAt = map['createdAt'];
    final DateTime safeCreatedAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : DateTime.now();

    final dynamic rawReadAt = map['readAt'];
    final DateTime? safeReadAt = rawReadAt is Timestamp ? rawReadAt.toDate() : null;

    return AppNotification(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      actorId: map['actorId']?.toString(),
      type: parseType(map['type']?.toString()),
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      referenceType: map['referenceType']?.toString(),
      referenceId: map['referenceId']?.toString(),
      route: map['route']?.toString(),
      payload: safePayload,
      createdAt: safeCreatedAt,
      isRead: map['isRead'] == true,
      readAt: safeReadAt,
      priority: (map['priority'] ?? 'normal').toString(),
    );
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? actorId,
    NotificationType? type,
    String? title,
    String? message,
    String? referenceType,
    String? referenceId,
    String? route,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    String? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      route: route ?? this.route,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
    );
  }
}
