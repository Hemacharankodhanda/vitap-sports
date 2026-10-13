# Tournaments Architecture & Technical Design

**Repository**: `VIT-AP Sports`  
**Date**: October 13, 2026  
**Status**: Proposal for Review (Phase 1)

---

## 1. Architecture Principles & Constraints

1. **Pure-Dart Rules & Determinism**: All tournament logic (bracket generation, circle method round-robin, group snake allocations, standings calculations, NRR computation, and tie-breaking algorithms) lives in UI-free, immutable, deterministic pure Dart. Every algorithm is comprehensively unit-tested.
2. **Supabase Free-Tier Zero-Cost Compliance**:
   - Zero additional monthly operational costs.
   - Postgres schema with normalized tables and JSONB configuration/results.
   - Realtime subscriptions strictly isolated to active live tournament screens, scoped by `tournament_id` and disposed on screen exit.
   - All state transitions guarded by security-definer RPCs that validate caller permissions and ensure idempotency.
3. **Derived Standings (Single Source of Truth)**:
   - Standings are **derived on read** from fixture results using pure-Dart engines.
   - *Justification*: Storing a parallel standings table introduces state drift, synchronization bugs upon result corrections, and duplicated writes. Since tournaments in a campus context have at most dozens of matches, evaluating 10–50 fixture result JSONB objects in Dart takes < 1 ms on a phone and guarantees 100% mathematical consistency without drift.
4. **Professional Design System Adherence**:
   - Strictly Material 3 + App* design system tokens.
   - Flat surfaces, hairline borders (`1px`), 8pt grid, tabular figures (`fontFeatures: [FontFeature.tabularFigures()]`), calm typography.
   - Zero gradients, zero emojis, zero decorative icons.
   - Custom bracket visualization rendered via `CustomPainter` with orthogonal hairline connectors.

---

## 2. Data Model

### 2.1 Table: `public.tournaments`
Non-destructively alters/extends existing `public.tournaments`:
```sql
-- Alter existing table to add rich tournament attributes
ALTER TABLE public.tournaments
  ADD COLUMN IF NOT EXISTS sport TEXT NOT NULL DEFAULT 'cricket',
  ADD COLUMN IF NOT EXISTS config JSONB NOT NULL DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'open' CHECK (scope IN ('open', 'hostel', 'branch', 'year')),
  ADD COLUMN IF NOT EXISTS eligibility JSONB NOT NULL DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS organiser_id UUID REFERENCES public.users(id),
  ADD COLUMN IF NOT EXISTS is_official BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS max_entries INT,
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
```
- **Config JSONB Schema**:
  ```json
  {
    "match_format": "T20" | "Overs-10" | "90min" | "BestOf3",
    "points_win": 3,
    "points_draw": 1,
    "points_loss": 0,
    "points_tie": 1,
    "points_no_result": 1,
    "tie_breaker_order": ["points", "head_to_head", "goal_difference", "goals_for"],
    "third_place_match": true,
    "double_round_robin": false,
    "groups_count": 2,
    "qualifiers_per_group": 2,
    "knockout_tie_handling": "penalties" | "super_over" | "golden_point",
    "seeding_mode": "manual" | "rating" | "random",
    "random_seed": 42
  }
  ```
- **Eligibility JSONB Schema**:
  ```json
  {
    "allowed_hostels": ["MH-1", "MH-2"],
    "allowed_branches": ["CSE"],
    "allowed_years": ["1st Year"],
    "min_squad_size": 11,
    "max_squad_size": 15
  }
  ```

### 2.2 Table: `public.tournament_admins`
Manages multi-organiser and scorer assignments:
```sql
CREATE TABLE IF NOT EXISTS public.tournament_admins (
  tournament_id UUID REFERENCES public.tournaments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('organiser', 'co_organiser', 'scorer_manager')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (tournament_id, user_id)
);
```

### 2.3 Table: `public.tournament_groups`
Stores groups for multi-group league / group stage tournaments:
```sql
CREATE TABLE IF NOT EXISTS public.tournament_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_tournament_group_position UNIQUE (tournament_id, position)
);
```

### 2.4 Table: `public.tournament_entries`
Represents participating teams, individual players, or doubles pairs:
```sql
CREATE TABLE IF NOT EXISTS public.tournament_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('team', 'player', 'pair')),
  team_id UUID REFERENCES public.teams(id) ON DELETE SET NULL,
  player_ids UUID[] NOT NULL DEFAULT '{}',
  display_name TEXT NOT NULL,
  seed INT,
  group_id UUID REFERENCES public.tournament_groups(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'waitlisted', 'withdrawn', 'disqualified')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_tournament_entry_seed UNIQUE (tournament_id, seed)
);

CREATE INDEX IF NOT EXISTS idx_tournament_entries_tournament ON public.tournament_entries(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_entries_team ON public.tournament_entries(team_id);
```

