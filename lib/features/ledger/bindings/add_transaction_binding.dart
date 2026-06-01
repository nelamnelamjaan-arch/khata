import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/controllers/add_transaction_controller.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/receipt/controllers/receipt_controller.dart';

/// Registers controllers for the Add Transaction screen.
class AddTransactionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LedgerController>()) {
      Get.lazyPut<LedgerController>(() => LedgerController(), fenix: true);
    }
    Get.lazyPut<ReceiptController>(() => ReceiptController(), fenix: true);
    Get.lazyPut<AddTransactionController>(
      () => AddTransactionController(),
      fenix: true,
    );
  }
}
