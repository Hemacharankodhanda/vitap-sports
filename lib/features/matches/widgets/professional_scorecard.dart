// VIT-AP Sports — Professional Modern Scorecards.
/// Designed with modern sports aesthetics (Cricbuzz, ESPNcricinfo, FotMob, Sofascore).
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
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

      // Informative placeholder
      return _buildEmptyState(
        context,
        icon: Icons.scoreboard_outlined,
        title: 'Scorecard In Progress',
        subtitle: 'Detailed statistics and player scorecards will appear once scoring events are recorded.',
      );
    } catch (e, st) {
      debugPrint('Error in ProfessionalScorecard.build: $e\n$st');
      return _buildEmptyState(
        context,
        icon: Icons.scoreboard_outlined,
        title: 'Scorecard In Progress',
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.title.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTypography.caption,
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
    // Default to active innings if match is live, or latest innings
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

    if (id.startsWith('home_p_')) {
      final num = id.replaceFirst('home_p_', '');
      final t = widget.match.homeTeamName ?? 'Team 1';
      return '$t Player $num';
    }
    if (id.startsWith('away_p_')) {
      final num = id.replaceFirst('away_p_', '');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.state;

    if (state.innings.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_cricket_rounded,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Innings In Progress', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Deliveries and batter records will update here in real time.',
                style: AppTypography.caption,
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
          _buildInningsTabs(state, isDark),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. Selected Innings Header & Stats
        _buildInningsHeader(selectedInning, isDark),
        const SizedBox(height: AppSpacing.md),

        // 3. Batting Scorecard Table
        _buildBattingCard(selectedInning, isDark),
        const SizedBox(height: AppSpacing.lg),

        // 4. Bowling Scorecard Table
        _buildBowlingCard(selectedInning, isDark),

        // 5. If more than 1 innings and viewing all, also show the other innings smoothly
        if (state.innings.length > 1) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Other Innings',
                style: AppTypography.headline.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedInningsIndex = (_selectedInningsIndex == 0) ? 1 : 0;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Switch to ${_getTeamName(state.innings[(_selectedInningsIndex == 0) ? 1 : 0].battingTeamId)}'),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInningsTabs(CricketState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: List.generate(state.innings.length, (idx) {
          final inn = state.innings[idx];
          final isSelected = idx == _selectedInningsIndex;
          final teamName = _getTeamName(inn.battingTeamId);

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedInningsIndex = idx),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm,
                  horizontal: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      teamName,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${inn.totalRuns}/${inn.totalWickets} (${inn.overs.toStringAsFixed(1)})',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected
                            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
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

  Widget _buildInningsHeader(CricketInningsState inning, bool isDark) {
    final teamName = _getTeamName(inning.battingTeamId);
    final crr = inning.runRate.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teamName Innings',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'CRR: $crr rpo',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '/${inning.totalWickets}',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '(${inning.overs.toStringAsFixed(1)} Ov)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBattingCard(CricketInningsState inning, bool isDark) {
    if (inning.battingStats.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Text('No batting entries recorded yet.', style: AppTypography.caption),
          ),
        ),
      );
    }

    final headerBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9);
    final dividerColor = isDark ? const Color(0xFF262F3E) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'BATTER',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                _statColHeader('R', 38, isDark, isHighlight: true),
                _statColHeader('B', 32, isDark),
                _statColHeader('4s', 28, isDark),
                _statColHeader('6s', 28, isDark),
                _statColHeader('SR', 52, isDark),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isNotOut && batter.ballsFaced > 0) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.live.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'not out',
                                  style: AppTypography.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.live,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (batter.isOut && batter.howOut != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatDismissal(batter),
                              style: AppTypography.caption.copyWith(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _statColValue(
                    batter.runs.toString(),
                    38,
                    isDark,
                    isHighlight: true,
                    isBoundary: batter.runs >= 50,
                  ),
                  _statColValue(batter.ballsFaced.toString(), 32, isDark),
                  _statColValue(batter.fours.toString(), 28, isDark),
                  _statColValue(batter.sixes.toString(), 28, isDark),
                  _statColValue(batter.strikeRate.toStringAsFixed(1), 52, isDark),
                ],
              ),
            );
          }),

          // Extras Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant.withAlpha(50) : AppColors.lightSurfaceVariant.withAlpha(50),
              border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Extras',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '${inning.totalExtras} (b ${inning.byes}, lb ${inning.legByes}, w ${inning.wides}, nb ${inning.noBalls})',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Total Summary Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(15),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.cardRadius)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.headline.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${inning.totalRuns}/${inning.totalWickets} (${inning.overs.toStringAsFixed(1)} Ov, RR: ${inning.runRate.toStringAsFixed(2)})',
                  style: AppTypography.headline.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBowlingCard(CricketInningsState inning, bool isDark) {
    if (inning.bowlingStats.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Text('No bowling entries recorded yet.', style: AppTypography.caption),
          ),
        ),
      );
    }

    final headerBg = isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9);
    final dividerColor = isDark ? const Color(0xFF262F3E) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bowling Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'BOWLER',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                _statColHeader('O', 34, isDark),
                _statColHeader('M', 28, isDark),
                _statColHeader('R', 36, isDark),
                _statColHeader('W', 30, isDark, isHighlight: true),
                _statColHeader('ECON', 48, isDark),
              ],
            ),
          ),

          // Bowler Rows
          ...inning.bowlingStats.entries.map((entry) {
            final bowler = entry.value;
            final bowlerName = _getPlayerName(entry.key);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: dividerColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      bowlerName,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _statColValue(bowler.oversString, 34, isDark),
                  _statColValue(bowler.maidens.toString(), 28, isDark),
                  _statColValue(bowler.runsConceded.toString(), 36, isDark),
                  _statColValue(
                    bowler.wickets.toString(),
                    30,
                    isDark,
                    isHighlight: true,
                    isBoundary: bowler.wickets >= 3,
                  ),
                  _statColValue(bowler.economy.toStringAsFixed(1), 48, isDark),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statColHeader(String title, double width, bool isDark, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
          color: isHighlight
              ? Theme.of(context).colorScheme.primary
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _statColValue(
    String val,
    double width,
    bool isDark, {
    bool isHighlight = false,
    bool isBoundary = false,
  }) {
    Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    if (isHighlight) {
      textColor = isBoundary ? const Color(0xFFF59E0B) : Theme.of(context).colorScheme.primary;
    }

    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
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
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_soccer_rounded,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text('Football Match Stats', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Goal scorers, assists, and disciplinary cards will appear here as recorded.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark ? const Color(0xFF262F3E) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.cardRadius)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PLAYER',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      _colHeader('GOALS ⚽', 65, isDark),
                      _colHeader('AST 🎯', 55, isDark),
                      _colHeader('YC 🟨', 45, isDark),
                      _colHeader('RC 🟥', 45, isDark),
                    ],
                  ),
                ),
                ...stats.entries.map((entry) {
                  final s = entry.value;
                  final pName = _getPlayerName(entry.key);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF262F3E) : const Color(0xFFE2E8F0),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            pName,
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _colValue((s['goals'] ?? 0).toString(), 65, isDark, isHighlight: (s['goals'] ?? 0) > 0),
                        _colValue((s['assists'] ?? 0).toString(), 55, isDark),
                        _colValue((s['yellow_cards'] ?? 0).toString(), 45, isDark),
                        _colValue((s['red_cards'] ?? 0).toString(), 45, isDark),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
  }

  Widget _colHeader(String title, double width, bool isDark) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _colValue(String val, double width, bool isDark, {bool isHighlight = false}) {
    return SizedBox(
      width: width,
      child: Text(
        val,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          color: isHighlight ? const Color(0xFF10B981) : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
    if (id == 'home') return match.resolvedHomeTeamName ?? 'Team 1';
    if (id == 'away') return match.resolvedAwayTeamName ?? 'Team 2';
    final p = match.participants.where((e) => e.teamId == id || e.userId == id).firstOrNull;
    return p?.teamName ??
        p?.userName ??
        (id == match.homeTeamId ? match.resolvedHomeTeamName : match.resolvedAwayTeamName) ??
        'Team';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeName = _getTeamName(state.homeId);
    final awayName = _getTeamName(state.awayId);

    if (state.games.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_tennis_rounded,
                  size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: AppSpacing.sm),
              Text('Badminton Match Stats', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text('Game scores and rally points will appear here.', style: AppTypography.caption),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(30),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(homeName, style: AppTypography.headline.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.homeGamesWon} Games',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                      color: state.homeGamesWon > state.awayGamesWon
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ],
              ),
              Text(
                'VS',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Column(
                children: [
                  Text(awayName, style: AppTypography.headline.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.awayGamesWon} Games',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w800,
                      color: state.awayGamesWon > state.homeGamesWon
                          ? Theme.of(context).colorScheme.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: isDark ? const Color(0xFF262F3E) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'G${idx + 1}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
                          fontSize: 18,
                          fontWeight: isHomeWinner ? FontWeight.bold : FontWeight.w500,
                          color: isHomeWinner
                              ? Theme.of(context).colorScheme.primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                      Text(
                        '-',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${game.awayPoints}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isAwayWinner ? FontWeight.bold : FontWeight.w500,
                          color: isAwayWinner
                              ? Theme.of(context).colorScheme.primary
                              : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                if (game.isCompleted)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
