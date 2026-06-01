# Technical Concerns

**Analysis Date:** 2026-03-25

## Technical Debt

**1. High Component Coupling:**
- `CycleProvider` in `lib/providers/cycle_provider.dart` is approximately 1,400 lines long. It handles UI state, business logic, health data sync, and persistence.
- **Risk:** High maintenance overhead and difficulty in testing isolated components.
- **Recommendation:** Extract health sync and cycle calculations into dedicated service classes.

**2. Database Migration Strategy (Backend):**
- `lunara-backend/src/app.js` use `sequelize.sync({ alter: true })`.
- **Risk:** Unpredictable schema changes in production and potential data loss.
- **Recommendation:** Switch to a formal migration-based workflow using `sequelize-cli`.

**3. Manual Date Math:**
- Extensive use of `DateTime.difference` and `inDays` for cycle predictions throughout the codebase.
- **Risk:** Potential edge cases around timezones and daylight savings time.
- **Recommendation:** Standardize on UTC for all internal calculations and use a dedicated library if complexity increases.

## Potential Fragility

**1. Cloud/Local State Sync:**
- Complex logic in `_fetchCloudHistory` for merging local and remote data.
- **Risk:** Conflict resolution is currently basic (mostly "last one wins" or "remote wins").
- **Recommendation:** Implement a more robust versioning or timestamp-based sync protocol.

**2. Hardcoded Default Values:**
- Several default metrics (weight, height, age) are hardcoded in providers.
- **Risk:** May lead to incorrect initial predictions if not immediately updated by the user.

## Security Considerations

**1. Input Validation:**
- While `zod` is used in the backend, the consistency of its application across all routes needs verification.
- **Fragile areas:** Ensure all data synced from the frontend is strictly validated before DB insertion.

**2. Secret Management:**
- No `.env` files were detected in the committed code, but it's critical to ensure placeholders don't accidentally contain real keys.
- **Risk:** Accidental commit of Supabase or Gemini API keys.
- **Recommendation:** Use a secret manager or strictly enforced `.env.template` patterns.

## Performance Concerns

**1. UI Thread Blocking:**
- Complex cycle history processing and prediction logic in `CycleProvider` may block the UI thread if the history grows large.
- **Recommendation:** Use `Isolate` for heavy computational tasks like multi-cycle analysis.

**2. Widget Tree Depth:**
- Large screens often use many nested widgets and multiple `context.watch<T>()` calls.
- **Recommendation:** Use `Selector` or split widgets into smaller pieces to minimize rebuilds.
