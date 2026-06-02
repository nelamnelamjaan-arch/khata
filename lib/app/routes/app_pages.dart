import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/features/auth/auth.dart';
import 'package:smart_khata_manager/features/dashboard/views/dashboard_page.dart';
import 'package:smart_khata_manager/features/ledger/bindings/add_transaction_binding.dart';
import 'package:smart_khata_manager/features/ledger/bindings/ledger_binding.dart';
import 'package:smart_khata_manager/features/ledger/views/add_transaction_page.dart';
import 'package:smart_khata_manager/features/ledger/bindings/party_detail_binding.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/views/category_khata_page.dart';
import 'package:smart_khata_manager/features/ledger/views/khata_book_tabs_page.dart';
import 'package:smart_khata_manager/features/ledger/views/party_detail_page.dart';
import 'package:smart_khata_manager/features/splash/views/splash_page.dart';

abstract final class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthScreen(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignupPage(),
      binding: AuthBinding(),
      middlewares: [GuestMiddleware()],
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ledger,
      page: () => const KhataBookTabsPage(),
      binding: LedgerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ledgerLenay,
      page: () => const CategoryKhataPage(category: KhataCategory.lenay),
      binding: LedgerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ledgerDenay,
      page: () => const CategoryKhataPage(category: KhataCategory.denay),
      binding: LedgerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.partyDetail,
      page: () => const PartyDetailPage(),
      binding: PartyDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.addTransaction,
      page: () => const AddTransactionPage(),
      binding: AddTransactionBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
