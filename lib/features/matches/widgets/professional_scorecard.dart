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
  const ProfessionalScorecard({super.key, required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    if (match.score == null) return const SizedBox.shrink();

    final sportLower = match.sportName?.toLowerCase() ?? '';
    
    if (sportLower == 'cricket') {
      return _CricketScorecard(state: CricketState.fromJson(match.score!), match: match);
    } else if (sportLower == 'football') {
      return _FootballScorecard(state: FootballState.fromJson(match.score!), match: match);
    } else if (sportLower == 'badminton') {
      return _BadmintonScorecard(state: BadmintonState.fromJson(match.score!), match: match);
    }

    return const SizedBox.shrink();
  }
}

class _CricketScorecard extends StatelessWidget {
  const _CricketScorecard({required this.state, required this.match});
  final CricketState state;
  final MatchModel match;

  String _getPlayerName(String? id) {
    if (id == null) return 'Unknown';
    final p = match.participants.where((e) => e.userId == id).firstOrNull;
    return p?.userName ?? id;
  }

  String _getTeamName(String? id) {
    if (id == null) return 'Team';
    final p = match.participants.where((e) => e.teamId == id).firstOrNull;
    return p?.teamName ?? 'Team';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < state.innings.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xl),
          Text(
            '${_getTeamName(state.innings[i].battingTeamId)} Innings',
            style: AppTypography.title.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
          Text(
            '${state.innings[i].totalRuns}/${state.innings[i].totalWickets} (${state.innings[i].overs.toStringAsFixed(1)} Ov)',
            style: AppTypography.body,
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
                        batter.howOut!,
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
  const _FootballScorecard({required this.state, required this.match});
  final FootballState state;
  final MatchModel match;
  
  String _getPlayerName(String? id) {
    if (id == null) return 'Unknown';
    final p = match.participants.where((e) => e.userId == id).firstOrNull;
    return p?.userName ?? id;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = state.playerStats;

    if (stats.isEmpty) {
      return const Center(child: Text('No player statistics recorded.'));
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
    if (id == null) return 'Team';
    final p = match.participants.where((e) => e.teamId == id).firstOrNull;
    return p?.teamName ?? 'Team';
  }

  @override
  Widget build(BuildContext context) {
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
