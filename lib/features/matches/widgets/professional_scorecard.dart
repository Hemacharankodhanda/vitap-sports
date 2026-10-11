// VIT-AP Sports — Professional Scorecards.
import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../scoring/engines/cricket/cricket_state.dart';
import '../../scoring/engines/football/football_state.dart';
import '../../scoring/engines/badminton/badminton_state.dart';
import '../data/models/match_model.dart';

class ProfessionalScorecard extends StatelessWidget {
  const ProfessionalScorecard({
    super.key,
    required this.match,
    this.scoringState,
    this.playerNames,
  });

  final MatchModel match;
  final dynamic scoringState;
  final Map<String, String>? playerNames;

  @override
  Widget build(BuildContext context) {
    try {
      final sportLower = (match.sportName ?? '').toLowerCase().trim();
      dynamic resolvedState = scoringState;

      if (resolvedState == null && match.score != null) {
        try {
          if (sportLower == 'cricket' || sportLower.isEmpty) {
            resolvedState = CricketState.fromJson(Map<String, dynamic>.from(match.score!));
          } else if (sportLower == 'football') {
            resolvedState = FootballState.fromJson(Map<String, dynamic>.from(match.score!));
          } else if (sportLower == 'badminton') {
            resolvedState = BadmintonState.fromJson(Map<String, dynamic>.from(match.score!));
          }
        } catch (e) {
          debugPrint('Error parsing match.score: $e');
        }
      }

      if (resolvedState is CricketState) {
        return _CricketScorecard(state: resolvedState, match: match, playerNames: playerNames);
      } else if (resolvedState is FootballState) {
        return _FootballScorecard(state: resolvedState, match: match, playerNames: playerNames);
      } else if (resolvedState is BadmintonState) {
        return _BadmintonScorecard(state: resolvedState, match: match);
      }

      // Informative card instead of blank screen
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.scoreboard_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withAlpha(160),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scorecard In Progress',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Detailed statistics and player scorecards will appear once scoring events are recorded.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error in ProfessionalScorecard.build: $e\n$st');
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.scoreboard_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary.withAlpha(160),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scorecard In Progress',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scorecard details will appear once loaded.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _CricketScorecard extends StatelessWidget {
  const _CricketScorecard({
    required this.state,
    required this.match,
    this.playerNames,
  });
  final CricketState state;
  final MatchModel match;
  final Map<String, String>? playerNames;

  String _getPlayerName(String? id) {
    if (id == null || id.isEmpty) return 'Player';
    // 1. Explicit playerNames map passed in
    if (playerNames != null && playerNames![id] != null && playerNames![id]!.isNotEmpty) {
      return playerNames![id]!;
    }
    // 2. Embedded in match.score
    if (match.score != null) {
      final pNames = match.score!['player_names'];
      if (pNames is Map && pNames[id] != null && pNames[id].toString().isNotEmpty) {
        return pNames[id].toString();
      }
      final pStats = match.score!['player_stats'];
      if (pStats is Map && pStats[id] is Map && pStats[id]['name'] != null) {
        final n = pStats[id]['name'].toString();
        if (n.isNotEmpty) return n;
      }
    }
    // 3. Match participants
    final p = match.participants.where((e) => e.userId == id || e.teamId == id).firstOrNull;
    if (p?.userName != null && p!.userName!.isNotEmpty) return p.userName!;
    if (p?.teamName != null && p!.teamName!.isNotEmpty) return p.teamName!;

    // 4. Default player labels
    if (id.startsWith('home_p_')) {
      final num = id.replaceFirst('home_p_', '');
      final t = match.homeTeamName ?? 'Team 1';
      return '$t Player $num';
    }
    if (id.startsWith('away_p_')) {
      final num = id.replaceFirst('away_p_', '');
      final t = match.awayTeamName ?? 'Team 2';
      return '$t Player $num';
    }

    // 5. Hide ugly UUIDs with fallback
    if (id.length == 36 && id.contains('-')) {
      return 'Player';
    }
    return id;
  }

  String _formatDismissal(BatterRecord batter) {
    final how = batter.howOut?.toLowerCase().trim();
    if (how == null || how.isEmpty) return 'out';
    final bowlerName = batter.bowlerId != null ? _getPlayerName(batter.bowlerId) : null;
    final fielderName = batter.fielderId != null ? _getPlayerName(batter.fielderId) : null;

    if (how == 'bowled') {
      return bowlerName != null ? 'b $bowlerName' : 'bowled';
    } else if (how == 'caught') {
      if (fielderName != null && bowlerName != null) {
        return fielderName == bowlerName ? 'c & b $bowlerName' : 'c $fielderName b $bowlerName';
      }
      return bowlerName != null ? 'c ... b $bowlerName' : 'caught';
    } else if (how == 'lbw') {
      return bowlerName != null ? 'lbw b $bowlerName' : 'lbw';
    } else if (how == 'run_out' || how == 'run out') {
      return fielderName != null ? 'run out ($fielderName)' : 'run out';
    } else if (how == 'stumped') {
      if (fielderName != null && bowlerName != null) {
        return 'st $fielderName b $bowlerName';
      }
      return 'stumped';
    } else if (how == 'hit_wicket') {
      return bowlerName != null ? 'hit wicket b $bowlerName' : 'hit wicket';
    }
    return how;
  }

  String _getTeamName(String? id) {
    if (id == null || id.isEmpty) return 'Team';
    if (id == 'home') return match.homeTeamName ?? 'Team 1';
    if (id == 'away') return match.awayTeamName ?? 'Team 2';
    final p = match.participants.where((e) => e.teamId == id || e.userId == id).firstOrNull;
    return p?.teamName ?? p?.userName ?? match.homeTeamName ?? match.awayTeamName ?? 'Team';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (state.innings.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_cricket_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Innings In Progress', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text('Deliveries and batter records will update here in real time.', style: AppTypography.caption),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < state.innings.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xl),
          Text(
            '${_getTeamName(state.innings[i].battingTeamId)} Innings',
            style: AppTypography.title.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${state.innings[i].totalRuns}/${state.innings[i].totalWickets} (${state.innings[i].overs.toStringAsFixed(1)} Ov)',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBattingTable(state.innings[i], isDark, context),
          const SizedBox(height: AppSpacing.md),
          _buildBowlingTable(state.innings[i], isDark, context),
        ]
      ],
    );
  }

