import 'package:flutter/foundation.dart';

import '../../../../services/database/hive_service.dart';
import '../../../auth/data/datasources/biometric_service.dart';

/// Manages Ghost Mode state: biometric lock, auto-lock, and privacy settings.
///
/// This provider integrates with [HiveService] for persistence and
/// [BiometricService] for authentication. It exposes reactive state
/// that the UI (lock screen, privacy settings) observes.
class PrivacyProvider extends ChangeNotifier {
  PrivacyProvider() {
    _loadSettings();
  }

  // ─── State ─────────────────────────────────────────

  bool _isLocked = true;
  bool _ghostModeEnabled = false;
  bool _biometricEnabled = false;
  int _autoLockTimeoutMinutes = 1;
  bool _isInitialized = false;

  bool get isLocked => _isLocked;
  bool get ghostModeEnabled => _ghostModeEnabled;
  bool get biometricEnabled => _biometricEnabled;
  int get autoLockTimeoutMinutes => _autoLockTimeoutMinutes;
  bool get isInitialized => _isInitialized;

  /// Whether the lock screen should be shown.
  ///
  /// Only shows if Ghost Mode is on AND biometric is on AND the app is locked.
  bool get shouldShowLockScreen =>
      _ghostModeEnabled && _biometricEnabled && _isLocked;

  // ─── Initialization ────────────────────────────────

  /// Loads persisted settings from Hive on startup.
  Future<void> _loadSettings() async {
    try {
      if (!HiveService.instance.isInitialized) {
        // Hive not ready yet — will be called again after init
        return;
      }

      final settings = await HiveService.instance.getSettings();
      _ghostModeEnabled = settings.ghostModeEnabled;
      _biometricEnabled = settings.biometricEnabled;
      _autoLockTimeoutMinutes = settings.autoLockTimeoutMinutes;

      // If ghost mode + biometric are enabled, start locked
      _isLocked = _ghostModeEnabled && _biometricEnabled;

      // Check if auto-lock timeout has elapsed since last unlock
      if (_isLocked && settings.lastUnlockTimestamp != null) {
        final elapsed =
            DateTime.now().difference(settings.lastUnlockTimestamp!);
        if (elapsed.inMinutes < _autoLockTimeoutMinutes) {
          _isLocked = false; // Within timeout, stay unlocked
        }
      }

      _isInitialized = true;
      notifyListeners();
      debugPrint(
        '🛡️ [PrivacyProvider] Loaded: ghost=$_ghostModeEnabled, '
        'biometric=$_biometricEnabled, locked=$_isLocked',
      );
    } catch (e) {
      debugPrint('🛡️ [PrivacyProvider] Failed to load settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Call after HiveService.init() completes to load persisted settings.
  Future<void> initialize() async {
    await _loadSettings();
  }

  // ─── Lock / Unlock ─────────────────────────────────

  /// Attempts biometric authentication and unlocks if successful.
  Future<bool> unlock() async {
    final result = await BiometricService.instance.authenticate(
      reason: 'Authenticate to open Lunara',
    );

    if (result == BiometricResult.success) {
      _isLocked = false;

      // Record unlock timestamp for auto-lock timeout calculation
      await HiveService.instance.updateSettings((s) {
        s.lastUnlockTimestamp = DateTime.now();
      });

      notifyListeners();
      return true;
    }

    return false;
  }

  /// Locks the app immediately (e.g., when backgrounded or manually locked).
  void lock() {
    if (_ghostModeEnabled && _biometricEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  /// Called when the app transitions to/from background.
  ///
  /// If Ghost Mode is enabled, this checks whether the auto-lock timeout
  /// has elapsed since the last unlock, and locks if so.
  Future<void> onAppLifecycleChanged(bool isResumed) async {
    if (!_ghostModeEnabled || !_biometricEnabled) return;

    if (isResumed) {
      final settings = await HiveService.instance.getSettings();
      if (settings.lastUnlockTimestamp == null) {
        _isLocked = true;
        notifyListeners();
        return;
      }

      final elapsed =
          DateTime.now().difference(settings.lastUnlockTimestamp!);

      if (_autoLockTimeoutMinutes == 0 ||
          elapsed.inMinutes >= _autoLockTimeoutMinutes) {
        _isLocked = true;
        notifyListeners();
      }
    }
  }

  // ─── Settings Mutations ────────────────────────────

  /// Toggles Ghost Mode on/off.
  Future<void> toggleGhostMode(bool enabled) async {
    _ghostModeEnabled = enabled;
    if (!enabled) {
      _isLocked = false; // Disable lock when ghost mode is off
    }

    await HiveService.instance.updateSettings((s) {
      s.ghostModeEnabled = enabled;
    });

    notifyListeners();
  }

  /// Toggles biometric authentication on/off.
  ///
  /// When enabling, verifies the device supports biometrics first.
  Future<bool> toggleBiometric(bool enabled) async {
    if (enabled) {
      // Verify biometric capability before enabling
      final supported = await BiometricService.instance.isDeviceSupported;
      final enrolled = await BiometricService.instance.isBiometricEnrolled;

      if (!supported || !enrolled) {
        debugPrint(
          '🛡️ [PrivacyProvider] Cannot enable biometric: '
          'supported=$supported, enrolled=$enrolled',
        );
        return false;
      }

      // Require authentication to enable biometric lock
      final result = await BiometricService.instance.authenticate(
        reason: 'Verify your identity to enable biometric lock',
      );

      if (result != BiometricResult.success) {
        return false;
      }
    }

    _biometricEnabled = enabled;
    if (!enabled) {
      _isLocked = false;
    }

    await HiveService.instance.updateSettings((s) {
      s.biometricEnabled = enabled;
    });

    notifyListeners();
    return true;
  }

  /// Updates the auto-lock timeout duration.
  Future<void> setAutoLockTimeout(int minutes) async {
    _autoLockTimeoutMinutes = minutes;

    await HiveService.instance.updateSettings((s) {
      s.autoLockTimeoutMinutes = minutes;
    });

    notifyListeners();
  }

  /// Wipes all local data and resets all settings to defaults.
  ///
  /// **Destructive**: Irrecoverable. Requires re-onboarding.
  Future<void> wipeAllData() async {
    await HiveService.instance.wipeAllData();

    _ghostModeEnabled = false;
    _biometricEnabled = false;
    _isLocked = false;
    _autoLockTimeoutMinutes = 1;

    notifyListeners();
    debugPrint('🛡️ [PrivacyProvider] All data wiped, settings reset.');
  }
}
