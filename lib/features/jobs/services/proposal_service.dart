import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/proposal.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';
import '../../ads/services/lawyer_ad_service.dart';
import '../../wallet/services/wallet_service.dart';

class ProposalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final WalletService _walletService = WalletService();

  // Submit a Proposal
  Future<void> submitProposal({
    required String caseId,
    required String lawyerId,
    required String lawyerName,
    required String lawyerImage,
    required double rating,
    required String location,
    required String coverLetter,
    required double bidAmount,
    required String duration,
  }) async {
    final proposalRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(lawyerId); // Use lawyerId as doc ID to enforce uniqueness

    final docSnapshot = await proposalRef.get();
    if (docSnapshot.exists) {
      throw Exception('You have already submitted a proposal for this job.');
    }

    final proposalData = Proposal(
      id: proposalRef.id,
      lawyerId: lawyerId,
      lawyerName: lawyerName,
      lawyerImage: lawyerImage,
      rating: rating,
      location: location,
      coverLetter: coverLetter,
      bidAmount: bidAmount,
      duration: duration,
      createdAt: DateTime.now(),
    ).toMap();

    // Use a batch or transaction if you want to update proposal count atomically
    // For simplicity and scalability, incrementing count via FieldValue.increment is robust
    final batch = _firestore.batch();

    // 1. Add Proposal to Subcollection
    batch.set(proposalRef, proposalData);

    // 2. Increment Proposal Count on Case Document
    final caseRef = _firestore.collection('cases').doc(caseId);
    batch.update(caseRef, {
      'proposalCount': FieldValue.increment(1),
      // Extendable: Add 'lastActivity' timestamp to case for sorting recently active jobs
      'lastActivity': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    final caseDoc = await _firestore.collection('cases').doc(caseId).get();
    final clientId = caseDoc.data()?['clientId'] as String?;
    if (clientId != null && clientId.isNotEmpty) {
      await _notificationService.createForUser(
        userId: clientId,
        actorId: lawyerId,
        type: NotificationType.proposalReceived,
        title: 'New proposal received',
        message: '$lawyerName submitted a proposal on your case.',
        referenceType: 'case',
        referenceId: caseId,
        route: '/case-details/$caseId',
        payload: {'caseId': caseId, 'lawyerId': lawyerId},
      );
    }

    await _notificationService.createForUser(
      userId: lawyerId,
      actorId: lawyerId,
      type: NotificationType.proposalSubmitted,
      title: 'Proposal submitted',
      message: 'Your proposal was sent successfully.',
      referenceType: 'case',
      referenceId: caseId,
      route: '/case-details/$caseId',
      payload: {'caseId': caseId},
    );
  }

  // Delete a Proposal
  Future<void> deleteProposal(String caseId, String proposalId) async {
    final batch = _firestore.batch();

    // 1. Delete Proposal
    final proposalRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(proposalId);
    batch.delete(proposalRef);

    // 2. Decrement Proposal Count
    final caseRef = _firestore.collection('cases').doc(caseId);
    batch.update(caseRef, {
      'proposalCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  // Update a Proposal
  Future<void> updateProposal({
    required String caseId,
    required String proposalId,
    required String coverLetter,
    required double bidAmount,
    required String duration,
  }) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(proposalId)
        .update({
      'coverLetter': coverLetter,
      'bidAmount': bidAmount,
      'duration': duration,
      // strictly speaking, we might not want to update createdAt
    });
  }

  // Get Proposals for a Case (Stream) with Sorting
  Stream<List<Proposal>> getProposalsForCase(String caseId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .snapshots()
        .map((snapshot) {
      final proposals = snapshot.docs.map((doc) {
        return Proposal.fromMap(doc.data(), doc.id);
      }).toList();

      // Custom Sort: Accepted > Pending > Rejected, then by Date (Newest first)
      proposals.sort((a, b) {
        // 1. Status Priority
        final statusPriorityA = _getStatusPriority(a.status);
        final statusPriorityB = _getStatusPriority(b.status);

        if (statusPriorityA != statusPriorityB) {
          return statusPriorityA.compareTo(statusPriorityB);
        }

        // 2. Date Priority (Newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

      return proposals;
    });
  }

  int _getStatusPriority(String status) {
    switch (status) {
      case 'accepted':
        return 0; // Top
      case 'pending':
        return 1; // Middle
      case 'rejected':
        return 2; // Bottom
      default:
        return 3;
    }
  }

  // Accept a Proposal (and reject others)
  Future<void> acceptProposal(String caseId, String proposalId) async {
    final proposalsRef =
        _firestore.collection('cases').doc(caseId).collection('proposals');

    // 1. Get all proposals for this case
    final querySnapshot = await proposalsRef.get();
    
    // Get the accepted proposal data to extract lawyer's budget
    Proposal? acceptedProposal;
    for (var doc in querySnapshot.docs) {
      if (doc.id == proposalId) {
        acceptedProposal = Proposal.fromMap(doc.data(), doc.id);
        break;
      }
    }

    if (acceptedProposal == null) {
      throw Exception('Proposal not found');
    }

    final acceptedLawyerId = _getLawyerIdFromProposal(querySnapshot, proposalId);
    if (acceptedLawyerId.isEmpty) {
      throw Exception('Lawyer not found for selected proposal');
    }

    final caseRef = _firestore.collection('cases').doc(caseId);
    final caseDoc = await caseRef.get();
    final caseData = caseDoc.data();
    final clientId = caseData?['clientId'] as String?;
    if (clientId == null || clientId.isEmpty) {
      throw Exception('Client not found for this case');
    }

    final holdAmount = acceptedProposal.bidAmount;
    final holdOperationId = 'proposal_accept_${caseId}_$proposalId';

    await _walletService.holdFunds(
      userId: clientId,
      amount: holdAmount,
      operationId: holdOperationId,
      reason: 'proposal_acceptance_hold',
      referenceType: 'case_proposal',
      referenceId: proposalId,
      metadata: {
        'caseId': caseId,
        'proposalId': proposalId,
        'lawyerId': acceptedLawyerId,
      },
    );

    final batch = _firestore.batch();

    for (var doc in querySnapshot.docs) {
      if (doc.id == proposalId) {
        // Accept the target proposal
        batch.update(doc.reference, {'status': 'accepted'});
      } else {
        // Reject all other proposals
        batch.update(doc.reference, {'status': 'rejected'});
      }
    }

    // 2. Update Case status, acceptedLawyerId, and lawyer's agreed budget
    batch.update(caseRef, {
      'status': 'active', // Changed from 'open' to 'active'
      'acceptedLawyerId': acceptedLawyerId,
      'agreedBudget': holdAmount, // Store lawyer's agreed budget
      'budgetSource': 'lawyer', // Mark that budget is from lawyer's proposal, not client
      'heldAmount': holdAmount,
      'paymentStatus': 'held',
      'holdOperationId': holdOperationId,
    });

    await batch.commit();

    // 3. Check and manage ad status based on case limit
    try {
      final lawyerAdService = LawyerAdService();
      await lawyerAdService.checkAndManageAdStatus(acceptedLawyerId);
    } catch (e) {
      print('Error checking ad status: $e');
    }

    if (acceptedLawyerId.isNotEmpty) {
      await _notificationService.createForUser(
        userId: acceptedLawyerId,
        actorId: clientId,
        type: NotificationType.proposalAccepted,
        title: 'Proposal accepted',
        message: 'Your proposal has been accepted. Case is now active.',
        referenceType: 'case',
        referenceId: caseId,
        route: '/case-details/$caseId',
        payload: {'caseId': caseId},
      );
    }
  }

  String _getLawyerIdFromProposal(QuerySnapshot snapshot, String proposalId) {
    try {
      final doc = snapshot.docs.firstWhere((doc) => doc.id == proposalId);
      return doc['lawyerId'] as String;
    } catch (e) {
      return '';
    }
  }

  // Reject a Proposal
  Future<void> rejectProposal(String caseId, String proposalId) async {
    final proposalDoc = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(proposalId)
        .get();

    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(proposalId)
        .update({'status': 'rejected'});

    final lawyerId = proposalDoc.data()?['lawyerId'] as String?;
    final clientId = (await _firestore.collection('cases').doc(caseId).get())
        .data()?['clientId'] as String?;

    if (lawyerId != null && lawyerId.isNotEmpty) {
      await _notificationService.createForUser(
        userId: lawyerId,
        actorId: clientId,
        type: NotificationType.proposalRejected,
        title: 'Proposal not selected',
        message: 'Your proposal was not selected for this case.',
        referenceType: 'case',
        referenceId: caseId,
        route: '/case-details/$caseId',
        payload: {'caseId': caseId},
      );
    }
  }

  // Un-reject a Proposal (Undo Rejection)
  Future<void> unrejectProposal(String caseId, String proposalId) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('proposals')
        .doc(proposalId)
        .update({'status': 'pending'});
  }
}
