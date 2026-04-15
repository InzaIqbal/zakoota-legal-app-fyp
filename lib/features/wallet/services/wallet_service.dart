import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet_transaction_model.dart';

class WalletService {
  static const double dummyDepositCap = 50000;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  CollectionReference<Map<String, dynamic>> _txRef(String userId) {
    return _userRef(userId).collection('wallet_transactions');
  }

  DocumentReference<Map<String, dynamic>> _operationRef(String operationId) {
    return _firestore.collection('wallet_operations').doc(operationId);
  }

  Stream<double> streamWalletBalance(String userId) {
    return _userRef(userId).snapshots().map((doc) {
      return (doc.data()?['walletBalance'] ?? 0).toDouble();
    });
  }

  Stream<List<WalletTransactionModel>> streamWalletTransactions(
    String userId, {
    int limit = 50,
  }) {
    return _txRef(userId)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final transactions = <WalletTransactionModel>[];
      for (final doc in snapshot.docs) {
        try {
          transactions.add(WalletTransactionModel.fromMap(doc.data(), doc.id));
        } catch (_) {
          // Skip malformed transaction rows instead of crashing the wallet stream.
        }
      }
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return transactions;
    });
  }

  Future<double> getWalletBalance(String userId) async {
    final doc = await _userRef(userId).get();
    return (doc.data()?['walletBalance'] ?? 0).toDouble();
  }

  Future<void> depositDummy({
    required String userId,
    required double amount,
    required String method,
    required String operationId,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than zero');
    if (amount > dummyDepositCap) {
      throw Exception('Dummy deposit cap is PKR ${dummyDepositCap.toInt()}');
    }

    await credit(
      userId: userId,
      amount: amount,
      reason: 'deposit_dummy',
      method: method,
      operationId: operationId,
      metadata: {'mode': 'dummy'},
    );
  }

  Future<void> credit({
    required String userId,
    required double amount,
    required String reason,
    required String operationId,
    String? method,
    String? counterpartyUserId,
    String? referenceType,
    String? referenceId,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    await _firestore.runTransaction((tx) async {
      final opRef = _operationRef(operationId);
      final opDoc = await tx.get(opRef);
      if (opDoc.exists) return;

      final userRef = _userRef(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final currentBalance = (userDoc.data()?['walletBalance'] ?? 0).toDouble();
      final nextBalance = currentBalance + amount;

      final txDoc = _txRef(userId).doc();
      final walletTx = WalletTransactionModel(
        id: txDoc.id,
        operationId: operationId,
        userId: userId,
        type: WalletTxType.credit,
        reason: reason,
        amount: amount,
        currency: 'PKR',
        status: 'completed',
        method: method,
        counterpartyUserId: counterpartyUserId,
        referenceType: referenceType,
        referenceId: referenceId,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      tx.update(userRef, {
        'walletBalance': nextBalance,
        'lastActivity': Timestamp.fromDate(DateTime.now()),
      });
      tx.set(txDoc, walletTx.toMap());
      tx.set(opRef, {
        'operationId': operationId,
        'type': 'credit',
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> debit({
    required String userId,
    required double amount,
    required String reason,
    required String operationId,
    String? counterpartyUserId,
    String? referenceType,
    String? referenceId,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    await _firestore.runTransaction((tx) async {
      final opRef = _operationRef(operationId);
      final opDoc = await tx.get(opRef);
      if (opDoc.exists) return;

      final userRef = _userRef(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final currentBalance = (userDoc.data()?['walletBalance'] ?? 0).toDouble();
      if (currentBalance < amount) {
        throw Exception('Insufficient wallet balance');
      }
      final nextBalance = currentBalance - amount;

      final txDoc = _txRef(userId).doc();
      final walletTx = WalletTransactionModel(
        id: txDoc.id,
        operationId: operationId,
        userId: userId,
        type: WalletTxType.debit,
        reason: reason,
        amount: amount,
        currency: 'PKR',
        status: 'completed',
        counterpartyUserId: counterpartyUserId,
        referenceType: referenceType,
        referenceId: referenceId,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      tx.update(userRef, {
        'walletBalance': nextBalance,
        'lastActivity': Timestamp.fromDate(DateTime.now()),
      });
      tx.set(txDoc, walletTx.toMap());
      tx.set(opRef, {
        'operationId': operationId,
        'type': 'debit',
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> transfer({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String operationId,
    required String debitReason,
    required String creditReason,
    String? referenceType,
    String? referenceId,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than zero');
    if (fromUserId == toUserId) throw Exception('Invalid transfer parties');

    await _firestore.runTransaction((tx) async {
      final opRef = _operationRef(operationId);
      final opDoc = await tx.get(opRef);
      if (opDoc.exists) return;

      final fromRef = _userRef(fromUserId);
      final toRef = _userRef(toUserId);
      final fromDoc = await tx.get(fromRef);
      final toDoc = await tx.get(toRef);
      if (!fromDoc.exists || !toDoc.exists) {
        throw Exception('Account not found');
      }

      final fromBalance = (fromDoc.data()?['walletBalance'] ?? 0).toDouble();
      if (fromBalance < amount) throw Exception('Insufficient wallet balance');
      final toBalance = (toDoc.data()?['walletBalance'] ?? 0).toDouble();

      final now = DateTime.now();
      final debitTxRef = _txRef(fromUserId).doc();
      final creditTxRef = _txRef(toUserId).doc();

      tx.update(fromRef, {
        'walletBalance': fromBalance - amount,
        'lastActivity': Timestamp.fromDate(now),
      });
      tx.update(toRef, {
        'walletBalance': toBalance + amount,
        'lastActivity': Timestamp.fromDate(now),
      });

      tx.set(
        debitTxRef,
        WalletTransactionModel(
          id: debitTxRef.id,
          operationId: operationId,
          userId: fromUserId,
          type: WalletTxType.debit,
          reason: debitReason,
          amount: amount,
          currency: 'PKR',
          status: 'completed',
          counterpartyUserId: toUserId,
          referenceType: referenceType,
          referenceId: referenceId,
          metadata: metadata,
          createdAt: now,
        ).toMap(),
      );

      tx.set(
        creditTxRef,
        WalletTransactionModel(
          id: creditTxRef.id,
          operationId: operationId,
          userId: toUserId,
          type: WalletTxType.credit,
          reason: creditReason,
          amount: amount,
          currency: 'PKR',
          status: 'completed',
          counterpartyUserId: fromUserId,
          referenceType: referenceType,
          referenceId: referenceId,
          metadata: metadata,
          createdAt: now,
        ).toMap(),
      );

      final transferRef = _firestore.collection('wallet_transfers').doc();
      tx.set(transferRef, {
        'transferId': transferRef.id,
        'operationId': operationId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'currency': 'PKR',
        'status': 'completed',
        'debitReason': debitReason,
        'creditReason': creditReason,
        'referenceType': referenceType,
        'referenceId': referenceId,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(now),
      });

      tx.set(opRef, {
        'operationId': operationId,
        'type': 'transfer',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }

  Future<void> createWithdrawalRequest({
    required String userId,
    required double amount,
    required String method,
    required String account,
    String? accountTitle,
    required String operationId,
  }) async {
    if (amount <= 0) throw Exception('Amount must be greater than zero');

    await _firestore.runTransaction((tx) async {
      final opRef = _operationRef(operationId);
      final opDoc = await tx.get(opRef);
      if (opDoc.exists) return;

      final userRef = _userRef(userId);
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');
      final rawBalance = userDoc.data()?['walletBalance'];
      final balance = rawBalance is num
          ? rawBalance.toDouble()
          : double.tryParse(rawBalance?.toString() ?? '0') ?? 0.0;

      if (balance < amount) {
        throw Exception(
          'Insufficient wallet balance. Available: PKR ${balance.toStringAsFixed(2)}, Requested: PKR ${amount.toStringAsFixed(2)}',
        );
      }

      final now = DateTime.now();
      final reqRef = _firestore.collection('withdrawal_requests').doc();
      final txRef = _txRef(userId).doc();

      // Auto-approve withdrawal: immediately debit the wallet
      tx.update(userRef, {
        'walletBalance': balance - amount,
        'lastActivity': Timestamp.fromDate(now),
      });

      tx.set(reqRef, {
        'requestId': reqRef.id,
        'operationId': operationId,
        'userId': userId,
        'amount': amount,
        'currency': 'PKR',
        'method': method,
        'account': account,
        'accountTitle': accountTitle,
        'status': 'completed',
        'completedAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });

      tx.set(
        txRef,
        WalletTransactionModel(
          id: txRef.id,
          operationId: operationId,
          userId: userId,
          type: WalletTxType.debit,
          reason: 'withdrawal_request',
          amount: amount,
          currency: 'PKR',
          status: 'completed',
          method: method,
          referenceType: 'withdrawal_request',
          referenceId: reqRef.id,
          metadata: {'account': account, 'accountTitle': accountTitle},
          createdAt: now,
        ).toMap(),
      );

      tx.set(opRef, {
        'operationId': operationId,
        'type': 'withdrawal_request',
        'userId': userId,
        'amount': amount,
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }
}
