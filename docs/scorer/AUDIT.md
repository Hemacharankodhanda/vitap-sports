# Live Match Scorer Audit Report (Phase 0)

Date: 2026-10-10
Repository: `vitap-sports`
Branch: `feature/live-scorer`

---

## 1. System Inventory & Evidence

### 1.1 Authentication & Domain Restriction
- **Client Implementation**:
  - `lib/features/auth/data/auth_service.dart:15-38`: Supabase Google OAuth sign-in flow (`signInWithOAuth(OAuthProvider.google)`).
  - `lib/features/auth/screens/login_screen.dart`: UI with "Continue with Google".
- **Database Trigger**:
  - `supabase/migrations/003_auth_domain_trigger.sql:6-49`: Trigger `on_auth_user_created` on `auth.users` calls `public.handle_new_user()`.
  - Enforces `user_email LIKE '%@vitap.ac.in'`. Rejects invalid signups with `RAISE EXCEPTION` and deletes the unverified `auth.users` row.
  - Automatically provisions `public.users` row with `id`, `name`, and `avatar_url`.

### 1.2 Profiles
- **Model & Service**:
  - `lib/features/profile/data/models/user_model.dart:4-30`: Defines `UserModel` (`id`, `name`, `branch`, `year`, `hostelBlock`, `avatarUrl`, `matchesPlayed`, `wins`, `losses`, `mvpCount`).
  - `lib/features/profile/data/profile_service.dart:12-42`: Queries `users` and manages sports interests in `user_sports`.
- **Database Schema**:
  - `supabase/migrations/001_create_tables.sql:17-30`: `public.users` table holds user stats (`matches_played`, `wins`, `losses`, `mvp_count`).
  - `001_create_tables.sql:33-38`: `public.user_sports` associates users with sports and skill levels (`Beginner`, `Intermediate`, `Advanced`).

### 1.3 Teams & Captain Roles
- **Model & Service**:
  - `lib/features/teams/data/models/team_model.dart`: Defines `TeamModel` and `TeamMember`.
  - `lib/features/teams/data/team_service.dart:13-118`: Manages team creation, members, and recruitment posts.
- **Database Schema**:
  - `supabase/migrations/001_create_tables.sql:41-52`: `public.teams` table stores `captain_id UUID REFERENCES public.users(id)` and win/loss/draw records (`wins`, `losses`, `draws`).
  - `001_create_tables.sql:55-63`: `public.team_members` with roles `captain`, `vice_captain`, `member`.
- **RLS Permissions**:
  - `supabase/migrations/002_rls_policies.sql:58-88`: Only captains can update/delete teams, manage roster members, or accept recruitment join requests.

### 1.4 Match Creation, Challenges & Pick-Up Games/RSVP
- **Matches**:
  - `supabase/migrations/001_create_tables.sql:65-78`: `public.matches` table has `sport_id`, `venue`, `scheduled_at`, `status` (`upcoming`, `live`, `completed`, `cancelled`), `format`, `created_by`, `scorer_id`, `home_score`, `away_score`.
  - Note: Status check constraint does NOT currently include `paused` or `abandoned`.
- **Participants & RSVPs**:
  - `001_create_tables.sql:81-88`: `public.match_participants` supports both team fixtures (`team_id`) and individual/pick-up participants (`user_id`, `side` in `home`, `away`, `individual`, `rsvp_status` in `pending`, `confirmed`, `declined`).
- **Challenges**:
  - `001_create_tables.sql:175-182`: `public.challenges` table for team-to-team challenge flows.
- **UI Navigation**:
  - `lib/features/matches/screens/match_detail_screen.dart:174-205`: Only `match.createdBy` or `match.scorerId` can edit scorecards and manage squads.

### 1.5 Existing Scorecard Code & Architecture
- **Service**:
  - `lib/features/scorecards/data/scorecard_service.dart:10-25`: Only two methods: `getScorecardData` and `updateScorecardData` doing raw `upsert` on table `public.scorecards`.
- **Model**:
  - `lib/features/scorecards/data/models/cricket_scorecard_model.dart:4-349`: Large, cricket-specific state snapshot (`CricketScorecardState`, `CricketInnings`, `BatterStats`, `BowlerStats`, `BallEvent`, `CricketExtras`).
- **Screens**:
  - `lib/features/scorecards/screens/scorecard_edit_screen.dart:53-65`: Checks `match.sportName == 'Cricket'` -> renders `CricketScoringDashboard`; otherwise renders basic fallback score counter.
  - `lib/features/scorecards/screens/cricket_scoring_dashboard.dart`: Stateful UI directly mutating state on button taps and uploading full json snapshot via `updateScorecardData`.
  - `lib/features/scorecards/screens/scorecard_view_screen.dart`: Renders cricket summary or basic score.
- **Providers**:
  - `lib/features/scorecards/providers/scorecard_providers.dart:13-16`: `scorecardDataProvider` is a static `FutureProvider.family`, not reactive/realtime.

### 1.6 JSONB Usage
- `public.scorecards.data`: JSONB storing raw scorecard state snapshot (`001_create_tables.sql:94`).
- `public.scorecards.summary`: JSONB storing high-level summary (`001_create_tables.sql:95`).
- `public.sports.config`: JSONB storing template rules (`001_create_tables.sql:12`).
- `public.feed_events.payload`: JSONB storing activity details (`001_create_tables.sql:197`).

