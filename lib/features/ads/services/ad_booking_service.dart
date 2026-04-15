import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ad_booking_model.dart';

class AdBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _bookingsRef =>
      _firestore.collection('ad_bookings');

  Future<void> createBooking(AdBookingModel booking) async {
    await _bookingsRef.doc(booking.id).set(booking.toMap());
  }

  Future<AdBookingModel?> getBookingById(String bookingId) async {
    final doc = await _bookingsRef.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return AdBookingModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> markSetupCompleted(String bookingId, String caseId) async {
    await _bookingsRef.doc(bookingId).update({
      'setupStatus': 'completed',
      'caseId': caseId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<String> chargeAndCreateBooking({
    required String adId,
    required String lawyerId,
    required String clientId,
    required double amount,
  }) async {
    final bookingId = _bookingsRef.doc().id;

    await _firestore.runTransaction((tx) async {
      final clientRef = _firestore.collection('users').doc(clientId);
      final lawyerRef = _firestore.collection('users').doc(lawyerId);
      final clientDoc = await tx.get(clientRef);
      final lawyerDoc = await tx.get(lawyerRef);
      if (!clientDoc.exists) {
        throw Exception('Client profile not found');
      }
      if (!lawyerDoc.exists) {
        throw Exception('Lawyer profile not found');
      }

      final clientBalance = (clientDoc.data()?['walletBalance'] ?? 0).toDouble();
      if (clientBalance < amount) {
        throw Exception('Insufficient wallet balance');
      }
      final lawyerBalance = (lawyerDoc.data()?['walletBalance'] ?? 0).toDouble();
      final now = Timestamp.fromDate(DateTime.now());

      tx.update(clientRef, {
        'walletBalance': clientBalance - amount,
        'lastActivity': now,
      });

      tx.update(lawyerRef, {
        'walletBalance': lawyerBalance + amount,
        'lastActivity': now,
      });

      tx.set(_bookingsRef.doc(bookingId), {
        'adId': adId,
        'lawyerId': lawyerId,
        'clientId': clientId,
        'amount': amount,
        'paymentStatus': 'paid',
        'setupStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      // Increment bookings counter on the ad document
      final adRef = _firestore.collection('lawyer_ads').doc(adId);
      tx.update(adRef, {'bookings': FieldValue.increment(1)});

      final clientTxRef = clientRef.collection('wallet_transactions').doc();
      final lawyerTxRef = lawyerRef.collection('wallet_transactions').doc();
      tx.set(clientTxRef, {
        'operationId': 'ad_booking_$bookingId',
        'userId': clientId,
        'type': 'debit',
        'reason': 'ad_booking_payment',
        'amount': amount,
        'currency': 'PKR',
        'status': 'completed',
        'counterpartyUserId': lawyerId,
        'referenceType': 'ad_booking',
        'referenceId': bookingId,
        'metadata': {'adId': adId},
        'createdAt': now,
      });
      tx.set(lawyerTxRef, {
        'operationId': 'ad_booking_$bookingId',
        'userId': lawyerId,
        'type': 'credit',
        'reason': 'ad_booking_received',
        'amount': amount,
        'currency': 'PKR',
        'status': 'completed',
        'counterpartyUserId': clientId,
        'referenceType': 'ad_booking',
        'referenceId': bookingId,
        'metadata': {'adId': adId},
        'createdAt': now,
      });
    });

    return bookingId;
  }
}
