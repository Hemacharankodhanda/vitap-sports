/// VIT-AP Sports — StatTile and StatGridCard widgets (Apple Design System).
///
/// Component specification:
/// - Tabular figures on all numbers via FontFeature.tabularFigures().
/// - Hero value in large font with Caption label below in textSecondary.
/// - Group tiles in a single card with hairline dividers (0.5 to 1 px).
/// - Shows '-' for undefined values, never NaN.
library;

import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final displayValue = (value.isEmpty || value.toLowerCase() == 'nan' || value.toLowerCase() == 'null')
        ? '-'
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayValue,
            style: TextStyle(
              fontFamily: AppTypography.title.fontFamily,
              fontSize: 26,
              height: 32 / 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: valueColor ?? colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Card that groups multiple StatTiles in a 2 or 3 column grid with hairline dividers.
class StatGridCard extends StatelessWidget {
  const StatGridCard({
    super.key,
    required this.tiles,
    this.columns = 2,
  });

  final List<StatTile> tiles;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final rowCount = (tiles.length / columns).ceil();

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rowCount, (rowIndex) {
          final isLastRow = rowIndex == rowCount - 1;
          final startIdx = rowIndex * columns;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(columns, (colIndex) {
                    final tileIdx = startIdx + colIndex;
                    final isLastCol = colIndex == columns - 1;

                    if (tileIdx < tiles.length) {
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(child: tiles[tileIdx]),
                            if (!isLastCol)
                              VerticalDivider(
                                width: 1,
                                thickness: 0.5,
                                color: colors.divider,
                              ),
                          ],
                        ),
                      );
                    }
                    return Expanded(child: const SizedBox.shrink());
                  }),
                ),
              ),
              if (!isLastRow)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }
}
