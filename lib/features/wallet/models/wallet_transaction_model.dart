import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTxType { credit, debit }

class WalletTransactionModel {
  final String id;
  final String operationId;
  final String userId;
  final WalletTxType type;
  final String reason;
  final double amount;
  final String currency;
  final String status;
  final String? method;
  final String? counterpartyUserId;
  final String? referenceType;
  final String? referenceId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.operationId,
    required this.userId,
    required this.type,
    required this.reason,
    required this.amount,
    required this.currency,
    required this.status,
    this.method,
    this.counterpartyUserId,
    this.referenceType,
    this.referenceId,
    this.metadata = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationId': operationId,
      'userId': userId,
      'type': type.name,
      'reason': reason,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
      'counterpartyUserId': counterpartyUserId,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return WalletTransactionModel(
      id: id,
      operationId: (map['operationId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      type: (map['type'] ?? 'debit').toString() == 'credit'
          ? WalletTxType.credit
          : WalletTxType.debit,
      reason: (map['reason'] ?? '').toString(),
      amount: (map['amount'] ?? 0).toDouble(),
      currency: (map['currency'] ?? 'PKR').toString(),
      status: (map['status'] ?? 'completed').toString(),
      method: map['method']?.toString(),
      counterpartyUserId: map['counterpartyUserId']?.toString(),
      referenceType: map['referenceType']?.toString(),
      referenceId: map['referenceId']?.toString(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? const {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
