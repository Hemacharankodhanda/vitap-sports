# Tournaments Feature Status & Implementation Tracker

## Current Status
- **Branch**: `feature/tournaments`
- **Current Phase**: Phase 5 & 6 — Player Profile Honours & Scope Enforcement
- **Status**: Phase 4 Presentation UI, CustomPaint bracket canvas, standings table, organizer wizards, and router integration completed and verified with 121/121 passing tests. Proceeding to profile honours and scope enforcement.

---

## Phase 4 Plan (Iteration 4: UI & CustomPaint Bracket) — COMPLETED
1. [x] Create Bracket CustomPainter & Node Widget:
   - `BracketConnectorPainter`: Smooth rectilinear connecting paths from round to round with active-path accent highlights.
   - `BracketNodeCard`: Compact 2-slot match card displaying seed, display name, score, winner styling, live indicator, and tap actions.
2. [x] Tournament List Screen:
   - Status filter tabs (`All`, `Live`, `Upcoming`, `Completed`).
   - Sport filter chips (`All`, `Cricket`, `Badminton`, `Football`).
   - Tournament card with format badge, date range, scope badge, entrant count, and official marker.
   - Floating Action Button to create tournament (with organizer permission check).
3. [x] Tournament Detail Screen (6-tab layout):
   - Tab 1: **Overview** (dates, scope, format, organizers, rules, registration action).
   - Tab 2: **Fixtures** (stage/round/group indicators, fixture cards with live match link and admin scoring trigger).
   - Tab 3: **Table** (standings table with rank, P, W, D, L, GD/NRR, Pts, qualification indicator).
   - Tab 4: **Bracket** (interactive horizontally & vertically scrollable knockout bracket drawn with CustomPaint).
   - Tab 5: **Stats** (matches played, entrants count, progress indicator).
   - Tab 6: **Teams / Entries** (list of registered entries, seeds, status, registration button for users).
4. [x] Organiser Management Wizards:
   - Create Tournament Dialog / Sheet.
   - Register Entry BottomSheet (with profile eligibility validation feedback).
   - Generate Draw Dialog (knockout / round-robin / groups config + seed allocator).
   - Create Match Dialog for Fixtures.
5. [x] Wire into App Router (`app_router.dart` and `shell_screen.dart` navigation bar).
6. [x] Unit & widget tests in `test/tournaments/tournament_ui_widgets_test.dart` (32/32 tests in tournaments suite passing).


---

## Iteration Log

### Iteration 1 — Phase 0: Audit & Phase 1: Design
- **Read**:
  - `lib/features/matches/data/models/match_model.dart`
  - `lib/features/matches/data/match_service.dart`
  - `lib/features/teams/data/models/team_model.dart`
  - `lib/features/teams/data/team_service.dart`
  - `lib/features/profile/data/models/user_model.dart`
  - `lib/features/profile/screens/edit_profile_screen.dart`
  - `lib/features/feed/screens/feed_screen.dart`
  - `lib/features/leaderboard/screens/leaderboard_screen.dart`
  - `lib/features/leaderboard/providers/leaderboard_providers.dart`
  - `lib/features/scoring/data/live_scorer_service.dart`
  - `lib/features/scoring/providers/live_scorer_providers.dart`
  - `lib/core/router/app_router.dart`
  - `lib/core/router/shell_screen.dart`
  - `lib/core/widgets/*` (AppButton, AppCard, AppChip, AppBottomSheet, AppDialog, StatusLabel, etc.)
  - `supabase/migrations/001_create_tables.sql`
  - `supabase/migrations/002_rls_policies.sql`
  - `supabase/migrations/005_functions.sql`
  - `supabase/migrations/006_live_scorer_schema.sql`
  - `supabase/migrations/009_player_stats_tables.sql`
  - `supabase/migrations/011_fix_career_stats_and_finish_match.sql`
- **Changed**:
  - `docs/tournaments/STATUS.md` (created)
  - `docs/tournaments/AUDIT.md` (created)
  - `docs/tournaments/DESIGN.md` (created)
- **Verification**:
  - `flutter test`: 89 tests passing.
  - `flutter analyze`: Baseline clean (no compile errors).
- **Next Slice**:
  - Phase 2: Pure-Dart engines.

