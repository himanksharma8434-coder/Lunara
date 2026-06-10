import 'package:shared_preferences/shared_preferences.dart';
import 'plus_service.dart';

/// A service to track and enforce daily limits on AI requests.
///
/// Free tier: 10 messages/day.
/// Plus tier: Unlimited.
class AIRateLimitService {
  static const String _keyDailyCount = 'ai_daily_request_count';
  static const String _keyLastRequestDate = 'ai_last_request_date';

  AIRateLimitService._();
  static final AIRateLimitService instance = AIRateLimitService._();

  /// The daily limit for the current tier.
  /// Returns the free-tier cap or -1 for unlimited (Plus).
  static int get dailyLimit {
    final plus = PlusService.instance;
    return plus.isPlus ? -1 : PlusService.freeDailyLimit;
  }

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
    // Plus users always can
    if (PlusService.instance.isPlus) return true;

    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    return count < PlusService.freeDailyLimit;
  }

  /// Increments the count of daily requests.
  Future<void> incrementRequestCount() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    await prefs.setInt(_keyDailyCount, count + 1);
  }

  /// Returns the number of requests remaining for today.
  /// Returns -1 for unlimited (Plus).
  Future<int> getRemainingRequests() async {
    if (PlusService.instance.isPlus) return -1;

    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    final count = prefs.getInt(_keyDailyCount) ?? 0;
    int remaining = PlusService.freeDailyLimit - count;
    return remaining > 0 ? remaining : 0;
  }
}
