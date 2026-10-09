# Live Scorer Implementation Status

## Plan for Iteration 2: Pure Dart Scoring Engines (Football, Badminton, Cricket)
- [ ] Define core event-sourced contracts: `MatchEvent`, `ScoringEngine<TState, TConfig>`, and `SportRegistry`.
- [ ] Implement `FootballEngine`: goals, own goals, yellow/red cards (2nd yellow -> red), substitutions, stoppage time, penalty shootouts.
- [ ] Implement `BadmintonEngine`: rally-point system, 21-pt win-by-2 cap 30, even/odd court serving position tracking, doubles rotation, intervals, walkover/retire.
- [ ] Implement `CricketEngine`: balls, overs, wides/no-balls with Free Hit, byes/leg-byes, strike rotation, wicket dismissal validation, bowler over limits, maiden detection, target/margin computation.
- [ ] Implement pure Dart scenario tests for each engine in `test/scoring/` covering all specified rule edge cases + event fold & undo property tests.
- [ ] Verify zero analyzer errors and 100% test pass.

---

## Feature & Architecture Status Table

| Feature / Area | Status | Evidence / Notes |
| :--- | :--- | :--- |
| **Auth & VIT-AP Domain Trigger** | **Working** | `003_auth_domain_trigger.sql:6-49`, `auth_service.dart:15-38`. Trigger on `auth.users` enforces `@vitap.ac.in`. |
| **User Profiles & Stats** | **Working** | `001_create_tables.sql:17-30`, `user_model.dart:4-30`. Profile schema exists. |
| **Teams & Captain Roles** | **Working** | `001_create_tables.sql:41-62`, `002_rls_policies.sql:58-88`. RLS verifies captain permissions. |
| **Matches & Participants** | **Working** | `001_create_tables.sql:65-88`, `match_model.dart:4-100`. Supports team fixtures and pick-up RSVPs. |
| **Live Scorer Schema (`match_events`)** | **Working** | `006_live_scorer_schema.sql:1-42`. Table created with `uq_match_events_match_seq`, full replica identity, and `matches` scoring columns. |
| **RPC Functions (`record_event`, etc.)** | **Working** | `006_live_scorer_schema.sql:43-290`. Implemented `record_event`, `undo_event`, and idempotent `finish_match`. Verified in `supabase/tests/rpc_checks.sql`. |
| **Core `ScoringEngine` Abstraction** | **Missing** | To be implemented in Iteration 2. |
| **Football Scoring Engine** | **Missing** | To be implemented in Iteration 2. |
| **Badminton Scoring Engine** | **Missing** | To be implemented in Iteration 2. |
| **Cricket Scoring Engine** | **Missing** | To be implemented in Iteration 2. |
| **Realtime Stream Subscriptions** | **Broken** | `scorecards_providers.dart` needs StreamProvider for live matches and match_events notifier. |
| **Scorer Screen Shell & Offline Queue** | **Missing** | Shell screen driven by `engine.availableActions(state)`. |
| **Viewer Screen Realtime Timeline** | **Missing** | Viewer screen with live count-up animation and timeline updates. |
| **Sport-Specific Setup Dialogs** | **Missing** | Toss, playing XI, opening pairs, kickoff flows. |
| **Automated Engine Unit Tests** | **Missing** | Scenario tests for all three sports. |

---

## Iteration Log

### Iteration 0: System Audit (Phase 0)
- **Goal**: Perform comprehensive codebase and database audit; produce `AUDIT.md`, `STATUS.md`, `ISSUES.md`.
- **Findings**:
  - Found and fixed a blocking compilation error in `test/widget_test.dart` (referenced nonexistent `MyApp`).
  - Identified gap in `scorecards` architecture: only ad-hoc snapshot upserts exist, no event sourcing, missing Football & Badminton engines.
- **Changes**:
  - Created branch `feature/live-scorer`.
  - Created `docs/scorer/AUDIT.md`.
  - Created `docs/scorer/STATUS.md`.
  - Created `docs/scorer/ISSUES.md`.
  - Fixed `test/widget_test.dart` to smoke-test `AppButton`.
- **Verification**:
  - `git branch` -> `feature/live-scorer`
  - `flutter test` -> 1 passing test (100% pass)
  - `flutter analyze` -> Zero compilation errors

### Iteration 1: Database Migration & Schema Foundations
- **Goal**: Build event-sourced schema (`match_events`), scoring columns on `matches`, Realtime publication, and atomic RPCs (`record_event`, `undo_event`, `finish_match`).
- **Changes**:
  - Created `supabase/migrations/006_live_scorer_schema.sql`.
  - Created SQL test verification script in `supabase/tests/rpc_checks.sql`.
  - Updated `docs/scorer/STATUS.md`.
- **Verification**:
  - Migration script checked for safe additive execution with re-runnable statements.
  - `flutter test` -> All tests passed.
- **Next Slice**: Iteration 2: Pure Dart scoring engines for Football, Badminton, and Cricket with complete scenario test suites.
