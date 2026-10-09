# VIT-AP Sports — Live Match Scorer Architecture

## 1. Architectural Overview

The Live Match Scorer in VIT-AP Sports is engineered as an **event-sourced, realtime, offline-resilient scoring system** built with Flutter, Riverpod, and Supabase.

```
┌────────────────────────────────────────────────────────┐
│                   Scorer UI Shell                      │
│        (Driven by engine.availableActions(state))      │
└──────────────────────────┬─────────────────────────────┘
                           │ Optimistic Local Apply
                           ▼
┌────────────────────────────────────────────────────────┐
│             Pure Dart Scoring Engine                   │
│ (initialState, apply, validate, availableActions, fold)│
└──────────────────────────┬─────────────────────────────┘
                           │ Enqueue with client UUID
                           ▼
┌────────────────────────────────────────────────────────┐
│               Offline Optimistic Queue                 │
│         (Sequential FIFO flush + idempotency)          │
└──────────────────────────┬─────────────────────────────┘
                           │ RPC record_event / undo_event
                           ▼
┌────────────────────────────────────────────────────────┐
│               Supabase Postgres Database               │
│ - matches (status, score snapshot, scorer_ids)         │
│ - match_events (immutable, unique (match_id, seq))     │
│ - REPLICA IDENTITY FULL (enables delete filtering)     │
└──────────────────────────┬─────────────────────────────┘
                           │ Realtime Publication
                           ▼
┌────────────────────────────────────────────────────────┐
│                  Spectator Viewer                      │
│ (Subscribes first -> loads initial -> animated counts) │
└────────────────────────────────────────────────────────┘
```

### Key Pillars:
1. **Immutable Event Sourcing**: Every scoring action is an immutable row in `match_events` identified by a client-generated UUID for idempotency.
2. **Single Source of Rules**: Scoring logic lives exclusively inside pure, UI-free Dart engines behind a unified `ScoringEngine<TState, TConfig>` contract.
3. **Atomic Postgres Transactions**: Scoring actions, undos, and match completions execute atomically inside Postgres RPCs (`record_event`, `undo_event`, `finish_match`, `take_over_scoring`).
4. **Offline Resilience**: Scoring actions are applied optimistically to local UI state and queued in memory. If offline, the queue retries sequentially without ever producing duplicate database events.
5. **Realtime Spectator Streaming**: The viewer screen subscribes to Supabase Realtime channels before fetching initial state, guaranteeing zero dropped events, and renders score updates with count-up animations.

---

## 2. Database Schema & RPC Functions

### A. Tables & Columns
- **`public.matches`**:
  - `config` (`jsonb`): Sport-specific match rules (e.g., overs per innings, half length, game points).
  - `score` (`jsonb`): Current derived state snapshot for zero-latency queries.
  - `scorer_id` (`uuid`): Active primary scorer.
  - `scorer_ids` (`uuid[]`): List of permitted scorers.
  - `result` (`jsonb`): Final match outcome (winner, margin, stats summary).
  - `status`: `'scheduled'`, `'live'`, `'paused'`, `'completed'`, `'abandoned'`.
- **`public.match_events`**:
  - `id` (`uuid` PK): Client-generated UUID for deduplication.
  - `match_id` (`uuid` FK): Reference to `public.matches`.
  - `seq` (`int`): Monotonically increasing sequence number per match (`UNIQUE(match_id, seq)`).
  - `type` (`text`): Event type name.
  - `team_id` (`uuid` FK): Participating team (or null for individual/guest).
  - `player_id` (`uuid` FK): Participating player (or null).
  - `payload` (`jsonb`): Contextual data (e.g. dismissal type, goal kind, runs).
  - `created_by` (`uuid` FK): Authenticated scorer who created the event.
  - `created_at` (`timestamptz`): Timestamp.
  - `REPLICA IDENTITY FULL`: Configured so Realtime transmits deleted rows on undo.

