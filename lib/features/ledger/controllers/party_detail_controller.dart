import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Controller for the party detail screen — streams transactions for one party.
class PartyDetailController extends GetxController {
  PartyDetailController({LedgerController? ledgerController})
      : _ledger = ledgerController ?? Get.find<LedgerController>();

  final LedgerController _ledger;

  late final Party party;

  LedgerController get ledger => _ledger;

  /// Latest party data (balance updates in real time from Firestore).
  Party get currentParty => _ledger.selectedParty.value ?? party;

  List<TransactionModel> get transactions => _ledger.transactions;

  @override
  void onInit() {
    super.onInit();
    party = Get.arguments as Party;
    _ledger.selectParty(party);
  }

  @override
  void onClose() {
    _ledger.clearSelection();
    super.onClose();
  }

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime date,
    String note = '',
  }) async {
    await _ledger.addTransaction(
      partyId: party.id,
      amount: amount,
      type: type,
      date: date,
      note: note,
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _ledger.deleteTransaction(transactionId);
  }
}
