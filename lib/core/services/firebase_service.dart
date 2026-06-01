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

  Future<FirebaseService> init() async {
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
      await Firebase.initializeApp(options: options);

      _firestore = FirebaseFirestore.instance;

      if (!kIsWeb) {
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      await _firestore!.enableNetwork();
      isFirestoreReady.value = true;

      if (kDebugMode) {
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
    } catch (e) {
      initError.value = e.toString();
      isFirestoreReady.value = false;
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase init failed: $e');
      }
    }
    return this;
  }

  Future<void> syncPendingWrites() async {
    await _firestore?.waitForPendingWrites();
  }

  Future<void> goOffline() async => _firestore?.disableNetwork();

  Future<void> goOnline() async => _firestore?.enableNetwork();
}
