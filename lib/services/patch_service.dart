import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:lunara/services/logger_service.dart';

class PatchService extends ChangeNotifier {
  static final PatchService instance = PatchService._();
  PatchService._();

  final _shorebirdCodePush = ShorebirdCodePush();
  bool _isUpdateReadyToInstall = false;
  
  bool get isUpdateReadyToInstall => _isUpdateReadyToInstall;

  /// Initializes the Shorebird code push service and checks for updates silently.
  Future<void> init() async {
    try {
      final currentPatch = await currentPatchNumber();
      LoggerService.instance.info('Current Shorebird patch number: ${currentPatch ?? "none"}', tag: 'Shorebird');
      
      // Fire and forget check for update
      _checkForUpdate();
    } catch (e, st) {
      LoggerService.instance.error('Failed to initialize Shorebird', error: e, stackTrace: st, tag: 'Shorebird');
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final available = await isNewPatchAvailable();
      if (available) {
        LoggerService.instance.info('New patch available. Downloading...', tag: 'Shorebird');
        await downloadPatch();
      } else {
        LoggerService.instance.info('No new patches available.', tag: 'Shorebird');
      }
    } catch (e, st) {
      LoggerService.instance.error('Error during patch check flow', error: e, stackTrace: st, tag: 'Shorebird');
    }
  }

  /// Checks if a new patch is available for download.
  Future<bool> isNewPatchAvailable() async {
    try {
      return await _shorebirdCodePush.isNewPatchAvailableForDownload();
    } catch (e, st) {
      LoggerService.instance.error('Error checking for patch', error: e, stackTrace: st, tag: 'Shorebird');
      return false;
    }
  }

  /// Downloads the available patch.
  Future<void> downloadPatch() async {
    try {
      await _shorebirdCodePush.downloadUpdateIfAvailable();
      LoggerService.instance.info('Patch downloaded successfully. Waiting for restart.', tag: 'Shorebird');
      _isUpdateReadyToInstall = true;
      notifyListeners();
    } catch (e, st) {
      LoggerService.instance.error('Failed to download patch', error: e, stackTrace: st, tag: 'Shorebird');
    }
  }

  /// Gets the current patch number.
  Future<int?> currentPatchNumber() async {
    try {
      return await _shorebirdCodePush.currentPatchNumber();
    } catch (e) {
      return null;
    }
  }
}
