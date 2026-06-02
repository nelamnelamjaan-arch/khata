import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/firebase_env_config.dart';

/// Result of [FirebaseService.verifyConnection] for mobile/desktop checks.
class FirebaseConnectionTestResult {
  const FirebaseConnectionTestResult({
    required this.ok,
    required this.message,
  });

  final bool ok;
  final String message;
}

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

      if (kDebugMode && !kIsWeb) {
        await _debugWriteTest();
      }
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

  Future<void> _debugWriteTest() async {
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

  /// One-tap check from dashboard — works on mobile browsers after Vercel deploy.
  Future<FirebaseConnectionTestResult> verifyConnection() async {
    if (!isFirestoreReady.value || _firestore == null) {
      final retry = await initWithRetry(maxAttempts: 2);
      if (!retry) {
        return FirebaseConnectionTestResult(
          ok: false,
          message: initError.value ?? 'Firestore not initialized.',
        );
      }
    }

    final db = _firestore!;
    try {
      final snap = await db
          .collection('_connection_test')
          .doc('ping')
          .get()
          .timeout(const Duration(seconds: 15));

      if (snap.exists) {
        return const FirebaseConnectionTestResult(
          ok: true,
          message: 'Read OK from Firestore (_connection_test/ping).',
        );
      }

      await db.collection('_connection_test').doc('ping').set({
        'ok': true,
        'checkedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'native',
      });

      return const FirebaseConnectionTestResult(
        ok: true,
        message: 'Write OK to Firestore (_connection_test/ping).',
      );
    } catch (e) {
      return FirebaseConnectionTestResult(
        ok: false,
        message: 'Firestore test failed: $e',
      );
    }
  }

  Future<void> syncPendingWrites() async {
    await _firestore?.waitForPendingWrites();
  }

  Future<void> goOffline() async => _firestore?.disableNetwork();

  Future<void> goOnline() async => _firestore?.enableNetwork();
}
