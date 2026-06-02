import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_pages.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/theme/app_theme.dart';
import 'package:smart_khata_manager/features/splash/views/splash_page.dart';

class SmartKhataApp extends StatelessWidget {
  const SmartKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Always boot via splash — it initializes Firebase then routes onward.
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      unknownRoute: GetPage(
        name: AppRoutes.splash,
        page: () => const SplashPage(),
      ),
    );
  }
}
