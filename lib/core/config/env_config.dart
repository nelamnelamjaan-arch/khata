import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads and exposes environment variables (Gemini API key, etc.).
abstract final class EnvConfig {
  static Future<void> load() async {
    for (final file in ['.env', '.env.example']) {
      try {
        await dotenv.load(fileName: file, isOptional: true);
        if (hasGeminiKey) return;
      } catch (_) {
        // Try next file (local .env is gitignored; CI uses .env.example).
      }
    }
  }

  static String get geminiApiKey => (dotenv.env['GEMINI_API_KEY'] ?? '').trim();
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
