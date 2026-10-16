-- VIT-AP Sports — Migration 012: Tournaments Schema, RLS, and RPCs
-- Adds comprehensive support for Knockout, League, and Group Stage + Knockout tournaments
-- for Cricket, Badminton, and Football.

-- 1. Extend and alter existing tournaments table safely
ALTER TABLE public.tournaments DROP CONSTRAINT IF EXISTS tournaments_format_check;
ALTER TABLE public.tournaments ADD CONSTRAINT tournaments_format_check CHECK (format IN ('knockout', 'league', 'groups_knockout'));

ALTER TABLE public.tournaments DROP CONSTRAINT IF EXISTS tournaments_status_check;
ALTER TABLE public.tournaments ADD CONSTRAINT tournaments_status_check CHECK (status IN ('draft', 'registration_open', 'registration_closed', 'ready', 'live', 'completed', 'cancelled', 'upcoming', 'active'));

ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS sport TEXT;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'open' CHECK (scope IN ('open', 'hostel', 'branch', 'year'));
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{}'::JSONB;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS eligibility JSONB NOT NULL DEFAULT '{}'::JSONB;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS organiser_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMPTZ;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS max_entries INT;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ;
ALTER TABLE public.tournaments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Backfill organiser_id from created_by if present
UPDATE public.tournaments SET organiser_id = created_by WHERE organiser_id IS NULL AND created_by IS NOT NULL;

-- 2. Create Tournament Admins Table
CREATE TABLE IF NOT EXISTS public.tournament_admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('organiser', 'admin', 'scorer')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tournament_id, user_id)
);

-- 3. Create Tournament Groups Table
CREATE TABLE IF NOT EXISTS public.tournament_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  order_index INT NOT NULL DEFAULT 0,
  config JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (tournament_id, name)
);

-- 4. Create Tournament Entries Table
CREATE TABLE IF NOT EXISTS public.tournament_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  kind TEXT NOT NULL DEFAULT 'team' CHECK (kind IN ('team', 'solo', 'pair')),
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  partner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  display_name TEXT NOT NULL,
  seed INT,
  group_id UUID REFERENCES public.tournament_groups(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn', 'disqualified')),
  metadata JSONB NOT NULL DEFAULT '{}'::JSONB,
  registered_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  registered_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tournament_entries_unique_team 
  ON public.tournament_entries (tournament_id, team_id) 
  WHERE team_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_tournament_entries_unique_user 
  ON public.tournament_entries (tournament_id, user_id) 
  WHERE user_id IS NOT NULL AND kind IN ('solo', 'player');

-- 5. Create Tournament Fixtures Table
CREATE TABLE IF NOT EXISTS public.tournament_fixtures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('group', 'knockout', 'third_place')),
  group_id UUID REFERENCES public.tournament_groups(id) ON DELETE SET NULL,
  round INT NOT NULL DEFAULT 1,
  position INT NOT NULL DEFAULT 1,
  round_label TEXT NOT NULL,
  entry_a_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  entry_b_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  source_fixture_a_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  source_fixture_b_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  source_outcome_a TEXT CHECK (source_outcome_a IN ('winner', 'loser')),
  source_outcome_b TEXT CHECK (source_outcome_b IN ('winner', 'loser')),
  is_bye BOOLEAN NOT NULL DEFAULT false,
  scheduled_at TIMESTAMPTZ,
  venue TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'live', 'completed', 'walkover', 'cancelled')),
  match_id UUID REFERENCES public.matches(id) ON DELETE SET NULL,
  result JSONB NOT NULL DEFAULT '{}'::JSONB,
  winner_entry_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  next_fixture_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  next_slot TEXT CHECK (next_slot IN ('a', 'b')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Extend matches table to link to tournament & fixture
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS tournament_id UUID REFERENCES public.tournaments(id) ON DELETE SET NULL;
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS fixture_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL;

-- 7. Create Tournament Audit Logs Table
CREATE TABLE IF NOT EXISTS public.tournament_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  fixture_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  actor_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  before JSONB NOT NULL DEFAULT '{}'::JSONB,
  after JSONB NOT NULL DEFAULT '{}'::JSONB,
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_tournaments_sport_status ON public.tournaments (sport, status);
CREATE INDEX IF NOT EXISTS idx_tournaments_organiser ON public.tournaments (organiser_id);
CREATE INDEX IF NOT EXISTS idx_tournament_entries_tournament_id ON public.tournament_entries (tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_entries_team_id ON public.tournament_entries (team_id);
CREATE INDEX IF NOT EXISTS idx_tournament_entries_user_id ON public.tournament_entries (user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_fixtures_tournament_id ON public.tournament_fixtures (tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_fixtures_group_id ON public.tournament_fixtures (group_id);
CREATE INDEX IF NOT EXISTS idx_tournament_fixtures_match_id ON public.tournament_fixtures (match_id);
CREATE INDEX IF NOT EXISTS idx_tournament_fixtures_next ON public.tournament_fixtures (next_fixture_id);
CREATE INDEX IF NOT EXISTS idx_matches_tournament_id ON public.matches (tournament_id);
CREATE INDEX IF NOT EXISTS idx_matches_fixture_id ON public.matches (fixture_id);

-- 9. Enable RLS on all tables
ALTER TABLE public.tournament_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_fixtures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tournament_audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function: is_tournament_admin
CREATE OR REPLACE FUNCTION public.is_tournament_admin(p_tournament_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.tournaments WHERE id = p_tournament_id AND (organiser_id = p_user_id OR created_by = p_user_id)
    UNION
    SELECT 1 FROM public.tournament_admins WHERE tournament_id = p_tournament_id AND user_id = p_user_id
  );
$$;

-- RLS Policies
-- Tournaments
DROP POLICY IF EXISTS "Tournaments are viewable by all" ON public.tournaments;
CREATE POLICY "Tournaments are viewable by all" ON public.tournaments
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can create tournaments" ON public.tournaments;
CREATE POLICY "Authenticated users can create tournaments" ON public.tournaments
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = organiser_id OR auth.uid() = created_by);

DROP POLICY IF EXISTS "Organisers and admins can update tournaments" ON public.tournaments;
CREATE POLICY "Organisers and admins can update tournaments" ON public.tournaments
  FOR UPDATE TO authenticated
  USING (public.is_tournament_admin(id, auth.uid()))
  WITH CHECK (public.is_tournament_admin(id, auth.uid()));

-- Tournament Admins
DROP POLICY IF EXISTS "Tournament admins are viewable by all" ON public.tournament_admins;
CREATE POLICY "Tournament admins are viewable by all" ON public.tournament_admins
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Organisers can manage admins" ON public.tournament_admins;
CREATE POLICY "Organisers can manage admins" ON public.tournament_admins
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.tournaments WHERE id = tournament_id AND (organiser_id = auth.uid() OR created_by = auth.uid())))
  WITH CHECK (EXISTS (SELECT 1 FROM public.tournaments WHERE id = tournament_id AND (organiser_id = auth.uid() OR created_by = auth.uid())));

-- Tournament Groups
DROP POLICY IF EXISTS "Tournament groups are viewable by all" ON public.tournament_groups;
CREATE POLICY "Tournament groups are viewable by all" ON public.tournament_groups
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage tournament groups" ON public.tournament_groups;
CREATE POLICY "Admins can manage tournament groups" ON public.tournament_groups
  FOR ALL TO authenticated
  USING (public.is_tournament_admin(tournament_id, auth.uid()))
  WITH CHECK (public.is_tournament_admin(tournament_id, auth.uid()));

-- Tournament Entries
DROP POLICY IF EXISTS "Tournament entries are viewable by all" ON public.tournament_entries;
CREATE POLICY "Tournament entries are viewable by all" ON public.tournament_entries
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Authenticated users can register entries" ON public.tournament_entries;
CREATE POLICY "Authenticated users can register entries" ON public.tournament_entries
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = registered_by OR auth.uid() = user_id OR public.is_tournament_admin(tournament_id, auth.uid()));

