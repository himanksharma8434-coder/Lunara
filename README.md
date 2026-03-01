# Lunara 🌙

Lunara is a modern, privacy-focused cycle tracking and wellness application built with Flutter and Supabase. It helps users track their menstrual cycles, symptoms, moods, and provides personalized health insights.

## Features ✨

- **Cycle Tracking**: Log periods, predict fertile windows, and understand your body's rhythm.
- **Symptom Logging**: Track daily symptoms, moods, and wellness metrics (water, sleep, steps).
- **Smart Notifications**: Get reminders for period starts, fertile days, and daily logging.
- **Cloud Sync**: Securely backup your data to Supabase and sync across devices.
- **Modern UI**: Beautiful design with support for both Light and Dark modes.
- **Privacy First**: Sensitive data is handled securely with modern authentication.

## Tech Stack 🛠️

- **Frontend**: [Flutter](https://flutter.dev)
- **Backend/Auth/Database**: [Supabase](https://supabase.com)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Storage**: `shared_preferences` for local settings.
- **AI Integration**: [Google Gemini](https://deepmind.google/technologies/gemini/) (for health insights).

## Getting Started 🚀

### Prerequisites

- Flutter SDK (latest version)
- Dart SDK
- Android Studio / VS Code with Flutter extension
- A Supabase Project

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/lunara.git
   cd lunara
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Environment:
   Run the app with `--dart-define` to inject your keys:
   ```bash
   flutter run \
     --dart-define=GEMINI_API_KEY=YOUR_KEY \
     --dart-define=SUPABASE_URL=YOUR_URL \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

## Development 💻

To contribute or run locally:
- Use `lib/main.dart` as the entry point.
- Modify UI components in `lib/screens`.
- Update business logic in `lib/providers` and `lib/services`.

---

Built with ❤️ for better health tracking.
"# Lunara" 
