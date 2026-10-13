# Supabase Tournaments Schema & RPC Specification

## Overview
This document specifies all database schema changes, RLS policies, and security-definer RPCs for the TOURNAMENTS feature in **VIT-AP Sports**.
All database changes are contained in:
[`supabase/migrations/012_tournaments_schema_and_rpc.sql`](file:///d:/projects/vitap-sports/supabase/migrations/012_tournaments_schema_and_rpc.sql)

---

## 1. Tables Modified & Created

### `public.tournaments` (Extended)
- **Modifications**:
  - Format constraint expanded to include `'groups_knockout'`.
  - Status constraint expanded to include `'draft'`, `'registration_open'`, `'registration_closed'`, `'ready'`, `'live'`, `'completed'`, `'cancelled'`.
- **Added Columns**:
  - `sport text`: Sport identifier (`'cricket'`, `'badminton'`, `'football'`).
  - `scope text NOT NULL DEFAULT 'open'`: Scope restriction (`'open'`, `'hostel'`, `'branch'`, `'year'`).
  - `config jsonb NOT NULL DEFAULT '{}'`: Format configurations (points, overs quota, sets, etc.).
  - `eligibility jsonb NOT NULL DEFAULT '{}'`: Restrictions (e.g. `{"hostel_block": "MH-1"}`, `{"branch": "CSE"}`, `{"year": "2024"}`).
  - `organiser_id uuid REFERENCES public.users(id)`: Creator and primary organiser.
  - `is_official boolean NOT NULL DEFAULT false`: Official university tournament flag.
  - `registration_deadline timestamptz`: Cut-off for registrations.
  - `max_entries int`: Entry ceiling.
  - `start_date timestamptz`: Scheduled start.
  - `end_date timestamptz`: Scheduled completion.
  - `updated_at timestamptz`: Modification timestamp.

### `public.tournament_admins` (New)
Multi-admin support allowing organisers to delegate draw management and scoring duties.
- `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
- `tournament_id uuid REFERENCES public.tournaments(id) ON DELETE CASCADE`
- `user_id uuid REFERENCES public.users(id) ON DELETE CASCADE`
- `role text NOT NULL DEFAULT 'admin' CHECK (role IN ('organiser', 'admin', 'scorer'))`
- `created_at timestamptz DEFAULT NOW()`
- `UNIQUE (tournament_id, user_id)`

### `public.tournament_groups` (New)
For group stage round-robin tournaments (e.g., Group A, Group B).
- `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
- `tournament_id uuid REFERENCES public.tournaments(id) ON DELETE CASCADE`
- `name text NOT NULL` (e.g., "Group A")
- `order_index int NOT NULL DEFAULT 0`
- `config jsonb NOT NULL DEFAULT '{}'`
- `created_at timestamptz DEFAULT NOW()`
- `UNIQUE (tournament_id, name)`

### `public.tournament_entries` (New)
Unified participant registry supporting team, solo, and pair (doubles) entries.
- `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
- `tournament_id uuid REFERENCES public.tournaments(id) ON DELETE CASCADE`
- `kind text NOT NULL DEFAULT 'team' CHECK (kind IN ('team', 'solo', 'pair'))`
- `team_id uuid REFERENCES public.teams(id) ON DELETE SET NULL`
- `user_id uuid REFERENCES public.users(id) ON DELETE SET NULL`
- `partner_id uuid REFERENCES public.users(id) ON DELETE SET NULL`
- `display_name text NOT NULL`
- `seed int`
- `group_id uuid REFERENCES public.tournament_groups(id) ON DELETE SET NULL`
- `status text NOT NULL DEFAULT 'approved' CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn', 'disqualified'))`
- `metadata jsonb NOT NULL DEFAULT '{}'`
- `registered_by uuid REFERENCES public.users(id) ON DELETE SET NULL`
- `registered_at timestamptz DEFAULT NOW()`
- Constraints:
  - `UNIQUE (tournament_id, team_id) WHERE team_id IS NOT NULL`
  - `UNIQUE (tournament_id, user_id) WHERE user_id IS NOT NULL AND kind = 'solo'`

### `public.tournament_fixtures` (New)
The single source of truth for all matches in the tournament draw tree.
- `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
- `tournament_id uuid REFERENCES public.tournaments(id) ON DELETE CASCADE`
- `stage text NOT NULL CHECK (stage IN ('group', 'knockout', 'third_place'))`
- `group_id uuid REFERENCES public.tournament_groups(id) ON DELETE SET NULL`
- `round int NOT NULL DEFAULT 1`
- `position int NOT NULL DEFAULT 1`
- `round_label text NOT NULL` (e.g. "Quarter-final 1", "Round 1")
- `entry_a_id uuid REFERENCES public.tournament_entries(id) ON DELETE SET NULL`
- `entry_b_id uuid REFERENCES public.tournament_entries(id) ON DELETE SET NULL`
- `source_fixture_a_id uuid REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL`
- `source_fixture_b_id uuid REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL`
- `source_outcome_a text CHECK (source_outcome_a IN ('winner', 'loser'))`
- `source_outcome_b text CHECK (source_outcome_b IN ('winner', 'loser'))`
- `is_bye boolean NOT NULL DEFAULT false`
- `scheduled_at timestamptz`
- `venue text`
- `status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'live', 'completed', 'walkover', 'cancelled'))`
- `match_id uuid REFERENCES public.matches(id) ON DELETE SET NULL`
- `result jsonb NOT NULL DEFAULT '{}'`
- `winner_entry_id uuid REFERENCES public.tournament_entries(id) ON DELETE SET NULL`
- `next_fixture_id uuid REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL`
- `next_slot text CHECK (next_slot IN ('a', 'b'))`
- `created_at timestamptz DEFAULT NOW()`
- `updated_at timestamptz DEFAULT NOW()`

### `public.matches` (Extended)
- Added `tournament_id uuid REFERENCES public.tournaments(id) ON DELETE SET NULL`
- Added `fixture_id uuid REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL`

### `public.tournament_audit_logs` (New)
Immutable record of administrative actions, score modifications, walkovers, and withdrawals.
- `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`
- `tournament_id uuid NOT NULL REFERENCES public.tournaments(id) ON DELETE CASCADE`
- `fixture_id uuid REFERENCES public.tournament_fixtures(id) ON DELETE SET NULL`
- `actor_id uuid REFERENCES public.users(id) ON DELETE SET NULL`
- `action text NOT NULL`
- `before jsonb NOT NULL DEFAULT '{}'`
- `after jsonb NOT NULL DEFAULT '{}'`
- `reason text`
- `created_at timestamptz DEFAULT NOW()`

---

## 2. Row Level Security (RLS)

All tables have RLS enabled with strict security:
- **Public Read**: Anyone authenticated can view tournaments, admins, groups, approved entries, fixtures, and standings.
- **Tournament Creation**: Any authenticated user can create tournaments (`auth.uid() = organiser_id`).
- **Organiser Permissions**: Managed via `public.is_tournament_admin(tournament_id, auth.uid())` which checks ownership and admin table.
- **Entry Registration**: Users can register themselves or their team; organisers can manage entries.
- **Fixture Scheduling & Editing**: Only tournament admins can generate draws or modify fixtures.

---

## 3. Security Definer RPCs

1. `public.create_tournament(...)`
2. `public.register_tournament_entry(...)`
3. `public.withdraw_tournament_entry(...)`
4. `public.generate_tournament_draw(...)`
5. `public.schedule_tournament_fixture(...)`
6. `public.create_match_for_fixture(...)`
7. `public.handle_tournament_match_finished(...)` (Internal hook invoked by `finish_match`)
8. `public.finish_match(...)` (Enhanced with tournament bracket advancement hook)
