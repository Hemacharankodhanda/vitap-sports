/// VIT-AP Sports — Tournament Standings Table.
///
/// Standings table presenting derived league/group standings with tabular figures,
/// qualification zone indicators, and head-to-head tie-break resolution.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/tournament_models.dart';

class TournamentStandingsTable extends StatelessWidget {
  const TournamentStandingsTable({
    required this.sport,
    required this.rows,
    this.qualifiersCount = 2,
    super.key,
  });

  final String sport;
  final List<TournamentStandingsRow> rows;
  final int qualifiersCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No standings data available yet',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
        ),
      );
    }

    final isCricket = sport.toLowerCase().contains('cricket');
    final isBadminton = sport.toLowerCase().contains('badminton');

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.border.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'TEAM / ENTRANT',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _headerCell('P'),
                _headerCell('W'),
                if (!isBadminton) _headerCell(isCricket ? 'T/NR' : 'D'),
                _headerCell('L'),
                _headerCell(isCricket ? 'NRR' : (isBadminton ? 'GD' : 'GD'), flex: 2),
                _headerCell('PTS', isLast: true),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: colors.border),

          // Table Rows
          for (int i = 0; i < rows.length; i++) ...[
            _TableRow(
              rank: i + 1,
              row: rows[i],
              sport: sport,
              isCricket: isCricket,
              isBadminton: isBadminton,
              isQualified: (i + 1) <= qualifiersCount,
            ),
            if (i < rows.length - 1)
              Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.5)),
          ],
          if (qualifiersCount > 0) ...[
            Divider(height: 1, thickness: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.win,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Top $qualifiersCount teams qualify for knockout phase',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.rank,
    required this.row,
    required this.sport,
    required this.isCricket,
    required this.isBadminton,
    required this.isQualified,
  });

  final int rank;
  final TournamentStandingsRow row;
  final String sport;
  final bool isCricket;
  final bool isBadminton;
  final bool isQualified;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    String diffText = '';
    if (isCricket) {
      diffText = row.netRunRate >= 0 ? '+${row.netRunRate.toStringAsFixed(3)}' : row.netRunRate.toStringAsFixed(3);
    } else if (isBadminton) {
      diffText = '${row.gameDifference >= 0 ? '+' : ''}${row.gameDifference}';
    } else {
      diffText = '${row.goalDifference >= 0 ? '+' : ''}${row.goalDifference}';
    }

    return Container(
      decoration: BoxDecoration(
        border: isQualified
            ? Border(left: BorderSide(color: AppColors.win, width: 3.5))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: AppTypography.caption.copyWith(
                fontWeight: isQualified ? FontWeight.w700 : FontWeight.w500,
                color: isQualified ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
          // Team Name + Seed
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontWeight: isQualified ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (row.seed != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '#${row.seed}',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Matches Played
          _dataCell(context, '${row.played}'),
          // Won
          _dataCell(context, '${row.won}'),
          // Drawn / Tied
          if (!isBadminton) _dataCell(context, '${row.drawn + row.tied}'),
          // Lost
          _dataCell(context, '${row.lost}'),
          // GD / NRR
          _dataCell(context, diffText, flex: 2),
          // Points
          _dataCell(
            context,
            '${row.points}',
            isBold: true,
            color: isQualified ? colors.textPrimary : null,
          ),
        ],
      ),
    );
  }

  Widget _dataCell(
    BuildContext context,
    String val, {
    int flex = 1,
    bool isBold = false,
    Color? color,
  }) {
    final colors = context.appColors;

    return Expanded(
      flex: flex,
      child: Text(
        val,
        textAlign: TextAlign.center,
        style: AppTypography.caption.copyWith(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? colors.textSecondary,
        ),
      ),
    );
  }
}
