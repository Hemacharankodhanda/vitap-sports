# Tournaments Feature Status & Implementation Tracker

## Current Status
- **Branch**: `feature/tournaments`
- **Current Phase**: Phase 0 (Audit) & Phase 1 (Design)
- **Status**: Design Complete — Awaiting Approval before Phase 2

---

## Phase 0 & 1 Plan (Iteration 1)
1. [x] Switch to `feature/tournaments` branch and verify baseline tests/analyzer (`89 tests passed`).
2. [x] Conduct Phase 0 Codebase Audit (`docs/tournaments/AUDIT.md`):
   - Document relations between matches, teams, participants, and entries.
   - Document exact `finish_match` RPC implementation and side effects.
   - Document notifications, feed events, leaderboards, and badges.
   - Document route structure and design-system widgets.
   - Document hostel/branch/year profile fields and scope rules.
3. [x] Develop Phase 1 Technical Architecture & Design (`docs/tournaments/DESIGN.md`):
   - Data model (schema, indexes, foreign keys, RLS, audit logs).
   - State machines (tournaments, entries, fixtures).
   - Pure-Dart algorithm specifications (Knockout, Round Robin, Groups, Standings, NRR).
   - Security-definer RPC specifications & permissions.
   - Atomic `finish_match` hook for fixture completion and advancement.
   - UI structure, bracket CustomPainter layout, and organiser workflows.
4. [ ] Obtain user approval on `docs/tournaments/DESIGN.md` before proceeding to Phase 2.

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
  - Await user approval of `DESIGN.md`.
  - Phase 2: Pure-Dart engines (Knockout generator, Round-robin generator, Group allocator, Standings engines, Advancement & Withdrawal logic).
