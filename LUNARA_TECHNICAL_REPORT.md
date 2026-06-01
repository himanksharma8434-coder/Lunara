# Lunara: Technical Implementation Report

**Project Name:** Lunara  
**Version:** 1.0.0  
**Authors:** [Your Name/Team]  
**Date:** April 2026  

---

## 1. Project Overview
Lunara is a privacy-first menstrual health and wellness companion designed to empower users with deep insights into their hormonal health. Unlike traditional trackers, Lunara prioritizes **Local-First Privacy** (Ghost Mode), ensuring that sensitive health data remains on-device and encrypted.

### Key Features:
- **Intelligent Cycle Prediction:** Adaptive algorithms that learn from historical data.
- **AI Wellness Insights:** Leveraging Google Gemini for personalized health guidance.
- **Ghost Mode:** AES-256 encrypted local storage with biometric lock.
- **Community interaction:** Secure, real-time discussions hosted on Supabase.

---

## 2. Technical Stack
| Category | Technology | Rationale |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter (Dart) | Multi-platform consistency and high-performance UI. |
| **Backend / Cloud** | Supabase | Real-time database, Auth, and secure RLS policies. |
| **Local Persistence** | Hive | High-speed NoSQL with native encryption support. |
| **State Management** | Provider | Reactive development with clean separation of concerns. |
| **AI Engine** | Google Gemini | State-of-the-art LLM for health and wellness context. |

---

## 3. Architecture & Design Patterns
Lunara follows a **Layered Architecture** to ensure maintainability and scalability:

1.  **Presentation Layer**: Flutter widgets and screens (e.g., `SymptomLogScreen`, `MainScreen`).
2.  **State Management Layer**: Providers that manage business logic and reactively update the UI (e.g., `CycleProvider`, `AuthProvider`).
3.  **Service Layer**: Infrastructure abstractions for external integrations (e.g., `SupabaseService`, `HealthService`).
4.  **Data Layer**: Local and remote persistence (e.g., `HiveService`, `DatabaseService`).

### The "Local-First" Pattern
To ensure maximum privacy, Lunara implements a "Local-First" strategy. Most health data is written to **Hive** locally first. Syncing to the cloud is optional and handled with strict privacy gates.

---

## 4. Why Hive? (Selection Analysis)
A critical design decision in Lunara was choosing **Hive** over the standard **Shared Preferences**.

### Comparative Analysis:
| Feature | Shared Preferences | Hive |
| :--- | :--- | :--- |
| **Performance** | Slower (suitable for small flags) | Ultra-fast (Binary format) |
| **Data Types** | Primitive types only (String, int) | Strong type safety (Custom Objects) |
| **Encryption** | Requires manual implementation | **Native AES-256 Support** |
| **Structure**| Flat key-value pairs | NoSQL Boxes (Relational-like) |

### Rationale for Choosing Hive:
1.  **Security:** Since Lunara handles sensitive medical/health information, we required native encryption. Hive's `HiveAesCipher` allows us to encrypt data on disk without third-party wrapper lag.
2.  **Complexity:** Menstrual records and assessments are complex objects. Encoding these to JSON strings for Shared Preferences is error-prone. Hive's **TypeAdapters** allow us to store Dart objects directly.
3.  **Speed:** Lunara features real-time charts and intensive data lookups. Hive's in-memory performance ensures the UI never stutters during calculations.

---

## 5. Core Implementation Highlights

### A. App Entry & Routing (`main.dart`)
The entry point manages complex initialization logic and the **Ghost Mode Gate**. If the app is locked, the router intercepts all navigation and forces the `LockScreen`.

```dart
// Snippet: Ghost Mode Lock Gate
if (privacyProvider.shouldShowLockScreen) {
  return MaterialApp(
    home: const LockScreen(),
    theme: AppTheme.darkTheme,
  );
}
```

### B. Encrypted Storage (`hive_service.dart`)
This service manages the lifecycle of the local database. It uses a singleton pattern to provide global access to encrypted "Boxes."

```dart
// Snippet: Opening an Encrypted Box
final encryptionKey = await EncryptionService.instance.getOrCreateEncryptionKey();
await Hive.openBox<UserProfileLocal>(
  'userProfiles', 
  encryptionCipher: HiveAesCipher(encryptionKey)
);
```

### C. Menstrual Intelligence Service
This is a pure, stateless engine that calculates cycle phases using **recency weighting** and **exponential decay**. It doesn't just guess; it learns.

```dart
// Snippet: Adaptive Luteal Phase
double _computeWeightedLength(List<int> gaps) {
  // Most recent cycles influence predictions more
  final recencyWeight = pow(_decayFactor, (gaps.length - 1 - i));
  // ... calculation logic
}
```

---

## 6. Security & Privacy
1.  **Ghost Mode:** Uses `flutter_secure_storage` to store the master encryption key and `Hive` for the data.
2.  **Row Level Security (RLS):** Our Supabase backend implements RLS, ensuring that no user can read another's cloud-synced data even if they have the API key.
3.  **Biometric Lock:** Integrated using `local_auth` to unlock the Ghost Mode gate.

---

## 7. Development & Setup
To run the project locally:
1.  Install Flutter SDK (`^3.6.0`).
2.  Run `flutter pub get`.
3.  Configure `.env` with Supabase and Gemini API keys.
4.  Run `flutter run`.

---

**Conclusion:** Lunara demonstrates a sophisticated integration of modern local-first database techniques, AI-driven insights, and a privacy-centric user experience.
