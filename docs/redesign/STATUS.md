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

---

### Iteration 6 — Phase 4: Slice 4.3: Profile Screens
- **Goal:** Restyle `ProfileScreen`, `PublicProfileScreen`, and `EditProfileScreen` with Apple design direction (`FrostedAppBar`, borderless `AppCard` profile summaries, `StatsRow` with tabular figures, `PlayerCareerStatsCard` with monochrome surface cards, `BadgeGrid` with Apple squircle cards, zero emojis, 200% text scale survivability) without changing Supabase user queries or storage upload flows.
- **Files Modified / Created:**
  - `lib/features/profile/screens/profile_screen.dart` (Restyled with `FrostedAppBar`, responsive margin, Large Title/Title typography, clean avatar hero)
  - `lib/features/profile/screens/public_profile_screen.dart` (Restyled with `FrostedAppBar`, responsive margin, clean avatar hero)
  - `lib/features/profile/screens/edit_profile_screen.dart` (Restyled with `FrostedAppBar`, monochrome camera badge, responsive margin)
  - `lib/features/profile/widgets/stats_row.dart` (Restyled with tabular figures on stat values, hairline divider, and `AppCard` container)
  - `lib/features/profile/widgets/player_career_stats_card.dart` (Restyled with monochrome surface containers, tabular figures, warning-tinted MVP pill, and sports icons)
  - `lib/features/profile/widgets/badge_grid.dart` (Restyled with `radiusCardInner` 16dp surfaces, monochrome badge icons, and clean typography)
  - `lib/features/matches/widgets/match_card.dart` (Added ValueKey `cricket_batting_indicator` to cricket batting icon)
  - `test/matches/google_cricket_match_card_test.dart` (Updated batting indicator assertions to use `find.byKey(ValueKey('cricket_batting_indicator'))`)
  - `test/profile/profile_screens_test.dart` (New: widget tests for ProfileScreen details/stats/chips, 200% text scale survivability, and EditProfileScreen pre-filled inputs)
  - `docs/redesign/PARITY.md` (Updated `/profile`, `/profile/edit`, and `/leaderboard/player/:id` status to Restyled)
- **Verification:**
  - `flutter test`: 157/157 tests passing (100% green, including 3 new profile screen widget tests and 9 existing profile/stats tests).
  - `flutter analyze`: 77 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.4: Teams Screens (`teams_list_screen.dart`, `create_team_screen.dart`, `recruitment_screen.dart`, `team_detail_screen.dart`).

---

### Iteration 7 — Phase 4: Slice 4.4: Teams Screens
- **Goal:** Restyle `TeamsListScreen`, `CreateTeamScreen`, `RecruitmentScreen`, and `TeamDetailScreen` with Apple design aesthetic (`FrostedAppBar`, squircle team avatars `radius 12`, borderless `AppCard` team items, tabular figures on W-L records, destructive confirmation via `AppDialog.showConfirmation`, zero emojis) while preserving 100% of team state queries, captain permissions, and recruitment actions.
- **Files Modified / Created:**
  - `lib/features/teams/screens/teams_list_screen.dart` (Restyled with `FrostedAppBar`, responsive margin, cleaned unused imports)
  - `lib/features/teams/widgets/team_card.dart` (Restyled with squircle team avatar `isTeam: true`, tabular figures for `${team.wins}W - ${team.losses}L`, clean typography)
  - `lib/features/teams/screens/create_team_screen.dart` (Restyled with `FrostedAppBar`, cleaned unused `image_utils` import, responsive margin)
  - `lib/features/teams/screens/recruitment_screen.dart` (Restyled with `FrostedAppBar` and clean `EmptyState`)
  - `lib/features/teams/screens/team_detail_screen.dart` (Restyled with `FrostedAppBar`, squircle logo `isTeam: true`, responsive padding, and `AppDialog.showConfirmation` with `isDestructive: true`)
  - `lib/features/teams/widgets/member_tile.dart` (Restyled with warning-tinted captain pill and loss-tinted remove button)
  - `test/teams/teams_screens_test.dart` (New: widget tests for teams list rendering, squircle avatars, 200% text scale survivability, create form, recruitment empty state, and team detail)
  - `docs/redesign/PARITY.md` (Updated `/teams`, `/teams/create`, `/teams/recruitment`, and `/teams/:id` status to Restyled)
