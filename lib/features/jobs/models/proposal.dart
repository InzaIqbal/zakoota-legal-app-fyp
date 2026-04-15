import 'package:cloud_firestore/cloud_firestore.dart';

class Proposal {
  final String id;
  final String lawyerId; // Added lawyerId
  final String lawyerName;
  final String lawyerImage;
  final double rating;
  final String location;
  final String coverLetter;
  final double bidAmount;
  final String duration;
  final DateTime createdAt;
  final String status; // 'pending', 'accepted', 'rejected'

  const Proposal({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.lawyerImage,
    required this.rating,
    required this.location,
    required this.coverLetter,
    required this.bidAmount,
    required this.duration,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'lawyerImage': lawyerImage,
      'rating': rating,
      'location': location,
      'coverLetter': coverLetter,
      'bidAmount': bidAmount,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory Proposal.fromMap(Map<String, dynamic> map, String id) {
    return Proposal(
      id: id,
      lawyerId: map['lawyerId'] ?? '',
      lawyerName: map['lawyerName'] ?? 'Unknown Lawyer',
      lawyerImage: map['lawyerImage'] ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=$id',
      rating: (map['rating'] ?? 0.0).toDouble(),
      location: map['location'] ?? 'Unknown',
      coverLetter: map['coverLetter'] ?? '',
      bidAmount: (map['bidAmount'] ?? 0.0).toDouble(),
      duration: map['duration'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
    );
  }
}
