# Lunara 🌙

**Your personal cycle & wellness companion.**

Lunara is a modern, privacy-focused menstrual cycle tracking and wellness app built with Flutter and Supabase. It helps users understand their body through intelligent cycle predictions, symptom tracking, and health insights — all while keeping data secure and private.

---

## Features ✨

| Feature | Description |
|---------|-------------|
| 🩸 **Cycle Tracking** | Log periods, predict fertile windows & ovulation with adaptive algorithms |
| 📊 **Insights & Charts** | Visualize mood, sleep, steps, and symptom trends over time |
| 🤖 **AI Health Chat** | Ask cycle-related questions powered by Google Gemini |
| 📝 **Symptom & Mood Logging** | Track daily symptoms, moods, and wellness metrics |
| 🔔 **Smart Notifications** | Period predictions, daily reminders, and fertile window alerts |
| ❤️ **Health Connect / HealthKit** | Sync steps, sleep, heart rate, and menstrual data |
| 👫 **Partner Sync** | Share cycle data with a partner in real-time |
| 📄 **PDF Reports** | Export health summaries for your doctor |
| 🌙 **Dark Mode** | Beautiful UI in both light and dark themes |
| ☁️ **Cloud Sync** | Securely back up data to Supabase across devices |
| 🔒 **Privacy First** | Global error handling, encrypted storage, no data selling |

---

## Tech Stack 🛠️

- **Frontend**: [Flutter](https://flutter.dev) 3.x
- **Backend / Auth / DB**: [Supabase](https://supabase.com) (PostgreSQL, Auth, Realtime)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Storage**: `shared_preferences`, `flutter_secure_storage`
- **AI**: [Google Gemini](https://deepmind.google/technologies/gemini/) via `google_generative_ai`
- **Health**: `health` package (Google Health Connect + Apple HealthKit)
- **Charts**: `fl_chart`
- **Notifications**: `flutter_local_notifications`
- **PDF Export**: `pdf` + `printing`

---

## Getting Started 🚀

### Prerequisites

- Flutter SDK `>=3.6.0`
- Dart SDK `>=3.6.0`
- Android Studio / VS Code with Flutter extension
- A [Supabase](https://supabase.com) project
- (Optional) A Google Gemini API key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/himanksharma8434-coder/Lunara.git
   cd lunara
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables:**

   Copy the example config and add your keys:
   ```bash
   cp lib/config/env.example.dart lib/config/env.dart
   ```
   Edit `lib/config/env.dart` with your Supabase URL, anon key, and Gemini API key.

   Alternatively, use `--dart-define` at build time:
   ```bash
   flutter run \
     --dart-define=GEMINI_API_KEY=your_key \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_anon_key
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

### Running Tests

```bash
flutter test
```

---

## Project Structure 📁

```
lib/
├── config/           # App configuration & environment variables
├── models/           # Data models (User, Cycle, Assessment, etc.)
├── providers/        # State management (Auth, Cycle, Theme, AI)
├── screens/          # All app screens (27 screens)
├── services/         # Backend services (DB, Health, Notifications, PDF, Logging)
├── theme/            # App theming (light/dark)
├── widgets/          # Reusable UI components
└── main.dart         # App entry point with global error handling
```

---

## Key Screens

- **Home** — Cycle overview, daily metrics, AI insights
- **Calendar** — Interactive cycle calendar with period logging
- **Insights** — Trend charts (mood, sleep, symptoms, steps)
- **AI Chat** — Ask health questions with Gemini-powered responses
- **Profile** — Account settings, health sync, partner link, PDF export

---

## Security & Privacy 🔒

- SSL certificate validation enforced (no insecure overrides)
- Global error handling via `runZonedGuarded` + `FlutterError.onError`
- Centralized logging with `LoggerService` (Crashlytics-ready)
- API keys stored in git-ignored `env.dart`, not hardcoded
- Health data access requires explicit user permission

---

## License

This project is private. All rights reserved.

---

Built with ❤️ for better health tracking.
