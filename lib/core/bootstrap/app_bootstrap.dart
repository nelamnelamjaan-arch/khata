import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/app/bindings/initial_binding.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';

/// Result of early app bootstrap (before [runApp]).
class AppBootstrapResult {
  const AppBootstrapResult({
    required this.firebaseReady,
    this.errorMessage,
  });

  final bool firebaseReady;
  final String? errorMessage;
}

/// Loads env + initializes Firebase with web-specific resilience.
Future<AppBootstrapResult> bootstrapApplication() async {
  await EnvConfig.load();

  final firebase = Get.find<FirebaseService>();

  try {
    final ready = await firebase.initWithRetry(
      maxAttempts: kIsWeb ? 3 : 2,
    );
    return AppBootstrapResult(
      firebaseReady: ready,
      errorMessage: ready ? null : firebase.initError.value,
    );
  } catch (e, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('bootstrapApplication failed: $e\n$stack');
    }
    return AppBootstrapResult(
      firebaseReady: false,
      errorMessage: e.toString(),
    );
  }
}
