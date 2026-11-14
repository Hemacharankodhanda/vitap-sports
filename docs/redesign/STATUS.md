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

---

### Iteration 2 — Phase 2: Design-System Widgets Restyling & New Controls
- **Goal:** Restyle all existing core widgets to the Apple design system spec (pill buttons, borderless surface cards with radius 24, stacked input fields with radius 14, pill chips, clean 24dp status badges with live pulsing dot, circular/squircle avatars, tabular stats, clean empty/error states without emojis, radius 24 dialogs, radius 28 sheets, floating snack capsules) and introduce `AppSegmented`, `AppSwitch`, `FrostedBar`, and `AdaptiveScaffold`.
- **Files Modified / Created:**
  - `lib/core/widgets/app_button.dart` (Restyled to Apple StadiumBorder pill, press animation with Cubic curve, primaryFill / onPrimary, fillSecondary, destructive tint, HapticFeedback)
  - `lib/core/widgets/app_card.dart` (Radius 24, surface fill, borderless by default, elevation 0, hairline inset dividers for grouped cards)
  - `lib/core/widgets/app_text_field.dart` (Radius 14, height 52, surface fill, borderless at rest, 1.5px focus border, 1px loss border, stacked Callout w500 label, Footnote helper/error)
  - `lib/core/widgets/app_chip.dart` (Pill shape, unselected fillSecondary + textPrimary, selected primaryFill + onPrimary, container-tinted ResultChip with tabular figures)
  - `lib/core/widgets/status_badge.dart` (Height 24 pill, Caption w600, liveContainer with 6px pulsing dot, fillSecondary upcoming, surface completed, warningContainer paused)
  - `lib/core/widgets/app_avatar.dart` (Circle for players, radius 12 squircle for teams, fillSecondary neutral initials fallback, 150ms fade-in)
  - `lib/core/widgets/stat_tile.dart` (Tabular figures on all numbers, large display value with Caption label below, single card grid with hairline dividers, NaN to '-')
  - `lib/core/widgets/empty_state.dart` (Centered column without emojis, outline icon in textSecondary, Headline title, Body subtitle, pill action)
  - `lib/core/widgets/error_view.dart` (Centered blocking error & inline lossContainer banner without emojis, pill retry button)
  - `lib/core/widgets/app_dialog.dart` (Radius 24, surfaceElevated background, 40% scrim, stacked pill buttons, destructive confirmation support)
  - `lib/core/widgets/app_bottom_sheet.dart` (Top radius 28, surfaceElevated background, 36x5 drag handle, 40% scrim, pinned bottom action)
  - `lib/core/widgets/app_snack.dart` (Floating capsule pill shape, soft shadow, primaryFill background with onPrimary text)
  - `lib/core/widgets/app_segmented.dart` (New: pill track in fillSecondary, animated sliding thumb with 250ms curve, 2 to 4 options)
  - `lib/core/widgets/app_switch.dart` (New: custom Apple switch with primaryFill active track and fillSecondary inactive track; AppSwitchRow for settings)
  - `lib/core/widgets/frosted_bar.dart` (New: 80% opacity background with backdrop blur sigma 20, hairline dividers, wrapped in RepaintBoundary)
  - `lib/core/widgets/adaptive_scaffold.dart` (New: responsive navigation scaffold: compact bottom frosted bar with 24px icons + labels always visible; medium/expanded navigation rail on left)
  - `test/core/components_spec_test.dart` (Expanded with 6 new tests covering AppSegmented, AppSwitch, FrostedBar, AdaptiveScaffold, AppDialog, AppBottomSheet, and AppSnack)
- **Verification:**
  - `flutter test`: 147/147 tests passing (100% green).
  - `flutter analyze`: 77 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 3: Navigation Shell & Appearance Settings (`ShellScreen` adaptive navigation, `ThemeSettingsScreen` with `AppSegmented` System/Light/Dark mode switch).

---

