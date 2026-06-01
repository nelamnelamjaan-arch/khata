import 'dart:io';

import 'package:get/get.dart';
import 'package:smart_khata_manager/core/services/ai_service.dart';
import 'package:smart_khata_manager/core/services/ai_service_exception.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/features/ocr/services/ocr_service.dart';
import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';
import 'package:smart_khata_manager/features/receipt/models/receipt_scan_result.dart';
import 'package:smart_khata_manager/features/receipt/views/receipt_camera_page.dart';

/// Orchestrates camera → ML Kit OCR → Gemini AI receipt scanning.
class ReceiptController extends GetxController {
  ReceiptController({
    OcrService? ocrService,
    AiService? aiService,
    NetworkService? networkService,
  })  : _ocr = ocrService ?? Get.find<OcrService>(),
        _ai = aiService ?? Get.find<AiService>(),
        _network = networkService ?? Get.find<NetworkService>();

  final OcrService _ocr;
  final AiService _ai;
  final NetworkService _network;

  final isProcessing = false.obs;
  final rawOcrText = RxnString();
  final parsedReceipt = Rxn<ParsedReceiptData>();
  final errorMessage = RxnString();

  /// Opens [ReceiptCameraPage] and runs the full scan pipeline.
  Future<ReceiptScanResult?> scanReceiptFromCamera() async {
    final imageFile = await Get.to<File>(() => const ReceiptCameraPage());
    if (imageFile == null) return null;
    return scanFromImage(imageFile);
  }

  /// Image → ML Kit OCR → Gemini parse (when online).
  Future<ReceiptScanResult> scanFromImage(File imageFile) async {
    isProcessing.value = true;
    errorMessage.value = null;
    parsedReceipt.value = null;

    try {
      final rawText = await _ocr.extractTextFromImage(imageFile);
      rawOcrText.value = rawText;

      if (rawText.trim().isEmpty) {
        errorMessage.value = 'No text detected on the receipt.';
        return ReceiptScanResult(rawText: '', usedAiParsing: false);
      }

      final online = await _network.checkOnline();
      if (!online) {
        return ReceiptScanResult(
          rawText: rawText,
          usedAiParsing: false,
          isOffline: true,
        );
      }

      try {
        final parsed = await _ai.parseReceiptText(rawText);
        parsedReceipt.value = parsed;
        return ReceiptScanResult(
          rawText: rawText,
          parsed: parsed,
          usedAiParsing: true,
        );
      } on AiServiceException catch (e) {
        errorMessage.value = e.message;
        return ReceiptScanResult(
          rawText: rawText,
          usedAiParsing: false,
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to scan receipt: $e';
      return ReceiptScanResult(rawText: '', usedAiParsing: false);
    } finally {
      isProcessing.value = false;
    }
  }

  void clear() {
    rawOcrText.value = null;
    parsedReceipt.value = null;
    errorMessage.value = null;
  }
}
