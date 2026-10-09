# Build Prompt: VIT-AP Sports (Flutter + Supabase)

Copy everything below into Antigravity as your build prompt.

---

## Project Overview

Build a Flutter + Supabase Android app called **"VIT-AP Sports"** — a sports community app for VIT-AP University students. Users create profiles, form teams across multiple sports, host/schedule matches, track live scorecards, and view stats/leaderboards.

**Design priority is as important as functionality.** This app must feel premium, minimal, and pixel-precise — not like a generic CRUD app. Read the Design System section carefully before writing any UI code, and apply it consistently across every screen.

---

## Design System (apply to every screen, no exceptions)

**Visual language:** Minimalist, generous white space, one clear focal point per screen. No visual clutter, no unnecessary borders/dividers/shadows unless they serve hierarchy.

**Alignment & layout — this is critical:**
- Every screen must use a consistent horizontal padding (e.g., 20px) — never let content touch screen edges inconsistently across screens.
- All text baselines, icons, and buttons within a row must be vertically centered against each other — no visual "wobble."
- Use a strict 8px spacing grid (4/8/12/16/24/32) for all margins and paddings — no arbitrary values like 13px or 22px.
- Buttons must have consistent height across the whole app (e.g., 48px for primary buttons, 40px for secondary/chip buttons).
- Icon sizes must be consistent per context (e.g., all nav icons 24px, all inline icons 18px) — never mix sizes for the same semantic role.
- Cards (team cards, match cards, player cards) must share one consistent corner radius, padding, and elevation style throughout the app.
- Text hierarchy: max 3 font sizes per screen (heading, body, caption) using a consistent type scale — no ad hoc font sizes.
- Center-align empty states (icon + message) both horizontally and vertically within their container.

**Color & theming:**
- Support both light and dark mode, built on Material 3 (`useMaterial3: true`), with a single accent color (pick a sport-energy color — e.g., a vivid green or orange — used sparingly for CTAs, active states, and live indicators only).
- Neutral grayscale palette for everything else (backgrounds, cards, text) — avoid decorative colors elsewhere.
- Live match indicators use the accent color with a subtle pulsing dot animation — this is the one place motion draws attention.

**Animation guidelines (clean, purposeful, never gratuitous):**
- Page transitions: subtle fade + slight slide (200-250ms), using Flutter's built-in `PageTransitionsTheme` — no bouncy or overshoot curves.
- List items: staggered fade-in on first load only (not on every rebuild), 300ms max total.
- Button taps: gentle scale-down (0.96) on press using `AnimatedScale`, no ripple overload.
- Score updates: numbers should animate via `TweenAnimationBuilder` when they change (count-up effect), not just snap.
- Bottom nav bar: smooth icon/label color transition on tab switch, no jarring jumps.
- Never use more than one animation curve type per screen — pick `Curves.easeOutCubic` as the app-wide default and stick to it.
- Avoid animating things that don't need it (static text, non-interactive labels).

**Typography:** Use Google Fonts package with a single clean sans-serif family (e.g., Inter or Manrope) across the whole app — do not mix fonts.

**Component consistency:** Build a small internal design-system layer first (reusable `AppButton`, `AppCard`, `AppTextField`, `AppChip`, `SectionHeader` widgets) and use ONLY these across all screens — do not hand-roll one-off buttons or cards per screen. This is the main mechanism for guaranteeing alignment consistency app-wide.

---

## Tech Stack

- **Frontend:** Flutter (latest stable), Material 3
- **Backend:** Supabase (Postgres, Auth, Realtime, Storage) — free tier
- **State management:** Riverpod (preferred) or Provider — pick one and use it consistently everywhere, no mixing
- **Fonts/Icons:** google_fonts, a single consistent icon set (Material Symbols or Lucide via flutter package) — no mixing icon families
- **Image handling:** image_picker + flutter_image_compress before any Supabase Storage upload (keep storage usage low on free tier)

---

## Auth

- Google OAuth via Supabase Auth, restricted to the VIT-AP student email domain
- Enforce domain restriction server-side via a Postgres trigger on the `auth.users` table (reject/delete sign-ups outside the allowed domain) — do not rely on client-side checks alone
- Clean, minimal auth screen: logo, single "Continue with Google" button, no clutter

---

## Core Features to Build

### 1. Profiles
- Name, branch, year, hostel block, profile photo, sports played (multi-select), skill level per sport
- Stats summary: matches played, wins, MVP count, sport-specific stats
- Achievements/badges section (grid of earned badges, greyed-out for unearned ones)

### 2. Teams
- Create/join team per sport, captain role with elevated permissions (edit roster, schedule matches)
- Team profile: logo, roster list, win/loss record, upcoming fixtures, past match history
- "Looking for players" open recruitment post (sport, position needed, contact via in-app request)

### 3. Matches
- Create match: sport, venue, date/time, format
- Challenge flow: Team A challenges Team B → Team B accepts/declines (push notification on status change)
- Individual RSVP for informal/pickup games (no team required)
- Match detail screen: participants, venue, scheduled time, live/upcoming/completed status badge

### 4. Live Scorecards
- Sport-specific scorecard input (store as JSONB in Supabase — one `scorecards` table with a flexible `data` JSONB column, not per-sport tables)
- Realtime score sync via Supabase Realtime — viewers see score updates live without refreshing
- Post-match auto-generated summary card (final score, top performer highlight)

### 5. Tournaments (build after core features are stable)
- Knockout bracket generator
- League table with auto-updated standings after each match result is submitted

### 6. Community/Leaderboards
- Global and per-sport leaderboards (top scorers, most active players, best win-rate teams)
- Simple activity feed: recent match results, new team formations, badges earned

---

## Suggested Supabase Schema

```
users (id, name, branch, year, hostel_block, avatar_url, created_at)
sports (id, name, icon)
user_sports (user_id, sport_id, skill_level)
teams (id, name, sport_id, logo_url, captain_id, created_at)
team_members (team_id, user_id, role, joined_at)
matches (id, sport_id, venue, scheduled_at, status, format, created_by)
match_participants (match_id, team_id OR user_id, side)
scorecards (id, match_id, data JSONB, updated_at)
tournaments (id, name, sport_id, format, status)
tournament_matches (tournament_id, match_id, round)
achievements (id, name, description, icon)
user_achievements (user_id, achievement_id, earned_at)
```

Apply Row Level Security (RLS) on every table: users can read public data freely, but writes to teams/matches/scorecards should be restricted to captains/match creators/participants only.

---

## Build Order (build and verify each stage before moving to the next)

1. Design-system widget layer (`AppButton`, `AppCard`, `AppTextField`, `AppChip`, `SectionHeader`) + theme (light/dark, Material 3, Google Fonts)
2. Supabase project setup + schema + RLS policies + Google OAuth with domain trigger
3. Auth flow + profile creation/edit screen
4. Teams: create/join/view, roster management
5. Matches: create, challenge/accept flow, RSVP
6. Live scorecards + Realtime sync
7. Leaderboards + activity feed
8. Tournaments (bracket + league table)
9. Polish pass: verify every screen against the Design System section above — check padding consistency, button heights, icon sizes, and animation curves across all screens before considering any screen "done"

---

## Non-Negotiables

- Every screen must be checked against the alignment rules above before moving to the next feature — do not defer "polish" to the end, bake it in per-screen.
- No screen ships with inconsistent padding, mismatched icon sizes, or ad-hoc font sizes, even in early prototype stages.
- Reuse the internal design-system widgets everywhere — flag any place a one-off widget was used instead, and refactor before continuing.
