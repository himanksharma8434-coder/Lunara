# Lunara 🌙 — Comprehensive Educational & Architectural Guide

Welcome to the **Lunara Educational & Architectural Guide**! This document is designed for students, software engineers, data scientists, and healthcare technology enthusiasts who want to learn how modern, privacy-first mobile applications are designed, built, and deployed.

---

## 📚 Table of Contents

1. [Understanding the Science: Menstrual Physiology & Algorithmic Modeling](#1-understanding-the-science-menstrual-physiology--algorithmic-modeling)
2. [Software Engineering: Local-First Privacy & Zero-Knowledge Security](#2-software-engineering-local-first-privacy--zero-knowledge-security)
3. [Architecture & Patterns: Clean Layered Architecture in Flutter](#3-architecture--patterns-clean-layered-architecture-in-flutter)
4. [Artificial Intelligence: Dual LLM Integration & Rate Limiting](#4-artificial-intelligence-dual-llm-integration--rate-limiting)
5. [Real-time Distributed Systems: Supabase Sync & Partner Pairing](#5-real-time-distributed-systems-supabase-sync--partner-pairing)
6. [Mobile DevOps: Over-The-Air (OTA) Code Push with Shorebird](#6-mobile-devops-over-the-air-ota-code-push-with-shorebird)
7. [Hands-On Code Walkthroughs & Learning Exercises](#7-hands-on-code-walkthroughs--learning-exercises)

---

## 1. Understanding the Science: Menstrual Physiology & Algorithmic Modeling

Menstrual cycle prediction is traditionally done using simple calendar averages (e.g. assuming every user has a 28-day cycle with ovulation on day 14). However, physiological cycles vary significantly due to stress, hormonal fluctuations, PCOS (Polycystic Ovary Syndrome), and irregular anovulatory cycles.

Lunara replaces static averages with a **stateless, recency-weighted prediction algorithm** located in `lib/services/menstrual_intelligence_service.dart`.

### Key Mathematical & Biological Concepts:

#### A. Exponential Decay Recency-Weighting
Recent cycles are more representative of future cycle length than older cycles. Lunara applies an **exponential decay factor** ($\lambda = 0.80$):

$$\text{Weight}_i = \lambda^{(N - 1 - i)}$$

Where $N$ is total historical cycles, and $i$ is the cycle index ($0$ being oldest, $N-1$ being most recent). The weighted mean cycle length is calculated as:

$$\bar{L} = \frac{\sum_{i=0}^{N-1} (\text{Length}_i \cdot \text{Weight}_i)}{\sum_{i=0}^{N-1} \text{Weight}_i}$$

> **Educational Takeaway**: Outliers (such as a 45-day cycle caused by illness) are down-weighted over time rather than arbitrarily deleted, respecting real-world health variations like PCOS.

#### B. Basal Body Temperature (BBT) & Thermal Shift Detection
Progesterone released after ovulation causes a slight rise in resting body temperature ($0.2^\circ\text{C} - 0.5^\circ\text{C}$). Lunara applies the **3-day coverline rule**:
- A baseline average is established over 6 consecutive pre-ovulation low temperatures.
- Ovulation is confirmed when 3 consecutive daily temperatures exceed the baseline by at least $0.2^\circ\text{C}$.

#### C. Cervical Mucus & Symptom Shift
- **Fertile Mucus**: `EggWhite` or `Watery` consistency indicates high estrogen and approaching ovulation.
- **Pre-Menstrual Symptoms**: Markers such as *Cramps*, *Bloating*, and *Breast Tenderness* appearing near the end of the luteal phase trigger a dynamic date shift of up to $\pm 3$ days to adjust predicted period start dates in real time.

---

## 2. Software Engineering: Local-First Privacy & Zero-Knowledge Security

Health and reproductive data is among the most sensitive data a user owns. Lunara prioritizes a **Local-First (Ghost Mode)** paradigm.

```
                      +-----------------------------+
                      |   User Interface (Screen)   |
                      +--------------+--------------+
                                     |
                                     v
                      +-----------------------------+
                      |  Encrypted Hive Box (AES)   |  <--- ON-DEVICE (FAST)
                      +--------------+--------------+
                                     |
                          Is Cloud Sync Enabled?
                               /           \
                             YES            NO
                             /               \
                            v                 v
                 +-------------------+    [End Process]
                 |  Supabase Cloud   |   (Data stays on
                 | (Encrypted Vault) |   device only)
                 +-------------------+
```

### Technical Concepts:
1. **Master Encryption Key Isolation**: Master AES keys are generated natively on device and stored in hardware-backed secure enclaves (`Keychain` on iOS, `Keystore` via EncryptedSharedPreferences on Android) via `flutter_secure_storage`.
2. **Hive AES-256 Binary Storage**: Hive stores custom Dart objects directly in binary `.hive` files using `HiveAesCipher`.
3. **Biometric Guard (`local_auth`)**: When Ghost Mode is locked, navigation is trapped by a top-level route guard forcing the `LockScreen` before decrypting local Hive storage.

---

## 3. Architecture & Patterns: Clean Layered Architecture in Flutter

Lunara uses **Clean Layered Architecture** with the **Provider** pattern for reactive state management.

```
lib/
├── screens/      <-- PRESENTATION LAYER: UI Widgets & Layouts
├── providers/    <-- STATE MANAGEMENT LAYER: Business Logic & Controllers
├── services/     <-- SERVICE LAYER: Algorithmic Engines, API Clients, I/O
└── models/       <-- DATA LAYER: Data Structures & Entities
```

### Why Provider?
- **Separation of Concerns**: UI widgets only rebuild when notified (`notifyListeners()`).
- **Testability**: Services and providers can be easily mocked using `mocktail` or `mockito` without building UI widgets.

---

## 4. Artificial Intelligence: Dual LLM Integration & Rate Limiting

Lunara integrates AI to act as a supportive wellness guide, answering user questions about symptoms, cycle phases, and nutrition.

### Architecture Highlights:
- **Primary AI**: Google Gemini (`google_generative_ai` SDK).
- **Fallback AI**: Groq Cloud API (`groq_service.dart`) for high-throughput resilience.
- **Sliding-Window Rate Limiter** (`ai_rate_limit_service.dart`): Prevents API abuse and quota exhaustion by tracking query timestamps in local cache.
- **Prompt Safety System**: System instructions strictly constrain AI responses to wellness guidance, advising users to seek professional medical advice for clinical diagnoses.

---

## 5. Real-time Distributed Systems: Supabase Sync & Partner Pairing

To enable real-time features like **Partner Sync** and **Anonymous Community Forums**:

### Key Concepts:
1. **Row Level Security (RLS)**: PostgreSQL policies in Supabase enforce `auth.uid() = user_id`, guaranteeing that even if someone acquires a database connection, they cannot query another user's rows.
2. **Postgres Changes Subscription**: `SupabaseRealtime` listens directly to database change events over WebSockets, updating the partner's UI instantly when a period log or phase transition is recorded.

---

## 6. Mobile DevOps: Over-The-Air (OTA) Code Push with Shorebird

Traditional mobile updates require manual app store submission, review (1-3 days), and user adoption delay. Lunara integrates **Shorebird Code Push** (`shorebird_code_push`).

### How OTA Works:
1. Shorebird compiles Dart code into executable bytecode patches.
2. On app launch, `PatchService.instance.init()` checks Shorebird servers in the background.
3. If an OTA patch is available, it downloads and prepares the patch for the next seamless app launch.

> **Safety Rule**: Shorebird patches **Dart-only code**. Native Android (`android/`) or iOS (`ios/`) changes require a standard app store release.

---

## 7. Hands-On Code Walkthroughs & Learning Exercises

### Exercise 1: Tracing Cycle Prediction
- **File**: [`lib/services/menstrual_intelligence_service.dart`](file:///d:/Lunara/lunara/lib/services/menstrual_intelligence_service.dart)
- **Task**: Inspect `predictNextCycle()`. Notice how historical cycle start dates are converted into cycle length intervals (`gaps`), and trace how `_computeWeightedLength()` computes the predicted length using `_decayFactor`.

### Exercise 2: Tracing Local Encryption Setup
- **File**: [`lib/services/database/hive_service.dart`](file:///d:/Lunara/lunara/lib/services/database/hive_service.dart)
- **Task**: Observe how `Hive.openBox()` consumes a `HiveAesCipher` key obtained from native storage. Try explaining to a colleague why raw encryption keys should never be stored in plain text configuration files.

### Exercise 3: Adding a Custom Log Metric
- **Challenge**: Suppose you want to add a new tracking metric, such as *Water Intake (ml)*.
  1. Add `waterIntake` field to `lib/models/assessment_model.dart`.
  2. Update Hive TypeAdapter in `hive_service.dart`.
  3. Add input controls in `lib/screens/symptom_log_screen.dart`.
  4. Display trends in `lib/screens/insights_screen.dart`.

---

*Designed for learning and engineering excellence. Happy coding! 🚀*
