import 'package:flutter/material.dart';

/// Ledger-aware color palette.
abstract final class AppColors {
  // ── Ledger Colors ─────────────────────────────────────────────────────────
  /// Receivable — "Lenay hain" (Green)
  static const Color receivable = Color(0xFF2E7D32);
  static const Color receivableLight = Color(0xFFE8F5E9);

  /// Payable — "Denay hain" (Red)
  static const Color payable = Color(0xFFC62828);
  static const Color payableLight = Color(0xFFFFEBEE);

  // ── App Theme ─────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
}
