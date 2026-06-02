import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_pages.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/theme/app_theme.dart';

class SmartKhataApp extends StatelessWidget {
  const SmartKhataApp({super.key});

  static const _protectedRoutes = {
    AppRoutes.dashboard,
    AppRoutes.ledger,
    AppRoutes.partyDetail,
    AppRoutes.addTransaction,
  };

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      routingCallback: _guardProtectedRoutes,
    );
  }

  /// Blocks direct hash URLs like /#/dashboard when the user is not signed in.
  void _guardProtectedRoutes(Routing? routing) {
    final current = routing?.current;
    if (current == null || !_protectedRoutes.contains(current)) return;
    if (!Get.isRegistered<AuthService>()) return;
    if (!Get.find<AuthService>().isSignedIn) {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
