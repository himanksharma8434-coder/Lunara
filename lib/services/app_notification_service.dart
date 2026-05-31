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

  // The curated list of female body health facts and guidance
  static const List<String> _guidanceFacts = [
    "Hydration is key! Drinking enough water helps reduce bloating during your luteal phase.",
    "Did you know? Basal Body Temperature (BBT) dips slightly just before ovulation, then spikes after.",
    "Gentle exercises like yoga can help ease menstrual cramps by improving pelvic blood flow.",
    "Changes in cervical mucus are normal and mirror your estrogen levels throughout your cycle.",
    "Prioritizing sleep during your period helps your body recover from the energy dip.",
    "Cravings ahead of your period are linked to serotonin drops—dark chocolate can help!",
    "Your skin might flourish during ovulation due to high estrogen and peaking testosterone.",
    "Tracking your daily symptoms helps identify patterns that make your body unique.",
    "Feeling tired? Iron-rich foods like spinach and lentils are great during menstruation.",
    "The follicular phase is often the best time for high-energy workouts and starting new projects.",
    "Hormonal shifts can cause slight changes to your immune system throughout the month.",
    "Stress directly affects the hypothalamus, which controls your menstrual cycle—take time to breathe.",
    "Magnesium is excellent for reducing both physical cramps and emotional PMS symptoms.",
    "Your basal body temperature stays elevated during the entire luteal phase.",
    "Did you know? The length of the luteal phase (post-ovulation) is almost always exactly 14 days.",
    "Some women experience 'mittelschmerz'—a slight twinge of pain on one side exactly at ovulation.",
    "Ovulation is the only time an egg can be fertilized, and it only survives 12-24 hours.",
    "Your sense of smell might actually become sharper right before and during ovulation!",
    "It's completely normal for your period to fluctuate by a few days depending on stress and diet.",
    "Don't ignore severe pain. If cramps are debilitating, it's worth talking to a healthcare provider.",
    "Seed cycling (flax, pumpkin, sesame, sunflower) is a natural way some women support their hormones.",
    "During your period, your metabolic rate naturally drops a bit before resetting.",
    "Progesterone (dominant in your luteal phase) has a natural calming, sleep-promoting effect.",
    "Breasts may feel tender right before your period due to swelling milk glands from progesterone.",
    "Regularly logging symptoms not only helps you—it provides vital data for your doctor if needed."
  ];

  String _getRandomFact() {
    final list = _guidanceFacts.toList()..shuffle();
    return list.first;
  }

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
    await _notifications.initialize(settings: settings);

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _dailyEnabled = prefs.getBool(_dailyPrefKey) ?? true;
    _cycleEnabled = prefs.getBool(_cyclePrefKey) ?? true;

    // Reschedule daily if enabled
    if (_dailyEnabled) {
      scheduleDailyReminder();
    }
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ─── TOGGLES ────────────────────────────

  Future<void> toggleDailyReminders(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyPrefKey, enable);
    _dailyEnabled = enable;

    if (enable) {
      await scheduleDailyReminder();
    } else {
      await _notifications.cancel(id: _dailyReminderId);
    }
    notifyListeners();
  }

  Future<void> toggleCycleReminders(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cyclePrefKey, enable);
    _cycleEnabled = enable;

    if (!enable) {
      await _notifications.cancel(id: _periodReminderId);
      await _notifications.cancel(id: _ovulationReminderId);
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
        ? "Log for ${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}"
        : "Time to reflect! 🌸";

    final body = isTrackingForSomeoneElse
        ? "Don't forget to log their symptoms and mood today!"
        : "Log your mood, water intake, and sleep to keep your wellness streaks going.";

    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyGuidance() async {
    if (!_dailyEnabled) return;

    // Morning Guidance (9 AM)
    var morningDate = tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0);
    if (morningDate.isBefore(tz.TZDateTime.now(tz.local))) morningDate = morningDate.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      id: 200,
      title: 'Morning Body Insight 🌸',
      body: _getRandomFact(),
      scheduledDate: morningDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('guidance_channel', 'Daily Health Insights'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Evening Guidance (8 PM)
    var eveningDate = tz.TZDateTime(tz.local, DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0);
    if (eveningDate.isBefore(tz.TZDateTime.now(tz.local))) eveningDate = eveningDate.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      id: 201,
      title: 'Evening Health Check 🌙',
      body: _getRandomFact(),
      scheduledDate: eveningDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('guidance_channel', 'Daily Health Insights'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
        ? "${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}'s Period is Approaching"
        : "Period approaching";

    final body = isTrackingForSomeoneElse
        ? "Their period is predicted to start in 2 days. Time to be extra supportive!"
        : "Your cycle is expected to start in 2 days. Stay prepared! 🌸";

    await _notifications.zonedSchedule(
      id: _periodReminderId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'period_channel',
          'Period Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
        ? "${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}'s Fertile Window"
        : "Fertile Window Approaching";

    final body = isTrackingForSomeoneElse
        ? "Their fertile window begins tomorrow."
        : "Your fertile window begins tomorrow.";

    await _notifications.zonedSchedule(
      id: _ovulationReminderId,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fertility_channel',
          'Fertility Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
