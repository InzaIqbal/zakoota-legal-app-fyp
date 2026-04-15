import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/lawyer_mock_data.dart';

class LawyerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<LawyerProfile>? _cachedLawyers;
  DateTime? _cacheTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Fetch all verified and active lawyers from Firestore
  Future<List<LawyerProfile>> fetchAllLawyers() async {
    try {
      // Check cache
      if (_cachedLawyers != null && _cacheTime != null) {
        final elapsed = DateTime.now().difference(_cacheTime!);
        if (elapsed < _cacheDuration) {
          debugPrint('Using cached lawyers (${_cachedLawyers!.length} lawyers)');
          return _cachedLawyers!;
        }
      }

      // Query all users with role 'lawyer'
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'lawyer')
          .limit(100)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Firestore query timeout');
              throw Exception('Database query timeout');
            },
          );

      final List<LawyerProfile> lawyers = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final lawyer = _documentToLawyerProfile(doc.id, data);
          
          // Only include active, strictly verified, and currently accepting lawyers.
          if (lawyer.accountStatus == 'active' && 
              lawyer.verificationStatus == 'approved' &&
              lawyer.isAcceptingCases) {
            lawyers.add(lawyer);
          }
        } catch (e) {
          debugPrint('Error parsing lawyer document ${doc.id}: $e');
          continue;
        }
      }

      // Cache the results
      _cachedLawyers = lawyers;
      _cacheTime = DateTime.now();

      debugPrint('Fetched ${lawyers.length} verified/active lawyers from Firestore');
      return lawyers;
    } catch (e) {
      debugPrint('Error fetching lawyers from Firestore: $e');
      // Return cached data if available
      if (_cachedLawyers != null) {
        debugPrint('Returning cached lawyers (${_cachedLawyers!.length}) due to error');
        return _cachedLawyers!;
      }
      return [];
    }
  }

  /// Clear cache when needed
  void clearCache() {
    _cachedLawyers = null;
    _cacheTime = null;
  }

  /// Search and filter lawyers
  Future<List<LawyerProfile>> searchLawyers({
    String? category,
    String? query,
    bool verifiedOnly = false,
    double? minRating,
  }) async {
    try {
      List<LawyerProfile> lawyers = await fetchAllLawyers();
      debugPrint('Total verified/active lawyers: ${lawyers.length}');

      if (lawyers.isEmpty) {
        debugPrint('No lawyers found in database');
        return [];
      }

      // Filter by query
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        lawyers = lawyers
            .where((lawyer) =>
                lawyer.fullName.toLowerCase().contains(lowerQuery) ||
                lawyer.specializations.any((spec) =>
                    spec.toLowerCase().contains(lowerQuery)) ||
                lawyer.professionalHeading.toLowerCase().contains(lowerQuery))
            .toList();
        debugPrint('After query filter: ${lawyers.length}');
      }

      // Optional explicit verified filter.
      if (verifiedOnly) {
        lawyers = lawyers.where((lawyer) => lawyer.isVerified).toList();
      }

      // Filter by category (using specializations)
      if (category != null && category.isNotEmpty) {
        lawyers = lawyers
            .where((lawyer) =>
                lawyer.specializations
                    .any((spec) => spec.equalsIgnoreCase(category)))
            .toList();
        debugPrint('After category filter: ${lawyers.length}');
      }

      // Filter by minimum rating
      if (minRating != null) {
        lawyers = lawyers
            .where((lawyer) => lawyer.ratingDouble >= minRating)
            .toList();
        debugPrint('After rating filter: ${lawyers.length}');
      }

      debugPrint('✓ Final result: ${lawyers.length} lawyers');
      for (var lawyer in lawyers) {
        debugPrint(
            '  - ${lawyer.fullName} (Status: ${lawyer.verificationStatus}, Account: ${lawyer.accountStatus})');
      }

      return lawyers;
    } catch (e) {
      debugPrint('Error searching lawyers: $e');
      return [];
    }
  }

  /// Get lawyer by ID
  Future<LawyerProfile?> getLawyerById(String id) async {
    try {
      debugPrint('LawyerService: Fetching lawyer profile for ID: $id');
      
      DocumentSnapshot? doc;
      try {
        doc = await _firestore.collection('lawyers').doc(id).get();
      } catch (e) {
        debugPrint('LawyerService: Could not read from "lawyers" collection ($e). Proceeding to fallback.');
      }

      if (doc == null || !doc.exists) {
        debugPrint('LawyerService: Not found in "lawyers" collection. Checking "users" fallback...');
        
        DocumentSnapshot? userDoc;
        try {
          userDoc = await _firestore.collection('users').doc(id).get();
        } catch (e) {
          debugPrint('LawyerService: CRITICAL - "users" collection threw error: $e');
          throw Exception('Security Rules blocked reading the profile. Please update Firebase Console Rules!');
        }

        if (userDoc.exists) {
          debugPrint('LawyerService: Found in "users" collection. Mapping data...');
          final userData = userDoc.data() as Map<String, dynamic>;
          return _documentToLawyerProfile(userDoc.id, userData);
        }

        debugPrint('LawyerService: Not found in "users". Trying mock data fallback...');
        // Try mock data as final fallback
        try {
          final mockLawyer = LawyerMockData.lawyers
              .firstWhere((lawyer) => lawyer.id == id);
          debugPrint('LawyerService: Found in mock data.');
          return mockLawyer;
        } catch (mockError) {
          debugPrint('LawyerService: Not found in mock data either.');
          throw Exception('Document ID $id does not exist in lawyers, users, or mock data.');
        }
      }

      debugPrint('LawyerService: Found in "lawyers" collection.');
      return _documentToLawyerProfile(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('LawyerService: CRITICAL ERROR getting lawyer by id ($id): $e');
      rethrow;
    }
  }

  /// Fetch actual reviews from the `reviews` collection dynamically
  Future<Map<String, dynamic>> getLawyerReviews(String lawyerId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('lawyerId', isEqualTo: lawyerId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return {
          'reviews': <LawyerReview>[],
          'rating': 0.0,
          'count': 0,
        };
      }

      double totalRating = 0.0;
      List<LawyerReview> resultReviews = [];

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        final clientId = data['clientId'] as String?;
        final description = data['description'] as String? ?? '';
        final ratings = data['ratings'] as Map<String, dynamic>? ?? {};
        final createdAt = data['createdAt'] as Timestamp?;

        // Calculate mean rating for this review
        double sum = 0.0;
        ratings.forEach((k, v) => sum += (v as num).toDouble());
        double reviewMean =
            ratings.isEmpty ? 5.0 : sum / ratings.length; // Default to 5.0 if ratings map empty
        
        totalRating += reviewMean;

        // Fetch client name
        String clientName = 'Client';
        if (clientId != null) {
           final clientDoc = await _firestore.collection('users').doc(clientId).get();
           if (clientDoc.exists) {
              clientName = clientDoc.data()?['fullName'] as String? ?? 'Client';
           }
        }

        // Format Date
        String dateString = '';
        if (createdAt != null) {
          final date = createdAt.toDate();
          dateString = '${date.day}/${date.month}/${date.year}';
        } else {
          final now = DateTime.now();
          dateString = '${now.day}/${now.month}/${now.year}';
        }

        resultReviews.add(
          LawyerReview(
            clientName: clientName,
            rating: reviewMean,
            comment: description,
            date: dateString,
          )
        );
      }
      
      // Sort newest first if there are any timestamps, conceptually let's just return list
      return {
        'reviews': resultReviews,
        'rating': totalRating / reviewsSnapshot.docs.length,
        'count': reviewsSnapshot.docs.length,
      };
    } catch (e) {
      debugPrint('LawyerService: Error fetching raw reviews: $e');
      return {
        'reviews': <LawyerReview>[],
        'rating': 0.0,
        'count': 0,
      };
    }
  }

  /// Convert Firestore document to LawyerProfile
  LawyerProfile _documentToLawyerProfile(
      String id, Map<String, dynamic> data) {
    try {
      return LawyerProfile(
        id: id,
        fullName: data['fullName'] ?? '',
        professionalHeading: data['professionalHeading'] ?? '',
        location: data['location'] ?? '',
        photoUrl: data['photoUrl'] ?? 'https://i.pravatar.cc/150?img=1',
        specializations: List<String>.from(data['specializations'] ?? []),
        experienceYears: (data['experienceYears'] ?? 0) is String 
            ? int.tryParse(data['experienceYears']) ?? 0
            : (data['experienceYears'] ?? 0).toInt(),
        rating: (data['rating'] ?? 0.0).toDouble(),
        reviewsCount: (data['reviewsCount'] ?? 0).toInt(),
        hourlyRate: (data['hourlyRate'] ?? data['consultationRate'] ?? 0.0).toDouble(),
        verificationStatus: data['verificationStatus'] ?? 'pending',
        accountStatus: data['accountStatus'] ?? ((data['isActive'] ?? true) ? 'active' : 'inactive'),
        isAcceptingCases: data['isAcceptingCases'] ?? true,
        education: data['education'] is String
            ? [data['education']]
            : List<String>.from(data['education'] ?? []),
        barLicenseNo: data['barLicenseNo'] ?? '',
        bio: data['bio'] ?? data['aboutMe'] ?? '',
        reviews: (data['reviews'] as List?)
                ?.map((review) {
                  if (review is Map<String, dynamic>) {
                    return LawyerReview(
                      clientName: review['clientName'] ?? '',
                      rating: (review['rating'] ?? 0.0).toDouble(),
                      comment: review['comment'] ?? '',
                      date: review['date'] ?? '',
                    );
                  }
                  return null;
                })
                .whereType<LawyerReview>()
                .toList() ??
            [],
      );
    } catch (e) {
      debugPrint('LawyerService: Error mapping document $id: $e');
      debugPrint('LawyerService: Raw data: $data');
      rethrow;
    }
  }

  /// Applies a hard penalty to the Lawyer for directly cancelling a consultation
  Future<void> applyCancellationPenalty(String lawyerId) async {
    try {
      // 1. Inject a 1-star system review into the `reviews` collection
      await _firestore.collection('reviews').add({
        'lawyerId': lawyerId,
        'clientId': 'SYSTEM',
        'description': 'Automated Penalty: The lawyer abruptly cancelled a scheduled consultation.',
        'ratings': {
          'reliability': 1.0,
          'professionalism': 1.0,
        },
        'createdAt': Timestamp.now(),
      });

      // 2. Increment their cancelled jobs count in their profile for job completion metrics
      await _firestore.collection('users').doc(lawyerId).set({
        'cancelledJobsCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('Applied cancellation penalty to lawyer $lawyerId');
    } catch (e) {
      debugPrint('Failed to apply cancellation penalty: $e');
    }
  }
}

extension StringExtension on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}
