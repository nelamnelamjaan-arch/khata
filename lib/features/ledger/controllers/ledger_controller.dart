import 'dart:async';

import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';

/// GetX controller — reactive state layer over [LedgerService].
class LedgerController extends GetxController {
  LedgerController({LedgerService? ledgerService})
      : _ledger = ledgerService ?? Get.find<LedgerService>();

  final LedgerService _ledger;

  // ── Reactive state ────────────────────────────────────────────────────────
  final parties = <Party>[].obs;
  final transactions = <TransactionModel>[].obs;
  final selectedParty = Rxn<Party>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  StreamSubscription<List<Party>>? _partiesSub;
  StreamSubscription<List<TransactionModel>>? _transactionsSub;

  @override
  void onInit() {
    super.onInit();
    _listenToParties();
  }

  @override
  void onClose() {
    _partiesSub?.cancel();
    _transactionsSub?.cancel();
    super.onClose();
  }

  // ── Party operations ──────────────────────────────────────────────────────

  Future<Party> createParty({
    required String name,
    required String phone,
  }) async {
    Party? created;
    await _runGuarded(() async {
      created = await _ledger.createParty(name: name, phone: phone);
    });
    if (created == null) {
      throw StateError(errorMessage.value ?? 'Failed to create party');
    }
    return created!;
  }

  Future<void> updateParty(Party party) async {
    await _runGuarded(() async {
      await _ledger.updateParty(party);
    });
  }

  Future<void> deleteParty(String partyId) async {
    await _runGuarded(() async {
      await _ledger.deleteParty(partyId);
      if (selectedParty.value?.id == partyId) {
        selectedParty.value = null;
        transactions.clear();
        _transactionsSub?.cancel();
      }
    });
  }

  /// Select a party and stream its transactions in real time.
  void selectParty(Party party) {
    selectedParty.value = party;
    _transactionsSub?.cancel();
    _transactionsSub = _ledger.watchTransactionsByParty(party.id).listen(
          transactions.assignAll,
          onError: (Object e) => errorMessage.value = e.toString(),
        );
  }

  void clearSelection() {
    selectedParty.value = null;
    transactions.clear();
    _transactionsSub?.cancel();
  }

  // ── Transaction operations ────────────────────────────────────────────────

  Future<void> addTransaction({
    required String partyId,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
  }) async {
    await _runGuarded(() async {
      await _ledger.addTransaction(
        partyId: partyId,
        amount: amount,
        type: type,
        date: date,
        note: note,
      );
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _runGuarded(() async {
      await _ledger.updateTransaction(transaction);
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _runGuarded(() async {
      await _ledger.deleteTransaction(transactionId);
    });
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _listenToParties() {
    _partiesSub = _ledger.watchParties().listen(
      (list) {
        parties.assignAll(list);

        // Keep selected party in sync with latest balance
        final selected = selectedParty.value;
        if (selected != null) {
          final updated = list.where((p) => p.id == selected.id).firstOrNull;
          if (updated != null) selectedParty.value = updated;
        }
      },
      onError: (Object e) => errorMessage.value = e.toString(),
    );
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      await action();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
