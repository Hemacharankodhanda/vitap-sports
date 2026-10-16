# 🏆 VIT-AP Sports

[![Flutter](https://img.shields.io/badge/Flutter-3.12+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![State Management](https://img.shields.io/badge/State-Riverpod_2.6-blueviolet)](https://riverpod.dev)
[![Router](https://img.shields.io/badge/Router-GoRouter_14.8-orange)](https://pub.dev/packages/go_router)
[![Tests](https://img.shields.io/badge/Tests-136_Passing-brightgreen)](https://github.com/Hemacharankodhanda/vitap-sports)

**VIT-AP Sports** is a full-featured campus athletic and esports management platform built exclusively for students, teams, and tournament organisers at **VIT-AP University (Amaravati)**. 

The application streamlines intra-university sporting activities across Cricket, Football, Badminton, Basketball, Volleyball, and more — offering live ball-by-ball / event scoring, dynamic tournament brackets with automated standings, team management, free-agent recruitment, and career statistics tracking.

---

## 📱 Key Highlights & Features

### 🏆 1. Comprehensive Tournament Engine
- **Three Supported Formats**:
  - **Knockout (Single Elimination)**: Automatic bracket seeds, byes handling, and optional third-place playoff.
  - **League (Round-Robin)**: Complete round generation with home/away scheduling.
  - **Group Stage + Knockout**: Multi-group round-robin followed by qualifying advancement into an elimination bracket.
- **Dynamic Interactive Bracket Viewer**:
  - Zoomable and pannable tournament tree powered by `InteractiveViewer`.
  - Custom vector connectors rendered via Flutter `CustomPainter` with winner route highlighting.
  - One-tap navigation from bracket match nodes directly into live scorecards.
- **Automated Standings & Tie-Breakers**:
  - Real-time points table calculation.
  - Sport-specific tie-breakers: **Net Run Rate (NRR)** for Cricket, **Goal Difference (GD)** & Head-to-Head for Football, Set/Point differentials for Badminton.
- **Team Entry & Application Workflow**:
  - Teams/players submit join applications with status set to `pending`.
  - Organisers can review pending registrations, inspect full team information via an interactive team modal (`/teams/:id`), and **Approve** or **Decline** applications.
  - Real-time pending application count badge on tournament tabs and overview alerts.
  - Strict duplicate registration prevention and scope checks (Hostel Block, Academic Branch, or Graduation Year).
- **Honours & Podium**:
  - Automated gold/silver/bronze tournament honours and individual awards (Best Batter, Best Bowler, Golden Boot, MVP) synced directly to player profiles.

---

### ⚡ 2. Real-Time Live Scoring & Spectator Arena
- **Multisport Live Scoring Console**:
  - **Cricket**: Ball-by-ball input, striker/non-striker rotation, bowler selection, runs, extras (wides, no-balls, leg byes, byes), wickets, and over summaries.
  - **Football**: Minute-by-minute timeline, goals, assists, yellow/red cards, substitutions, halves, and stoppage time.
  - **Badminton**: Point-by-point tracking with set winners, deuce handling, and server rotation.
- **Spectator Experience**:
  - Real-time score and commentary updates broadcasted via Supabase Realtime channels with zero latency.
- **Scorer Delegation & Takeover**:
  - Match owners can assign official scorers or seamlessly take over scoring permissions with authorization safeguards.

---

### 👥 3. Teams & Free Agents Marketplace
- **Team Hub**: Create teams, upload logos, assign captaincy, manage active rosters, and review incoming join requests.
- **Recruitment Board**: Post open recruitment calls for specific positions (e.g., wicketkeeper, striker, singles badminton player).
- **Free Agents Directory**: Unaffiliated players can advertise their availability; captains can filter by sport, hostel block, and branch to recruit new talent.

---

### 📊 4. Player Profiles, Career Stats & Leaderboards
- **Automated Career Aggregations**:
  - When matches conclude, PostgreSQL triggers and RPCs automatically update career totals: matches played, wins, losses, batting strike rates, bowling economies, goals scored, and clean sheets.
- **Achievements & Badges**:
  - Unlock achievements such as *First Match*, *5 Wins*, *Hat-trick*, *Team Captain*, and *Tournament MVP*.
- **Campus Leaderboards**:
  - Live university rankings for teams and players filterable by sport, academic year, and hostel block.

---

### 🔒 5. Campus Security & Campus Scoping
- **Email Domain Restriction**: Guaranteed access exclusively for `@vitapstudent.ac.in` and `@vitap.ac.in` email accounts.
- **Hostel & Branch Scopes**: Tournaments can be restricted to specific hostel blocks (e.g., MH-1, MH-2, LH-1) or academic branches (e.g., CSE, ECE, Mechanical).

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | [Flutter 3.12+ (Dart 3.12+)](https://flutter.dev) | Cross-platform mobile client (Android & iOS) |
| **Backend & DB** | [Supabase](https://supabase.com) (PostgreSQL 15+) | Relational DB, Auth, Realtime websockets, and Storage |
| **State Management** | [Flutter Riverpod 2.6+](https://riverpod.dev) | Dependency injection, reactive providers, and state caching |
| **Routing** | [GoRouter 14.8+](https://pub.dev/packages/go_router) | Declarative navigation, deep linking, and persistent tab shells |
| **Design System** | Material 3 + Custom Sports Theme | Dark/Light theme, glassmorphic cards, Google Fonts (`Outfit` & `Inter`) |
| **Vector Graphics** | Flutter `CustomPainter` & `flutter_svg` | Dynamic bracket tree line rendering and SVG badge graphics |
| **Testing** | `flutter_test` | 136 Unit, engine, and widget tests |

---

## 📁 Project Architecture

The codebase follows a modular, **feature-first Clean Architecture** pattern ensuring high testability, separation of concerns, and pure Dart business engines:

```text
lib/
├── main.dart                          # App entry point, Supabase initialization, and ProviderScope
├── core/
│   ├── constants/                     # Supabase endpoints, sports constants, storage bucket keys
│   ├── providers/                     # Global providers (theme, network status)
│   ├── router/                        # GoRouter configuration, tab persistence, auth redirects
│   ├── services/                      # Base network and local storage services
│   ├── theme/                         # Sports color palettes, Material 3 theme data, typography
│   ├── utils/                         # Date formatters, score calculators, validation helpers
│   └── widgets/                       # Reusable UI widgets (AppButton, AppCard, EmptyStates, etc.)
└── features/
    ├── auth/                          # University domain login, OTP, onboarding
    ├── feed/                          # Campus sports feed, live tickers, announcements
    ├── free_agents/                   # Free agents marketplace, search, filters
    ├── leaderboard/                   # Campus-wide player and team leaderboards
    ├── matches/                       # Match scheduling, squad lineups, detail screen
    ├── profile/                       # Career stats, achievements, honours, user profile
    ├── scorecards/                    # Live spectator scorecards and event timeline
    ├── scoring/                       # Interactive live scoring consoles (Cricket, Football, Badminton)
    ├── settings/                      # App preferences and theme toggles
    ├── teams/                         # Team creation, roster management, recruitment board
    └── tournaments/                   # Tournament engine:
        ├── domain/models/             # Pure Dart tournament models, formats, and entities
        ├── domain/engines/            # BracketEngine, StandingsEngine, LeagueEngine
        ├── data/                      # TournamentService with Supabase RPC integrations
        ├── providers/                 # Riverpod tournament state, standings, and bracket providers
        └── presentation/              # Bracket CustomPaint, approval flows, standings tables
```

---

## 🗄️ Database Migrations

The database backend is structured across 12 sequential Supabase SQL migrations located in `supabase/migrations/`:

| Migration | Description |
| :--- | :--- |
| `001_create_tables.sql` | Core schema: users, teams, matches, sports, scorecards, audit logs |
| `002_rls_policies.sql` | Row Level Security (RLS) policies for user data isolation |
| `003_auth_domain_trigger.sql` | Auth hook enforcing `@vitapstudent.ac.in` / `@vitap.ac.in` domains |
| `004_seed_sports.sql` | Pre-populates default sports (Cricket, Football, Badminton, etc.) & achievements |
| `005_functions.sql` | Core helper functions and stored procedures |
| `006_live_scorer_schema.sql` | Live ball-by-ball and event-level timeline schema |
| `007_take_over_scoring.sql` | Authorization procedures for scorer delegation and takeover |
| `008_start_match_and_scorer_permissions.sql` | Match kickoff state machine and scorer role permissions |
| `009_player_stats_tables.sql` | Individual player career statistics breakdown tables |
| `010_leaderboard_view.sql` | SQL materialized views for high-performance leaderboard queries |
| `011_fix_career_stats_and_finish_match.sql` | Automated trigger updating career stats upon match completion |
| `012_tournaments_schema_and_rpc.sql` | Complete tournament schema: brackets, groups, entries, approval RPCs |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.12.2` ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `^3.12.2` (Bundled with Flutter)
- **Supabase Account**: A Supabase project with PostgreSQL 15+

### 1. Clone the Repository
```bash
git clone https://github.com/Hemacharankodhanda/vitap-sports.git
cd vitap-sports
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Database Setup
1. Open your Supabase Dashboard -> **SQL Editor**.
2. Run the migrations in chronological order from `supabase/migrations/` (or apply `012_tournaments_schema_and_rpc.sql` for the latest tournament engine).
3. Ensure storage buckets `avatars` and `team-logos` are configured with public read access.

### 4. Run the Application
```bash
# Run on connected mobile device or emulator
flutter run
```

---


**Test Suite Coverage (136 Tests Passing)**:
- ✅ **Bracket & Standings Engines**: Knouckout progression, byes, league scheduling, Net Run Rate, and Goal Difference computations.
- ✅ **Service & Providers**: Application approval RPC workflows, duplicate registration filters, and entry status states.
- ✅ **Live Scoring & Viewers**: Ball-by-ball cricket, event timelines, and spectator realtime updates.
- ✅ **UI & Navigation**: Router deep-linking, tab switching, and bracket custom rendering.

---

## 🤝 Contributing

Contributions are welcome! If you are a student or developer looking to enhance VIT-AP Sports:
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'feat: add some amazing feature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License

This project is developed for the students and sports community of **VIT-AP University**.
Distributed under the MIT License. See `LICENSE` for more information.
