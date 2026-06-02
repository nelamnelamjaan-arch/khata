import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/ai_service.dart';
import 'package:smart_khata_manager/core/services/firebase_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/services/notification_service.dart';
import 'package:smart_khata_manager/features/ledger/services/ledger_service.dart';
import 'package:smart_khata_manager/features/ocr/services/ocr_service.dart';

/// Registers GetX services synchronously — safe to call before [runApp].
void registerCoreServices() {
  if (!Get.isRegistered<NetworkService>()) {
    Get.put<NetworkService>(NetworkService(), permanent: true);
  }
  if (!Get.isRegistered<FirebaseService>()) {
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
  }
  if (!Get.isRegistered<AiService>()) {
    Get.put<AiService>(AiService(), permanent: true);
  }
  if (!Get.isRegistered<NotificationService>()) {
    Get.put<NotificationService>(NotificationService(), permanent: true);
  }
  if (!Get.isRegistered<OcrService>()) {
    Get.put<OcrService>(OcrService(), permanent: true);
  }
  if (!Get.isRegistered<LedgerService>()) {
    Get.put<LedgerService>(LedgerService(), permanent: true);
  }
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
