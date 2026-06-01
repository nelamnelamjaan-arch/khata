import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';

/// Result of the hybrid OCR + AI receipt scan pipeline.
class ReceiptScanResult {
  const ReceiptScanResult({
    required this.rawText,
    this.parsed,
    required this.usedAiParsing,
    this.isOffline = false,
  });

  final String rawText;
  final ParsedReceiptData? parsed;

  /// True when Gemini successfully parsed the OCR text.
  final bool usedAiParsing;

  /// True when device was offline — only raw OCR is available.
  final bool isOffline;
}
