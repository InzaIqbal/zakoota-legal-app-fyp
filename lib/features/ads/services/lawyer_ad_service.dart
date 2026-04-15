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
}
