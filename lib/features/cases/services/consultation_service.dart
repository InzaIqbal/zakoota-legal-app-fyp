import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_model.dart';
import '../../events/models/event_model.dart';
import '../../events/services/event_service.dart';
import 'dart:async';
import '../../chat/services/chat_service.dart';
import '../../chat/models/message_model.dart';
import '../../lawyers/services/lawyer_service.dart';
import '../../notifications/models/notification_model.dart';
import '../../notifications/services/notification_service.dart';

class ConsultationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ===================== CRUD Operations =====================

  /// Create a consultation request
  Future<void> requestConsultation(ConsultationModel consultation, String requesterName, String requesterRole) async {
    final activity = ConsultationActivity(
      id: _firestore.collection('tmp').doc().id,
      userId: consultation.requesterId,
      userName: requesterName,
      userRole: requesterRole,
      action: 'created',
      timestamp: DateTime.now(),
    );

    // Fetch current case status
    final caseDoc = await _firestore.collection('cases').doc(consultation.caseId).get();
    final currentCaseStatus = caseDoc.exists ? (caseDoc.data()?['status'] ?? 'active') : 'active';

    final updatedConsultation = consultation.copyWith(
      activityLog: [activity],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      caseStatus: currentCaseStatus,
    );

    await _firestore
        .collection('cases')
        .doc(consultation.caseId)
        .collection('consultations')
        .doc(consultation.id)
        .set(updatedConsultation.toMap());

    await _notificationService.createForUser(
      userId: consultation.targetId,
      actorId: consultation.requesterId,
      type: NotificationType.consultationRequested,
      title: 'New consultation request',
      message: '$requesterName requested a consultation.',
      referenceType: 'consultation',
      referenceId: consultation.id,
      route: '/case-details/${consultation.caseId}',
      payload: {
        'caseId': consultation.caseId,
        'consultationId': consultation.id,
      },
    );
  }

  /// Get a specific consultation
  Future<ConsultationModel?> getConsultation(String caseId, String consultationId) async {
    final doc = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .get();

    if (!doc.exists) return null;
    return ConsultationModel.fromMap(doc.data()!, doc.id);
  }

  /// Update consultation with new details and log activity
  Future<void> updateConsultation(ConsultationModel updated, String userId, String userName, String userRole) async {
    final oldDoc = await _firestore
        .collection('cases')
        .doc(updated.caseId)
        .collection('consultations')
        .doc(updated.id)
        .get();
    
    if (!oldDoc.exists) return;
    final old = ConsultationModel.fromMap(oldDoc.data()!, oldDoc.id);

    List<ConsultationActivity> newActivities = [...old.activityLog];
    
    // Check for changes and log
    if (updated.scheduledAt != old.scheduledAt) {
      newActivities.add(ConsultationActivity(
        id: _firestore.collection('tmp').doc().id,
        userId: userId,
        userName: userName,
        userRole: userRole,
        action: 'updated_time',
        previousValue: old.scheduledAt.toString(),
        newValue: updated.scheduledAt.toString(),
        timestamp: DateTime.now(),
      ));
    }

    if (updated.location != old.location || updated.meetingLink != old.meetingLink) {
      newActivities.add(ConsultationActivity(
        id: _firestore.collection('tmp').doc().id,
        userId: userId,
        userName: userName,
        userRole: userRole,
        action: 'updated_location',
        previousValue: old.type == 'video' ? old.meetingLink : old.location,
        newValue: updated.type == 'video' ? updated.meetingLink : updated.location,
        timestamp: DateTime.now(),
      ));
    }

    if (updated.type != old.type) {
      newActivities.add(ConsultationActivity(
        id: _firestore.collection('tmp').doc().id,
        userId: userId,
        userName: userName,
        userRole: userRole,
        action: 'updated_type',
        previousValue: old.type,
        newValue: updated.type,
        timestamp: DateTime.now(),
      ));
    }

    await _firestore
        .collection('cases')
        .doc(updated.caseId)
        .collection('consultations')
        .doc(updated.id)
        .update({
          ...updated.toMap(),
          'activityLog': newActivities.map((e) => e.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });
  }

  /// Delete a consultation (only for pending/rejected ones)
  Future<void> deleteConsultation(String caseId, String consultationId) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .delete();
  }

  // ===================== Status Management =====================

  /// Helper to log status change activity
  Future<void> _logStatusActivity(
    String caseId, 
    String consultationId, 
    String userId, 
    String userName, 
    String userRole,
    String action, 
    {String? reason}
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);
    
    final doc = await docRef.get();
    if (!doc.exists) return;
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    final activity = ConsultationActivity(
      id: _firestore.collection('tmp').doc().id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      action: action,
      newValue: reason,
      timestamp: DateTime.now(),
    );

    await docRef.update({
      'activityLog': [...consultation.activityLog.map((e) => e.toMap()), activity.toMap()],
      'updatedAt': Timestamp.now(),
    });
  }

  /// Accept a consultation request
  Future<void> acceptConsultation(String caseId, String consultationId, String userId, String userName, String userRole, {String? location}) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    if (!doc.exists) return;
    
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    final updateData = <String, dynamic>{
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'hasUnresolvedProposal': false,
    };

    if (location != null && location.isNotEmpty) {
      updateData['location'] = location;
    }

    await docRef.update(updateData);
    
    await _logStatusActivity(caseId, consultationId, userId, userName, userRole, 'accepted');

    // Create a global Event for the timeline
    try {
      final String subtitle = caseId == 'standalone' ? 'Direct Consultation' : 'Case #$caseId';
      final event = EventModel(
        id: consultationId, // Tie event ID 1:1 with consultation
        type: 'consultation',
        title: 'Consultation: ${consultation.description}',
        subtitle: subtitle,
        caseId: consultation.caseId,
        referenceId: consultationId,
        participants: [consultation.requesterId, consultation.targetId],
        scheduledAt: consultation.scheduledAt,
        status: 'upcoming',
      );
      await EventService().createEvent(event);
    } catch (e) {
      print('Failed to create global event for consultation: $e');
    }

    try {
      final chatService = ChatService();
      final chat = await chatService.getOrCreateChat(
        clientId: consultation.clientId,
        lawyerId: consultation.lawyerId,
        clientName: consultation.clientName ?? 'Client',
        lawyerName: consultation.lawyerName ?? 'Lawyer',
        clientAvatar: consultation.clientAvatar,
        lawyerAvatar: consultation.lawyerAvatar,
      );

      final message = MessageModel(
        id: '', 
        senderId: userId,
        text: 'Consultation accepted! Topic: ${consultation.description}',
        timestamp: DateTime.now(),
        type: 'consultation_accepted',
        metadata: {
          'consultationId': consultation.id,
          'topic': consultation.description,
          'meetingType': consultation.type,
          'date': consultation.scheduledAt.toIso8601String(),
          'location': location ?? consultation.location,
        },
      );

      await chatService.sendMessage(chat.id, message, true);
    } catch (e) {
      // Ignore chat errors so accept still completes
    }

    await _notificationService.createForUser(
      userId: consultation.requesterId,
      actorId: consultation.targetId,
      type: NotificationType.consultationAccepted,
      title: 'Consultation accepted',
      message: 'Your consultation request was accepted.',
      referenceType: 'consultation',
      referenceId: consultation.id,
      route: '/case-details/$caseId',
      payload: {'caseId': caseId, 'consultationId': consultation.id},
    );
  }

  /// Reject a consultation with optional reason
  Future<void> rejectConsultation(
      String caseId, String consultationId, String userId, String userName, String userRole, String? reason) async {
    final consultationDoc = await _firestore
      .collection('cases')
      .doc(caseId)
      .collection('consultations')
      .doc(consultationId)
      .get();

    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': 'rejected',
          'rejectionReason': reason,
          'updatedAt': Timestamp.now(),
        });
    
    await _logStatusActivity(caseId, consultationId, userId, userName, userRole, 'rejected', reason: reason);

    // Cancel dynamic event if present
    try {
      await EventService().updateEvent(consultationId, {'status': 'cancelled'});
    } catch (e) {}

    final consultation = consultationDoc.exists
        ? ConsultationModel.fromMap(consultationDoc.data()!, consultationDoc.id)
        : null;

    if (consultation != null) {
      await _notificationService.createForUser(
        userId: consultation.requesterId,
        actorId: consultation.targetId,
        type: NotificationType.consultationRejected,
        title: 'Consultation request declined',
        message: reason != null && reason.isNotEmpty
            ? 'Reason: $reason'
            : 'Your consultation request was declined.',
        referenceType: 'consultation',
        referenceId: consultation.id,
        route: '/case-details/$caseId',
        payload: {'caseId': caseId, 'consultationId': consultation.id},
      );
    }
  }

  /// Client requests cancellation (Requires Lawyer approval for refund)
  Future<void> requestCancellation(
      ConsultationModel consultation, String userId, String userName, String? reason) async {
    if (consultation.status == 'cancellation_requested' || consultation.status == 'cancelled') {
        return; // Already handled
    }
    
    final caseId = consultation.caseId;
    final consultationId = consultation.id;
    
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': 'cancellation_requested',
          'cancellationRequestedBy': userId,
          'cancellationReason': reason,
          'updatedAt': Timestamp.now(),
        });
    
    await _logStatusActivity(caseId, consultationId, userId, userName, 'Client', 'cancellation_requested', reason: reason);

    try {
      final chatService = ChatService();
      final chat = await chatService.getOrCreateChat(
        clientId: consultation.clientId,
        lawyerId: consultation.lawyerId,
        clientName: consultation.clientName ?? 'Client',
        lawyerName: consultation.lawyerName ?? 'Lawyer',
        clientAvatar: consultation.clientAvatar,
        lawyerAvatar: consultation.lawyerAvatar,
      );

      final message = MessageModel(
        id: '',
        senderId: userId,
        text: 'Cancellation Requested! Reason: ${reason ?? "None provided"}',
        timestamp: DateTime.now(),
        type: 'cancellation_request',
        metadata: {
          'caseId': caseId,
          'consultationId': consultation.id,
          'topic': consultation.description,
          'cancellationReason': reason,
        },
      );

      await chatService.sendMessage(chat.id, message, true);
    } catch (e) {
      print('Failed to send cancellation request chat message: $e');
    }
  }

  /// Lawyer accepts or rejects a client's cancellation request
  Future<void> resolveClientCancellation(
      ConsultationModel consultation, String lawyerId, String lawyerName, bool isAccepted) async {
    if (consultation.status != 'cancellation_requested') {
        return; // Not in a state that can be resolved
    }
    
    final caseId = consultation.caseId;
    final consultationId = consultation.id;
    final status = isAccepted ? 'cancelled' : 'accepted'; // If rejected, reverts to accepted

    Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': Timestamp.now(),
    };

    if (isAccepted) {
      updateData['refundStatus'] = 'pending'; // Trigger refund
    } else {
      updateData['cancellationRequestedBy'] = FieldValue.delete(); // Clear request
      updateData['cancellationReason'] = FieldValue.delete();
    }

    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update(updateData);
    
    final actionName = isAccepted ? 'cancellation_accepted' : 'cancellation_rejected';
    await _logStatusActivity(caseId, consultationId, lawyerId, lawyerName, 'Lawyer', actionName);

    if (isAccepted) {
      try {
        await EventService().updateEvent(consultationId, {'status': 'cancelled'});
      } catch (e) {}
    }

    try {
      final chatService = ChatService();
      final chat = await chatService.getOrCreateChat(
        clientId: consultation.clientId,
        lawyerId: consultation.lawyerId,
        clientName: consultation.clientName ?? 'Client',
        lawyerName: consultation.lawyerName ?? 'Lawyer',
      );

      final messageText = isAccepted 
          ? 'Cancellation Approved. Refund will be processed.' 
          : 'Cancellation Rejected. The consultation is still active.';

      final message = MessageModel(
        id: '',
        senderId: lawyerId,
        text: messageText,
        timestamp: DateTime.now(),
        type: actionName,
      );

      await chatService.sendMessage(chat.id, message, true);
    } catch (e) {}
  }

  /// Lawyer directly cancels (Immediate, but penalized)
  Future<void> lawyerDirectCancellation(
      ConsultationModel consultation, String lawyerId, String lawyerName, String? reason) async {
    final caseId = consultation.caseId;
    final consultationId = consultation.id;

    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': 'cancelled',
          'cancellationRequestedBy': lawyerId,
          'cancellationReason': reason,
          'refundStatus': 'pending', // Automatic refund when lawyer bails
          'penalized': true, // Tracks penalty application
          'updatedAt': Timestamp.now(),
        });
    
    await _logStatusActivity(caseId, consultationId, lawyerId, lawyerName, 'Lawyer', 'lawyer_direct_cancelled', reason: reason);

    try {
      await EventService().updateEvent(consultationId, {'status': 'cancelled'});
    } catch (e) {}

    // 1. Send Chat Notification
    try {
      final chatService = ChatService();
      final chat = await chatService.getOrCreateChat(
        clientId: consultation.clientId,
        lawyerId: consultation.lawyerId,
        clientName: consultation.clientName ?? 'Client',
        lawyerName: consultation.lawyerName ?? 'Lawyer',
      );

      final message = MessageModel(
        id: '',
        senderId: lawyerId,
        text: 'Lawyer has cancelled the consultation. Reason: ${reason ?? "None"}. Refund initiated.',
        timestamp: DateTime.now(),
        type: 'lawyer_direct_cancellation',
      );

      await chatService.sendMessage(chat.id, message, true);
    } catch (e) {}

    // 2. Penalize Lawyer using LawyerService
    await LawyerService().applyCancellationPenalty(lawyerId);
  }

  /// Mark consultation as completed with optional notes
  Future<void> completeConsultation(
      String caseId, String consultationId, String userId, String userName, String userRole, String? notes) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': 'completed',
          'completionNotes': notes,
          'completedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
    
    await _logStatusActivity(caseId, consultationId, userId, userName, userRole, 'completed', reason: notes);

    // Complete dynamic event if present
    try {
      await EventService().updateEvent(consultationId, {'status': 'completed'});
    } catch (e) {}
  }

  /// Mark consultation as no-show
  Future<void> markAsNoShow(String caseId, String consultationId) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': 'no_show',
          'updatedAt': Timestamp.now(),
        });
  }

  /// Update consultation status (generic method for backward compatibility)
  Future<void> updateStatus(
      String caseId, String consultationId, String status) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'status': status,
          'updatedAt': Timestamp.now(),
        });
  }

  /// Update caseStatus for all consultations of a given case (when case status changes)
  Future<void> updateConsultationCaseStatus(String caseId, String newStatus) async {
    final consultations = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .get();

    final batch = _firestore.batch();
    for (var doc in consultations.docs) {
      batch.update(doc.reference, {'caseStatus': newStatus});
    }
    await batch.commit();
  }

  // ===================== Counter-Proposal Management =====================

  /// Add a counter proposal (suggest alternative time/location)
  Future<void> addCounterProposal(
    String caseId,
    String consultationId,
    CounterProposal counterProposal,
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    final updatedProposals = [...consultation.counterProposals, counterProposal];

    await docRef.update({
      'counterProposals': updatedProposals.map((x) => x.toMap()).toList(),
      'hasUnresolvedProposal': true,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Accept a counter proposal and update the consultation
  Future<void> acceptCounterProposal(
    String caseId,
    String consultationId,
    int proposalIndex,
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    if (proposalIndex < 0 || proposalIndex >= consultation.counterProposals.length) {
      throw Exception('Invalid proposal index');
    }

    final acceptedProposal = consultation.counterProposals[proposalIndex];
    
    // Update consultations with accepted proposal details
    final updatedProposals = consultation.counterProposals.asMap().entries.map((entry) {
      if (entry.key == proposalIndex) {
        return entry.value.copyWith(isAccepted: true) ?? entry.value;
      }
      return entry.value;
    }).toList();

    await docRef.update({
      'scheduledAt': Timestamp.fromDate(acceptedProposal.proposedDate),
      'type': acceptedProposal.proposedType,
      'location': acceptedProposal.proposedLocation,
      'meetingLink': acceptedProposal.proposedMeetingLink,
      'counterProposals': updatedProposals.map((x) => x.toMap()).toList(),
      'hasUnresolvedProposal': false,
      'status': 'accepted',
      'acceptedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Reject a counter proposal
  Future<void> rejectCounterProposal(
    String caseId,
    String consultationId,
    int proposalIndex,
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    // Remove the rejected proposal
    final updatedProposals = consultation.counterProposals
        .asMap()
        .entries
        .where((entry) => entry.key != proposalIndex)
        .map((entry) => entry.value)
        .toList();

    await docRef.update({
      'counterProposals': updatedProposals.map((x) => x.toMap()).toList(),
      'hasUnresolvedProposal': updatedProposals.isNotEmpty,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===================== Meeting Details Management =====================

  /// Update meeting link for video consultation
  Future<void> updateMeetingLink(
    String caseId,
    String consultationId,
    String meetingLink,
    String? platform,
  ) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'meetingLink': meetingLink,
          'meetingPlatform': platform,
          'updatedAt': Timestamp.now(),
        });
  }

  /// Update location for in-person consultation
  Future<void> updateLocation(
    String caseId,
    String consultationId,
    String location,
  ) async {
    await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .update({
          'location': location,
          'updatedAt': Timestamp.now(),
        });
  }

  /// Add attachments to consultation
  Future<void> addAttachments(
    String caseId,
    String consultationId,
    List<String> attachmentIds,
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    final updatedAttachments = [...consultation.attachmentIds, ...attachmentIds];

    await docRef.update({
      'attachmentIds': updatedAttachments,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Remove an attachment
  Future<void> removeAttachment(
    String caseId,
    String consultationId,
    String attachmentId,
  ) async {
    final docRef = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId);

    final doc = await docRef.get();
    final consultation = ConsultationModel.fromMap(doc.data()!, doc.id);

    final updatedAttachments = consultation.attachmentIds
        .where((id) => id != attachmentId)
        .toList();

    await docRef.update({
      'attachmentIds': updatedAttachments,
      'updatedAt': Timestamp.now(),
    });
  }

  // ===================== Streaming/Query Operations =====================

  /// Stream Consultations for a specific case
  Stream<List<ConsultationModel>> getConsultationsForCase(String caseId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConsultationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Stream pending consultations for a case
  Stream<List<ConsultationModel>> getPendingConsultationsForCase(String caseId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConsultationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Stream accepted consultations for a case
  Stream<List<ConsultationModel>> getAcceptedConsultationsForCase(String caseId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .where('status', isEqualTo: 'accepted')
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConsultationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Stream Consultations for a User (Lawyer or Client) - Merging two streams
  Stream<List<ConsultationModel>> getConsultationsForUser(String userId) {
    // 1. Where user is requester
    final requesterStream = _firestore
        .collectionGroup('consultations')
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // 2. Where user is target
    final targetStream = _firestore
        .collectionGroup('consultations')
        .where('targetId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    // Merge logic
    late StreamController<List<ConsultationModel>> controller;

    controller = StreamController<List<ConsultationModel>>(
      onListen: () {
        List<ConsultationModel> fromRequester = [];
        List<ConsultationModel> fromTarget = [];

        void emit() {
          final all = [...fromRequester, ...fromTarget]
              .where((c) => c.caseStatus != 'closed' && c.caseId != 'standalone')
              .toList();
          
          _checkAndCompleteExpired(all);

          // Sort by date desc
          all.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          if (!controller.isClosed) controller.add(all);
        }

        final sub1 = requesterStream.listen((snap) {
          fromRequester = snap.docs
              .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
              .toList();
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        final sub2 = targetStream.listen((snap) {
          fromTarget = snap.docs
              .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
              .toList();
          emit();
        }, onError: (e) {
          if (!controller.isClosed) controller.addError(e);
        });

        controller.onCancel = () {
          sub1.cancel();
          sub2.cancel();
        };
      },
    );

    return controller.stream;
  }

  /// Get a stream of a specific consultation
  Stream<ConsultationModel?> getConsultationStream(String caseId, String consultationId) {
    return _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .doc(consultationId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final c = ConsultationModel.fromMap(doc.data()!, doc.id);
          _checkAndCompleteExpired([c]);
          return c;
        });
  }

  Future<void> _checkAndCompleteExpired(List<ConsultationModel> consultations) async {
    final now = DateTime.now();
    for (var c in consultations) {
      if (c.status == 'accepted' && c.scheduledAt.isBefore(now)) {
        try {
          await _firestore
              .collection('cases')
              .doc(c.caseId)
              .collection('consultations')
              .doc(c.id)
              .update({
            'status': 'completed',
            'completedAt': Timestamp.now(),
            'updatedAt': Timestamp.now(),
          });
        } catch (e) {
          // Ignore
        }
      }
    }
  }

  /// Get pending consultations for a user (those awaiting their response)
  Stream<List<ConsultationModel>> getPendingConsultationsForUser(String userId) {
    return _firestore
        .collectionGroup('consultations')
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .where((c) => c.caseStatus != 'closed' && c.caseId != 'standalone')
          .toList();
    });
  }

  /// Get upcoming accepted consultations for a user
  Stream<List<ConsultationModel>> getUpcomingConsultationsForUser(String userId) {
    final now = DateTime.now();
    
    // This is a workaround since we can't filter with >= and where together easily
    // We'll fetch all consultations and filter in code
    return getConsultationsForUser(userId).map((consultations) {
      return consultations
          .where((c) => 
              c.status == 'accepted' &&
              c.scheduledAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
  }

  /// Get completed consultations for a user
  Stream<List<ConsultationModel>> getCompletedConsultationsForUser(String userId) {
    return _firestore
        .collectionGroup('consultations')
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allCompleted = snapshot.docs
          .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Filter to only consultations involving this user and exclude closed cases
      return allCompleted
          .where((c) => (c.requesterId == userId || c.targetId == userId) && c.caseStatus != 'closed' && c.caseId != 'standalone')
          .toList()
        ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime(1970)) ?? 0);
    });
  }

  /// Search consultations by status and date range
  Future<List<ConsultationModel>> searchConsultations({
    required String caseId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    final docs = await query.get();
    var consultations = docs.docs
        .map((doc) => ConsultationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    if (startDate != null) {
      consultations = consultations
          .where((c) => c.scheduledAt.isAfter(startDate))
          .toList();
    }

    if (endDate != null) {
      consultations = consultations
          .where((c) => c.scheduledAt.isBefore(endDate))
          .toList();
    }

    return consultations..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  }

  /// Get consultation statistics for a case
  Future<Map<String, int>> getConsultationStats(String caseId) async {
    final snapshot = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .get();

    final consultations = snapshot.docs
        .map((doc) => ConsultationModel.fromMap(doc.data(), doc.id))
        .toList();

    return {
      'total': consultations.length,
      'pending': consultations.where((c) => c.status == 'pending').length,
      'accepted': consultations.where((c) => c.status == 'accepted').length,
      'completed': consultations.where((c) => c.status == 'completed').length,
      'rejected': consultations.where((c) => c.status == 'rejected').length,
      'cancelled': consultations.where((c) => c.status == 'cancelled').length,
    };
  }

  /// Get the number of consultations for a specific case
  Future<int> getConsultationCountForCase(String caseId) async {
    final snapshot = await _firestore
        .collection('cases')
        .doc(caseId)
        .collection('consultations')
        .get();
    return snapshot.docs.length;
  }
}
