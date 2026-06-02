import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Urdu labels for khata entry types.
abstract final class KhataLabels {
  static String entryTypeLabel(TransactionType type) {
    return switch (type) {
      TransactionType.udharDiya => 'Odhaar diya (Lenay hain)',
      TransactionType.wasooli => 'Wasooli / Wapas mile',
      TransactionType.qarzLiya => 'Odhaar liya (Denay hain)',
      TransactionType.adaKiya => 'Ada kiya / Day diye',
    };
  }

  static String entryTypeShort(TransactionType type) {
    return switch (type) {
      TransactionType.udharDiya => 'Odhaar diya',
      TransactionType.wasooli => 'Wasooli',
      TransactionType.qarzLiya => 'Odhaar liya',
      TransactionType.adaKiya => 'Ada kiya',
    };
  }

  static String entryDescription(TransactionType type) {
    return switch (type) {
      TransactionType.udharDiya =>
        'Unhon ne aap se udhar liya — lenay hain badhenge',
      TransactionType.wasooli =>
        'Unhon ne wapas diye — lenay hain kam honge',
      TransactionType.qarzLiya =>
        'Aap ne un se udhar liya — denay hain badhenge',
      TransactionType.adaKiya =>
        'Aap ne unhe wapas day diye — denay hain kam honge',
    };
  }

  static const lenaySectionTitle = 'Odhaar diya — Lenay hain';
  static const denaySectionTitle = 'Odhaar liya — Denay hain';

  static const addPartyHint =
      'Har shakhs ka alag khata — jitne marzi log add kar sakte hain';

  static const partiesTitle = 'Khata Book';
}