### B. Postgres RPCs (`SECURITY DEFINER`)
1. **`record_event(p_match_id, p_event, p_snapshot)`**:
   - Validates that caller is authorized (creator, captain, or in `scorer_ids`).
   - Validates match is live.
   - Inserts into `match_events` with `ON CONFLICT (id) DO NOTHING` (idempotent).
   - Atomically updates `matches.score` with `p_snapshot`.
2. **`undo_event(p_match_id, p_event_id, p_snapshot)`**:
   - Validates caller authorization and match status.
   - Deletes target event by `id`.
   - Atomically rolls back `matches.score` to previous snapshot.
3. **`finish_match(p_match_id, p_result, p_final_score)`**:
   - Idempotency guard: If `status == 'completed'`, returns immediately to prevent double-counting.
   - Updates match `status = 'completed'`, writes `result` and `score`.
   - Updates team win/loss/draw records.
   - Increments player `matches_played`, `wins`, `losses`, and `mvp_count`.
   - Emits a `feed_events` item for campus-wide visibility.
4. **`take_over_scoring(p_match_id)`**:
   - Allows match creator or participating captain to take over scoring delegation.

---

## 3. Event Catalog Per Sport

### ⚽ Football
- **`period_start`**: Begins half or extra-time period (`payload: {period: 'first_half' | 'second_half' | 'extra_time_1' | 'extra_time_2' | 'shootout'}`).
- **`period_end`**: Marks half-time, full-time, or break.
- **`added_time`**: Records stoppage time minutes (`payload: {minutes: int}`).
- **`goal`**: Regular goal awarded to team (`payload: {team, scorer, assist?, kind: 'open_play' | 'penalty' | 'free_kick' | 'header' | 'other'}`).
- **`own_goal`**: Point awarded to opposing team; credited to player as own goal.
- **`yellow_card`**: Player cautioned. A 2nd yellow in the same match automatically creates a red card and removes the player from the pitch.
- **`red_card`**: Player sent off; cannot be substituted back in.
- **`substitution`**: Pitch player swapped with bench player (`payload: {player_out, player_in}`). Validates `player_out` is on pitch and `player_in` is unused and not carded.
- **`penalty_missed`**: Penalty kick missed in regulation play.
- **`shootout_kick`**: Alternate penalty shootout kicks (`payload: {team, player, scored: bool}`). Mathematically terminates early when lead cannot be overcome; sudden death pairs thereafter. Shootout score is kept separate from match score.

### 🏸 Badminton
- **`rally_won`**: Every rally awards 1 point to the winning side (`payload: {team, reason?: 'smash' | 'net' | 'out' | 'fault' | 'service_fault'}`).
- **`let`**: Replays rally without altering score.
- **`retire`**: Side retires; opponent immediately wins remaining required games/match.
- **`walkover`**: Opponent wins 2-0 (21-0, 21-0).
- **Service Court & Rotation Rules**:
  - Even serving score = Right service court.
  - Odd serving score = Left service court.
  - Singles: Server and receiver stand diagonally based on score parity.
  - Doubles: Winning rally retains serve and swaps court side. Losing rally switches serve to opponent, where the player matching the new score parity serves without swapping.
- **Game Win**: First to 21 with lead of 2. Tied 29-29 -> next point wins 30-29.
- **Intervals**: 60s informational prompt when leading score reaches 11; change ends after each game and at 11 in Game 3.

### 🏏 Cricket
- **`delivery`**: Legal or non-legal delivery (`payload: {type: 'normal' | 'wide' | 'no_ball' | 'bye' | 'leg_bye', bat_runs: int, boundary: bool, runs_run: int}`).
  - `normal`: 0-6 runs, boundary 4/6, batter balls +1, bowler charged.
  - `wide`: Does not advance over, 1 penalty + runs run, boundary off wide = 5, bowler charged, batter balls not incremented.
  - `no_ball`: 1 penalty run, runs off bat charged to bowler, next ball is FREE HIT.
  - `bye` / `leg_bye`: Legal ball, extras to team, not batter or bowler.
