/// Live dashboard totals computed from Firestore data.
class DashboardSummary {
  const DashboardSummary({
    required this.totalReceivable,
    required this.totalPayable,
    required this.kulOdhaarDiya,
    required this.totalWasooli,
    required this.kulOdhaarLiya,
    required this.totalAdaKiya,
    required this.receivablePartyCount,
    required this.payablePartyCount,
    required this.transactionCount,
    required this.partyCount,
    required this.rawTransactionDocs,
  });

  final double totalReceivable;
  final double totalPayable;
  final double kulOdhaarDiya;
  final double totalWasooli;
  final double kulOdhaarLiya;
  final double totalAdaKiya;
  final int receivablePartyCount;
  final int payablePartyCount;
  final int transactionCount;
  final int partyCount;
  final int rawTransactionDocs;

  static const empty = DashboardSummary(
    totalReceivable: 0,
    totalPayable: 0,
    kulOdhaarDiya: 0,
    totalWasooli: 0,
    kulOdhaarLiya: 0,
    totalAdaKiya: 0,
    receivablePartyCount: 0,
    payablePartyCount: 0,
    transactionCount: 0,
    partyCount: 0,
    rawTransactionDocs: 0,
  );
}