### 1.7 Realtime Setup
- **Publication**:
  - `supabase/migrations/001_create_tables.sql:210-211`:
    ```sql
    ALTER PUBLICATION supabase_realtime ADD TABLE public.scorecards;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
    ```
- **Replica Identity**:
  - Neither `scorecards`, `matches`, nor any table currently has `REPLICA IDENTITY FULL`.
  - Default replica identity only transmits primary keys on `DELETE`, which breaks granular event undo deletes across realtime streams.
- **Client Subscription**:
  - The client does NOT have any Supabase Realtime channel stream subscribed for scorecard updates. `ScorecardViewScreen` reads a `FutureProvider` on first mount.

### 1.8 RLS Policies for Matches & Scorecards
- `supabase/migrations/002_rls_policies.sql:91-104`: Matches:
  - SELECT allowed to all authenticated users.
  - INSERT allowed if `auth.uid() = created_by`.
  - UPDATE allowed if `auth.uid() = created_by OR auth.uid() = scorer_id`.
- `002_rls_policies.sql:116-143`: Scorecards:
  - SELECT allowed to all authenticated users.
  - INSERT & UPDATE allowed for `updated_by = auth.uid()` or creator or scorer.
- **Current vulnerability / gap**: Direct client table modification is permitted without transactional event integrity or atomic rule validation.

### 1.9 Notifications & Match Completion Hooks
- **Notifications**:
  - No remote push notifications configured (FCM/APNS).
- **Match Completion Hooks**:
  - `supabase/migrations/005_functions.sql:132-165`: `on_match_completed` trigger creates a feed event on match status transition to `completed` and invokes `update_tournament_standings`.
  - **Gaps**: Does not update `public.users` (`matches_played`, `wins`, `losses`), nor `public.teams` (`wins`, `losses`, `draws`).

---

## 2. Gap List: What Exists vs What The Scorer Needs

| Area | What Exists | What The Scorer Needs | Gap Status |
| :--- | :--- | :--- | :--- |
| **Data Model** | Snapshot-only in `scorecards.data` | Event-sourced `match_events` table (immutable, client-uuid, `seq` unique per match, replica identity full) | **Missing** |
| **Match Schema** | Statuses: `upcoming, live, completed, cancelled`. Columns: basic scores. | Support `status IN ('scheduled', 'live', 'paused', 'completed', 'abandoned')`, `config JSONB`, `score JSONB`, `scorer_ids UUID[]`, `result JSONB` | **Missing** |
| **Rules Engine** | Ad-hoc UI state mutations in `CricketScoringDashboard` | Pure Dart `ScoringEngine` interface with 3 full engines: Cricket, Badminton, Football | **Missing** |
| **Database RPCs** | Direct client upserts | Atomic Postgres RPCs: `record_event`, `undo_event`, `finish_match` (with idempotency, authorization check, and stat rollup) | **Missing** |
| **Realtime Stream** | Table in publication, but no client stream listener | Riverpod `StreamProvider.autoDispose.family` for match row + `match_events` stream notifier with optimistic apply & delete | **Missing** |
| **Scorer Screen** | Hardcoded cricket dashboard | Unified action-driven scorer shell (`availableActions(state)`), haptics, always-visible Undo, offline queue | **Missing** |
| **Setup Flow** | Rudimentary squads check | Sport-specific setup dialogs/wizards (toss, opening batters/bowler, badminton toss/server, football kickoff/lineups) | **Missing** |
| **Multi-Sport Support**| Stub/dummy counter for non-cricket sports | Authoritative rule-compliant engines and displays for Cricket, Badminton, and Football | **Missing** |

---

## 3. Scorecard Model Strategy: Reuse vs Replace

### Decision: **Extend & Adapt (Hybrid Approach)**

1. **Why Not Keep As-Is**:
   The current `CricketScorecardState` in `cricket_scorecard_model.dart` is tightly coupled to mutable in-memory state manipulation inside `CricketScoringDashboard`. It lacks event idempotency, free hit tracking, accurate bowling rotation rules, and does not provide an abstraction for Badminton and Football.
2. **Why Not Wipe/Delete**:
   The existing structure (`CricketScorecardState`, `CricketInnings`, `BatterStats`, `BowlerStats`) already defines appropriate snapshot JSON field names (`total_runs`, `total_wickets`, `batting_stats`, `bowling_stats`, `extras`). Existing UI screens and summary generators reference these concepts.
3. **Execution Plan**:
   - Establish the root contract `ScoringEngine<TState, TConfig>` in pure Dart.
   - For **Cricket**, maintain JSON compatibility with `CricketScorecardState` for the derived snapshot, but implement the state transitions purely via an immutable `CricketEngine` folding `MatchEvent`s.
   - For **Badminton**, implement `BadmintonEngine` (games, points, 21 cap 30, even/odd court serving positions).
   - For **Football**, implement `FootballEngine` (goals, own goals, yellow/red cards, substitutions, periods, stoppage time, penalty shootouts).
   - The snapshot stored in `matches.score` will contain the sport engine's state JSON, maintaining zero downtime and total backwards compatibility.
