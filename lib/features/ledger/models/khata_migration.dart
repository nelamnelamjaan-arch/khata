import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Purane Firestore records ko safely parse karein — kuch delete nahi hota.
///
/// Strategy:
/// 1. **Read-time defaults** — agar field missing ho to infer karo (app break nahi hoti).
/// 2. **Optional backfill** — [LedgerService.backfillLegacyFields] sirf missing
///    fields add karta hai; existing values overwrite nahi karta.
abstract final class KhataMigration {
  /// Party: purane docs mein `category` nahi → balance se guess.
  ///
  /// ```dart
  /// category: entry.category ?? (balance > 0 ? 'denay' : 'lenay')
  /// ```
  static KhataCategory resolvePartyCategory(
    Map<String, dynamic> map, {
    required double balance,
  }) {
    final raw = map['category'] ??
        map['bookCategory'] ??
        map['khataCategory'] ??
        map['khataType'] ??
        map['section'];
    if (raw != null && raw.toString().trim().isNotEmpty) {
      return KhataCategory.fromString(raw.toString());
    }
    // Purana data: positive balance = denay (payable), warna lenay.
    if (balance > 0) return KhataCategory.denay;
    return KhataCategory.lenay;
  }

  /// Transaction: `bookCategory` missing → entry type se infer.
  ///
  /// Agar purana doc sirf `type: debit/credit` rakhta ho:
  /// - debit → udhar_diya → lenay
  /// - credit → wasooli → lenay (default, user ki hidayat ke mutabiq)
  ///
  /// Agar `type` literally `lenay`/`denay` ho to bhi sahi map hota hai.
  static KhataCategory resolveBookCategory(
    Map<String, dynamic> map,
    TransactionType entryType, {
    KhataCategory? partyCategory,
  }) {
    final raw = map['bookCategory'] ??
        map['khataCategory'] ??
        map['khataType'] ??
        map['section'];

    // Kabhi purane docs mein `type` hi lenay/denay tha (entry type alag field mein).
    final typeField = map['type']?.toString().trim().toLowerCase();
    if (typeField == 'lenay' ||
        typeField == 'lena' ||
        typeField == 'receivable') {
      return KhataCategory.lenay;
    }
    if (typeField == 'denay' ||
        typeField == 'dena' ||
        typeField == 'payable') {
      return KhataCategory.denay;
    }

    if (raw != null && raw.toString().trim().isNotEmpty) {
      return KhataCategory.fromString(raw.toString());
    }

    // Party category se hint (backfill / linked parse).
    if (partyCategory != null) return partyCategory;

    // Default: entry type se — unknown → lenay (safe default).
    if (entryType.isDenaySide) return KhataCategory.denay;
    return KhataCategory.lenay;
  }

  /// Firestore doc mein `bookCategory` missing hai?
  static bool transactionNeedsBackfill(Map<String, dynamic> data) {
    final raw = data['bookCategory'] ??
        data['khataCategory'] ??
        data['khataType'] ??
        data['section'];
    return raw == null || raw.toString().trim().isEmpty;
  }

  /// Firestore doc mein party `category` missing hai?
  static bool partyNeedsBackfill(Map<String, dynamic> data) {
    final raw = data['category'] ??
        data['bookCategory'] ??
        data['khataCategory'];
    return raw == null || raw.toString().trim().isEmpty;
  }
}
