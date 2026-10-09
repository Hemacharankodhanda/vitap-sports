-- VIT-AP Sports — Live Scorer Migration
-- Event-sourced match events, engine snapshot schema, RPCs, and Realtime publication.

-- 1. Extend matches table with event-sourced & scoring columns
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS config JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS score JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS scorer_ids UUID[] DEFAULT ARRAY[]::UUID[],
  ADD COLUMN IF NOT EXISTS result JSONB DEFAULT '{}'::JSONB;

-- Safely expand status constraint to support scheduled, live, paused, completed, abandoned, upcoming, cancelled
ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_status_check;
ALTER TABLE public.matches ADD CONSTRAINT matches_status_check
  CHECK (status IN ('scheduled', 'live', 'paused', 'completed', 'abandoned', 'upcoming', 'cancelled'));

-- 2. Create immutable match_events table
CREATE TABLE IF NOT EXISTS public.match_events (
  id UUID PRIMARY KEY, -- Client-generated UUID for idempotency
  match_id UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  seq INT NOT NULL,
  type TEXT NOT NULL,
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  player_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  payload JSONB DEFAULT '{}'::JSONB,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_match_events_match_seq UNIQUE (match_id, seq)
);

CREATE INDEX IF NOT EXISTS idx_match_events_match_seq ON public.match_events(match_id, seq ASC);
CREATE INDEX IF NOT EXISTS idx_match_events_created ON public.match_events(created_at DESC);

-- 3. Configure Realtime and Full Replica Identity
-- Full replica identity allows clients to receive entire deleted record on undo
ALTER TABLE public.match_events REPLICA IDENTITY FULL;
ALTER TABLE public.matches REPLICA IDENTITY FULL;

DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.match_events;
  EXCEPTION WHEN duplicate_object THEN
    -- already in publication
  END;
END $$;

-- 4. Row Level Security on match_events
ALTER TABLE public.match_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Match events are readable by all authenticated users" ON public.match_events;
CREATE POLICY "Match events are readable by all authenticated users"
  ON public.match_events FOR SELECT
  TO authenticated USING (true);

-- Deny direct table modification to regular users; events must be authored via atomic RPCs
DROP POLICY IF EXISTS "Direct match event insert restricted" ON public.match_events;
CREATE POLICY "Direct match event insert restricted"
  ON public.match_events FOR INSERT
  TO authenticated WITH CHECK (false);

-- 5. Helper function: Check if caller is authorized scorer
CREATE OR REPLACE FUNCTION public.is_authorized_scorer(p_match_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_authorized BOOLEAN := FALSE;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.matches m
    WHERE m.id = p_match_id
      AND (
        m.created_by = p_user_id
        OR m.scorer_id = p_user_id
        OR p_user_id = ANY(m.scorer_ids)
        OR EXISTS (
          SELECT 1 FROM public.match_participants mp
          JOIN public.teams t ON t.id = mp.team_id
          WHERE mp.match_id = m.id AND t.captain_id = p_user_id
        )
      )
  ) INTO v_authorized;

  RETURN v_authorized;
END;
$$;