- **Verification:**
  - `flutter test`: 162/162 tests passing (100% green, including 5 new team widget tests).
  - `flutter analyze`: 75 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.5: Matches & Challenges Screens (`matches_list_screen.dart`, `match_detail_screen.dart`, `manage_squad_screen.dart`).

---

### Iteration 8 — Phase 4: Slice 4.5: Matches & Challenges Screens
- **Goal:** Restyle `MatchesListScreen`, `MatchDetailScreen`, and `ManageSquadScreen` with Apple design aesthetic (`FrostedAppBar`, `AppSegmented<String>` 3-way view toggle for Upcoming/Live/Completed, clean surface cards, prominent live score banner, soft `winContainer` winner card with `Icons.emoji_events_rounded` preserved for parity, `AppDialog.showConfirmation` with `isDestructive: true` for deleting match, pinned bottom action in manage squad, 200% text scale survivability) with zero breaking changes to match streaming or scoring navigation.
- **Files Modified / Created:**
  - `lib/features/matches/screens/matches_list_screen.dart` (Restyled with `FrostedAppBar`, `AppSegmented<String>` view toggle, responsive margin, and clean list spacing)
  - `lib/features/matches/screens/match_detail_screen.dart` (Restyled with `FrostedAppBar`, responsive margin, soft `winContainer` winner banner, and `AppDialog.showConfirmation` for match deletion)
  - `lib/features/matches/screens/manage_squad_screen.dart` (Restyled with `FrostedAppBar`, surface cards for player check tiles, responsive margin, and pinned `AppButton` bottom bar)
  - `test/matches/matches_screens_test.dart` (New: widget tests for MatchesListScreen segmented toggle, upcoming match card display, and 200% text scale survivability)
  - `docs/redesign/PARITY.md` (Updated `/matches`, `/matches/:id`, and `/matches/:id/squad/:teamId/:side` status to Restyled)
- **Verification:**
  - `flutter test`: 164/164 tests passing (100% green, including 2 new matches screen tests and 22 existing match/scorecard tests).
  - `flutter analyze`: 75 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.6: Match Creation & Scorer Setup (`create_match_screen.dart`, `sport_setup_widget.dart`).

---

### Iteration 9 — Phase 4: Slice 4.6: Match Creation & Scorer Setup
- **Goal:** Restyle `CreateMatchScreen` and `SportSetupWidget` with Apple design aesthetic (`FrostedAppBar`, `AppChip` sport/format pickers, `AppBreakpoints.maxReadingWidth` constraint, borderless `AppCard` pre-match configuration, Apple-style singles/doubles player selectors, `AppSwitch` football overtime toggles, sheet drag handles, `radiusSheetTop` 28dp, and 200% text scale survivability) without touching Supabase insert mutations, match scheduling data, or toss/lineup configuration models.
- **Files Modified / Created:**
  - `lib/core/theme/app_colors.dart` (Added `colors` alias to `BuildContext.appColors`)
  - `lib/core/theme/app_spacing.dart` (Added backward-compatible aliases: `radiusSheetTop`, `radiusFull`, `sheetPadding`)
  - `lib/features/matches/screens/create_match_screen.dart` (Restyled with `FrostedAppBar`, max reading width constraint, responsive padding, Apple input decorations, squad management sheet with drag handle, and clean pill buttons)
  - `lib/features/scoring/presentation/widgets/sport_setup_widget.dart` (Restyled with borderless surface card, Apple player selector tiles, doubles pair cards with win/loss status pills, AppSwitch toggles for football, and squad picker modal sheets)
  - `test/matches/matches_screens_test.dart` (Added widget tests for CreateMatchScreen dark mode rendering, FrostedAppBar, sport chips, and 200% text scale survivability)
  - `docs/redesign/PARITY.md` (Updated `/matches/create` status to Restyled)
- **Verification:**
  - `flutter test`: 166/166 tests passing (100% green, including badminton match flow and create match widget tests).
  - `flutter analyze`: 78 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.7: Live Scorer (`scorecard_edit_screen.dart`, `scorer_action_grid.dart`, `live_score_header.dart`, `action_dialogs.dart`).

---

