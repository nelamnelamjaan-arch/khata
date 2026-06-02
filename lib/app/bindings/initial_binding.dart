import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/ai_service.dart';
import 'package:smart_khata_manager/core/services/auth_service.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/services/notification_service.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';
import 'package:smart_khata_manager/features/ocr/services/ocr_service.dart';

/// Registers GetX services synchronously — safe to call before [runApp].
void registerCoreServices() {
  void put<T extends GetxService>(T Function() factory, String label) {
    if (Get.isRegistered<T>()) return;
    try {
      Get.put<T>(factory(), permanent: true);
    } catch (e, stack) {
      if (kDebugMode) print('$label registration failed: $e\n$stack');
      throw StateError('$label: $e');
    }
  }

  put<NetworkService>(() => NetworkService(), 'NetworkService');
  put<FirebaseService>(() => FirebaseService(), 'FirebaseService');
  put<AuthService>(() => AuthService(), 'AuthService');
  put<AiService>(() => AiService(), 'AiService');
  put<NotificationService>(
    () => NotificationService(),
    'NotificationService',
  );
  put<OcrService>(() => OcrService(), 'OcrService');
  put<LedgerService>(() => LedgerService(), 'LedgerService');
}

/// Async initialization — Firebase, network, AI, notifications.
Future<void> initCoreServices() async {
  await EnvConfig.load();

  try {
    await Get.find<NetworkService>().init();
  } catch (e) {
    if (kDebugMode) print('NetworkService init: $e');
  }

  final firebase = Get.find<FirebaseService>();
  if (!firebase.isFirestoreReady.value) {
    try {
      await firebase.initWithRetry(maxAttempts: 3);
    } catch (e) {
      if (kDebugMode) print('FirebaseService init: $e');
    }
  }

  if (firebase.isFirestoreReady.value) {
    try {
      await Get.find<AuthService>().init();
    } catch (e) {
      if (kDebugMode) print('AuthService init: $e');
    }
  }

  try {
    await Get.find<AiService>().init();
  } catch (e) {
    if (kDebugMode) print('AiService init: $e');
  }

  if (!kIsWeb) {
    try {
      final notifications = Get.find<NotificationService>();
      await notifications.init();
      await notifications.requestPermissions();
    } catch (e) {
      if (kDebugMode) print('NotificationService init: $e');
    }
  }
}

/// Legacy entry — kept for tests / scripts.
Future<void> bootstrapApp() async {
  registerCoreServices();
  await initCoreServices();
}
