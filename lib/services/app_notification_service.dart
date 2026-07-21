import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prediction_result.dart';
import 'database_service.dart';
import 'plus_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class AppNotificationService extends ChangeNotifier {
  static final AppNotificationService _instance =
      AppNotificationService._internal();
  factory AppNotificationService() => _instance;
  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  RealtimeChannel? _realtimeChannel;

  // Stream for handling notification actions tapped by the user
  final StreamController<String> actionStream = StreamController<String>.broadcast();

  // Notification IDs
  static const int _dailyReminder12pmId = 100;
  static const int _dailyReminder6pmId = 103;
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



  Future<void> init() async {
    tz_data.initializeTimeZones(); // Use the correct alias
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      } catch (_) {
        // Fallback: Find a location in the database with the same current offset
        final offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
        bool found = false;
        for (final loc in tz.timeZoneDatabase.locations.values) {
          if (loc.currentTimeZone.offset.inMilliseconds == offsetMs) {
            tz.setLocalLocation(loc);
            found = true;
            break;
          }
        }
        if (!found) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (e) {
      debugPrint('Error setting local timezone location: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('ic_notification');
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



    // Listen to Auth State changes to subscribe/unsubscribe to Realtime
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed) {
        setupRealtimeListener();
      } else if (event == AuthChangeEvent.signedOut) {
        _realtimeChannel?.unsubscribe();
        _realtimeChannel = null;
      }
    });
  }

  void setupRealtimeListener() {
    _realtimeChannel?.unsubscribe();

    _realtimeChannel = Supabase.instance.client
        .channel('custom_notifications_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'custom_notifications',
          callback: (payload) {
            final content = payload.newRecord['content'] as String?;
            final recordUserId = payload.newRecord['user_id'] as String?;
            final currentUserId = Supabase.instance.client.auth.currentUser?.id;

            if (content != null && (recordUserId == currentUserId || recordUserId == null)) {
              // Only trigger instant notification for untimed insights
              if (!content.startsWith('[time:')) {
                showInstantNotification(
                  title: 'New Health Insight 🌸',
                  body: content,
                );
              }
              // Reschedule 7-day guidance to schedule/update timed/untimed notifications
              scheduleDailyGuidance();
            }
          },
        );
    
    _realtimeChannel!.subscribe();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.show(
        id: 999, // Unique ID for instant alerts
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_channel',
            'Instant Alerts',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFFFF8989),
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing notification: $e\n$stackTrace');
      // We don't have BuildContext here, but we can throw to the caller
      throw Exception('Notification failed: $e');
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
      await scheduleDailyGuidance();
    } else {
      await _notifications.cancel(id: _dailyReminder12pmId);
      await _notifications.cancel(id: _dailyReminder6pmId);
      await cancelDailyGuidance();
    }
    notifyListeners();
  }

  Future<void> cancelDailyGuidance() async {
    for (int i = 0; i < 7; i++) {
      await _notifications.cancel(id: 200 + i);
      await _notifications.cancel(id: 210 + i);
    }
    // Cancel timed insights
    for (int id = 500; id < 600; id++) {
      await _notifications.cancel(id: id);
    }
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
    
    var noonDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12);
    if (noonDate.isBefore(now)) {
      noonDate = noonDate.add(const Duration(days: 1));
    }

    var eveningDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);
    if (eveningDate.isBefore(now)) {
      eveningDate = eveningDate.add(const Duration(days: 1));
    }

    final noonTitle = isTrackingForSomeoneElse
        ? "Log for ${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}"
        : "Time to reflect! 🌸";

    final noonBody = isTrackingForSomeoneElse
        ? "Don't forget to log their symptoms and mood today!"
        : "Log your mood, water intake, and sleep to keep your wellness streaks going.";

    final eveningTitle = isTrackingForSomeoneElse
        ? "Did you forget? Log for ${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}"
        : "Checking in! 🌸";

    final eveningBody = isTrackingForSomeoneElse
        ? "There's still time to log their symptoms today!"
        : "You haven't logged your symptoms yet today. Take a quick moment to check in with your body.";

    await _notifications.zonedSchedule(
      id: _dailyReminder12pmId,
      title: noonTitle,
      body: noonBody,
      scheduledDate: noonDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFFFF8989),
          icon: 'ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _notifications.zonedSchedule(
      id: _dailyReminder6pmId,
      title: eveningTitle,
      body: eveningBody,
      scheduledDate: eveningDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFFFF8989),
          icon: 'ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelEveningReminderForToday({
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
  }) async {
    if (!_dailyEnabled) return;

    await _notifications.cancel(id: _dailyReminder6pmId);

    final now = tz.TZDateTime.now(tz.local);
    var tomorrow6pm = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, 18);

    final eveningTitle = isTrackingForSomeoneElse
        ? "Did you forget? Log for ${trackedPersonName.isNotEmpty ? trackedPersonName : "Partner"}"
        : "Checking in! 🌸";

    final eveningBody = isTrackingForSomeoneElse
        ? "There's still time to log their symptoms today!"
        : "You haven't logged your symptoms yet today. Take a quick moment to check in with your body.";

    await _notifications.zonedSchedule(
      id: _dailyReminder6pmId,
      title: eveningTitle,
      body: eveningBody,
      scheduledDate: tomorrow6pm,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFFFF8989),
          icon: 'ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyGuidance() async {
    if (!_dailyEnabled) return;

    // Clear old guidance first
    await cancelDailyGuidance();

    List<String> facts = [];
    final List<Map<String, dynamic>> timedInsights = [];
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser != null) {
      try {
        final customNotifications = await DatabaseService().fetchCustomNotifications(currentUser.id);
        for (final item in customNotifications) {
          final content = item['content'] as String? ?? '';
          final timeMatch = RegExp(r'^\[time:(\d{2}):(\d{2})\](.*)$', dotAll: true).firstMatch(content);
          if (timeMatch != null) {
            final hour = int.tryParse(timeMatch.group(1)!) ?? 9;
            final minute = int.tryParse(timeMatch.group(2)!) ?? 0;
            final cleanContent = timeMatch.group(3)!;
            timedInsights.add({
              'hour': hour,
              'minute': minute,
              'content': cleanContent,
            });
          } else {
            facts.add(content);
          }
        }
      } catch (e) {
        debugPrint('Error loading custom notifications from Supabase, falling back to local: $e');
      }
    }

    // Fallback to local facts if database is empty/failed
    if (facts.isEmpty) {
      facts = _guidanceFacts;
    }

    // Shuffle facts to send them randomly
    final shuffledFacts = List<String>.from(facts)..shuffle();

    final now = tz.TZDateTime.now(tz.local);

    // Schedule untimed insights (morning/evening)
    for (int i = 0; i < 7; i++) {
      // 1. Morning Guidance (9 AM) for day i
      var morningDate = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, 9, 0);
      if (morningDate.isBefore(now)) {
        continue;
      }

      final morningFact = shuffledFacts[(i * 2) % shuffledFacts.length];

      await _notifications.zonedSchedule(
        id: 200 + i,
        title: 'Morning Body Insight 🌸',
        body: morningFact,
        scheduledDate: morningDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'guidance_channel',
            'Daily Health Insights',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Color(0xFFFF8989),
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // 2. Evening Guidance (8 PM) for day i
      var eveningDate = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, 20, 0);
      if (eveningDate.isBefore(now)) {
        continue;
      }

      final eveningFact = shuffledFacts[(i * 2 + 1) % shuffledFacts.length];

      await _notifications.zonedSchedule(
        id: 210 + i,
        title: 'Evening Health Check 🌙',
        body: eveningFact,
        scheduledDate: eveningDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'guidance_channel',
            'Daily Health Insights',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Color(0xFFFF8989),
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    // Schedule timed insights
    int timedIdOffset = 500;
    for (final insight in timedInsights) {
      final hour = insight['hour'] as int;
      final minute = insight['minute'] as int;
      final content = insight['content'] as String;

      for (int i = 0; i < 7; i++) {
        var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, hour, minute);
        if (scheduledDate.isBefore(now)) {
          continue;
        }

        if (timedIdOffset >= 600) break;

        await _notifications.zonedSchedule(
          id: timedIdOffset,
          title: 'New Health Insight 🌸',
          body: content,
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'guidance_channel',
              'Daily Health Insights',
              importance: Importance.high,
              priority: Priority.high,
              color: Color(0xFFFF8989),
              icon: 'ic_notification',
              largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        timedIdOffset++;
      }
    }
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
          color: const Color(0xFFFF8989),
          icon: 'ic_notification',
          largeIcon: const DrawableResourceAndroidBitmap('lunara_logo'),
        ),
        iOS: const DarwinNotificationDetails(
          categoryIdentifier: 'period_reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
          color: Color(0xFFFF8989),
          icon: 'ic_notification',
          largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
            color: Color(0xFFFF8989),
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      currentId++;
    }
  }

  Future<void> scheduleCycleDayReminders({
    required int currentCycleDay,
    required int periodDuration,
    required int cycleLength,
    bool isTrackingForSomeoneElse = false,
  }) async {
    if (!_cycleEnabled || isTrackingForSomeoneElse) return;

    // Clear old cycle day reminders (use IDs 400-430)
    for (int i = 400; i < 431; i++) {
      await _notifications.cancel(id: i);
    }

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 30; i++) {
      // Calculate future cycle day
      int predictedCycleDay = ((currentCycleDay - 1 + i) % cycleLength) + 1;
      
      bool shouldSchedule = false;
      if (predictedCycleDay <= periodDuration) {
        // Rule 1: Menstrual phase -> Daily
        shouldSchedule = true;
      } else {
        // Rule 2: Non-menstrual phase -> Alternate days
        int daysAfterPeriod = predictedCycleDay - periodDuration;
        if (daysAfterPeriod % 2 != 0) {
          shouldSchedule = true;
        }
      }

      if (!shouldSchedule) continue;

      // Schedule at 10:00 AM (to avoid overlapping with the 12:00 PM logging reminder)
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, 10, 0);
      
      // If it's today and 10 AM has passed, skip
      if (scheduledDate.isBefore(now)) continue;

      final message = _getCycleDayMessage(predictedCycleDay, periodDuration);

      await _notifications.zonedSchedule(
        id: 400 + i,
        title: 'Day $predictedCycleDay 🌸',
        body: message,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'guidance_channel',
            'Daily Health Insights',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            color: Color(0xFFFF8989),
            icon: 'ic_notification',
            largeIcon: DrawableResourceAndroidBitmap('lunara_logo'),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  String _getCycleDayMessage(int dayOfCycle, int periodDuration) {
    if (dayOfCycle <= periodDuration) {
      final periodMsgs = [
        "Take it easy today! Ek garma-garam chai se acha lag skta hai ☕",
        "Body thodi tired ? Heating pad or adrak wali chai is your best friend right now ✨",
        "Cramps bothering you? Thoda rest kar lo and keep yourself hydrated 💧",
        "Your body is working hard. Watch Netflix & chill 🌸",
        "Periods can be tough, but you are tougher! Send yourself some love today 💜",
        "Aaram se din nikalo aaj. Comfort over everything else! 💆‍♀️",
        "Warm hugs and warm water for you today! You've got this ✨",
      ];
      return periodMsgs[(dayOfCycle - 1) % periodMsgs.length];
    } else if (dayOfCycle > periodDuration && dayOfCycle <= 12) {
      final follicularMsgs = [
        "Estrogen is rising! Increased energy levels make this a great time to start a new project 🚀",
        "Your skin might be glowing thanks to the estrogen peak. Enjoy the fresh vibe today ✨",
        "Mood levels are generally elevated during this phase. A great time for social activities ☕",
        "Energy levels are peaking. This is an optimal time for a good workout session 💪",
        "Feeling creative? This phase is perfect for picking up a new hobby 🎨",
        "Good vibes only! Focus on your wellness and maintain that positive energy 🌟",
        "Looking for a fresh start? Today is a great day for new beginnings! 🌿",
      ];
      return follicularMsgs[((dayOfCycle - periodDuration - 1) ~/ 2) % follicularMsgs.length];
    } else if (dayOfCycle > 12 && dayOfCycle <= 16) {
      final ovMsgs = [
        "Ovulation phase! You're likely experiencing peak energy and confidence 💁‍♀️",
        "Fertile window alert. Utilize your peak energy levels well today ✨",
        "Feeling sociable? Hormonal shifts during this time often boost social energy 🎉",
        "You are glowing! Take some time to pamper yourself today 💅",
      ];
      return ovMsgs[((dayOfCycle - 13) ~/ 2).clamp(0, ovMsgs.length - 1)];
    } else {
      final lutealMsgs = [
        "Progesterone rising . Breast tenderness are normal , comfort your breast🌸",
        "Mood swings feeling real? Thoda time nikal lo, suno apni pasand ki music 🎧",
        "Cravings hitting hard? Ek piece dark chocolate , totally allowed hai 🍫",
        "Energy thodi low lag sakti hai. Chill day plan karo, maybe watch a movie 🍿",
        "PMS might be knocking. Don't be too hard on yourself 💜",
        "Skin acting up? It happens before periods. Hydrate karo aur chill raho 💧",
        "Feeling bloated? Nimbu pani or green tea help kar sakti hai 🍵",
        "Feeling extra sensitive today? warm bath can do wonders 🛀",
      ];
      return lutealMsgs[((dayOfCycle - 17) ~/ 2).clamp(0, lutealMsgs.length - 1)];
    }
  }
}
