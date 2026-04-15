import 'package:cloud_firestore/cloud_firestore.dart';

/// Counter Proposal for consultation date/time negotiations
class CounterProposal {
  final String proposedBy; // userId who made the proposal
  final DateTime proposedDate;
  final String proposedType; // 'video' or 'in_person'
  final String? proposedLocation; // For in-person consultations
  final String? proposedMeetingLink; // For video consultations
  final String reason; // Why they're proposing a different time
  final DateTime createdAt;
  final bool isAccepted; // If original requester accepts this counter

  CounterProposal({
    required this.proposedBy,
    required this.proposedDate,
    required this.proposedType,
    this.proposedLocation,
    this.proposedMeetingLink,
    required this.reason,
    required this.createdAt,
    this.isAccepted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'proposedBy': proposedBy,
      'proposedDate': Timestamp.fromDate(proposedDate),
      'proposedType': proposedType,
      'proposedLocation': proposedLocation,
      'proposedMeetingLink': proposedMeetingLink,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAccepted': isAccepted,
    };
  }

  factory CounterProposal.fromMap(Map<String, dynamic> map) {
    return CounterProposal(
      proposedBy: map['proposedBy'] ?? '',
      proposedDate: (map['proposedDate'] as Timestamp).toDate(),
      proposedType: map['proposedType'] ?? 'video',
      proposedLocation: map['proposedLocation'],
      proposedMeetingLink: map['proposedMeetingLink'],
      reason: map['reason'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAccepted: map['isAccepted'] ?? false,
    );
  }

  /// Create a copy of this counter proposal with updated fields
  CounterProposal copyWith({
    String? proposedBy,
    DateTime? proposedDate,
    String? proposedType,
    String? proposedLocation,
    String? proposedMeetingLink,
    String? reason,
    DateTime? createdAt,
    bool? isAccepted,
  }) {
    return CounterProposal(
      proposedBy: proposedBy ?? this.proposedBy,
      proposedDate: proposedDate ?? this.proposedDate,
      proposedType: proposedType ?? this.proposedType,
      proposedLocation: proposedLocation ?? this.proposedLocation,
      proposedMeetingLink: proposedMeetingLink ?? this.proposedMeetingLink,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}

/// Activity log for consultation changes
class ConsultationActivity {
  final String id;
  final String userId;
  final String userName;
  final String userRole; // 'Lawyer' or 'Client'
  final String action; // 'created', 'updated_time', 'updated_location', 'accepted', 'rejected', 'cancelled'
  final String? previousValue;
  final String? newValue;
  final String? notes;
  final DateTime timestamp;

  ConsultationActivity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    this.previousValue,
    this.newValue,
    this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'action': action,
      'previousValue': previousValue,
      'newValue': newValue,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ConsultationActivity.fromMap(Map<String, dynamic> map) {
    return ConsultationActivity(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? '',
      action: map['action'] ?? '',
      previousValue: map['previousValue'],
      newValue: map['newValue'],
      notes: map['notes'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class ConsultationModel {
  final String id;
  final String caseId;
  final String requesterId; // Who requested it (Lawyer or Client)
  final String targetId; // Who needs to accept (Lawyer or Client)
  
  // Context for UI
  final String caseTitle;
  final String clientName;
  final String lawyerName;
  final String clientId;
  final String lawyerId;
  final String? clientAvatar;
  final String? lawyerAvatar;
  
  // Consultation Details
  final String type; // 'video' or 'in_person'
  final String description; // Purpose/topic of consultation
  final int durationMinutes; // Expected duration in minutes
  
  // Location/Meeting Details
  final String? location; // Address for in-person consultation
  final String? lawyerOfficeLocation; // Lawyer's office location for in-person (from lawyer profile)
  final String? meetingLink; // Video call link (Zoom, Google Meet, etc.)
  final String? meetingPlatform; // 'zoom', 'google_meet', 'teams', etc.
  
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled', 'completed', 'no_show', 'cancellation_requested'
  final String? rejectionReason; // Why it was rejected (if rejected)
  final String? cancellationReason; // Why it was cancelled
  final String? cancellationRequestedBy; // ID of user who requested cancellation
  
  // Financial & Stats
  final String? refundStatus; // 'pending', 'processed', 'declined'
  final bool penalized; // If lawyer cancelled directly and took a penalty

  // Scheduling
  final DateTime scheduledAt;
  final List<CounterProposal> counterProposals; // For negotiating alternative times
  final bool hasUnresolvedProposal; // If there's a pending counter-proposal
  final String caseStatus; // 'open', 'active', or 'closed' to filter consultations
  
  // Activity Tracking
  final List<ConsultationActivity> activityLog;
  
  // Additional Fields
  final String? notes; // Additional notes/instructions from requester
  final List<String> attachmentIds; // References to attached documents
  final String? completionNotes; // Notes after consultation is completed
  final DateTime? completedAt; // When the consultation actually happened
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt; // When the other party accepted
  final DateTime? reminderSentAt; // Track if reminder was sent

  ConsultationModel({
    required this.id,
    required this.caseId,
    required this.requesterId,
    required this.targetId,
    required this.caseTitle,
    required this.clientName,
    required this.lawyerName,
    required this.clientId,
    required this.lawyerId,
    this.clientAvatar,
    this.lawyerAvatar,
    required this.type,
    this.description = '',
    this.durationMinutes = 60,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    this.location,
    this.lawyerOfficeLocation,
    this.meetingLink,
    this.meetingPlatform,
    this.rejectionReason,
    this.cancellationReason,
    this.cancellationRequestedBy,
    this.refundStatus,
    this.penalized = false,
    this.counterProposals = const [],
    this.hasUnresolvedProposal = false,
    this.activityLog = const [],
    this.notes,
    this.attachmentIds = const [],
    this.completionNotes,
    this.completedAt,
    this.updatedAt,
    this.acceptedAt,
    this.reminderSentAt,
    this.caseStatus = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caseId': caseId,
      'requesterId': requesterId,
      'targetId': targetId,
      'caseTitle': caseTitle,
      'clientName': clientName,
      'lawyerName': lawyerName,
      'clientId': clientId,
      'lawyerId': lawyerId,
      'clientAvatar': clientAvatar,
      'lawyerAvatar': lawyerAvatar,
      'type': type,
      'description': description,
      'durationMinutes': durationMinutes,
      'status': status,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'lawyerOfficeLocation': lawyerOfficeLocation,
      'meetingLink': meetingLink,
      'meetingPlatform': meetingPlatform,
      'rejectionReason': rejectionReason,
      'cancellationReason': cancellationReason,
      'cancellationRequestedBy': cancellationRequestedBy,
      'refundStatus': refundStatus,
      'penalized': penalized,
      'counterProposals': counterProposals.map((x) => x.toMap()).toList(),
      'hasUnresolvedProposal': hasUnresolvedProposal,
      'activityLog': activityLog.map((x) => x.toMap()).toList(),
      'notes': notes,
      'attachmentIds': attachmentIds,
      'completionNotes': completionNotes,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'reminderSentAt': reminderSentAt != null ? Timestamp.fromDate(reminderSentAt!) : null,
      'caseStatus': caseStatus,
    };
  }

  factory ConsultationModel.fromMap(Map<String, dynamic> map, String id) {
    final counterProposalsData = map['counterProposals'] as List<dynamic>? ?? [];
    final counterProposals = counterProposalsData
        .map((item) => CounterProposal.fromMap(item as Map<String, dynamic>))
        .toList();

    final activityLogData = map['activityLog'] as List<dynamic>? ?? [];
    final activityLog = activityLogData
        .map((item) => ConsultationActivity.fromMap(item as Map<String, dynamic>))
        .toList();

    return ConsultationModel(
      id: id,
      caseId: map['caseId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      targetId: map['targetId'] ?? '',
      caseTitle: map['caseTitle'] ?? '',
      clientName: map['clientName'] ?? '',
      lawyerName: map['lawyerName'] ?? '',
      clientId: map['clientId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      clientAvatar: map['clientAvatar'],
      lawyerAvatar: map['lawyerAvatar'],
      type: map['type'] ?? 'video',
      description: map['description'] ?? '',
      durationMinutes: (map['durationMinutes'] as num? ?? 60).toInt(),
      status: map['status'] ?? 'pending',
      scheduledAt: (map['scheduledAt'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      location: map['location'],
      lawyerOfficeLocation: map['lawyerOfficeLocation'],
      meetingLink: map['meetingLink'],
      meetingPlatform: map['meetingPlatform'],
      rejectionReason: map['rejectionReason'],
      cancellationReason: map['cancellationReason'],
      cancellationRequestedBy: map['cancellationRequestedBy'],
      refundStatus: map['refundStatus'],
      penalized: map['penalized'] ?? false,
      counterProposals: counterProposals,
      hasUnresolvedProposal: map['hasUnresolvedProposal'] ?? false,
      activityLog: activityLog,
      notes: map['notes'],
      attachmentIds: List<String>.from(map['attachmentIds'] as List<dynamic>? ?? []),
      completionNotes: map['completionNotes'],
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      acceptedAt: map['acceptedAt'] != null ? (map['acceptedAt'] as Timestamp).toDate() : null,
      reminderSentAt: map['reminderSentAt'] != null ? (map['reminderSentAt'] as Timestamp).toDate() : null,
      caseStatus: map['caseStatus'] ?? 'active',
    );
  }

  /// Create a copy of this consultation with updated fields
  ConsultationModel copyWith({
    String? id,
    String? caseId,
    String? requesterId,
    String? targetId,
    String? caseTitle,
    String? clientName,
    String? lawyerName,
    String? clientId,
    String? lawyerId,
    String? clientAvatar,
    String? lawyerAvatar,
    String? type,
    String? description,
    int? durationMinutes,
    String? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    String? location,
    String? meetingLink,
    String? meetingPlatform,
    String? rejectionReason,
    String? cancellationReason,
    String? cancellationRequestedBy,
    String? refundStatus,
    bool? penalized,
    List<CounterProposal>? counterProposals,
    bool? hasUnresolvedProposal,
    List<ConsultationActivity>? activityLog,
    String? notes,
    List<String>? attachmentIds,
    String? completionNotes,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? reminderSentAt,
    String? caseStatus,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      requesterId: requesterId ?? this.requesterId,
      targetId: targetId ?? this.targetId,
      caseTitle: caseTitle ?? this.caseTitle,
      clientName: clientName ?? this.clientName,
      lawyerName: lawyerName ?? this.lawyerName,
      clientId: clientId ?? this.clientId,
      lawyerId: lawyerId ?? this.lawyerId,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      lawyerAvatar: lawyerAvatar ?? this.lawyerAvatar,
      type: type ?? this.type,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationRequestedBy: cancellationRequestedBy ?? this.cancellationRequestedBy,
      refundStatus: refundStatus ?? this.refundStatus,
      penalized: penalized ?? this.penalized,
      counterProposals: counterProposals ?? this.counterProposals,
      hasUnresolvedProposal: hasUnresolvedProposal ?? this.hasUnresolvedProposal,
      activityLog: activityLog ?? this.activityLog,
      notes: notes ?? this.notes,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      completionNotes: completionNotes ?? this.completionNotes,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      reminderSentAt: reminderSentAt ?? this.reminderSentAt,
      caseStatus: caseStatus ?? this.caseStatus,
    );
  }

  /// Check if consultation is upcoming
  bool get isUpcoming => scheduledAt.isAfter(DateTime.now()) && (status == 'accepted' || status == 'pending');

  /// Check if consultation should have been held already
  bool get isPastDue => scheduledAt.isBefore(DateTime.now()) && status != 'completed' && status != 'cancelled';

  /// Calculate days until consultation
  int get daysUntilConsultation {
    return scheduledAt.difference(DateTime.now()).inDays;
  }

  /// Get formatted date and time string
  String get formattedDateTime {
    final day = scheduledAt.day;
    final month = scheduledAt.month;
    final year = scheduledAt.year;
    final hour = scheduledAt.hour.toString().padLeft(2, '0');
    final minute = scheduledAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year @ $hour:$minute';
  }
}
