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
