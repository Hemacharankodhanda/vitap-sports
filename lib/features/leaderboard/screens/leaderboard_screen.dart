/// VIT-AP Sports — Redesigned Tabular Leaderboard Screen.
/// Follows VIT-AP Sports Design Rules: Material 3 with Apple HIG restraint,
/// tabular figures for all numerical statistics, content-first, flat surfaces with hairline borders.
library;

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../teams/data/models/team_model.dart';
import '../providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selectedSport = ref.watch(leaderboardSportProvider);
    final cricketCategory = ref.watch(cricketCategoryProvider);
    final playersAsync = ref.watch(topPlayersProvider);
    final teamsAsync = ref.watch(topTeamsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, size: AppSpacing.iconNav),
            onPressed: () => context.go('/leaderboard/tournaments'),
            tooltip: 'Tournaments',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.lg,
        ),
        children: [
          // ─── 1. Sport filter (Cricket, Football, Badminton - 'All' removed) ──
          SizedBox(
            height: AppSpacing.chipHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const ['Cricket', 'Football', 'Badminton'].map((sport) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: sport,
                    isSelected: selectedSport == sport,
                    onTap: () => ref.read(leaderboardSportProvider.notifier).state = sport,
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── 2. Cricket category filter (Batting, Bowling, Fielding) ──
          if (selectedSport == 'Cricket') ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.chipHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  (label: 'Batting', icon: Icons.sports_cricket_rounded),
                  (label: 'Bowling', icon: Icons.sports_baseball_rounded),
                  (label: 'Fielding', icon: Icons.sports_handball_rounded),
                ].map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: AppChip(
                      label: category.label,
                      icon: category.icon,
                      isSelected: cricketCategory == category.label,
                      onTap: () => ref.read(cricketCategoryProvider.notifier).state = category.label,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // ─── 3. Top Players Header ──────────────────────────────────────
          SectionHeader(
            title: selectedSport == 'Cricket'
                ? 'Top $cricketCategory Leaders'
                : 'Top Players',
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── 4. Tabular Player Leaderboard ──────────────────────────────
          playersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => AppCard(
              child: Center(
                child: Text('Error loading leaderboard: $err', style: AppTypography.caption),
              ),
            ),
            data: (players) {
              if (players.isEmpty) {
                return EmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: 'No leaderboard data yet',
                  subtitle: selectedSport == 'Cricket'
                      ? 'Play cricket matches to appear on the $cricketCategory leaderboard!'
                      : 'Play matches to appear on the leaderboard!',
                );
              }

              return _PlayerLeaderboardTable(
                players: players,
                sport: selectedSport,
                category: cricketCategory,
                colors: colors,
                onPlayerTap: (playerId) {
                  if (playerId.isNotEmpty) {
                    context.go('/leaderboard/player/$playerId');
                  }
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // ─── 5. Top Teams Header ─────────────────────────────────────────
          SectionHeader(
            title: '$selectedSport Teams',
          ),
          const SizedBox(height: AppSpacing.md),

          // ─── 6. Tabular Team Leaderboard ─────────────────────────────────
          teamsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => AppCard(
              child: Center(
                child: Text('Error loading team rankings: $err', style: AppTypography.caption),
              ),
            ),
            data: (teams) {
              if (teams.isEmpty) {
                return EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No team rankings yet',
                  subtitle: '$selectedSport teams will be ranked after completing matches.',
                );
              }

              return _TeamLeaderboardTable(
                teams: teams,
                colors: colors,
                onTeamTap: (teamId) {
                  if (teamId.isNotEmpty) {
                    context.go('/teams/$teamId');
                  }
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabular Player Leaderboard Table
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerLeaderboardTable extends StatelessWidget {
  const _PlayerLeaderboardTable({
    required this.players,
    required this.sport,
    required this.category,
    required this.colors,
    required this.onPlayerTap,
  });

  final List<Map<String, dynamic>> players;
  final String sport;
  final String category;
  final AppColorsExtension colors;
  final ValueChanged<String> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Column Header Row
          _buildHeaderRow(),

          // Player Rows
          for (int i = 0; i < players.length; i++)
            _buildPlayerRow(i, players[i]),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Rank Header
          SizedBox(
            width: 28,
            child: Text(
              '#',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Player Header
          Expanded(
            child: Text(
              'PLAYER',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: colors.textSecondary,
              ),
            ),
          ),

          // Sport/Category specific right-aligned stat headers
          ..._buildStatHeaders(),
        ],
      ),
    );
  }

  List<Widget> _buildStatHeaders() {
    final sportLower = sport.toLowerCase();
    if (sportLower == 'cricket') {
      if (category == 'Bowling') {
        return [
          _colHeader('WKTS', 42, isHighlight: true),
          _colHeader('OV', 38),
          _colHeader('RUNS', 40),
          _colHeader('MDN', 32),
          _colHeader('ECON', 48),
        ];
      } else if (category == 'Fielding') {
        return [
          _colHeader('DISM', 44, isHighlight: true),
          _colHeader('CT', 34),
          _colHeader('RO', 34),
          _colHeader('ST', 34),
        ];
      } else {
        // Batting
        return [
          _colHeader('RUNS', 44),
          _colHeader('AVG', 44, isHighlight: true),
          _colHeader('4s', 30),
          _colHeader('6s', 30),
          _colHeader('SR', 50),
        ];
      }
    } else if (sportLower == 'football') {
      return [
        _colHeader('M', 34),
        _colHeader('GOALS', 48, isHighlight: true),
        _colHeader('AST', 40),
      ];
    } else {
      // Badminton
      return [
        _colHeader('M', 38),
        _colHeader('PTS', 54, isHighlight: true),
      ];
    }
  }

  Widget _buildPlayerRow(int index, Map<String, dynamic> player) {
    final rank = index + 1;
    final playerId = player['id']?.toString() ?? '';
    final name = player['name']?.toString() ?? 'Player';
    final avatarUrl = player['avatar_url'] as String?;

    return InkWell(
      onTap: () => onPlayerTap(playerId),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm + 1,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            // Rank Number (#1, #2, #3, ...)
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: AppTypography.caption.fontFamily,
                  fontSize: 13,
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w500,
                  color: _rankColor(rank),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Player Avatar + Name
            Expanded(
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: avatarUrl,
                    name: name,
                    size: AppAvatarSize.small,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: AppTypography.callout.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right-aligned uniform statistics
            ..._buildStatValues(player),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatValues(Map<String, dynamic> p) {
    final sportLower = sport.toLowerCase();
    if (sportLower == 'cricket') {
      if (category == 'Bowling') {
        final wkts = _resolveWkts(p);
        final overs = _resolveOvers(p);
        final runs = _resolveBowlingRuns(p);
        final maidens = _resolveMaidens(p);
        final econ = _resolveEcon(p);

        return [
          _colValue(wkts, 42, isHighlight: true),
          _colValue(overs, 38),
          _colValue(runs, 40),
          _colValue(maidens, 32),
          _colValue(econ, 48),
        ];
      } else if (category == 'Fielding') {
        final dism = _resolveDismissals(p);
        final catches = _resolveCatches(p);
        final runOuts = _resolveRunOuts(p);
        final stumpings = _resolveStumpings(p);

        return [
          _colValue(dism, 44, isHighlight: true),
          _colValue(catches, 34),
          _colValue(runOuts, 34),
          _colValue(stumpings, 34),
        ];
      } else {
        // Batting
        final runs = _resolveBattingRuns(p);
        final avg = _resolveBattingAvg(p);
        final fours = _resolveBattingFours(p);
        final sixes = _resolveBattingSixes(p);
        final sr = _resolveBattingSr(p);

        return [
          _colValue(runs, 44),
          _colValue(avg, 44, isHighlight: true),
          _colValue(fours, 30),
          _colValue(sixes, 30),
          _colValue(sr, 50),
        ];
      }
    } else if (sportLower == 'football') {
      final matches = _resolveMatches(p);
      final goals = _resolveGoals(p);
      final assists = _resolveAssists(p);

      return [
        _colValue(matches, 34),
        _colValue(goals, 48, isHighlight: true),
        _colValue(assists, 40),
      ];
    } else {
      // Badminton
      final matches = _resolveMatches(p);
      final points = _resolvePoints(p);

      return [
        _colValue(matches, 38),
        _colValue(points, 54, isHighlight: true),
      ];
    }
  }

  // ── Column header and value builder helpers ────────────────────────────────
  Widget _colHeader(String title, double width, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isHighlight ? colors.accent : colors.textSecondary,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _colValue(String val, double width, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 13,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
          color: isHighlight ? colors.accent : colors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD97706); // Gold / Amber
      case 2:
        return const Color(0xFF64748B); // Silver / Slate
      case 3:
        return const Color(0xFFB45309); // Bronze
      default:
        return colors.textSecondary;
    }
  }

  // ── Stat extraction helpers (support both granular fields and formatted strings) ──
  String _resolveBattingRuns(Map<String, dynamic> p) {
    if (p['runs'] != null) return p['runs'].toString();
    final prim = p['primary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Runs').firstMatch(prim);
    if (m != null) return m.group(1)!;
    if (prim.contains(' ')) return prim.split(' ').first;
    return prim.isNotEmpty ? prim : '0';
  }

  String _resolveBattingAvg(Map<String, dynamic> p) {
    if (p['avg'] != null) return p['avg'].toString();
    if (p['batting_avg'] != null) return p['batting_avg'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'Avg:\s*([0-9.]+)').firstMatch(sec);
    if (m != null) return m.group(1)!;
    final prim = p['primary_stat']?.toString() ?? '';
    final m2 = RegExp(r'([0-9.]+)\s*Avg').firstMatch(prim);
    if (m2 != null) return m2.group(1)!;
    return '-';
  }

  String _resolveBattingFours(Map<String, dynamic> p) {
    if (p['fours'] != null) return p['fours'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*\(4s\)').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveBattingSixes(Map<String, dynamic> p) {
    if (p['sixes'] != null) return p['sixes'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*\(6s\)').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveBattingSr(Map<String, dynamic> p) {
    if (p['sr'] != null) return p['sr'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'SR:\s*([0-9.]+)').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveWkts(Map<String, dynamic> p) {
    if (p['wickets'] != null) return p['wickets'].toString();
    final prim = p['primary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Wickets').firstMatch(prim);
    if (m != null) return m.group(1)!;
    if (prim.contains(' ')) return prim.split(' ').first;
    return prim.isNotEmpty ? prim : '0';
  }

  String _resolveOvers(Map<String, dynamic> p) {
    if (p['overs'] != null) return p['overs'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'([0-9.]+)\s*Ov').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveBowlingRuns(Map<String, dynamic> p) {
    if (p['runs_conceded'] != null) return p['runs_conceded'].toString();
    if (p['runs'] != null) return p['runs'].toString();
    return '-';
  }

  String _resolveMaidens(Map<String, dynamic> p) {
    if (p['maidens'] != null) return p['maidens'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*M').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveEcon(Map<String, dynamic> p) {
    if (p['econ'] != null) return p['econ'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'Econ:\s*([0-9.]+)').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveDismissals(Map<String, dynamic> p) {
    if (p['dismissals'] != null) return p['dismissals'].toString();
    final prim = p['primary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Dismissals').firstMatch(prim);
    if (m != null) return m.group(1)!;
    if (prim.contains(' ')) return prim.split(' ').first;
    return '0';
  }

  String _resolveCatches(Map<String, dynamic> p) {
    if (p['catches'] != null) return p['catches'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Catches').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveRunOuts(Map<String, dynamic> p) {
    if (p['run_outs'] != null) return p['run_outs'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Run Outs').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveStumpings(Map<String, dynamic> p) {
    if (p['stumpings'] != null) return p['stumpings'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Stumpings').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveMatches(Map<String, dynamic> p) {
    if (p['matches_played'] != null) return p['matches_played'].toString();
    if (p['matches'] != null) return p['matches'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Matches').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolveGoals(Map<String, dynamic> p) {
    if (p['goals'] != null) return p['goals'].toString();
    final prim = p['primary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Goals').firstMatch(prim);
    if (m != null) return m.group(1)!;
    if (prim.contains(' ')) return prim.split(' ').first;
    return '0';
  }

  String _resolveAssists(Map<String, dynamic> p) {
    if (p['assists'] != null) return p['assists'].toString();
    final sec = p['secondary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Assists').firstMatch(sec);
    if (m != null) return m.group(1)!;
    return '-';
  }

  String _resolvePoints(Map<String, dynamic> p) {
    if (p['points'] != null) return p['points'].toString();
    final prim = p['primary_stat']?.toString() ?? '';
    final m = RegExp(r'(\d+)\s*Points').firstMatch(prim);
    if (m != null) return m.group(1)!;
    if (prim.contains(' ')) return prim.split(' ').first;
    return '0';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tabular Team Leaderboard Table
// ─────────────────────────────────────────────────────────────────────────────

class _TeamLeaderboardTable extends StatelessWidget {
  const _TeamLeaderboardTable({
    required this.teams,
    required this.colors,
    required this.onTeamTap,
  });

  final List<TeamModel> teams;
  final AppColorsExtension colors;
  final ValueChanged<String> onTeamTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              border: Border(bottom: BorderSide(color: colors.border, width: 1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'TEAM',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                _colHeader('M', 34),
                _colHeader('W', 36, isHighlight: true),
                _colHeader('L', 34),
                _colHeader('D', 34),
                _colHeader('WIN%', 48),
              ],
            ),
          ),

          // Team Rows
          for (int i = 0; i < teams.length; i++)
            _buildTeamRow(i, teams[i]),
        ],
      ),
    );
  }

  Widget _buildTeamRow(int index, TeamModel team) {
    final rank = index + 1;
    final totalMatches = team.wins + team.losses + team.draws;
    final winRate = totalMatches > 0
        ? '${((team.wins / totalMatches) * 100).toStringAsFixed(0)}%'
        : '0%';

    return InkWell(
      onTap: () => onTeamTap(team.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.cardPadding,
          vertical: AppSpacing.sm + 1,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: AppTypography.caption.fontFamily,
                  fontSize: 13,
                  fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.w500,
                  color: _rankColor(rank),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Row(
                children: [
                  AppAvatar(
                    imageUrl: team.logoUrl,
                    name: team.name,
                    size: AppAvatarSize.small,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      team.name,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            _colValue('$totalMatches', 34),
            _colValue('${team.wins}', 36, isHighlight: true),
            _colValue('${team.losses}', 34),
            _colValue('${team.draws}', 34),
            _colValue(winRate, 48),
          ],
        ),
      ),
    );
  }

  Widget _colHeader(String title, double width, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isHighlight ? colors.accent : colors.textSecondary,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _colValue(String val, double width, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 13,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w400,
          color: isHighlight ? colors.accent : colors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF64748B);
      case 3:
        return const Color(0xFFB45309);
      default:
        return colors.textSecondary;
    }
  }
}
