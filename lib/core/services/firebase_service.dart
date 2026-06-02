import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/firebase_env_config.dart';

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

  /// Idempotent init — safe from [main], splash, and retry.
  Future<FirebaseService> init() async {
    if (isFirestoreReady.value && _firestore != null) {
      return this;
    }

    final options = FirebaseEnvConfig.currentPlatform;

    if (_isPlaceholderConfig(options)) {
      initError.value =
          'Firebase not configured. Run:\n'
          '  flutterfire configure --project=khata-manager-ccf3a';
      isFirestoreReady.value = false;
      return this;
    }

    try {
      initError.value = null;
      await _ensureFirebaseApp(options);
      _firestore = FirebaseFirestore.instanceFor(app: Firebase.app());
      await _configureFirestore(_firestore!);
      isFirestoreReady.value = true;
    } catch (e, stack) {
      initError.value = _formatInitError(e);
      isFirestoreReady.value = false;
      _firestore = null;
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase init failed: $e\n$stack');
      }
    }
    return this;
  }

  Future<void> _ensureFirebaseApp(FirebaseOptions options) async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }

    try {
      await Firebase.initializeApp(options: options);
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app' || Firebase.apps.isNotEmpty) {
        return;
      }
      rethrow;
    } catch (e) {
      final message = e.toString();
      if (message.contains('duplicate-app') && Firebase.apps.isNotEmpty) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _configureFirestore(FirebaseFirestore db) async {
    if (kIsWeb) {
      db.settings = const Settings(
        persistenceEnabled: true,
        webExperimentalAutoDetectLongPolling: true,
      );
    } else {
      db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    try {
      await db.enableNetwork();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firestore enableNetwork (non-fatal): $e');
      }
    }
  }

  String _formatInitError(Object e) {
    final text = e.toString();
    if (kIsWeb && text.contains('network')) {
      return '$text\n\nTip: On mobile use normal browsing (not private), '
          'and add your *.vercel.app URL in Firebase Authorized domains.';
    }
    return text;
  }

  /// Retries init — splash / slow mobile networks.
  Future<bool> initWithRetry({int maxAttempts = 3}) async {
    if (isFirestoreReady.value && _firestore != null) return true;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      if (attempt > 1) {
        isFirestoreReady.value = false;
        _firestore = null;
      }
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
