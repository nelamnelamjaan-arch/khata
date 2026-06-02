import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/services/notification_service.dart';
import 'package:smart_khata_manager/features/dashboard/models/dashboard_summary.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';
import 'package:uuid/uuid.dart';

/// Firestore CRUD for parties and transactions, scoped to the signed-in user.
///
/// Data path: `users/{uid}/parties` and `users/{uid}/transactions`.
///
/// [addTransaction] atomically writes the transaction document and updates
/// the linked party's [Party.currentBalance] inside a Firestore transaction,
/// guaranteeing consistency in both online and offline modes.
class LedgerService extends GetxService {
  final _uuid = const Uuid();

  Stream<DashboardSummary>? _dashboardSummaryStream;
  String? _dashboardUserId;

  FirebaseFirestore? get _db => Get.find<FirebaseService>().firestore;

  AuthService get _auth => Get.find<AuthService>();

  bool get _isReady => _db != null && _auth.isSignedIn;

  FirebaseFirestore get _firestore {
    final db = _db;
    if (db == null) {
      final firebase = Get.find<FirebaseService>();
      final detail = firebase.initError.value ?? '';
      throw StateError(
        detail.isNotEmpty
            ? 'Firebase is not connected. $detail'
            : 'Firebase is not connected. Run: flutterfire configure',
      );
    }
    return db;
  }

  String get _userId {
    final uid = _auth.userId;
    if (uid == null || uid.isEmpty) {
      throw StateError(
        'Not signed in. Sign in before reading or writing khata data.',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _partiesRef => _firestore
      .collection(AppConstants.usersCollection)
      .doc(_userId)
      .collection(AppConstants.partiesCollection);

  CollectionReference<Map<String, dynamic>> get _transactionsRef => _firestore
      .collection(AppConstants.usersCollection)
      .doc(_userId)
      .collection(AppConstants.transactionsCollection);

  // ── Party CRUD ────────────────────────────────────────────────────────────

  void _ensureReady() {
    if (!_isReady) {
      final firebase = Get.find<FirebaseService>();
      final auth = Get.find<AuthService>();
      if (!auth.isSignedIn) {
        final authDetail = auth.authError.value?.trim();
        throw StateError(
          authDetail != null && authDetail.isNotEmpty
              ? 'Sign-in required. $authDetail'
              : 'Sign-in required. Sign in with email and password.',
        );
      }
      final detail = firebase.initError.value?.trim();
      final hint = detail != null && detail.isNotEmpty
          ? detail
          : 'Run: flutterfire configure. On Vercel, add your domain to Firebase Authorized domains.';
      throw StateError('Firebase is not connected. $hint');
    }
  }

  Future<Party> createParty({
    required String name,
    required String phone,
    String? id,
  }) async {
    _ensureReady();
    final partyId = id ?? _uuid.v4();
    final party = Party(
      id: partyId,
      name: name,
      phone: phone,
      currentBalance: 0,
    );

    await _partiesRef
        .doc(partyId)
        .set(party.toMap())
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException(
            'Save timed out. Check internet and Firestore rules.',
          ),
        );
    return party;
  }

  Future<Party?> getParty(String id) async {
    if (!_isReady) return null;
    final doc = await _partiesRef.doc(id).get();
    if (!doc.exists) return null;
    return Party.fromFirestore(doc);
  }

  Stream<List<Party>> watchParties() {
    return _whenReady((db, userId) {
      return db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.partiesCollection)
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(Party.fromFirestore)
                .toList(growable: false),
          );
    });
  }

  Future<void> updateParty(Party party) async {
    _ensureReady();
    await _partiesRef.doc(party.id).update({
      'name': party.name,
      'phone': party.phone,
    });
  }

  Future<void> deleteParty(String partyId) async {
    _ensureReady();
    final txDocs =
        await _transactionsRef.where('partyId', isEqualTo: partyId).get();

    final batch = _firestore.batch();
    for (final doc in txDocs.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_partiesRef.doc(partyId));
    await batch.commit();
  }

  // ── Transaction CRUD (auto balance update) ────────────────────────────────

