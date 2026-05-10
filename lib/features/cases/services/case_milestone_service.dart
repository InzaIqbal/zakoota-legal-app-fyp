import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/case_milestone_model.dart';

class CaseMilestoneService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _milestonesRef(String caseId) {
    return _firestore.collection('cases').doc(caseId).collection('milestones');
  }

  Stream<List<CaseMilestoneModel>> streamCaseMilestones(String caseId) {
    return _milestonesRef(caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CaseMilestoneModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createMilestone({
    required String caseId,
    required String title,
    required String details,
    DateTime? dueDate,
    double paymentAmount = 0.0,
    required String createdBy,
  }) async {
    final ref = _milestonesRef(caseId).doc();
    final now = DateTime.now();

    final milestone = CaseMilestoneModel(
      id: ref.id,
      caseId: caseId,
      title: title,
      details: details,
      status: 'pending',
      dueDate: dueDate,
      paymentAmount: paymentAmount,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(milestone.toMap());
  }

  Future<void> updateStatus({
    required String caseId,
    required String milestoneId,
    required String status,
  }) async {
    await _milestonesRef(caseId).doc(milestoneId).update({
      'status': status,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> markAsHeld({
    required String caseId,
    required String milestoneId,
    required String holdOperationId,
  }) async {
    await _milestonesRef(caseId).doc(milestoneId).update({
      'status': 'held',
      'holdOperationId': holdOperationId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> markAsReleased({
    required String caseId,
    required String milestoneId,
    required String releaseOperationId,
  }) async {
    await _milestonesRef(caseId).doc(milestoneId).update({
      'status': 'paid',
      'releaseOperationId': releaseOperationId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
