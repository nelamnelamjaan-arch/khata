import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';

/// Shows Firebase status + one-tap connection test (use on mobile to verify deploy/cache).
class FirebaseConnectionPanel extends StatefulWidget {
  const FirebaseConnectionPanel({super.key});

  @override
  State<FirebaseConnectionPanel> createState() => _FirebaseConnectionPanelState();
}

class _FirebaseConnectionPanelState extends State<FirebaseConnectionPanel> {
  bool _testing = false;
  String? _testResult;

  Future<void> _runTest() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final firebase = Get.find<FirebaseService>();
    final result = await firebase.verifyConnection();

    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result.message;
    });

    Get.snackbar(
      result.ok ? 'Firebase OK' : 'Firebase failed',
      result.message,
      backgroundColor: result.ok ? AppColors.receivableLight : AppColors.payableLight,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebase = Get.find<FirebaseService>();

    return Obx(() {
      final ready = firebase.isFirestoreReady.value;
      final error = firebase.initError.value;

      return Card(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.cloud_done : Icons.cloud_off,
                    color: ready ? AppColors.receivable : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ready ? 'Firebase connected' : 'Firebase not connected',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'Build ${AppConstants.buildLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (error != null && !ready) ...[
                const SizedBox(height: 6),
                Text(
                  error,
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ],
              if (_testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _testResult!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _testing ? null : _runTest,
                icon: _testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(_testing ? 'Testing…' : 'Test Firebase (mobile check)'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
