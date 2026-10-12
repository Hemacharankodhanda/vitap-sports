// VIT-AP Sports — Professional Modern Scorecards.
/// Designed under the VIT-AP Sports Design Rules (Material 3 with Apple HIG restraint).
/// - Content first, chrome quiet.
/// - 90% neutrals, 8% accent, 2% semantic tokens.
/// - Flat surfaces with 1px hairline border over shadows.
/// - Numbers are the heroes with tabular figures.
/// - No emojis in interface chrome.
library;

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../scoring/engines/badminton/badminton_state.dart';
import '../../scoring/engines/cricket/cricket_state.dart';
import '../../scoring/engines/football/football_state.dart';
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

      // Empty state
      return _buildEmptyState(
        context,
        icon: Icons.scoreboard_rounded,
        title: 'Scorecard in progress',
        subtitle: 'Player statistics and detailed breakdown will appear once scoring begins.',
      );
    } catch (e, st) {
      debugPrint('Error in ProfessionalScorecard.build: $e\n$st');
      return _buildEmptyState(
        context,
        icon: Icons.scoreboard_rounded,
        title: 'Scorecard in progress',
        subtitle: 'Scorecard details will appear once loaded.',
      );
    }
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.title.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.caption.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. CRICKET PROFESSIONAL SCORECARD
// ─────────────────────────────────────────────────────────────

class _CricketScorecard extends StatefulWidget {
  const _CricketScorecard({
    required this.state,
    required this.match,
    this.playerNames,
  });

  final CricketState state;
  final MatchModel match;
  final Map<String, String>? playerNames;

  @override
  State<_CricketScorecard> createState() => _CricketScorecardState();
}