  /// Adds a transaction and atomically updates the party balance.
  Future<TransactionModel> addTransaction({
    required String partyId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
    String? id,
  }) async {
    _ensureReady();
    _validateAmount(amount);

    final txId = id ?? _uuid.v4();
    final transaction = TransactionModel(
      id: txId,
      partyId: partyId,
      amount: amount,
      type: type,
      date: date,
      note: note,
    );

    await _firestore
        .runTransaction((firestoreTx) async {
      final partyRef = _partiesRef.doc(partyId);
      final partySnap = await firestoreTx.get(partyRef);

      if (!partySnap.exists) {
        throw StateError('Party not found: $partyId');
      }

      final party = Party.fromFirestore(partySnap);
      final newBalance = party.currentBalance + transaction.balanceDelta;

      firestoreTx.set(_transactionsRef.doc(txId), transaction.toMap());
      firestoreTx.update(partyRef, {'currentBalance': newBalance});
    })
        .timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Transaction save timed out. Check Firestore rules.',
      ),
    );

    // Receivable entry (Debit) → schedule payment-due reminder.
    if (type.isReceivableEntry) {
      await _scheduleReceivableReminder(transaction);
    }

    return transaction;
  }

  Future<TransactionModel?> getTransaction(String id) async {
    if (!_isReady) return null;
    final doc = await _transactionsRef.doc(id).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }

  Stream<List<TransactionModel>> watchTransactionsByParty(String partyId) {
    return _whenReady((db, userId) {
      return db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.transactionsCollection)
          .where('partyId', isEqualTo: partyId)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(TransactionModel.fromFirestore)
                .toList(growable: false),
          );
    });
  }

  Stream<List<TransactionModel>> watchAllTransactions() {
    return _whenReady((db, userId) {
      return db
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.transactionsCollection)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(TransactionModel.fromFirestore)
                .toList(growable: false),
          );
    });
  }

  Future<void> updateTransaction(TransactionModel updated) async {
    _ensureReady();
    _validateAmount(updated.amount);

    await _firestore.runTransaction((firestoreTx) async {
      final txRef = _transactionsRef.doc(updated.id);
      final existingSnap = await firestoreTx.get(txRef);

      if (!existingSnap.exists) {
        throw StateError('Transaction not found: ${updated.id}');
      }

      final existing = TransactionModel.fromFirestore(existingSnap);

      await _applyBalanceDelta(
        firestoreTx,
        existing.partyId,
        -existing.balanceDelta,
      );
      await _applyBalanceDelta(
        firestoreTx,
        updated.partyId,
        updated.balanceDelta,
      );

      firestoreTx.update(txRef, updated.toMap());
    });

    await _syncTransactionReminder(updated);
  }

  Future<void> deleteTransaction(String id) async {
    _ensureReady();
    TransactionModel? deleted;

    await _firestore.runTransaction((firestoreTx) async {
      final txRef = _transactionsRef.doc(id);
      final txSnap = await firestoreTx.get(txRef);

      if (!txSnap.exists) {
        throw StateError('Transaction not found: $id');
      }

      final existing = TransactionModel.fromFirestore(txSnap);
      deleted = existing;

      await _applyBalanceDelta(
        firestoreTx,
        existing.partyId,
        -existing.balanceDelta,
      );

      firestoreTx.delete(txRef);
    });

    if (deleted != null) {
      await _cancelTransactionReminder(deleted!);
    }
  }

  // ── Dashboard aggregates ──────────────────────────────────────────────────

  /// Real-time dashboard totals — cached stream (one subscription per user).
  Stream<DashboardSummary> watchDashboardSummary() {
    final firebase = Get.find<FirebaseService>();
    final userId = _auth.userId;

    if (_dashboardSummaryStream != null &&
        _dashboardUserId == userId &&
        firebase.isFirestoreReady.value &&
        firebase.firestore != null &&
        userId != null) {
      return _dashboardSummaryStream!;
    }

    _dashboardUserId = userId;
    _dashboardSummaryStream = _createDashboardSummaryStream();
    return _dashboardSummaryStream!;
  }

  Stream<DashboardSummary> _createDashboardSummaryStream() {
    final firebase = Get.find<FirebaseService>();
    final db = firebase.firestore;
    final userId = _auth.userId;

    if (db == null ||
        !firebase.isFirestoreReady.value ||
        userId == null ||
        userId.isEmpty) {
      return Stream.value(DashboardSummary.empty);
    }

    final partiesPath = db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.partiesCollection);
    final transactionsPath = db
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection(AppConstants.transactionsCollection);

    return Stream.multi((multi) {
      var latestTx = <TransactionModel>[];
      var latestParties = <Party>[];
      var rawTxDocs = 0;

      void emit() {
        if (multi.isClosed) return;
        multi.add(
          _computeDashboardSummary(
            transactions: latestTx,
            parties: latestParties,
            rawTransactionDocs: rawTxDocs,
          ),
        );
      }

      // Emit immediately so UI shows zeros then updates.
      emit();

      final txSub = transactionsPath.snapshots().listen((snap) {
        rawTxDocs = snap.docs.length;
        latestTx = snap.docs
            .map(TransactionModel.tryFromFirestore)
            .whereType<TransactionModel>()
            .toList(growable: false);
        emit();
      }, onError: multi.addError);

      final partySub = partiesPath.snapshots().listen((snap) {
        latestParties = snap.docs
            .map(Party.fromFirestore)
            .toList(growable: false);
        emit();
      }, onError: multi.addError);

      multi.onCancel = () {
        txSub.cancel();
        partySub.cancel();
      };
    });
  }

  DashboardSummary _computeDashboardSummary({
    required List<TransactionModel> transactions,
    required List<Party> parties,
    required int rawTransactionDocs,
  }) {
    // 1) Party balances (app updates these on every transaction).
    var partyReceivable = 0.0;
    var partyPayable = 0.0;
    var receivableParties = 0;
    var payableParties = 0;

    for (final party in parties) {
      if (party.isReceivable) {
        partyReceivable += party.receivableAmount;
        receivableParties++;
      } else if (party.isPayable) {
        partyPayable += party.payableAmount;
        payableParties++;
      }
    }

    // 2) Direct sum from transactions collection (manual/dummy data).
    var txReceivable = 0.0;
    var txPayable = 0.0;

    for (final tx in transactions) {
      if (tx.amount <= 0) continue;
      if (tx.type.isDebit) {
        txReceivable += tx.amount;
      } else {
        txPayable += tx.amount;
      }
    }

    // Use the higher value from either source so nothing is missed.
    final totalReceivable =
        partyReceivable > txReceivable ? partyReceivable : txReceivable;
    final totalPayable =
        partyPayable > txPayable ? partyPayable : txPayable;

    return DashboardSummary(
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
      receivablePartyCount: receivableParties > 0
          ? receivableParties
          : transactions.where((t) => t.isDebit).length,
      payablePartyCount:
          payableParties > 0 ? payableParties : transactions.where((t) => t.isCredit).length,
      transactionCount: transactions.length,
      partyCount: parties.length,
      rawTransactionDocs: rawTransactionDocs,
    );
  }

  /// Sum of absolute negative balances — total receivable (Lenay hain).
  Stream<double> watchTotalReceivable() {
    return watchDashboardSummary().map((s) => s.totalReceivable);
  }

  /// Sum of positive balances — total payable (Denay hain).
  Stream<double> watchTotalPayable() {
    return watchDashboardSummary().map((s) => s.totalPayable);
  }

  /// Re-subscribes when Firestore + auth become ready (fixes empty-stream race).
  Stream<T> _whenReady<T>(
    Stream<T> Function(FirebaseFirestore db, String userId) build,
  ) {
    final firebase = Get.find<FirebaseService>();
    final auth = Get.find<AuthService>();

    Stream<Object?> triggers() async* {
      yield Object();
      yield* firebase.isFirestoreReady.stream.distinct().map((_) => Object());
      yield* auth.authStateChanges().map((_) => Object());
    }

    return triggers().asyncExpand((_) {
      final db = firebase.firestore;
      final userId = auth.userId;
      if (!firebase.isFirestoreReady.value ||
          db == null ||
          userId == null ||
          userId.isEmpty) {
        return Stream<T>.empty();
      }
      return build(db, userId);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _applyBalanceDelta(
    Transaction firestoreTx,
    String partyId,
    double delta,
  ) async {
    final partyRef = _partiesRef.doc(partyId);
    final partySnap = await firestoreTx.get(partyRef);

    if (!partySnap.exists) {
      throw StateError('Party not found: $partyId');
    }

    final party = Party.fromFirestore(partySnap);
    firestoreTx.update(partyRef, {
      'currentBalance': party.currentBalance + delta,
    });
  }

  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('amount must be greater than zero');
    }
  }

  NotificationService? get _notifications =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  /// Debit = receivable (Lenay hain) — party owes payment to you.
  Future<void> _scheduleReceivableReminder(TransactionModel transaction) async {
    final notifications = _notifications;
    if (notifications == null) return;

    try {
      final party = await getParty(transaction.partyId);
      if (party == null) return;

      await notifications.scheduleTransactionReminder(
        transaction: transaction,
        partyName: party.name,
      );
    } catch (_) {
      // Reminder failure must not block ledger writes.
    }
  }

  Future<void> _syncTransactionReminder(TransactionModel transaction) async {
    final notifications = _notifications;
    if (notifications == null) return;

    try {
      await notifications.cancelTransactionReminder(transaction.id);
      if (transaction.type.isReceivableEntry) {
        await _scheduleReceivableReminder(transaction);
      }
    } catch (_) {}
  }

  Future<void> _cancelTransactionReminder(TransactionModel transaction) async {
    try {
      await _notifications?.cancelTransactionReminder(transaction.id);
    } catch (_) {}
  }
}
