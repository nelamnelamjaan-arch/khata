import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';

/// Result of early app bootstrap (before [runApp]).
class AppBootstrapResult {
  const AppBootstrapResult({
    required this.firebaseReady,
    required this.authInitialized,
    this.errorMessage,
  });

  final bool firebaseReady;
  final bool authInitialized;
  final String? errorMessage;
}

/// Loads env + initializes Firebase and the auth listener.
Future<AppBootstrapResult> bootstrapApplication() async {
  await EnvConfig.load();

  final firebase = Get.find<FirebaseService>();
  final auth = Get.find<AuthService>();

  try {
    final ready = await firebase.initWithRetry(
      maxAttempts: kIsWeb ? 3 : 2,
    );

    if (!ready) {
      return AppBootstrapResult(
        firebaseReady: false,
        authInitialized: false,
        errorMessage: firebase.initError.value,
      );
    }

    await auth.init();
    return const AppBootstrapResult(
      firebaseReady: true,
      authInitialized: true,
    );
  } catch (e, stack) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('bootstrapApplication failed: $e\n$stack');
    }
    return AppBootstrapResult(
      firebaseReady: false,
      authInitialized: false,
      errorMessage: e.toString(),
    );
  }
}