### Iteration 3 — Phase 3: Navigation Shell & Appearance Settings
- **Goal:** Replace `ShellScreen` bottom bar with `AdaptiveScaffold` (compact frosted bottom bar with always-visible labels and no indicator pill; medium/expanded navigation rail), restyle `ThemeSettingsScreen` with `AppSegmented` control and Apple grouped cards, and add automated navigation/settings widget tests.
- **Files Modified / Created:**
  - `lib/core/router/shell_screen.dart` (Updated to use `AdaptiveScaffold` with 5 persistent destinations: Home, Teams, Matches, Board, Profile)
  - `lib/features/settings/screens/theme_settings_screen.dart` (Restyled with `FrostedAppBar`, `AppSegmented<ThemeMode>` control, Apple grouped preview card, and circular accent color selectors)
  - `test/navigation/shell_navigation_test.dart` (New: widget tests verifying tab switching, adaptive navigation rail on wide screens, and theme mode switching)
- **Verification:**
  - `flutter test`: 151/151 tests passing (100% green, including 3 new shell navigation and theme settings tests).
  - `flutter analyze`: 77 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Screen-by-Screen Migration — Slice 4.1: Authentication Screens (`login_screen.dart`, `onboarding_screen.dart`).

---

### Iteration 4 — Phase 4: Slice 4.1: Authentication Screens
- **Goal:** Restyle `LoginScreen` and `OnboardingScreen` with Apple design direction (monochrome palette, soft rounded surfaces, Large Title typography, 200% text scale survivability, `FrostedAppBar`, `AppSegmented` for skill levels, zero emojis) without changing Supabase auth or profile mutation flows.
- **Files Modified / Created:**
  - `lib/features/auth/screens/login_screen.dart` (Restyled with large confident typography, clean surface logo card, scrollable constrained layout surviving 200% text scale, pill button, zero emojis)
  - `lib/features/auth/screens/onboarding_screen.dart` (Restyled with `FrostedAppBar`, stacked `AppTextField` inputs, pill chips for year/hostel, `AppSegmented<String>` for sport skill levels, and primary pill button)
  - `lib/core/widgets/app_chip.dart` (Removed unconstrained Center wrapper to prevent expansion inside Wrap)
  - `lib/core/widgets/app_segmented.dart` (Wrapped text in Flexible to prevent horizontal overflow on long segment labels)
  - `test/auth/auth_screens_test.dart` (New: widget tests for LoginScreen layout, 200% text scale test, and OnboardingScreen fields/chips/segmented selection)
  - `docs/redesign/PARITY.md` (Updated `/login`, `/onboarding`, and `/profile/theme` status to Restyled)
- **Verification:**
  - `flutter test`: 154/154 tests passing (100% green, including 3 new auth widget tests).
  - `flutter analyze`: 77 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.2: Feed / Home Screen (`feed_screen.dart`, `free_agents_screen.dart`).

---

### Iteration 5 — Phase 4: Slice 4.2: Feed / Home Screen
- **Goal:** Restyle `FeedScreen` and `FreeAgentsScreen` with Apple design direction (monochrome palette, soft rounded surfaces, `FrostedAppBar`, `SportFilterBar` with `AppChip` pills, live match section with pulsing dot badge, borderless Quick Action cards, `EmptyState` without emojis, bat emoji replaced with sports icon) while preserving exact live match streaming, challenges, and navigation behaviors.
- **Files Modified / Created:**
  - `lib/features/feed/screens/feed_screen.dart` (Restyled with `FrostedAppBar`, `SportFilterBar`, live matches section with live badge + MatchCards, clean Quick Action cards with borderless surface cards & radius 24, and Activity Feed `EmptyState` without emojis)
  - `lib/features/free_agents/screens/free_agents_screen.dart` (Restyled with `FrostedAppBar`, `AppChip` horizontal filter bar, hairline divider, and `EmptyState`)
  - `lib/core/widgets/sport_filter_bar.dart` (Restyled to use `AppChip` pill chips)
  - `lib/features/matches/widgets/match_card.dart` (Replaced bat emoji with `Icons.sports_cricket_rounded`)
  - `test/auth/auth_screens_test.dart` (Cleaned up unused import and doc comment)
  - `test/feed/feed_live_matches_test.dart` (Cleaned up library doc comment)
  - `docs/redesign/PARITY.md` (Updated `/home` and `/home/free-agents` status to Restyled)
- **Verification:**
  - `flutter test`: 154/154 tests passing (100% green, including feed live matches tests).
  - `flutter analyze`: 77 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.3: Profile Screens (`profile_screen.dart`, `edit_profile_screen.dart`, `public_profile_screen.dart`).
