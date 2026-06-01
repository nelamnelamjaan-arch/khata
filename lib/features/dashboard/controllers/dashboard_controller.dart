import 'dart:async';

import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';

/// Dashboard controller — live Firestore totals for receivable / payable.
class DashboardController extends GetxController {
  final totalReceivable = 0.0.obs;
  final totalPayable = 0.0.obs;
  final receivablePartyCount = 0.obs;
  final payablePartyCount = 0.obs;

  StreamSubscription<double>? _receivableSub;
  StreamSubscription<double>? _payableSub;
  StreamSubscription<List<Party>>? _partiesSub;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<LedgerService>()) return;

    final ledger = Get.find<LedgerService>();
    _receivableSub =
        ledger.watchTotalReceivable().listen(totalReceivable.call);
    _payableSub = ledger.watchTotalPayable().listen(totalPayable.call);
    _partiesSub = ledger.watchParties().listen((parties) {
      receivablePartyCount.value = parties.where((p) => p.isReceivable).length;
      payablePartyCount.value = parties.where((p) => p.isPayable).length;
    });
  }

  @override
  void onClose() {
    _receivableSub?.cancel();
    _payableSub?.cancel();
    _partiesSub?.cancel();
    super.onClose();
  }
}
