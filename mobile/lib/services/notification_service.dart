import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'task_reminder';
  static const _channelName = 'Task Reminder';
  static const _channelDescription = 'Pengingat deadline task harian';
  static const _reminderOffsets = [
    Duration(days: 3),
    Duration(days: 1),
    Duration(hours: 6),
    Duration(hours: 1),
    Duration.zero,
  ];

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    await requestPermissions();
  }

  static Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  // Jadwalkan beberapa notifikasi berdasarkan deadline task.
  static Future<void> scheduleTaskReminders({
    required int taskId,
    required String title,
    required DateTime deadline,
  }) async {
    await cancelReminder(taskId);
    if (deadline.isBefore(DateTime.now())) return;
    await requestPermissions();

    for (var i = 0; i < _reminderOffsets.length; i++) {
      final offset = _reminderOffsets[i];
      final reminderAt = deadline.subtract(offset);
      if (reminderAt.isBefore(DateTime.now())) continue;

      await _scheduleWithFallback(
        _notificationId(taskId, i),
        _notificationTitle(offset),
        title,
        reminderAt,
      );
    }
  }

  // Tetap disediakan untuk kompatibilitas jika ada alur yang memakai satu waktu.
  static Future<void> scheduleReminder({
    required int taskId,
    required String title,
    required DateTime reminderAt,
  }) async {
    await _plugin.cancel(taskId);
    if (reminderAt.isBefore(DateTime.now())) return;
    await requestPermissions();

    await _scheduleWithFallback(
      taskId,
      'Deadline mendekat!',
      title,
      reminderAt,
    );
  }

  static Future<void> _scheduleWithFallback(
    int notificationId,
    String notificationTitle,
    String body,
    DateTime reminderAt,
  ) async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canScheduleExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    try {
      await _schedule(
        notificationId,
        notificationTitle,
        body,
        reminderAt,
        canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (_) {
      await _schedule(
        notificationId,
        notificationTitle,
        body,
        reminderAt,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> _schedule(
    int notificationId,
    String notificationTitle,
    String body,
    DateTime reminderAt,
    AndroidScheduleMode scheduleMode,
  ) async {
    await _plugin.zonedSchedule(
      notificationId,
      notificationTitle,
      body,
      tz.TZDateTime.fromMillisecondsSinceEpoch(
        tz.local,
        reminderAt.millisecondsSinceEpoch,
      ),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Batalkan notifikasi (saat task dihapus atau selesai).
  static Future<void> cancelReminder(int taskId) async {
    await _plugin.cancel(taskId);
    for (var i = 0; i < _reminderOffsets.length; i++) {
      await _plugin.cancel(_notificationId(taskId, i));
    }
  }

  // Batalkan semua notifikasi.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static int _notificationId(int taskId, int reminderIndex) {
    return (taskId * 100) + reminderIndex;
  }

  static String _notificationTitle(Duration offset) {
    if (offset.inDays >= 1) {
      return offset.inDays == 1
          ? 'Deadline besok'
          : 'Deadline ${offset.inDays} hari lagi';
    }
    if (offset.inHours >= 1) return 'Deadline ${offset.inHours} jam lagi';
    return 'Deadline sekarang';
  }
}
