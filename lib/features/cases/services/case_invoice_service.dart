import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/case_invoice_model.dart';
import '../../wallet/services/wallet_service.dart';

class CaseInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();

  CollectionReference<Map<String, dynamic>> _invoicesRef(String caseId) {
    return _firestore.collection('cases').doc(caseId).collection('invoices');
  }

  Stream<List<CaseInvoiceModel>> streamCaseInvoices(String caseId) {
    return _invoicesRef(caseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CaseInvoiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createInvoice({
    required String caseId,
    required String title,
    required String notes,
    required double amount,
    required String currency,
    required String payerId,
    required String payeeId,
    DateTime? dueDate,
  }) async {
    final ref = _invoicesRef(caseId).doc();
    final now = DateTime.now();

    final invoice = CaseInvoiceModel(
      id: ref.id,
      caseId: caseId,
      title: title,
      notes: notes,
      amount: amount,
      currency: currency,
      status: 'pending',
      payerId: payerId,
      payeeId: payeeId,
      dueDate: dueDate,
      paidAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(invoice.toMap());
  }

  Future<void> markAsPaid({
    required String caseId,
    required String invoiceId,
  }) async {
    final now = DateTime.now();
    await _invoicesRef(caseId).doc(invoiceId).update({
      'status': 'paid',
      'paidAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> payInvoice({
    required String caseId,
    required String invoiceId,
    required String currentUserId,
  }) async {
    final invoiceRef = _invoicesRef(caseId).doc(invoiceId);
    final invoiceDoc = await invoiceRef.get();
    if (!invoiceDoc.exists || invoiceDoc.data() == null) {
      throw Exception('Invoice not found');
    }

    final invoice = CaseInvoiceModel.fromMap(invoiceDoc.data()!, invoiceDoc.id);
    if (invoice.status == 'paid' || invoice.status == 'held') {
      return;
    }

    if (invoice.payerId != currentUserId) {
      throw Exception('Only the invoice payer can complete this payment');
    }

    final now = DateTime.now();
    final operationId = 'invoice_hold_${invoice.id}';

    await _walletService.holdFunds(
      userId: invoice.payerId,
      amount: invoice.amount,
      operationId: operationId,
      reason: 'invoice_payment_hold',
      referenceType: 'case_invoice',
      referenceId: invoice.id,
      metadata: {
        'caseId': caseId,
        'title': invoice.title,
      },
    );

    await invoiceRef.update({
      'status': 'held',
      'heldAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'holdOperationId': operationId,
    });
  }

  Future<void> releaseInvoicePayment({
    required String caseId,
    required String invoiceId,
    required String currentUserId,
  }) async {
    final invoiceRef = _invoicesRef(caseId).doc(invoiceId);
    final invoiceDoc = await invoiceRef.get();
    if (!invoiceDoc.exists || invoiceDoc.data() == null) {
      throw Exception('Invoice not found');
    }

    final invoice = CaseInvoiceModel.fromMap(invoiceDoc.data()!, invoiceDoc.id);
    if (invoice.status == 'paid') {
      return;
    }

    if (invoice.payerId != currentUserId) {
      throw Exception('Only the invoice payer can release this payment');
    }

    if (invoice.holdOperationId == null || invoice.holdOperationId!.isEmpty) {
      throw Exception('Invoice hold not found');
    }

    final operationId = 'invoice_release_${invoice.id}';
    final now = DateTime.now();

    await _walletService.releaseHeldFunds(
      fromUserId: invoice.payerId,
      toUserId: invoice.payeeId,
      amount: invoice.amount,
      operationId: operationId,
      releaseReason: 'invoice_payment_release',
      originalHoldOperationId: invoice.holdOperationId!,
      metadata: {
        'caseId': caseId,
        'title': invoice.title,
      },
    );

    await invoiceRef.update({
      'status': 'paid',
      'paidAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'releaseOperationId': operationId,
    });
  }
}
