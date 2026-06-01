# Architecture Overview

**Analysis Date:** 2026-03-25

## System Pattern

**Type:** Multi-module (Flutter Frontend + Node.js Backend)
- **Frontend:** Reactive, Provider-based architecture with local-first privacy (Ghost Mode).
- **Backend:** REST API using Express.js and Sequelize ORM.

## Layered Architecture (Frontend)

**1. Presentation Layer (`lib/screens`, `lib/widgets`):**
- Focused on UI rendering and user interaction.
- Screens are navigated via a central router in `main.dart`.
- Uses `MultiProvider` to inject state into the widget tree.

**2. State Management Layer (`lib/providers`):**
- `AuthProvider`: Manages user session, onboarding state, and login.
- `CycleProvider`: Handles menstrual cycle data and predictions.
- `PrivacyProvider`: Manages "Ghost Mode" (lock state and encryption).
- `ThemeProvider`: Manages app-wide styles and theme switching.

**3. Service Layer (`lib/services`):**
- Infrastructure abstractions (e.g., `Supabase`, `Health`, `Hive`).
- Handles communication with external APIs and local storage.

**4. Data Layer (`lib/models`, `lib/services/database`):**
- Defines data structures and persistence logic.
- `HiveService` provides encrypted local storage for privacy-first data.

## Layered Architecture (Backend)

**1. Entry Point (`lunara-backend/src/app.js`):**
- Bootstraps Express, middleware, and route registration.
- Handles database synchronization via Sequelize.

**2. Routing Layer (`lunara-backend/src/routes`):**
- Modular route definitions (e.g., `/api/auth`, `/api/cycles`).
- Maps endpoints to controllers.

**3. Request Handling (`lunara-backend/src/controllers`):**
- Extracts data from requests and coordinates service calls.

**4. Business Logic (`lunara-backend/src/services`):**
- Domain-specific logic separated from transport (HTTP).

**5. Persistence (`lunara-backend/src/models`):**
- Sequelize models representing the PostgreSQL schema.

## Data Flow

**Authentication Flow:**
- User logs in via `LoginScreen` -> `AuthProvider`.
- `AuthProvider` calls `Supabase.auth.signInWithPassword`.
- On success, session info is stored in `SharedPreferences` and Supabase client persists the token.

**Health Data Flow:**
- `HealthService` requests permissions and fetches data from the platform (HealthKit/Google Fit).
- Data is processed and stored locally via `Hive` or synced to Supabase (depending on privacy settings).

**Ghost Mode (Privacy Flow):**
- Sensitive data is stored in encrypted Hive boxes using `HiveService`.
- `PrivacyProvider` monitors app lifecycle to auto-lock the app when backgrounded.
- `LockScreen` intercepts all routes when `shouldShowLockScreen` is true.

## Key Abstractions

- `HiveService`: Centralized management of encrypted boxes.
- `HealthService`: Unified API for background health data fetching.
- `LoggerService`: Singleton for consistent logging across the app.
