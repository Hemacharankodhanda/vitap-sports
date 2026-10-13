# Tournaments Feature — Codebase Audit

**Repository**: `VIT-AP Sports`  
**Date**: October 13, 2026  
**Author**: Senior Flutter + Supabase Engineer  
**Purpose**: Document the baseline architecture, data relationships, and components relevant to implementing the Tournaments module.

---

## 1. Matches, Teams, Participants, and Entries Today

### 1.1 Match Model & Tables
- **Schema**: `public.matches` defined in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L65-L78).
  - Columns: `id`, `sport_id`, `venue`, `scheduled_at`, `status` (`'upcoming'`, `'live'`, `'completed'`, `'cancelled'`), `format`, `description`, `created_by`, `scorer_id`, `home_score`, `away_score`, `created_at`.
  - Added in [006_live_scorer_schema.sql](file:///d:/projects/vitap-sports/supabase/migrations/006_live_scorer_schema.sql#L8-L15): `config JSONB`, `score JSONB`, `result JSONB`.
  - **Tournament linkage**: Currently, `matches` has **no** `tournament_id` or `fixture_id` columns.
- **Dart Model**: [match_model.dart](file:///d:/projects/vitap-sports/lib/features/matches/data/models/match_model.dart#L4-L65).
  - Encapsulates `participants` as a list of `MatchParticipant`.
  - Resolves team IDs via `p.side == 'home'` or `'away'`, supporting either team-based matches (`teamId`) or individual/pair matches (`userId`).

### 1.2 Teams & Team Members
- **Schema**: `public.teams` & `public.team_members` in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L40-L62).
  - `teams`: `id`, `name`, `sport_id`, `logo_url`, `description`, `captain_id`, `wins`, `losses`, `draws`.
  - `team_members`: `team_id`, `user_id`, `role` (`'captain'`, `'vice_captain'`, `'member'`), `position`, `joined_at`.
- **Dart Model**: [team_model.dart](file:///d:/projects/vitap-sports/lib/features/teams/data/models/team_model.dart#L6-L65).
  - Tracks member rosters, roles, and aggregate win/loss counters.

### 1.3 Match Participants
- **Schema**: `public.match_participants` in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L81-L88).
  - Columns: `id`, `match_id`, `team_id` (nullable), `user_id` (nullable), `side` (`'home'`, `'away'`, `'individual'`), `rsvp_status` (`'pending'`, `'confirmed'`, `'declined'`).
- **Service**: [match_service.dart](file:///d:/projects/vitap-sports/lib/features/matches/data/match_service.dart#L80-L135).
  - When creating a match (`createMatch`), inserts 1 or 2 team rows (`side='home'` / `'away'`), and individual squad rows for participating players with `team_id` and `user_id`.
  - In individual sports (e.g. Badminton singles/doubles), `team_id` is null and `user_id` is populated directly.

### 1.4 Early Skeleton Tournament Tables
- In [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L101-L133), unused placeholder tables exist:
  - `public.tournaments` (`id`, `name`, `sport_id`, `format`, `status`, `created_by`, `created_at`).
  - `public.tournament_matches` (`tournament_id`, `match_id`, `round`, `match_order`).
  - `public.tournament_standings` (`id`, `tournament_id`, `team_id`, `played`, `won`, `drawn`, `lost`, `goals_for`, `goals_against`, `goal_difference`, `points`).
- **Audit Finding**: None of these tables are queried or utilized by any Dart code in `lib/` (verified via ripgrep). They will be safely migrated and expanded in a non-destructive timestamped migration.

### 1.5 What the Tournament Module Needs
1. **Match Linking**: `matches.tournament_id` (UUID references `tournaments.id`) and `matches.fixture_id` (UUID references `tournament_fixtures.id` with `UNIQUE` constraint).
2. **Entries Entity**: A dedicated `tournament_entries` table that can represent:
   - Team entries (Cricket, Football) pointing to `team_id` with an array of `player_ids`.
   - Individual entries (Badminton singles) pointing to 1 `player_id`.
   - Pair entries (Badminton doubles) pointing to 2 `player_ids`.
3. **Fixture Match Creation**: A security-definer RPC `create_match_for_fixture(p_fixture_id)` that initializes a `matches` record and populates `match_participants` directly from the fixture's two assigned entries.

---

## 2. The Exact `finish_match` Implementation and Its Updates

### 2.1 RPC Definition & Behavior
- **Location**: Migration [011_fix_career_stats_and_finish_match.sql](file:///d:/projects/vitap-sports/supabase/migrations/011_fix_career_stats_and_finish_match.sql#L69-L291).
- **Caller**: `auth.uid()`, validated via `public.is_authorized_scorer(p_match_id, v_caller)`.
- **Client Invocations**:
  - [live_scorer_service.dart](file:///d:/projects/vitap-sports/lib/features/scoring/data/live_scorer_service.dart#L108-L135).
  - [live_scorer_providers.dart](file:///d:/projects/vitap-sports/lib/features/scoring/providers/live_scorer_providers.dart#L755-L937).

### 2.2 Sequence of Updates in `finish_match`
1. **Authorization**: Checks `is_authorized_scorer`.
2. **Idempotency Guard**: If `v_match.status = 'completed'`, immediately returns `{'success': true, 'already_completed': true}` without duplicate writes.
3. **Matches Record**: Updates `public.matches`:
   ```sql
   UPDATE public.matches
   SET status = 'completed',
       result = p_result,
       score = p_final_score,
       home_score = COALESCE((p_final_score->>'home_score')::INT, home_score),
       away_score = COALESCE((p_final_score->>'away_score')::INT, away_score)
   WHERE id = p_match_id;
   ```
4. **Teams Record**: Updates `public.teams`:
   - If draw: `draws = draws + 1`.
   - If winner: `wins = wins + 1` for `v_winner_team_id`, `losses = losses + 1` for `v_loser_team_id`.
5. **Player Match Stats**: Upserts into `public.player_match_stats` from `p_final_score->'player_stats'`, resolving player UUIDs/names and attributing team IDs, match wins, losses, draws, and MVPs.
6. **Users Record**: Increments `matches_played`, `wins`, `losses`, `mvp_count` on `public.users`.
7. **Squad Member Crediting**: Any squad members of winning/losing teams not explicitly in `player_stats` receive a row in `player_match_stats` and updated user records.
8. **Feed Events**: Emits a `feed_events` record with `event_type = 'match_result'`.
9. **Return**: Returns `{'success': true, 'match_id': ..., 'winner_team_id': ..., 'loser_team_id': ...}`.

### 2.3 What the Tournament Module Needs from `finish_match`
- **Hook Placement**: Inside the same atomic Postgres transaction, if `v_match.fixture_id` is NOT NULL:
  1. Determine `v_winner_entry_id` based on winner team/player.
  2. Update `public.tournament_fixtures`:
     - `status = 'completed'`
     - `result = p_result`
     - `winner_entry_id = v_winner_entry_id`
  3. Advance the winner entry into `next_fixture_id` at `next_slot` ('a' or 'b').
  4. If a third-place fixture is configured (`source_outcome = 'loser'`), advance the losing entry into the third-place fixture.
  5. Check tournament status:
     - If tournament is `'ready'`, transition to `'live'` upon the first completed fixture.
     - If all fixtures for the tournament are completed, transition `tournaments.status = 'completed'`.
  6. Emit `feed_events` with `event_type = 'tournament_update'`.
  7. **Crucial Constraint**: If `v_match.fixture_id` IS NULL, the tournament branch is skipped completely. Non-tournament matches behave identically with zero risk of breakage.

---

## 3. Notifications, Activity Feed, Leaderboards, and Badges

### 3.1 Activity Feed
- **Schema**: `public.feed_events` in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L194-L200).
  - Columns: `id`, `event_type`, `payload JSONB`, `created_at`.
  - Check constraint: `event_type IN ('match_result', 'team_created', 'achievement_earned', 'tournament_update')`.
- **UI**: [feed_screen.dart](file:///d:/projects/vitap-sports/lib/features/feed/screens/feed_screen.dart).
  - Currently features live match real-time streams and quick actions.
- **Tournament Needs**: Emits `'tournament_update'` feed events when a tournament is created, registration opens, the draw is made, a stage completes, and a champion is crowned.

### 3.2 Notifications
- **Architecture**: Notifications are generated via Supabase triggers and client notification providers.
- **Tournament Needs**: User notifications for:
  - Registration status: "Your registration for {Tournament} was approved/waitlisted."
  - Fixture scheduling: "Match scheduled vs {Opponent} on {Date} at {Venue}."
  - Advancement: "You have advanced to the {Round} of {Tournament}!"
  - Champion: "{Winner} crowned champion of {Tournament}."

### 3.3 Leaderboards & Stats
- **Leaderboard Views**:
  - `public.player_career_stats` (aggregates JSONB counters across matches).
  - `public.player_leaderboard` ([011_fix_career_stats_and_finish_match.sql](file:///d:/projects/vitap-sports/supabase/migrations/011_fix_career_stats_and_finish_match.sql#L57-L66)).
- **Leaderboard Providers**: [leaderboard_providers.dart](file:///d:/projects/vitap-sports/lib/features/leaderboard/providers/leaderboard_providers.dart).
  - Top batsmen (runs, avg, SR), top bowlers (wickets, economy, overs), fielders (catches, run-outs), football (goals, assists), badminton (points).
- **Tournament Needs**:
  - Standings are derived in pure Dart from fixture results.
  - Tournament-specific player leaderboards (top run scorers, top wicket takers, golden boot, playmakers) are derived dynamically by joining `player_match_stats` -> `matches` WHERE `matches.tournament_id = :id`.
  - No duplicate stats tables created.

### 3.4 Badges & Achievements
- **Schema**: `public.achievements` & `public.user_achievements` in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L136-L150).
- **UI**: [badge_grid.dart](file:///d:/projects/vitap-sports/lib/features/profile/widgets/badge_grid.dart#L18-L26).
- **Tournament Needs**:
  - Seed official achievements: `Tournament Champion` and `Tournament Finalist`.
  - Award badges idempotently to winning and runner-up entries upon tournament completion.

---

## 4. Routes and Navigation Hierarchy

### 4.1 Shell Navigation
- Defined in [shell_screen.dart](file:///d:/projects/vitap-sports/lib/core/router/shell_screen.dart#L45-L71) with 5 tabs:
  1. Home (`/home`, index 0)
  2. Teams (`/teams`, index 1)
  3. Matches (`/matches`, index 2)
  4. Leaderboard (`/leaderboard`, index 3)
  5. Profile (`/profile`, index 4)

### 4.2 Tournaments Routes in GoRouter
- In [app_router.dart](file:///d:/projects/vitap-sports/lib/core/router/app_router.dart#L214-L238):
  - Tournaments are nested under the Leaderboard branch:
    - `/leaderboard/tournaments` -> `TournamentsListScreen`
    - `/leaderboard/tournaments/create` -> `CreateTournamentScreen`
    - `/leaderboard/tournaments/:id` -> `TournamentDetailScreen`
- **Audit Finding**:
  - `TournamentsListScreen`, `CreateTournamentScreen`, and `TournamentDetailScreen` are currently minimal placeholder screens with `EmptyState`.
  - All routes are already correctly integrated into the app router.

---

## 5. Design System: Existing vs Missing Widgets

### 5.1 Existing Widgets in `lib/core/widgets/`
| Widget | File | Specification Met |
|---|---|---|
| `AppButton` | [app_button.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_button.dart) | Primary, Secondary, Outlined, Text, Destructive; 48px & 40px; loading state. |
| `AppCard`, `AppGroupedCard` | [app_card.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_card.dart) | Flat, 1px border, radius 12, padding 16, hairline dividers. |
| `AppChip`, `ResultChip` | [app_chip.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_chip.dart) | 32px height filter chip, 24x24 result chip (W/D/L). |
| `AppBottomSheet` | [app_bottom_sheet.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_bottom_sheet.dart) | 16px top radius, drag handle, pinned bottom action. |
| `AppDialog` | [app_dialog.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_dialog.dart) | 16px radius, max width 400, 40% scrim, destructive confirmation. |
| `StatusLabel`, `StatusBadge` | [status_badge.dart](file:///d:/projects/vitap-sports/lib/core/widgets/status_badge.dart) | Live (pulsing dot), Upcoming, Completed, Paused, Cancelled. |
| `EmptyState` | [empty_state.dart](file:///d:/projects/vitap-sports/lib/core/widgets/empty_state.dart) | Minimal icon, title, subtitle, optional action. |
| `AppTextField` | [app_text_field.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_text_field.dart) | Flat hairline border, tabular figures, validation helpers. |
| `StatTile`, `StatGridCard` | [stat_tile.dart](file:///d:/projects/vitap-sports/lib/core/widgets/stat_tile.dart) | Tabular figures, clean contrast, NaN fallback. |
| `AppAvatar` | [app_avatar.dart](file:///d:/projects/vitap-sports/lib/core/widgets/app_avatar.dart) | Circular player avatars, rounded-square team avatars. |
| `SportFilterBar` | [sport_filter_bar.dart](file:///d:/projects/vitap-sports/lib/core/widgets/sport_filter_bar.dart) | Horizontal sport selector. |

### 5.2 Missing / Tournament-Specific Widgets Needed
1. **`BracketNodeCard`**: Compact two-row card for knockout bracket nodes displaying entry names, seeds, scores, bold winner row, and status tag (Live, FT, Upcoming).
2. **`BracketConnectorPainter`**: Pure `CustomPainter` rendering orthogonal hairline connectors between bracket rounds.
3. **`TournamentStandingsTable`**: Tabular layout for sport standings (Rank, Team, P, W, D, L, GD/NRR, Pts) with highlighted user row and tie-break notes.

---

## 6. Profile Fields & Eligibility Scopes

### 6.1 Profile Attributes in `public.users`
- Defined in [001_create_tables.sql](file:///d:/projects/vitap-sports/supabase/migrations/001_create_tables.sql#L17-L30) and [user_model.dart](file:///d:/projects/vitap-sports/lib/features/profile/data/models/user_model.dart#L23-L25):
  - `branch`: `CSE`, `ECE`, `MECH`, `CIVIL`, `LAW`, `BUSINESS`.
  - `year`: `1st Year`, `2nd Year`, `3rd Year`, `4th Year`, `Postgrad`.
  - `hostel_block`: `MH-1` through `MH-6`, `LH-1` through `LH-3`, `Day Scholar`.

### 6.2 Tournament Scope Rules
- **Scope Options**:
  - `open`: Any registered student or team.
  - `hostel`: All members of a registering team/pair/individual must belong to the same hostel block (or matching tournament eligibility block).
  - `branch`: All members must be in the specified department.
  - `year`: All members must be in the specified academic year (e.g., Freshers Cup for `1st Year`).
- **Validation**:
  - The registration RPC and Dart pre-checks inspect every player's profile in the entry against the tournament's scope rule. If any player violates eligibility, registration is rejected with a clear message: `"Player {Name} belongs to {Hostel A}, but this tournament is restricted to {Hostel B}."`
