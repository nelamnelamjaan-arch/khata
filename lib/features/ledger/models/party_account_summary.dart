import 'package:smart_khata_manager/features/ledger/models/transaction.dart';

/// Per-party khata breakdown — kitna lena/dena tha, kitna mila/diya, kitna baaki.
class PartyAccountSummary {
  const PartyAccountSummary({
    required this.totalUdhar,
    required this.totalWasooli,
    required this.currentBalance,
  });

  /// Sum of all [debit] entries — udhar diya / unhe diye.
  final double totalUdhar;

  /// Sum of all [credit] entries — wapas mile / qarz liya.
  final double totalWasooli;

  /// Live balance from Firestore (credits − debits from zero).
  final double currentBalance;

  bool get isReceivable => currentBalance < 0;
  bool get isPayable => currentBalance > 0;
  bool get isSettled => currentBalance == 0;

  /// Baaki lenay hain (wo aap ko den).
  double get baakiLenay => isReceivable ? currentBalance.abs() : 0;

  /// Baaki denay hain (aap unhe den).
  double get baakiDenay => isPayable ? currentBalance : 0;

  /// Receivable side: kul udhar diya tha.
  double get kulLenayThay => totalUdhar;

  /// Receivable side: wapas mil chuka.
  double get wapasMile => totalWasooli;

  /// Payable side: kul dena tha / qarz liya.
  double get kulDenayThay => totalWasooli;

  /// Payable side: unhe day diye.
  double get dayDiye => totalUdhar;

  static PartyAccountSummary fromTransactions(
    List<TransactionModel> transactions, {
    double? currentBalance,
  }) {
    var udhar = 0.0;
    var wasooli = 0.0;

    for (final tx in transactions) {
      if (tx.amount <= 0) continue;
      if (tx.isDebit) {
        udhar += tx.amount;
      } else {
        wasooli += tx.amount;
      }
    }

    final balance = currentBalance ?? (wasooli - udhar);

    return PartyAccountSummary(
      totalUdhar: udhar,
      totalWasooli: wasooli,
      currentBalance: balance,
    );
  }

  static const empty = PartyAccountSummary(
    totalUdhar: 0,
    totalWasooli: 0,
    currentBalance: 0,
  );
}
