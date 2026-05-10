import 'package:cloud_firestore/cloud_firestore.dart';

class CaseMilestoneModel {
  final String id;
  final String caseId;
  final String title;
  final String details;
  final String status;
  final DateTime? dueDate;
  final double paymentAmount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? holdOperationId;
  final String? releaseOperationId;

  const CaseMilestoneModel({
    required this.id,
    required this.caseId,
    required this.title,
    required this.details,
    required this.status,
    required this.dueDate,
    required this.paymentAmount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.holdOperationId,
    this.releaseOperationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'title': title,
      'details': details,
      'status': status,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paymentAmount': paymentAmount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'holdOperationId': holdOperationId,
      'releaseOperationId': releaseOperationId,
    };
  }

  factory CaseMilestoneModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseMilestoneModel(
      id: id,
      caseId: map['caseId'] ?? '',
      title: map['title'] ?? '',
      details: map['details'] ?? '',
      status: map['status'] ?? 'pending',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      paymentAmount: (map['paymentAmount'] as num?)?.toDouble() ?? 0.0,
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      holdOperationId: map['holdOperationId'] as String?,
      releaseOperationId: map['releaseOperationId'] as String?,
    );
  }
}
