# Coding Conventions

**Analysis Date:** 2026-03-25

## General Principles

- **Privacy First:** Sensitive user data must be encrypted before local storage or cloud sync.
- **Fail Fast:** Validate inputs (using `zod` on backend) and handle errors explicitly.
- **Async Safety:** Use `runZonedGuarded` or `try-catch` with logging for all asynchronous operations.

## Flutter Conventions

**Naming:**
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private variables/methods: `_underscorePrefix`
- Providers: Suffixed with `Provider` (e.g., `AuthProvider`)
- Services: Suffixed with `Service` (e.g., `HiveService`)

**State Management:**
- Use `ChangeNotifier` and `notifyListeners()`.
- Consumers should use `context.watch<T>()` or `context.read<T>()`.
- Avoid logic in the widget tree; defer to Providers.

**Error Handling:**
- Wrap `main` in `runZonedGuarded`.
- Use `LoggerService.instance.error` for tracking.
- Friendly error messages returned as `String?` from async methods (e.g., `login`).

**Linting:**
- Follows `package:flutter_lints/flutter.yaml`.
- Specific overrides in `analysis_options.yaml` (e.g., ignoring `deprecated_member_use`).

## Backend Conventions

**Naming:**
- Files: `camelCase.js` (e.g., `authRoutes.js`)
- Methods: `camelCase`
- Models: `PascalCase` (Sequelize models)

**Structure:**
- CommonJS (`require`) module system.
- Controllers handle HTTP logic; Services handle business logic.
- Models define the schema and relationships.

**Validation:**
- Use `zod` for request body and parameter validation.
- All database interactions should be managed through Sequelize models.

## Documentation

- **Comments:** Use `///` for documentation comments on public methods.
- **Logging:** Always specify a `tag` in `LoggerService` for easier filtering.
