# VIT-AP Sports — Tournaments System

A complete, enterprise-grade tournament management, scheduling, bracket rendering, and standings engine for VIT-AP University sports (Cricket, Badminton, Football). Built with pure-Dart algorithmic engines, zero-cost `CustomPaint` bracket visualization, and Supabase free-tier architectural discipline.

---

## Architecture & Design Principles

```
┌────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                            │
│  TournamentDetailScreen (6 Tabs: Overview, Fixtures, Table, Bracket,  │
│                          Stats, Teams)                                 │
│  KnockoutBracketView (CustomPaint BracketConnectorPainter)             │
│  TournamentStandingsTable (Tabular Figures, Qualification Bar)         │
│  TournamentHonoursSection (Player Profile Podiums: Gold/Silver/Bronze) │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ ref.watch()
┌────────────────────────────────────▼───────────────────────────────────┐
│                        RIVERPOD PROVIDERS LAYER                        │
│  tournamentsListProvider, tournamentDetailProvider                     │
│  tournamentStandingsProvider ──► (Pure-Dart Derived on Read)           │
│  tournamentFixturesProvider, playerTournamentHonoursProvider           │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
┌────────────────────────────────────▼───────────────────────────────────┐
│                       PURE-DART DOMAIN ENGINES                         │
│  KnockoutBracketEngine  RoundRobinEngine      GroupStageEngine         │
│  StandingsEngine (NRR, GD, Differentials)   AdvancementEngine          │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │ RPC Calls & Realtime
┌────────────────────────────────────▼───────────────────────────────────┐
│                     SUPABASE / POSTGRES FREE TIER                      │
│  tournaments, tournament_entries, tournament_fixtures, tournament_groups│
│  RLS on all tables, Security-Definer RPCs, Supabase Realtime           │
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Zero Database Drift Standings
Standings are **never stored as mutable database rows**. Instead, `tournamentStandingsProvider` calculates standings entirely in pure Dart on read directly from fixture results using `StandingsEngine`. This guarantees:
- **Zero synchronization drift**: Results cannot disagree with the table.
- **Instant replay/corrections**: Fixing an overturned score immediately updates the table with zero table recalculation migration jobs.
- **Supabase free-tier savings**: Eliminates periodic background triggers or cloud functions.

### 2. Zero-Cost CustomPaint Bracket
No external packages are used for rendering knockout brackets. Rectilinear advancement connectors are drawn directly on an interactive canvas using `BracketConnectorPainter` and `CustomPaint`, supporting:
- Horizontal and vertical scrolling.
- Multi-round power-of-2 trees (Round of 16, Quarter-Finals, Semi-Finals, Final).
- Highlighted progression paths for winning teams.
- Standalone 3rd place playoff match.
- Live active match badges and tabular scores.

---

## Supported Sports & Rules

| Sport | Formats Supported | Standings & Tie-Break Logic |
| :--- | :--- | :--- |
| **Football** | Knockout, League, Group Stage + KO | 3 pts for Win, 1 pt for Draw, 0 for Loss. Tie-break: Points ➔ Head-to-Head mini-table ➔ Goal Difference (GD) ➔ Goals For (GF). Walkovers default to 3-0. |
| **Cricket** | Knockout, League, Group Stage + KO | 2 pts for Win, 1 pt for Tie/NR, 0 for Loss. Tie-break: Points ➔ Net Run Rate (NRR) with full-quota all-out rule (`(Runs Scored / Max Overs) - (Runs Conceded / Max Overs)`). |
| **Badminton** | Knockout, Single/Doubles KO | Match Wins ➔ Game Difference ➔ Total Points Difference ➔ Head-to-Head. |

---

## Tournament Scopes & Eligibility Enforcement

Tournaments can be restricted to specific VIT-AP student cohorts:
1. **Open**: Any registered student from any block or branch.
2. **Hostel**: Restricted to students residing in a specific hostel block (e.g. `MH-1`, `MH-2`, `LH-1`).
3. **Branch**: Restricted to specific academic branches (e.g. `CSE`, `ECE`, `MECH`).
4. **Batch Year**: Restricted to specific graduation years (e.g. `2024`, `2025`, `2026`).

Eligibility is validated both on client input via `RegisterEntrySheet` against `UserModel` and at the database level inside `register_tournament_entry` RPC.

---

## Directory Structure

```
lib/features/tournaments/
├── domain/
│   └── models/
│       └── tournament_models.dart       # Tournament, Entry, Fixture, Group, Standings models
├── engines/
│   ├── advancement_engine.dart          # Winner advancement & loser 3rd place routing
│   ├── group_stage_engine.dart          # Snake seeding & cross-group knockout generation
│   ├── knockout_bracket_engine.dart     # Standard seeding, power of 2, byes generator
│   ├── round_robin_engine.dart          # Circle method schedule generator (even/odd)
│   └── standings_engine.dart            # Sport-specific table calculations
├── data/
│   └── tournament_service.dart          # Supabase client queries, RPCs & Realtime streams
├── providers/
│   └── tournament_providers.dart        # Riverpod providers, filter state, derived tables
└── presentation/
    ├── screens/
    │   ├── tournament_list_screen.dart   # Filterable list, status tabs, organizer CTA
    │   └── tournament_detail_screen.dart # 6-tab hub (Overview, Fixtures, Table, Bracket, Stats, Teams)
    └── widgets/
        ├── bracket_connector_painter.dart # CustomPaint rectilinear connector paths
        ├── bracket_node_card.dart         # Compact 2-slot bracket match card
        ├── create_tournament_sheet.dart   # Organiser creation wizard
        ├── generate_draw_dialog.dart      # Draw generation dialog
        ├── knockout_bracket_view.dart     # Multi-round bracket canvas
        ├── register_entry_sheet.dart      # Scope-validated entry registration
        ├── tournament_card.dart           # Tournament overview card
        ├── tournament_honours_section.dart# Profile podium trophies & medals
        └── tournament_standings_table.dart# Sport standings table with qualification marker
```

---

## Testing & Verification

The tournament feature contains 36 dedicated unit and widget tests with 100% pass rate:
- `test/tournaments/tournament_engines_test.dart`: 19 tests covering mathematical desk checks, power-of-2 scaling (2 to 64 entrants), circle method schedules, NRR all-out formulas, tie-break trails, and idempotent bracket advancement.
- `test/tournaments/tournament_service_and_providers_test.dart`: 6 tests covering model JSON roundtripping and read-time derived standings.
- `test/tournaments/tournament_ui_widgets_test.dart`: 7 tests covering `TournamentCard`, `BracketNodeCard`, `TournamentStandingsTable`, and `KnockoutBracketView`.
- `test/tournaments/tournament_honours_test.dart`: 4 tests covering podium honours models and profile widget rendering.

Run tests:
```bash
flutter test test/tournaments/
```
