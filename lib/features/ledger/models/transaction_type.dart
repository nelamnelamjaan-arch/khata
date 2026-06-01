import 'package:smart_khata_manager/core/config/app_constants.dart';

/// Credit / Debit entry type for khata transactions.
enum TransactionType {
  credit(AppConstants.entryCredit),
  debit(AppConstants.entryDebit);

  const TransactionType(this.value);

  final String value;

  bool get isCredit => this == TransactionType.credit;
  bool get isDebit => this == TransactionType.debit;
  bool get isReceivableEntry => isDebit;

  static TransactionType fromString(String raw) {
    final normalized = raw.trim().toLowerCase();

    switch (normalized) {
      case 'credit':
      case 'payable':
      case 'denay':
      case 'dena':
      case 'pay':
        return TransactionType.credit;
      case 'debit':
      case 'receivable':
      case 'lenay':
      case 'lena':
      case 'receive':
        return TransactionType.debit;
      default:
        return TransactionType.debit;
    }
  }
}
