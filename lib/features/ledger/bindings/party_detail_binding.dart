import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/controllers/party_detail_controller.dart';

/// Registers [PartyDetailController] and shared [LedgerController].
class PartyDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LedgerController>()) {
      Get.lazyPut<LedgerController>(() => LedgerController(), fenix: true);
    }
    Get.lazyPut<PartyDetailController>(() => PartyDetailController());
  }
}