### 2.5 Table: `public.tournament_fixtures`
Defines match slots across groups and knockout rounds:
```sql
CREATE TABLE IF NOT EXISTS public.tournament_fixtures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('group', 'knockout', 'third_place')),
  group_id UUID REFERENCES public.tournament_groups(id) ON DELETE SET NULL,
  round INT NOT NULL,
  position INT NOT NULL,
  round_label TEXT NOT NULL,
  entry_a_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  entry_b_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  source_fixture_a_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  source_fixture_b_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  source_outcome_a TEXT CHECK (source_outcome_a IN ('winner', 'loser')),
  source_outcome_b TEXT CHECK (source_outcome_b IN ('winner', 'loser')),
  is_bye BOOLEAN NOT NULL DEFAULT FALSE,
  scheduled_at TIMESTAMPTZ,
  venue TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'live', 'completed', 'walkover', 'cancelled')),
  match_id UUID REFERENCES public.matches(id) ON DELETE SET NULL,
  result JSONB DEFAULT '{}'::JSONB,
  winner_entry_id UUID REFERENCES public.tournament_entries(id) ON DELETE SET NULL,
  next_fixture_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL,
  next_slot TEXT CHECK (next_slot IN ('a', 'b')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fixtures_tournament ON public.tournament_fixtures(tournament_id);
CREATE INDEX IF NOT EXISTS idx_fixtures_match ON public.tournament_fixtures(match_id);
CREATE INDEX IF NOT EXISTS idx_fixtures_stage_round ON public.tournament_fixtures(tournament_id, stage, round);
```

### 2.6 Foreign Key Extensions on `public.matches`
```sql
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS tournament_id UUID REFERENCES public.tournaments(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS fixture_id UUID REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_matches_fixture_unique ON public.matches(fixture_id) WHERE fixture_id IS NOT NULL;
```

### 2.7 Table: `public.tournament_audit_logs`
Audit trail for critical organiser interventions:
```sql
CREATE TABLE IF NOT EXISTS public.tournament_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id),
  action TEXT NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 3. State Machines

### 3.1 Tournament Lifecycle
```
[draft]
   │
   ├─► publish registration ──► [registration_open]
   │                                  │
   │                                  ├─► deadline / manual close ──► [registration_closed]
   │                                  │                                     │
   │                                  │                                     ├─► generate draw ──► [ready]
   │                                  │                                     │                        │
   │                                  │                                     │                        ├─► first match starts ──► [live]
   │                                  │                                     │                        │                            │
   │                                  │                                     │                        │                            └─► all fixtures complete ──► [completed]
   ▼                                  ▼                                     ▼                        ▼                                                                 ▲
[cancelled] ◄────────────────────────────────────────────────────────────────────────────────────────┘
```
- **Rules**:
  - `draft`: Only organizers can edit. No public entries allowed.
  - `registration_open`: Captains and players can register/withdraw entries.
  - `registration_closed`: Organisers review/approve entries and assign seeds.
  - `ready`: Fixtures generated. Draw can be regenerated only before any fixture starts.
  - `live`: At least one fixture is live or completed. Structural regeneration is blocked.
  - `completed`: All fixtures completed, champion determined, badges awarded.
  - `cancelled`: Can be cancelled by organizer from any non-completed state.

### 3.2 Fixture Lifecycle
```
[pending] ──(both entries known & time assigned)──► [scheduled] ──► [live] ──► [completed]
    │                                                                               ▲
    ├───────────────── (bye / walkover) ────────────────────────────────────────────┤
    └───────────────── (match abandoned / cancelled) ──► [cancelled]
```

### 3.3 Entry Lifecycle
```
[pending] ──► [approved] ──► [withdrawn] (before draw)
   │               │
   ├─► [waitlisted]└─► [disqualified] (organizer action)
   └─► [rejected]
