import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';
import 'package:smart_khata_manager/features/ledger/models/party.dart';
import 'package:smart_khata_manager/features/ledger/models/party_account_summary.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// Lenay / Denay filtering aur reduce-based totals.
abstract final class KhataCalculations {
  /// Sirf us category ki entries — mixed data nahi.
  static List<TransactionModel> filterByCategory(
    List<TransactionModel> entries,
    KhataCategory category,
  ) {
    return entries.where((e) => e.bookCategory == category).toList();
  }

  /// Kul udhar diya / liya — sirf lenay ya denay entries ka sum.
  static double kulUdhar(
    List<TransactionModel> entries,
    KhataCategory category,
  ) {
    return filterByCategory(entries, category).fold<double>(0, (sum, tx) {
      if (tx.amount <= 0) return sum;
      return switch (tx.type) {
        TransactionType.udharDiya || TransactionType.qarzLiya => sum + tx.amount,
        _ => sum,
      };
    });
  }

  /// Wasooli / ada kiya — sirf us category ka wapas sum.
  static double totalWapas(
    List<TransactionModel> entries,
    KhataCategory category,
  ) {
    return filterByCategory(entries, category).fold<double>(0, (sum, tx) {
      if (tx.amount <= 0) return sum;
      return switch (tx.type) {
        TransactionType.wasooli || TransactionType.adaKiya => sum + tx.amount,
        _ => sum,
      };
    });
  }

  /// Baaki raqam parties se — alag lenay aur denay totals.
  static double totalBaaki(
    List<Party> parties,
    KhataCategory category,
  ) {
    return parties
        .where((p) => p.category == category)
        .fold<double>(0, (sum, party) {
      if (category == KhataCategory.lenay) {
        return sum + party.receivableAmount;
      }
      return sum + party.payableAmount;
    });
  }

  /// Dashboard-style totals from all transactions.
  static ({double totalLenay, double totalDenay}) totalsFromTransactions(
    List<TransactionModel> entries,
  ) {
    final lenayEntries = entries.where((e) => e.bookCategory == KhataCategory.lenay);
    final denayEntries = entries.where((e) => e.bookCategory == KhataCategory.denay);

    double lenayBaaki = 0;
    for (final tx in lenayEntries) {
      lenayBaaki += tx.balanceDelta;
    }
    double denayBaaki = 0;
    for (final tx in denayEntries) {
      denayBaaki += tx.balanceDelta;
    }

    return (
      totalLenay: lenayBaaki < 0 ? lenayBaaki.abs() : 0,
      totalDenay: denayBaaki > 0 ? denayBaaki : 0,
    );
  }

  static PartyAccountSummary summarizeParty(
    KhataCategory category,
    List<TransactionModel> transactions, {
    double? currentBalance,
  }) {
    final filtered = filterByCategory(transactions, category);
    return PartyAccountSummary.fromTransactions(
      category,
      filtered,
      currentBalance: currentBalance,
    );
  }
}
