import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Urdu labels for khata entry types.
abstract final class KhataLabels {
  static String entryTypeLabel(TransactionType type) {
    return type.isDebit ? 'Udhar diya (Lenay hain)' : 'Wasooli / Wapas mila';
  }

  static String entryTypeShort(TransactionType type) {
    return type.isDebit ? 'Udhar' : 'Wasooli';
  }

  static String entryDescription(TransactionType type) {
    if (type.isDebit) {
      return 'Unhon ne aap se udhar liya — lenay hain badhenge';
    }
    return 'Unhon ne wapas diye — lenay hain kam honge';
  }

  static const addPartyHint =
      'Har shakhs ka alag khata — jitne marzi log add kar sakte hain';

  static const partiesTitle = 'Khata Book';
}
