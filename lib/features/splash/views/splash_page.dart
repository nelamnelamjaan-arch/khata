import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';
import 'package:smart_khata_manager/app/routes/app_routes.dart';

/// Splash screen — verifies services are ready, then navigates to dashboard.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await initCoreServices();

    if (!mounted) return;

    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 72, color: Color(0xFF1565C0)),
            SizedBox(height: 24),
            Text(
              'Smart Khata Manager',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
