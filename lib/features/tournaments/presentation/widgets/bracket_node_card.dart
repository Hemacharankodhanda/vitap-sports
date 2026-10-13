/// VIT-AP Sports — Bracket Node Card.
///
/// Compact 2-slot match card representing a knockout bracket node.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament_models.dart';

class BracketNodeCard extends StatelessWidget {
  const BracketNodeCard({
    required this.fixture,
    this.entryA,
    this.entryB,
    this.onTap,
    super.key,
  });

  final TournamentFixture fixture;
  final TournamentEntry? entryA;
  final TournamentEntry? entryB;
  final VoidCallback? onTap;

  static const double cardWidth = 200.0;
  static const double cardHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isLive = fixture.status == FixtureStatus.live;
    final isCompleted = fixture.status == FixtureStatus.completed || fixture.status == FixtureStatus.walkover;

    final winnerId = fixture.winnerEntryId;
    final isAWinner = isCompleted && winnerId != null && winnerId == entryA?.id;
    final isBWinner = isCompleted && winnerId != null && winnerId == entryB?.id;

    final nameA = entryA?.displayName ?? (fixture.isBye && fixture.entryAId == null ? 'Bye' : (fixture.sourceFixtureAId != null ? 'Winner of M${fixture.sourceFixtureAId!.split('_').last}' : 'TBD'));
    final nameB = entryB?.displayName ?? (fixture.isBye && fixture.entryBId == null ? 'Bye' : (fixture.sourceFixtureBId != null ? 'Winner of M${fixture.sourceFixtureBId!.split('_').last}' : 'TBD'));

    final scoreA = _extractScore(fixture.result, isA: true);
    final scoreB = _extractScore(fixture.result, isA: false);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLive ? AppColors.live : colors.border,
            width: isLive ? 1.5 : 1.0,
          ),
          boxShadow: isLive
              ? [
                  BoxShadow(
                    color: AppColors.live.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Slot A
                Expanded(
                  child: _SlotRow(
                    seed: entryA?.seed,
                    name: nameA,
                    score: scoreA,
                    isWinner: isAWinner,
                    isBye: fixture.isBye && entryA == null,
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.border,
                ),
                // Slot B
                Expanded(
                  child: _SlotRow(
                    seed: entryB?.seed,
                    name: nameB,
                    score: scoreB,
                    isWinner: isBWinner,
                    isBye: fixture.isBye && entryB == null,
                  ),
                ),
              ],
            ),
            if (isLive)
              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.live,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _extractScore(Map<String, dynamic> result, {required bool isA}) {
    if (result.isEmpty) return null;
    if (result['result_type'] == 'bye') return 'Bye';
    if (result['result_type'] == 'walkover') {
      return result['winner_entry_id'] == (isA ? fixture.entryAId : fixture.entryBId) ? 'W/O' : '-';
    }

    if (result['football'] is Map) {
      final fb = result['football'] as Map<String, dynamic>;
      final val = isA ? fb['goals_a'] : fb['goals_b'];
      if (val != null) return val.toString();
    }
    if (result['cricket'] is Map) {
      final ckt = result['cricket'] as Map<String, dynamic>;
      final team = isA ? ckt['a'] : ckt['b'];
      if (team is Map) {
        final r = team['runs'];
        final w = team['wickets'];
        if (r != null) return '$r${w != null ? '/$w' : ''}';
      }
    }
    if (result['badminton'] is Map) {
      final bm = result['badminton'] as Map<String, dynamic>;
      final g = isA ? bm['games_won_a'] : bm['games_won_b'];
      if (g != null) return g.toString();
    }

    final key = isA ? 'home_score' : 'away_score';
    if (result.containsKey(key) && result[key] != null) {
      return result[key].toString();
    }

    return null;
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.name,
    this.seed,
    this.score,
    this.isWinner = false,
    this.isBye = false,
  });

  final int? seed;
  final String name;
  final String? score;
  final bool isWinner;
  final bool isBye;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      color: isWinner ? AppColors.accentSurface : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          if (seed != null) ...[
            Text(
              '$seed',
              style: AppTypography.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                color: isWinner
                    ? colors.textPrimary
                    : (isBye ? colors.textTertiary : colors.textSecondary),
              ),
            ),
          ),
          if (score != null) ...[
            const SizedBox(width: 4),
            Text(
              score!,
              style: AppTypography.caption.copyWith(
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                color: isWinner ? AppColors.accent : colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
