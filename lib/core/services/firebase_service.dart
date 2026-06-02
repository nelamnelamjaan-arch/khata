import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/firebase_options.dart';

/// Central Firebase bootstrap with **offline-first** Firestore persistence.
class FirebaseService extends GetxService {
  FirebaseFirestore? _firestore;

  FirebaseFirestore? get firestore => _firestore;

  final RxBool isFirestoreReady = false.obs;
  final RxnString initError = RxnString();

  static bool _isPlaceholderConfig(FirebaseOptions options) {
    return options.apiKey.contains('YOUR_') ||
        options.appId.contains('YOUR_') ||
        options.projectId.contains('YOUR_');
  }

  /// Idempotent init — safe to call from [main] and splash retry.
  Future<FirebaseService> init() async {
    if (isFirestoreReady.value && _firestore != null) {
      return this;
    }

    final options = DefaultFirebaseOptions.currentPlatform;

    if (_isPlaceholderConfig(options)) {
      initError.value =
          'Firebase not configured. Run:\n'
          '  firebase login\n'
          '  flutterfire configure --project=khata-manager-ccf3a';
      isFirestoreReady.value = false;
      return this;
    }

    try {
      initError.value = null;

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }

      _firestore = FirebaseFirestore.instance;

      if (kIsWeb) {
        // Mobile Safari / strict networks: long-polling avoids WebChannel failures.
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          webExperimentalAutoDetectLongPolling: true,
        );
      } else {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      try {
        await _firestore!.enableNetwork();
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Firestore enableNetwork (non-fatal): $e');
        }
      }

      isFirestoreReady.value = true;

      // Debug write test — desktop only; skipped on web (Safari/mobile can fail).
      if (kDebugMode && !kIsWeb) {
        try {
          await _firestore!
              .collection('_connection_test')
              .doc('ping')
              .set({'ok': true, 'at': FieldValue.serverTimestamp()});
        } catch (e) {
          initError.value =
              'Firestore write test failed: $e\n'
              'Run: firebase deploy --only firestore:rules';
        }
      }
    } catch (e, stack) {
      initError.value = e.toString();
      isFirestoreReady.value = false;
      _firestore = null;
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase init failed: $e\n$stack');
      }
    }
    return this;
  }

  /// Retries init — used on splash when mobile networks are slow or flaky.
  Future<bool> initWithRetry({int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      isFirestoreReady.value = false;
      _firestore = null;
      await init();
      if (isFirestoreReady.value) return true;
      if (attempt < maxAttempts) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
    return false;
  }

  Future<void> syncPendingWrites() async {
    await _firestore?.waitForPendingWrites();
  }

  Future<void> goOffline() async => _firestore?.disableNetwork();

  Future<void> goOnline() async => _firestore?.enableNetwork();
}