DROP POLICY IF EXISTS "Admins or registrants can update entries" ON public.tournament_entries;
CREATE POLICY "Admins or registrants can update entries" ON public.tournament_entries
  FOR UPDATE TO authenticated
  USING (auth.uid() = registered_by OR auth.uid() = user_id OR public.is_tournament_admin(tournament_id, auth.uid()))
  WITH CHECK (auth.uid() = registered_by OR auth.uid() = user_id OR public.is_tournament_admin(tournament_id, auth.uid()));

-- Tournament Fixtures
DROP POLICY IF EXISTS "Tournament fixtures are viewable by all" ON public.tournament_fixtures;
CREATE POLICY "Tournament fixtures are viewable by all" ON public.tournament_fixtures
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Admins can manage fixtures" ON public.tournament_fixtures;
CREATE POLICY "Admins can manage fixtures" ON public.tournament_fixtures
  FOR ALL TO authenticated
  USING (public.is_tournament_admin(tournament_id, auth.uid()))
  WITH CHECK (public.is_tournament_admin(tournament_id, auth.uid()));

-- Tournament Audit Logs
DROP POLICY IF EXISTS "Admins can view audit logs" ON public.tournament_audit_logs;
CREATE POLICY "Admins can view audit logs" ON public.tournament_audit_logs
  FOR SELECT TO authenticated
  USING (public.is_tournament_admin(tournament_id, auth.uid()));

-- 10. Realtime Publications
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.tournaments;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.tournament_entries;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.tournament_fixtures;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
  END IF;
END $$;

-- 11. Security Definer RPCs

-- 11.1 Create Tournament
CREATE OR REPLACE FUNCTION public.create_tournament(
  p_name TEXT,
  p_sport TEXT,
  p_format TEXT,
  p_scope TEXT DEFAULT 'open',
  p_config JSONB DEFAULT '{}'::JSONB,
  p_eligibility JSONB DEFAULT '{}'::JSONB,
  p_max_entries INT DEFAULT NULL,
  p_registration_deadline TIMESTAMPTZ DEFAULT NULL,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_sport_id UUID;
  v_tournament RECORD;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT id INTO v_sport_id FROM public.sports WHERE LOWER(name) = LOWER(p_sport) LIMIT 1;

  INSERT INTO public.tournaments (
    name, sport, sport_id, format, status, scope, config, eligibility,
    organiser_id, created_by, max_entries, registration_deadline, start_date, end_date
  )
  VALUES (
    p_name, LOWER(p_sport), v_sport_id, p_format, 'draft', COALESCE(p_scope, 'open'),
    COALESCE(p_config, '{}'::JSONB), COALESCE(p_eligibility, '{}'::JSONB),
    v_caller, v_caller, p_max_entries, p_registration_deadline, p_start_date, p_end_date
  )
  RETURNING * INTO v_tournament;

  INSERT INTO public.tournament_admins (tournament_id, user_id, role)
  VALUES (v_tournament.id, v_caller, 'organiser')
  ON CONFLICT DO NOTHING;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, after)
  VALUES (v_tournament.id, v_caller, 'tournament_created', to_jsonb(v_tournament));

  RETURN to_jsonb(v_tournament);
END;
$$;

