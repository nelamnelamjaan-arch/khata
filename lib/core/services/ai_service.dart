import 'dart:convert';

import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/core/config/env_config.dart';
import 'package:smart_khata_manager/core/services/ai_service_exception.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';

/// Gemini AI service — parses raw OCR/receipt text into structured data.
///
/// The API key is read securely from `.env` (`GEMINI_API_KEY`) via
/// [EnvConfig.geminiApiKey]. It is never hardcoded in source code.
class AiService extends GetxService {
  GenerativeModel? _model;

  /// Initializes Gemini using the key from [EnvConfig].
  Future<AiService> init() async {
    if (!EnvConfig.hasGeminiKey) {
      return this;
    }

    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: EnvConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );

    return this;
  }

  bool get isAvailable => _model != null;

  /// Parses messy receipt text into [ParsedReceiptData] using Gemini.
  ///
  /// Throws [AiServiceException] when offline, unconfigured, or on parse failure.
  Future<ParsedReceiptData> parseReceiptText(String rawText) async {
    if (_model == null) {
      throw AiServiceException(
        'Gemini API key is missing. Add GEMINI_API_KEY to your .env file.',
      );
    }

    if (rawText.trim().isEmpty) {
      throw AiServiceException('OCR text is empty — nothing to parse.');
    }

    final network = Get.find<NetworkService>();
    if (!await network.checkOnline()) {
      throw AiServiceException(
        'No internet connection. Gemini parsing requires online mode.',
      );
    }

    const prompt = '''
You are a receipt parser for a Pakistani khata (ledger) app.
Extract structured data from the OCR text below.

Return ONLY valid JSON with exactly these fields:
{
  "partyName": "string or null",
  "amount": number or null,
  "date": "ISO-8601 date string or null"
}

Rules:
- partyName: shop/person name from the receipt
- amount: numeric total only, no currency symbols
- date: ISO-8601 (YYYY-MM-DD) if detectable, else null

OCR Text:
''';

    try {
      final response = await _model!.generateContent([
        Content.text('$prompt$rawText'),
      ]);

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        throw AiServiceException('Gemini returned an empty response.');
      }

      return _parseResponseJson(text);
    } on AiServiceException {
      rethrow;
    } on GenerativeAIException catch (e) {
      throw AiServiceException(
        'Gemini API call failed: ${e.message}',
        cause: e,
      );
    } catch (e) {
      throw AiServiceException(
        'Unexpected error during receipt parsing.',
        cause: e,
      );
    }
  }

  ParsedReceiptData _parseResponseJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);

      if (decoded is! Map<String, dynamic>) {
        throw AiServiceException(
          'Invalid response format: expected a JSON object.',
        );
      }

      return ParsedReceiptData.fromJson(decoded);
    } on AiServiceException {
      rethrow;
    } on FormatException catch (e) {
      throw AiServiceException(
        'Could not decode Gemini response: ${e.message}',
        cause: e,
      );
    }
  }
}
