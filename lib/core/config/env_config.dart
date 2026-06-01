import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads and exposes environment variables (Gemini API key, etc.).
abstract final class EnvConfig {
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env', isOptional: true);
    } catch (_) {
      // .env is optional (e.g. missing on web build or first run).
    }
  }

  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
