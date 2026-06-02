import 'package:get/get.dart';
import 'package:smart_khata_manager/core/utils/platform_image.dart';
import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';

/// Web stub — ML Kit OCR is not available in the browser.
class OcrService extends GetxService {
  Future<String> extractTextFromImage(PlatformImage imageFile) async {
    throw UnsupportedError('Receipt OCR is not available on web.');
  }

  Future<({String rawText, ParsedReceiptData? parsed})> scanReceipt(
    PlatformImage imageFile,
  ) async {
    throw UnsupportedError('Receipt OCR is not available on web.');
  }
}
