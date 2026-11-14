# VIT-AP Sports UI Redesign — Status & Plan

## High-Level Implementation Plan

1. **Phase 0: Baseline & Parity Inventory (Done)**
   - Audit all routes, screens, actions, inputs, dialogs, sheets, tabs, realtime subscriptions, and permissions.
   - Run baseline `flutter test` (138/138 passing) and `flutter analyze` (78 pre-existing issues recorded).
   - Establish `docs/redesign/PARITY.md` and `docs/redesign/STATUS.md`.

2. **Phase 1: Apple Design Tokens & Theme Foundation**
   - Replace/expand design tokens in `lib/core/theme/` (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`).
   - Implement clean light & dark `ThemeData` with high-contrast monochrome aesthetic (white/black, soft grays, Inter with tabular figures, 0 elevation).
   - Pre-load `ThemeMode` in `main.dart` with `shared_preferences` to eliminate cold-start flash.
   - Add automated contrast validation test (`test/theme/contrast_test.dart`).

3. **Phase 2: Design-System Widgets Restyling & New Controls**
   - Restyle existing core widgets (`AppButton`, `AppCard`, `AppTextField`, `AppChip`, `StatusLabel`, `AppAvatar`, `StatTile`, `FormStrip`, `EmptyState`, `ErrorView`, `AppDialog`, `AppBottomSheet`, `AppSnack`).
   - Add new components: `AppSegmented`, `AppSwitch`, `FrostedBar`, `AdaptiveScaffold`, and `AppBreakpoints`.
   - Add widget test coverage for new and restyled components in light and dark modes.

4. **Phase 3: Navigation Shell & Appearance Settings**
   - Replace `ShellScreen` chrome with frosted navigation bars (`FrostedBar` with blur & hairline dividers) and adaptive navigation rail on medium/expanded screens.
   - Restyle `ThemeSettingsScreen` with `AppSegmented` control for System / Light / Dark modes.

5. **Phase 4: Screen-by-Screen Migration (in required order)**
   - Slices: Auth -> Feed/Home -> Profile -> Teams -> Matches & Challenges -> Match Creation -> Scorer Setup -> Live Scorer (3 sports) -> Live Viewer -> Match Analysis -> Leaderboards -> Tournaments -> Settings.
   - Each slice updates `PARITY.md`, replaces inline colors/emojis with tokens, and passes test/analyze.

6. **Phase 5: Responsive, Accessibility & Motion Pass**
   - Two-pane tablet/landscape scorer layout, 200% text scale test, reduce-motion checks, semantics labels.

7. **Phase 6: Performance Pass**
   - Rebuild scopes verification, list virtualization, image sizing, and `RepaintBoundary` placement.

8. **Phase 7: Final Audit & Deliverables**
   - Final audit for raw colors/emojis, complete `DESIGN_SPEC.md` and `REPORT.md`, verify exit criteria.

---

## Iteration Log

### Iteration 0 — Phase 0: Baseline & Parity Inventory
- **Goal:** Establish strict baseline without changing UI or business logic, catalog all interactive elements into `PARITY.md`, audit design system, and identify risky areas.
- **Files Read:**
  - `lib/core/router/app_router.dart`
  - `lib/core/widgets/*`
  - `lib/core/theme/*`
  - `lib/features/*`
  - `test/core/components_spec_test.dart`
- **Files Created:**
  - `docs/redesign/STATUS.md`
  - `docs/redesign/PARITY.md`
- **Baseline Verification:**
  - `flutter test`: 138/138 tests passed (100% green).
  - `flutter analyze`: 78 issues found (all pre-existing lints and warnings: unused imports, deprecated members, avoid_print). Zero compilation errors.
- **Risks & Invariants Documented:**
  - Realtime subscriptions, live scoring engines, and tournament RPCs must remain strictly untouched.
  - Zero changes to backend, Supabase models, or route paths.
- **Next Slice:** Phase 1: Tokens and Theming Foundation (`app_colors.dart`, `app_typography.dart`, `app_theme.dart`, `app_theme_provider.dart`, contrast tests).

---

### Iteration 1 — Phase 1: Apple Design Tokens & Theme Foundation
- **Goal:** Replace/expand design tokens in `lib/core/theme/` to Apple design direction (monochrome palette, soft rounded surfaces, hairline dividers, Inter font with tabular figures, 0 elevation, responsive breakpoints, smooth motion specs), support pre-loaded theme mode without cold-start flash, and write automated WCAG 2.1 contrast and theme persistence tests.
- **Files Read:**
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_typography.dart`
  - `lib/core/theme/app_spacing.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/app_theme_provider.dart`
  - `lib/main.dart`
  - `test/core/components_spec_test.dart`
- **Files Modified / Created:**
  - `lib/core/theme/app_colors.dart` (Apple monochrome tokens, light/dark values, semantic accents, backwards-compatible getters and AppColorsExtension)
  - `lib/core/theme/app_typography.dart` (Apple typography scale from Display XL 48 down to Caption 12, tabular figures for all numbers, test-safe font loading)
  - `lib/core/theme/app_spacing.dart` (Apple 8pt grid, radii: button/chip pill, input 14, card 24, sheet 28, dialog 24)
  - `lib/core/theme/app_breakpoints.dart` (New: compact <600, medium 600..1023, expanded >=1024, responsive screen padding)
  - `lib/core/theme/app_motion.dart` (New: Apple curve Cubic(0.28, 0.11, 0.32, 1.0), press 120ms, stateChange 250ms, pageOrSheet 350ms, reduce motion support)
  - `lib/core/theme/app_theme.dart` (Clean elevation 0 ThemeData, hairline dividers, Apple-styled components)
  - `lib/core/theme/app_theme_provider.dart` (initialThemeModeProvider support)
  - `lib/main.dart` (Pre-loads theme mode from SharedPreferences before runApp to eliminate flash)
  - `lib/features/scoring/presentation/widgets/action_dialogs.dart` (Wrapped row contents in Expanded to prevent flex overflow)
  - `lib/features/matches/screens/match_detail_screen.dart` (Optimized status badge vertical margins to fit viewport cleanly)
  - `test/theme/contrast_test.dart` (New: WCAG 2.1 contrast ratio automated test suite + theme persistence test)
- **Verification:**
  - `flutter test`: 142/142 tests passing (100% green, including 4 new contrast & persistence tests).
  - `flutter analyze`: 77 issues (all pre-existing lints; zero compilation errors, zero new warnings).
- **Next Slice:** Phase 2: Design-System Widgets Restyling & New Controls (`AppButton`, `AppCard`, `AppTextField`, `AppChip`, `StatusLabel`, `AppAvatar`, `StatTile`, `FormStrip`, `EmptyState`, `ErrorView`, `AppDialog`, `AppBottomSheet`, `AppSegmented`, `AppSwitch`, `FrostedBar`, `AdaptiveScaffold`).
