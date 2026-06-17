import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  /// Save data to cache with a specified expiration duration.
  Future<void> setCache(String key, dynamic data, {Duration ttl = const Duration(hours: 1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheObject = {
      'timestamp': DateTime.now().toIso8601String(),
      'ttl_seconds': ttl.inSeconds,
      'data': data,
    };
    await prefs.setString(key, jsonEncode(cacheObject));
  }

  /// Retrieve data from cache if it exists and hasn't expired.
  Future<dynamic> getCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return null;

    try {
      final cacheObject = jsonDecode(jsonStr);
      final cachedTime = DateTime.parse(cacheObject['timestamp']);
      final ttlSeconds = cacheObject['ttl_seconds'] as int;
      final expiryTime = cachedTime.add(Duration(seconds: ttlSeconds));

      if (DateTime.now().isAfter(expiryTime)) {
        // Cache expired
        await prefs.remove(key);
        return null;
      }

      return cacheObject['data'];
    } catch (e) {
      // If parsing fails, clear the corrupted cache
      await prefs.remove(key);
      return null;
    }
  }

  /// Clear a specific cache key
  Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear all app cache (useful on logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming all cache keys start with a specific prefix if we want to be safe, 
    // but SharedPreferences clear() wipes everything.
    // To be safer, we could iterate and remove only specific keys if needed,
    // but typically clearAll is fine on logout.
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith('api_cache_') || key.startsWith('ai_pred_')) {
        await prefs.remove(key);
      }
    }
  }
}
