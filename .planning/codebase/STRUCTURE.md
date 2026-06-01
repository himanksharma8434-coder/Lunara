# Project Structure

**Analysis Date:** 2026-03-25

## Root Directory Layout

- `lib/` - Flutter frontend source code.
- `lunara-backend/` - Node.js backend source code.
- `assets/` - Images, fonts, and animation files (e.g., Lottie).
- `test/` - Flutter unit and widget tests.
- `.planning/` - GSD project tracking and codebase maps.
- `.gsd/` - GSD templates and legacy configuration.

## Frontend Layout (`lib/`)

- `config/`: Application-wide configuration and constants.
  - `app_config.dart`: Supabase URLs, API keys, and feature flags.
- `features/`: Feature-sliced modules (e.g., `privacy`).
- `models/`: Plain Dart objects representing domain entities.
- `providers/`: State management (ChangeNotifiers).
- `screens/`: High-level UI pages/routes.
- `services/`: Low-level infrastructure and external API communication.
  - `database/`: Database-specific services (e.g., Hive).
- `theme/`: Global styles, colors, and theme definitions.
- `widgets/`: Reusable, atomic UI components.

## Backend Layout (`lunara-backend/src/`)

- `config/`: Environment configuration and DB connection.
- `controllers/`: Logic for handling API requests.
- `middleware/`: Auth guards and validation layers.
- `models/`: Sequelize model definitions.
- `routes/`: API endpoint definitions by resource.
- `services/`: Complex business logic extracted from controllers.

## Key Locations

- **Entry Points:**
  - Frontend: `lib/main.dart`
  - Backend: `lunara-backend/src/app.js`
- **Authentication:** `lib/providers/auth_provider.dart`
- **Local Storage:** `lib/services/database/hive_service.dart`
- **API Routes:** `lunara-backend/src/routes/*.js`

## Naming Conventions

- **Frontend:** Lowercase with underscores (snake_case) for files; PascalCase for classes.
- **Backend:** camelCase for files and methods; PascalCase for models/classes.
- **Models:** Typically suffixed with `_model.dart` or `Model.js`.
- **Controllers:** Suffixed with `Controller.js`.
- **Routes:** Suffixed with `Routes.js`.
