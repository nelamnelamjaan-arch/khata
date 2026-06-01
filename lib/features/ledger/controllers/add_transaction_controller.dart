import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_khata_manager/features/ledger/controllers/ledger_controller.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';
import 'package:smart_khata_manager/features/receipt/controllers/receipt_controller.dart';
import 'package:smart_khata_manager/features/receipt/models/parsed_receipt_data.dart';
import 'package:smart_khata_manager/features/receipt/models/receipt_scan_result.dart';

/// Manages the Add Transaction form, including AI auto-fill from receipts.
class AddTransactionController extends GetxController {
  AddTransactionController({
    LedgerController? ledgerController,
    ReceiptController? receiptController,
  })  : _ledger = ledgerController ?? Get.find<LedgerController>(),
        _receipt = receiptController ?? Get.find<ReceiptController>();

  final LedgerController _ledger;
  final ReceiptController _receipt;
  final _imagePicker = ImagePicker();

  final amountController = TextEditingController();
  final partyNameController = TextEditingController();
  final noteController = TextEditingController();

  final selectedDate = DateTime.now().obs;
  final selectedPartyId = RxnString();
  final transactionType = TransactionType.debit.obs;
  final isSubmitting = false.obs;
  final isScanning = false.obs;
  final lockPartySelection = false.obs;

  static const _offlineMessage =
      'AI parsing unavailable. Form auto-filled with raw text.';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Party) {
      _prefillParty(args);
    }
  }

  void _prefillParty(Party party) {
    lockPartySelection.value = true;
    selectedPartyId.value = party.id;
    partyNameController.text = party.name;
  }

  @override
  void onClose() {
    amountController.dispose();
    partyNameController.dispose();
    noteController.dispose();
    super.onClose();
  }

  /// Primary entry — opens camera, runs ML Kit OCR + Gemini AI parse.
  Future<void> scanReceipt() async {
    isScanning.value = true;
    try {
      final result = await _receipt.scanReceiptFromCamera();
      if (result != null && result.rawText.isNotEmpty) {
        _applyScanResult(result);
      }
    } finally {
      isScanning.value = false;
    }
  }

  /// Fallback — pick an existing photo from gallery.
  Future<void> scanReceiptFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    isScanning.value = true;
    try {
      final result = await _receipt.scanFromImage(File(picked.path));
      if (result.rawText.isNotEmpty) {
        _applyScanResult(result);
      }
    } finally {
      isScanning.value = false;
    }
  }

  /// Apply [ParsedReceiptData] and always store raw OCR text in [noteController].
  void applyParsedReceipt(ParsedReceiptData data, {required String rawOcrText}) {
    if (!lockPartySelection.value &&
        data.partyName != null &&
        data.partyName!.trim().isNotEmpty) {
      partyNameController.text = data.partyName!.trim();
      _matchExistingParty(data.partyName!.trim());
    }

    if (data.amount != null && data.amount! > 0) {
      amountController.text = data.amount!.toStringAsFixed(
        data.amount! % 1 == 0 ? 0 : 2,
      );
    }

    if (data.date != null) {
      selectedDate.value = data.date!;
    }

    noteController.text = rawOcrText;
  }

  void _applyScanResult(ReceiptScanResult result) {
    if (result.isOffline) {
      noteController.text = result.rawText;
      Get.snackbar('Offline', _offlineMessage, duration: const Duration(seconds: 4));
      return;
    }

    if (result.usedAiParsing && result.parsed != null) {
      applyParsedReceipt(result.parsed!, rawOcrText: result.rawText);
      Get.snackbar(
        'Smart Scan',
        'Date, amount, and party auto-filled from receipt.',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    noteController.text = result.rawText;
    final error = _receipt.errorMessage.value;
    Get.snackbar(
      'Partial scan',
      error ?? 'Raw OCR text added to Note. Review fields manually.',
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> submitTransaction() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('Validation', 'Enter a valid amount.');
      return;
    }

    final partyId = await _resolvePartyId();
    if (partyId == null) return;

    isSubmitting.value = true;
    try {
      await _ledger.addTransaction(
        partyId: partyId,
        amount: amount,
        type: transactionType.value,
        date: selectedDate.value,
        note: noteController.text.trim(),
      );
      Get.back(result: true);
      Get.snackbar('Success', 'Transaction saved.');
    } catch (_) {
      Get.snackbar('Error', _ledger.errorMessage.value ?? 'Failed to save.');
    } finally {
      isSubmitting.value = false;
    }
  }

  void _matchExistingParty(String name) {
    final match = _ledger.parties.firstWhereOrNull(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (match != null) selectedPartyId.value = match.id;
  }

  Future<String?> _resolvePartyId() async {
    if (selectedPartyId.value != null) return selectedPartyId.value;

    final name = partyNameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Validation', 'Enter or select a party name.');
      return null;
    }

    final existing = _ledger.parties.firstWhereOrNull(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );
    if (existing != null) return existing.id;

    final created = await _ledger.createParty(name: name, phone: '');
    return created.id;
  }
}
