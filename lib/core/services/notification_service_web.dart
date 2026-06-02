import 'package:get/get.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';

/// Web stub — local notifications are not supported in the browser.
class NotificationService extends GetxService {
  bool get permissionsGranted => false;

  Future<NotificationService> init() async => this;

  Future<bool> requestPermissions() async => false;

  Future<void> scheduleTransactionReminder({
    required TransactionModel transaction,
    required String partyName,
    DateTime? reminderDate,
  }) async {}

  static int notificationIdFor(String transactionId) =>
      transactionId.hashCode.abs() % 0x7FFFFFFF;

  Future<void> cancelTransactionReminder(String transactionId) async {}

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}

  Future<void> cancelReminder(int id) async {}

  Future<void> cancelAll() async {}
}
