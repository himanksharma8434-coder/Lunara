import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

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
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('lunara_logo');

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    _isInitialized = true;
  }

  // Request Permissions for Android 13+ and iOS
  Future<void> requestPermissions() async {
    if (!_isInitialized) await init();

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();

    final iOSImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    await iOSImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // General Notification Details
  NotificationDetails _getNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'lunara_cycle_alerts',
        'Cycle Alerts',
        channelDescription:
            'Notifications for period and fertility predictions',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'lunara_logo',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Schedule a notification for a specific date/time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_isInitialized) await init();

    // Ensure we don't schedule in the past
    if (scheduledDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Scheduled notification $id for $tzScheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Schedule daily repeating notification
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (!_isInitialized) await init();

    final now = DateTime.now();
    var scheduledDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzScheduledDate =
        tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: _getNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents:
            DateTimeComponents.time, // Make it repeating daily
      );
      debugPrint(
          'Scheduled daily reminder $id for ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  // Schedule the 2 daily health guidance facts
  Future<void> scheduleDailyGuidance() async {
    if (!_isInitialized) await init();

    // ID 100 for Morning Guidance
    await scheduleDailyReminder(
      id: 100,
      title: 'Morning Body Insight 🌸',
      body: _getRandomFact(),
      time: const TimeOfDay(hour: 9, minute: 0),
    );

    // ID 101 for Evening Guidance
    await scheduleDailyReminder(
      id: 101,
      title: 'Evening Health Check 🌙',
      body: _getRandomFact(),
      time: const TimeOfDay(hour: 20, minute: 0),
    );

    debugPrint('Scheduled morning (9AM) and evening (8PM) health guidance.');
  }
}
