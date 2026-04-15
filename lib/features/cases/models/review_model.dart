import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String? id;
  final String caseId;
  final String lawyerId;
  final String clientId;
  final Map<String, double> ratings; // qualityOfWork, budgetAdjustment, wayOfTalking, promptness, expertise
  final String description;
  final DateTime createdAt;

  ReviewModel({
    this.id,
    required this.caseId,
    required this.lawyerId,
    required this.clientId,
    required this.ratings,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'lawyerId': lawyerId,
      'clientId': clientId,
      'ratings': ratings,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      caseId: map['caseId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      clientId: map['clientId'] ?? '',
      ratings: Map<String, double>.from(map['ratings'] ?? {}),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    final total = ratings.values.reduce((a, b) => a + b);
    return total / ratings.length;
  }
}
