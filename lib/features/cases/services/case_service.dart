import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/case_model.dart';
import 'consultation_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';

class CaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  Future<void> createCase({
    required String clientId,
    required String title,
    required String description,
    required String category,
    required String city,
    required double budgetMin,
    required double budgetMax,
    required String meetingPreference,
    required List<Map<String, dynamic>>
        attachments, // List of {file: File, title: String}
  }) async {
    try {
      final String caseId = _uuid.v4();
      List<CaseAttachment> caseAttachments = [];

      // 1. Upload attachments
      for (var attachment in attachments) {
        File file = attachment['file'] as File;
        String title = attachment['title'] as String;
        String fileName = file.path.split(Platform.pathSeparator).last;
        String extension = fileName.split('.').last;

        Reference ref = _storage.ref().child('cases/$caseId/$fileName');
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        caseAttachments.add(CaseAttachment(
          title: title,
          fileUrl: downloadUrl,
          fileType: extension,
        ));
      }

      // 2. Create Case Model
      final newCase = CaseModel(
        caseId: caseId,
        clientId: clientId,
        title: title,
        description: description,
        category: category,
        city: city,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        meetingPreference: meetingPreference,
        attachments: caseAttachments,
        status: 'open',
        proposalCount: 0,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore
      await _firestore.collection('cases').doc(caseId).set(newCase.toMap());

      await _notificationService.createForUser(
        userId: clientId,
        actorId: clientId,
        type: NotificationType.casePosted,
        title: 'Case posted successfully',
        message: 'Your case "$title" is now live for lawyers.',
        referenceType: 'case',
        referenceId: caseId,
        route: '/case-details/$caseId',
        payload: {'caseId': caseId},
      );
    } catch (e) {
      throw Exception('Failed to create case: $e');
    }
  }

  // Toggle Ad Visibility
  Future<void> toggleAdVisibility(String caseId, bool isVisible) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseId)
          .update({'isAdVisible': isVisible});
    } catch (e) {
      throw Exception('Failed to update ad visibility: $e');
    }
  }

  // Increment View Count
  Future<void> incrementViewCount(String caseId) async {
    try {
      await _firestore
          .collection('cases')
          .doc(caseId)
          .update({'viewsCount': FieldValue.increment(1)});
    } catch (e) {
      // Fail silently for analytics updates
    }
  }

  // Update Case with History
  Future<void> updateCase(
      String caseId, Map<String, dynamic> updates, CaseModel oldCase) async {
    try {
      // 1. Create History Record
      await _firestore
          .collection('cases')
          .doc(caseId)
          .collection('history')
          .add({
        'updatedAt': FieldValue.serverTimestamp(),
        'previousTitle': oldCase.title,
        'previousDescription': oldCase.description,
        'previousBudgetMin': oldCase.budgetMin,
        'previousBudgetMax': oldCase.budgetMax,
      });

      // 2. Update Main Doc
      await _firestore.collection('cases').doc(caseId).update(updates);
    } catch (e) {
      throw Exception('Failed to update case: $e');
    }
  }

  // Add Attachment
  Future<void> addAttachment(String caseId, File file, String title) async {
    try {
      String fileName =
          '${_uuid.v4()}_${file.path.split(Platform.pathSeparator).last}';
      String extension = fileName.split('.').last;

      Reference ref = _storage.ref().child('cases/$caseId/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      final newAttachment = CaseAttachment(
        title: title,
        fileUrl: downloadUrl,
        fileType: extension,
      );

      await _firestore.collection('cases').doc(caseId).update({
        'attachments': FieldValue.arrayUnion([newAttachment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to add attachment: $e');
    }
  }

  // Delete Attachment
  Future<void> deleteAttachment(
      String caseId, CaseAttachment attachment) async {
    try {
      // 1. Delete from Storage
      try {
        final ref = _storage.refFromURL(attachment.fileUrl);
        await ref.delete();
      } catch (e) {
        // Continue to delete from Firestore even if storage delete fails (e.g. file not found)
      }

      // 2. Remove from Firestore
      await _firestore.collection('cases').doc(caseId).update({
        'attachments': FieldValue.arrayRemove([attachment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  // Update Attachment Title
  Future<void> updateAttachmentTitle(
      String caseId, CaseAttachment attachment, String newTitle) async {
    try {
      final newAttachment = CaseAttachment(
        title: newTitle,
        fileUrl: attachment.fileUrl,
        fileType: attachment.fileType,
      );

      // Firestore array updates require removing the old complete object and adding the new one
      await _firestore.collection('cases').doc(caseId).update({
        'attachments': FieldValue.arrayRemove([attachment.toMap()]),
      });

      await _firestore.collection('cases').doc(caseId).update({
        'attachments': FieldValue.arrayUnion([newAttachment.toMap()]),
      });
    } catch (e) {
      throw Exception('Failed to update attachment title: $e');
    }
  }

  Stream<List<CaseModel>> getCasesForClient(String clientId) {
    return _firestore
        .collection('cases')
        .where('clientId', isEqualTo: clientId)
        .where('status', whereIn: ['open', 'active'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<CaseModel>> getCasesForLawyer(String lawyerId) {
    return _firestore
        .collection('cases')
        .where('acceptedLawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<CaseModel>> getCompletedCasesForClient(String clientId) {
    return _firestore
        .collection('cases')
        .where('clientId', isEqualTo: clientId)
        .where('status', isEqualTo: 'closed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<CaseModel>> getCompletedCasesForLawyer(String lawyerId) {
    return _firestore
        .collection('cases')
        .where('acceptedLawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: 'closed')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }


  Stream<List<CaseModel>> getOpenCases() {
    return _firestore
        .collection('cases')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CaseModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Signal Work Done (Lawyer)
  Future<void> signalWorkDone(String caseId) async {
    try {
      final caseDoc = await _firestore.collection('cases').doc(caseId).get();
      final data = caseDoc.data();

      await _firestore.collection('cases').doc(caseId).update({
        'workCompletionStatus': 'lawyer_signalled',
      });

      if (data != null) {
        final clientId = data['clientId'] as String?;
        if (clientId != null && clientId.isNotEmpty) {
          await _notificationService.createForUser(
            userId: clientId,
            actorId: data['acceptedLawyerId'] as String?,
            type: NotificationType.caseAssigned,
            title: 'Work completion submitted',
            message: 'Lawyer marked work as completed for your case.',
            referenceType: 'case',
            referenceId: caseId,
            route: '/case-details/$caseId',
            payload: {'caseId': caseId},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to signal work done: $e');
    }
  }

  // Verify Work (Client)
  Future<void> verifyWork(String caseId, bool isAccepted) async {
    try {
      final caseDoc = await _firestore.collection('cases').doc(caseId).get();
      final data = caseDoc.data();

      await _firestore.collection('cases').doc(caseId).update({
        'workCompletionStatus': isAccepted ? 'client_accepted' : 'client_rejected',
      });

      if (data != null) {
        final lawyerId = data['acceptedLawyerId'] as String?;
        if (lawyerId != null && lawyerId.isNotEmpty) {
          await _notificationService.createForUser(
            userId: lawyerId,
            actorId: data['clientId'] as String?,
            type: isAccepted
                ? NotificationType.consultationCompleted
                : NotificationType.proposalRejected,
            title: isAccepted ? 'Work approved by client' : 'Work changes requested',
            message: isAccepted
                ? 'Client approved your completed work.'
                : 'Client requested changes to your submitted work.',
            referenceType: 'case',
            referenceId: caseId,
            route: '/case-details/$caseId',
            payload: {'caseId': caseId},
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to verify work: $e');
    }
  }

  // Complete Case
  Future<void> completeCase(String caseId) async {
    try {
      final caseDoc = await _firestore.collection('cases').doc(caseId).get();
      final data = caseDoc.data();
      final clientId = data?['clientId'] as String?;
      final lawyerId = data?['acceptedLawyerId'] as String?;
      final agreedBudget = (data?['agreedBudget'] as num?)?.toDouble() ?? 0.0;

      // If case has agreed budget and both parties exist, transfer payment from client to lawyer
      if (agreedBudget > 0 && clientId != null && clientId.isNotEmpty && lawyerId != null && lawyerId.isNotEmpty) {
        final operationId = 'case_completion_${caseId}_${DateTime.now().millisecondsSinceEpoch}';

        // Atomic payment: debit client, credit lawyer, log both sides
        await _firestore.runTransaction((transaction) async {
          // Check client balance
          final clientDoc = await transaction.get(_firestore.collection('users').doc(clientId));
          final clientBalance = (clientDoc.get('walletBalance') as num?)?.toDouble() ?? 0.0;

          if (clientBalance < agreedBudget) {
            throw Exception('Insufficient balance to release payment. Available: PKR ${clientBalance.toStringAsFixed(2)}, Required: PKR ${agreedBudget.toStringAsFixed(2)}');
          }

          final newClientBalance = clientBalance - agreedBudget;
          final lawyerDoc = await transaction.get(_firestore.collection('users').doc(lawyerId));
          final lawyerBalance = (lawyerDoc.get('walletBalance') as num?)?.toDouble() ?? 0.0;
          final newLawyerBalance = lawyerBalance + agreedBudget;

          // Update both wallets
          transaction.update(_firestore.collection('users').doc(clientId), {
            'walletBalance': newClientBalance,
          });

          transaction.update(_firestore.collection('users').doc(lawyerId), {
            'walletBalance': newLawyerBalance,
          });

          // Log transaction for client (debit)
          transaction.set(
            _firestore.collection('users').doc(clientId).collection('wallet_transactions').doc(),
            {
              'type': 'case_completion_payment',
              'operationId': operationId,
              'amount': -agreedBudget,
              'previousBalance': clientBalance,
              'newBalance': newClientBalance,
              'description': 'Case completion payment released to lawyer',
              'otherParty': lawyerId,
              'caseId': caseId,
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'completed',
            },
          );

          // Log transaction for lawyer (credit)
          transaction.set(
            _firestore.collection('users').doc(lawyerId).collection('wallet_transactions').doc(),
            {
              'type': 'case_completion_payment',
              'operationId': operationId,
              'amount': agreedBudget,
              'previousBalance': lawyerBalance,
              'newBalance': newLawyerBalance,
              'description': 'Case completion payment received from client',
              'otherParty': clientId,
              'caseId': caseId,
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'completed',
            },
          );

          // Mark case as closed
          transaction.update(_firestore.collection('cases').doc(caseId), {
            'status': 'closed',
            'completedAt': FieldValue.serverTimestamp(),
          });
        });
      } else {
        // No payment needed, just close case
        await _firestore.collection('cases').doc(caseId).update({
          'status': 'closed',
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update associated consultations caseStatus
      await ConsultationService().updateConsultationCaseStatus(caseId, 'closed');

      if (data != null) {
        final notifications = <AppNotification>[];

        if (clientId != null && clientId.isNotEmpty) {
          notifications.add(
            AppNotification(
              id: '',
              userId: clientId,
              actorId: lawyerId,
              type: NotificationType.caseClosed,
              title: 'Case closed',
              message: agreedBudget > 0
                  ? 'Your case has been closed and payment of PKR ${agreedBudget.toStringAsFixed(2)} has been transferred to the lawyer.'
                  : 'Your case has been marked as closed.',
              referenceType: 'case',
              referenceId: caseId,
              route: '/case-details/$caseId',
              payload: {'caseId': caseId},
              createdAt: DateTime.now(),
            ),
          );
        }

        if (lawyerId != null && lawyerId.isNotEmpty) {
          notifications.add(
            AppNotification(
              id: '',
              userId: lawyerId,
              actorId: clientId,
              type: NotificationType.caseClosed,
              title: 'Case closed and payment received',
              message: agreedBudget > 0
                  ? 'Your case has been closed and you have received payment of PKR ${agreedBudget.toStringAsFixed(2)} from the client.'
                  : 'One of your assigned cases has been closed.',
              referenceType: 'case',
              referenceId: caseId,
              route: '/case-details/$caseId',
              payload: {'caseId': caseId},
              createdAt: DateTime.now(),
            ),
          );
        }

        if (notifications.isNotEmpty) {
          await _notificationService.createBatchNotifications(notifications);
        }
      }
    } catch (e) {
      throw Exception('Failed to complete case: $e');
    }
  }

  // Submit Review
  Future<void> submitReview(
      {required String caseId,
      required String lawyerId,
      required String clientId,
      required Map<String, double> ratings,
      required String description}) async {
    try {
      // 1. Save individual review document
      final reviewDoc = _firestore.collection('reviews').doc();
      await reviewDoc.set({
        'caseId': caseId,
        'lawyerId': lawyerId,
        'clientId': clientId,
        'ratings': ratings,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Calculate the mean of the new ratings
      double sum = 0;
      ratings.forEach((key, value) => sum += value);
      double reviewMean = sum / (ratings.isEmpty ? 1 : ratings.length);

      // 3. Fetch client's name for the review array
      final clientDoc = await _firestore.collection('users').doc(clientId).get();
      final clientName = clientDoc.data()?['fullName'] as String? ?? 'Client';

      // 4. Fetch lawyer's current profile for calculating new aggregate rating
      final lawyerDoc = await _firestore.collection('users').doc(lawyerId).get();
      final currentRating = (lawyerDoc.data()?['rating'] ?? 0.0).toDouble();
      final currentReviewsCount = (lawyerDoc.data()?['reviewsCount'] ?? 0).toInt();

      final newTotalScore = (currentRating * currentReviewsCount) + reviewMean;
      final newReviewsCount = currentReviewsCount + 1;
      final newRating = double.parse((newTotalScore / newReviewsCount).toStringAsFixed(1));

      // 5. Create review map for the lawyer's profile array
      final now = DateTime.now();
      final reviewObj = {
        'clientName': clientName,
        'rating': reviewMean,
        'comment': description,
        'date': '${now.day}/${now.month}/${now.year}'
      };

      // 6. Update lawyer's profile with new rating, count, and append the review
      await _firestore.collection('users').doc(lawyerId).update({
        'reviewsCount': newReviewsCount,
        'rating': newRating,
        'reviews': FieldValue.arrayUnion([reviewObj])
      });
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }
}
