import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerAdModel {
  final String id;
  final String lawyerId;
  final String lawyerName;
  final String title;
  final String description;
  final String category;
  final String pricingType;
  final double price;
  final String duration;
  final String locationMode;
  final List<String> requiredClientDocs;
  final bool isActive;
  final int views;
  final int bookings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LawyerAdModel({
    required this.id,
    required this.lawyerId,
    required this.lawyerName,
    required this.title,
    required this.description,
    required this.category,
    required this.pricingType,
    required this.price,
    required this.duration,
    required this.locationMode,
    required this.requiredClientDocs,
    required this.isActive,
    required this.views,
    required this.bookings,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'lawyerName': lawyerName,
      'title': title,
      'description': description,
      'category': category,
      'pricingType': pricingType,
      'price': price,
      'duration': duration,
      'locationMode': locationMode,
      'requiredClientDocs': requiredClientDocs,
      'isActive': isActive,
      'views': views,
      'bookings': bookings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory LawyerAdModel.fromMap(Map<String, dynamic> map, String id) {
    return LawyerAdModel(
      id: id,
      lawyerId: map['lawyerId'] ?? '',
      lawyerName: map['lawyerName'] ?? 'Lawyer',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      pricingType: map['pricingType'] ?? 'fixed',
      price: (map['price'] ?? 0).toDouble(),
      duration: map['duration'] ?? '',
      locationMode: map['locationMode'] ?? 'Remote',
      requiredClientDocs:
          List<String>.from(map['requiredClientDocs'] ?? const []),
      isActive: map['isActive'] ?? true,
      views: (map['views'] ?? 0).toInt(),
      bookings: (map['bookings'] ?? 0).toInt(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  LawyerAdModel copyWith({
    String? id,
    String? lawyerId,
    String? lawyerName,
    String? title,
    String? description,
    String? category,
    String? pricingType,
    double? price,
    String? duration,
    String? locationMode,
    List<String>? requiredClientDocs,
    bool? isActive,
    int? views,
    int? bookings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LawyerAdModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      lawyerName: lawyerName ?? this.lawyerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      pricingType: pricingType ?? this.pricingType,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      locationMode: locationMode ?? this.locationMode,
      requiredClientDocs: requiredClientDocs ?? this.requiredClientDocs,
      isActive: isActive ?? this.isActive,
      views: views ?? this.views,
      bookings: bookings ?? this.bookings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
