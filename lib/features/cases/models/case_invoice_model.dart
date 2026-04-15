import 'package:cloud_firestore/cloud_firestore.dart';

class CaseInvoiceModel {
  final String id;
  final String caseId;
  final String title;
  final String notes;
  final double amount;
  final String currency;
  final String status;
  final String payerId;
  final String payeeId;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseInvoiceModel({
    required this.id,
    required this.caseId,
    required this.title,
    required this.notes,
    required this.amount,
    required this.currency,
    required this.status,
    required this.payerId,
    required this.payeeId,
    required this.dueDate,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'title': title,
      'notes': notes,
      'amount': amount,
      'currency': currency,
      'status': status,
      'payerId': payerId,
      'payeeId': payeeId,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CaseInvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseInvoiceModel(
      id: id,
      caseId: map['caseId'] ?? '',
      title: map['title'] ?? '',
      notes: map['notes'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'PKR',
      status: map['status'] ?? 'pending',
      payerId: map['payerId'] ?? '',
      payeeId: map['payeeId'] ?? '',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
