import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/case_invoice_model.dart';
import '../../wallet/models/wallet_transaction_model.dart';

class CaseInvoiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await _firestore.runTransaction((tx) async {
      final invoiceRef = _invoicesRef(caseId).doc(invoiceId);
      final invoiceDoc = await tx.get(invoiceRef);
      if (!invoiceDoc.exists || invoiceDoc.data() == null) {
        throw Exception('Invoice not found');
      }

      final invoice = CaseInvoiceModel.fromMap(invoiceDoc.data()!, invoiceDoc.id);
      if (invoice.status == 'paid') {
        return;
      }

      if (invoice.payerId != currentUserId) {
        throw Exception('Only the invoice payer can complete this payment');
      }

      final payerRef = _firestore.collection('users').doc(invoice.payerId);
      final payeeRef = _firestore.collection('users').doc(invoice.payeeId);
      final payerDoc = await tx.get(payerRef);
      final payeeDoc = await tx.get(payeeRef);
      if (!payerDoc.exists) throw Exception('Payer profile not found');
      if (!payeeDoc.exists) throw Exception('Payee profile not found');

      final payerBalance = (payerDoc.data()?['walletBalance'] ?? 0).toDouble();
      if (payerBalance < invoice.amount) {
        throw Exception('Insufficient wallet balance');
      }

      final payeeBalance = (payeeDoc.data()?['walletBalance'] ?? 0).toDouble();
      final now = DateTime.now();
      final operationId = 'invoice_payment_${invoice.id}';

      tx.update(payerRef, {
        'walletBalance': payerBalance - invoice.amount,
        'lastActivity': Timestamp.fromDate(now),
      });

      tx.update(payeeRef, {
        'walletBalance': payeeBalance + invoice.amount,
        'lastActivity': Timestamp.fromDate(now),
      });

      tx.update(invoiceRef, {
        'status': 'paid',
        'paidAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final payerTxRef = payerRef.collection('wallet_transactions').doc();
      final payeeTxRef = payeeRef.collection('wallet_transactions').doc();

      tx.set(
        payerTxRef,
        WalletTransactionModel(
          id: payerTxRef.id,
          operationId: operationId,
          userId: invoice.payerId,
          type: WalletTxType.debit,
          reason: 'invoice_payment',
          amount: invoice.amount,
          currency: invoice.currency,
          status: 'completed',
          counterpartyUserId: invoice.payeeId,
          referenceType: 'case_invoice',
          referenceId: invoice.id,
          metadata: {
            'caseId': caseId,
            'title': invoice.title,
          },
          createdAt: now,
        ).toMap(),
      );

      tx.set(
        payeeTxRef,
        WalletTransactionModel(
          id: payeeTxRef.id,
          operationId: operationId,
          userId: invoice.payeeId,
          type: WalletTxType.credit,
          reason: 'invoice_payment_received',
          amount: invoice.amount,
          currency: invoice.currency,
          status: 'completed',
          counterpartyUserId: invoice.payerId,
          referenceType: 'case_invoice',
          referenceId: invoice.id,
          metadata: {
            'caseId': caseId,
            'title': invoice.title,
          },
          createdAt: now,
        ).toMap(),
      );
    });
  }
}
