# Supabase Migration & Rollout Guide — Player Stats

This document covers the SQL changes, backfill instructions, and rollback plans for deploying the new Player Stats & Match Analysis feature.

## 1. Schema Changes (Migration 009)

The new schema shifts from flat user counters to event-sourced, idempotent stats tracked per-match. 

### `player_match_stats` Table
Stores raw stat counters for each player in a specific match.

```sql
CREATE TABLE IF NOT EXISTS public.player_match_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  player_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  sport TEXT NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  counters JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_player_match_stats UNIQUE (match_id, player_id)
);

-- RLS: Readable by everyone
```

### `match_analysis` Table
(Optional cache for expensive computations - UI payload for Match Analysis screens).

```sql
CREATE TABLE IF NOT EXISTS public.match_analysis (
  match_id UUID PRIMARY KEY REFERENCES public.matches(id) ON DELETE CASCADE,
  analysis JSONB NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### `player_career_stats` View
Dynamically computes career stats mathematically from match stats. Guaranteed to never drift.

```sql
CREATE OR REPLACE VIEW public.player_career_stats AS
SELECT 
  player_id,
  sport,
  COUNT(match_id) AS matches_played,
  jsonb_object_agg(key, val) AS career_counters
FROM (
  SELECT 
    player_id, 
    sport, 
    match_id,
    key, 
    SUM((value)::numeric) AS val
  FROM public.player_match_stats,
       jsonb_each_text(counters)
  GROUP BY player_id, sport, match_id, key
) grouped_counters
GROUP BY player_id, sport;
```

---

## 2. RPC Updates

### `finish_match`
The `finish_match` RPC has been completely overhauled to be idempotent. It now accepts the raw `p_final_score` JSON emitted by Dart engines which contains `{ player_stats: { ... } }`. 

Crucially, it also handles W/L assignment without Dart's involvement:
```sql
-- Resolves the Team ID and injects Wins/Losses into the JSON counters
SELECT team_id INTO v_player_team_id FROM public.match_participants WHERE match_id = p_match_id AND player_id = v_stat_record.key::UUID;
-- Appends {"matches_won": 1} or {"matches_lost": 1} based on winner_team_id
```

---

## 3. Backfill Instructions (Legacy Matches)

Older matches completed before Migration 009 will not have rows in `player_match_stats`.

### Step 1: Re-fold offline state (Dart)
To retroactively generate `player_match_stats` for old matches, write a one-off Dart script that:
1. Queries all matches where `status = 'completed'` AND `score->'player_stats'` IS NULL.
2. Pulls all raw scoring events from the `match_events` table for that match.
3. Instantiates the appropriate `LiveScorerEngine` (Cricket, Badminton, Football).
4. Folds all events to reconstruct the final `score` JSON payload, which will now automatically include `player_stats`.
5. Calls the new RPC `recompute_match_stats(match_id, player_stats_json)` (if you choose to expose it separately), or just manually bulk-inserts into `player_match_stats`.

### Step 2: Clean up Users Table
The legacy `users` table still has `matches_played`, `wins`, `losses`, `mvp_count` columns. 
These columns are effectively deprecated. The `UserModel` in Dart has been updated to automatically overlay the `player_career_stats` derived aggregates on top of these. 
Once all matches are fully backfilled, you can drop these columns from the `users` table entirely.

---

## 4. Rollback Plan

If the migration fails or causes data drift:
1. **Dart:** Revert to the previous `finish_match` signature expectations in Dart.
2. **Database:**
```sql
DROP VIEW IF EXISTS public.player_career_stats;
DROP TABLE IF EXISTS public.match_analysis;
DROP TABLE IF EXISTS public.player_match_stats;
```
3. No historical data is lost on rollback, as the `matches.score` and `users` table structures remain untouched. You will merely fall back to relying on the legacy flat integers on the `users` table.