- **`wicket`**: Dismissal (`payload: {dismissal_type, dismissed_batter_id, new_batter_id?, fielder_id?, runs_completed: int, batters_crossed: bool}`).
  - Credited to bowler: `bowled`, `caught`, `lbw`, `stumped`, `hit_wicket`.
  - Not credited: `run_out`, `obstructing_the_field`, `retired_out`.
  - On wide: only `stumped`, `run_out`, `hit_wicket` allowed.
  - On no-ball or free hit: only `run_out` allowed.
- **Strike Rotation**:
  - Odd physically run runs swap strike.
  - End of over swaps strike (applied after ball's own swap).
  - Bowler cannot bowl consecutive overs; enforces max overs per bowler.
- **Maiden Detection**: Over completed with 6 legal balls and 0 runs conceded.
- **Target & Win Margin**: Computes required run rate, balls remaining, "won by X runs" or "won by Y wickets".

---

## 4. How to Add a New Sport

The architecture is fully modular. Adding a new sport (e.g. Volleyball, Basketball, Tennis) requires **zero changes to the Scorer Screen shell or Viewer Screen**:

### Step 1: Define Sport State and Config
Create `lib/features/scoring/engines/<sport>/<sport>_state.dart`:
```dart
class VolleyballConfig {
  const VolleyballConfig({this.setsToWin = 3, this.pointsPerSet = 25});
  final int setsToWin;
  final int pointsPerSet;
  factory VolleyballConfig.fromJson(Map<String, dynamic>? json) => ...;
  Map<String, dynamic> toJson() => ...;
}

class VolleyballState {
  const VolleyballState({required this.homeId, required this.awayId, ...});
  ...
  factory VolleyballState.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```

### Step 2: Implement Pure ScoringEngine
Create `lib/features/scoring/engines/<sport>/<sport>_engine.dart`:
```dart
class VolleyballEngine extends ScoringEngine<VolleyballState, VolleyballConfig> {
  @override
  String get sport => 'Volleyball';

  @override
  VolleyballState initialState(VolleyballConfig config, {required String homeId, required String awayId, Map<String, dynamic>? extra}) { ... }

  @override
  VolleyballState apply(VolleyballState state, MatchEvent event) { ... }

  @override
  String? validate(VolleyballState state, MatchEvent event) { ... }

  @override
  List<ScoringAction> availableActions(VolleyballState state) {
    return [
      ScoringAction(id: 'point_home', label: 'Point Home', type: 'point', isPrimary: true),
      ScoringAction(id: 'point_away', label: 'Point Away', type: 'point', isPrimary: true),
      ScoringAction(id: 'timeout', label: 'Timeout', type: 'timeout'),
    ];
  }

  @override
  bool isComplete(VolleyballState state) { ... }

  @override
  Map<String, dynamic> result(VolleyballState state) { ... }
}
```

### Step 3: Register in SportRegistry
In `lib/features/scoring/domain/sport_registry.dart`:
```dart
static final Map<String, ScoringEngine> _registry = {
  'Cricket': CricketEngine(),
  'Badminton': BadmintonEngine(),
  'Football': FootballEngine(),
  'Volleyball': VolleyballEngine(), // <-- Simply register here!
};
```

### Step 4: Add Unit Test Suite
Create `test/scoring/<sport>_engine_test.dart` and assert scenario rules and property folds.

Because the Scorer UI dynamically reads `engine.availableActions(state)`, your new sport will automatically render in the Scorer Shell and Live Viewer!

---

## 5. Verification Proof & Quality Metrics

- **Unit & Widget Tests**: 31/31 passing tests covering all rules, edge cases, property folds, undo restoration, offline queue, and UI rendering.
- **Flutter Analyzer**: 0 errors, 0 warnings across `lib/features/scoring/`, `lib/features/scorecards/`, and `test/scoring/`.
- **Apple HIG Compliance**: All interactive buttons enforce >= 44pt touch targets, standard spacing tokens (`AppSpacing`), haptic feedback (`HapticFeedback.lightImpact`), and theme tokens.
- **Zero Cost**: Built exclusively on open-source dependencies without paid third-party APIs.
