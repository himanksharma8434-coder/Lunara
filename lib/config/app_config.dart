import 'env.dart';

/// Centralized app configuration.
///
/// All secrets are loaded from [Env] (lib/config/env.dart) which is
/// git-ignored. See env.example.dart for the template.
///
/// You can still override at build time using --dart-define:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///   flutter run --dart-define=SUPABASE_URL=your_url_here
///   flutter run --dart-define=SUPABASE_ANON_KEY=your_key_here
class AppConfig {
  AppConfig._();

  /// Gemini AI API key — uses --dart-define override, else falls back to Env.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: Env.geminiApiKey,
  );

  /// Supabase Project URL — uses --dart-define override, else falls back to Env.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: Env.supabaseUrl,
  );

  /// Supabase anon (public) key — uses --dart-define override, else falls back to Env.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: Env.supabaseAnonKey,
  );
}
