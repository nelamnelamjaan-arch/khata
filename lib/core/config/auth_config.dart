import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OAuth / social sign-in configuration.
abstract final class AuthConfig {
  /// Web OAuth client ID from Firebase Console → Authentication → Google → Web SDK.
  /// Also add to `web/index.html` as `google-signin-client_id` meta tag.
  static String get googleWebClientId {
    const fromDefine = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromDotenv = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim();
    if (fromDotenv != null && fromDotenv.isNotEmpty) return fromDotenv;

    return '';
  }

  static bool get hasGoogleWebClientId => googleWebClientId.isNotEmpty;
}
