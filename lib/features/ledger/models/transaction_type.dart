import 'package:smart_khata_manager/core/config/app_constants.dart';

/// Khata entry type — odhaar dena (lenay) vs odhaar lena (denay).
enum TransactionType {
  /// Unhon ne aap se udhar liya — aap ke lenay badhenge.
  udharDiya('udhar_diya'),

  /// Unhon ne wapas diye — lenay kam honge.
  wasooli('wasooli'),

  /// Aap ne un se qarz / udhar liya — denay badhenge.
  qarzLiya('qarz_liya'),

  /// Aap ne unhe wapas day diye — denay kam honge.
  adaKiya('ada_kiya');

  const TransactionType(this.value);

  final String value;

  bool get isUdharDiya => this == TransactionType.udharDiya;
  bool get isWasooli => this == TransactionType.wasooli;
  bool get isQarzLiya => this == TransactionType.qarzLiya;
  bool get isAdaKiya => this == TransactionType.adaKiya;

  /// Lenay side (odhaar diya category).
  bool get isLenaySide => isUdharDiya || isWasooli;

  /// Denay side (odhaar liya category).
  bool get isDenaySide => isQarzLiya || isAdaKiya;

  /// Triggers payment reminder when a new receivable is created.
  bool get isReceivableEntry => isUdharDiya;

  /// Signed change to [Party.currentBalance] (negative = lenay, positive = denay).
  double balanceDeltaFor(double amount) {
    return switch (this) {
      TransactionType.udharDiya => -amount,
      TransactionType.wasooli => amount,
      TransactionType.qarzLiya => amount,
      TransactionType.adaKiya => -amount,
    };
  }

  /// Legacy helpers used by older code paths.
  bool get isDebit => isUdharDiya || isAdaKiya;
  bool get isCredit => isWasooli || isQarzLiya;

  static TransactionType fromString(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_');

    switch (normalized) {
      case 'udhar_diya':
      case 'udhardiya':
      case 'debit':
      case 'receivable':
      case 'lenay':
      case 'lena':
        return TransactionType.udharDiya;
      case 'wasooli':
      case 'wapas':
      case 'receive':
      case 'wasool':
      case 'credit':
        return TransactionType.wasooli;
      case 'qarz_liya':
      case 'qarzliya':
      case 'odhaar_liya':
      case 'payable':
      case 'denay':
      case 'dena':
      case 'pay':
        return TransactionType.qarzLiya;
      case 'ada_kiya':
      case 'adakiya':
      case 'day_diye':
      case 'wapas_diye':
        return TransactionType.adaKiya;
      default:
        return TransactionType.udharDiya;
    }
  }
}
