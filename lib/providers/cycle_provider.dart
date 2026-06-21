import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_result.dart';
import '../services/app_notification_service.dart';
import '../services/database_service.dart';
import '../services/health_service.dart';
import '../services/menstrual_intelligence_service.dart';
import '../services/plus_service.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:async';

class CycleProvider extends ChangeNotifier {
  final SharedPreferences _prefs; // Store reference to preferences

  // User Info
  String _userName = '';
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  int _periodDuration = 5;
  int _age = 0;
  String _userGender = 'Female';
  int _weight = 60; // kg
  int _height = 165; // cm
  bool _bodyMetricsCompleted = false;
  bool _isIrregular = false;

  // Multi-Cycle History (stores start dates of past cycles)
  List<DateTime> _cycleHistory = [];

  // Daily Metrics
  int _dailySteps = 0;
  int _waterGlasses = 0;
  double _sleepHours = 0.0;
  String _currentMood = 'Good';
  double? _todayBbt; // Basal Body Temperature in °C
  String?
      _todayCervicalMucus; // 'Dry' | 'Sticky' | 'Creamy' | 'EggWhite' | 'Watery'

  // Partner Tracking
  bool _isTrackingForSomeoneElse = false;
  String _trackedPersonName = '';
  String _trackedPersonRelation = 'Partner';

  // Symptom Tracking
  List<String> _todaySymptoms = [];
  final Map<DateTime, List<String>> _symptomHistory = {};
  List<Map<String, dynamic>> _customSymptoms = [];

  // Notes & Journal
  final List<Map<String, dynamic>> _journalEntries = [];

  // Wellness History (for charts)
  Map<String, Map<String, dynamic>> _wellnessHistory = {};

  // Intelligence Engine
  final MenstrualIntelligenceService _intelligenceService =
      MenstrualIntelligenceService();
  PredictionResult _latestPrediction = const PredictionResult();

  // Predictions
  DateTime? _nextPeriodDate;
  DateTime? _ovulationDate;

  // Health Connect Integration
  bool _healthConnected = false;
  int? _heartRate;
  bool _isSyncing = false;
  String? _lastSyncStatus;
  Timer? _syncTimer;

  // Getters for sync state
  bool get isSyncing => _isSyncing;
  String? get lastSyncStatus => _lastSyncStatus;

  // Partner Sync
  String? _partnerLinkId;
  String? _partnerLinkRole;
  String? _linkedPartnerName;
  String? _linkedPartnerUid;
  String? _activeInviteCode;

  // Partner View data (global state)
  Map<String, dynamic>? _partnerProfile;
  List<Map<String, dynamic>> _partnerCycles = [];
  StreamSubscription? _assessmentSub;
  List<Map<String, dynamic>> _partnerAssessments = [];

  // Constructor - Automatically loads data on startup
  CycleProvider(this._prefs) {
    _loadFromPrefs();
    _setupAutoSync();
    PlusService.instance.addListener(_onPlusStatusChanged);
    AppNotificationService().addListener(_onNotificationPrefsChanged);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _assessmentSub?.cancel();
    PlusService.instance.removeListener(_onPlusStatusChanged);
    AppNotificationService().removeListener(_onNotificationPrefsChanged);
    super.dispose();
  }

  void _onPlusStatusChanged() {
    _updateReminders();
  }

  void _onNotificationPrefsChanged() {
    _updateReminders();
  }