### Iteration 2 — Phase 2: Pure-Dart Engines & Unit Tests
- **Created**:
  - `lib/features/tournaments/domain/models/tournament_models.dart`: Models for tournaments, entries, fixtures, groups, standings rows, and trails.
  - `lib/features/tournaments/engines/knockout_bracket_engine.dart`: Power of 2, seeding order, bye completion, semi-final linkages, third-place playoff, reproducible random draw.
  - `lib/features/tournaments/engines/round_robin_engine.dart`: Circle method for even/odd participants, rest rounds, single/double round-robin.
  - `lib/features/tournaments/engines/group_stage_engine.dart`: Snake seeding distribution, group round-robin, cross-pairing knockout tree.
  - `lib/features/tournaments/engines/standings_engine.dart`: Sport-specific standings with tie-breaks (Football GD/GF/mini-table, Cricket NRR with all-out overs quota, Badminton game/point difference, unresolvable tie detection).
  - `lib/features/tournaments/engines/advancement_engine.dart`: Next fixture routing, third-place loser routing, shootout/super-over requirement enforcement, walkovers, mid-tournament withdrawals, downstream reset validation.
  - `test/tournaments/tournament_engines_test.dart`: 19 comprehensive unit tests covering all edge cases and desk checks.
- **Verification**:
  - `flutter test test/tournaments/tournament_engines_test.dart`: 19/19 passed.
  - `flutter test`: 108/108 passed (0 regressions).
  - `flutter analyze lib/features/tournaments/ test/tournaments/`: 0 issues found.
- **Next Slice**:
  - Phase 3: Supabase Schema, RLS & RPCs.

### Iteration 3 — Phase 3: Supabase Schema, RLS & RPCs
- **Created**:
  - `supabase/migrations/012_tournaments_schema_and_rpc.sql`:
    - Safely altered `tournaments` and `matches`.
    - Created `tournament_admins`, `tournament_groups`, `tournament_entries`, `tournament_fixtures`, `tournament_audit_logs`.
    - Created performance indexes and RLS policies on all 5 tables.
    - Security Definer RPCs: `create_tournament`, `register_tournament_entry`, `withdraw_tournament_entry`, `generate_tournament_draw`, `schedule_tournament_fixture`, `create_match_for_fixture`, `handle_tournament_match_finished`.
    - Enhanced `finish_match` with atomic tournament bracket advancement hook.
  - `docs/tournaments/SUPABASE_CHANGES.md`: Full specification of migrations, schemas, RLS, and RPCs.
  - `lib/features/tournaments/data/tournament_service.dart`: Client queries, realtime streams, and RPC wrappers.
  - `lib/features/tournaments/providers/tournament_providers.dart`: Riverpod providers with live derived standings.
  - `test/tournaments/tournament_service_and_providers_test.dart`: Model serialization & provider tests.
- **Verification**:
  - `flutter test test/tournaments/`: 25/25 passed.
  - `flutter test`: 114/114 passed (0 regressions).
  - `flutter analyze lib/features/tournaments/ test/tournaments/`: 0 issues found.
- **Next Slice**:
  - Phase 4: Presentation & Design System UI.

### Iteration 4 — Phase 4: Presentation & Design System UI
- **Created**:
  - `lib/features/tournaments/presentation/widgets/bracket_connector_painter.dart`: CustomPainter for rectilinear bracket paths and active progression highlights.
  - `lib/features/tournaments/presentation/widgets/bracket_node_card.dart`: Compact 2-slot match card with LIVE indicator, winner highlights, and score displays.
  - `lib/features/tournaments/presentation/widgets/knockout_bracket_view.dart`: Scrollable bracket canvas connecting rounds and third-place match.
  - `lib/features/tournaments/presentation/widgets/tournament_card.dart`: Overview tournament list item with format, status, and scope chips.
  - `lib/features/tournaments/presentation/widgets/tournament_standings_table.dart`: Tabular statistics table with sport-specific columns (NRR / GD / Diff) and qualification markers.
  - `lib/features/tournaments/presentation/widgets/create_tournament_sheet.dart`: Tournament creation wizard with sports, formats, scopes, and dates.
  - `lib/features/tournaments/presentation/widgets/register_entry_sheet.dart`: Entry registration sheet with live hostel/branch/year scope eligibility validation.
  - `lib/features/tournaments/presentation/widgets/generate_draw_dialog.dart`: Draw generator wizard connecting to knockout, league, and group engines.
  - `lib/features/tournaments/presentation/screens/tournament_list_screen.dart`: List screen with status & sport filter tabs and creation CTA.
  - `lib/features/tournaments/presentation/screens/tournament_detail_screen.dart`: 6-tab tournament hub with live fixtures, tables, bracket, stats, and rosters.
  - `test/tournaments/tournament_ui_widgets_test.dart`: Widget test suite covering cards, nodes, standings tables, and brackets.
- **Verification**:
  - `flutter test test/tournaments/`: 32/32 passed.
  - `flutter test`: 121/121 passed (0 regressions across entire codebase).
  - `flutter analyze lib/features/tournaments/`: 0 issues found.
- **Next Slice**:
  - Phase 5: Player Profile Honours, Tournament Badges, and Scope Enforcement.