### Iteration 10 — Phase 4: Slice 4.7: Live Scorer
- **Goal:** Restyle live scorer shell (`ScorecardEditScreen`), action key grid (`ScorerActionGrid`), live scoreboard (`LiveScoreHeader`), and scoring sheets/modals (`ActionDialogs`) with Apple design aesthetic (large touch targets >= 48dp, scorer keys 64-80dp, tabular figures on all scores/overs/run-rates, frosted bottom bar with pinned Undo and destructive Finish Match, modal bottom sheets with drag handles and radius 28dp top, `AppDialog.showConfirmation` with `isDestructive: true`, zero emojis) with 100% preservation of optimistic updates, offline queue, and Dart scoring engines.
- **Files Modified:**
  - `lib/features/scorecards/screens/scorecard_edit_screen.dart` (Restyled with `FrostedBar` bottom bar, `heightFactor: 1.0` centering, max reading width constraint, responsive padding, and `AppDialog.showConfirmation` destructive flow)
  - `lib/features/scoring/presentation/widgets/scorer_action_grid.dart` (Restyled scorer keys with >= 48dp / >= 64dp touch targets, `AppColors.loss.withValues(alpha: 0.16)` destructive keys, tabular figures, and subtle haptic feedback)
  - `lib/features/scoring/presentation/widgets/live_score_header.dart` (Replaced all emojis with semantic Cupertino/Material icons, tabular figures on all numbers, clean status badges, and borderless surface card)
  - `lib/features/scoring/presentation/widgets/action_dialogs.dart` (Restyled bottom sheets with top drag handle, `radiusSheetTop` 28dp, `AppTextField`, `AppChip`, and `AppDialog.showConfirmation` for destructive actions)
  - `test/scoring/scorer_screen_test.dart` (Cleaned test code and verified live scorer widget tests)
  - `test/matches/badminton_completed_scorecard_test.dart`, `test/matches/match_detail_winner_test.dart`, `test/navigation/shell_navigation_test.dart` (Cleaned warnings and dangling doc comments)
  - `docs/redesign/PARITY.md` (Updated `/matches/:id/score` status to Restyled)
- **Verification:**
  - `flutter test`: 166/166 tests passing (100% green, including 42 scoring tests).
  - `flutter analyze`: 70 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.8: Live Viewer & Match Analysis (`scorecard_view_screen.dart`, `match_analysis_screen.dart`, `professional_scorecard.dart`).

---

### Iteration 11 — Phase 4: Slice 4.8: Live Viewer & Match Analysis
- **Goal:** Restyle `ScorecardViewScreen`, `MatchAnalysisScreen`, and `ProfessionalScorecard` widgets (Cricket, Football, Badminton) with Apple design aesthetic (`FrostedAppBar`, `AppSegmented<int>` view toggle between Scorecard and Player Performance, `ConstrainedBox(maxWidth: AppBreakpoints.maxReadingWidth)`, `context.colors`, hairline 0.5px dividers, radius 24 cards, tabular figures for all scores and statistics, zero emojis, circular player avatars, squircle team badges) with zero breaking changes to realtime listeners, innings tabs, or analysis data streams.
- **Files Modified:**
  - `lib/features/scorecards/screens/scorecard_view_screen.dart` (Restyled with `FrostedAppBar`, responsive max reading width constraint, tabular figures on live scores, clean timeline tiles, and live status badge)
  - `lib/features/matches/screens/match_analysis_screen.dart` (Restyled with `FrostedAppBar`, `AppSegmented<int>` toggle, responsive max reading width constraint, `AppCard`, `AppAvatar`, tabular figures on player performance)
  - `lib/features/matches/widgets/professional_scorecard.dart` (Modernized Cricket, Football, and Badminton tabular scorecards with `context.colors`, 0.5px hairline dividers, radius 24 cards, and tabular figures)
  - `lib/features/matches/screens/match_detail_screen.dart` (Cleaned unused `dart:ui` import, unused variables)
  - `lib/features/matches/widgets/match_card.dart` (Cleaned unused `dart:ui` import)
  - `docs/redesign/PARITY.md` (Updated `/matches/:id/scorecard` and `/matches/:id/analysis` status to Restyled)
- **Verification:**
  - `flutter test`: 166/166 tests passing (100% green).
  - `flutter analyze`: 56 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.9: Leaderboards (`leaderboard_screen.dart`).

---

