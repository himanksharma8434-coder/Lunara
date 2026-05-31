import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages AES-256 encryption keys for the local Hive database.
///
/// On first launch, generates a cryptographically secure 256-bit key
/// and persists it in the platform's secure keystore (Keychain on iOS,
/// EncryptedSharedPreferences on Android). On subsequent launches,
/// retrieves the existing key.
///
/// The key never leaves the device and is protected by the OS-level
/// secure storage, which itself is hardware-backed on modern devices.
class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const String _encryptionKeyStorageKey = 'lunara_hive_encryption_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Uint8List? _cachedKey;

  /// Returns the 256-bit encryption key, generating one if it doesn't exist.
  ///
  /// The key is cached in-memory for the session lifetime to avoid repeated
  /// secure storage reads during hot reloads / restarts.
  Future<Uint8List> getOrCreateEncryptionKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      final stored = await _secureStorage.read(key: _encryptionKeyStorageKey);

      if (stored != null && stored.isNotEmpty) {
        _cachedKey = _parseKeyString(stored);
        debugPrint('🔐 [EncryptionService] Loaded existing encryption key.');
        return _cachedKey!;
      }
    } catch (e) {
      debugPrint(
        '🔐 [EncryptionService] Could not read stored key: $e. Generating new.',
      );
    }

    // Generate a fresh 256-bit key (32 bytes)
    _cachedKey = _generateKey();
    await _persistKey(_cachedKey!);
    debugPrint('🔐 [EncryptionService] Generated and stored new encryption key.');
    return _cachedKey!;
  }

  /// Generates a cryptographically secure 256-bit (32-byte) random key.
  Uint8List _generateKey() {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
  }

  /// Persists the key as a comma-separated byte string in secure storage.
  Future<void> _persistKey(Uint8List key) async {
    final keyString = key.join(',');
    await _secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: keyString,
    );
  }

  /// Parses a comma-separated byte string back into a [Uint8List].
  Uint8List _parseKeyString(String keyString) {
    final bytes = keyString.split(',').map((s) => int.parse(s.trim())).toList();
    return Uint8List.fromList(bytes);
  }

  /// Destroys the encryption key from secure storage.
  ///
  /// **WARNING**: This makes all locally encrypted data irrecoverable.
  /// Use only for the "Wipe all data" feature in Ghost Mode settings.
  Future<void> destroyEncryptionKey() async {
    _cachedKey = null;
    await _secureStorage.delete(key: _encryptionKeyStorageKey);
    debugPrint('🔐 [EncryptionService] Encryption key destroyed.');
  }
}