-- 11.2 Register Tournament Entry
CREATE OR REPLACE FUNCTION public.register_tournament_entry(
  p_tournament_id UUID,
  p_kind TEXT,
  p_team_id UUID DEFAULT NULL,
  p_user_id UUID DEFAULT NULL,
  p_partner_id UUID DEFAULT NULL,
  p_display_name TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_tournament RECORD;
  v_display_name TEXT := p_display_name;
  v_user_profile RECORD;
  v_partner_profile RECORD;
  v_team RECORD;
  v_entry RECORD;
  v_current_entries_count INT;
  v_target_user_id UUID;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_tournament FROM public.tournaments WHERE id = p_tournament_id;
  IF v_tournament.id IS NULL THEN
    RAISE EXCEPTION 'Tournament not found';
  END IF;

  IF v_tournament.status != 'registration_open' AND NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Tournament registration is not currently open (status: %)', v_tournament.status;
  END IF;

  IF v_tournament.registration_deadline IS NOT NULL AND NOW() > v_tournament.registration_deadline AND NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Tournament registration deadline has passed';
  END IF;

  IF v_tournament.max_entries IS NOT NULL THEN
    SELECT COUNT(*) INTO v_current_entries_count 
    FROM public.tournament_entries 
    WHERE tournament_id = p_tournament_id AND status != 'withdrawn' AND status != 'rejected';
    
    IF v_current_entries_count >= v_tournament.max_entries AND NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
      RAISE EXCEPTION 'Tournament registration is full (%/% entries)', v_current_entries_count, v_tournament.max_entries;
    END IF;
  END IF;

  -- Eligibility Check
  IF p_kind = 'team' THEN
    IF p_team_id IS NULL THEN
      RAISE EXCEPTION 'team_id is required for team entry';
    END IF;
    SELECT * INTO v_team FROM public.teams WHERE id = p_team_id;
    IF v_team.id IS NULL THEN
      RAISE EXCEPTION 'Team not found';
    END IF;
    v_display_name := COALESCE(v_display_name, v_team.name);
    
    -- Check if team or team name is already registered
    IF EXISTS (
      SELECT 1 FROM public.tournament_entries 
      WHERE tournament_id = p_tournament_id 
        AND team_id = p_team_id 
        AND status NOT IN ('withdrawn', 'rejected')
    ) THEN
      RAISE EXCEPTION 'This team is already registered for this tournament';
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.tournament_entries 
      WHERE tournament_id = p_tournament_id 
        AND LOWER(TRIM(display_name)) = LOWER(TRIM(v_display_name))
        AND status NOT IN ('withdrawn', 'rejected')
    ) THEN
      RAISE EXCEPTION 'A team with the name "%" is already registered for this tournament', v_display_name;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.team_members WHERE team_id = p_team_id AND user_id = v_caller) 
       AND v_team.captain_id != v_caller 
       AND NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
      RAISE EXCEPTION 'Only team captain or members can register this team';
    END IF;
  ELSE
    v_target_user_id := COALESCE(p_user_id, v_caller);
    SELECT * INTO v_user_profile FROM public.users WHERE id = v_target_user_id;
    IF v_user_profile.id IS NULL THEN
      RAISE EXCEPTION 'User profile not found';
    END IF;
    v_display_name := COALESCE(v_display_name, v_user_profile.name);

    IF p_kind = 'pair' AND p_partner_id IS NOT NULL THEN
      SELECT * INTO v_partner_profile FROM public.users WHERE id = p_partner_id;
      v_display_name := v_display_name || ' / ' || COALESCE(v_partner_profile.name, 'Partner');
    END IF;

    -- Check if user is already registered
    IF EXISTS (
      SELECT 1 FROM public.tournament_entries 
      WHERE tournament_id = p_tournament_id 
        AND (user_id = v_target_user_id OR LOWER(TRIM(display_name)) = LOWER(TRIM(v_display_name)))
        AND status NOT IN ('withdrawn', 'rejected')
    ) THEN
      RAISE EXCEPTION 'Participant is already registered for this tournament';
    END IF;

    -- Check Scope Eligibility (Hostel, Branch, Year)
    IF v_tournament.scope = 'hostel' AND v_tournament.eligibility ? 'hostel_block' THEN
      IF v_user_profile.hostel_block IS NULL OR LOWER(v_user_profile.hostel_block) != LOWER(v_tournament.eligibility->>'hostel_block') THEN
        RAISE EXCEPTION 'Ineligible: Tournament is restricted to hostel block %', v_tournament.eligibility->>'hostel_block';
      END IF;
    ELSIF v_tournament.scope = 'branch' AND v_tournament.eligibility ? 'branch' THEN
      IF v_user_profile.branch IS NULL OR LOWER(v_user_profile.branch) != LOWER(v_tournament.eligibility->>'branch') THEN
        RAISE EXCEPTION 'Ineligible: Tournament is restricted to branch %', v_tournament.eligibility->>'branch';
      END IF;
    ELSIF v_tournament.scope = 'year' AND v_tournament.eligibility ? 'year' THEN
      IF v_user_profile.year IS NULL OR v_user_profile.year != (v_tournament.eligibility->>'year') THEN
        RAISE EXCEPTION 'Ineligible: Tournament is restricted to year %', v_tournament.eligibility->>'year';
      END IF;
    END IF;
  END IF;

  INSERT INTO public.tournament_entries (
    tournament_id, kind, team_id, user_id, partner_id, display_name,
    status, metadata, registered_by
  )
  VALUES (
    p_tournament_id, p_kind, p_team_id, v_target_user_id, p_partner_id, v_display_name,
    'pending', COALESCE(p_metadata, '{}'::JSONB), v_caller
  )
  RETURNING * INTO v_entry;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, after)
  VALUES (p_tournament_id, v_caller, 'entry_registered', to_jsonb(v_entry));

  RETURN to_jsonb(v_entry);
