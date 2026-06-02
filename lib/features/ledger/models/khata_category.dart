import 'package:flutter/material.dart';
import 'package:smart_khata_manager/core/theme/app_colors.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Do alag khata books — odhaar unhon ne liya vs aap ne liya.
enum KhataCategory {
  /// Unhon ne aap se udhar liya — aap ke lenay hain.
  lenay('lenay'),

  /// Aap ne un se udhar liya — aap ke denay hain.
  denay('denay');

  const KhataCategory(this.value);

  final String value;

  static KhataCategory fromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'denay':
      case 'payable':
      case 'dena':
        return KhataCategory.denay;
      case 'lenay':
      case 'receivable':
      case 'lena':
      default:
        return KhataCategory.lenay;
    }
  }

  String get title => switch (this) {
        KhataCategory.lenay => 'Odhaar Unhon Ne Liya',
        KhataCategory.denay => 'Odhaar Maine Liya',
      };

  String get subtitle => switch (this) {
        KhataCategory.lenay => 'Wo aap ko den — lenay ka hisaab',
        KhataCategory.denay => 'Aap unhe den — denay ka hisaab',
      };

  String get addNameLabel => 'Naya Naam Add Karein';
  String get emptyHint => switch (this) {
        KhataCategory.lenay =>
          'Jis ne aap se udhar liya us ka naam yahan add karein',
        KhataCategory.denay =>
          'Jis se aap ne udhar liya us ka naam yahan add karein',
      };

  Color get color => switch (this) {
        KhataCategory.lenay => AppColors.receivable,
        KhataCategory.denay => AppColors.payable,
      };

  Color get bgColor => switch (this) {
        KhataCategory.lenay => AppColors.receivableLight,
        KhataCategory.denay => AppColors.payableLight,
      };

  IconData get icon => switch (this) {
        KhataCategory.lenay => Icons.arrow_downward,
        KhataCategory.denay => Icons.arrow_upward,
      };

  /// Sirf is category ke entry types.
  List<TransactionType> get entryTypes => switch (this) {
        KhataCategory.lenay => [
            TransactionType.udharDiya,
            TransactionType.wasooli,
          ],
        KhataCategory.denay => [
            TransactionType.qarzLiya,
            TransactionType.adaKiya,
          ],
      };

  TransactionType get defaultEntryType => entryTypes.first;

  String get kulLabel => switch (this) {
        KhataCategory.lenay => 'Kul odhaar diya',
        KhataCategory.denay => 'Kul odhaar liya',
      };

  String get wapasLabel => switch (this) {
        KhataCategory.lenay => 'Wasooli / Wapas mile',
        KhataCategory.denay => 'Ada kiya / Day diye',
      };

  String get baakiLabel => switch (this) {
        KhataCategory.lenay => 'Baaki lenay hain',
        KhataCategory.denay => 'Baaki denay hain',
      };

  bool allowsTransactionType(TransactionType type) => entryTypes.contains(type);
}
