/// VIT-AP Sports — Knockout Bracket View.
///
/// Horizontally scrollable and pannable canvas that lays out knockout rounds
/// and connects matches using [BracketConnectorPainter].
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tournament_models.dart';
import 'bracket_connector_painter.dart';
import 'bracket_node_card.dart';

class KnockoutBracketView extends StatelessWidget {
  const KnockoutBracketView({
    required this.fixtures,
    required this.entries,
    this.onFixtureTap,
    super.key,
  });

  final List<TournamentFixture> fixtures;
  final List<TournamentEntry> entries;
  final void Function(TournamentFixture fixture)? onFixtureTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final knockoutFixtures = fixtures.where((f) => f.stage == FixtureStage.knockout).toList();
    if (knockoutFixtures.isEmpty) {
      return Center(
        child: Text(
          'Bracket has not been generated yet',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
      );
    }

    final entryMap = {for (final e in entries) e.id: e};

    // Group fixtures by round
    final roundMap = <int, List<TournamentFixture>>{};
    for (final f in knockoutFixtures) {
      roundMap.putIfAbsent(f.round, () => []).add(f);
    }

    final sortedRounds = roundMap.keys.toList()..sort();
    for (final r in sortedRounds) {
      roundMap[r]!.sort((a, b) => a.position.compareTo(b.position));
    }

    // Geometry constants
    const cardW = BracketNodeCard.cardWidth;
    const cardH = BracketNodeCard.cardHeight;
    const colSpacing = 48.0;
    const baseRowGap = 20.0;
    const headerHeight = 36.0;

    final round1Matches = roundMap[1] ?? [];
    final r1Count = max(1, round1Matches.length);

    // Calculate node coordinates: (round, position) -> Offset(left, top)
    final nodePositions = <String, Offset>{};
    String key(int r, int pos) => '$r:$pos';

    // Round 1 positions
    for (int i = 0; i < round1Matches.length; i++) {
      final pos = round1Matches[i].position;
      final top = headerHeight + i * (cardH + baseRowGap);
      nodePositions[key(1, pos)] = Offset(0, top);
    }

    // Subsequent round positions (centered between parent matches)
    for (int rIndex = 1; rIndex < sortedRounds.length; rIndex++) {
      final r = sortedRounds[rIndex];
      final currentMatches = roundMap[r] ?? [];
      final left = rIndex * (cardW + colSpacing);

      for (final f in currentMatches) {
        final pos = f.position;
        final parentPos1 = (pos - 1) * 2 + 1;
        final parentPos2 = (pos - 1) * 2 + 2;

        final parentOffset1 = nodePositions[key(r - 1, parentPos1)];
        final parentOffset2 = nodePositions[key(r - 1, parentPos2)];

        double top;
        if (parentOffset1 != null && parentOffset2 != null) {
          top = (parentOffset1.dy + parentOffset2.dy) / 2;
        } else if (parentOffset1 != null) {
          top = parentOffset1.dy;
        } else {
          top = headerHeight + (pos - 1) * (cardH + baseRowGap);
        }
        nodePositions[key(r, pos)] = Offset(left, top);
      }
    }

    // Generate connectors
    final connectors = <BracketConnector>[];
    for (int rIndex = 1; rIndex < sortedRounds.length; rIndex++) {
      final r = sortedRounds[rIndex];
      final currentMatches = roundMap[r] ?? [];

      for (final f in currentMatches) {
        final pos = f.position;
        final targetOffset = nodePositions[key(r, pos)];
        if (targetOffset == null) continue;

        final prevPos1 = (pos - 1) * 2 + 1;
        final prevPos2 = (pos - 1) * 2 + 2;

        final p1 = nodePositions[key(r - 1, prevPos1)];
        final p2 = nodePositions[key(r - 1, prevPos2)];

        if (p1 != null) {
          final isP1Active = f.entryAId != null;
          connectors.add(
            BracketConnector(
              startPoint: Offset(p1.dx + cardW, p1.dy + cardH / 2),
              endPoint: Offset(targetOffset.dx, targetOffset.dy + cardH * 0.25),
              isActive: isP1Active,
            ),
          );
        }

        if (p2 != null) {
          final isP2Active = f.entryBId != null;
          connectors.add(
            BracketConnector(
              startPoint: Offset(p2.dx + cardW, p2.dy + cardH / 2),
              endPoint: Offset(targetOffset.dx, targetOffset.dy + cardH * 0.75),
              isActive: isP2Active,
            ),
          );
        }
      }
    }

    final totalWidth = sortedRounds.length * cardW + (sortedRounds.length - 1) * colSpacing + 48.0;
    final totalHeight = headerHeight + r1Count * (cardH + baseRowGap) + 40.0;

    // Optional third-place playoff
    final thirdPlace = fixtures.where((f) => f.stage == FixtureStage.thirdPlace).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Bracket Canvas
              SizedBox(
                width: max(320.0, totalWidth),
                height: max(200.0, totalHeight),
                child: Stack(
                  children: [
                    // Round Column Headers
                    for (int i = 0; i < sortedRounds.length; i++) ...[
                      Positioned(
                        left: i * (cardW + colSpacing),
                        top: 0,
                        width: cardW,
                        child: Text(
                          roundMap[sortedRounds[i]]?.first.roundLabel.split(' (').first ?? 'Round ${sortedRounds[i]}',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],

                    // Connectors Layer
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BracketConnectorPainter(
                          connectors: connectors,
                          defaultColor: colors.border,
                          activeColor: AppColors.accent,
                        ),
                      ),
                    ),

                    // Match Cards Layer
                    for (final r in sortedRounds)
                      for (final f in roundMap[r]!) ...[
                        if (nodePositions[key(r, f.position)] != null)
                          Positioned(
                            left: nodePositions[key(r, f.position)]!.dx,
                            top: nodePositions[key(r, f.position)]!.dy,
                            child: BracketNodeCard(
                              fixture: f,
                              entryA: f.entryAId != null ? entryMap[f.entryAId] : null,
                              entryB: f.entryBId != null ? entryMap[f.entryBId] : null,
                              onTap: () => onFixtureTap?.call(f),
                            ),
                          ),
                      ],
                  ],
                ),
              ),

              // Third Place Playoff Section (if present)
              if (thirdPlace.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Third-place Playoff',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                BracketNodeCard(
                  fixture: thirdPlace.first,
                  entryA: thirdPlace.first.entryAId != null ? entryMap[thirdPlace.first.entryAId] : null,
                  entryB: thirdPlace.first.entryBId != null ? entryMap[thirdPlace.first.entryBId] : null,
                  onTap: () => onFixtureTap?.call(thirdPlace.first),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
