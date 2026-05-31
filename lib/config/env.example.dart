// ──────────────────────────────────────────────────────────────
// 🔒  env.example.dart — TEMPLATE for env.dart
// ──────────────────────────────────────────────────────────────
// Copy this file to env.dart and fill in your real values.
//   cp env.example.dart env.dart
// ──────────────────────────────────────────────────────────────

class Env {
  Env._();

  /// Supabase Project URL
  /// Get from: Supabase Dashboard → Project Settings → API → Project URL
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';

  /// Supabase anon (public) key
  /// Get from: Supabase Dashboard → Project Settings → API → anon key
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  /// Gemini AI API key
  /// Get from: https://aistudio.google.com/apikey
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';

  /// Groq AI API key
  /// Get from: https://console.groq.com/keys
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
}
