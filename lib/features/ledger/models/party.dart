import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_khata_manager/features/ledger/models/khata_category.dart';

/// A party (customer / supplier) in the khata ledger.
class Party {
  const Party({
    required this.id,
    required this.name,
    required this.phone,
    required this.currentBalance,
    required this.category,
  });

  final String id;
  final String name;
  final String phone;
  final double currentBalance;
  final KhataCategory category;

  bool get isReceivable => category == KhataCategory.lenay && currentBalance < 0;
  bool get isPayable => category == KhataCategory.denay && currentBalance > 0;
  double get receivableAmount =>
      category == KhataCategory.lenay && currentBalance < 0
          ? currentBalance.abs()
          : 0;
  double get payableAmount =>
      category == KhataCategory.denay && currentBalance > 0
          ? currentBalance
          : 0;

  bool get isSettled => currentBalance == 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'currentBalance': currentBalance,
        'category': category.value,
      };

  factory Party.fromMap(Map<String, dynamic> map) {
    final balance = _readBalance(map);
    return Party(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      phone: map['phone']?.toString() ?? '',
      currentBalance: balance,
      category: _readCategory(map, balance),
    );
  }

  factory Party.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Party.fromMap({...data, 'id': doc.id});
  }

  static KhataCategory _readCategory(Map<String, dynamic> map, double balance) {
    final raw = map['category']?.toString();
    if (raw != null && raw.isNotEmpty) {
      return KhataCategory.fromString(raw);
    }
    // Purane records: balance se guess karein.
    if (balance > 0) return KhataCategory.denay;
    return KhataCategory.lenay;
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
