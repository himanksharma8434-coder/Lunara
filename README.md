# Lunara 🌙

**Your Local-First Personal Cycle, Reproductive Health & AI Wellness Companion**

[![Flutter](https://img.shields.io/badge/Flutter-3.6+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Hive Encryption](https://img.shields.io/badge/Security-Hive%20AES--256-FF6F00?style=for-the-badge&logo=hive&logoColor=white)](https://pub.dev/packages/hive)
[![Google Gemini](https://img.shields.io/badge/AI-Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
[![Shorebird](https://img.shields.io/badge/OTA-Shorebird%20Code%20Push-29B6F6?style=for-the-badge&logo=flutter&logoColor=white)](https://shorebird.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg?style=for-the-badge)]()

---

## 📌 Overview

**Lunara** is a state-of-the-art, privacy-centric menstrual health and reproductive wellness platform built with **Flutter** and **Supabase**. Engineered around a **Local-First Architecture (Ghost Mode)**, Lunara ensures sensitive health data remains strictly encrypted on device using **AES-256 Hive boxes** unlocked via native biometric credentials.

Unlike generic period trackers, Lunara combines a **stateless, recency-weighted Menstrual Intelligence Algorithm** with **Google Gemini AI** and **Groq LLM fallbacks** to deliver accurate cycle phase predictions, fertile window estimations, symptom correlation, personalized wellness plans, partner synchronization, clinical PDF exports, and healthcare provider discovery.

---

## ✨ Key Features Matrix

| Feature Module | Description & Technical Details |
| :--- | :--- |
| 🩸 **Adaptive Menstrual Engine** | Uses exponential decay weighting ($\lambda = 0.80$), BBT thermal shift detection (3-day coverline rule), cervical mucus profiling, and symptom correlation ($\pm 3$ days adjustment) for period & fertile window prediction. |
| 🔒 **Ghost Mode (Local-First Encryption)** | Complete zero-knowledge on-device storage with **Hive AES-256** binary boxes. Master keys are securely generated and isolated in native Keychain/Keystore via `flutter_secure_storage` with `local_auth` biometric locking. |
| 🤖 **Dual AI Wellness Engine** | Powered by **Google Gemini** (`google_generative_ai`) and **Groq AI** (`groq_service.dart`) with built-in sliding-window rate limiting (`ai_rate_limit_service.dart`) for personalized reproductive health guidance. |
| 👫 **Partner Sync** | Real-time cycle phase, mood, and daily status sharing with partners via **Supabase Realtime Postgres Changes** channels. |
| ❤️ **Health Kit & Health Connect** | Bi-directional synchronization with **Google Health Connect** (Android) and **Apple HealthKit** (iOS) for sleep patterns, daily step counts, basal body temperature (BBT), and heart rate metrics. |
| 💬 **Anonymous Community Forum** | Real-time community discussions with post creation, threaded commenting, voting, saved bookmarks (`SavedPostsService`), content moderation, and reporting. |
| 📅 **Doctor Discovery & Booking** | Geolocation-driven clinic & specialist search (`geolocator`), detailed provider profiles, appointment scheduling, and status tracking. |
| 💳 **Lunara Plus & Payments** | Premium subscription tier management integrated with **Razorpay** (`razorpay_flutter`), supporting tier upgrades, receipt verification, and feature gates. |
| 📄 **PDF Medical Report Generator** | Vector-based PDF summary generator (`pdf` & `printing`) compiling cycle history, symptom frequency, BBT graphs, and health notes for OB-GYNs. |
| 🔔 **Intelligent Notification Hub** | Local notification engine (`flutter_local_notifications`) with custom reminder schedules (period start, ovulation, daily check-in, medication) and timezone awareness (`timezone`). |
| ⚡ **Shorebird Over-The-Air (OTA) Updates** | Instant code push integration (`shorebird_code_push`) to ship Dart-level bug fixes instantly without waiting for app store submission delays. |

---

## 🛠️ Tech Stack & Dependencies

### Frontend Framework & Architecture
- **Framework**: Flutter 3.6+ / Dart 3.6+
- **State Management**: Reactive state handling with `Provider` (`AuthProvider`, `CycleProvider`, `ThemeProvider`, `AIProvider`, `PrivacyProvider`).
- **Design System**: Material 3, custom glassmorphism, dynamic dark/light themes, custom animations (`lottie`, `shimmer`, `flutter_staggered_animations`).

### Core Packages & Libraries
| Package | Version | Purpose |
| :--- | :--- | :--- |
| `supabase_flutter` | `^2.12.0` | Authentication, PostgreSQL Database, Realtime Subscriptions |
| `hive` / `hive_flutter` | `^2.2.3` | Local-First encrypted NoSQL database (AES-256) |
| `flutter_secure_storage` | `^10.0.0` | Secure storage for master encryption keys |
| `google_generative_ai` | `^0.4.7` | Google Gemini AI integration |
| `health` | `^13.3.1` | Google Health Connect & Apple HealthKit sync |
| `fl_chart` | `^1.1.1` | Smooth trend visualization for BBT, mood, and sleep |
| `razorpay_flutter` | `^1.4.5` | In-app subscription payment processing |
| `flutter_local_notifications` | `^21.0.0` | Scheduled & push local notifications |
| `shorebird_code_push` | `^2.0.6` | Over-the-air code deployment |
| `local_auth` | `^2.3.0` | Biometric authentication (Fingerprint / Face ID) |
| `geolocator` | `^13.0.2` | GPS-based doctor discovery |
| `pdf` & `printing` | `^3.11.3` | Clinical report PDF generation & printing |

---

## 📐 Architecture & Design Patterns

Lunara adheres to **Clean Layered Architecture** with strict separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                   │
│   (Flutter Widgets, Custom Components, Theme System)    │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│                  State Management Layer                 │
│  (AuthProvider, CycleProvider, AIProvider, Privacy)     │
└────────────────────────────┬────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────┐
│                      Service Layer                      │
│ (MenstrualIntelligence, Health, Notification, AI, PDF)  │
└──────────────┬───────────────────────────┬──────────────┘
               │                           │
┌──────────────▼─────────────┐   ┌─────────▼──────────────┐
│  Local-First Data (Hive)   │   │  Cloud Backend         │
│  (Encrypted AES-256 Boxes) │   │  (Supabase Auth & RLS) │
└────────────────────────────┘   └────────────────────────┘
```

### Why Hive over SharedPreferences?
1. **Security**: Native AES-256 disk encryption (`HiveAesCipher`) protects sensitive reproductive health logs.
2. **Speed & Memory**: In-memory binary storage provides ultra-low latency reads required for chart rendering.
3. **Structured Objects**: TypeAdapters allow direct storage of strongly-typed Dart domain models without JSON serialization overhead.

---

## 📁 Repository Structure

```
lunara/
├── android/                        # Native Android project configuration
├── ios/                            # Native iOS project configuration
├── assets/                         # Graphic assets, icons, and Lottie animations
├── lib/
│   ├── config/                     # Environment configuration & error rules
│   │   ├── app_config.dart
│   │   ├── app_errors.dart
│   │   ├── env.dart                # Git-ignored API keys config
│   │   └── env.example.dart        # Environment template file
│   ├── features/                   # Modular domain features
│   │   ├── auth/                   # Authentication logic & state
│   │   └── privacy/                # Ghost Mode local privacy engine & lock screen
│   ├── models/                     # Data models (User, Cycle, Assessment, Post, etc.)
│   ├── providers/                  # Provider state controllers (Cycle, Auth, Theme, AI)
│   ├── screens/                    # Application UI screens (35+ screens)
│   │   ├── main_screen.dart        # Shell navigation container
│   │   ├── calendar_screen.dart    # Cycle calendar & period logging
│   │   ├── insights_screen.dart    # Trend analytics & charts
│   │   ├── ai_chat_screen.dart     # AI Health Companion interface
│   │   ├── community_screen.dart   # Community discussion board
│   │   ├── partner_sync_screen.dart# Real-time partner synchronization
│   │   ├── wellness_plan_screen.dart# Custom AI wellness plans
│   │   └── ...                     # Additional detail & settings screens
│   ├── services/                   # Business logic & infrastructure abstractions
│   │   ├── menstrual_intelligence_service.dart # Cycle calculation engine
│   │   ├── app_notification_service.dart       # Local notification manager
│   │   ├── health_service.dart                 # HealthKit / Health Connect interface
│   │   ├── database_service.dart               # Supabase CRUD operations
│   │   ├── groq_service.dart                   # Fallback AI service
│   │   ├── pdf_export_service.dart             # PDF report generator
│   │   ├── razorpay_service.dart               # Payment gateway handler
│   │   ├── logger_service.dart                 # Centralized error logging
│   │   └── database/
│   │       └── hive_service.dart              # Encrypted local persistence
│   ├── theme/                      # App theme palettes & typography
│   ├── utils/                      # Helper methods, date formatters, and validators
│   ├── widgets/                    # Reusable custom UI components
│   └── main.dart                   # Application bootstrap with global error zoning
├── lunara-backend/                 # Node.js/Express admin & utility backend
│   ├── src/
│   │   ├── controllers/            # Route handlers
│   │   ├── middleware/             # JWT & validation middleware
│   │   └── models/                 # Sequelize database models
│   └── package.json
├── supabase/                       # Supabase local migration & edge functions
├── LUNARA_TECHNICAL_REPORT.md      # Detailed technical architecture report
├── SHOREBIRD_RUNBOOK.md            # Over-the-air patching deployment guide
├── supabase_rls_policies.sql       # PostgreSQL Row-Level Security policies
├── pubspec.yaml                    # Flutter project manifest & dependencies
├── shorebird.yaml                  # Shorebird OTA release configuration
└── README.md                       # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed on your developer machine:
- **Flutter SDK**: `>=3.6.0` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `>=3.6.0`
- **Android Studio** / **VS Code** with Flutter and Dart extensions
- **Supabase Account**: A active Supabase project ([Supabase Dashboard](https://supabase.com))
- **Google Gemini API Key**: ([Google AI Studio](https://aistudio.google.com/))

---

### Installation & Environment Setup

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/himanksharma8434-coder/Lunara.git
   cd Lunara/lunara
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**

   Create a `.env` file in the root of `lunara/` or copy the example template:
   ```bash
   cp lib/config/env.example.dart lib/config/env.dart
   ```
   Populate your keys in `.env` (or `lib/config/env.dart`):
   ```env
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   GEMINI_API_KEY=your-google-gemini-api-key
   GROQ_API_KEY=your-groq-api-key
   RAZORPAY_KEY_ID=your-razorpay-key-id
   ```

   Alternatively, supply variables directly during compilation:
   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=your_url \
     --dart-define=SUPABASE_ANON_KEY=your_anon_key \
     --dart-define=GEMINI_API_KEY=your_gemini_key
   ```

4. **Database & RLS Setup:**
   Run the contents of `supabase_rls_policies.sql` in your Supabase SQL Editor to configure Row Level Security for all tables.

5. **Run the Application:**
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Code Quality

Run the automated unit and widget test suite:
```bash
flutter test
```

Run static code analysis and linter checks:
```bash
flutter analyze
```

---

## ⚡ Over-The-Air (OTA) Updates with Shorebird

Lunara utilizes **Shorebird Code Push** to push Dart fixes directly to end users without requiring App Store or Google Play re-reviews.

- **Initial Release Build**:
  ```bash
  shorebird release android
  shorebird release ios
  ```

- **Deploying a Patch**:
  ```bash
  shorebird patch android
  shorebird patch ios
  ```
*Refer to [`EDUCATIONAL_GUIDE.md`](file:///d:/Lunara/lunara/EDUCATIONAL_GUIDE.md) for step-by-step technical educational concepts and [`SHOREBIRD_RUNBOOK.md`](file:///d:/Lunara/lunara/SHOREBIRD_RUNBOOK.md) for full patch compliance instructions.*

---

## 🔒 Security & Compliance

- **Zero-Knowledge Local Storage**: All personal cycle logs and health entries in Ghost Mode are encrypted using AES-256 before disk writes.
- **Row Level Security (RLS)**: PostgreSQL tables strictly enforce `auth.uid() = user_id` access controls in Supabase.
- **SSL / TLS Pinning & Transport Security**: Secure communication enforced across all external network calls.
- **Global Error Guarding**: Production runtime exceptions are captured silently via `runZonedGuarded` and `FlutterError.onError` without crashing the application.

---

## 📄 License & Attribution

This project is proprietary software. All rights reserved.

Built with ❤️ for privacy, health empowerment, and intelligent cycle care.
