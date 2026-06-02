import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Per-party khata breakdown — sirf us category ka hisaab.
class PartyAccountSummary {
  const PartyAccountSummary({
    required this.category,
    required this.kulOdhaar,
    required this.totalWapas,
    required this.currentBalance,
  });

  final KhataCategory category;
  final double kulOdhaar;
  final double totalWapas;
  final double currentBalance;

  double get baaki => category == KhataCategory.lenay
      ? (currentBalance < 0 ? currentBalance.abs() : 0)
      : (currentBalance > 0 ? currentBalance : 0);

  bool get isSettled => currentBalance == 0;
  bool get hasActivity => kulOdhaar > 0 || totalWapas > 0;

  static PartyAccountSummary fromTransactions(
    KhataCategory category,
    List<TransactionModel> transactions, {
    double? currentBalance,
  }) {
    var kul = 0.0;
    var wapas = 0.0;
    var computedBalance = 0.0;

    for (final tx in transactions) {
      if (tx.amount <= 0) continue;
      switch (tx.type) {
        case TransactionType.udharDiya:
        case TransactionType.qarzLiya:
          kul += tx.amount;
        case TransactionType.wasooli:
        case TransactionType.adaKiya:
          wapas += tx.amount;
      }
      computedBalance += tx.balanceDelta;
    }

    return PartyAccountSummary(
      category: category,
      kulOdhaar: kul,
      totalWapas: wapas,
      currentBalance: currentBalance ?? computedBalance,
    );
  }

  static const empty = PartyAccountSummary(
    category: KhataCategory.lenay,
    kulOdhaar: 0,
    totalWapas: 0,
    currentBalance: 0,
  );
}
