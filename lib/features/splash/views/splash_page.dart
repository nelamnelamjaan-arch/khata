import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/ai_service.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';

/// Splash — initializes Firebase, then routes to auth or dashboard.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await EnvConfig.load();

      try {
        await Get.find<NetworkService>().init();
      } catch (e) {
        if (kDebugMode) print('NetworkService init: $e');
      }

      final firebase = Get.find<FirebaseService>();
      final firebaseOk = firebase.isFirestoreReady.value ||
          await firebase.initWithRetry(maxAttempts: 3);

      if (!firebaseOk) {
        final detail =
            firebase.initError.value ?? 'Could not connect to Firebase.';
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = detail;
        });
        return;
      }

      final auth = Get.find<AuthService>();
      await auth.init();

      try {
        await Get.find<AiService>().init();
      } catch (e) {
        if (kDebugMode) print('AiService init: $e');
      }

      if (!mounted) return;
      final nextRoute =
          auth.isSignedIn ? AppRoutes.dashboard : AppRoutes.auth;
      Get.offAllNamed(nextRoute);
    } catch (e, stack) {
      if (kDebugMode) print('Splash bootstrap failed: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 72,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(height: 24),
              const Text(
                'Smart Khata Manager',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              if (_loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Connecting to Firebase…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ] else if (_error != null) ...[
                Icon(Icons.cloud_off, size: 48, color: Colors.orange.shade700),
                const SizedBox(height: 16),
                Text(
                  'Startup failed',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add khata-caet.vercel.app under Firebase → Authentication → Authorized domains, then retry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _bootstrap,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
