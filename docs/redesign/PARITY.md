# VIT-AP Sports — Parity Contract & Screen Inventory

This document serves as the absolute contract for the presentation-layer redesign. Every existing route, screen, user action, input, dialog, sheet, tab, realtime subscription, and permission check must be preserved with exact behavioral parity.

**Status Legend:**
- `Unchanged`: Not yet touched (Phase 0 baseline).
- `Restyled`: Visual appearance modernized per Apple design tokens without structural shift.
- `Re-laid out`: Responsive layout adapted for multiple breakpoints (compact/medium/expanded).

---

## 1. Route & Screen Parity Table

| Route / Path | Screen & Location | Interactive Elements (Actions, Inputs, Gestures) | Dialogs / Sheets / Popups | Realtime & Permissions | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `/login` | `LoginScreen`<br>`lib/features/auth/screens/login_screen.dart` | • Email input<br>• Password input<br>• "Sign In" button<br>• "Sign In with Google" OAuth button<br>• Toggle Sign In / Sign Up mode<br>• "Forgot Password" tap | • Password reset email snackbar / dialog | • Supabase OAuth flow<br>• Auto-redirect if session exists | Restyled |
| `/onboarding` | `OnboardingScreen`<br>`lib/features/auth/screens/onboarding_screen.dart` | • Full name input<br>• Registration/Roll number input<br>• Sports interest chips toggle<br>• Hostel/gender dropdowns<br>• "Complete Profile" CTA button | • Validation snackbars | • Profile creation Supabase mutation | Restyled |
| `/home` (Tab 0) | `FeedScreen`<br>`lib/features/feed/screens/feed_screen.dart` | • Sport filter bar chips<br>• Live match cards tap (`-> /matches/:id`)<br>• Quick actions (Create Match, Find Free Agents, Tournaments)<br>• Challenge banner action (Accept/Decline)<br>• Pull-to-refresh gesture | • Challenge response confirm sheet | • Realtime scorecard subscription (`scorecard-updates`) | Restyled |
| `/home/free-agents` | `FreeAgentsScreen`<br>`lib/features/free_agents/screens/free_agents_screen.dart` | • Sport filter chips<br>• Search input<br>• "List Myself as Free Agent" button<br>• Contact / Invite player card taps | • Free agent registration sheet | • Database queries for active agents | Restyled |
| `/teams` (Tab 1) | `TeamsListScreen`<br>`lib/features/teams/screens/teams_list_screen.dart` | • Sport filter bar<br>• Team search text field<br>• "Create Team" button (`-> /teams/create`)<br>• "Recruitment" button (`-> /teams/recruitment`)<br>• Team card tap (`-> /teams/:id`) | • None | • Realtime teams list | Restyled |
| `/teams/create` | `CreateTeamScreen`<br>`lib/features/teams/screens/create_team_screen.dart` | • Team name input<br>• Sport dropdown selector<br>• Logo picker tap (Camera / Gallery)<br>• Team bio input<br>• "Open for Recruitment" switch<br>• "Create Team" button | • Image source picker sheet (Camera / Gallery) | • Camera & Photo library permissions | Restyled |
| `/teams/recruitment` | `RecruitmentScreen`<br>`lib/features/teams/screens/recruitment_screen.dart` | • Sport filter chips<br>• Role / position filters<br>• "Apply to Team" tap<br>• Captain: Accept / Decline applicant taps | • Application confirmation dialog | • Applicant status mutations | Restyled |
| `/teams/:id` | `TeamDetailScreen`<br>`lib/features/teams/screens/team_detail_screen.dart` | • Tabs: Roster, Matches, Stats<br>• Captain: "Edit Team" button<br>• Captain: "Invite Player" button<br>• "Leave Team" button<br>• "Disband Team" button (captain only) | • Confirm Leave dialog<br>• Confirm Disband dialog<br>• Invite player modal sheet | • Captain role permission checks | Restyled |
| `/matches` (Tab 2) | `MatchesListScreen`<br>`lib/features/matches/screens/matches_list_screen.dart` | • Tabs: Live, Upcoming, Completed<br>• Sport filter chips<br>• "Create Match" button (`-> /matches/create`)<br>• Match card tap (`-> /matches/:id`)<br>• Pull-to-refresh | • None | • Realtime match status updates | Restyled |
| `/matches/create` | `CreateMatchScreen`<br>`lib/features/matches/screens/create_match_screen.dart` | • Sport selector (Cricket, Football, Badminton)<br>• Team 1 selector & Team 2 selector<br>• Date and time pickers<br>• Venue input field<br>• Sport-specific rules (overs, sets, halves)<br>• "Create Match" CTA | • Date picker dialog<br>• Time picker dialog | • Match insert mutation | Restyled |
| `/matches/:id` | `MatchDetailScreen`<br>`lib/features/matches/screens/match_detail_screen.dart` | • Tabs: Summary, Scorecard, Squads, Info<br>• "Start Scoring" / "Live Scorer" button (`-> /matches/:id/scorecard/edit`)<br>• "View Scorecard" button (`-> /matches/:id/scorecard`)<br>• "Manage Squad" button (`-> /matches/:id/squad/:teamId/:side`)<br>• Challenge actions: Accept / Decline buttons | • Cancel match dialog<br>• Forfeit confirmation dialog | • Realtime scorecard updates channel<br>• Scorer authorization check | Restyled |
| `/matches/:id/squad/:teamId/:side` | `ManageSquadScreen`<br>`lib/features/matches/screens/manage_squad_screen.dart` | • Player selection checkboxes<br>• Playing XI toggle / Bench toggle<br>• Captain designation tap<br>• Wicket-keeper / Goalkeeper designation tap<br>• "Save Squad" CTA | • Validation warning snackbar | • Team roster access | Restyled |
| `/matches/:id/scorecard`<br>`/matches/:id/analysis` | `MatchAnalysisScreen`<br>`lib/features/matches/screens/match_analysis_screen.dart` | • Tabs: Overview, Full Scorecard, Charts, Events<br>• Innings toggle chips (Innings 1 / Innings 2)<br>• Share scorecard button<br>• Horizontal scroll for tables | • Share options modal | • Live match summary query | Unchanged |
| `/matches/:id/scorecard/edit` | `ScorecardEditScreen`<br>`lib/features/scorecards/screens/scorecard_edit_screen.dart` | • **Keypad:** Runs (0, 1, 2, 3, 4, 6)<br>• Extras (Wide, No-Ball, Bye, Leg-Bye, Penalty)<br>• Wicket button tap<br>• Striker / Non-striker switcher tap<br>• Bowler selector tap<br>• Undo ball action button (haptic tap)<br>• "End Match" / "End Innings" buttons | • Wicket detail dialog (dismissal type, fielder, new batter)<br>• Over complete summary sheet<br>• End of Innings confirmation dialog<br>• Match conclusion dialog | • Realtime live broadcast channel<br>• Wake-lock enabled (screen kept awake)<br>• Haptic feedback on tap | Unchanged |
| `/leaderboard` (Tab 3) | `LeaderboardScreen`<br>`lib/features/leaderboard/screens/leaderboard_screen.dart` | • Tabs: Teams, Players, Tournaments<br>• Sport filter bar<br>• Timeframe selector (All-Time, Semester, Monthly)<br>• Player row tap (`-> /leaderboard/player/:id`)<br>• Team row tap (`-> /teams/:id`)<br>• Tournaments tab CTA (`-> /tournaments`) | • Filter options modal | • Leaderboard aggregation RPCs | Unchanged |
| `/leaderboard/player/:id` | `PublicProfileScreen`<br>`lib/features/profile/screens/public_profile_screen.dart` | • Career stats card (`PlayerCareerStatsCard`)<br>• Match history list tap (`-> /matches/:id`)<br>• Sports badges view | • None | • Public profile data query | Restyled |
| `/tournaments` | `TournamentsListScreen`<br>`lib/features/tournaments/presentation/screens/tournament_list_screen.dart` | • Tabs: Ongoing, Upcoming, Completed<br>• Sport filter chips<br>• Search input<br>• "Create Tournament" button (`-> /tournaments/create`)<br>• Tournament card tap (`-> /tournaments/:id`) | • None | • Tournaments query & filters | Unchanged |
| `/tournaments/create` | `CreateTournamentScreen`<br>`lib/features/tournaments/screens/create_tournament_screen.dart` | • Tournament name input<br>• Sport dropdown<br>• Format selector (Knockout, Round Robin, Group Stage)<br>• Max teams input<br>• Start & end date pickers<br>• Venue input<br>• Rules text field<br>• "Create Tournament" button | • Date picker dialogs | • Tournament insert RPC | Unchanged |
| `/tournaments/:id` | `TournamentDetailScreen`<br>`lib/features/tournaments/presentation/screens/tournament_detail_screen.dart` | • Tabs: Overview, Bracket, Standings, Matches, Teams, Honours, Organiser<br>• Bracket: interactive node taps, horizontal scroll<br>• Standings: sortable table columns<br>• Organiser: "Generate Draws" button, "Record Result" tap, "Publish Honours" tap | • `RegisterEntrySheet` (register team)<br>• `GenerateDrawDialog` (seedings & draw configuration)<br>• Decline entry modal<br>• Honours edit sheet | • Tournament state machine RPCs<br>• Organiser role permission checks | Unchanged |
| `/profile` (Tab 4) | `ProfileScreen`<br>`lib/features/profile/screens/profile_screen.dart` | • User avatar and bio display<br>• Career stats summary<br>• "Edit Profile" button (`-> /profile/edit`)<br>• "Appearance" / "Theme Settings" button (`-> /profile/theme`)<br>• "Logout" button | • Logout confirmation dialog | • Auth state listener | Restyled |
| `/profile/edit` | `EditProfileScreen`<br>`lib/features/profile/screens/edit_profile_screen.dart` | • Name input field<br>• Bio input field<br>• Avatar tap to change photo<br>• Preferred sports toggle chips<br>• "Save Profile" CTA | • Image source selector sheet | • Camera & gallery permissions<br>• Supabase storage upload | Restyled |
| `/profile/theme` | `ThemeSettingsScreen`<br>`lib/features/settings/screens/theme_settings_screen.dart` | • Theme mode selector (System, Light, Dark)<br>• Instant theme preview | • None | • `SharedPreferences` persistence<br>• `themeProvider` | Restyled |

