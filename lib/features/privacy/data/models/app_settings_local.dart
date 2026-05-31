import 'package:hive/hive.dart';

part 'app_settings_local.g.dart';

/// Ghost Mode and privacy settings stored in the encrypted Hive database.
///
/// This uses a singleton pattern where we store specific keys in a generic
/// box, or use a specific single-object box.
@HiveType(typeId: 3)
class AppSettingsLocal extends HiveObject {
  /// Whether Ghost Mode is enabled (full local-first privacy).
  @HiveField(0)
  bool ghostModeEnabled = false;

  /// Whether biometric authentication is required on app launch.
  @HiveField(1)
  bool biometricEnabled = false;

  /// Auto-lock timeout in minutes. 0 = lock immediately on background.
  @HiveField(2)
  int autoLockTimeoutMinutes = 1;

  /// Timestamp of the last successful biometric unlock.
  /// Used to determine if re-authentication is needed after backgrounding.
  @HiveField(3)
  DateTime? lastUnlockTimestamp;

  /// User's selected journey mode for Pillar 4:
  /// 'performance', 'hormone_management', 'trying_to_conceive', 'avoiding_pregnancy'
  @HiveField(4)
  String? journeyMode;
}
