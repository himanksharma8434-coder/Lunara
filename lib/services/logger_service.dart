import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A centralized logging service for the Lunara app.
///
/// In debug mode, logs are printed to the console.
/// In release mode, only warnings and errors are recorded, and could be
/// forwarded to a remote crash-reporting service (e.g. Firebase Crashlytics).
class LoggerService {
  LoggerService._();
  static final LoggerService instance = LoggerService._();

  /// Log a general informational message (debug builds only).
  void info(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'Lunara');
    }
  }

  /// Log a warning. Visible in all builds.
  void warning(String message, {String? tag}) {
    developer.log('⚠️ $message', name: tag ?? 'Lunara');
  }

  /// Log an error with an optional stack trace.
  /// In release mode, this is where you'd forward to Crashlytics.
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      '❌ $message',
      name: tag ?? 'Lunara',
      error: error,
      stackTrace: stackTrace,
    );

    // TODO: In production, forward to Firebase Crashlytics:
    // if (!kDebugMode) {
    //   FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
    // }
  }
}