END;
$$;

-- 11.3 Withdraw Entry
CREATE OR REPLACE FUNCTION public.withdraw_tournament_entry(
  p_tournament_id UUID,
  p_entry_id UUID,
  p_reason TEXT DEFAULT 'Participant withdrawal'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_entry RECORD;
  v_fix RECORD;
  v_opp_id UUID;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO v_entry FROM public.tournament_entries WHERE id = p_entry_id AND tournament_id = p_tournament_id;
  IF v_entry.id IS NULL THEN
    RAISE EXCEPTION 'Entry not found';
  END IF;

  IF NOT public.is_tournament_admin(p_tournament_id, v_caller) 
     AND v_entry.registered_by != v_caller 
     AND v_entry.user_id != v_caller THEN
    RAISE EXCEPTION 'Not authorized to withdraw this entry';
  END IF;

  UPDATE public.tournament_entries
  SET status = 'withdrawn'
  WHERE id = p_entry_id;

  -- Cascade walkovers to remaining fixtures
  FOR v_fix IN 
    SELECT * FROM public.tournament_fixtures 
    WHERE tournament_id = p_tournament_id 
      AND (entry_a_id = p_entry_id OR entry_b_id = p_entry_id)
      AND status IN ('pending', 'scheduled')
  LOOP
    v_opp_id := CASE WHEN v_fix.entry_a_id = p_entry_id THEN v_fix.entry_b_id ELSE v_fix.entry_a_id END;
    
    UPDATE public.tournament_fixtures
    SET status = 'walkover',
        winner_entry_id = v_opp_id,
        result = jsonb_build_object(
          'result_type', 'walkover',
          'winner_entry_id', v_opp_id,
          'withdrawn_entry_id', p_entry_id,
          'reason', p_reason
        ),
        updated_at = NOW()
    WHERE id = v_fix.id;

    IF v_opp_id IS NOT NULL AND v_fix.next_fixture_id IS NOT NULL THEN
      IF v_fix.next_slot = 'a' THEN
        UPDATE public.tournament_fixtures 
        SET entry_a_id = v_opp_id,
            status = CASE WHEN entry_b_id IS NOT NULL THEN 'scheduled' ELSE status END,
            updated_at = NOW()
        WHERE id = v_fix.next_fixture_id;
      ELSE
        UPDATE public.tournament_fixtures 
        SET entry_b_id = v_opp_id,
            status = CASE WHEN entry_a_id IS NOT NULL THEN 'scheduled' ELSE status END,
            updated_at = NOW()
        WHERE id = v_fix.next_fixture_id;
      END IF;
    END IF;
  END LOOP;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, reason, before, after)
  VALUES (p_tournament_id, v_caller, 'entry_withdrawn', p_reason, to_jsonb(v_entry), jsonb_build_object('status', 'withdrawn'));

  RETURN jsonb_build_object('success', true, 'entry_id', p_entry_id);
END;
$$;

-- 11.4 Approve Entry
CREATE OR REPLACE FUNCTION public.approve_tournament_entry(
  p_tournament_id UUID,
  p_entry_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_entry RECORD;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament organisers can approve entries';
  END IF;

  SELECT * INTO v_entry 
  FROM public.tournament_entries 
  WHERE id = p_entry_id AND tournament_id = p_tournament_id;

  IF v_entry.id IS NULL THEN
    RAISE EXCEPTION 'Entry not found';
  END IF;

  UPDATE public.tournament_entries
  SET status = 'approved'
  WHERE id = p_entry_id AND tournament_id = p_tournament_id
  RETURNING * INTO v_entry;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, before, after)
  VALUES (p_tournament_id, v_caller, 'entry_approved', jsonb_build_object('status', 'pending'), to_jsonb(v_entry));

  RETURN to_jsonb(v_entry);
END;
$$;

-- 11.5 Reject Entry
CREATE OR REPLACE FUNCTION public.reject_tournament_entry(
  p_tournament_id UUID,
  p_entry_id UUID,
  p_reason TEXT DEFAULT 'Entry rejected by organiser'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_entry RECORD;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament organisers can reject entries';
  END IF;

  SELECT * INTO v_entry 
  FROM public.tournament_entries 
  WHERE id = p_entry_id AND tournament_id = p_tournament_id;

  IF v_entry.id IS NULL THEN
    RAISE EXCEPTION 'Entry not found';
  END IF;

  UPDATE public.tournament_entries
  SET status = 'rejected'
  WHERE id = p_entry_id AND tournament_id = p_tournament_id
  RETURNING * INTO v_entry;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, reason, before, after)
  VALUES (p_tournament_id, v_caller, 'entry_rejected', p_reason, jsonb_build_object('status', v_entry.status), to_jsonb(v_entry));

  RETURN to_jsonb(v_entry);
END;
$$;