  void _setupAutoSync() {
    // Sync every 30 minutes if connected
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (_healthConnected) {
        _autoSyncHealth();
      }
    });
  }

  // --- PERSISTENCE LOGIC ---

  void _loadFromPrefs() {
    _userName = _prefs.getString('user_name') ?? '';
    final dateStr = _prefs.getString('last_period_date');
    if (dateStr != null) _lastPeriodDate = DateTime.parse(dateStr);

    _cycleLength = _prefs.getInt('cycle_length') ?? 28;
    _periodDuration = _prefs.getInt('period_duration') ?? 5;
    _age = _prefs.getInt('age') ?? 0;
    _userGender = _prefs.getString('user_gender') ?? 'Female';
    _weight = _prefs.getInt('weight') ?? 60;
    _height = _prefs.getInt('height') ?? 165;
    _bodyMetricsCompleted = _prefs.getBool('metrics_completed') ?? false;
    _dailySteps = _prefs.getInt('daily_steps') ?? 0;
    _waterGlasses = _prefs.getInt('water_glasses') ?? 0;
    _sleepHours = _prefs.getDouble('sleep_hours') ?? 0.0;

    _isTrackingForSomeoneElse = _prefs.getBool('tracking_for_others') ?? false;
    _trackedPersonName = _prefs.getString('tracked_person_name') ?? '';
    _trackedPersonRelation =
        _prefs.getString('tracked_person_relation') ?? 'Partner';

    // Load cycle history
    final historyListJson = _prefs.getString('cycle_history');
    if (historyListJson != null) {
      final decoded = jsonDecode(historyListJson) as List<dynamic>;
      _cycleHistory = decoded.map((e) => DateTime.parse(e as String)).toList();
      _cycleHistory.sort();
    }

    // Load wellness history
    final historyJson = _prefs.getString('wellness_history');
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
      _wellnessHistory =
          decoded.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)));
    }

    // Load custom symptoms
    final customSymptomsJson = _prefs.getString('custom_symptoms');
    if (customSymptomsJson != null) {
      try {
        final decoded = jsonDecode(customSymptomsJson) as List<dynamic>;
        _customSymptoms =
            decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('Error loading custom symptoms: $e');
      }
    }

    _calculatePredictions();
    _healthConnected = _prefs.getBool('health_connected') ?? false;
    notifyListeners();

    // Fetch cloud history asynchronously to keep UI fast
    _fetchCloudHistory();

    // Auto-sync health data if connected
    if (_healthConnected) {
      _autoSyncHealth();
    }

    // Load partner link status
    _loadPartnerLink();

    _isIrregular = _prefs.getBool('is_irregular') ?? false;

    // Check if it's a new day to reset daily trackers
    checkNewDay();
  }

  /// Checks if the date has changed since the last time metrics were modified/loaded.
  /// If it's a new day, resets all daily trackers (water, sleep, symptoms, etc.) to their default states.
  void checkNewDay() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDateStr = _prefs.getString('last_daily_metrics_date');

    if (lastDateStr != todayStr) {
      // It's a new day! Reset daily trackers
      _dailySteps = 0;
      _waterGlasses = 0;
      _sleepHours = 0.0;
      _currentMood = 'Good';
      _todaySymptoms.clear();
      _todayBbt = null;
      _todayCervicalMucus = null;

      // Update prefs immediately
      _prefs.setInt('daily_steps', 0);
      _prefs.setInt('water_glasses', 0);
      _prefs.setDouble('sleep_hours', 0.0);
      _prefs.setString('last_daily_metrics_date', todayStr);

      notifyListeners();
      debugPrint('Daily metrics reset for new day: $todayStr');
    }
  }

  Future<void> _fetchCloudHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final db = DatabaseService();

      // Restore user profile from cloud
      final profile = await db.getUserProfile(userId);
      if (profile != null) {
        bool updated = false;
        if (_userName.isEmpty && (profile['name'] ?? '').isNotEmpty) {
          _userName = profile['name'];
          updated = true;
        }
        if (_age == 0 && (profile['age'] ?? 0) > 0) {
          _age = profile['age'];
          updated = true;
        }
        if (_weight == 60 && (profile['weight'] ?? 60) != 60) {
          _weight = profile['weight'];
          updated = true;
        }
        if (_height == 165 && (profile['height'] ?? 165) != 165) {
          _height = profile['height'];
          updated = true;
        }
        if (profile['cycle_length'] != null) {
          _cycleLength = profile['cycle_length'];
          updated = true;
        }
        if (profile['period_duration'] != null) {
          _periodDuration = profile['period_duration'];
          updated = true;
        }
        if (profile['is_irregular'] != null) {
          _isIrregular = profile['is_irregular'] == true;
          updated = true;
        }
        if (profile['tracking_for_others'] != null) {
          _isTrackingForSomeoneElse = profile['tracking_for_others'] == true;
          updated = true;
        }
        if (profile['tracked_person_name'] != null) {
          _trackedPersonName = profile['tracked_person_name'];
          updated = true;
        }
        if (profile['tracked_person_relation'] != null) {
          _trackedPersonRelation = profile['tracked_person_relation'];
          updated = true;
        }
        if (updated) {
          await _saveToPrefs();
        }

        // Auto-recover hasCompletedOnboarding if cloud data proves
        // the user already provided body metrics + period date.
        // This flag gets wiped on logout, but cloud data persists.
        final hasRealMetrics = _weight != 60 || _height != 165;
        final hasPeriodData = _lastPeriodDate != null;
        if (hasRealMetrics && hasPeriodData) {
          final onboardingDone =
              _prefs.getBool('hasCompletedOnboarding') ?? false;
          if (!onboardingDone) {
            await _prefs.setBool('hasCompletedOnboarding', true);
            _bodyMetricsCompleted = true;
            await _saveToPrefs();
          }
        }
      }

      // Restore cycle history from cloud
      final cloudCycles = await db.getCycles(userId);
      if (cloudCycles.isNotEmpty) {
        for (final cycle in cloudCycles) {
          final startDate = DateTime.tryParse(cycle['start_date'] ?? '');
          if (startDate != null) {
            _addToCycleHistory(startDate);
          }
        }
        // Update last period date if cloud has newer data
        if (_cycleHistory.isNotEmpty) {
          final latest = _cycleHistory.last;
          if (_lastPeriodDate == null || latest.isAfter(_lastPeriodDate!)) {
            _lastPeriodDate = latest;
          }
        }
        _calculatePredictions();
        await _saveToPrefs();
        _updateReminders();
      }

      // Restore assessments (wellness history) from cloud
      final cloudAssessments = await db.getAssessments(userId);
      if (cloudAssessments.isNotEmpty) {
        bool historyUpdated = false;
        for (final a in cloudAssessments) {
          final dateStr = a['date'];
          if (dateStr == null) continue;
          final key = dateStr.toString().split('T')[0];
          // Only add if not already in local history
          if (!_wellnessHistory.containsKey(key)) {
            _wellnessHistory[key] = {
              'water': a['water_intake'] ?? 0,
              'sleep': (a['sleep_hours'] ?? 0.0).toDouble(),
              'steps': a['steps'] ?? 0,
              'mood': a['mood'] ?? 'Good',
              'symptoms': a['symptoms'] != null
                  ? List<String>.from(a['symptoms'])
                  : <String>[],
            };
            historyUpdated = true;
          }
        }
        if (historyUpdated) {
          await _saveToPrefs();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Cloud fetch error: $e');
    }
  }

  /// Public method to trigger cloud data loading (e.g., after login).
  Future<void> loadFromCloud() async {
    await _fetchCloudHistory();
  }

  /// Sync user profile to cloud.
  Future<void> syncProfileToCloud() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (userId == null) return;
    try {
      await DatabaseService().saveUserProfile(
        uid: userId,
        email: email ?? '',
        name: _userName,
        gender: _userGender,
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        age: _age,
        weight: _weight,
        height: _height,
        isIrregular: _isIrregular,
        trackingForOthers: _isTrackingForSomeoneElse,
        trackedPersonName: _trackedPersonName,
        trackedPersonRelation: _trackedPersonRelation,
      );
    } catch (e) {
      debugPrint('Cloud sync error (profile): $e');
    }
  }

  /// Update user profile data locally and sync to cloud
  Future<void> updateProfile({
    required String name,
    required String gender,
    required int age,
    required int height,
    required int weight,
    required int cycleLength,
    required int periodDuration,
    bool isTrackingForSomeoneElse = false,
    String trackedPersonName = '',
    String trackedPersonRelation = 'Partner',
  }) async {
    _userName = name;
    _userGender = gender;
    _age = age;
    _height = height;
    _weight = weight;
    _cycleLength = cycleLength;
    _periodDuration = periodDuration;
    _isTrackingForSomeoneElse = isTrackingForSomeoneElse;
    _trackedPersonName = trackedPersonName;
    _trackedPersonRelation = trackedPersonRelation;
    // _isIrregular is handled separately via setIsIrregular but could be added here

    await _saveToPrefs();
    notifyListeners();
    await syncProfileToCloud();
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setString('user_name', _userName);
    if (_lastPeriodDate != null) {
      await _prefs.setString(
          'last_period_date', _lastPeriodDate!.toIso8601String());
    }
    await _prefs.setInt('cycle_length', _cycleLength);
    await _prefs.setInt('period_duration', _periodDuration);
    await _prefs.setInt('age', _age);
    await _prefs.setString('user_gender', _userGender);
    await _prefs.setInt('weight', _weight);
    await _prefs.setInt('height', _height);
    await _prefs.setBool('metrics_completed', _bodyMetricsCompleted);
    await _prefs.setInt('daily_steps', _dailySteps);
    await _prefs.setInt('water_glasses', _waterGlasses);
    await _prefs.setDouble('sleep_hours', _sleepHours);
    await _prefs.setBool('tracking_for_others', _isTrackingForSomeoneElse);
    await _prefs.setString('tracked_person_name', _trackedPersonName);
    await _prefs.setString('tracked_person_relation', _trackedPersonRelation);
    await _prefs.setBool('is_irregular', _isIrregular);
    await _prefs.setString('wellness_history', jsonEncode(_wellnessHistory));
    // Persist cycle history
    await _prefs.setString('cycle_history',
        jsonEncode(_cycleHistory.map((d) => d.toIso8601String()).toList()));
    // Persist custom symptoms
    await _prefs.setString('custom_symptoms', jsonEncode(_customSymptoms));
  }

  // Getters - User Info
  String get userName => _userName;
  DateTime? get lastPeriodDate => _lastPeriodDate;
  int get cycleLength => _cycleLength;
  int get periodDuration => _periodDuration;
  int get age => _age;
  String get userGender => _userGender;
  int get weight => _weight;
  int get height => _height;
  bool get bodyMetricsCompleted => _bodyMetricsCompleted;
  bool get isIrregular => _isIrregular;
  List<Map<String, dynamic>> get customSymptoms => _customSymptoms;

  // Partner Tracking Getters
  bool get isTrackingForSomeoneElse => _isTrackingForSomeoneElse;
  String get trackedPersonName => _trackedPersonName;
  String get trackedPersonRelation => _trackedPersonRelation;

  // --- ACTIONS ---

  void setIsIrregular(bool value) {
    _isIrregular = value;
    _saveToPrefs();
    notifyListeners();
    syncProfileToCloud();
  }

  // Dynamic name getter for UI (e.g. "Your Cycle" vs "Sarah's Cycle")
  String get cycleOwnerName {
    if (isPartnerLinked &&
        partnerLinkRole == 'partner' &&
        _linkedPartnerName != null) {
      return "$_linkedPartnerName's";
    }
    if (_isTrackingForSomeoneElse && _trackedPersonName.isNotEmpty) {
      return "$_trackedPersonName's";
    }
    return "Your";
  }

  // Dynamic symptom prompt getter
  String get symptomPromptName =>
      _isTrackingForSomeoneElse && _trackedPersonName.isNotEmpty
          ? "Log $_trackedPersonName's symptoms"
          : "Log your symptoms";

  // Getters - Daily Metrics
  int get dailySteps => _dailySteps;
  int get waterGlasses => _waterGlasses;
  double get sleepHours => _sleepHours;
  String get currentMood => _currentMood;

  // Getters - Health Connect
  bool get isHealthConnected => _healthConnected;
  int? get heartRate => _heartRate;

  // Getters - BBT & Cervical Mucus
  double? get todayBbt => _todayBbt;
  String? get todayCervicalMucus => _todayCervicalMucus;

  /// Ovulation confidence from FAM markers (BBT + Cervical Mucus).
  OvulationConfidence get ovulationConfidence =>
      _latestPrediction.ovulationConfidence;

  /// BBT-confirmed ovulation date (null if no thermal shift detected).
  DateTime? get bbtConfirmedOvulation =>
      _latestPrediction.bbtConfirmedOvulation;

  /// Cervical mucus peak day (null if no confirmed peak).
  DateTime? get cmPeakDay => _latestPrediction.cmPeakDay;

  /// Connect to Health Connect / Apple HealthKit.
  /// Requests permissions directly without checking availability first.
  Future<String?> connectHealth() async {
    final service = HealthService();
    try {
      final granted = await service.requestPermissions();
      if (!granted) return service.lastError ?? 'Permission denied';

      _healthConnected = true;
      await _prefs.setBool('health_connected', true);
      notifyListeners();

      // Immediately sync after connecting
      await syncFromHealth();
      return null;
    } catch (e) {
      debugPrint('Health connect error: $e');
      return e.toString();
    }
  }

  /// Disconnect from Health Connect.
  Future<void> disconnectHealth() async {
    _healthConnected = false;
    _heartRate = null;
    await _prefs.setBool('health_connected', false);
    notifyListeners();
  }

  /// Sync health data from the platform into this provider.
  Future<void> syncFromHealth() async {
    if (!_healthConnected) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final service = HealthService();
      await service.syncAll(this);

      // Also fetch heart rate (stored locally, not in provider setters)
      final hr = await service.fetchLatestHeartRate();
      if (hr != null) {
        _heartRate = hr;
      }

      _lastSyncStatus =
          "Last synced: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    } catch (e) {
      _lastSyncStatus = "Sync failed: $e";
      debugPrint('Sync from health error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Import menstrual dates from the health platform into cycle history.
  /// Groups dates into period clusters and updates the last period date.
  void importMenstrualDates(List<DateTime> dates) {
    if (dates.isEmpty) return;

    bool updated = false;
    for (final date in dates) {
      final normalized = DateTime(date.year, date.month, date.day);
      // Check if this date is already in our history (within 2 days tolerance)
      final isDuplicate = _cycleHistory.any(
        (existing) => existing.difference(normalized).inDays.abs() <= 2,
      );
      if (!isDuplicate) {
        _addToCycleHistory(normalized);
        updated = true;
      }
    }

    if (updated) {
      // Update last period date to the most recent cluster start
      if (_cycleHistory.isNotEmpty) {
        final latest = _cycleHistory.last;
        if (_lastPeriodDate == null || latest.isAfter(_lastPeriodDate!)) {
          _lastPeriodDate = latest;
        }
      }
      _calculatePredictions();
      _saveToPrefs();
      notifyListeners();
      debugPrint('Imported menstrual dates from health platform');
    }
  }

  /// Write the current period data back to the health platform.
  Future<void> writePeriodToHealth() async {
    if (!_healthConnected || _lastPeriodDate == null) return;
    try {
      final service = HealthService();
      await service.writePeriodData(
        startDate: _lastPeriodDate!,
        durationDays: _periodDuration,
      );
    } catch (e) {
      debugPrint('Write period to health error: $e');
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Auto-sync on app startup (called from constructor/timer).
  Future<void> _autoSyncHealth() async {
    if (!_healthConnected || _isSyncing) return;

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      _lastSyncStatus = "No internet. Sync paused.";
      notifyListeners();
      return;
    }

    try {
      await syncFromHealth();
      await writePeriodToHealth();
    } catch (e) {
      debugPrint('Auto health sync error: $e');
    }
  }

  // ─── Partner Sync ──────────────────────────────────────

  // Getters
  String? get partnerLinkId => _partnerLinkId;
  String? get partnerLinkRole => _partnerLinkRole;
  String? get linkedPartnerName => _linkedPartnerName;
  String? get linkedPartnerUid => _linkedPartnerUid;
  String? get activeInviteCode => _activeInviteCode;
  bool get isPartnerLinked =>
      _partnerLinkId != null && _partnerLinkRole != null;

  Map<String, dynamic>? get partnerProfile => _partnerProfile;
  List<Map<String, dynamic>> get partnerCycles => _partnerCycles;
  List<Map<String, dynamic>> get partnerAssessments => _partnerAssessments;

  /// Helper to determine if we are currently viewing the partner's cycle (read-only observer)
  bool get isViewingPartner => isPartnerLinked && partnerLinkRole == 'partner';

  int get _activeCycleLength => isViewingPartner
      ? (_partnerProfile?['cycle_length'] ?? _cycleLength)
      : _cycleLength;

  int get _activePeriodDuration => isViewingPartner
      ? (_partnerProfile?['period_duration'] ?? _periodDuration)
      : _periodDuration;

  DateTime? get _activeLastPeriodDate {
    if (isViewingPartner) {
      if (_partnerCycles.isEmpty) return null;
      final sorted = List<Map<String, dynamic>>.from(_partnerCycles);
      sorted.sort((a, b) => DateTime.parse(a['start_date'] as String)
          .compareTo(DateTime.parse(b['start_date'] as String)));
      if (sorted.isNotEmpty) {
        return DateTime.parse(sorted.last['start_date'] as String);
      }
    }
    return _lastPeriodDate;
  }

  List<DateTime> get _activeCycleHistory {
    if (isViewingPartner) {
      final dates = _partnerCycles
          .map((c) => DateTime.parse(c['start_date'] as String))
          .toList();
      dates.sort((a, b) => a.compareTo(b));
      return dates;
    }
    return _cycleHistory;
  }

  /// Load partner link from Supabase on startup.
  Future<void> _loadPartnerLink() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final db = DatabaseService();
      final link = await db.getActivePartnerLink(uid);
      if (link != null) {
        _partnerLinkId = link['id'];
        _partnerLinkRole = link['role'];

        // Fetch partner's name
        final otherUid = link['role'] == 'tracker'
            ? link['partner_uid']
            : link['tracker_uid'];
        if (otherUid != null) {
          _linkedPartnerUid = otherUid;
          final profile = await db.getPartnerProfile(otherUid);
          _linkedPartnerName = profile?['name'] ?? 'Partner';

          if (_partnerLinkRole == 'partner') {
            await _subscribeToPartnerData(otherUid);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Load partner link error: $e');
    }
  }

  Future<void> _subscribeToPartnerData(String trackerUid) async {
    final db = DatabaseService();
    _partnerProfile = await db.getPartnerProfile(trackerUid);
    _partnerCycles = await db.getPartnerCycles(trackerUid);

    // Subscribe to real-time assessments
    await _assessmentSub?.cancel();
    _assessmentSub = db.streamPartnerAssessments(trackerUid).listen((data) {
      _partnerAssessments = data;
      // Trigger widget updates with partner details
      _updateHomeWidget();
      notifyListeners();
    });

    // Trigger widget update with partner details
    await _updateHomeWidget();
    notifyListeners();
  }

  /// Generate a 6-digit invite code for partner linking.
  Future<String?> generateInviteCode() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return null;

      final db = DatabaseService();
      final code = await db.createPartnerInvite(uid);
      if (code != null) {
        _activeInviteCode = code;
        notifyListeners();
      }
      return code;
    } catch (e) {
      debugPrint('Generate invite error: $e');
      return null;
    }
  }

  /// Accept an invite code from a partner.
  Future<bool> acceptInviteCode(String code) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return false;

      final db = DatabaseService();
      final link = await db.acceptPartnerInvite(uid, code);
      if (link == null) return false;

      // Reload the link to populate all fields
      await _loadPartnerLink();
      return true;
    } catch (e) {
      debugPrint('Accept invite error: $e');
      return false;
    }
  }

  /// Revoke (disconnect) the active partner link.
  Future<void> revokePartnerLink() async {
    try {
      if (_partnerLinkId == null) return;

      final db = DatabaseService();
      await db.revokePartnerLink(_partnerLinkId!);

      _partnerLinkId = null;
      _partnerLinkRole = null;
      _linkedPartnerName = null;
      _linkedPartnerUid = null;
      _activeInviteCode = null;
      _partnerProfile = null;
      _partnerCycles = [];
      _partnerAssessments = [];
      _assessmentSub?.cancel();
      _assessmentSub = null;

      // Update native widget (revert to user cycle data)
      _updateHomeWidget();
      notifyListeners();
    } catch (e) {
      debugPrint('Revoke partner error: $e');
    }
  }

  // Getters - Symptoms
  List<String> get todaySymptoms => _todaySymptoms;
  Map<DateTime, List<String>> get symptomHistory => _symptomHistory;

  // Getters - Journal
  List<Map<String, dynamic>> get journalEntries => _journalEntries;

  // Getters - Wellness History
  Map<String, Map<String, dynamic>> get wellnessHistory => _wellnessHistory;

  /// Returns the last [days] days of wellness data, sorted by date.
  List<Map<String, dynamic>> getWellnessHistory(int days) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = days - 1; i >= 0; i--) {
      final date =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final key = date.toIso8601String().split('T')[0];
      final entry = _wellnessHistory[key];
      result.add({
        'date': date,
        'dateKey': key,
        'water': entry?['water'] ?? 0,
        'sleep': (entry?['sleep'] ?? 0.0).toDouble(),
        'steps': entry?['steps'] ?? 0,
        'mood': entry?['mood'] ?? 'Good',
        'symptoms': entry?['symptoms'] != null
            ? List<String>.from(entry!['symptoms'])
            : <String>[],
        'bbt': entry?['bbt'],
        'cervicalMucus': entry?['cervicalMucus'],
      });
    }
    return result;
  }

  /// Saves today's metrics as a daily snapshot for historical charting.
  Future<void> _saveDailySnapshot() async {
    final today = DateTime.now();
    final key = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')[0];

    final snapshot = {
      'water': _waterGlasses,
      'sleep': _sleepHours,
      'steps': _dailySteps,
      'mood': _currentMood,
      'symptoms': List<String>.from(_todaySymptoms),
      if (_todayBbt != null) 'bbt': _todayBbt,
      if (_todayCervicalMucus != null) 'cervicalMucus': _todayCervicalMucus,
    };

    _wellnessHistory[key] = snapshot;

    // Update the last_daily_metrics_date so we don't accidentally reset later today
    final todayStr = "${today.year}-${today.month}-${today.day}";
    _prefs.setString('last_daily_metrics_date', todayStr);

    // Sync daily assessment to cloud
    _syncDailySnapshotToCloud(key);

    // Cancel the 6 PM reminder for today since the user logged their metrics
    AppNotificationService().cancelEveningReminderForToday(
      isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
      trackedPersonName: _trackedPersonName,
    );
  }

  /// Returns aggregated symptom counts across the last [days] days.
  Map<String, int> getSymptomFrequency(int days) {
    final history = getWellnessHistory(days);
    final freq = <String, int>{};
    for (final entry in history) {
      for (final symptom in (entry['symptoms'] as List<String>)) {
        freq[symptom] = (freq[symptom] ?? 0) + 1;
      }
    }
    // Sort by frequency descending
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  // Getters - Predictions
  DateTime? get nextPeriodDate => _nextPeriodDate;
  DateTime? get ovulationDate => _ovulationDate;

  /// Predicts likely symptoms for today based on historical occurrences in the current phase.
  List<String> get currentPredictions {
    final phaseSymptoms = symptomsByPhase[currentPhase];
    if (phaseSymptoms == null || phaseSymptoms.isEmpty) return [];

    final sorted = phaseSymptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final predictions = <String>[];
    for (var entry in sorted.take(2)) {
      // Only predict if it has happened at least twice in this phase historically
      if (entry.value >= 2) {
        predictions.add(entry.key);
      }
    }
    return predictions;
  }

  // ─── MULTI-CYCLE INTELLIGENCE ────────────────────────

  /// Returns the list of past cycle start dates.
  List<DateTime> get cycleHistory => List.unmodifiable(_cycleHistory);

  /// The latest prediction result from the intelligence service.
  PredictionResult get latestPrediction => _latestPrediction;

  /// Adaptive cycle length computed via the intelligence engine.
  /// Uses exponential-decay weighted average — no outlier filtering.
  int get adaptiveCycleLength => _latestPrediction.effectiveCycleLengthRounded;

  /// The effective cycle length used for all calculations.
  int get effectiveCycleLength => adaptiveCycleLength;

  /// Dynamic ovulation day based on adaptive luteal phase.
  int get _ovulationDay => _latestPrediction.ovulationDay;

  /// Confidence score (0.0–1.0) for the current prediction.
  double get predictionConfidence => _latestPrediction.confidenceScore;

  /// Human-readable confidence label.
  String get confidenceLabel => _latestPrediction.confidenceLabel;

  /// Overall cycle regularity classification.
  CycleClassification get cycleClassification =>
      _latestPrediction.cycleClassification;

  /// Human-readable factors that influenced the prediction.
  List<String> get adjustmentFactors => _latestPrediction.adjustmentFactors;

  /// Lower bound of prediction window (for variable-confidence cycles).
  DateTime? get variableWindowStart => _latestPrediction.windowStart;

  /// Upper bound of prediction window.
  DateTime? get variableWindowEnd => _latestPrediction.windowEnd;

  /// Whether the prediction should be shown as a range.
  bool get isVariableWindow => _latestPrediction.isVariableWindow;

  /// Standard deviation of cycle gaps.
  double get cycleStdDev => _latestPrediction.standardDeviation;

  /// Personalized luteal phase length.
  int get lutealPhaseLength => _latestPrediction.lutealPhaseLength;

  // Calculated Properties
  int get currentCycleDay {
    final lastDate = _activeLastPeriodDate;
    if (lastDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastStart = DateTime(lastDate.year, lastDate.month, lastDate.day);

    final daysSinceStart = today.difference(lastStart).inDays;
    return (daysSinceStart % effectiveCycleLength) + 1;
  }

  /// Dynamic phase calculation based on actual cycle length.
  /// Menstrual: 1 → periodDuration
  /// Follicular: periodDuration+1 → ovulationDay-2
  /// Ovulation: ovulationDay-1 → ovulationDay+1 (3-day window)
  /// Luteal: ovulationDay+2 → cycleLength
  String get currentPhase => _getPhaseForDay(currentCycleDay);

  String _getPhaseForDay(int day) {
    if (_activeLastPeriodDate == null) return 'Waiting for Sync';
    if (day <= _activePeriodDuration) return 'Menstrual';
    final ovDay = _ovulationDay;
    if (day < ovDay - 1) return 'Follicular';
    if (day <= ovDay + 1) return 'Ovulation';
    return 'Luteal';
  }

  int get daysUntilNextPeriod {
    if (_activeLastPeriodDate == null) return 0;
    final day = currentCycleDay;
    return effectiveCycleLength - (day - 1);
  }

  bool get isOnPeriod => currentCycleDay <= _periodDuration;

  // ─── PERIOD CONFIRMATION LOOP ──────────────────────

  /// Whether to show "Did your period start?" prompt.
  /// Shows when user is within ±2 days of predicted period start
  /// and hasn't been asked/dismissed today.
  bool get shouldShowPeriodConfirmation {
    if (_lastPeriodDate == null || _nextPeriodDate == null) return false;
    // Don't show if already on period (days 1-2)
    if (currentCycleDay <= 2) return false;
    // Check if we're near the predicted period (within 2 days)
    final daysLeft = daysUntilNextPeriod;
    if (daysLeft > 2) return false; // Too early
    // Check if already dismissed today
    final lastDismissed = _prefs.getString('period_confirm_dismissed');
    if (lastDismissed != null) {
      final dismissedDate = DateTime.tryParse(lastDismissed);
      if (dismissedDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dismissed = DateTime(
            dismissedDate.year, dismissedDate.month, dismissedDate.day);
        if (today.isAtSameMomentAs(dismissed)) return false;
      }
    }
    return true;
  }

  /// User confirms their period started today.
  void confirmPeriodStarted() {
    final today = DateTime.now();
    setLastPeriodDate(DateTime(today.year, today.month, today.day));
    // Clear the dismiss flag
    _prefs.remove('period_confirm_dismissed');
    notifyListeners();
  }

  /// User says "Not yet" — dismiss for today and notify backend.
  void dismissPeriodConfirmation() {
    _prefs.setString(
        'period_confirm_dismissed', DateTime.now().toIso8601String());
    // Sync this delay event to backend so intelligence engine can learn
    _syncPeriodDelayToCloud();
    notifyListeners();
  }

  /// Log a period delay ("Not yet") event to the cloud so the backend
  /// intelligence engine can learn from prediction misses.
  Future<void> _syncPeriodDelayToCloud() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _nextPeriodDate == null) return;
    try {
      await DatabaseService().logPeriodDelay(
        userId: userId,
        predictedDate: _nextPeriodDate!,
        dismissedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Cloud sync error (period delay): $e');
    }
  }

  // ─── FERTILE WINDOW (Clinical Model) ─────────────────

  /// Fertile window: 5 days before ovulation + ovulation day = 6 days total.
  DateTime? get fertileWindowStart {
    if (_ovulationDate == null) return null;
    return _ovulationDate!.subtract(const Duration(days: 5));
  }

  DateTime? get fertileWindowEnd => _ovulationDate;

  int get daysUntilFertileWindow {
    if (fertileWindowStart == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = fertileWindowStart!.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get isInFertileWindow {
    final day = currentCycleDay;
    final ovDay = _ovulationDay;
    return day >= (ovDay - 5) && day <= ovDay;
  }

  // ─── CYCLE REGULARITY & STATISTICS ───────────────────

  /// Cycle lengths computed from history (no outlier filtering).
  List<int> get _historicalCycleLengths {
    if (_cycleHistory.length < 2) return [];
    final lengths = <int>[];
    for (int i = 1; i < _cycleHistory.length; i++) {
      final gap = _cycleHistory[i].difference(_cycleHistory[i - 1]).inDays;
      if (gap > 0) lengths.add(gap);
    }
    return lengths;
  }

  int get shortestCycle {
    final lengths = _historicalCycleLengths;
    if (lengths.isEmpty) return _cycleLength;
    return lengths.reduce(min);
  }

  int get longestCycle {
    final lengths = _historicalCycleLengths;
    if (lengths.isEmpty) return _cycleLength;
    return lengths.reduce(max);
  }

  int get cycleLengthVariation => longestCycle - shortestCycle;

  /// Irregularity now driven by the intelligence service classification.
  bool get isCycleIrregular =>
      cycleClassification == CycleClassification.irregular ||
      cycleClassification == CycleClassification.highlyIrregular;

  /// Human-readable irregularity warning.
  String? get irregularityWarning {
    if (_cycleHistory.length < 3) return null;
    if (!isCycleIrregular) return null;
    final classLabel =
        cycleClassification == CycleClassification.highlyIrregular
            ? 'highly irregular'
            : 'irregular';
    return 'Your cycles are $classLabel '
        '(σ=${cycleStdDev.toStringAsFixed(1)} days, '
        '$shortestCycle–$longestCycle day range). '
        'Predictions are shown as a window. '
        'Consider discussing with your doctor.';
  }

  int get totalCyclesTracked => _cycleHistory.length;

  // ─── PHASE-SPECIFIC SYMPTOM ANALYSIS ─────────────────

  /// Groups historical symptoms by which cycle phase they occurred in.
  Map<String, Map<String, int>> get symptomsByPhase {
    if (_lastPeriodDate == null || _wellnessHistory.isEmpty) return {};
    final result = <String, Map<String, int>>{
      'Menstrual': {},
      'Follicular': {},
      'Ovulation': {},
      'Luteal': {},
    };
    for (final entry in _wellnessHistory.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      final symptoms = entry.value['symptoms'];
      if (symptoms == null) continue;
      final phase = getPhaseForDate(date);
      if (!result.containsKey(phase)) continue;
      for (final s in List<String>.from(symptoms)) {
        result[phase]![s] = (result[phase]![s] ?? 0) + 1;
      }
    }
    return result;
  }

  /// Returns the top symptoms for the current phase based on history.
  List<String> get topSymptomsForCurrentPhase {
    final phaseSymptoms = symptomsByPhase[currentPhase];
    if (phaseSymptoms == null || phaseSymptoms.isEmpty) return [];
    final sorted = phaseSymptoms.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  // ─── ENHANCED AI CONTEXT ────────────────────────────

  String get aiUserContext {
    final fertileInfo = isInFertileWindow
        ? 'Currently in fertile window.'
        : (daysUntilFertileWindow > 0
            ? 'Fertile window in $daysUntilFertileWindow days.'
            : '');
    final classLabel = cycleClassification.name;
    final confLabel = confidenceLabel;
    final historyInfo = _cycleHistory.length >= 2
        ? 'Tracking ${_cycleHistory.length} cycles. '
            'Weighted avg: $adaptiveCycleLength days '
            '($shortestCycle–$longestCycle range, σ=${cycleStdDev.toStringAsFixed(1)}). '
            'Classification: $classLabel. '
            'Prediction confidence: $confLabel.'
        : 'Limited cycle history available.';

    return """
    User Profile: $_userName (Age: $_age, Gender: $_userGender).
    Current Cycle Status: Day $currentCycleDay of $effectiveCycleLength, $currentPhase phase. $daysUntilNextPeriod days until next period.
    $fertileInfo
    $historyInfo
    Luteal phase: $lutealPhaseLength days${lutealPhaseLength != 14 ? ' (personalized)' : ' (default)'}.
    Body Metrics: BMI ${bmi.toStringAsFixed(1)} (Weight: ${_weight}kg, Height: ${_height}cm).
    Today's Progress: $_dailySteps steps, $_waterGlasses glasses of water, $_sleepHours hrs sleep.
    Recent Symptoms: ${_todaySymptoms.isEmpty ? "No symptoms reported today" : _todaySymptoms.join(", ")}.
    Common symptoms in $currentPhase phase: ${topSymptomsForCurrentPhase.isEmpty ? 'None recorded yet' : topSymptomsForCurrentPhase.join(', ')}.
    """;
  }

  // ─── DYNAMIC GREETINGS ──────────────────────────────

  /// Generates an empathetic greeting with 20+ variations across phases.
  String get dynamicGreeting {
    if (_lastPeriodDate == null) return 'How are you feeling today?';

    final day = currentCycleDay;
    final phase = currentPhase;
    final rng = Random(DateTime.now().day); // Consistent per day

    final greetings = <String, List<String>>{
      'Menstrual': [
        'Be gentle with yourself today. Rest if you need it. 💜',
        'Your body is doing amazing work. Stay hydrated and nourished.',
        'It\'s okay to slow down. Honor what your body needs today.',
        'Wrap yourself in comfort today — you deserve it.',
        'Warm tea and rest can work wonders today. Take it easy.',
      ],
      'Follicular': [
        'Energy is returning! A great time to start new things. ✨',
        'You\'re glowing! High energy makes this a perfect day to focus.',
        'Your body is rebuilding. Channel this fresh energy into something new.',
        'Creativity peaks now — perfect for brainstorming and planning.',
        'Rising estrogen is boosting your mood. Embrace it!',
      ],
      'Ovulation': [
        'Peak energy! You are radiating confidence today. 🌟',
        'You\'re at your most magnetic! A great day for social connections.',
        'Your body is at peak performance — make the most of it!',
        'Energy and mood are at their highest. Enjoy this vibrant phase!',
        'Communication skills peak now — great for important conversations.',
      ],
      'Luteal': day > effectiveCycleLength - 5
          ? [
              'Your cycle is winding down. Time to slow down and cozy up.',
              'PMS may visit soon. Extra self-care is your best friend.',
              'Be extra kind to yourself — mood shifts are completely normal.',
              'Your period is approaching. Stock up on comfort essentials.',
              'Almost there. Listen to your cravings — your body knows.',
            ]
          : [
              'Take it easy today. Listen to what your body needs.',
              'Energy might dip today. Try some light stretching or yoga.',
              'Progesterone is rising — you may crave cozy activities.',
              'Nesting mode activated! A calm evening sounds perfect.',
              'Your body is preparing. Prioritize sleep tonight.',
            ],
    };

    final options = greetings[phase] ?? ['How are you feeling today?'];
    return options[rng.nextInt(options.length)];
  }

  // ─── ENHANCED PREDICTIVE INSIGHTS ───────────────────

  /// Phase-aware predictive insights with transition alerts and symptom predictions.
  String? get predictiveInsight {
    if (_lastPeriodDate == null) return null;

    final day = currentCycleDay;
    final phase = currentPhase;
    final ovDay = _ovulationDay;
    final cycleLen = effectiveCycleLength;

    // Irregularity alert (highest priority)
    if (irregularityWarning != null && day == 1) {
      return irregularityWarning;
    }

    // Phase transition alerts
    if (day == _periodDuration) {
      return 'Your period is ending soon. Energy should start improving tomorrow as you enter the Follicular phase.';
    }
    if (day == ovDay - 2) {
      return 'You\'ll enter your fertile window tomorrow. This is when energy and libido typically peak.';
    }
    if (day == ovDay + 1) {
      return 'Ovulation is likely today or yesterday. You\'re transitioning into the Luteal phase.';
    }
    if (day == cycleLen - 5) {
      return 'PMS window begins around now. Watch for mood shifts, cravings, and bloating in the next few days.';
    }
    if (day == cycleLen - 2) {
      return 'You are 2 days away from your period. You might notice changes in energy or mood tomorrow.';
    }
    if (day == cycleLen) {
      return 'Your period may start tomorrow based on your ${_cycleHistory.length >= 2 ? 'average' : 'estimated'} cycle of $cycleLen days.';
    }

    // Symptom-based predictions (using phase history)
    if (_wellnessHistory.isNotEmpty) {
      final phaseSymptoms = symptomsByPhase[phase];
      if (phaseSymptoms != null && phaseSymptoms.isNotEmpty) {
        final sorted = phaseSymptoms.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topSymptom = sorted.first.key;
        if (!_todaySymptoms.contains(topSymptom) && sorted.first.value >= 3) {
          return 'During $phase phase, you commonly experience $topSymptom. Keep an eye out and prepare accordingly.';
        }
      }
    }

    // Fertile window insight
    if (isInFertileWindow) {
      return 'You\'re in your fertile window — energy and mood tend to be at their best!';
    }

    return null;
  }

  // Setters - User Info
  void updateUserName(String name) {
    _userName = name;
    _saveToPrefs();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    _saveToPrefs();
    notifyListeners();
  }

  void setAge(int age) {
    _age = age;
    _saveToPrefs();
    notifyListeners();
  }

  void setUserGender(String gender) {
    _userGender = gender;
    _saveToPrefs();
    notifyListeners();
  }

  void setLastPeriodDate(DateTime date) {
    _lastPeriodDate = date;
    _addToCycleHistory(date);
    _calculatePredictions();
    _saveToPrefs();
    _updateReminders();
    _syncPeriodStartToCloud(date);
    notifyListeners();
  }

  /// Updates the existing last period date (from settings) to avoid duplicate cycles near the same time
  void updateLastPeriodDate(DateTime newDate) {
    if (isViewingPartner) return;
    if (_lastPeriodDate == null) {
      setLastPeriodDate(newDate);
      return;
    }

    final oldDate = _lastPeriodDate!;
    _lastPeriodDate = newDate;

    final normalizedNew = DateTime(newDate.year, newDate.month, newDate.day);
    final normalizedOld = DateTime(oldDate.year, oldDate.month, oldDate.day);

    // Remove the exact old date from history
    _cycleHistory.removeWhere((d) => d.isAtSameMomentAs(normalizedOld));
    // Remove any nearby dates to prevent duplicate artifacts
    _cycleHistory
        .removeWhere((d) => (d.difference(normalizedNew).inDays).abs() < 15);

    _cycleHistory.add(normalizedNew);
    _cycleHistory.sort();
    // Keep max 12 cycles
    if (_cycleHistory.length > 12) {
      _cycleHistory = _cycleHistory.sublist(_cycleHistory.length - 12);
    }

    _calculatePredictions();
    _saveToPrefs();
    _updateReminders();
    _replacePeriodStartInCloud(oldDate, newDate);
    notifyListeners();
  }

  /// Logs a new period start date to the multi-cycle history.
  /// Keeps max 12 cycles and avoids duplicates within 15 days.
  void _addToCycleHistory(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    // Avoid duplicate entries (within 15 days of an existing entry)
    final isDuplicate =
        _cycleHistory.any((d) => (d.difference(normalized).inDays).abs() < 15);
    if (!isDuplicate) {
      _cycleHistory.add(normalized);
      _cycleHistory.sort();
      // Keep max 12 cycles
      if (_cycleHistory.length > 12) {
        _cycleHistory = _cycleHistory.sublist(_cycleHistory.length - 12);
      }
    }
  }

  /// Manually log a new period start (can be called from UI).
  void logNewPeriod(DateTime startDate) {
    setLastPeriodDate(startDate);
  }

  Future<void> _replacePeriodStartInCloud(
      DateTime oldDate, DateTime newDate) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      // First, delete the old cycle
      await Supabase.instance.client
          .from('cycles')
          .delete()
          .eq('user_id', userId)
          .eq('start_date', oldDate.toIso8601String().split('T')[0]);

      // Then insert the new one
      await DatabaseService().upsertCycle(
        userId: userId,
        startDate: newDate,
      );
    } catch (e) {
      debugPrint('Cloud sync error (replace cycle): $e');
    }
  }

  Future<void> _syncPeriodStartToCloud(DateTime date) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await DatabaseService().upsertCycle(
        userId: userId,
        startDate: date,
      );
    } catch (e) {
      debugPrint('Cloud sync error (cycle): $e');
    }
  }

  Future<void> _syncDailySnapshotToCloud(String dateKey) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final snapshot = _wellnessHistory[dateKey];
    if (snapshot == null) return;
    try {
      await DatabaseService().upsertAssessment(
        userId: userId,
        date: DateTime.parse(dateKey),
        mood: snapshot['mood'] as String?,
        symptoms: snapshot['symptoms'] != null
            ? List<String>.from(snapshot['symptoms'])
            : null,
        waterIntake: (snapshot['water'] ?? 0) as int,
        sleepHours: (snapshot['sleep'] ?? 0.0).toDouble(),
        steps: (snapshot['steps'] ?? 0) as int,
      );
    } catch (e) {
      debugPrint('Cloud sync error (assessment): $e');
    }
  }

  void setCycleLength(int length) {
    _cycleLength = length;
    _calculatePredictions();
    _saveToPrefs();
    _updateReminders();
    notifyListeners();
  }

  void updateCycleLength(int length) {
    _cycleLength = length;
    _calculatePredictions();
    _saveToPrefs();
    _updateReminders();
    notifyListeners();
  }

  void setPeriodDuration(int duration) {
    _periodDuration = duration;
    _saveToPrefs();
    notifyListeners();
  }

  void updatePeriodLength(int length) {
    _periodDuration = length;
    _saveToPrefs();
    notifyListeners();
  }

  void setWeight(int weight) {
    _weight = weight;
    _saveToPrefs();
    notifyListeners();
  }

  void setHeight(int height) {
    _height = height;
    _saveToPrefs();
    notifyListeners();
  }

  void setBodyMetricsCompleted(bool completed) {
    _bodyMetricsCompleted = completed;
    _saveToPrefs();
    notifyListeners();
  }

  double get bmi {
    if (_height == 0) return 0;
    final heightInMeters = _height / 100;
    return _weight / (heightInMeters * heightInMeters);
  }

  // Daily Metrics Methods
  void updateSteps(int steps) {
    _dailySteps = steps;
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  void incrementSteps(int amount) {
    _dailySteps += amount;
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  void updateWater(int glasses) {
    _waterGlasses = glasses.clamp(0, 12);
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  /// Log today's Basal Body Temperature (in °C, range 35.0–38.5).
  void updateBbt(double temp) {
    _todayBbt = temp.clamp(35.0, 38.5);
    _saveDailySnapshot();
    _calculatePredictions(); // BBT data can trigger ovulation confirmation
    _saveToPrefs();
    notifyListeners();
  }

  /// Log today's cervical mucus observation.
  /// Accepted values: 'Dry', 'Sticky', 'Creamy', 'EggWhite', 'Watery'.
  void updateCervicalMucus(String type) {
    if (isViewingPartner) return;
    _todayCervicalMucus = type;
    _saveDailySnapshot();
    _calculatePredictions(); // CM data can trigger ovulation confirmation
    _saveToPrefs();
    notifyListeners();
  }

  void incrementWater() {
    if (_waterGlasses < 12) {
      _waterGlasses++;
      _saveDailySnapshot();
      _saveToPrefs();
      notifyListeners();
    }
  }

  void decrementWater() {
    if (_waterGlasses > 0) {
      _waterGlasses--;
      _saveDailySnapshot();
      _saveToPrefs();
      notifyListeners();
    }
  }

  void updateSleep(double hours) {
    _sleepHours = hours.clamp(0.0, 24.0);
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  void updateMood(String mood) {
    _currentMood = mood;
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  // Symptom Tracking Methods
  void addSymptom(String symptom) {
    if (isViewingPartner) return;
    if (!_todaySymptoms.contains(symptom)) {
      _todaySymptoms.add(symptom);
      _updateSymptomHistory();
      notifyListeners();
    }
  }

  void addQuickSymptom(String symptom) {
    if (!_todaySymptoms.contains(symptom)) {
      _todaySymptoms.add(symptom);
      _saveDailySnapshot();
      _saveToPrefs();
      notifyListeners();
    }
  }

  void removeSymptom(String symptom) {
    if (isViewingPartner) return;
    _todaySymptoms.remove(symptom);
    _updateSymptomHistory();
    notifyListeners();
  }

  void setTodaySymptoms(List<String> symptoms) {
    _todaySymptoms = symptoms;
    _updateSymptomHistory();
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  void addCustomSymptom(String name, int iconCodePoint, int colorValue) {
    if (!_customSymptoms
        .any((s) => s['name'].toString().toLowerCase() == name.toLowerCase())) {
      _customSymptoms.add({
        'name': name,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
      });
      _saveToPrefs();
      notifyListeners();
    }
  }

  void deleteCustomSymptom(String name) {
    _customSymptoms.removeWhere((s) => s['name'] == name);
    _todaySymptoms.remove(name);
    _updateSymptomHistory();
    _saveDailySnapshot();
    _saveToPrefs();
    notifyListeners();
  }

  void _updateSymptomHistory() {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    _symptomHistory[todayKey] = List.from(_todaySymptoms);
  }

  List<String> getSymptomsForDate(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    return _symptomHistory[dateKey] ?? [];
  }

  // ─── PREDICTION CALCULATIONS ────────────────────────

  void _calculatePredictions() {
    // Run the intelligence engine
    _latestPrediction = _intelligenceService.predict(
      cycleHistory: _activeCycleHistory,
      wellnessHistory:
          _wellnessHistory, // Partner wellness history mapping is optional for basic display
      userSetCycleLength: _activeCycleLength,
      periodDuration: _activePeriodDuration,
      lastPeriodDate: _activeLastPeriodDate,
    );

    _nextPeriodDate = _latestPrediction.predictedNextPeriod;
    _ovulationDate = _latestPrediction.predictedOvulation;

    // Trigger update for the Home Screen widget asynchronously
    _updateHomeWidget();
  }

  /// Update home screen widget using the home_widget package bridge.
  Future<void> _updateHomeWidget() async {
    try {
      // Determine if we should update with partner's cycle data
      final usePartner =
          _partnerLinkRole == 'partner' && _partnerCycles.isNotEmpty;

      final String phase;
      final int day;
      final int total;
      final String fertility;
      final int lastPeriodDateMs;
      final int cycleLen;
      final int periodDuration;
      final int ovulationDay;

      if (usePartner) {
        final cycleLength = _partnerProfile?['cycle_length'] ?? 28;
        final duration = _partnerProfile?['period_duration'] ?? 5;
        final latestStart =
            DateTime.parse(_partnerCycles.first['start_date'] as String);
        final cycleDay = DateTime.now().difference(latestStart).inDays + 1;

        final ovDay = cycleLength - 14;

        String pPhase = 'Unknown';
        if (cycleDay <= duration) {
          pPhase = 'Menstrual';
        } else if (cycleDay <= ovDay - 2) {
          pPhase = 'Follicular';
        } else if (cycleDay <= ovDay + 1) {
          pPhase = 'Ovulation';
        } else {
          pPhase = 'Luteal';
        }

        final pFertility = cycleDay <= duration
            ? "Menstruation"
            : ((cycleDay >= ovDay - 5 && cycleDay <= ovDay)
                ? "High Fertility"
                : "Low Fertility");

        phase = pPhase;
        day = cycleDay;
        total = cycleLength;
        fertility = pFertility;
        lastPeriodDateMs = latestStart.millisecondsSinceEpoch;
        cycleLen = cycleLength;
        periodDuration = duration;
        ovulationDay = ovDay;
      } else {
        phase = currentPhase;
        day = currentCycleDay;
        total = effectiveCycleLength;
        fertility = isOnPeriod
            ? "Menstruation"
            : (isInFertileWindow ? "High Fertility" : "Low Fertility");
        lastPeriodDateMs = _lastPeriodDate != null
            ? _lastPeriodDate!.millisecondsSinceEpoch
            : 0;
        cycleLen = effectiveCycleLength;
        periodDuration = _periodDuration;
        ovulationDay = _ovulationDay;
      }

      // Save widget keys (shared with Android remote views)
      await HomeWidget.saveWidgetData<String>('cycle_phase', '$phase Phase');
      await HomeWidget.saveWidgetData<String>(
          'cycle_day', 'Day $day of $total');
      await HomeWidget.saveWidgetData<String>('fertility_status', fertility);

      // Save raw widget configuration for native-side dynamic calculations
      await HomeWidget.saveWidgetData<int>(
          'last_period_date_ms', lastPeriodDateMs);
      await HomeWidget.saveWidgetData<int>('cycle_length', cycleLen);
      await HomeWidget.saveWidgetData<int>('period_duration', periodDuration);
      await HomeWidget.saveWidgetData<int>('ovulation_day', ovulationDay);

      // Request launcher database refresh
      await HomeWidget.updateWidget(
        name: 'LunaraWidgetProvider',
        androidName: 'LunaraWidgetProvider',
      );
      debugPrint(
          'Home Widget updated: $phase Phase, Day $day of $total, $fertility');
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  // Trigger Notification Scheduling
  void _updateReminders() {
    if (_nextPeriodDate == null) return;

    final appNs = AppNotificationService();

    // Schedule Period Reminder
    appNs.schedulePeriodReminder(
      _nextPeriodDate!,
      isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
      trackedPersonName: _trackedPersonName,
    );

    // Schedule Fertile Window Reminder
    if (fertileWindowStart != null) {
      appNs.scheduleFertileWindowReminder(
        fertileWindowStart!,
        isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
        trackedPersonName: _trackedPersonName,
      );
    }

    // Reschedule Daily Reminder (to ensure strings are updated)
    appNs.scheduleDailyReminder(
      isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
      trackedPersonName: _trackedPersonName,
    );

    // Schedule Wellness Forecast Reminders
    appNs.scheduleWellnessForecastReminders(
      _latestPrediction.wellnessForecasts,
      isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
      trackedPersonName: _trackedPersonName,
    );
  }

  // Helper Methods for UI (Calendar Screen)
  bool isOvulationDay(DateTime date) {
    if (_lastPeriodDate == null) return false;
    final targetDate = DateTime(date.year, date.month, date.day);
    final lastStart = DateTime(
        _lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);

    final daysSinceStart = targetDate.difference(lastStart).inDays;
    if (daysSinceStart < 0) return false; // Before tracking started
    final dayInCycle = (daysSinceStart % effectiveCycleLength) + 1;
    // Ovulation day is typically 14 days before the end of the cycle
    final ovDay = effectiveCycleLength - 14;
    return dayInCycle == ovDay;
  }

  String getPhaseForDate(DateTime date) {
    if (_lastPeriodDate == null) return 'Unknown';
    final daysSinceStart = date.difference(_lastPeriodDate!).inDays;
    final day = (daysSinceStart % effectiveCycleLength) + 1;
    return _getPhaseForDay(day);
  }

  bool isPeriodDay(DateTime date) {
    if (_lastPeriodDate == null) return false;
    final targetDate = DateTime(date.year, date.month, date.day);
    final lastStart = DateTime(
        _lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);

    final daysSinceStart = targetDate.difference(lastStart).inDays;
    final dayInCycle = (daysSinceStart % effectiveCycleLength) + 1;
    return dayInCycle >= 1 && dayInCycle <= _periodDuration;
  }

  /// Clinical fertile window: 5 days before ovulation + ovulation day.
  /// Now works for future predicted cycles using modular arithmetic.
  bool isFertileDay(DateTime date) {
    if (_lastPeriodDate == null) return false;
    final targetDate = DateTime(date.year, date.month, date.day);
    final lastStart = DateTime(
        _lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);

    final daysSinceStart = targetDate.difference(lastStart).inDays;
    if (daysSinceStart < 0) return false;
    final dayInCycle = (daysSinceStart % effectiveCycleLength) + 1;
    final ovDay = effectiveCycleLength - 14;
    // Clinical fertile window: 5 days before ovulation through ovulation day
    return dayInCycle >= (ovDay - 5) && dayInCycle <= ovDay;
  }

  /// Whether this date is a predicted (future) date vs confirmed history.
  bool isPredictedDay(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    return targetDate.isAfter(todayNorm);
  }

  /// Returns which phase day this is within the cycle for background coloring.
  /// Returns: 'menstrual', 'follicular', 'ovulatory', 'luteal', or 'none'.
  String getPhaseTypeForDate(DateTime date) {
    if (_lastPeriodDate == null) return 'none';
    final targetDate = DateTime(date.year, date.month, date.day);
    final lastStart = DateTime(
        _lastPeriodDate!.year, _lastPeriodDate!.month, _lastPeriodDate!.day);

    final daysSinceStart = targetDate.difference(lastStart).inDays;
    if (daysSinceStart < 0) return 'none';
    final dayInCycle = (daysSinceStart % effectiveCycleLength) + 1;
    final ovDay = effectiveCycleLength - 14;

    if (dayInCycle >= 1 && dayInCycle <= _periodDuration) return 'menstrual';
    if (dayInCycle <= ovDay - 5) return 'follicular';
    if (dayInCycle <= ovDay) return 'ovulatory';
    return 'luteal';
  }
}
