/// Global constants for Smart Khata Manager.
abstract final class AppConstants {
  static const String appName = 'Smart Khata Manager';

  /// Injected on Vercel via `--dart-define=BUILD_ID=` (git SHA); shows on dashboard.
  static const String buildLabel = String.fromEnvironment(
    'BUILD_ID',
    defaultValue: 'local',
  );

  // ── Firestore Collections ───────────────────────────────────────────────
  /// Top-level user root — each user's data lives under `users/{uid}/…`.
  static const String usersCollection = 'users';
  static const String partiesCollection = 'parties';
  static const String transactionsCollection = 'transactions';
  static const String remindersCollection = 'reminders';

  // ── Ledger Types (Double-Entry) ─────────────────────────────────────────
  /// Receivable — "Lenay hain" (money owed TO us) → Green
  static const String ledgerReceivable = 'receivable';

  /// Payable — "Denay hain" (money WE owe) → Red
  static const String ledgerPayable = 'payable';

  // ── Transaction Entry Types ─────────────────────────────────────────────
  static const String entryCredit = 'credit';
  static const String entryDebit = 'debit';

  // ── Gemini Model (Free Tier) ────────────────────────────────────────────
  static const String geminiModel = 'gemini-1.5-flash';

  // ── Notification Channel ──────────────────────────────────────────────────
  static const String notificationChannelId = 'khata_reminders';
  static const String notificationChannelName = 'Payment Reminders';
  static const String notificationChannelDescription =
      'Notifications for due payment reminders';

  /// Days after [TransactionModel.date] to fire the payment reminder.
  static const int reminderDaysAfter = 3;

  /// Default hour (24h) on the reminder day.
  static const int reminderHour = 9;
  static const int reminderMinute = 0;
}