-- 11.6 Generate Tournament Draw
CREATE OR REPLACE FUNCTION public.generate_tournament_draw(
  p_tournament_id UUID,
  p_fixtures JSONB,
  p_groups JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_group_item JSONB;
  v_fix_item JSONB;
  v_grp_id UUID;
BEGIN
  IF v_caller IS NULL OR NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament organisers can generate the draw';
  END IF;

  -- 1. Insert groups if any
  IF jsonb_array_length(p_groups) > 0 THEN
    FOR v_group_item IN SELECT * FROM jsonb_array_elements(p_groups)
    LOOP
      v_grp_id := NULLIF(v_group_item->>'id', '')::UUID;
      IF v_grp_id IS NULL THEN
        v_grp_id := gen_random_uuid();
      END IF;

      INSERT INTO public.tournament_groups (id, tournament_id, name, order_index, config)
      VALUES (
        v_grp_id,
        p_tournament_id,
        v_group_item->>'name',
        COALESCE((v_group_item->>'order_index')::INT, 0),
        COALESCE(v_group_item->'config', '{}'::JSONB)
      )
      ON CONFLICT (tournament_id, name) DO UPDATE
      SET order_index = EXCLUDED.order_index,
          config = EXCLUDED.config;
    END LOOP;
  END IF;

  -- 2. Insert fixtures
  FOR v_fix_item IN SELECT * FROM jsonb_array_elements(p_fixtures)
  LOOP
    INSERT INTO public.tournament_fixtures (
      id, tournament_id, stage, group_id, round, position, round_label,
      entry_a_id, entry_b_id, source_fixture_a_id, source_fixture_b_id,
      source_outcome_a, source_outcome_b, is_bye, status, result,
      winner_entry_id, next_fixture_id, next_slot, scheduled_at, venue
    )
    VALUES (
      (v_fix_item->>'id')::UUID,
      p_tournament_id,
      v_fix_item->>'stage',
      NULLIF(v_fix_item->>'group_id', '')::UUID,
      COALESCE((v_fix_item->>'round')::INT, 1),
      COALESCE((v_fix_item->>'position')::INT, 1),
      v_fix_item->>'round_label',
      NULLIF(v_fix_item->>'entry_a_id', '')::UUID,
      NULLIF(v_fix_item->>'entry_b_id', '')::UUID,
      NULLIF(v_fix_item->>'source_fixture_a_id', '')::UUID,
      NULLIF(v_fix_item->>'source_fixture_b_id', '')::UUID,
      v_fix_item->>'source_outcome_a',
      v_fix_item->>'source_outcome_b',
      COALESCE((v_fix_item->>'is_bye')::BOOLEAN, false),
      COALESCE(v_fix_item->>'status', 'pending'),
      COALESCE(v_fix_item->'result', '{}'::JSONB),
      NULLIF(v_fix_item->>'winner_entry_id', '')::UUID,
      NULLIF(v_fix_item->>'next_fixture_id', '')::UUID,
      v_fix_item->>'next_slot',
      NULLIF(v_fix_item->>'scheduled_at', '')::TIMESTAMPTZ,
      v_fix_item->>'venue'
    )
    ON CONFLICT (id) DO UPDATE
    SET stage = EXCLUDED.stage,
        group_id = EXCLUDED.group_id,
        round = EXCLUDED.round,
        position = EXCLUDED.position,
        round_label = EXCLUDED.round_label,
        entry_a_id = EXCLUDED.entry_a_id,
        entry_b_id = EXCLUDED.entry_b_id,
        source_fixture_a_id = EXCLUDED.source_fixture_a_id,
        source_fixture_b_id = EXCLUDED.source_fixture_b_id,
        source_outcome_a = EXCLUDED.source_outcome_a,
        source_outcome_b = EXCLUDED.source_outcome_b,
        is_bye = EXCLUDED.is_bye,
        status = EXCLUDED.status,
        result = EXCLUDED.result,
        winner_entry_id = EXCLUDED.winner_entry_id,
        next_fixture_id = EXCLUDED.next_fixture_id,
        next_slot = EXCLUDED.next_slot,
        updated_at = NOW();
  END LOOP;

  -- 3. Transition tournament to live
  UPDATE public.tournaments
  SET status = 'live',
      updated_at = NOW()
  WHERE id = p_tournament_id;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, after)
  VALUES (p_tournament_id, v_caller, 'draw_generated', jsonb_build_object('fixtures_count', jsonb_array_length(p_fixtures)));

  RETURN jsonb_build_object('success', true, 'tournament_id', p_tournament_id);
END;
$$;

