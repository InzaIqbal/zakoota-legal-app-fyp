import 'package:cloud_firestore/cloud_firestore.dart';

class CaseAttachment {
  final String title;
  final String fileUrl;
  final String fileType;

  CaseAttachment({
    required this.title,
    required this.fileUrl,
    required this.fileType,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
    };
  }

  factory CaseAttachment.fromMap(Map<String, dynamic> map) {
    return CaseAttachment(
      title: map['title'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? 'unknown',
    );
  }
}

class CaseModel {
  final String caseId;
  final String clientId;
  final String title;
  final String description;
  final String category;
  final String city;
  final double budgetMin;
  final double budgetMax;
  final String meetingPreference; // 'in_person' or 'virtual'
  final List<CaseAttachment> attachments;
  final String status; // 'open', 'active', 'closed', 'cancelled'
  final int proposalCount;
  final DateTime createdAt;
  final bool isAdVisible;
  final int viewsCount;
  final int savesCount;
  final String? acceptedLawyerId; // New field
  final double? agreedBudget; // Lawyer's agreed budget from accepted proposal
  final String? budgetSource; // 'client' or 'lawyer' - indicates which budget is active
  final double? heldAmount; // Amount currently held in custody
  final String? paymentStatus; // 'none', 'held', 'released'
  final String? holdOperationId; // Wallet hold operation id for escrow
  final String? releaseOperationId; // Wallet release operation id for escrow
  final String? workCompletionStatus; // null, 'lawyer_signalled', 'client_accepted', 'client_rejected'
  final DateTime? completedAt;

  CaseModel({
    required this.caseId,
    required this.clientId,
    required this.title,
    required this.description,
    required this.category,
    required this.city,
    required this.budgetMin,
    required this.budgetMax,
    required this.meetingPreference,
    required this.attachments,
    required this.status,
    required this.proposalCount,
    required this.createdAt,
    this.isAdVisible = true,
    this.viewsCount = 0,
    this.savesCount = 0,
    this.acceptedLawyerId,
    this.agreedBudget,
    this.budgetSource,
    this.heldAmount,
    this.paymentStatus,
    this.holdOperationId,
    this.releaseOperationId,
    this.workCompletionStatus,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'clientId': clientId,
      'title': title,
      'description': description,
      'category': category,
      'city': city,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'meetingPreference': meetingPreference,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'status': status,
      'proposalCount': proposalCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAdVisible': isAdVisible,
      'viewsCount': viewsCount,
      'savesCount': savesCount,
      'acceptedLawyerId': acceptedLawyerId,
      'agreedBudget': agreedBudget,
      'budgetSource': budgetSource,
      'heldAmount': heldAmount,
      'paymentStatus': paymentStatus,
      'holdOperationId': holdOperationId,
      'releaseOperationId': releaseOperationId,
      'workCompletionStatus': workCompletionStatus,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory CaseModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseModel(
      caseId: id,
      clientId: map['clientId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      city: map['city'] ?? '',
      budgetMin: (map['budgetMin'] ?? 0).toDouble(),
      budgetMax: (map['budgetMax'] ?? 0).toDouble(),
      meetingPreference: map['meetingPreference'] ?? 'in_person',
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((x) => CaseAttachment.fromMap(x))
              .toList() ??
          [],
      status: map['status'] ?? 'open',
      proposalCount: map['proposalCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdVisible: map['isAdVisible'] ?? true,
      viewsCount: map['viewsCount'] ?? 0,
      savesCount: map['savesCount'] ?? 0,
      acceptedLawyerId: map['acceptedLawyerId'],
      agreedBudget: map['agreedBudget'] != null ? (map['agreedBudget'] as num).toDouble() : null,
      budgetSource: map['budgetSource'],
      heldAmount: map['heldAmount'] != null ? (map['heldAmount'] as num).toDouble() : null,
      paymentStatus: map['paymentStatus'],
      holdOperationId: map['holdOperationId'] as String?,
      releaseOperationId: map['releaseOperationId'] as String?,
      workCompletionStatus: map['workCompletionStatus'],
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  CaseModel copyWith({
    String? status,
    String? workCompletionStatus,
    DateTime? completedAt,
    String? acceptedLawyerId,
    double? agreedBudget,
    String? budgetSource,
    double? heldAmount,
    String? paymentStatus,
    String? holdOperationId,
    String? releaseOperationId,
  }) {
    return CaseModel(
      caseId: caseId,
      clientId: clientId,
      title: title,
      description: description,
      category: category,
      city: city,
      budgetMin: budgetMin,
      budgetMax: budgetMax,
      meetingPreference: meetingPreference,
      attachments: attachments,
      status: status ?? this.status,
      proposalCount: proposalCount,
      createdAt: createdAt,
      isAdVisible: isAdVisible,
      viewsCount: viewsCount,
      savesCount: savesCount,
      acceptedLawyerId: acceptedLawyerId ?? this.acceptedLawyerId,
      agreedBudget: agreedBudget ?? this.agreedBudget,
      budgetSource: budgetSource ?? this.budgetSource,
      heldAmount: heldAmount ?? this.heldAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      holdOperationId: holdOperationId ?? this.holdOperationId,
      releaseOperationId: releaseOperationId ?? this.releaseOperationId,
      workCompletionStatus: workCompletionStatus ?? this.workCompletionStatus,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