```

---

## 4. Pure-Dart Algorithms & Rule Engines

### 4.1 Knockout Bracket Generator (`KnockoutBracketEngine`)
- **Bracket Sizing**: Next power of 2: $S = 2^{\lceil \log_2(N) \rceil}$.
- **Byes Count**: $B = S - N$.
- **Bye Allocation**: Awarded to seeds $1, 2, \dots, B$.
- **Standard Seeding Placement**:
  - Generalized recursive seeding so Seed 1 and Seed 2 can meet only in the Final:
    - Size 4: (1 v 4), (2 v 3)
    - Size 8: (1 v 8), (4 v 5), (3 v 6), (2 v 7)
    - Size 16: (1 v 16), (8 v 9), (4 v 13), (5 v 12), (3 v 14), (6 v 11), (7 v 10), (2 v 15)
- **Automatic Bye Advancement**: When a fixture has one entry and a bye, it is auto-completed with `status = completed`, `is_bye = true`, advancing the seed immediately to Round 2.
- **Third-Place Playoff**: Generates an additional fixture linking the losers of both semi-finals.

### 4.2 Round-Robin Generator (`RoundRobinEngine`)
- **Circle Method Algorithm**:
  - If $N$ is odd, introduce a dummy "Rest" bye so $N' = N + 1$.
  - Generates $N' - 1$ rounds, with $N' / 2$ fixtures per round.
  - Rotates entries $2 \dots N'$ around fixed entry 1.
- **Double Round-Robin**:
  - Repeats schedule swapping home and away entries (`entry_a` and `entry_b`).

### 4.3 Group Allocator (`GroupStageEngine`)
- **Snake Seeding**:
  - Distributes seeded entries sequentially:
    - Group A: 1, 4, 5, 8...
    - Group B: 2, 3, 6, 7...
- **Per-Group Round-Robin**: Executes circle method per group.
- **Knockout Transition**:
  - Qualifiers per group (default 2).
  - Cross-pairing: Winner Group A vs Runner-up Group B ($A_1 \times B_2$) and Winner Group B vs Runner-up Group A ($B_1 \times A_2$).

### 4.4 Standings & Tie-Break Engines

#### Football Standings
- **Points**: 3 Win, 1 Draw, 0 Loss. Walkover default: 3–0 win (3 pts, +3 GD).
- **Default Tie-Breakers**:
  1. Points
  2. Head-to-Head points (mini-table of tied entries)
  3. Head-to-Head goal difference
  4. Overall goal difference
  5. Goals scored
  6. Flag: `"needs_organiser_decision"` (prevents silent arbitrary sorting)

#### Cricket Standings & Net Run Rate (NRR)
- **Points**: 2 Win, 1 Tie, 1 No Result, 0 Loss.
- **NRR Formula**:
  $$\text{NRR} = \left( \frac{\text{Total Runs Scored}}{\text{Total Overs Faced}} \right) - \left( \frac{\text{Total Runs Conceded}}{\text{Total Overs Bowled}} \right)$$
- **All-Out Rule**: If a team is bowled all out, their overs faced are counted as the full innings quota (e.g. 10.0 overs in a 10-over match, even if all out in 7.2 overs).
- **Overs from Balls**: Fractional overs are computed strictly from balls:
  $$3.4 \text{ overs} = 22 \text{ balls} = \frac{22}{6} = 3.6667 \text{ overs}$$
- **No Result / Abandoned**: Excluded from NRR calculation.

#### Badminton Standings
- **Points**: 1 per match win.
- **Tie-Breakers**:
  1. Points (Match wins)
  2. Head-to-Head
  3. Game Difference ($\text{Games Won} - \text{Games Lost}$)
  4. Point Difference ($\text{Points Won} - \text{Points Lost}$)
  5. Flag: `"needs_organiser_decision"`

---

## 5. Security Architecture & RPC Interface

### 5.1 RLS Policies
- `tournaments`: SELECT for all authenticated; INSERT/UPDATE/DELETE restricted to organizers and admins.
- `tournament_admins`: SELECT for all authenticated; INSERT/DELETE restricted to tournament creator or admin.
- `tournament_entries`: SELECT for all authenticated; INSERT for team captain / individual player; UPDATE/DELETE restricted to organizer or owner (before draw).
- `tournament_fixtures`: SELECT for all authenticated; INSERT/UPDATE strictly through security-definer RPCs (direct client mutations blocked).
- `tournament_audit_logs`: SELECT for organizers; INSERT restricted to security-definer functions.

### 5.2 Security-Definer RPCs
| RPC | Parameters | Responsibility |
|---|---|---|
| `create_tournament` | `p_name`, `p_sport`, `p_format`, `p_config`, `p_scope`, `p_eligibility`, `...` | Creates tournament, adds creator as organizer admin in atomic transaction. |
| `register_entry` | `p_tournament_id`, `p_kind`, `p_team_id`, `p_player_ids`, `p_display_name` | Validates eligibility (hostel/branch/year, max squad, no duplicate player) and inserts entry. |
| `review_entry` | `p_entry_id`, `p_status` ('approved', 'waitlisted', 'rejected') | Validates organizer role and updates entry status. |
| `generate_draw` | `p_tournament_id`, `p_plan` (JSONB) | Writes groups and fixtures generated by Dart engine inside one atomic transaction. |
| `schedule_fixture` | `p_fixture_id`, `p_scheduled_at`, `p_venue` | Validates organizer role, checks venue and entry time-slot conflicts. |
| `create_match_for_fixture` | `p_fixture_id` | Spawns `matches` row with `tournament_id` and `fixture_id`, populating `match_participants`. |
| `record_fixture_result` | `p_fixture_id`, `p_result` | Updates fixture, records winner, advances to downstream slot. |
| `apply_walkover` | `p_fixture_id`, `p_winner_entry_id`, `p_reason` | Awards walkover, records score (e.g. 3-0 in football), and advances winner. |
| `advance_stage` | `p_tournament_id`, `p_knockout_fixtures` | Confirms group results and instantiates knockout stage fixtures. |
| `correct_fixture_result` | `p_fixture_id`, `p_new_result`, `p_reset_downstream` | Allows result correction; requires explicit reset confirmation if downstream matches played. |

---

## 6. The `finish_match` Hook

In `finish_match` ([011_fix_career_stats_and_finish_match.sql](file:///d:/projects/vitap-sports/supabase/migrations/011_fix_career_stats_and_finish_match.sql#L117-L290)):
```sql
-- Tournament Hook
IF v_match.fixture_id IS NOT NULL THEN
  DECLARE
    v_fixture RECORD;
    v_winner_entry_id UUID;
  BEGIN
    SELECT * INTO v_fixture FROM public.tournament_fixtures WHERE id = v_match.fixture_id;
    
    IF v_fixture.id IS NOT NULL THEN
      -- Resolve winner entry
      IF v_winner_team_id IS NOT NULL THEN
        SELECT id INTO v_winner_entry_id FROM public.tournament_entries 
        WHERE tournament_id = v_match.tournament_id AND team_id = v_winner_team_id LIMIT 1;
      END IF;
      
      -- Update fixture
      UPDATE public.tournament_fixtures
      SET status = 'completed',
          result = p_result,
          winner_entry_id = v_winner_entry_id,
          updated_at = NOW()
      WHERE id = v_fixture.id;
      
      -- Advance winner to next fixture
      IF v_fixture.next_fixture_id IS NOT NULL AND v_winner_entry_id IS NOT NULL THEN
        IF v_fixture.next_slot = 'a' THEN
          UPDATE public.tournament_fixtures SET entry_a_id = v_winner_entry_id WHERE id = v_fixture.next_fixture_id;
        ELSIF v_fixture.next_slot = 'b' THEN
          UPDATE public.tournament_fixtures SET entry_b_id = v_winner_entry_id WHERE id = v_fixture.next_fixture_id;
        END IF;
      END IF;
      
      -- Check tournament status transition
      UPDATE public.tournaments SET status = 'live', updated_at = NOW()
      WHERE id = v_match.tournament_id AND status = 'ready';
      
      -- Check if tournament completed
      IF NOT EXISTS (
        SELECT 1 FROM public.tournament_fixtures 
        WHERE tournament_id = v_match.tournament_id AND status NOT IN ('completed', 'walkover', 'cancelled')
      ) THEN
        UPDATE public.tournaments SET status = 'completed', updated_at = NOW()
        WHERE id = v_match.tournament_id;
      END IF;
    END IF;
  END;
