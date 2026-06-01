# Technology Stack

**Analysis Date:** 2026-03-25

## Languages

**Primary:**
- Dart 3.6.0+ - Flutter frontend application code
- JavaScript (Node.js) - Backend application code (`lunara-backend`)

**Secondary:**
- HTML/CSS - Web-related assets/components
- SQL - Database queries (PostgreSQL/Supabase)

## Runtime

**Environment:**
- Flutter SDK 3.6.0+ - Mobile/Web UI runtime
- Node.js 20.x+ - Backend server runtime
- PostgrSQL - Database engine

**Package Manager:**
- `pub` - Flutter dependencies (`pubspec.yaml`)
- `npm` - Node.js dependencies (`package.json`)
- Lockfiles: `pubspec.lock`, `package-lock.json` (implied)

## Frameworks

**Core:**
- Flutter - UI framework for the mobile/web app
- Express 5.2.1 - Backend web framework
- Sequelize 6.37.7 - Node.js ORM for PostgreSQL

**Testing:**
- `flutter_test` - Flutter unit and widget tests
- `test` - Node.js (scripts in `package.json`)

**Build/Dev:**
- `nodemon` - Backend development auto-restart
- `sequelize-cli` - Database migration and seed management

## Key Dependencies

**Critical:**
- `supabase_flutter` 2.8.3 - Backend as a Service (Auth, DB, Storage)
- `google_generative_ai` 0.4.5 - Gemini AI integration
- `provider` 6.1.2 - Frontend state management
- `hive` 2.2.3 - Lightweight local storage for Flutter
- `health` 11.0.1 - Health data integration (Apple Health / Google Fit)
- `sequelize` 6.37.7 - DB abstraction (Backend)

**Infrastructure:**
- `express` 5.2.1 - Backend routing and middleware
- `pg` 8.16.3 - PostgreSQL client for Node.js
- `jsonwebtoken` - Backend session management
- `zod` - Runtime schema validation for backend APIs

## Configuration

**Environment:**
- `.env` files - Backend configuration (env vars like `DATABASE_URL`, `JWT_SECRET`)
- `pubspec.yaml` - Frontend assets and dependencies

**Build:**
- `analysis_options.yaml` - Dart linting and formatting
- `package.json` - Node.js scripts and metadata

## Platform Requirements

**Development:**
- Cross-platform (Windows/macOS/Linux)
- Requires Flutter SDK and Node.js environment

**Production:**
- Android/iOS for mobile app
- Web browsers for Flutter web
- Node.js environment (Containerized or PaaS) for backend
- Supabase/PostgreSQL for data persistence
