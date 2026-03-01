import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class AppNotificationService extends ChangeNotifier {
  static final AppNotificationService _instance =
      AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _dailyReminderId = 100;
  static const int _periodReminderId = 101;
  static const int _ovulationReminderId = 102;

  // Preferences Keys
  static const String _dailyPrefKey = 'pref_daily_reminders';
  static const String _cyclePrefKey = 'pref_cycle_reminders';

  bool _dailyEnabled = true;
  bool _cycleEnabled = true;

  bool get dailyEnabled => _dailyEnabled;
  bool get cycleEnabled => _cycleEnabled;

  Future<void> init() async {
    tz_data.initializeTimeZones(); // Use the correct alias

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _dailyEnabled = prefs.getBool(_dailyPrefKey) ?? true;
    _cycleEnabled = prefs.getBool(_cyclePrefKey) ?? true;

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Reschedule daily if enabled
    if (_dailyEnabled) {
      scheduleDailyReminder();
    }
  }

  // ─── TOGGLES ────────────────────────────

  Future<void> toggleDailyReminders(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyPrefKey, enable);
    _dailyEnabled = enable;

    if (enable) {
      await scheduleDailyReminder();
    } else {
      await _notifications.cancel(_dailyReminderId);
    }
    notifyListeners();
  }

  Future<void> toggleCycleReminders(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cyclePrefKey, enable);
    _cycleEnabled = enable;

    if (!enable) {
      await _notifications.cancel(_periodReminderId);
      await _notifications.cancel(_ovulationReminderId);
    }
    notifyListeners();
  }

  // ─── PARTNER-AWARE SCHEDULING ────────────────────────────

  Future<void> scheduleDailyReminder({
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
  }) async {
    if (!_dailyEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final title = isTrackingForSomeoneElse
        ? 'Log for ${trackedPersonName.isNotEmpty ? trackedPersonName : 'Partner'}'
        : 'Time to reflect! 🌸';
        
    final body = isTrackingForSomeoneElse
        ? 'Don\'t forget to log their symptoms and mood today!'
        : 'Log your mood, water intake, and sleep to keep your wellness streaks going.';

    await _notifications.zonedSchedule(
      _dailyReminderId,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> schedulePeriodReminder(
    DateTime nextPeriodDate, {
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
  }) async {
    if (!_cycleEnabled) return;

    final reminderDate = nextPeriodDate.subtract(const Duration(days: 2));
    if (reminderDate.isBefore(DateTime.now())) return;

    final title = isTrackingForSomeoneElse 
        ? '${trackedPersonName.isNotEmpty ? trackedPersonName : 'Partner'}\'s Period is Approaching'
        : 'Period approaching';
        
    final body = isTrackingForSomeoneElse
        ? 'Their period is predicted to start in 2 days. Time to be extra supportive!'
        : 'Your cycle is expected to start in 2 days. Stay prepared! 🌸';

    await _notifications.zonedSchedule(
      _periodReminderId,
      title,
      body,
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'period_channel',
          'Period Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleFertileWindowReminder(
    DateTime fertileWindowStart, {
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
  }) async {
    if (!_cycleEnabled) return;

    final reminderDate = fertileWindowStart.subtract(const Duration(days: 1));
    if (reminderDate.isBefore(DateTime.now())) return;

    final title = isTrackingForSomeoneElse
        ? '${trackedPersonName.isNotEmpty ? trackedPersonName : 'Partner'}\'s Fertile Window'
        : 'Fertile Window Approaching';
        
    final body = isTrackingForSomeoneElse
        ? 'Their fertile window begins tomorrow.'
        : 'Your fertile window begins tomorrow.';

    await _notifications.zonedSchedule(
      _ovulationReminderId,
      title,
      body,
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fertility_channel',
          'Fertility Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
