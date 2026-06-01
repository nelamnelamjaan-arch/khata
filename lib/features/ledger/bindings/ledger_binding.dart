import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';

/// Registers [LedgerController] for ledger feature screens.
class LedgerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LedgerController>()) {
      Get.lazyPut<LedgerController>(() => LedgerController(), fenix: true);
    }
  }
}