  Widget _buildBattingTable(CricketInningsState inning, bool isDark, BuildContext context) {
    if (inning.battingStats.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('No batting entries recorded yet.', style: AppTypography.caption),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingTextStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          columns: const [
            DataColumn(label: Text('Batter')),
            DataColumn(label: Text('R'), numeric: true),
            DataColumn(label: Text('B'), numeric: true),
            DataColumn(label: Text('4s'), numeric: true),
            DataColumn(label: Text('6s'), numeric: true),
            DataColumn(label: Text('SR'), numeric: true),
          ],
          rows: inning.battingStats.entries.map((e) {
            final batter = e.value;
            final isNotOut = !batter.isOut;
            return DataRow(cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_getPlayerName(e.key)}${isNotOut && batter.ballsFaced > 0 ? "*" : ""}', 
                      style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                    if (batter.isOut && batter.howOut != null)
                      Text(
                        _formatDismissal(batter),
                        style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      )
                  ],
                )
              ),
              DataCell(Text(batter.runs.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(batter.ballsFaced.toString())),
              DataCell(Text(batter.fours.toString())),
              DataCell(Text(batter.sixes.toString())),
              DataCell(Text(batter.strikeRate.toStringAsFixed(1))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBowlingTable(CricketInningsState inning, bool isDark, BuildContext context) {
    if (inning.bowlingStats.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text('No bowling entries recorded yet.', style: AppTypography.caption),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingTextStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          columns: const [
            DataColumn(label: Text('Bowler')),
            DataColumn(label: Text('O'), numeric: true),
            DataColumn(label: Text('M'), numeric: true),
            DataColumn(label: Text('R'), numeric: true),
            DataColumn(label: Text('W'), numeric: true),
            DataColumn(label: Text('ER'), numeric: true),
          ],
          rows: inning.bowlingStats.entries.map((e) {
            final bowler = e.value;
            return DataRow(cells: [
              DataCell(Text(_getPlayerName(e.key), style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(bowler.oversString)),
              DataCell(Text(bowler.maidens.toString())),
              DataCell(Text(bowler.runsConceded.toString())),
              DataCell(Text(bowler.wickets.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(bowler.economy.toStringAsFixed(1))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _FootballScorecard extends StatelessWidget {
  const _FootballScorecard({
    required this.state,
    required this.match,
    this.playerNames,
  });
  final FootballState state;
  final MatchModel match;
  final Map<String, String>? playerNames;
  
  String _getPlayerName(String? id) {
    if (id == null || id.isEmpty) return 'Player';
    if (playerNames != null && playerNames![id] != null && playerNames![id]!.isNotEmpty) {
      return playerNames![id]!;
    }
    if (match.score != null) {
      final pNames = match.score!['player_names'];
      if (pNames is Map && pNames[id] != null && pNames[id].toString().isNotEmpty) {
        return pNames[id].toString();
      }
      final pStats = match.score!['player_stats'];
      if (pStats is Map && pStats[id] is Map && pStats[id]['name'] != null) {
        final n = pStats[id]['name'].toString();
        if (n.isNotEmpty) return n;
      }
    }
    final p = match.participants.where((e) => e.userId == id || e.teamId == id).firstOrNull;
    if (p?.userName != null && p!.userName!.isNotEmpty) return p.userName!;
    if (p?.teamName != null && p!.teamName!.isNotEmpty) return p.teamName!;

    if (id.startsWith('home_p_')) {
      final num = id.replaceFirst('home_p_', '');
      final t = match.homeTeamName ?? 'Team 1';
      return '$t Player $num';
    }
    if (id.startsWith('away_p_')) {
      final num = id.replaceFirst('away_p_', '');
      final t = match.awayTeamName ?? 'Team 2';
      return '$t Player $num';
    }

    if (id.length == 36 && id.contains('-')) {
      return 'Player';
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = state.playerStats;

    if (stats.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_soccer_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Football Match Stats', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text('Goal scorers, assists, and disciplinary cards will appear here as recorded.', style: AppTypography.caption),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingTextStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[700]),
          columns: const [
            DataColumn(label: Text('Player')),
            DataColumn(label: Text('Goals'), numeric: true),
            DataColumn(label: Text('Assists'), numeric: true),
            DataColumn(label: Text('YC'), numeric: true),
            DataColumn(label: Text('RC'), numeric: true),
          ],
          rows: stats.entries.map((e) {
            final s = e.value;
            return DataRow(cells: [
              DataCell(Text(_getPlayerName(e.key), style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text((s['goals'] ?? 0).toString())),
              DataCell(Text((s['assists'] ?? 0).toString())),
              DataCell(Text((s['yellow_cards'] ?? 0).toString())),
              DataCell(Text((s['red_cards'] ?? 0).toString())),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

class _BadmintonScorecard extends StatelessWidget {
  const _BadmintonScorecard({required this.state, required this.match});
  final BadmintonState state;
  final MatchModel match;

  String _getTeamName(String? id) {
    if (id == null || id.isEmpty) return 'Team';
    if (id == 'home') return match.homeTeamName ?? 'Team 1';
    if (id == 'away') return match.awayTeamName ?? 'Team 2';
    final p = match.participants.where((e) => e.teamId == id || e.userId == id).firstOrNull;
    return p?.teamName ?? p?.userName ?? match.homeTeamName ?? match.awayTeamName ?? 'Team';
  }

  @override
  Widget build(BuildContext context) {
    if (state.games.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_tennis_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Badminton Match Stats', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text('Game scores and rally points will appear here.', style: AppTypography.caption),
            ],
          ),
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Game')),
            DataColumn(label: Text(_getTeamName(state.homeId))),
            DataColumn(label: Text(_getTeamName(state.awayId))),
          ],
          rows: List.generate(state.games.length, (index) {
            final game = state.games[index];
            return DataRow(cells: [
              DataCell(Text('Game ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(game.homePoints.toString(), style: TextStyle(fontWeight: game.winnerId == state.homeId ? FontWeight.bold : FontWeight.normal))),
              DataCell(Text(game.awayPoints.toString(), style: TextStyle(fontWeight: game.winnerId == state.awayId ? FontWeight.bold : FontWeight.normal))),
            ]);
          }),
        ),
      ),
    );
  }
}
