/// Centralized app configuration.
///
/// Pass secrets at build time using:
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///   flutter run --dart-define=SUPABASE_URL=your_url_here
///   flutter run --dart-define=SUPABASE_ANON_KEY=your_key_here
class AppConfig {
  AppConfig._();

  /// Gemini AI API key — injected at build time via --dart-define.
  /// Falls back to empty string if not provided.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Supabase Project URL — injected at build time via --dart-define.
  /// Get this from: Supabase Dashboard → Project Settings → API → Project URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://iiftktwprnrtojbhscbw.supabase.co',
  );

  /// Supabase anon (public) key — injected at build time via --dart-define.
  /// Get this from: Supabase Dashboard → Project Settings → API → anon key
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlpZnRrdHdwcm5ydG9qYmhzY2J3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyMTA0MTEsImV4cCI6MjA4Nzc4NjQxMX0.GXEhL0dPXNY0r_zkBJyfCMQMkC-ezOQjQs1niwadOpc',
  );
}
