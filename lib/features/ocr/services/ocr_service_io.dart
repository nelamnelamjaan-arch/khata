import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smart_khata_manager/core/services/ai_service.dart';
import 'package:smart_khata_manager/core/services/network_service.dart';
import 'package:smart_khata_manager/core/utils/platform_image.dart';
import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';

/// Hybrid OCR engine (mobile/desktop):
/// - **Offline** → Google ML Kit (on-device text extraction)
/// - **Online**  → [AiService] (Gemini structured parsing)
class OcrService extends GetxService {
  final TextRecognizer _recognizer = TextRecognizer();

  /// Extract raw text from an image using on-device ML Kit.
  Future<String> extractTextFromImage(PlatformImage imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// OCR + optional AI parse when online.
  Future<({String rawText, ParsedReceiptData? parsed})> scanReceipt(
    PlatformImage imageFile,
  ) async {
    final rawText = await extractTextFromImage(imageFile);

    ParsedReceiptData? parsed;
    final network = Get.find<NetworkService>();
    if (await network.checkOnline()) {
      try {
        final ai = Get.find<AiService>();
        parsed = await ai.parseReceiptText(rawText);
      } catch (_) {
        parsed = null;
      }
    }

    return (rawText: rawText, parsed: parsed);
  }

  @override
  void onClose() {
    _recognizer.close();
    super.onClose();
  }
}
