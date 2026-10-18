/// VIT-AP Sports — GoRouter configuration.
///
/// Shell route for bottom navigation, auth redirect, named routes.
/// Each tab retains its own navigation stack per HIG guidelines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/free_agents/screens/free_agents_screen.dart';
import '../../features/leaderboard/screens/leaderboard_screen.dart';
import '../../features/matches/screens/create_match_screen.dart';
import '../../features/matches/screens/manage_squad_screen.dart';
import '../../features/matches/screens/match_analysis_screen.dart';
import '../../features/matches/screens/match_detail_screen.dart';
import '../../features/matches/screens/matches_list_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/scorecards/screens/scorecard_edit_screen.dart';
import '../../features/settings/screens/theme_settings_screen.dart';
import '../../features/teams/screens/create_team_screen.dart';
import '../../features/teams/screens/recruitment_screen.dart';
import '../../features/teams/screens/team_detail_screen.dart';
import '../../features/teams/screens/teams_list_screen.dart';
import '../../features/tournaments/screens/create_tournament_screen.dart';
import '../../features/tournaments/screens/tournament_detail_screen.dart';
import '../../features/tournaments/screens/tournaments_list_screen.dart';
import 'shell_screen.dart';

// Route names
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String teams = '/teams';
  static const String matches = '/matches';
  static const String leaderboard = '/leaderboard';
  static const String profile = '/profile';

  // Sub-routes
  static const String teamDetail = '/teams/:id';
  static const String createTeam = '/teams/create';
  static const String recruitment = '/teams/recruitment';
  static const String matchDetail = '/matches/:id';
  static const String createMatch = '/matches/create';
  static const String scorecardView = '/matches/:id/scorecard';
  static const String scorecardEdit = '/matches/:id/scorecard/edit';
  static const String editProfile = '/profile/edit';
  static const String freeAgents = '/free-agents';
  static const String tournaments = '/tournaments';
  static const String tournamentDetail = '/tournaments/:id';
  static const String createTournament = '/tournaments/create';
}

// Navigation keys for each tab's navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _teamsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'teams');
final _matchesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'matches');
final _leaderboardNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'leaderboard');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.uri.toString();
      
      // Handle Supabase OAuth callback deep link — let Supabase SDK
      // process the token while we redirect to home.
      if (location.contains('login-callback') || location.contains('callback')) {
        return AppRoutes.home;
      }

      // Synchronously check if session exists to avoid redirecting during stream load
      final hasSession = ref.read(authServiceProvider).currentSession != null;
      
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;
      final isOnOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!hasSession && !isOnLoginPage && !isOnOnboarding) return AppRoutes.login;
      if (hasSession && isOnLoginPage) return AppRoutes.home;
      return null;
    },
    onException: (_, GoRouterState state, GoRouter router) {
      // Catch any unmatched routes and redirect to home
      router.go(AppRoutes.home);
    },
    routes: [
      // ─── Auth Routes (outside shell) ─────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.tournaments,
        builder: (_, __) => const TournamentsListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, __) => const CreateTournamentScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (_, state) => TournamentDetailScreen(
              tournamentId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // ─── Main Shell (bottom nav) ─────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) => ShellScreen(
          navigationShell: navigationShell,
        ),
        branches: [
          // Home / Feed
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, __) => const FeedScreen(),
                routes: [
                  GoRoute(
                    path: 'free-agents',
                    builder: (_, __) => const FreeAgentsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Teams
          StatefulShellBranch(
            navigatorKey: _teamsNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.teams,
                builder: (_, __) => const TeamsListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (_, __) => const CreateTeamScreen(),
                  ),
                  GoRoute(
                    path: 'recruitment',
                    builder: (_, __) => const RecruitmentScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (_, state) => TeamDetailScreen(
                      teamId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Matches
          StatefulShellBranch(
            navigatorKey: _matchesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (_, __) => const MatchesListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (_, __) => const CreateMatchScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => MatchDetailScreen(
                      matchId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'squad/:teamId/:side',
                        builder: (_, state) => ManageSquadScreen(
                          matchId: state.pathParameters['id']!,
                          teamId: state.pathParameters['teamId']!,
                          side: state.pathParameters['side']!,
                        ),
                      ),
                      GoRoute(
                        path: 'scorecard',
                        builder: (_, state) => MatchAnalysisScreen(
                          matchId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'scorecard/edit',
                        builder: (_, state) => ScorecardEditScreen(
                          matchId: state.pathParameters['id']!,
                        ),
                      ),
                      GoRoute(
                        path: 'analysis',
                        builder: (_, state) => MatchAnalysisScreen(
                          matchId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Leaderboard
          StatefulShellBranch(
            navigatorKey: _leaderboardNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (_, __) => const LeaderboardScreen(),
                routes: [
                  GoRoute(
                    path: 'tournaments',
                    builder: (_, __) => const TournamentsListScreen(),
                    routes: [
                      GoRoute(
                        path: 'create',
                        builder: (_, __) =>
                            const CreateTournamentScreen(),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => TournamentDetailScreen(
                          tournamentId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'player/:id',
                    builder: (_, state) => PublicProfileScreen(
                      playerId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Profile
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'theme',
                    builder: (_, __) => const ThemeSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
