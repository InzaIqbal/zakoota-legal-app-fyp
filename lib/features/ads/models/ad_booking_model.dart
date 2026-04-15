import 'package:cloud_firestore/cloud_firestore.dart';

class AdBookingModel {
  final String id;
  final String adId;
  final String lawyerId;
  final String clientId;
  final double amount;
  final String paymentStatus;
  final String setupStatus;
  final String? caseId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdBookingModel({
    required this.id,
    required this.adId,
    required this.lawyerId,
    required this.clientId,
    required this.amount,
    required this.paymentStatus,
    required this.setupStatus,
    this.caseId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'amount': amount,
      'paymentStatus': paymentStatus,
      'setupStatus': setupStatus,
      'caseId': caseId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AdBookingModel.fromMap(Map<String, dynamic> map, String id) {
    return AdBookingModel(
      id: id,
      adId: map['adId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      clientId: map['clientId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentStatus: map['paymentStatus'] ?? 'pending',
      setupStatus: map['setupStatus'] ?? 'pending',
      caseId: map['caseId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
