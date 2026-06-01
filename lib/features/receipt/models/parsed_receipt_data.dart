/// Structured receipt fields extracted by [AiService].
class ParsedReceiptData {
  const ParsedReceiptData({
    this.partyName,
    this.amount,
    this.date,
  });

  final String? partyName;
  final double? amount;
  final DateTime? date;

  bool get hasAnyField =>
      partyName != null || amount != null || date != null;

  factory ParsedReceiptData.fromJson(Map<String, dynamic> json) {
    final partyName = json['partyName'];
    final amount = json['amount'];
    final date = json['date'];

    if (partyName != null && partyName is! String) {
      throw FormatException('partyName must be a string or null');
    }
    if (amount != null && amount is! num) {
      throw FormatException('amount must be a number or null');
    }
    if (date != null && date is! String) {
      throw FormatException('date must be an ISO-8601 string or null');
    }

    return ParsedReceiptData(
      partyName: partyName as String?,
      amount: (amount as num?)?.toDouble(),
      date: date != null ? DateTime.tryParse(date as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'partyName': partyName,
        'amount': amount,
        'date': date?.toIso8601String(),
      };
}
