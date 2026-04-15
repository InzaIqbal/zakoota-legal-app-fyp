import 'package:cloud_firestore/cloud_firestore.dart';
import '../../cases/models/case_model.dart';

class LawyerCaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Active Cases for a Lawyer
  Stream<List<CaseModel>> getActiveCasesForLawyer(String lawyerId) {
    return _firestore
        .collection('cases')
        .where('acceptedLawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