### Iteration 12 — Phase 4: Slice 4.9: Leaderboards
- **Goal:** Restyle `LeaderboardScreen` with Apple design aesthetic (`FrostedAppBar`, `AppSegmented<String>` sport selector [Cricket, Football, Badminton], `AppSegmented<String>` Cricket category selector [Batting, Bowling, Fielding], responsive max reading width constraint, borderless radius 24 surface cards, hairline 0.5px dividers, `FittedBox` scale-down safety for tabular numbers, tabular figures on all ranks and metrics, squircle team avatars with `isTeam: true`, 200% text scale survivability) without touching Supabase RPC queries, sorting models, or player/team routing.
- **Files Modified:**
  - `lib/features/leaderboard/screens/leaderboard_screen.dart` (Restyled with `FrostedAppBar`, `AppSegmented<String>` controls, borderless radius 24 tables with inset hairline dividers, tabular figures, squircle team avatars)
  - `lib/features/leaderboard/providers/leaderboard_providers.dart` (Cleaned unused `user_model.dart` import)
  - `lib/core/widgets/section_header.dart` (Wrapped title in `Expanded` to prevent flex overflow at 200% text scale, cleaned unused import)
  - `lib/core/widgets/app_segmented.dart` (Improved `Flexible` width measurement at high text scales by removing unnecessary `MainAxisSize.min`)
  - `test/leaderboard/leaderboard_screen_test.dart` (Added widget tests for dark mode rendering, squircle team avatars, and 200% text scale survivability)
  - `docs/redesign/PARITY.md` (Updated `/leaderboard` status to Restyled)
- **Verification:**
  - `flutter test`: 168/168 tests passing (100% green, including 6 leaderboard widget tests).
  - `flutter analyze`: 53 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 4: Slice 4.10: Tournaments (`tournament_list_screen.dart`, `tournament_detail_screen.dart`, `create_tournament_sheet.dart`, `generate_draw_dialog.dart`, knockout bracket view, standings table).

---

### Iteration 13 — Phase 4: Slice 4.10: Tournaments
- **Goal:** Restyle Tournaments screens and components (`TournamentListScreen`, `TournamentDetailScreen`, `CreateTournamentScreen`, `TournamentCard`, `BracketNodeCard`, `TournamentStandingsTable`, `CreateTournamentSheet`, `RegisterEntrySheet`, `GenerateDrawDialog`) with Apple design aesthetic (`FrostedAppBar`, responsive max reading width constraints, radius 24 borderless surface cards, tabular figures on all seeds/scores/standings, hairline 0.5px dividers, Apple status badges with container tints, sheets with top drag handle and `radiusSheetTop` 28dp, radius 24 dialogs, zero emojis) without touching tournament state machines, draw generation RPCs, or standings calculations.
- **Files Modified:**
  - `lib/features/tournaments/presentation/screens/tournament_list_screen.dart` (Restyled with `FrostedAppBar`, Stadium pill `FloatingActionButton.extended`, hairline dividers, responsive max reading width constraint, and `AppChip` filters)
  - `lib/features/tournaments/presentation/screens/tournament_detail_screen.dart` (Restyled with `FrostedAppBar`, Apple-styled `TabBar` with hairline indicator and tabular pending count badge, responsive reading width, cleaned string interpolation)
  - `lib/features/tournaments/screens/create_tournament_screen.dart` (Restyled with `FrostedAppBar` and max reading width constraint)
  - `lib/features/tournaments/presentation/widgets/tournament_card.dart` (Restyled with Apple pill badges with container tints, official pill tag, radius 24 `AppCard`)
  - `lib/features/tournaments/presentation/widgets/bracket_node_card.dart` (Restyled with borderless radius 14 node, hairline divider, tabular figures, and live pill tag)
  - `lib/features/tournaments/presentation/widgets/tournament_standings_table.dart` (Restyled with radius 24 `AppCard`, `fillSecondary` header row, hairline dividers, tabular figures, and clean win-tint qualification bar)
  - `lib/features/tournaments/presentation/widgets/create_tournament_sheet.dart` (Added drag handle, top radius 28dp, `surfaceElevated` background, and fixed deprecated `activeColor` to `activeTrackColor: colors.primaryFill, activeThumbColor: colors.onPrimary`)
  - `lib/features/tournaments/presentation/widgets/register_entry_sheet.dart` (Added drag handle, top radius 28dp, and `surfaceElevated` background)
  - `lib/features/tournaments/presentation/widgets/generate_draw_dialog.dart` (Restyled `AlertDialog` with radius 24 `AppSpacing.radiusDialog`, `surfaceElevated` background, and `AppButton` pill buttons)
  - `docs/redesign/PARITY.md` (Updated `/tournaments`, `/tournaments/create`, and `/tournaments/:id` status to Restyled)
