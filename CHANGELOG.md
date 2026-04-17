# Changelog

All notable changes to this project are documented in this file.

## [Unreleased] - 2026-04-18

### Added
- Added manual food search source switch with Open Food Facts support in addition to MY/SG database search.
- Added paginated manual search with infinite scroll loading.
- Added profile goal editing entry from profile screen via "Set My Own Goals".
- Added prefilled profile setup editing flow (reuse onboarding screen for profile updates).
- Added optional manual macro target mode and persisted macro/manual flags.
- Added dark theme support and persisted theme mode setting (System/Light/Dark).
- Added meal detail screen for editing logged meal portion sizes and recalculated nutrition.
- Added confidence percentage support for AI food suggestions and UI badges.
- Added robust Gemini response parsing and fallback suggestion handling.
- Added Open Food Facts service integration and web-safe HTTP fallback.
- Added Firebase Windows options support.
- Added multi-source food dataset assets and seeding utilities/scripts.
- Added Firestore rules and Firebase config files.

### Changed
- Refactored app router to use `AppRouter.create(authProvider)` with refresh listenable auth routing.
- Updated app startup flow with safer Firebase initialization retry and startup error screen.
- Moved food seeding to background startup task to avoid blocking app launch.
- Switched many hard-coded white surfaces to shared theme-aware surface colors.
- Updated `AppColors` to become dark-mode aware through computed getters and theme mode tracking.
- Improved profile recalculation flow with user prompt options:
  - Re-enter details first
  - Recalculate using current details
- Updated dashboard macro targets to derive defaults from calories when custom macros are absent.
- Improved chatbot error messages for rate limits and API key/config issues.
- Improved Firestore service error handling/logging and search scoring behavior.

### Fixed
- Fixed "Recalculate target does nothing" UX by introducing explicit recalc flow and success feedback.
- Fixed inability to edit activity level/goal after onboarding by enabling setup prefill edit mode.
- Fixed dark mode readability issues on selected cards and shared text/surface colors.
- Fixed OFF mapping/type issues (`num` to `double` conversions) and helper restoration.
- Fixed auth provider initial session state hydration from current user.
- Fixed meal save/update edge cases with safer id handling and submit guarding.
- Fixed several UI input ergonomics (text input actions, submit behavior, loading guards).

### Removed
- Removed the citizen science project attachment card from meal detail flow.
- Removed dependency on old local `myfcd_foods.json` asset in favor of expanded datasets.

### Dependencies
- Added/updated dependencies including:
  - `openfoodfacts`
  - `http`
  - `url_launcher`
  - Firebase/DataConnect related packages
- Regenerated platform plugin registrants where required.

### Notes
- Android local SDK path issue (`local.properties` / Android SDK setup) is environment-specific and not a code regression.
- Open Food Facts availability may still vary by network/rate-limit/temporary upstream outages.
