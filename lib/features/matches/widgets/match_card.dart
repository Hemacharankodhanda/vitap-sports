import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/models/match_model.dart';

/// VIT-AP Sports — Google-style Match Card.
///
/// Presents sports fixtures (Cricket, Football, Badminton) in an iconic,
/// stacked two-row team layout matching Google's sports search cards:
/// - Real-time batting indicators (🏏)
/// - Tabular runs, wickets, and overs: e.g. 165/4 (20.0)
/// - Live chase equations: e.g. "Titans need 24 runs in 9 balls (RRR 16.0)"
/// - Result margins with winner highlighting
/// - Clean venue and scheduled time footer
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap});

  final MatchModel match;
  final VoidCallback? onTap;

  MatchStatus get _status {
    switch (match.status) {
      case 'live':
        return MatchStatus.live;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.upcoming;
    }
  }

  bool get _isLive => _status == MatchStatus.live;
  bool get _isCompleted => _status == MatchStatus.completed;
  bool get _isUpcoming => _status == MatchStatus.upcoming;

  String get _sportName => (match.sportName ?? 'Sport').trim();
  String get _sportLower => _sportName.toLowerCase();

  String get _sportHeaderLabel {
    final sName = _sportName.toUpperCase();
    if (match.format != null && match.format!.trim().isNotEmpty) {
      return '$sName • ${match.format!.trim().toUpperCase()}';
    }
    return sName;
  }

  IconData get _sportIcon {
    switch (_sportLower) {
      case 'cricket':
        return Icons.sports_cricket_rounded;
      case 'football':
        return Icons.sports_soccer_rounded;
      case 'badminton':
        return Icons.sports_tennis_rounded;
      case 'basketball':
        return Icons.sports_basketball_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeName = match.resolvedHomeTeamName ?? 'Team 1';
    final awayName = match.resolvedAwayTeamName ?? 'Team 2';

    if (_sportLower == 'cricket') {
      return _buildCricketCard(context, homeName, awayName, isDark);
    } else if (_sportLower == 'badminton') {
      return _buildBadmintonCard(context, homeName, awayName, isDark);
    } else {
      return _buildGenericCard(context, homeName, awayName, isDark);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1. CRICKET (GOOGLE-STYLE) SCORECARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildCricketCard(
    BuildContext context,
    String homeName,
    String awayName,
    bool isDark,
  ) {
    final data = _parseCricketData(homeName, awayName);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: AppSpacing.md),

          // Team 1 Row
          _buildTeamRow(
            context: context,
            teamName: homeName,
            isBatting: data.isHomeBatting,
            isWinner: data.isHomeWinner,
            scoreText: data.homeScoreText,
            oversText: data.homeOversText,
            hasBatted: data.homeHasBatted,
            isDark: isDark,
          ),
          const SizedBox(height: 6),

          // Team 2 Row
          _buildTeamRow(
            context: context,
            teamName: awayName,
            isBatting: data.isAwayBatting,
            isWinner: data.isAwayWinner,
            scoreText: data.awayScoreText,
            oversText: data.awayOversText,
            hasBatted: data.awayHasBatted,
            isDark: isDark,
          ),

          // Situation / Equation Banner
          if (data.situation != null && data.situation!.isNotEmpty)
            _buildSituationBanner(
              context: context,
              text: data.situation!,
              isLive: _isLive,
              isCompleted: _isCompleted,
              isDark: isDark,
            ),

          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  _CricketParsedData _parseCricketData(String homeName, String awayName) {
    final scoreMap = match.score;
    final resultMap = match.result;
    final inningsRaw = (scoreMap?['innings'] as List?) ?? (resultMap?['innings'] as List?);
    final currentInningsIndex = (scoreMap?['current_innings_index'] as num?)?.toInt() ?? 0;
    final target = (scoreMap?['target'] as num?)?.toInt();
    final oversConfig = (match.config?['overs_per_innings'] as num?)?.toInt() ??
        (scoreMap?['config']?['overs_per_innings'] as num?)?.toInt();

    Map<String, dynamic>? homeInning;
    Map<String, dynamic>? awayInning;

    if (inningsRaw != null && inningsRaw.isNotEmpty) {
      for (final item in inningsRaw) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final bId = m['batting_team_id']?.toString();
        if (bId == match.homeTeamId ||
            bId == 'home' ||
            match.participants.any((p) => p.side == 'home' && (p.teamId == bId || p.userId == bId))) {
          homeInning = m;
        } else if (bId == match.awayTeamId ||
            bId == 'away' ||
            match.participants.any((p) => p.side == 'away' && (p.teamId == bId || p.userId == bId))) {
          awayInning = m;
        }
      }

      // Positional fallback if unmapped
      if (homeInning == null && awayInning == null) {
        if (inningsRaw.isNotEmpty && inningsRaw[0] is Map) {
          homeInning = Map<String, dynamic>.from(inningsRaw[0] as Map);
        }
        if (inningsRaw.length > 1 && inningsRaw[1] is Map) {
          awayInning = Map<String, dynamic>.from(inningsRaw[1] as Map);
        }
      } else if (homeInning != null && awayInning == null && inningsRaw.length > 1) {
        for (final item in inningsRaw) {
          if (item is Map && item != homeInning) {
            awayInning = Map<String, dynamic>.from(item);
            break;
          }
        }
      } else if (awayInning != null && homeInning == null && inningsRaw.length > 1) {
        for (final item in inningsRaw) {
          if (item is Map && item != awayInning) {
            homeInning = Map<String, dynamic>.from(item);
            break;
          }
        }
      }
    }

    // Determine currently batting team
    bool isHomeBatting = false;
    bool isAwayBatting = false;
    if (_isLive && inningsRaw != null && inningsRaw.isNotEmpty) {
      final activeIdx = currentInningsIndex < inningsRaw.length ? currentInningsIndex : 0;
      final activeInn = inningsRaw[activeIdx];
      if (activeInn is Map) {
        final activeInnMap = Map<String, dynamic>.from(activeInn);
        if (activeInnMap == homeInning) {
          isHomeBatting = true;
        } else if (activeInnMap == awayInning) {
          isAwayBatting = true;
        } else {
          final bId = activeInnMap['batting_team_id']?.toString();
          if (bId == match.homeTeamId || bId == 'home') {
            isHomeBatting = true;
          } else {
            isAwayBatting = true;
          }
        }
      }
    }

    // Determine winner
    final winnerId = match.winnerTeamId;
    final winningName = match.winningTeamName;
    final isHomeWinner = _isCompleted &&
        (winnerId == match.homeTeamId || winnerId == 'home' || winningName == homeName);
    final isAwayWinner = _isCompleted &&
        (winnerId == match.awayTeamId || winnerId == 'away' || winningName == awayName);

    // Format home score
    String? homeScoreText;
    String? homeOversText;
    bool homeHasBatted = homeInning != null;
    if (homeInning != null) {
      final runs = (homeInning['total_runs'] as num?)?.toInt() ?? 0;
      final wkts = (homeInning['total_wickets'] as num?)?.toInt() ?? 0;
      homeScoreText = '$runs/$wkts';
      final balls = (homeInning['legal_balls'] as num?)?.toInt();
      if (balls != null) {
        homeOversText = '${balls ~/ 6}.${balls % 6}';
      } else if (homeInning['total_overs'] != null) {
        homeOversText = homeInning['total_overs'].toString();
      }
    } else if (match.homeScore != null) {
      homeScoreText = '${match.homeScore}';
      homeHasBatted = true;
    }

    // Format away score
    String? awayScoreText;
    String? awayOversText;
    bool awayHasBatted = awayInning != null;
    if (awayInning != null) {
      final runs = (awayInning['total_runs'] as num?)?.toInt() ?? 0;
      final wkts = (awayInning['total_wickets'] as num?)?.toInt() ?? 0;
      awayScoreText = '$runs/$wkts';
      final balls = (awayInning['legal_balls'] as num?)?.toInt();
      if (balls != null) {
        awayOversText = '${balls ~/ 6}.${balls % 6}';
      } else if (awayInning['total_overs'] != null) {
        awayOversText = awayInning['total_overs'].toString();
      }
    } else if (match.awayScore != null) {
      awayScoreText = '${match.awayScore}';
      awayHasBatted = true;
    }

    // Generate Google situation text
    String? situation;
    if (_isCompleted) {
      situation = match.resultMargin;
      if (situation == null || situation.isEmpty) {
        if (isHomeWinner) {
          situation = '$homeName won';
        } else if (isAwayWinner) {
          situation = '$awayName won';
        } else if (match.isDraw) {
          situation = 'Match tied';
        }
      } else {
        final sLower = situation.toLowerCase();
        if (!sLower.contains('won') && !sLower.contains('tied') && !sLower.contains('draw')) {
          final win = isHomeWinner ? homeName : (isAwayWinner ? awayName : winningName);
          if (win != null) situation = '$win $situation';
        }
      }
    } else if (_isLive) {
      if (currentInningsIndex == 1 && inningsRaw != null && inningsRaw.length >= 2) {
        final inn1 = inningsRaw[0] as Map;
        final inn2 = inningsRaw[1] as Map;
        final inn1Runs = (inn1['total_runs'] as num?)?.toInt() ?? 0;
        final inn2Runs = (inn2['total_runs'] as num?)?.toInt() ?? 0;
        final inn2Balls = (inn2['legal_balls'] as num?)?.toInt() ?? 0;
        final chasingTeam = isHomeBatting ? homeName : awayName;
        final targetRuns = target ?? (inn1Runs + 1);
        final needed = targetRuns - inn2Runs;

        if (oversConfig != null) {
          final maxBalls = oversConfig * 6;
          final ballsLeft = maxBalls - inn2Balls;
          if (needed > 0 && ballsLeft > 0) {
            final rrr = (needed / (ballsLeft / 6.0)).toStringAsFixed(1);
            situation = '$chasingTeam need $needed runs in $ballsLeft balls (RRR $rrr)';
          } else if (needed <= 0) {
            situation = '$chasingTeam need 0 runs to win';
          } else {
            situation = 'Innings completed';
          }
        } else {
          if (needed > 0) {
            situation = '$chasingTeam need $needed runs to win';
          }
        }
      } else if (inningsRaw != null && inningsRaw.isNotEmpty) {
        final inn1 = inningsRaw[0] as Map;
        final inn1Runs = (inn1['total_runs'] as num?)?.toInt() ?? 0;
        final inn1Balls = (inn1['legal_balls'] as num?)?.toInt() ?? 0;
        final battingName = isHomeBatting ? homeName : awayName;
        if (inn1['is_complete'] == true && target != null) {
          situation = 'Innings break • Target $target';
        } else if (inn1Balls > 0) {
          final crr = (inn1Runs / (inn1Balls / 6.0)).toStringAsFixed(1);
          situation = '$battingName batting • CRR $crr';
        } else {
          situation = '$battingName elected to bat';
        }
      }
    }

    return _CricketParsedData(
      homeScoreText: homeScoreText,
      homeOversText: homeOversText,
      homeHasBatted: homeHasBatted,
      isHomeBatting: isHomeBatting,
      isHomeWinner: isHomeWinner,
      awayScoreText: awayScoreText,
      awayOversText: awayOversText,
      awayHasBatted: awayHasBatted,
      isAwayBatting: isAwayBatting,
      isAwayWinner: isAwayWinner,
      situation: situation,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2. BADMINTON SCORECARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildBadmintonCard(
    BuildContext context,
    String homeName,
    String awayName,
    bool isDark,
  ) {
    final scoreMap = match.score;
    final resultMap = match.result;
    final hGames = (scoreMap?['home_games_won'] as num?)?.toInt() ??
        (resultMap?['home_games_won'] as num?)?.toInt() ??
        (scoreMap?['home_score'] as num?)?.toInt() ??
        (resultMap?['home_score'] as num?)?.toInt() ??
        match.homeScore;
    final aGames = (scoreMap?['away_games_won'] as num?)?.toInt() ??
        (resultMap?['away_games_won'] as num?)?.toInt() ??
        (scoreMap?['away_score'] as num?)?.toInt() ??
        (resultMap?['away_score'] as num?)?.toInt() ??
        match.awayScore;

    final winnerId = match.winnerTeamId;
    final isHomeWinner = _isCompleted &&
        (winnerId == match.homeTeamId ||
            winnerId == 'home' ||
            match.winningTeamName == homeName ||
            (hGames != null && aGames != null && hGames > aGames));
    final isAwayWinner = _isCompleted &&
        (winnerId == match.awayTeamId ||
            winnerId == 'away' ||
            match.winningTeamName == awayName ||
            (hGames != null && aGames != null && aGames > hGames));

    String? gamesSummary = resultMap?['games_summary']?.toString() ??
        scoreMap?['games_summary']?.toString();
    final gamesRaw = (scoreMap?['games'] as List?) ?? (resultMap?['games'] as List?);
    final homeGamePoints = <int>[];
    final awayGamePoints = <int>[];
    int currentHomePoints = 0;
    int currentAwayPoints = 0;

    if (gamesRaw != null && gamesRaw.isNotEmpty) {
      final list = <String>[];
      for (final g in gamesRaw) {
        if (g is Map) {
          final hp = (g['home_points'] as num?)?.toInt() ?? 0;
          final ap = (g['away_points'] as num?)?.toInt() ?? 0;
          homeGamePoints.add(hp);
          awayGamePoints.add(ap);
          if (hp > 0 || ap > 0 || g['is_completed'] == true) {
            list.add('$hp-$ap');
          }
        }
      }
      if (list.isNotEmpty && (gamesSummary == null || gamesSummary.isEmpty)) {
        gamesSummary = list.join(', ');
      }
      final curGame = gamesRaw.last;
      if (curGame is Map) {
        currentHomePoints = (curGame['home_points'] as num?)?.toInt() ?? 0;
        currentAwayPoints = (curGame['away_points'] as num?)?.toInt() ?? 0;
      }
    }

    if (homeGamePoints.isEmpty && gamesSummary != null && gamesSummary.isNotEmpty) {
      final reg = RegExp(r'(\d+)\s*[-–]\s*(\d+)');
      for (final match in reg.allMatches(gamesSummary)) {
        homeGamePoints.add(int.tryParse(match.group(1)!) ?? 0);
        awayGamePoints.add(int.tryParse(match.group(2)!) ?? 0);
      }
    }

    String? situation;
    if (_isCompleted) {
      if (match.resultMargin != null && match.resultMargin!.isNotEmpty) {
        situation = match.resultMargin;
      } else if (match.winningTeamName != null) {
        situation = gamesSummary != null && gamesSummary.isNotEmpty
            ? '${match.winningTeamName} won ($gamesSummary)'
            : '${match.winningTeamName} won';
      } else {
        situation = gamesSummary != null && gamesSummary.isNotEmpty
            ? 'Match Completed ($gamesSummary)'
            : 'Match Completed';
      }
    } else if (_isLive) {
      final curIdx = (scoreMap?['current_game_index'] as num?)?.toInt() ??
          (gamesRaw != null && gamesRaw.isNotEmpty ? gamesRaw.length - 1 : 0);
      situation = 'Game ${curIdx + 1}';
    }

    String? hScore;
    String? aScore;
    String? hOvers;
    String? aOvers;

    if (_isCompleted) {
      hScore = hGames != null ? '$hGames' : (homeGamePoints.isNotEmpty ? '${homeGamePoints.last}' : null);
      aScore = aGames != null ? '$aGames' : (awayGamePoints.isNotEmpty ? '${awayGamePoints.last}' : null);
      hOvers = homeGamePoints.isNotEmpty ? homeGamePoints.join(', ') : null;
      aOvers = awayGamePoints.isNotEmpty ? awayGamePoints.join(', ') : null;
    } else if (_isLive) {
      hScore = '$currentHomePoints pts';
      aScore = '$currentAwayPoints pts';
      hOvers = (hGames != null && hGames > 0) ? '$hGames ${(hGames == 1 ? "game" : "games")}' : null;
      aOvers = (aGames != null && aGames > 0) ? '$aGames ${(aGames == 1 ? "game" : "games")}' : null;
    } else {
      hScore = hGames != null ? '$hGames' : null;
      aScore = aGames != null ? '$aGames' : null;
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: AppSpacing.md),

          _buildTeamRow(
            context: context,
            teamName: homeName,
            isBatting: false,
            isWinner: isHomeWinner,
            scoreText: hScore,
            oversText: hOvers,
            hasBatted: hScore != null,
            isDark: isDark,
          ),
          const SizedBox(height: 6),

          _buildTeamRow(
            context: context,
            teamName: awayName,
            isBatting: false,
            isWinner: isAwayWinner,
            scoreText: aScore,
            oversText: aOvers,
            hasBatted: aScore != null,
            isDark: isDark,
          ),

          if (situation != null && situation.isNotEmpty)
            _buildSituationBanner(
              context: context,
              text: situation,
              isLive: _isLive,
              isCompleted: _isCompleted,
              isDark: isDark,
            ),

          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 3. FOOTBALL & GENERIC SCORECARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildGenericCard(
    BuildContext context,
    String homeName,
    String awayName,
    bool isDark,
  ) {
    final hScore = (match.score?['home_score'] as num?)?.toInt() ?? match.homeScore;
    final aScore = (match.score?['away_score'] as num?)?.toInt() ?? match.awayScore;

    final winnerId = match.winnerTeamId;
    final isHomeWinner = _isCompleted &&
        (winnerId == match.homeTeamId || winnerId == 'home' || match.winningTeamName == homeName);
    final isAwayWinner = _isCompleted &&
        (winnerId == match.awayTeamId || winnerId == 'away' || match.winningTeamName == awayName);

    String? situation;
    if (_isCompleted) {
      if (match.winningTeamName != null) {
        situation = '${match.winningTeamName} won';
      } else if (match.isDraw) {
        situation = 'Full Time • Draw';
      } else {
        situation = 'Full Time';
      }
    } else if (_isLive) {
      situation = 'Live Match';
    }

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: AppSpacing.md),

          _buildTeamRow(
            context: context,
            teamName: homeName,
            isBatting: false,
            isWinner: isHomeWinner,
            scoreText: hScore != null ? '$hScore' : null,
            oversText: null,
            hasBatted: hScore != null,
            isDark: isDark,
          ),
          const SizedBox(height: 6),

          _buildTeamRow(
            context: context,
            teamName: awayName,
            isBatting: false,
            isWinner: isAwayWinner,
            scoreText: aScore != null ? '$aScore' : null,
            oversText: null,
            hasBatted: aScore != null,
            isDark: isDark,
          ),

          if (situation != null && situation.isNotEmpty)
            _buildSituationBanner(
              context: context,
              text: situation,
              isLive: _isLive,
              isCompleted: _isCompleted,
              isDark: isDark,
            ),

          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SHARED REUSABLE WIDGETS
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_sportIcon, size: 16, color: primary),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  _sportHeaderLabel,
                  style: AppTypography.caption.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildStatusBadge() {
    switch (_status) {
      case MatchStatus.live:
        return const StatusLabel.live();
      case MatchStatus.upcoming:
        return const StatusLabel.upcoming();
      case MatchStatus.completed:
        return StatusLabel(
          label: _sportLower == 'cricket' ? 'Completed' : 'FT',
          variant: StatusLabelVariant.completed,
        );
      case MatchStatus.cancelled:
        return const StatusLabel(
          label: 'Cancelled',
          variant: StatusLabelVariant.completed,
        );
      case MatchStatus.paused:
        return const StatusLabel.paused();
    }
  }

  Widget _buildTeamRow({
    required BuildContext context,
    required String teamName,
    required bool isBatting,
    required bool isWinner,
    required String? scoreText,
    required String? oversText,
    required bool hasBatted,
    required bool isDark,
  }) {
    final isHighlighted = isBatting || (_isCompleted && isWinner);
    final isDimmed = _isCompleted && !isWinner && !match.isDraw;

    final nameColor = isDimmed
        ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
        : (isHighlighted
            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary));

    final fontWeight = isHighlighted ? FontWeight.bold : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Monogram Avatar
          _buildTeamAvatar(context, teamName, isDark, isHighlighted),
          const SizedBox(width: AppSpacing.sm),

          // Team Name + Batting Indicator
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    teamName,
                    style: AppTypography.headline.copyWith(
                      color: nameColor,
                      fontWeight: fontWeight,
                      fontSize: 15.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isBatting) ...[
                  const SizedBox(width: 6),
                  const Text('🏏', style: TextStyle(fontSize: 13)),
                ],
                if (_isCompleted && isWinner) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.success,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Score + Overs
          if (!_isUpcoming) ...[
            if (hasBatted && scoreText != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    scoreText,
                    style: AppTypography.headline.copyWith(
                      color: isDimmed
                          ? (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (oversText != null && oversText.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($oversText)',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (_isLive) ...[
              Text(
                'Yet to bat',
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                  fontStyle: FontStyle.italic,
                  fontSize: 12.5,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTeamAvatar(
    BuildContext context,
    String name,
    bool isDark,
    bool isHighlighted,
  ) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isHighlighted
            ? primary.withAlpha(isDark ? 45 : 30)
            : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighlighted
              ? primary.withAlpha(isDark ? 120 : 80)
              : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.bold,
          color: isHighlighted
              ? primary
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSituationBanner({
    required BuildContext context,
    required String text,
    required bool isLive,
    required bool isCompleted,
    required bool isDark,
  }) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    IconData icon;

    if (isCompleted) {
      textColor = AppColors.success;
      bgColor = AppColors.success.withAlpha(isDark ? 28 : 18);
      borderColor = AppColors.success.withAlpha(isDark ? 80 : 50);
      icon = Icons.emoji_events_outlined;
    } else if (isLive) {
      textColor = isDark ? AppColors.liveDark : AppColors.liveLight;
      bgColor = textColor.withAlpha(isDark ? 30 : 18);
      borderColor = textColor.withAlpha(isDark ? 80 : 50);
      icon = Icons.sports_cricket_outlined;
    } else {
      textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
      bgColor = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
      borderColor = Colors.transparent;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm + 2, bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Column(
      children: [
        Divider(
          height: AppSpacing.lg,
          thickness: 0.6,
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: AppSpacing.iconInline,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                match.venue,
                style: AppTypography.caption.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.schedule_rounded,
              size: AppSpacing.iconInline,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppDateUtils.formatSmartDateTime(match.scheduledAt),
              style: AppTypography.caption.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CricketParsedData {
  const _CricketParsedData({
    required this.homeScoreText,
    required this.homeOversText,
    required this.homeHasBatted,
    required this.isHomeBatting,
    required this.isHomeWinner,
    required this.awayScoreText,
    required this.awayOversText,
    required this.awayHasBatted,
    required this.isAwayBatting,
    required this.isAwayWinner,
    required this.situation,
  });

  final String? homeScoreText;
  final String? homeOversText;
  final bool homeHasBatted;
  final bool isHomeBatting;
  final bool isHomeWinner;

  final String? awayScoreText;
  final String? awayOversText;
  final bool awayHasBatted;
  final bool isAwayBatting;
  final bool isAwayWinner;

  final String? situation;
}
