import 'package:shared_preferences/shared_preferences.dart';

/// A service to track and enforce daily limits on AI requests.
class AIRateLimitService {
  static const String _keyDailyCount = 'ai_daily_request_count';
  static const String _keyLastRequestDate = 'ai_last_request_date';
  
  /// The daily limit for free AI usage as requested.
  static const int dailyLimit = 100;

  AIRateLimitService._();
  static final AIRateLimitService instance = AIRateLimitService._();

  /// Resets the daily count if the current date is different from the last recorded request date.
  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final lastDateStr = prefs.getString(_keyLastRequestDate);

    if (lastDateStr != todayStr) {
      await prefs.setInt(_keyDailyCount, 0);
      await prefs.setString(_keyLastRequestDate, todayStr);
    }
  }

  /// Checks if the user can still make AI requests today.
  Future<bool> canMakeRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    return count < dailyLimit;
  }

  /// Increments the count of daily requests.
  Future<void> incrementRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    await prefs.setInt(_keyDailyCount, count + 1);
  }

  /// Returns the number of requests remaining for today.
  Future<int> getRemainingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    int remaining = dailyLimit - count;
    return remaining > 0 ? remaining : 0;
  }
}
