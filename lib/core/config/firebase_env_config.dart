import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_khata_manager/firebase_options.dart';

/// Resolves [FirebaseOptions] from `--dart-define`, `.env`, then FlutterFire defaults.
///
/// Web API keys are public in the client bundle; overrides are for Vercel/CI flexibility.
abstract final class FirebaseEnvConfig {
  // `--dart-define` values must use compile-time literal keys (not runtime variables).
  static const _defineApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _defineAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _defineMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _defineProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _defineAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _defineDatabaseUrl =
      String.fromEnvironment('FIREBASE_DATABASE_URL');
  static const _defineStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _defineMeasurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

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
      authDomain: _pickOptional('FIREBASE_AUTH_DOMAIN', defaults.authDomain),
      databaseURL: _pickOptional('FIREBASE_DATABASE_URL', defaults.databaseURL),
      storageBucket:
          _pickOptional('FIREBASE_STORAGE_BUCKET', defaults.storageBucket),
      measurementId:
          _pickOptional('FIREBASE_MEASUREMENT_ID', defaults.measurementId),
    );
  }

  static String _defineFor(String key) {
    return switch (key) {
      'FIREBASE_API_KEY' => _defineApiKey,
      'FIREBASE_APP_ID' => _defineAppId,
      'FIREBASE_MESSAGING_SENDER_ID' => _defineMessagingSenderId,
      'FIREBASE_PROJECT_ID' => _defineProjectId,
      'FIREBASE_AUTH_DOMAIN' => _defineAuthDomain,
      'FIREBASE_DATABASE_URL' => _defineDatabaseUrl,
      'FIREBASE_STORAGE_BUCKET' => _defineStorageBucket,
      'FIREBASE_MEASUREMENT_ID' => _defineMeasurementId,
      _ => '',
    };
  }

  static String _pick(String key, String fallback) {
    final fromDefine = _defineFor(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromDotenv = dotenv.env[key]?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

    return fallback;
  }

  static String? _pickOptional(String key, String? fallback) {
    final fromDefine = _defineFor(key);
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
      if (_defineFor(key).isNotEmpty) return true;
      final v = dotenv.env[key]?.trim();
      if (v != null && v.isNotEmpty) return true;
    }
    return false;
  }
}
