# Tournaments Feature Status & Implementation Tracker

## Current Status
- **Branch**: `feature/tournaments`
- **Current Phase**: Phase 3 — Supabase Schema, RLS & RPCs
- **Status**: Pure-Dart engines completed and verified (108/108 tests passing). Proceeding to Supabase migrations and RPCs.

---

## Phase 2 Plan (Iteration 2: Pure-Dart Engines) — COMPLETED
1. [x] Implement immutable tournament domain models (`TournamentEntry`, `TournamentFixture`, `TournamentGroup`, `FixtureResult`, `TournamentStandingsRow`, `TieBreakTrail`).
2. [x] Build `KnockoutBracketEngine`:
   - Power of 2 sizing, standard seeding layout ($1 \times 8, 4 \times 5, 3 \times 6, 2 \times 7$), top seed byes with automatic advancement, third-place playoff, reproducible random seeds.
3. [x] Build `RoundRobinEngine`:
   - Circle method, odd $N$ rest rounds, single & double round-robin, round grouping.
4. [x] Build `GroupStageEngine`:
   - Snake seeding across $G$ groups, per-group round-robin, cross-pairing qualification ($A_1 \times B_2$, $B_1 \times A_2$).
5. [x] Build sport-specific `StandingsEngine`:
   - Football: 3/1/0 pts, goal difference, goals for, head-to-head mini-tables, 3-0 walkover.
   - Cricket: 2/1/1/0 pts, Net Run Rate (NRR) with all-out innings quota rule and balls-to-overs conversion, NR exclusions.
   - Badminton: match wins, game difference, point difference, head-to-head.
   - Multi-way tie-break resolution and `"needs_organiser_decision"` flag.
6. [x] Build `AdvancementEngine`:
   - Slot advancement to `next_fixture_id` / `next_slot`, third-place loser routing, walkover score application, withdrawal / disqualification waterfall, downstream reset validations.
7. [x] Implement comprehensive pure-Dart test suite covering all desk-checks and edge cases ($N=2 \dots 64$, desk check 5 & 6 entrants, odd round robin, cricket NRR example, football 3-way tie). Verify clean analysis and green tests.

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
  - Phase 3: Supabase Schema, RLS & RPCs (`supabase/migrations/012_tournaments_schema_and_rpc.sql`).

