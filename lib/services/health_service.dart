import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/cycle_provider.dart';

/// Service to interface with Google Health Connect (Android) and Apple HealthKit (iOS).
class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  bool _configured = false;

  /// Data types we want to read from the health platform.
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  /// Ensure the Health plugin is configured. Call once on app start.
  Future<void> configure() async {
    if (_configured) return;
    await Health().configure();
    _configured = true;
  }

  /// Check if the health platform (Health Connect / HealthKit) is available.
  Future<bool> isAvailable() async {
    await configure();
    return await Health().isHealthConnectAvailable();
  }

  /// Request read-only permissions for the data types we need.
  Future<bool> requestPermissions() async {
    await configure();
    try {
      final authorized = await Health().requestAuthorization(_readTypes);
      return authorized;
    } catch (e) {
      debugPrint('Health permission error: $e');
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

      // Save last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('health_last_sync', DateTime.now().toIso8601String());

      debugPrint('Health sync complete: steps=$steps, sleep=$sleep, weight=$weight, height=$height');
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
}