-- 6. RPC: record_event
-- Atomically inserts an event, checks permissions and match status, and updates matches.score snapshot
CREATE OR REPLACE FUNCTION public.record_event(
  p_match_id UUID,
  p_event JSONB,
  p_snapshot JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_status TEXT;
  v_event_id UUID;
  v_seq INT;
  v_type TEXT;
  v_team_id UUID;
  v_player_id UUID;
  v_payload JSONB;
BEGIN
  -- Verify authorization
  IF NOT public.is_authorized_scorer(p_match_id, v_caller) THEN
    RAISE EXCEPTION 'Not authorized to score this match';
  END IF;

  -- Verify match status is live
  SELECT status INTO v_status FROM public.matches WHERE id = p_match_id;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;
  IF v_status NOT IN ('live', 'scheduled', 'upcoming') THEN
    RAISE EXCEPTION 'Match is not currently in a scoreable state (status: %)', v_status;
  END IF;

  -- Parse event fields
  v_event_id := (p_event->>'id')::UUID;
  v_seq := (p_event->>'seq')::INT;
  v_type := p_event->>'type';
  v_team_id := NULLIF(p_event->>'team_id', '')::UUID;
  v_player_id := NULLIF(p_event->>'player_id', '')::UUID;
  v_payload := COALESCE(p_event->'payload', '{}'::JSONB);

  IF v_event_id IS NULL OR v_seq IS NULL OR v_type IS NULL THEN
    RAISE EXCEPTION 'Invalid event data: id, seq, and type are required';
  END IF;

  -- Insert event (idempotent: ignore if exact id already inserted)
  INSERT INTO public.match_events (
    id, match_id, seq, type, team_id, player_id, payload, created_by
  ) VALUES (
    v_event_id, p_match_id, v_seq, v_type, v_team_id, v_player_id, v_payload, v_caller
  )
  ON CONFLICT (id) DO NOTHING;

  -- Update matches score snapshot and promote scheduled to live
  UPDATE public.matches
  SET score = p_snapshot,
      status = 'live',
      home_score = COALESCE((p_snapshot->>'home_score')::INT, home_score),
      away_score = COALESCE((p_snapshot->>'away_score')::INT, away_score)
  WHERE id = p_match_id;

  -- Backward-compatibility: update scorecards table if present
  INSERT INTO public.scorecards (match_id, data, updated_by, updated_at)
  VALUES (p_match_id, p_snapshot, v_caller, NOW())
  ON CONFLICT (match_id) DO UPDATE SET
    data = EXCLUDED.data,
    updated_by = EXCLUDED.updated_by,
    updated_at = NOW();

  RETURN jsonb_build_object('success', true, 'event_id', v_event_id, 'seq', v_seq);
END;
$$;

-- 7. RPC: undo_event
-- Atomically deletes the target event and rolls back the matches.score snapshot
CREATE OR REPLACE FUNCTION public.undo_event(
  p_match_id UUID,
  p_event_id UUID,
  p_snapshot JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_status TEXT;
BEGIN
  IF NOT public.is_authorized_scorer(p_match_id, v_caller) THEN
    RAISE EXCEPTION 'Not authorized to undo events on this match';
  END IF;

  SELECT status INTO v_status FROM public.matches WHERE id = p_match_id;
  IF v_status != 'live' THEN
    RAISE EXCEPTION 'Cannot undo events when match is not live';
  END IF;

  DELETE FROM public.match_events
  WHERE id = p_event_id AND match_id = p_match_id;

  UPDATE public.matches
  SET score = p_snapshot,
      home_score = COALESCE((p_snapshot->>'home_score')::INT, home_score),
      away_score = COALESCE((p_snapshot->>'away_score')::INT, away_score)
  WHERE id = p_match_id;

  UPDATE public.scorecards
  SET data = p_snapshot, updated_by = v_caller, updated_at = NOW()
  WHERE match_id = p_match_id;

  RETURN jsonb_build_object('success', true, 'undone_event_id', p_event_id);
END;
$$;

-- 8. RPC: finish_match
-- Atomically completes match, writes result, updates team/user stats, and emits feed event exactly once (idempotent)
CREATE OR REPLACE FUNCTION public.finish_match(
  p_match_id UUID,
  p_result JSONB,
  p_final_score JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_match RECORD;
  v_winner_team_id UUID;
  v_loser_team_id UUID;
  v_is_draw BOOLEAN := FALSE;
  v_home_team_id UUID;
  v_away_team_id UUID;
  v_mvp_user_id UUID;
  v_player_id UUID;
BEGIN
  IF NOT public.is_authorized_scorer(p_match_id, v_caller) THEN
    RAISE EXCEPTION 'Not authorized to finish this match';
  END IF;

  SELECT * INTO v_match FROM public.matches WHERE id = p_match_id;
  IF v_match.id IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;

  -- IDEMPOTENCY CHECK: If already completed, return without double-counting stats
  IF v_match.status = 'completed' THEN
    RETURN jsonb_build_object('success', true, 'already_completed', true);
  END IF;

  v_winner_team_id := NULLIF(p_result->>'winner_team_id', '')::UUID;
  v_loser_team_id := NULLIF(p_result->>'loser_team_id', '')::UUID;
  v_is_draw := COALESCE((p_result->>'is_draw')::BOOLEAN, FALSE);
  v_mvp_user_id := NULLIF(p_result->>'mvp_user_id', '')::UUID;

  -- 1. Mark match completed with result and final score
  UPDATE public.matches
  SET status = 'completed',
      result = p_result,
      score = p_final_score,
      home_score = COALESCE((p_final_score->>'home_score')::INT, home_score),
      away_score = COALESCE((p_final_score->>'away_score')::INT, away_score)
  WHERE id = p_match_id;

  -- 2. Update team records
  SELECT team_id INTO v_home_team_id
  FROM public.match_participants WHERE match_id = p_match_id AND side = 'home' AND team_id IS NOT NULL LIMIT 1;

  SELECT team_id INTO v_away_team_id
  FROM public.match_participants WHERE match_id = p_match_id AND side = 'away' AND team_id IS NOT NULL LIMIT 1;

  IF v_is_draw THEN
    IF v_home_team_id IS NOT NULL THEN
      UPDATE public.teams SET draws = draws + 1 WHERE id = v_home_team_id;
    END IF;
    IF v_away_team_id IS NOT NULL THEN
      UPDATE public.teams SET draws = draws + 1 WHERE id = v_away_team_id;
    END IF;
  ELSIF v_winner_team_id IS NOT NULL THEN
    UPDATE public.teams SET wins = wins + 1 WHERE id = v_winner_team_id;
    IF v_loser_team_id IS NOT NULL THEN
      UPDATE public.teams SET losses = losses + 1 WHERE id = v_loser_team_id;
    END IF;
  END IF;

  -- 3. Update player stats for participants
  FOR v_player_id IN (
    SELECT DISTINCT user_id FROM public.match_participants
    WHERE match_id = p_match_id AND user_id IS NOT NULL
  ) LOOP
    UPDATE public.users
    SET matches_played = matches_played + 1
    WHERE id = v_player_id;
  END LOOP;

  -- Update winners & losers player stats if applicable
  IF NOT v_is_draw AND v_winner_team_id IS NOT NULL THEN
    UPDATE public.users
    SET wins = wins + 1
    WHERE id IN (
      SELECT user_id FROM public.team_members WHERE team_id = v_winner_team_id
      UNION
      SELECT user_id FROM public.match_participants WHERE match_id = p_match_id AND team_id = v_winner_team_id AND user_id IS NOT NULL
    );

    IF v_loser_team_id IS NOT NULL THEN
      UPDATE public.users
      SET losses = losses + 1
      WHERE id IN (
        SELECT user_id FROM public.team_members WHERE team_id = v_loser_team_id
        UNION
        SELECT user_id FROM public.match_participants WHERE match_id = p_match_id AND team_id = v_loser_team_id AND user_id IS NOT NULL
      );
    END IF;
  END IF;

  -- MVP award
  IF v_mvp_user_id IS NOT NULL THEN
    UPDATE public.users SET mvp_count = mvp_count + 1 WHERE id = v_mvp_user_id;
  END IF;

  -- 4. Emit match_result feed event
  INSERT INTO public.feed_events (event_type, payload)
  VALUES (
    'match_result',
    jsonb_build_object(
      'match_id', p_match_id,
      'sport_id', v_match.sport_id,
      'venue', v_match.venue,
      'result', p_result,
      'final_score', p_final_score,
      'completed_at', NOW()
    )
  );

  RETURN jsonb_build_object('success', true, 'status', 'completed');
END;
$$;
