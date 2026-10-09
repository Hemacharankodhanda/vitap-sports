-- VIT-AP Sports — Migration 007: Take Over Scoring RPC
-- Allows authorized scorers (creator or team captain) to set themselves as the active scorer.

CREATE OR REPLACE FUNCTION public.take_over_scoring(p_match_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_status TEXT;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT public.is_authorized_scorer(p_match_id, v_caller) THEN
    RAISE EXCEPTION 'Not authorized to score this match';
  END IF;

  SELECT status INTO v_status FROM public.matches WHERE id = p_match_id;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;

  IF v_status IN ('completed', 'abandoned', 'cancelled') THEN
    RAISE EXCEPTION 'Cannot take over scoring on a completed or cancelled match';
  END IF;

  UPDATE public.matches
  SET scorer_id = v_caller,
      scorer_ids = array_append(array_remove(COALESCE(scorer_ids, ARRAY[]::UUID[]), v_caller), v_caller)
  WHERE id = p_match_id;

  RETURN jsonb_build_object('success', true, 'scorer_id', v_caller);
END;
$$;
