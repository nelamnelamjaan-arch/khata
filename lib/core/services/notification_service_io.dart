import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:smart_khata_manager/core/config/app_constants.dart';
import 'package:smart_khata_manager/features/ledger/models/transaction.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local notification engine for payment due-date reminders.
class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _permissionsGranted = false;

  bool get permissionsGranted => _permissionsGranted;

  Future<NotificationService> init() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createAndroidChannel();
    return this;
  }

  /// Requests notification permissions (call after [init], e.g. on app start).
  Future<bool> requestPermissions() async {
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.android => await _requestAndroidPermissions(),
      TargetPlatform.iOS => await _requestIosPermissions(),
      _ => true,
    };

    _permissionsGranted = granted;
    return granted;
  }

  /// Schedules a receivable payment reminder.
  ///
  /// Fires [AppConstants.reminderDaysAfter] days after [transaction.date]
  /// at [AppConstants.reminderHour]:00 local time.
  Future<void> scheduleTransactionReminder({
    required TransactionModel transaction,
    required String partyName,
    DateTime? reminderDate,
  }) async {
    if (!_permissionsGranted) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    final scheduledAt = _resolveReminderDate(
      transactionDate: transaction.date,
      override: reminderDate,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    final amount = transaction.amount.toStringAsFixed(
      transaction.amount % 1 == 0 ? 0 : 2,
    );
    final body =
        'Reminder: A payment of Rs. $amount is due from $partyName.';

    await scheduleReminder(
      id: notificationIdFor(transaction.id),
      title: 'Payment Reminder',
      body: body,
      scheduledDate: scheduledAt,
      payload: transaction.id,
    );
  }

  /// Stable notification id derived from a transaction id.
  static int notificationIdFor(String transactionId) =>
      transactionId.hashCode.abs() % 0x7FFFFFFF;

  Future<void> cancelTransactionReminder(String transactionId) =>
      cancelReminder(notificationIdFor(transactionId));

  /// Schedule a one-time local notification.
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          channelDescription: AppConstants.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelReminder(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Private ───────────────────────────────────────────────────────────────

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final notificationGranted =
        await android.requestNotificationsPermission() ?? true;
    await android.requestExactAlarmsPermission();
    return notificationGranted;
  }

  Future<bool> _requestIosPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return true;

    return await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<void> _createAndroidChannel() async {
    const channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  DateTime _resolveReminderDate({
    required DateTime transactionDate,
    DateTime? override,
  }) {
    final base = override ??
        transactionDate.add(
          const Duration(days: AppConstants.reminderDaysAfter),
        );

    return DateTime(
      base.year,
      base.month,
      base.day,
      AppConstants.reminderHour,
      AppConstants.reminderMinute,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      // Future: navigate to party/transaction detail.
    }
  }
}
