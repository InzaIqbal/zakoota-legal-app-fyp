import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lawyer_ad_model.dart';

class LawyerAdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _adsRef =>
      _firestore.collection('lawyer_ads');

  Future<void> createAd(LawyerAdModel ad) async {
    await _adsRef.doc(ad.id).set(ad.toMap());
  }

  Future<void> updateAd(LawyerAdModel ad) async {
    await _adsRef.doc(ad.id).update(ad.toMap());
  }

  Future<void> deleteAd(String adId) async {
    await _adsRef.doc(adId).delete();
  }

  Future<void> setAdActive(String adId, bool isActive) async {
    await _adsRef.doc(adId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Pauses all currently active ads for a lawyer.
  Future<int> pauseAllActiveAdsForLawyer(String lawyerId) async {
    final activeAds = await _adsRef
        .where('lawyerId', isEqualTo: lawyerId)
        .where('isActive', isEqualTo: true)
        .get();

    if (activeAds.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    final now = Timestamp.fromDate(DateTime.now());

    for (final doc in activeAds.docs) {
      batch.update(doc.reference, {
        'isActive': false,
        'updatedAt': now,
      });
    }

    await batch.commit();
    return activeAds.docs.length;
  }

  Stream<List<LawyerAdModel>> streamMyAds(String lawyerId) {
    return _adsRef
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LawyerAdModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<LawyerAdModel>> searchActiveAds({
    String? category,
    String? query,
  }) async {
    Query<Map<String, dynamic>> q =
        _adsRef.where('isActive', isEqualTo: true).limit(100);

    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    final snapshot = await q.get();
    var ads = snapshot.docs
        .map((doc) => LawyerAdModel.fromMap(doc.data(), doc.id))
        .toList();

    if (query != null && query.trim().isNotEmpty) {
      final lower = query.trim().toLowerCase();
      ads = ads.where((ad) {
        return ad.title.toLowerCase().contains(lower) ||
            ad.description.toLowerCase().contains(lower) ||
            ad.lawyerName.toLowerCase().contains(lower) ||
            ad.category.toLowerCase().contains(lower);
      }).toList();
    }

    ads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return ads;
  }

  Future<LawyerAdModel?> getAdById(String adId) async {
    final doc = await _adsRef.doc(adId).get();
    if (!doc.exists || doc.data() == null) return null;
    return LawyerAdModel.fromMap(doc.data()!, doc.id);
  }

  /// Get count of active cases for a lawyer
  Future<int> getActiveCaseCount(String lawyerId) async {
    try {
      final snapshot = await _firestore
          .collection('cases')
          .where('acceptedLawyerId', isEqualTo: lawyerId)
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active case count: $e');
      return 0;
    }
  }

  /// Check case limit and auto-pause ads if needed
  Future<void> checkAndManageAdStatus(String lawyerId) async {
    try {
      final activeCaseCount = await getActiveCaseCount(lawyerId);

      if (activeCaseCount >= 5) {
        // Auto-pause all ads
        await pauseAdsDueToActiveCases(lawyerId);
      }
    } catch (e) {
      print('Error checking ad status: $e');
    }
  }

  /// Pause all ads for lawyer due to active case limit
  Future<List<String>> pauseAdsDueToActiveCases(String lawyerId) async {
    try {
      final snapshot = await _adsRef
          .where('lawyerId', isEqualTo: lawyerId)
          .where('isActive', isEqualTo: true)
          .get();

      final pausedAdIds = <String>[];
      final batch = _firestore.batch();
      final now = Timestamp.fromDate(DateTime.now());

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'pausedReason': 'case_limit_reached',
          'pausedAt': now,
          'updatedAt': now,
        });
        pausedAdIds.add(doc.id);
      }

      if (pausedAdIds.isNotEmpty) {
        await batch.commit();
      }

      return pausedAdIds;
    } catch (e) {
      print('Error pausing ads due to case limit: $e');
      return [];
    }
  }

  /// Check if lawyer can reactivate an ad (must have < 5 active cases)
  Future<bool> canReactivateAd(String adId, String lawyerId) async {
    try {
      final activeCaseCount = await getActiveCaseCount(lawyerId);
      return activeCaseCount < 5;
    } catch (e) {
      print('Error checking if can reactivate ad: $e');
      return false;
    }
  }

  /// Set ad active with case limit validation
  Future<void> setAdActiveWithValidation(
    String adId,
    bool isActive,
    String lawyerId,
  ) async {
    try {
      if (isActive) {
        // Check if lawyer can activate
        final canActivate = await canReactivateAd(adId, lawyerId);
        if (!canActivate) {
          throw AdActivationException(
            'Cannot activate ad: you have reached the maximum of 5 active cases',
          );
        }
      }

      await _adsRef.doc(adId).update({
        'isActive': isActive,
        'pausedReason': isActive ? null : 'manual_pause',
        if (!isActive) 'pausedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error setting ad active: $e');
      rethrow;
    }
  }
}

class AdActivationException implements Exception {
  final String message;
  AdActivationException(this.message);

  @override
  String toString() => message;
}
