# Live Scorer Implementation Status

## Plan for Iteration 4: Unified Scorer Screen UI
- [ ] Connect `scorecard_edit_screen.dart` to `liveScorerNotifierProvider` driven dynamically by `engine.availableActions(state)`.
- [ ] Build sport-specific match setup flows (Football lineups & kickoff; Badminton singles/doubles & first server; Cricket toss, opening pair, opening bowler).
- [ ] Implement large tap targets (Apple HIG compliant >= 44pt), haptic feedback (`HapticFeedback.lightImpact`), and always-visible Undo.
- [ ] Implement clear confirmation dialogs for destructive actions (Finish Match, Abandon).
- [ ] Display subtle "syncing / offline queued" banner with manual retry trigger.
- [ ] Implement "Take Over Scoring" flow for creator/captains when another scorer is assigned.
- [ ] Verify `flutter analyze` and `flutter test`.

---

## Feature & Architecture Status Table

| Feature / Area | Status | Evidence / Notes |
| :--- | :--- | :--- |
| **Auth & VIT-AP Domain Trigger** | **Working** | `003_auth_domain_trigger.sql:6-49`, `auth_service.dart:15-38`. Trigger on `auth.users` enforces `@vitap.ac.in`. |
| **User Profiles & Stats** | **Working** | `001_create_tables.sql:17-30`, `user_model.dart:4-30`. Profile schema exists. |
| **Teams & Captain Roles** | **Working** | `001_create_tables.sql:41-62`, `002_rls_policies.sql:58-88`. RLS verifies captain permissions. |
| **Matches & Participants** | **Working** | `001_create_tables.sql:65-88`, `match_model.dart:4-100`. Supports team fixtures and pick-up RSVPs. |
| **Live Scorer Schema (`match_events`)** | **Working** | `006_live_scorer_schema.sql:1-42`. Table created with `uq_match_events_match_seq`, full replica identity, and `matches` scoring columns. |
| **RPC Functions (`record_event`, etc.)** | **Working** | `006_live_scorer_schema.sql:43-290`, `007_take_over_scoring.sql`. Implemented `record_event`, `undo_event`, idempotent `finish_match`, and `take_over_scoring`. Verified in `supabase/tests/rpc_checks.sql`. |
| **Core `ScoringEngine` Abstraction** | **Working** | `lib/features/scoring/domain/scoring_engine.dart`. Pure Dart, immutable, supports `initialState`, `apply`, `validate`, `availableActions`, `isComplete`, `result`, and `fold`. |
| **Football Scoring Engine** | **Working** | `football_engine.dart`, `football_state.dart`. Own goals, 2nd yellow -> red, substitutions, stoppage time, penalty shootouts with early mathematical termination. Verified in `football_engine_test.dart`. |
| **Badminton Scoring Engine** | **Working** | `badminton_engine.dart`, `badminton_state.dart`. 21-pt win-by-2 cap 30, even/odd court serving position tracking, doubles rotation, intervals, walkover/retire. Verified in `badminton_engine_test.dart`. |
| **Cricket Scoring Engine** | **Working** | `cricket_engine.dart`, `cricket_state.dart`. Overs, maidens, wides/no-balls with Free Hit, strike rotation, wicket dismissal validation, bowler over limits, target/margin calculation. Verified in `cricket_engine_test.dart`. |
| **Realtime Stream Subscriptions & Data Layer** | **Working** | `live_scorer_service.dart`, `live_scorer_providers.dart`. Subscribes to Realtime first before initial load, stream on `matches`, timeline insert/delete reconciler, offline optimistic event queue with UUID idempotency and retry. Verified in `live_scorer_test.dart`. |
| **Scorer Screen Shell & Offline Queue** | **Partial** | Queue logic working in `live_scorer_providers.dart`. Shell UI planned for Iteration 4. |
| **Viewer Screen Realtime Timeline** | **Missing** | Planned in Iteration 5 (`scorecard_view_screen.dart`). |
| **Sport-Specific Setup Dialogs** | **Missing** | Planned in Iteration 4. |
| **Automated Engine Unit Tests** | **Working** | 26 unit tests passing across all three engines, property folds, undo restoration, and offline queue syncing in `test/scoring/`. |

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

### Iteration 2: Pure Dart Scoring Engines & Comprehensive Test Suites
- **Goal**: Implement immutable, pure Dart scoring engines for Football, Badminton, and Cricket behind `ScoringEngine` contract, plus property and scenario tests.
- **Changes**:
  - Created `lib/features/scoring/domain/match_event.dart`.
  - Created `lib/features/scoring/domain/scoring_engine.dart`.
  - Created `lib/features/scoring/domain/sport_registry.dart`.
  - Created `lib/features/scoring/engines/football/football_state.dart` and `football_engine.dart`.
  - Created `lib/features/scoring/engines/badminton/badminton_state.dart` and `badminton_engine.dart`.
  - Created `lib/features/scoring/engines/cricket/cricket_state.dart` and `cricket_engine.dart`.
  - Created comprehensive test suites (`football_engine_test.dart`, `badminton_engine_test.dart`, `cricket_engine_test.dart`).
- **Verification**:
  - `flutter test` -> 20/20 tests passing (100% pass across all 3 engines).
  - Property tests verified: `fold(all_events)` reproduces state snapshot; `undo` restores exact previous state.
  - `flutter analyze lib/features/scoring/ test/scoring/` -> 0 errors, 0 warnings.

### Iteration 3: Realtime & Riverpod Data Layer with Offline Optimistic Queue
- **Goal**: Implement `LiveScorerService`, Realtime subscription flow, Riverpod stream providers, and optimistic event queue with client UUID idempotency and retry.
- **Changes**:
  - Created `supabase/migrations/007_take_over_scoring.sql` for safe scorer delegation.
  - Created `lib/features/scoring/data/live_scorer_service.dart`.
  - Created `lib/features/scoring/providers/live_scorer_providers.dart`:
    - `liveMatchStreamProvider`: auto-disposing Realtime row stream.
    - `LiveEventsNotifier`: subscribes to Realtime first before initial query to prevent dropped events, tracks inserts and deletes with replica identity full.
    - `LiveScorerNotifier`: drives state via `SportRegistry.fold()`, optimistic local apply, sequential queue flush, idempotency, undo, and atomic match finish.
  - Enhanced `SportRegistry` with `parseConfig`, `initialState`, and `fold` helpers.
  - Created unit tests in `test/scoring/live_scorer_test.dart` for queue retention, network retry, optimistic local state, and undo.
- **Verification**:
  - `flutter test` -> 26/26 tests passing (100% pass across all 4 test suites).
  - `flutter analyze lib/features/scoring/ test/scoring/` -> 0 errors, 0 warnings.
- **Next Slice**: Iteration 4: Unified Scorer Screen UI (`scorecard_edit_screen.dart`, setup flows, availableActions grid, haptics, undo).
