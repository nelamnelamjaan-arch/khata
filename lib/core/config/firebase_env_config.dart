import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_khata_manager/firebase_options.dart';

/// Resolves [FirebaseOptions] from `--dart-define`, `.env`, then FlutterFire defaults.
///
/// Web API keys are public in the client bundle; overrides are for Vercel/CI flexibility.
abstract final class FirebaseEnvConfig {
  static FirebaseOptions get currentPlatform {
    final defaults = DefaultFirebaseOptions.currentPlatform;
    if (!kIsWeb) return defaults;
    return _withOverrides(defaults);
  }

  static FirebaseOptions _withOverrides(FirebaseOptions defaults) {
    return FirebaseOptions(
      apiKey: _pick('FIREBASE_API_KEY', defaults.apiKey),
      appId: _pick('FIREBASE_APP_ID', defaults.appId),
      messagingSenderId:
          _pick('FIREBASE_MESSAGING_SENDER_ID', defaults.messagingSenderId),
      projectId: _pick('FIREBASE_PROJECT_ID', defaults.projectId),
      authDomain: _pick('FIREBASE_AUTH_DOMAIN', defaults.authDomain),
      databaseURL: _pick('FIREBASE_DATABASE_URL', defaults.databaseURL),
      storageBucket: _pick('FIREBASE_STORAGE_BUCKET', defaults.storageBucket),
      measurementId: _pick('FIREBASE_MEASUREMENT_ID', defaults.measurementId),
    );
  }

  static String _pick(String key, String fallback) {
    final fromDefine = String.fromEnvironment(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromDotenv = dotenv.env[key]?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

    return fallback;
  }

  static bool get usesOverrides {
    if (!kIsWeb) return false;
    const keys = [
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID',
      'FIREBASE_PROJECT_ID',
    ];
    for (final key in keys) {
      if (String.fromEnvironment(key).isNotEmpty) return true;
      final v = dotenv.env[key]?.trim();
      if (v != null && v.isNotEmpty) return true;
    }
    return false;
  }
}
