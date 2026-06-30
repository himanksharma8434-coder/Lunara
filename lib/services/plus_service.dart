import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Singleton service to manage plus subscription status.
///
/// For now this is a local flag stored in SharedPreferences + synced
/// to the `users` table column `is_premium`.  When you integrate a
/// payment provider (Google Play Billing / RevenueCat / Stripe) you
/// only need to call [setPlus] from the purchase callback.
class PlusService extends ChangeNotifier {
  static const String _keyIsPremium = 'is_premium';

  PlusService._();
  static final PlusService instance = PlusService._();

  bool _isPlus = false;

  bool get isPlus => _isPlus;

  // ─── Free-tier AI limits ───────────────────────────
  /// Daily AI message cap for free users.
  static const int freeDailyLimit = 10;

  // ─── Model tiers ──────────────────────────────────
  /// Models available to free users (lightweight & cheap).
  static const List<String> freeModels = [
    'qwen-3.6-27b',
    'mixtral-8x7b-32768',
  ];

  /// Models available to Plus users (powerful reasoning).
  static const List<String> plusModels = [
    'qwen-3.6-27b',
    'mixtral-8x7b-32768',
  ];

  /// Returns the ordered model list for the current tier.
  List<String> get availableModels => _isPlus ? plusModels : freeModels;

  /// The daily AI request limit for the current tier.
  /// Returns -1 for unlimited (Plus).
  int get dailyLimit => _isPlus ? -1 : freeDailyLimit;

  // ─── Initialisation ───────────────────────────────
  /// Load the cached plus flag. Call once on app start.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPlus = prefs.getBool(_keyIsPremium) ?? false;
    notifyListeners();

    // Also try to fetch from Supabase if logged in
    await _syncFromCloud();
  }

  // ─── Mutation ─────────────────────────────────────
  /// Set plus status (called from purchase flow or admin toggle).
  Future<void> setPlus(bool value) async {
    _isPlus = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
    notifyListeners();

    // Sync to Supabase
    await _syncToCloud(value);
  }

  // ─── Cloud sync ───────────────────────────────────
  Future<void> _syncFromCloud() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      final row = await Supabase.instance.client
          .from('users')
          .select('is_premium')
          .eq('uid', uid)
          .maybeSingle();

      if (row != null && row['is_premium'] == true) {
        _isPlus = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyIsPremium, true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PlusService: cloud sync read error: $e');
    }
  }

  Future<void> _syncToCloud(bool value) async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'is_premium': value}).eq('uid', uid);
    } catch (e) {
      debugPrint('PlusService: cloud sync write error: $e');
    }
  }
}