END IF;
```

---

## 7. User Interface & Screen Architecture

### 7.1 Tournaments List Screen (`TournamentsListScreen`)
- **Route**: `/leaderboard/tournaments`
- **Filter Chips**: `All`, `Live`, `Upcoming`, `Completed` + Horizontal `SportFilterBar`.
- **Tournament Card**:
  - Sport badge, format label, tournament title, date span, entrants count, status tag.
  - Built with `AppCard` (flat surface, hairline border, elevation 0).

### 7.2 Tournament Detail Screen (`TournamentDetailScreen`)
- **Route**: `/leaderboard/tournaments/:id`
- **Tabs**:
  1. **Overview**: Description, rules summary, point system, organizer contacts, eligibility rules.
  2. **Fixtures**: Filterable by stage/round; cards showing scheduled time, venue, entries, status; tap opens live scorecard or match analysis.
  3. **Table** (for League / Group formats): Standings table per group with tabular figures, tie-break notes, and highlighted current user team.
  4. **Bracket** (for Knockout formats): Horizontally scrollable round columns with orthogonal connectors drawn via `BracketConnectorPainter`.
  5. **Stats**: Derived tournament leaderboards (top run scorers, top wicket takers, golden boot, assists).
  6. **Teams / Entries**: Seeded entrant list.

### 7.3 Organiser Console
- Creation wizard: Basics -> Format & Rules -> Eligibility & Scope -> Registration Settings -> Review.
- Entries manager: Approve, waitlist, reject, assign seeds.
- Draw generator & preview: Seeded bracket preview before confirmation.
- Fixture scheduler: Date/time/venue picker with conflict detection alerts.
