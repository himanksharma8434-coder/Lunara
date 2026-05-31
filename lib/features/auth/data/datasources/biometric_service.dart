import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric authentication result.
enum BiometricResult {
  /// Authentication succeeded.
  success,

  /// User cancelled or failed authentication.
  failed,

  /// Biometrics not available on this device.
  unavailable,

  /// Biometrics not enrolled (no fingerprint/face registered).
  notEnrolled,

  /// Platform error (e.g., permission denied).
  error,
}

/// Service that wraps the `local_auth` plugin for biometric authentication.
///
/// Supports FaceID, fingerprint, and iris scanning depending on the
/// device hardware. Falls back gracefully when biometrics are unavailable.
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks whether the device supports any form of biometric authentication.
  Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      debugPrint('🔒 [BiometricService] isDeviceSupported error: $e');
      return false;
    }
  }

  /// Checks whether biometrics are currently enrolled (e.g., a fingerprint
  /// or face is registered in system settings).
  Future<bool> get isBiometricEnrolled async {
    try {
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on PlatformException catch (e) {
      debugPrint('🔒 [BiometricService] isBiometricEnrolled error: $e');
      return false;
    }
  }

  /// Returns the list of available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('🔒 [BiometricService] getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Prompts the user for biometric authentication.
  ///
  /// [reason] is the message shown to the user explaining why authentication
  /// is needed (e.g., "Authenticate to open Lunara").
  ///
  /// Returns a [BiometricResult] indicating success, failure, or unavailability.
  Future<BiometricResult> authenticate({
    String reason = 'Authenticate to open Lunara',
  }) async {
    try {
      final deviceSupported = await isDeviceSupported;
      if (!deviceSupported) {
        debugPrint('🔒 [BiometricService] Device does not support biometrics.');
        return BiometricResult.unavailable;
      }

      final enrolled = await isBiometricEnrolled;
      if (!enrolled) {
        debugPrint('🔒 [BiometricService] No biometrics enrolled.');
        return BiometricResult.notEnrolled;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN/passcode fallback
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        debugPrint('🔒 [BiometricService] Authentication successful.');
        return BiometricResult.success;
      } else {
        debugPrint('🔒 [BiometricService] Authentication failed/cancelled.');
        return BiometricResult.failed;
      }
    } on PlatformException catch (e) {
      debugPrint('🔒 [BiometricService] PlatformException: $e');
      return BiometricResult.error;
    }
  }
}