---

## 2. Design System Inventory & Audit

### Existing Core Widgets (`lib/core/widgets/`)
1. `AppButton` (`app_button.dart`): Primary, secondary, outlined, text, destructive, destructiveInline. Large & compact.
2. `AppCard` & `AppGroupedCard` (`app_card.dart`): Card container and grouped card with dividers.
3. `AppTextField` (`app_text_field.dart`): Standard stacked label textfield, search variant, prefix/suffix icons.
4. `AppChip` & `ResultChip` (`app_chip.dart`): Pill-shaped filter chips, W/L/D match result indicators.
5. `StatusLabel` (`status_badge.dart`): Live, upcoming, completed (FT), paused indicators.
6. `AppAvatar` (`app_avatar.dart`): Player circular avatar, team rounded square avatar.
7. `StatTile` & `StatGridCard` (`stat_tile.dart`): Tabular numeric metrics display.
8. `FormStrip` (`form_strip.dart`): Recent 5 match form outcome chips.
9. `EmptyState` (`empty_state.dart`): Empty placeholder view.
10. `ErrorView` & `InlineErrorBanner` (`error_view.dart`): Failure states.
11. `AppDialog` (`app_dialog.dart`): Modal confirmation dialogs.
12. `AppBottomSheet` (`app_bottom_sheet.dart`): Modal action sheets with drag handle.
13. `AppSnack` (`app_snack.dart`): Floating feedback banner.
14. `SportFilterBar` (`sport_filter_bar.dart`): Horizontal sport chips scroller.
15. `SectionHeader` (`section_header.dart`): Section title with optional action.

