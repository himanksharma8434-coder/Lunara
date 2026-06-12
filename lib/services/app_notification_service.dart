import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prediction_result.dart';
import 'plus_service.dart';

class AppNotificationService extends ChangeNotifier {
  static final AppNotificationService _instance =
      AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Stream for handling notification actions tapped by the user
  final StreamController<String> actionStream = StreamController<String>.broadcast();

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
    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId != null) {
          actionStream.add(response.actionId!);
        }
      },
    );

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
      await cancelWellnessForecastReminders();
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
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
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
        android: AndroidNotificationDetails(
          'guidance_channel',
          'Daily Health Insights',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
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
        android: AndroidNotificationDetails(
          'guidance_channel',
          'Daily Health Insights',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
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

    final rawReminderDate = nextPeriodDate.subtract(const Duration(days: 2));
    // Force the notification to fire at 9:00 AM local time
    final reminderDate = tz.TZDateTime(
        tz.local, rawReminderDate.year, rawReminderDate.month, rawReminderDate.day, 9, 0);

    if (reminderDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final title = isTrackingForSomeoneElse
        ? "${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}'s Period is Approaching"
        : "Period approaching";

    final partnerBodies = [
      "Their period is predicted to start in 2 days. Time to be extra supportive!",
      "A gentle heads-up: their cycle begins soon. Bring out their favorite snacks!",
      "Expect their period in about 48 hours. Keep the vibes calm and positive ✨"
    ];

    final selfBodies = [
      "Just a heads up, your period is likely arriving in a couple of days. Time to prep your favorite snacks! 🍫",
      "Your cycle is approaching! Make sure you've got everything you need for the days ahead. 🌸",
      "A gentle reminder from Lunara: your period is expected in about 2 days. Be kind to yourself!",
      "Prediction update: expect your cycle to begin soon. Keep your water bottle handy! 💧",
      "Your period is around the corner. Remember to prioritize rest and stay hydrated! ✨"
    ];

    final bodyPool = isTrackingForSomeoneElse ? partnerBodies : selfBodies;
    final selectedBody = (bodyPool.toList()..shuffle()).first;

    await _notifications.zonedSchedule(
      id: _periodReminderId,
      title: title,
      body: selectedBody,
      scheduledDate: reminderDate,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'period_channel',
          'Period Reminders',
          importance: Importance.max,
          priority: Priority.high,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          actions: [
            if (!isTrackingForSomeoneElse) ...[
              const AndroidNotificationAction(
                'action_period_started',
                'Yes, it started',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'action_not_yet',
                'Not yet',
                showsUserInterface: true,
              ),
            ]
          ],
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'period_reminder',
        ),
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

    final rawReminderDate = fertileWindowStart.subtract(const Duration(days: 1));
    // Force the notification to fire at 9:00 AM local time
    final reminderDate = tz.TZDateTime(
        tz.local, rawReminderDate.year, rawReminderDate.month, rawReminderDate.day, 9, 0);

    if (reminderDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final title = isTrackingForSomeoneElse
        ? "${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}'s Fertile Window"
        : "Fertile Window Approaching";

    final partnerBodies = [
      "Their fertile window begins tomorrow.",
      "Just a heads up: their fertile window is starting tomorrow.",
      "Prediction update: their fertile window opens tomorrow."
    ];

    final selfBodies = [
      "Your fertile window begins tomorrow. Keep logging your symptoms for the best insights!",
      "Ovulation is approaching! Your fertile window officially starts tomorrow. ✨",
      "Just a heads up: you are entering your fertile window starting tomorrow.",
      "Your fertile window opens tomorrow! A great time to stay in tune with your body's signals."
    ];

    final bodyPool = isTrackingForSomeoneElse ? partnerBodies : selfBodies;
    final selectedBody = (bodyPool.toList()..shuffle()).first;

    await _notifications.zonedSchedule(
      id: _ovulationReminderId,
      title: title,
      body: selectedBody,
      scheduledDate: reminderDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'fertility_channel',
          'Fertility Reminders',
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelWellnessForecastReminders() async {
    for (int id = 300; id < 350; id++) {
      await _notifications.cancel(id: id);
    }
  }

  Future<void> scheduleWellnessForecastReminders(
    List<WellnessForecast> forecasts, {
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
  }) async {
    // 1. Clear existing wellness forecast alerts
    await cancelWellnessForecastReminders();

    // 2. Return early if cycle reminders are disabled or user is not a Plus subscriber
    if (!_cycleEnabled || !PlusService.instance.isPlus) return;

    final now = tz.TZDateTime.now(tz.local);
    int currentId = 300;

    for (final forecast in forecasts) {
      if (currentId >= 350) break; // Limit scheduled counts to defined range

      // Force wellness notification to fire at 9:00 AM local time on the forecast date
      final scheduledDate = tz.TZDateTime(
        tz.local,
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
        9,
        0,
      );

      // Skip past dates
      if (scheduledDate.isBefore(now)) continue;

      String title;
      String body;

      if (isTrackingForSomeoneElse) {
        final partnerName = trackedPersonName.isNotEmpty ? trackedPersonName : "Partner";
        switch (forecast.type) {
          case 'menstrual_rest':
            title = "$partnerName's Menstrual Rest Window 🌸";
            body = "$partnerName is in their Menstrual Rest Window today. Make sure they get plenty of rest and warm, iron-rich meals.";
            break;
          case 'energy_peak':
            title = "$partnerName's ${forecast.title} ⚡";
            body = "$partnerName is in a high-energy phase today. ${forecast.description}";
            break;
          case 'fertility_peak':
            title = "$partnerName's ${forecast.title} ✨";
            body = "$partnerName's fertility window is active today. ${forecast.description}";
            break;
          case 'pms_warning':
            title = "$partnerName's PMS Support Window 💜";
            body = "$partnerName is entering their PMS phase. Time to be extra supportive and create a calm environment.";
            break;
          case 'mood_dip':
            title = "$partnerName's Hormonal Dip Alert 🍃";
            body = "$partnerName is experiencing a hormonal dip today. Be extra gentle and understanding.";
            break;
          default:
            title = "$partnerName's Cycle Insight 🌸";
            body = "${forecast.title}: ${forecast.description}";
        }
      } else {
        switch (forecast.type) {
          case 'menstrual_rest':
            title = "Menstrual Rest Window 🌸";
            body = "Your hormones are at baseline. Prioritize rest, stay hydrated, and eat warm, iron-rich meals today.";
            break;
          case 'energy_peak':
            title = "${forecast.title} ⚡";
            body = "Rising estrogen boosts energy and mental clarity! Great day for focus and workouts.";
            break;
          case 'fertility_peak':
            title = "${forecast.title} ✨";
            body = "Estrogen is high. Your body is approaching ovulation—expect peak vitality and energy!";
            break;
          case 'pms_warning':
            title = "PMS Support Window 💜";
            body = "Hormones are shifting. Prioritize self-care, keep a calm environment, and stay kind to yourself.";
            break;
          case 'mood_dip':
            title = "Hormonal Dip Alert 🍃";
            body = "Hormones are dropping to baseline. A little fatigue or sensitivity is normal today—rest up!";
            break;
          default:
            title = "${forecast.title} 🌸";
            body = forecast.description;
        }
      }

      await _notifications.zonedSchedule(
        id: currentId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'guidance_channel',
            'Daily Health Insights',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      currentId++;
    }
  }
}
