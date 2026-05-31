import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/privacy/data/models/app_settings_local.dart';
import '../../features/privacy/data/models/assessment_local.dart';
import '../../features/privacy/data/models/cycle_record_local.dart';
import '../../features/privacy/data/models/user_profile_local.dart';
import 'encryption_service.dart';

/// Singleton service that manages the encrypted Hive local database.
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  bool _isInit = false;
  bool get isInitialized => _isInit;

  Future<void> init() async {
    if (_isInit) return;

    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserProfileLocalAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CycleRecordLocalAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AssessmentLocalAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(AppSettingsLocalAdapter());

    // Get the encryption key
    final encryptionKey = await EncryptionService.instance.getOrCreateEncryptionKey();

    // Open Encrypted Boxes
    await Hive.openBox<UserProfileLocal>('userProfiles', encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<CycleRecordLocal>('cycleRecords', encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<AssessmentLocal>('assessments', encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox<AppSettingsLocal>('appSettings', encryptionCipher: HiveAesCipher(encryptionKey));

    _isInit = true;
    debugPrint('📦 [HiveService] Database initialized with AES-256 encryption.');
  }

  // ─── Convenience Box Accessors ──────────────

  Box<UserProfileLocal> get userProfiles => Hive.box<UserProfileLocal>('userProfiles');
  Box<CycleRecordLocal> get cycleRecords => Hive.box<CycleRecordLocal>('cycleRecords');
  Box<AssessmentLocal> get assessments => Hive.box<AssessmentLocal>('assessments');
  Box<AppSettingsLocal> get appSettings => Hive.box<AppSettingsLocal>('appSettings');

  // ─── Settings Helpers ─────────────────────────────

  Future<AppSettingsLocal> getSettings() async {
    if (appSettings.isEmpty) {
      final defaults = AppSettingsLocal();
      await appSettings.put('default', defaults);
      return defaults;
    }
    return appSettings.get('default')!;
  }

  Future<void> updateSettings(void Function(AppSettingsLocal settings) mutator) async {
    final settings = await getSettings();
    mutator(settings);
    await settings.save();
  }

  // ─── Database Lifecycle ────────────────────────────

  Future<void> wipeAllData() async {
    await userProfiles.clear();
    await cycleRecords.clear();
    await assessments.clear();
    await appSettings.clear();
    await EncryptionService.instance.destroyEncryptionKey();
    debugPrint('📦 [HiveService] All local data wiped and key destroyed.');
  }

  Future<void> close() async {
    await Hive.close();
    _isInit = false;
    debugPrint('📦 [HiveService] Database closed.');
  }
}
