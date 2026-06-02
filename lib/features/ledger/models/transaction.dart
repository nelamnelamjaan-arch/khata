import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction_type.dart';

/// A credit/debit ledger entry linked to a [Party].
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.partyId,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
  });

  final String id;
  final String partyId;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String note;

  bool get isCredit => type.isCredit;
  bool get isDebit => type.isDebit;

  /// Signed delta applied to [Party.currentBalance].
  double get balanceDelta => type.balanceDeltaFor(amount);

  Map<String, dynamic> toMap() => {
        'id': id,
        'partyId': partyId,
        'amount': amount,
        'type': type.value,
        'date': Timestamp.fromDate(date),
        'note': note,
      };

  /// Parses app-written docs and manual/dummy Firestore entries.
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String? ?? '',
      partyId: _readPartyId(map),
      amount: _readAmount(map),
      type: TransactionType.fromString(_readTypeRaw(map)),
      date: _parseDate(map['date']),
      note: map['note'] as String? ?? map['description'] as String? ?? '',
    );
  }

  factory TransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return TransactionModel.fromMap({...data, 'id': doc.id});
  }

  /// Safe parse — skips malformed manual/dummy documents.
  static TransactionModel? tryFromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data == null || data.isEmpty) return null;
      final amount = _readAmount(data);
      if (amount <= 0) return null;
      return TransactionModel.fromMap({...data, 'id': doc.id});
    } catch (_) {
      return null;
    }
  }

  static String _readPartyId(Map<String, dynamic> map) {
    final raw = map['partyId'] ?? map['party_id'] ?? map['party'];
    return raw?.toString() ?? '';
  }

  static double _readAmount(Map<String, dynamic> map) {
    const keys = [
      'amount',
      'totalAmount',
      'total',
      'value',
      'price',
      'rs',
    ];
    for (final key in keys) {
      final raw = map[key];
      if (raw is num) return raw.toDouble();
      if (raw is String) {
        final parsed = double.tryParse(raw.replaceAll(',', ''));
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0;
  }

  static String _readTypeRaw(Map<String, dynamic> map) {
    final raw = map['type'] ??
        map['transactionType'] ??
        map['entryType'] ??
        map['ledgerType'] ??
        map['category'];
    return raw?.toString() ?? AppConstants.entryDebit;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
