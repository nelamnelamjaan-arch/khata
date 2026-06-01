import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/features/dashboard/views/dashboard_page.dart';
import 'package:smart_khata_manager/features/ledger/bindings/add_transaction_binding.dart';
import 'package:smart_khata_manager/features/ledger/bindings/ledger_binding.dart';
import 'package:smart_khata_manager/features/ledger/views/add_transaction_page.dart';
import 'package:smart_khata_manager/features/ledger/bindings/party_detail_binding.dart';
import 'package:smart_khata_manager/features/ledger/views/party_detail_page.dart';
import 'package:smart_khata_manager/features/ledger/views/parties_list_page.dart';
import 'package:smart_khata_manager/features/splash/views/splash_page.dart';

abstract final class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
    ),
    GetPage(
      name: AppRoutes.ledger,
      page: () => const PartiesListPage(),
      binding: LedgerBinding(),
    ),
    GetPage(
      name: AppRoutes.partyDetail,
      page: () => const PartyDetailPage(),
      binding: PartyDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.addTransaction,
      page: () => const AddTransactionPage(),
      binding: AddTransactionBinding(),
    ),
  ];
}