- **Verification:**
  - `flutter test`: 168/168 tests passing (100% green, including 49 tournament unit/widget/routing tests).
  - `flutter analyze`: 51 issues (all pre-existing lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 5: Responsive, Accessibility & Motion Pass (Multi-breakpoint layouts, 200% text scale verification, reduce-motion auditing).

---

### Iteration 14 — Phase 5: Responsive, Accessibility & Motion Pass
- **Goal:** Audit and enhance responsive layouts, accessibility touch targets, semantics, and reduced motion across all core components and navigation structures.
- **Files Modified / Created:**
  - `lib/core/theme/app_motion.dart` (Added `AppMotion.duration(context, standard)` which collapses duration to `Duration.zero` when `disableAnimations` is true)
  - `lib/core/widgets/app_button.dart` (Wrapped with explicit `Semantics` [button trait, enabled state, label] and verified minHeight >= 48dp)
  - `lib/core/widgets/app_chip.dart` (Wrapped with `Semantics` [button trait, selected state, label], cleaned unused import, verified >= 48x48dp touch target)
  - `lib/core/widgets/app_card.dart` (Added `Semantics(button: true)` when `onTap != null`)
  - `lib/core/widgets/app_segmented.dart` (Wrapped options in `Semantics`, added `HapticFeedback.selectionClick()`, added `Material` transparency wrapper, animated position uses reduced-motion duration)
  - `lib/core/widgets/adaptive_scaffold.dart` (Added `Semantics` to `_BottomNavItem` and `_RailNavItem`)
  - `test/accessibility/responsive_accessibility_motion_test.dart` (New: automated test suite verifying compact 360x640 bottom bar vs tablet 768x1024 rail vs wide 1280x800 rail, 48x48 touch targets, semantics traits, 200% text scale survivability, and reduced motion duration collapse)
- **Verification:**
  - `flutter test`: 176/176 tests passing (100% green, including 8 new responsive/accessibility/motion tests).
  - `flutter analyze`: 50 issues (all pre-existing baseline lints, zero compilation errors, zero new warnings).
- **Next Slice:** Phase 6: Performance Pass & Phase 7: Final Audit, Deliverables & Report.

---

### Iteration 15 — Phase 6: Performance Pass & Phase 7: Final Audit & Deliverables
- **Goal:** Execute performance optimizations (RepaintBoundary on frosted bars, memCache capped on network avatars, const subtrees), sweep codebase for zero raw colors/emojis, run full test and contrast suites, and author final deliverables (`DESIGN_SPEC.md`, `REPORT.md`, `CONTRAST_REPORT.md`).
- **Files Modified / Created:**
  - `lib/core/widgets/app_avatar.dart` (Capped `memCacheWidth` and `memCacheHeight` to `(size.dimension * dpr).round()`, added Semantics on tap)
  - `lib/core/widgets/frosted_bar.dart` (Cleaned unused foundation import; verified RepaintBoundary wrapper around backdrop filters)
  - `lib/features/leaderboard/screens/leaderboard_screen.dart` (Replaced inline gold/silver/bronze colors with `colors.gold`, `colors.silver`, `colors.bronze`)
  - `lib/core/theme/app_colors.dart` (Added `gold`, `silver`, `bronze` medal getters to `AppColorsExtension`)
  - `lib/features/matches/screens/create_match_screen.dart` & `lib/features/scoring/presentation/widgets/sport_setup_widget.dart` (Replaced `✓` and `⚠` symbols with clean text)
  - `lib/main.dart` (Replaced `print` with `debugPrint` and removed emojis, fixing 6 lints)
  - `lib/features/matches/widgets/match_card.dart` (Cleaned cricket bat emoji in doc comment)
  - `docs/redesign/CONTRAST_REPORT.md` (New: comprehensive WCAG 2.1 contrast ratio verification table)
  - `docs/redesign/DESIGN_SPEC.md` (New: design system tokens, typography, radii, motion curves, component specs)
  - `docs/redesign/REPORT.md` (New: complete executive summary, architectural decisions, commit history, parity checklist)
- **Verification:**
  - `flutter test`: 176/176 tests passing (100% green).
  - `flutter analyze`: 43 issues (all pre-existing baseline lints; 0 errors, 0 new warnings).
  - Codebase sweep: 0 raw colors in features, 0 raw emojis anywhere in `lib/`.
- **Status:** **COMPLETE** — All exit criteria and non-negotiables met. Redesign ready for merge/review.