-- 11.5 Schedule Tournament Fixture
CREATE OR REPLACE FUNCTION public.schedule_tournament_fixture(
  p_fixture_id UUID,
  p_scheduled_at TIMESTAMPTZ,
  p_venue TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_fix RECORD;
BEGIN
  SELECT * INTO v_fix FROM public.tournament_fixtures WHERE id = p_fixture_id;
  IF v_fix.id IS NULL THEN
    RAISE EXCEPTION 'Fixture not found';
  END IF;

  IF v_caller IS NULL OR NOT public.is_tournament_admin(v_fix.tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament organisers or admins can schedule fixtures';
  END IF;

  UPDATE public.tournament_fixtures
  SET scheduled_at = p_scheduled_at,
      venue = COALESCE(p_venue, venue),
      status = CASE WHEN status = 'pending' AND entry_a_id IS NOT NULL AND entry_b_id IS NOT NULL THEN 'scheduled' ELSE status END,
      updated_at = NOW()
  WHERE id = p_fixture_id;

  IF v_fix.match_id IS NOT NULL THEN
    UPDATE public.matches
    SET scheduled_at = p_scheduled_at,
        venue = COALESCE(p_venue, venue)
    WHERE id = v_fix.match_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'fixture_id', p_fixture_id, 'scheduled_at', p_scheduled_at, 'venue', p_venue);
END;
$$;

-- 11.6 Create Match For Fixture
CREATE OR REPLACE FUNCTION public.create_match_for_fixture(
  p_fixture_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_fix RECORD;
  v_tournament RECORD;
  v_entry_a RECORD;
  v_entry_b RECORD;
  v_new_match_id UUID;
  v_sport_name TEXT;
BEGIN
  SELECT * INTO v_fix FROM public.tournament_fixtures WHERE id = p_fixture_id;
  IF v_fix.id IS NULL THEN
    RAISE EXCEPTION 'Fixture not found';
  END IF;

  IF v_caller IS NULL OR NOT public.is_tournament_admin(v_fix.tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament admins can initialize match for this fixture';
  END IF;

  IF v_fix.match_id IS NOT NULL THEN
    RETURN jsonb_build_object('success', true, 'match_id', v_fix.match_id, 'already_exists', true);
  END IF;

  IF v_fix.entry_a_id IS NULL OR v_fix.entry_b_id IS NULL THEN
    RAISE EXCEPTION 'Both entrants must be determined before creating match';
  END IF;

  SELECT * INTO v_tournament FROM public.tournaments WHERE id = v_fix.tournament_id;
  SELECT * INTO v_entry_a FROM public.tournament_entries WHERE id = v_fix.entry_a_id;
  SELECT * INTO v_entry_b FROM public.tournament_entries WHERE id = v_fix.entry_b_id;

  v_sport_name := LOWER(COALESCE(v_tournament.sport, 'cricket'));

  INSERT INTO public.matches (
    sport_id, scheduled_at, venue, status, tournament_id, fixture_id, created_by
  )
  VALUES (
    COALESCE(v_tournament.sport_id, (SELECT id FROM public.sports WHERE LOWER(name) = v_sport_name LIMIT 1)),
    COALESCE(v_fix.scheduled_at, NOW()),
    v_fix.venue,
    'upcoming',
    v_tournament.id,
    p_fixture_id,
    v_caller
  )
  RETURNING id INTO v_new_match_id;

  -- Add participants
  IF v_entry_a.team_id IS NOT NULL THEN
    INSERT INTO public.match_participants (match_id, team_id, side)
    VALUES (v_new_match_id, v_entry_a.team_id, 'home');
  ELSIF v_entry_a.user_id IS NOT NULL THEN
    INSERT INTO public.match_participants (match_id, user_id, side)
    VALUES (v_new_match_id, v_entry_a.user_id, 'home');
  END IF;

  IF v_entry_b.team_id IS NOT NULL THEN
    INSERT INTO public.match_participants (match_id, team_id, side)
    VALUES (v_new_match_id, v_entry_b.team_id, 'away');
  ELSIF v_entry_b.user_id IS NOT NULL THEN
    INSERT INTO public.match_participants (match_id, user_id, side)
    VALUES (v_new_match_id, v_entry_b.user_id, 'away');
  END IF;

  -- Link back to fixture
  UPDATE public.tournament_fixtures
  SET match_id = v_new_match_id,
      status = 'scheduled',
      updated_at = NOW()
  WHERE id = p_fixture_id;

  RETURN jsonb_build_object('success', true, 'match_id', v_new_match_id, 'fixture_id', p_fixture_id);
END;
$$;

-- 11.7 Internal Hook: Handle Tournament Match Finished
CREATE OR REPLACE FUNCTION public.handle_tournament_match_finished(
  p_tournament_id UUID,
  p_fixture_id UUID,
  p_result JSONB,
  p_final_score JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fix RECORD;
  v_winner_team_id UUID;
  v_loser_team_id UUID;
  v_winner_entry_id UUID;
  v_loser_entry_id UUID;
  v_next_fix RECORD;
  v_third_fix RECORD;
BEGIN
  SELECT * INTO v_fix FROM public.tournament_fixtures WHERE id = p_fixture_id AND tournament_id = p_tournament_id;
  IF v_fix.id IS NULL THEN
    RETURN;
  END IF;

  v_winner_team_id := NULLIF(p_result->>'winner_team_id', '')::UUID;
  v_loser_team_id := NULLIF(p_result->>'loser_team_id', '')::UUID;

  -- Resolve winner entry ID
  IF v_winner_team_id IS NOT NULL THEN
    SELECT id INTO v_winner_entry_id 
    FROM public.tournament_entries 
    WHERE tournament_id = p_tournament_id AND (team_id = v_winner_team_id OR user_id = v_winner_team_id)
    LIMIT 1;
  ELSE
    v_winner_entry_id := NULLIF(p_result->>'winner_entry_id', '')::UUID;
  END IF;

  -- Resolve loser entry ID
  IF v_loser_team_id IS NOT NULL THEN
    SELECT id INTO v_loser_entry_id 
    FROM public.tournament_entries 
    WHERE tournament_id = p_tournament_id AND (team_id = v_loser_team_id OR user_id = v_loser_team_id)
    LIMIT 1;
  ELSE
    v_loser_entry_id := CASE WHEN v_winner_entry_id = v_fix.entry_a_id THEN v_fix.entry_b_id ELSE v_fix.entry_a_id END;
  END IF;

  -- 1. Mark fixture completed
  UPDATE public.tournament_fixtures
  SET status = 'completed',
      result = p_result,
      winner_entry_id = v_winner_entry_id,
      updated_at = NOW()
  WHERE id = p_fixture_id;

  -- 2. Advance winner into next fixture
  IF v_fix.next_fixture_id IS NOT NULL AND v_winner_entry_id IS NOT NULL THEN
    IF v_fix.next_slot = 'a' THEN
      UPDATE public.tournament_fixtures
      SET entry_a_id = v_winner_entry_id,
          status = CASE WHEN entry_b_id IS NOT NULL THEN 'scheduled' ELSE status END,
          updated_at = NOW()
      WHERE id = v_fix.next_fixture_id;
    ELSE
      UPDATE public.tournament_fixtures
      SET entry_b_id = v_winner_entry_id,
          status = CASE WHEN entry_a_id IS NOT NULL THEN 'scheduled' ELSE status END,
          updated_at = NOW()
      WHERE id = v_fix.next_fixture_id;
    END IF;
  END IF;

  -- 3. Route loser to third-place playoff if applicable
  FOR v_third_fix IN
    SELECT * FROM public.tournament_fixtures
    WHERE tournament_id = p_tournament_id
      AND stage = 'third_place'
      AND (source_fixture_a_id = p_fixture_id OR source_fixture_b_id = p_fixture_id)
  LOOP
    IF v_third_fix.source_fixture_a_id = p_fixture_id THEN
      UPDATE public.tournament_fixtures
      SET entry_a_id = v_loser_entry_id,
          status = CASE WHEN entry_b_id IS NOT NULL THEN 'scheduled' ELSE status END,
          updated_at = NOW()
      WHERE id = v_third_fix.id;
    ELSE
      UPDATE public.tournament_fixtures
      SET entry_b_id = v_loser_entry_id,
          status = CASE WHEN entry_a_id IS NOT NULL THEN 'scheduled' ELSE status END,
          updated_at = NOW()
      WHERE id = v_third_fix.id;
    END IF;
  END LOOP;

  -- 4. If this is Final, mark tournament completed!
  IF v_fix.round_label = 'Final' THEN
    UPDATE public.tournaments
    SET status = 'completed',
        updated_at = NOW()
    WHERE id = p_tournament_id;
  END IF;
END;
$$;

-- 11.8 Update finish_match to invoke tournament hook
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
  v_mvp_user_id UUID;
  v_stat_record RECORD;
  v_sport_name TEXT;
  v_squad_user_id UUID;
BEGIN
  IF NOT public.is_authorized_scorer(p_match_id, v_caller) THEN
    RAISE EXCEPTION 'Not authorized to finish this match';
  END IF;

  SELECT * INTO v_match FROM public.matches WHERE id = p_match_id;
  IF v_match.id IS NULL THEN
    RAISE EXCEPTION 'Match not found';
  END IF;

  IF v_match.status = 'completed' THEN
    RETURN jsonb_build_object('success', true, 'already_completed', true);
  END IF;

  v_winner_team_id := NULLIF(p_result->>'winner_team_id', '')::UUID;
  v_loser_team_id := NULLIF(p_result->>'loser_team_id', '')::UUID;
  v_is_draw := COALESCE((p_result->>'is_draw')::BOOLEAN, (p_result->>'is_tie')::BOOLEAN, FALSE);
  v_mvp_user_id := NULLIF(p_result->>'mvp_user_id', '')::UUID;

  -- Auto-derive loser_team_id if missing in a 2-team match
  IF v_winner_team_id IS NOT NULL AND v_loser_team_id IS NULL THEN
    SELECT team_id INTO v_loser_team_id
    FROM public.match_participants
    WHERE match_id = p_match_id AND team_id IS NOT NULL AND team_id != v_winner_team_id
    LIMIT 1;
  END IF;

  -- 1. Mark match completed with result and final score
  UPDATE public.matches
  SET status = 'completed',
      result = p_result,
      score = p_final_score,
      home_score = COALESCE((p_final_score->>'home_score')::INT, home_score),
      away_score = COALESCE((p_final_score->>'away_score')::INT, away_score)
  WHERE id = p_match_id;

  -- 2. Update team records
  IF v_is_draw THEN
    UPDATE public.teams SET draws = draws + 1 WHERE id IN (
      SELECT team_id FROM public.match_participants WHERE match_id = p_match_id AND team_id IS NOT NULL
    );
  ELSIF v_winner_team_id IS NOT NULL THEN
    UPDATE public.teams SET wins = wins + 1 WHERE id = v_winner_team_id;
    IF v_loser_team_id IS NOT NULL THEN
      UPDATE public.teams SET losses = losses + 1 WHERE id = v_loser_team_id;
    END IF;
  END IF;

  -- Determine sport name
  SELECT LOWER(name) INTO v_sport_name FROM public.sports WHERE id = v_match.sport_id;
  v_sport_name := COALESCE(v_sport_name, LOWER(v_match.sport_id::TEXT), 'cricket');

  -- 3. Upsert player match stats from p_final_score->'player_stats'
  IF p_final_score ? 'player_stats' THEN
    FOR v_stat_record IN SELECT * FROM jsonb_each(p_final_score->'player_stats')
    LOOP
      DECLARE
        v_player_id UUID;
        v_player_team_id UUID;
        v_new_counters JSONB := v_stat_record.value;
      BEGIN
        IF v_stat_record.key ~ '^[0-9a-fA-F-]{36}$' THEN
          v_player_id := v_stat_record.key::UUID;
        ELSE
          SELECT user_id INTO v_player_id
          FROM public.team_members
          WHERE LOWER(position) = LOWER(v_stat_record.key)
          LIMIT 1;
        END IF;

        IF v_player_id IS NOT NULL THEN
          SELECT team_id INTO v_player_team_id
          FROM public.team_members
          WHERE user_id = v_player_id
            AND team_id IN (
              SELECT team_id FROM public.match_participants WHERE match_id = p_match_id AND team_id IS NOT NULL
            )
          LIMIT 1;

          IF v_player_team_id IS NULL THEN
            v_player_team_id := NULLIF(v_new_counters->>'team_id', '')::UUID;
          END IF;

          IF v_winner_team_id IS NOT NULL AND v_player_team_id = v_winner_team_id THEN
            v_new_counters := jsonb_set(v_new_counters, '{matches_won}', '1'::JSONB, true);
          ELSIF v_loser_team_id IS NOT NULL AND v_player_team_id = v_loser_team_id THEN
            v_new_counters := jsonb_set(v_new_counters, '{matches_lost}', '1'::JSONB, true);
          END IF;

          INSERT INTO public.player_match_stats (
            match_id, player_id, sport, team_id, counters
          )
          VALUES (
            p_match_id, v_player_id, v_sport_name, v_player_team_id, v_new_counters
          )
          ON CONFLICT (match_id, player_id) DO UPDATE
          SET counters = EXCLUDED.counters,
              team_id = COALESCE(EXCLUDED.team_id, player_match_stats.team_id);

          UPDATE public.users
          SET matches_played = matches_played + 1,
              wins = wins + CASE WHEN v_winner_team_id IS NOT NULL AND v_player_team_id = v_winner_team_id THEN 1 ELSE 0 END,
              losses = losses + CASE WHEN v_loser_team_id IS NOT NULL AND v_player_team_id = v_loser_team_id THEN 1 ELSE 0 END
          WHERE id = v_player_id;
        END IF;
      END;
    END LOOP;
  END IF;

  -- 4. Credit winning team squad members not in player_stats
  IF v_winner_team_id IS NOT NULL THEN
    FOR v_squad_user_id IN
      SELECT tm.user_id FROM public.team_members tm WHERE tm.team_id = v_winner_team_id AND tm.user_id IS NOT NULL
      UNION
      SELECT mp.user_id FROM public.match_participants mp WHERE mp.match_id = p_match_id AND mp.team_id = v_winner_team_id AND mp.user_id IS NOT NULL
    LOOP
      IF NOT EXISTS (SELECT 1 FROM public.player_match_stats WHERE match_id = p_match_id AND player_id = v_squad_user_id) THEN
        IF EXISTS (SELECT 1 FROM public.users WHERE id = v_squad_user_id) THEN
          INSERT INTO public.player_match_stats (match_id, player_id, sport, team_id, counters)
          VALUES (p_match_id, v_squad_user_id, v_sport_name, v_winner_team_id, '{"matches_won": 1}'::JSONB)
          ON CONFLICT (match_id, player_id) DO NOTHING;

          UPDATE public.users SET matches_played = matches_played + 1, wins = wins + 1 WHERE id = v_squad_user_id;
        END IF;
      END IF;
    END LOOP;
  END IF;

  -- 5. Credit losing team squad members not in player_stats
  IF v_loser_team_id IS NOT NULL THEN
    FOR v_squad_user_id IN
      SELECT tm.user_id FROM public.team_members tm WHERE tm.team_id = v_loser_team_id AND tm.user_id IS NOT NULL
      UNION
      SELECT mp.user_id FROM public.match_participants mp WHERE mp.match_id = p_match_id AND mp.team_id = v_loser_team_id AND mp.user_id IS NOT NULL
    LOOP
      IF NOT EXISTS (SELECT 1 FROM public.player_match_stats WHERE match_id = p_match_id AND player_id = v_squad_user_id) THEN
        IF EXISTS (SELECT 1 FROM public.users WHERE id = v_squad_user_id) THEN
          INSERT INTO public.player_match_stats (match_id, player_id, sport, team_id, counters)
          VALUES (p_match_id, v_squad_user_id, v_sport_name, v_loser_team_id, '{"matches_lost": 1}'::JSONB)
          ON CONFLICT (match_id, player_id) DO NOTHING;

          UPDATE public.users SET matches_played = matches_played + 1, losses = losses + 1 WHERE id = v_squad_user_id;
        END IF;
      END IF;
    END LOOP;
  END IF;

  -- 6. Emit match_result feed event
  INSERT INTO public.feed_events (event_type, payload)
  VALUES (
    'match_result',
    jsonb_build_object(
      'match_id', p_match_id,
      'winner_team_id', v_winner_team_id,
      'loser_team_id', v_loser_team_id,
      'is_draw', v_is_draw,
      'score', p_final_score,
      'result', p_result
    )
  );

  -- 7. Tournament Hook: If match belongs to a tournament fixture, advance bracket!
  IF v_match.tournament_id IS NOT NULL AND v_match.fixture_id IS NOT NULL THEN
    PERFORM public.handle_tournament_match_finished(v_match.tournament_id, v_match.fixture_id, p_result, p_final_score);
  END IF;

  RETURN jsonb_build_object(
    'success', true, 
    'match_id', p_match_id, 
    'winner_team_id', v_winner_team_id,
    'loser_team_id', v_loser_team_id
  );
END;
$$;

-- 11.9 Update Tournament Status
CREATE OR REPLACE FUNCTION public.update_tournament_status(
  p_tournament_id UUID,
  p_status TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller UUID := auth.uid();
  v_tournament RECORD;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF NOT public.is_tournament_admin(p_tournament_id, v_caller) THEN
    RAISE EXCEPTION 'Only tournament organisers can change tournament status';
  END IF;

  IF p_status NOT IN ('draft', 'registration_open', 'registration_closed', 'ready', 'live', 'completed', 'cancelled') THEN
    RAISE EXCEPTION 'Invalid tournament status: %', p_status;
  END IF;

  SELECT * INTO v_tournament FROM public.tournaments WHERE id = p_tournament_id;
  IF v_tournament.id IS NULL THEN
    RAISE EXCEPTION 'Tournament not found';
  END IF;

  UPDATE public.tournaments
  SET status = p_status,
      updated_at = NOW()
  WHERE id = p_tournament_id
  RETURNING * INTO v_tournament;

  INSERT INTO public.tournament_audit_logs (tournament_id, actor_id, action, before, after)
  VALUES (
    p_tournament_id, 
    v_caller, 
    'status_updated', 
    jsonb_build_object('status', v_tournament.status), 
    to_jsonb(v_tournament)
  );

  RETURN to_jsonb(v_tournament);
END;
$$;

