/// VIT-AP Sports — StatTile and StatGridCard widgets.
///
/// Component specification:
/// - Stat tile: value 28 / 36 / w700 tabular, label Caption in textSecondary.
/// - Group tiles in a single card in a 2 or 3 column grid with hairline dividers,
///   not one card per tile.
/// - Show '-' for undefined values, never NaN.
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayValue,
            style: TextStyle(
              fontFamily: AppTypography.largeTitle.fontFamily,
              fontSize: 28,
              height: 36 / 28,
              fontWeight: FontWeight.w700,
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

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: isLastCol
                                ? BorderSide.none
                                : BorderSide(color: colors.border, width: 1),
                          ),
                        ),
                        child: tileIdx < tiles.length
                            ? tiles[tileIdx]
                            : const SizedBox.shrink(),
                      ),
                    );
                  }),
                ),
              ),
              if (!isLastRow)
                Divider(height: 1, thickness: 1, color: colors.border),
            ],
          );
        }),
      ),
    );
  }
}
