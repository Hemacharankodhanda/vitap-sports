# Live Scorer and Stats Audit

## 1. Event-Sourced Scorer Foundation
The event-sourced scorer is fully functional for all three sports. The pure-Dart engines (`cricket_engine.dart`, `football_engine.dart`, `badminton_engine.dart`) use a command/event architecture and `SportRegistry.fold` to rebuild state. 

### Cricket
- **Events**: `set_bowler`, `set_batters`, `delivery`, `finish_match`.
- **Payloads**: The `delivery` payload captures `kind`, `runs`, `is_boundary`, `is_wicket`, `dismissal_type`, `fielder_id`, `out_batter_id`, `new_batter_id`, and `batters_crossed`.
- **Missing/Actionable**: The prompt requires that "Every event stores `striker_id`, `non_striker_id` and `bowler_id`... so any stat can be rebuilt later." Currently, the UI/scorer relies on the engine's active innings state rather than forcing these IDs onto every single delivery payload. We need to update the `delivery` action dispatchers (in the UI) to attach `striker_id`, `non_striker_id`, and `bowler_id` to the event payload. 

### Football
- **Events**: `lineups_set`, `period_start`, `period_end`, `added_time`, `goal`, `own_goal`, `yellow_card`, `red_card`, `substitution`, `shootout_kick`, `forfeit`, `walkover`.
- **Payloads**: Goals capture `scorer`, `assist`, `kind`. Cards and subs capture appropriate `player`, `player_in`, `player_out`. 
- **Missing/Actionable**: The engine tracks `pitchPlayers` and `benchPlayers` correctly. Clean sheets and minutes played can be accurately derived from folding `lineups_set` and `substitution` events.

### Badminton
- **Events**: `setup`, `rally_won`, `let`, `retire`, `walkover`. 
- **Payloads**: `rally_won` captures `team`.
- **Missing/Actionable**: To track "per-player points won" and "service points won", we need to know who was serving during the rally. The engine currently tracks `currentServerId` and `currentReceiverId`, but `rally_won` payloads do not explicitly record them. We must inject `server_id` and `receiver_id` into the `rally_won` event payload.

## 2. Current Player Profile
- **Model**: `UserModel` (`lib/features/profile/data/models/user_model.dart`) tracks global raw integers: `matchesPlayed`, `wins`, `losses`, `mvpCount`.
- **UI**: `ProfileScreen` (`lib/features/profile/screens/profile_screen.dart`) renders a simple `StatsRow` with these four numbers. It lacks per-sport context, Batting/Bowling/Fielding breakdowns, and any derived ratios (average, strike rate, win %).

## 3. How `finish_match` Works Today
- **Mechanism**: It's a Postgres RPC located in `supabase/migrations/006_live_scorer_schema.sql` (lines 213-335).
- **Stat Updating**: It atomically updates `matches` (status to `completed`), then directly increments `matches_played`, `wins`, `losses`, and `mvp_count` on the `users` and `teams` tables. 
- **Deficiency**: It **does not** create `player_match_stats` rows. It mutates `users` directly, which violates the requirement: "Career totals are RECOMPUTED as the sum of that player's player_match_stats rows (not incremented)".

## 4. Guest Players
- Guest players (entered via the "+ Enter Custom Player Name" flow) do not possess a UUID (they are treated as string names). The new SQL RPCs will need to filter out non-UUIDs when upserting to `player_match_stats` and `player_career_stats`, keeping their stats isolated to the match scorecard snapshot only.
