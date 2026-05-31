import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cycle_provider.dart';

/// Service to interface with Google Health Connect (Android) and Apple HealthKit (iOS).
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  bool _configured = false;
  String? lastError;

  /// Data types we want to read from the health platform.
  static final List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    // Reproductive health — available on both platforms
    HealthDataType.MENSTRUATION_FLOW,
  ];

  /// Data types we want to write (e.g. syncing period data back to health platform).
  static final List<HealthDataType> _writeTypes = [
    HealthDataType.MENSTRUATION_FLOW,
  ];

  /// Ensure the Health plugin is configured. Call once on app start.
  Future<void> configure() async {
    if (_configured) return;
    // Explicitly configure for Health Connect if available (Android 14+)
    final status = await Health().getHealthConnectSdkStatus();
    if (status == HealthConnectSdkStatus.sdkAvailable) {
      debugPrint('Health: Health Connect is available.');
    }
    await Health().configure();
    _configured = true;
  }

  /// Check if Health Connect is available on this device (Android only).
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final status = await Health().getHealthConnectSdkStatus();
      debugPrint('Health: Health Connect status: $status');
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      debugPrint('Health: Error checking Health Connect status: $e');
      return false;
    }
  }

  /// Check if the health platform (Health Connect / HealthKit) is available.
  Future<bool> isAvailable() async {
    await configure();
    try {
      if (Platform.isAndroid) {
        return await isHealthConnectAvailable();
      }
      // On iOS, HealthKit is always available on iPhones.
      return Platform.isIOS;
    } catch (e) {
      debugPrint('Health availability check error: $e');
      return false;
    }
  }

  /// Request read + write permissions for the data types we need.
  Future<bool> requestPermissions() async {
    await configure();
    lastError = null;
    try {
      if (Platform.isAndroid) {
        // Explicitly request Activity Recognition first via permission_handler
        final activityStatus = await Permission.activityRecognition.request();
        debugPrint('Health: Activity Recognition status: $activityStatus');
        
        if (activityStatus.isDenied) {
          lastError = 'Activity Recognition permission is required for steps.';
          return false;
        }

        final status = await Health().getHealthConnectSdkStatus();
        debugPrint('Health: Health Connect SDK status: $status');
        if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          lastError = 'Health Connect is not installed. Please install it from the Play Store.';
          await Health().installHealthConnect();
          return false;
        }
        
        if (status == HealthConnectSdkStatus.sdkUnavailable) {
          lastError = 'Health Connect is not supported on this device.';
          return false;
        }
      }

      final allTypes = [..._readTypes, ..._writeTypes];
      final permissions = [
        ...List.filled(_readTypes.length, HealthDataAccess.READ),
        ...List.filled(_writeTypes.length, HealthDataAccess.WRITE),
      ];
      
      debugPrint('Health: Calling requestAuthorization for ${allTypes.length} types...');
      final authorized = await Health().requestAuthorization(
        allTypes,
        permissions: permissions,
      );

      // Even if authorized is false, check what we actually have
      final grantedTypes = <HealthDataType>[];
      final deniedTypes = <HealthDataType>[];
      
      for (final type in allTypes) {
        final has = await Health().hasPermissions([type]);
        if (has == true) {
          grantedTypes.add(type);
        } else {
          deniedTypes.add(type);
        }
      }
      
      debugPrint('Health: requestAuthorization result: $authorized');
      debugPrint('Health: Detailed status - Granted: $grantedTypes');
      debugPrint('Health: Detailed status - Denied: $deniedTypes');

      if (authorized) return true;

      if (grantedTypes.isNotEmpty) {
        lastError = 'Selective access granted. Some features might be limited.';
        // We consider it a success if at least one type is granted
        return true;
      } else {
        lastError = 'Permission dialog was dismissed or all permissions were denied.';
        return false;
      }
    } catch (e, st) {
      lastError = 'Internal Error: $e';
      debugPrint('Health: Exception during requestPermissions: $e');
      debugPrint('Stacktrace:\n$st');
      return false;
    }
  }

  /// Check if we already have the required permissions.
  Future<bool> hasPermissions() async {
    await configure();
    try {
      final authorized = await Health().hasPermissions(_readTypes);
      return authorized ?? false;
    } catch (e) {
      debugPrint('Health hasPermissions error: $e');
      return false;
    }
  }

  /// Fetch today's total steps.
  Future<int> fetchTodaySteps() async {
    await configure();
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final steps = await Health().getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Health fetchSteps error: $e');
      return 0;
    }
  }

  /// Fetch last night's sleep duration in hours.
  Future<double> fetchLastNightSleep() async {
    await configure();
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final sleepData = await Health().getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP, HealthDataType.SLEEP_IN_BED],
        startTime: yesterday,
        endTime: now,
      );

      if (sleepData.isEmpty) return 0.0;

      // Sum up sleep durations
      double totalMinutes = 0;
      for (final point in sleepData) {
        final duration = point.dateTo.difference(point.dateFrom).inMinutes;
        totalMinutes += duration;
      }

      return double.parse((totalMinutes / 60.0).toStringAsFixed(1));
    } catch (e) {
      debugPrint('Health fetchSleep error: $e');
      return 0.0;
    }
  }

  /// Fetch latest heart rate reading (bpm).
  Future<int?> fetchLatestHeartRate() async {
    await configure();
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(hours: 24));

      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: oneDayAgo,
        endTime: now,
      );

      if (data.isEmpty) return null;

      // Get most recent reading
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return null;
    } catch (e) {
      debugPrint('Health fetchHeartRate error: $e');
      return null;
    }
  }

  /// Fetch latest weight in kg.
  Future<int?> fetchLatestWeight() async {
    await configure();
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: thirtyDaysAgo,
        endTime: now,
      );

      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toInt();
      }
      return null;
    } catch (e) {
      debugPrint('Health fetchWeight error: $e');
      return null;
    }
  }

  /// Fetch latest height in cm.
  Future<int?> fetchLatestHeight() async {
    await configure();
    try {
      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));

      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: oneYearAgo,
        endTime: now,
      );

      if (data.isEmpty) return null;
      data.sort((a, b) => b.dateTo.compareTo(a.dateTo));
      final value = data.first.value;
      if (value is NumericHealthValue) {
        // Health stores height in meters, convert to cm
        return (value.numericValue * 100).toInt();
      }
      return null;
    } catch (e) {
      debugPrint('Health fetchHeight error: $e');
      return null;
    }
  }

  /// Fetch menstrual flow data from the last 90 days.
  /// Returns a list of dates where menstruation was logged.
  Future<List<DateTime>> fetchMenstrualData() async {
    await configure();
    try {
      final now = DateTime.now();
      final ninetyDaysAgo = now.subtract(const Duration(days: 90));

      final data = await Health().getHealthDataFromTypes(
        types: [HealthDataType.MENSTRUATION_FLOW],
        startTime: ninetyDaysAgo,
        endTime: now,
      );

      if (data.isEmpty) return [];

      // Extract unique dates
      final dates = <DateTime>{};
      for (final point in data) {
        final d = point.dateFrom;
        dates.add(DateTime(d.year, d.month, d.day));
      }

      final sortedDates = dates.toList()..sort();
      debugPrint('Health: Found ${sortedDates.length} menstrual data points');
      return sortedDates;
    } catch (e) {
      debugPrint('Health fetchMenstrualData error: $e');
      return [];
    }
  }

  /// Write a period start date back to the health platform.
  Future<bool> writePeriodData({
    required DateTime startDate,
    required int durationDays,
  }) async {
    await configure();
    try {
      bool success = true;
      for (int i = 0; i < durationDays; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59));

        final wrote = await Health().writeHealthData(
          value: 0, // Flow value (0 = unspecified)
          type: HealthDataType.MENSTRUATION_FLOW,
          startTime: dayStart,
          endTime: dayEnd,
        );

        if (!wrote) success = false;
      }

      debugPrint(
          'Health: Wrote period data ($durationDays days) success=$success');
      return success;
    } catch (e) {
      debugPrint('Health writePeriodData error: $e');
      return false;
    }
  }

  /// Sync all health data into the CycleProvider.
  Future<void> syncAll(CycleProvider provider) async {
    try {
      final steps = await fetchTodaySteps();
      if (steps > 0) provider.updateSteps(steps);

      final sleep = await fetchLastNightSleep();
      if (sleep > 0) provider.updateSleep(sleep);

      final weight = await fetchLatestWeight();
      if (weight != null && weight > 0) provider.setWeight(weight);

      final height = await fetchLatestHeight();
      if (height != null && height > 0) provider.setHeight(height);

      // Sync menstrual data from health platform
      final menstrualDates = await fetchMenstrualData();
      if (menstrualDates.isNotEmpty) {
        debugPrint('Health: Syncing ${menstrualDates.length} menstrual dates');
        // The most recent date cluster is likely the last period start
        // We pass this to the provider for potential auto-update
        provider.importMenstrualDates(menstrualDates);
      }

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'health_last_sync', DateTime.now().toIso8601String());

      debugPrint(
          'Health sync complete: steps=$steps, sleep=$sleep, weight=$weight, height=$height, menstrualDates=${menstrualDates.length}');
    } catch (e) {
      debugPrint('Health syncAll error: $e');
    }
  }

  /// Get the last sync timestamp.
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('health_last_sync');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Get a human-readable name for the connected platform.
  String get platformName {
    if (Platform.isAndroid) return 'Google Fit (via Health Connect)';
    if (Platform.isIOS) return 'Apple Health';
    return 'Health Platform';
  }
}