### New Widgets To Be Added in Phase 2
1. `AppSegmented`: Sliding pill segmented control (System / Light / Dark and view switchers).
2. `AppSwitch`: Apple-style switch with smooth primaryFill track.
3. `FrostedBar`: Backdrop blur (sigma 20) with hairline divider, fallback to solid background, wrapped in `RepaintBoundary`.
4. `AdaptiveScaffold`: Custom multi-breakpoint scaffold (Bottom Bar on compact `< 600`, Navigation Rail on medium `600–1023` and expanded `>= 1024`).
5. `AppBreakpoints`: Responsive breakpoint constants (`compact`, `medium`, `expanded`).

### Audit of Inline Styles & Magic Numbers
- Many screens currently use raw `Color(0xFF...)` or `Colors.white`, `Colors.black`, `Colors.grey`.
- Several screen strings have emoji characters (e.g. `🏏 Cricket`, `⚽ Football`, `🏸 Badminton`, `🏆 Tournaments`).
- In Phase 4, every inline color will be replaced with semantic tokens from `AppColors`, and emojis will be replaced with clean typography and icons.

---

## 3. High-Risk Zones & Invariants

1. **Scoring Engines (`lib/features/scoring/engines/`)**
   - Invariant: `CricketEngine`, `BadmintonEngine`, and `FootballEngine` state machines are non-negotiable and strictly untouched.
   - Low tap latency must be preserved (no new allocations or layout work inside ball event tap callbacks).
2. **Realtime Channels (`lib/features/scoring/data/live_scorer_service.dart`)**
   - Supabase realtime channel events (`scorecardChannel`, broadcast payloads) must remain identical.
3. **Tournament RPCs & State Transitions (`lib/features/tournaments/data/tournament_service.dart`)**
   - Bracket advancement rules, standings tie-breakers, and database RPC names must remain untouched.
4. **Navigation Paths & GoRouter Parameters (`lib/core/router/app_router.dart`)**
   - All 22 routes, query parameters, and tab index order must remain intact.
5. **No Database Migrations or Backend Edits**
   - Supabase schema, table structures, and policies are completely unchanged.

---

## 4. Pre-Existing Issues Log (Observed at Phase 0)
- `flutter analyze` reported 78 issues:
  - 14 `unused_import` warnings in test and feature files.
  - Multiple `unnecessary_underscores` in router and screen lambda parameter definitions (`(_, __)` vs `(_, _)`).
  - Deprecated member `activeColor` on `Switch` in `create_tournament_sheet.dart`.
  - Deprecated member `anonKey` in `main.dart` (Supabase).
  - 6 `avoid_print` warnings in `main.dart`.
  - *Resolution:* These are recorded as pre-existing baseline items and will be preserved or cleaned during relevant screen presentation passes without touching business logic.