class _CricketScorecardState extends State<_CricketScorecard> {
  int _selectedInningsIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.state.currentInningsIndex < widget.state.innings.length) {
      _selectedInningsIndex = widget.state.currentInningsIndex;
    } else if (widget.state.innings.isNotEmpty) {
      _selectedInningsIndex = widget.state.innings.length - 1;
    }
  }

  String _getPlayerName(String? id) {
    if (id == null || id.isEmpty) return 'Player';
    if (widget.playerNames != null &&
        widget.playerNames![id] != null &&
        widget.playerNames![id]!.isNotEmpty) {
      return widget.playerNames![id]!;
    }
    if (widget.match.score != null) {
      final pNames = widget.match.score!['player_names'];
      if (pNames is Map && pNames[id] != null && pNames[id].toString().isNotEmpty) {
        return pNames[id].toString();
      }
      final pStats = widget.match.score!['player_stats'];
      if (pStats is Map && pStats[id] is Map && pStats[id]['name'] != null) {
        final n = pStats[id]['name'].toString();
        if (n.isNotEmpty) return n;
      }
    }
    final p = widget.match.participants
        .where((e) => e.userId == id || e.teamId == id)
        .firstOrNull;
    if (p?.userName != null && p!.userName!.isNotEmpty) return p.userName!;
    if (p?.teamName != null && p!.teamName!.isNotEmpty) return p.teamName!;

    final idLower = id.toLowerCase().trim();
    if (idLower == 'batter 1' ||
        idLower == 'batter 2' ||
        idLower == 'bowler 1' ||
        idLower == 'striker 1' ||
        idLower == 'non-striker 2' ||
        idLower == 'opening bowler') {
      final isCricket = widget.state is CricketState && (widget.state as CricketState).innings.isNotEmpty;
      final battingTeamId = isCricket
          ? (widget.state as CricketState).innings[_selectedInningsIndex.clamp(0, (widget.state as CricketState).innings.length - 1)].battingTeamId
          : widget.match.homeTeamId;
      final isHomeBatting = battingTeamId == widget.match.homeTeamId || battingTeamId == 'home';
      final battingTeamName = isHomeBatting ? (widget.match.homeTeamName ?? 'Team 1') : (widget.match.awayTeamName ?? 'Team 2');
      final bowlingTeamName = isHomeBatting ? (widget.match.awayTeamName ?? 'Team 2') : (widget.match.homeTeamName ?? 'Team 1');

      final battingParticipants = widget.match.participants
          .where((e) => (isHomeBatting ? (e.teamId == widget.match.homeTeamId || e.teamId == 'home') : (e.teamId == widget.match.awayTeamId || e.teamId == 'away')) && e.userName != null && e.userName!.isNotEmpty)
          .toList();
      final bowlingParticipants = widget.match.participants
          .where((e) => (isHomeBatting ? (e.teamId == widget.match.awayTeamId || e.teamId == 'away') : (e.teamId == widget.match.homeTeamId || e.teamId == 'home')) && e.userName != null && e.userName!.isNotEmpty)
          .toList();

      if (idLower == 'batter 1' || idLower == 'striker 1') {
        if (battingParticipants.isNotEmpty) return battingParticipants[0].userName!;
        return '$battingTeamName Player 1';
      }
      if (idLower == 'batter 2' || idLower == 'striker 2' || idLower == 'non-striker 2') {
        if (battingParticipants.length > 1) return battingParticipants[1].userName!;
        return '$battingTeamName Player 2';
      }
      if (idLower == 'bowler 1' || idLower == 'opening bowler') {
        if (bowlingParticipants.isNotEmpty) return bowlingParticipants[0].userName!;
        return '$bowlingTeamName Bowler 1';
      }
    }

    if (id.startsWith('home_p_')) {
      final num = int.tryParse(id.replaceFirst('home_p_', '')) ?? 1;
      final homeParts = widget.match.participants
          .where((e) => (e.teamId == widget.match.homeTeamId || e.teamId == 'home') && e.userName != null && e.userName!.isNotEmpty)
          .toList();
      if (num > 0 && num <= homeParts.length) return homeParts[num - 1].userName!;
      final t = widget.match.homeTeamName ?? 'Team 1';
      return '$t Player $num';
    }
    if (id.startsWith('away_p_')) {
      final num = int.tryParse(id.replaceFirst('away_p_', '')) ?? 1;
      final awayParts = widget.match.participants
          .where((e) => (e.teamId == widget.match.awayTeamId || e.teamId == 'away') && e.userName != null && e.userName!.isNotEmpty)
          .toList();
      if (num > 0 && num <= awayParts.length) return awayParts[num - 1].userName!;
      final t = widget.match.awayTeamName ?? 'Team 2';
      return '$t Player $num';
    }

    if (id.length == 36 && id.contains('-')) {
      return 'Player';
    }
    return id;
  }

  String _getTeamName(String? id) {
    if (id == null || id.isEmpty) return 'Team';
    if (id == 'home') return widget.match.resolvedHomeTeamName ?? 'Team 1';
    if (id == 'away') return widget.match.resolvedAwayTeamName ?? 'Team 2';
    final p = widget.match.participants
        .where((e) => e.teamId == id || e.userId == id)
        .firstOrNull;
    return p?.teamName ??
        p?.userName ??
        (id == widget.match.homeTeamId
            ? widget.match.resolvedHomeTeamName
            : widget.match.resolvedAwayTeamName) ??
        'Team';
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final state = widget.state;

    if (state.innings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_cricket_rounded, size: 24, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Innings in progress', style: AppTypography.title.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Deliveries and batter records will update here in real time.',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = _selectedInningsIndex.clamp(0, state.innings.length - 1);
    final selectedInning = state.innings[safeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Innings Tabs Selector (when multiple innings exist)
        if (state.innings.length > 1) ...[
          _buildInningsTabs(state, colors),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. Selected Innings Header & Stats
        _buildInningsHeader(selectedInning, colors),
        const SizedBox(height: AppSpacing.md),

        // 3. Batting Scorecard Table
        _buildBattingCard(selectedInning, colors),
        const SizedBox(height: AppSpacing.lg),

        // 4. Bowling Scorecard Table
        _buildBowlingCard(selectedInning, colors),

        // 5. If more than 1 innings, switch view
        if (state.innings.length > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedInningsIndex = (_selectedInningsIndex == 0) ? 1 : 0;
                });
              },
              icon: Icon(Icons.swap_horiz_rounded, size: 18, color: colors.accent),
              label: Text(
                'View ${_getTeamName(state.innings[(_selectedInningsIndex == 0) ? 1 : 0].battingTeamId)} innings',
                style: AppTypography.callout.copyWith(color: colors.accent),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInningsTabs(CricketState state, AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: List.generate(state.innings.length, (idx) {
          final inn = state.innings[idx];
          final isSelected = idx == _selectedInningsIndex;
          final teamName = _getTeamName(inn.battingTeamId);

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedInningsIndex = idx),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: colors.border, width: 1) : null,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Small team marker
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accent : colors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            teamName,
                            style: AppTypography.caption.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? colors.textPrimary : colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inn.totalRuns}/${inn.totalWickets} (${inn.overs.toStringAsFixed(1)})',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInningsHeader(CricketInningsState inning, AppColorsExtension colors) {
    final teamName = _getTeamName(inning.battingTeamId);
    final crr = inning.runRate.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '$teamName Innings',
                        style: AppTypography.headline.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'CRR $crr rpo',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${inning.totalRuns}',
                    style: AppTypography.largeTitle.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    '/${inning.totalWickets}',
                    style: AppTypography.title.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${inning.overs.toStringAsFixed(1)} ov',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattingCard(CricketInningsState inning, AppColorsExtension colors) {
    if (inning.battingStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Center(
          child: Text(
            'No batting entries recorded yet.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius - 1)),
              border: Border(bottom: BorderSide(color: colors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'BATTER',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _statColHeader('R', 38, colors, isHighlight: true),
                _statColHeader('B', 32, colors),
                _statColHeader('4s', 28, colors),
                _statColHeader('6s', 28, colors),
                _statColHeader('SR', 52, colors),
              ],
            ),
          ),

          // Batter Rows
          ...inning.battingStats.entries.map((entry) {
            final batter = entry.value;
            final isNotOut = !batter.isOut;
            final name = _getPlayerName(entry.key);
            final displayName = '$name${isNotOut && batter.ballsFaced > 0 ? "*" : ""}';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.callout.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          batter.isOut
                              ? _formatDismissal(batter)
                              : (batter.ballsFaced > 0 ? 'not out' : 'yet to bat'),
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statColValue(
                    batter.runs.toString(),
                    38,
                    colors,
                    isHighlight: true,
                    isBoundary: batter.runs >= 50,
                  ),
                  _statColValue(batter.ballsFaced.toString(), 32, colors),
                  _statColValue(batter.fours.toString(), 28, colors),
                  _statColValue(batter.sixes.toString(), 28, colors),
                  _statColValue(
                    batter.ballsFaced > 0 ? batter.strikeRate.toStringAsFixed(1) : '-',
                    52,
                    colors,
                  ),
                ],
              ),
            );
          }),

          // Extras Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extras',
                  style: AppTypography.callout.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${inning.totalExtras} (b ${inning.byes}, lb ${inning.legByes}, w ${inning.wides}, nb ${inning.noBalls})',
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Total Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.cardRadius - 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${inning.totalRuns}/${inning.totalWickets} (${inning.overs.toStringAsFixed(1)} ov, CRR: ${inning.runRate.toStringAsFixed(2)})',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingCard(CricketInningsState inning, AppColorsExtension colors) {
    if (inning.bowlingStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Center(
          child: Text(
            'No bowling entries recorded yet.',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius - 1)),
              border: Border(bottom: BorderSide(color: colors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'BOWLER',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _statColHeader('O', 34, colors),
                _statColHeader('M', 28, colors),
                _statColHeader('R', 36, colors),
                _statColHeader('W', 30, colors, isHighlight: true),
                _statColHeader('ECON', 48, colors),
              ],
            ),
          ),

          // Bowler Rows
          ...inning.bowlingStats.entries.map((entry) {
            final bowler = entry.value;
            final bowlerName = _getPlayerName(entry.key);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bowlerName,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statColValue(bowler.oversString, 34, colors),
                  _statColValue(bowler.maidens.toString(), 28, colors),
                  _statColValue(bowler.runsConceded.toString(), 36, colors),
                  _statColValue(
                    bowler.wickets.toString(),
                    30,
                    colors,
                    isHighlight: true,
                    isBoundary: bowler.wickets >= 3,
                  ),
                  _statColValue(bowler.economy.toStringAsFixed(1), 48, colors),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statColHeader(String title, double width, AppColorsExtension colors, {bool isHighlight = false}) {
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

  Widget _statColValue(
    String val,
    double width,
    AppColorsExtension colors, {
    bool isHighlight = false,
    bool isBoundary = false,
  }) {
    Color textColor = colors.textPrimary;
    if (isHighlight) {
      textColor = isBoundary ? colors.win : colors.accent;
    }

    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 13,
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. FOOTBALL PROFESSIONAL SCORECARD
// ─────────────────────────────────────────────────────────────

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
      final num = int.tryParse(id.replaceFirst('home_p_', '')) ?? 1;
      final homeParts = match.participants
          .where((e) => (e.teamId == match.homeTeamId || e.teamId == 'home') && e.userName != null && e.userName!.isNotEmpty)
          .toList();
      if (num > 0 && num <= homeParts.length) return homeParts[num - 1].userName!;
      final t = match.homeTeamName ?? 'Team 1';
      return '$t Player $num';
    }
    if (id.startsWith('away_p_')) {
      final num = int.tryParse(id.replaceFirst('away_p_', '')) ?? 1;
      final awayParts = match.participants
          .where((e) => (e.teamId == match.awayTeamId || e.teamId == 'away') && e.userName != null && e.userName!.isNotEmpty)
          .toList();
      if (num > 0 && num <= awayParts.length) return awayParts[num - 1].userName!;
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
    final colors = context.appColors;
    final stats = state.playerStats;

    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_soccer_rounded, size: 24, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Football match stats', style: AppTypography.title.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Goalscorers, assists, and disciplinary cards will appear here as recorded.',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header (Quiet chrome, no emojis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius - 1)),
              border: Border(bottom: BorderSide(color: colors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PLAYER',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _colHeader('G', 38, colors),
                _colHeader('A', 38, colors),
                _colHeader('YC', 38, colors),
                _colHeader('RC', 38, colors),
              ],
            ),
          ),
          ...stats.entries.map((entry) {
            final s = entry.value;
            final pName = _getPlayerName(entry.key);
            final goals = s['goals'] ?? 0;
            final assists = s['assists'] ?? 0;
            final yc = s['yellow_cards'] ?? 0;
            final rc = s['red_cards'] ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      pName,
                      style: AppTypography.callout.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _colValue(goals.toString(), 38, colors, isHighlight: goals > 0),
                  _colValue(assists > 0 ? assists.toString() : '-', 38, colors),
                  _colValue(yc > 0 ? yc.toString() : '-', 38, colors),
                  _colValue(rc > 0 ? rc.toString() : '-', 38, colors, isDestructive: rc > 0),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _colHeader(String title, double width, AppColorsExtension colors) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _colValue(
    String val,
    double width,
    AppColorsExtension colors, {
    bool isHighlight = false,
    bool isDestructive = false,
  }) {
    Color textColor = colors.textPrimary;
    if (isHighlight) {
      textColor = colors.win;
    } else if (isDestructive) {
      textColor = colors.loss;
    } else if (val == '-') {
      textColor = colors.textTertiary;
    }

    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontFamily: AppTypography.caption.fontFamily,
          fontSize: 13,
          fontWeight: isHighlight || isDestructive ? FontWeight.w600 : FontWeight.w400,
          color: textColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. BADMINTON PROFESSIONAL SCORECARD
// ─────────────────────────────────────────────────────────────

class _BadmintonScorecard extends StatelessWidget {
  const _BadmintonScorecard({required this.state, required this.match});
  final BadmintonState state;
  final MatchModel match;

  String _getTeamName(String? id) {
    if (id == null || id.isEmpty) return 'Team';
    if (id == 'home' || id == match.homeTeamId || id == state.homeId) {
      return match.resolvedHomeTeamName ?? 'Team 1';
    }
    if (id == 'away' || id == match.awayTeamId || id == state.awayId) {
      return match.resolvedAwayTeamName ?? 'Team 2';
    }
    final p = match.participants.where((e) => e.teamId == id || e.userId == id).firstOrNull;
    return p?.teamName ??
        p?.userName ??
        (id == state.homeId ? match.resolvedHomeTeamName : match.resolvedAwayTeamName) ??
        'Team';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final homeName = _getTeamName(state.homeId);
    final awayName = _getTeamName(state.awayId);

    if (state.games.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_tennis_rounded, size: 24, color: colors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Badminton match stats', style: AppTypography.title.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Game scores and rally points will appear here as recorded.',
                style: AppTypography.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overall Games Won Summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        homeName,
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.homeGamesWon}',
                    style: AppTypography.titleLarge.copyWith(
                      color: state.homeGamesWon > state.awayGamesWon ? colors.win : colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Games won',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
              Text(
                'VS',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textTertiary,
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        awayName,
                        style: AppTypography.callout.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.awayGamesWon}',
                    style: AppTypography.titleLarge.copyWith(
                      color: state.awayGamesWon > state.homeGamesWon ? colors.win : colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Games won',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Game by Game Breakdown Cards
        ...List.generate(state.games.length, (idx) {
          final game = state.games[idx];
          final isHomeWinner = game.winnerId == state.homeId || (game.isCompleted && game.homePoints > game.awayPoints);
          final isAwayWinner = game.winnerId == state.awayId || (game.isCompleted && game.awayPoints > game.homePoints);

          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPadding, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: colors.border, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colors.border, width: 0.5),
                  ),
                  child: Text(
                    'Game ${idx + 1}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '${game.homePoints}',
                        style: TextStyle(
                          fontFamily: AppTypography.title.fontFamily,
                          fontSize: 18,
                          fontWeight: isHomeWinner ? FontWeight.w700 : FontWeight.w500,
                          color: isHomeWinner ? colors.win : colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '-',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textTertiary,
                        ),
                      ),
                      Text(
                        '${game.awayPoints}',
                        style: TextStyle(
                          fontFamily: AppTypography.title.fontFamily,
                          fontSize: 18,
                          fontWeight: isAwayWinner ? FontWeight.w700 : FontWeight.w500,
                          color: isAwayWinner ? colors.win : colors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (game.isCompleted)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colors.win,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
