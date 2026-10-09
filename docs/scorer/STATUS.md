# Live Scorer Implementation Status

## Plan for Iteration 1: Database Migration & Schema Foundations
- [ ] Create timestamped migration `supabase/migrations/006_live_scorer_schema.sql` adding `match_events` table (with UUID, match_id, seq, type, payload, created_by, timestamps).
- [ ] Add `config`, `score`, `scorer_ids`, `result` columns to `public.matches`, and expand status check constraint to include `scheduled`, `live`, `paused`, `completed`, `abandoned`.
- [ ] Add `match_events` to `supabase_realtime` publication with `REPLICA IDENTITY FULL`.
- [ ] Create atomic, idempotent Postgres RPCs: `record_event`, `undo_event`, `finish_match`.
- [ ] Enforce strict RLS on `match_events` and `matches`.
- [ ] Verify SQL script syntax and safe re-runnability.

---

## Feature & Architecture Status Table

| Feature / Area | Status | Evidence / Notes |
| :--- | :--- | :--- |
| **Auth & VIT-AP Domain Trigger** | **Working** | `003_auth_domain_trigger.sql:6-49`, `auth_service.dart:15-38`. Trigger on `auth.users` enforces `@vitap.ac.in`. |
| **User Profiles & Stats** | **Working** | `001_create_tables.sql:17-30`, `user_model.dart:4-30`. Profile schema exists. |
| **Teams & Captain Roles** | **Working** | `001_create_tables.sql:41-62`, `002_rls_policies.sql:58-88`. RLS verifies captain permissions. |
| **Matches & Participants** | **Working** | `001_create_tables.sql:65-88`, `match_model.dart:4-100`. Supports team fixtures and pick-up RSVPs. |
| **Live Scorer Schema (`match_events`)** | **Missing** | `001_create_tables.sql` only has snapshot `scorecards`. No `match_events` or `matches.score` columns. |
| **RPC Functions (`record_event`, etc.)** | **Missing** | `005_functions.sql` has tournament standings, but no event-sourcing or atomic scorer RPCs. |
| **Core `ScoringEngine` Abstraction** | **Missing** | No common engine interface exists; pure Dart engine architecture required. |
| **Football Scoring Engine** | **Missing** | Only cricket had a model; Football engine with goals, cards, shootouts not implemented. |
| **Badminton Scoring Engine** | **Missing** | Badminton engine with 21-pt cap 30, even/odd court serving not implemented. |
| **Cricket Scoring Engine** | **Partial** | `cricket_scorecard_model.dart` has snapshot data class, but lacks immutable event folding, free-hit validation, bowler limits. |
| **Realtime Stream Subscriptions** | **Broken** | `scorecards` is in publication, but `scorecard_providers.dart:13-16` uses static `FutureProvider` without realtime streaming. |
| **Scorer Screen Shell & Offline Queue** | **Missing** | `scorecard_edit_screen.dart` is an ad-hoc screen without undo, availableActions, or optimistic offline queue. |
| **Viewer Screen Realtime Timeline** | **Missing** | `scorecard_view_screen.dart` does not stream events or animate count-up changes reactively. |
| **Sport-Specific Setup Dialogs** | **Missing** | Toss, playing XI, opening pairs, and kickoff flows are not implemented. |
| **Automated Engine Unit Tests** | **Missing** | No scenario unit tests exist for Cricket, Badminton, or Football engines. |

---

## Iteration Log

### Iteration 0: System Audit (Phase 0)
- **Goal**: Perform comprehensive codebase and database audit; produce `AUDIT.md`, `STATUS.md`, `ISSUES.md`.
- **Findings**:
  - Found and fixed a blocking compilation error in `test/widget_test.dart` (referenced nonexistent `MyApp`).
  - Identified gap in `scorecards` architecture: only ad-hoc snapshot upserts exist, no event sourcing, no Realtime stream provider in client, missing Football & Badminton engines.
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
- **Next Slice**: Iteration 1: Supabase migrations for `match_events`, match columns, Realtime publication, and RPCs.
