import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';

/// Redirects unauthenticated users to the auth screen.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthService>()) {
      return const RouteSettings(name: AppRoutes.splash);
    }
    if (!Get.find<AuthService>().isSignedIn) {
      return const RouteSettings(name: AppRoutes.auth);
    }
    return null;
  }
}

/// Redirects authenticated users away from auth/sign-up screens.
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthService>()) {
      return const RouteSettings(name: AppRoutes.splash);
    }
    if (Get.find<AuthService>().isSignedIn) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    return null;
  }
}
