import 'package:cloud_firestore/cloud_firestore.dart';

/// A party (customer / supplier) in the khata ledger.
class Party {
  const Party({
    required this.id,
    required this.name,
    required this.phone,
    required this.currentBalance,
  });

  final String id;
  final String name;
  final String phone;
  final double currentBalance;

  bool get isReceivable => currentBalance < 0;
  bool get isPayable => currentBalance > 0;
  double get receivableAmount => isReceivable ? currentBalance.abs() : 0;
  double get payableAmount => isPayable ? currentBalance : 0;

  bool get isSettled => currentBalance == 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'currentBalance': currentBalance,
      };

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      phone: map['phone']?.toString() ?? '',
      currentBalance: _readBalance(map),
    );
  }

  factory Party.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Party.fromMap({...data, 'id': doc.id});
  }

  static double _readBalance(Map<String, dynamic> map) {
    final raw = map['currentBalance'] ??
        map['balance'] ??
        map['amount'] ??
        map['current_balance'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }
}
