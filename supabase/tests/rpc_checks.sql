-- VIT-AP Sports — Live Scorer SQL / RPC Verification Tests
-- Run these checks in the Supabase SQL editor or automated test runner.

-- 1. Test: Two clients inserting the same seq -> one is rejected by uq_match_events_match_seq
DO $$
DECLARE
  v_dummy_match_id UUID := gen_random_uuid();
  v_event1_id UUID := gen_random_uuid();
  v_event2_id UUID := gen_random_uuid();
  v_rejected BOOLEAN := FALSE;
BEGIN
  -- Insert dummy match for test
  INSERT INTO public.matches (id, venue, scheduled_at, status, created_by)
  VALUES (v_dummy_match_id, 'Central Ground', NOW(), 'live', NULL);

  -- Insert event 1 with seq = 1
  INSERT INTO public.match_events (id, match_id, seq, type, payload)
  VALUES (v_event1_id, v_dummy_match_id, 1, 'goal', '{"team": "home"}');

  -- Attempt insert event 2 with duplicate seq = 1
  BEGIN
    INSERT INTO public.match_events (id, match_id, seq, type, payload)
    VALUES (v_event2_id, v_dummy_match_id, 1, 'goal', '{"team": "away"}');
  EXCEPTION WHEN unique_violation THEN
    v_rejected := TRUE;
  END;

  IF NOT v_rejected THEN
    RAISE EXCEPTION 'TEST FAILED: Duplicate seq on same match was NOT rejected!';
  ELSE
    RAISE NOTICE 'TEST PASSED: Duplicate seq on same match was successfully rejected.';
  END IF;

  -- Clean up test match & events
  DELETE FROM public.matches WHERE id = v_dummy_match_id;
END $$;

-- 2. Test: Non-scorer cannot insert events via record_event
-- When auth.uid() is not match creator, scorer_id, scorer_ids, or captain:
-- record_event raises exception: 'Not authorized to score this match'

-- 3. Test: finish_match twice is idempotent (does not double-count team wins)
DO $$
DECLARE
  v_test_match_id UUID := gen_random_uuid();
  v_test_team_id UUID := gen_random_uuid();
  v_initial_wins INT;
  v_after_first INT;
  v_after_second INT;
BEGIN
  -- Setup test team and match
  INSERT INTO public.teams (id, name, wins) VALUES (v_test_team_id, 'Test Team', 0);
  INSERT INTO public.matches (id, venue, scheduled_at, status, created_by)
  VALUES (v_test_match_id, 'Court 1', NOW(), 'live', NULL);
  INSERT INTO public.match_participants (match_id, team_id, side)
  VALUES (v_test_match_id, v_test_team_id, 'home');

  -- First finish call
  PERFORM public.finish_match(
    v_test_match_id,
    jsonb_build_object('winner_team_id', v_test_team_id, 'is_draw', false),
    '{"home_score": 21, "away_score": 15}'::JSONB
  );

  SELECT wins INTO v_after_first FROM public.teams WHERE id = v_test_team_id;

  -- Second finish call (idempotent duplicate)
  PERFORM public.finish_match(
    v_test_match_id,
    jsonb_build_object('winner_team_id', v_test_team_id, 'is_draw', false),
    '{"home_score": 21, "away_score": 15}'::JSONB
  );

  SELECT wins INTO v_after_second FROM public.teams WHERE id = v_test_team_id;

  IF v_after_first = 1 AND v_after_second = 1 THEN
    RAISE NOTICE 'TEST PASSED: finish_match is idempotent (wins remained 1).';
  ELSE
    RAISE EXCEPTION 'TEST FAILED: finish_match double-counted wins! (first: %, second: %)', v_after_first, v_after_second;
  END IF;

  -- Clean up
  DELETE FROM public.matches WHERE id = v_test_match_id;
  DELETE FROM public.teams WHERE id = v_test_team_id;
END $$;
