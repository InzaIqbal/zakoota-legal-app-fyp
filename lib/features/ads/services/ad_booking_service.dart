import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ad_booking_model.dart';
import '../../wallet/services/wallet_service.dart';

class AdBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

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

  /// Hold ad booking payment from client
  Future<String> holdAdBookingPayment({
    required String adId,
    required String lawyerId,
    required String clientId,
    required double amount,
  }) async {
    final bookingId = _bookingsRef.doc().id;
    final operationId = 'ad_booking_$bookingId';

    // Hold funds from client
    await _walletService.holdFunds(
      userId: clientId,
      amount: amount,
      operationId: operationId,
      reason: 'Ad booking payment',
      referenceType: 'ad_booking',
      referenceId: bookingId,
      metadata: {'adId': adId, 'lawyerId': lawyerId},
    );

    // Create booking in held state
    await _firestore.runTransaction((tx) async {
      tx.set(_bookingsRef.doc(bookingId), {
        'adId': adId,
        'lawyerId': lawyerId,
        'clientId': clientId,
        'amount': amount,
        'paymentStatus': 'held',
        'holdOperationId': operationId,
        'setupStatus': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Increment bookings counter on the ad document
      final adRef = _firestore.collection('lawyer_ads').doc(adId);
      tx.update(adRef, {'bookings': FieldValue.increment(1)});
    });

    return bookingId;
  }

  /// Release held ad booking payment to lawyer
  Future<void> releaseAdBookingPayment({
    required String bookingId,
    required String clientId,
    required String lawyerId,
    required double amount,
    required String holdOperationId,
  }) async {
    final operationId = 'ad_release_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';

    await _walletService.releaseHeldFunds(
      fromUserId: clientId,
      toUserId: lawyerId,
      amount: amount,
      operationId: operationId,
      releaseReason: 'Ad booking payment released',
      originalHoldOperationId: holdOperationId,
    );

    await _bookingsRef.doc(bookingId).update({
      'paymentStatus': 'released',
      'releaseOperationId': operationId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Refund held ad booking payment to client
  Future<void> refundAdBookingPayment({
    required String bookingId,
    required String clientId,
    required double amount,
    required String holdOperationId,
  }) async {
    final operationId = 'ad_refund_${bookingId}_${DateTime.now().millisecondsSinceEpoch}';

    await _walletService.refundHeldFunds(
      userId: clientId,
      amount: amount,
      operationId: operationId,
      originalHoldOperationId: holdOperationId,
      refundReason: 'Ad booking refunded',
    );

    await _bookingsRef.doc(bookingId).update({
      'paymentStatus': 'refunded',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
