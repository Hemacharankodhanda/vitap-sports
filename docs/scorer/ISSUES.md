# Known Issues & Unrelated Technical Debt

Date: 2026-10-10
Repository: `vitap-sports`

---

### Unrelated Issues Logged During Scorer Audit

1. **`test/widget_test.dart` compilation error on `MyApp`**:
   - *Status*: Fixed in Phase 0. Replaced template test with a valid `AppButton` widget test.
2. **Pre-existing static analyzer warnings across existing screens**:
   - *Details*: Multiple screens contain unused imports (`shell_screen.dart`, `login_screen.dart`, `free_agents_screen.dart`, `leaderboard_screen.dart`, `manage_squad_screen.dart`, `teams_list_screen.dart`), unused local variables (`isDark` in `app_avatar.dart`, `manage_squad_screen.dart`), and multiple underscores in parameter names.
   - *Policy*: Logged per Ground Rule 3; cleaned up as relevant without disturbing unrelated functionality.
3. **Missing Push Notifications**:
   - *Details*: Challenge accept/decline flows do not trigger APNS/FCM notifications.
4. **Matches Status Constraint Mismatch**:
   - *Details*: Existing `public.matches` constraint permits `('upcoming', 'live', 'completed', 'cancelled')`, while new live-scorer specification requires `('scheduled', 'live', 'paused', 'completed', 'abandoned')` (or alias handling). Handled cleanly via additive migration.
