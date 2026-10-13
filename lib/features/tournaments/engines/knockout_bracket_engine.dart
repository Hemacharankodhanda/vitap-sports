/// VIT-AP Sports — Knockout Bracket Generator Engine.
///
/// Pure-Dart deterministic engine for generating single-elimination knockout brackets.
library;

import 'dart:math';

import '../domain/models/tournament_models.dart';

class KnockoutBracketEngine {
  const KnockoutBracketEngine();

  /// Computes the next power of two greater than or equal to [n].
  static int nextPowerOfTwo(int n) {
    if (n <= 1) return 2;
    int power = 1;
    while (power < n) {
      power <<= 1;
    }
    return power;
  }

  /// Calculates total rounds for a bracket size (e.g. 8 -> 3 rounds).
  static int totalRounds(int bracketSize) {
    return (log(bracketSize) / ln2).round();
  }

  /// Standard tournament seeding layout for bracket of [size].
  ///
  /// For size 2: [1, 2]
  /// For size 4: [1, 4, 3, 2] -> matches (1v4), (3v2)
  /// For size 8: [1, 8, 4, 5, 3, 6, 2, 7] -> matches (1v8), (4v5), (3v6), (2v7)
  /// Recursively expands by replacing each seed x with [x, (currentSize * 2 + 1) - x].
  static List<int> generateSeedingOrder(int size) {
    if (size <= 1) return [1];
    if (size == 2) return [1, 2];
    List<int> order = [1, 4, 3, 2];
    while (order.length < size) {
      final nextOrder = <int>[];
      final currentMax = order.length * 2 + 1;
      for (final seed in order) {
        nextOrder.add(seed);
        nextOrder.add(currentMax - seed);
      }
      order = nextOrder;
    }
    return order;
  }

  /// Resolves the round label given the current round index (1-based) and [totalRounds].
  static String getRoundLabel(int round, int totalRounds, {bool isThirdPlace = false}) {
    if (isThirdPlace) return 'Third-place Playoff';
    final remaining = totalRounds - round;
    switch (remaining) {
      case 0:
        return 'Final';
      case 1:
        return 'Semi-final';
      case 2:
        return 'Quarter-final';
      case 3:
        return 'Round of 16';
      case 4:
        return 'Round of 32';
      default:
        return 'Round $round';
    }
  }

  /// Generates the complete knockout fixtures tree for [entries].
  ///
  /// [entries] are ordered or seeded. If [randomSeed] is provided, unseeded entries
  /// are shuffled deterministically.
  List<TournamentFixture> generateBracket({
    required String tournamentId,
    required List<TournamentEntry> entries,
    bool includeThirdPlace = false,
    int? randomSeed,
  }) {
    // Deduplicate entries by ID, teamId, userId, and normalized displayName
    final uniqueEntries = <TournamentEntry>[];
    final seenIds = <String>{};
    final seenTeamIds = <String>{};
    final seenUserIds = <String>{};
    final seenNames = <String>{};

    for (final e in entries) {
      if (e.id.isNotEmpty && seenIds.contains(e.id)) continue;
      if (e.teamId != null && e.teamId!.isNotEmpty && seenTeamIds.contains(e.teamId)) continue;
      if (e.userId != null && e.userId!.isNotEmpty && seenUserIds.contains(e.userId)) continue;
      final normName = e.displayName.trim().toLowerCase();
      if (normName.isNotEmpty && seenNames.contains(normName)) continue;

      if (e.id.isNotEmpty) seenIds.add(e.id);
      if (e.teamId != null && e.teamId!.isNotEmpty) seenTeamIds.add(e.teamId!);
      if (e.userId != null && e.userId!.isNotEmpty) seenUserIds.add(e.userId!);
      if (normName.isNotEmpty) seenNames.add(normName);
      uniqueEntries.add(e);
    }

    if (uniqueEntries.length < 2) {
      throw ArgumentError('A tournament requires at least 2 distinct entries');
    }

    final n = uniqueEntries.length;
    final size = nextPowerOfTwo(n);
    final totalRds = totalRounds(size);

    // 1. Prepare seeded list of entries (1-based index mapped to entry)
    final sortedEntries = List<TournamentEntry>.from(uniqueEntries);
    if (randomSeed != null) {
      final rng = Random(randomSeed);
      sortedEntries.shuffle(rng);
    } else {
      // Sort by seed if provided, otherwise preserve incoming order
      sortedEntries.sort((a, b) {
        if (a.seed != null && b.seed != null) return a.seed!.compareTo(b.seed!);
        if (a.seed != null) return -1;
        if (b.seed != null) return 1;
        return 0;
      });
    }

    // Assign explicit seed 1..N to entries
    final seedToEntry = <int, TournamentEntry>{};
    for (int i = 0; i < sortedEntries.length; i++) {
      final assignedSeed = i + 1;
      final entry = sortedEntries[i].copyWith(seed: sortedEntries[i].seed ?? assignedSeed);
      seedToEntry[assignedSeed] = entry;
    }

    // 2. Generate initial match pairings using standard seeding layout
    final seedingOrder = generateSeedingOrder(size);
    final round1MatchesCount = size ~/ 2;

    // Fixtures map: (round, position) -> TournamentFixture
    final fixtures = <String, TournamentFixture>{};
    String key(int r, int pos) => '$r:$pos';

    // 3. Pre-create all future knockout fixtures from Round 1 to Final
    for (int r = 1; r <= totalRds; r++) {
      final matchesInRound = size ~/ (1 << r);
      final label = getRoundLabel(r, totalRds);

      for (int pos = 1; pos <= matchesInRound; pos++) {
        final fixId = '${tournamentId}_r${r}_p$pos';
        String? nextFixId;
        String? nextSlot;

        if (r < totalRds) {
          final nextPos = (pos + 1) ~/ 2;
          nextFixId = '${tournamentId}_r${r + 1}_p$nextPos';
          nextSlot = (pos % 2 == 1) ? 'a' : 'b';
        }

        fixtures[key(r, pos)] = TournamentFixture(
          id: fixId,
          tournamentId: tournamentId,
          stage: FixtureStage.knockout,
          round: r,
          position: pos,
          roundLabel: label,
          status: FixtureStatus.pending,
          nextFixtureId: nextFixId,
          nextSlot: nextSlot,
        );
      }
    }

    // 4. Populate Round 1 pairings and link sources
    for (int pos = 1; pos <= round1MatchesCount; pos++) {
      final seedA = seedingOrder[(pos - 1) * 2];
      final seedB = seedingOrder[(pos - 1) * 2 + 1];

      final entryA = seedToEntry[seedA];
      final entryB = seedToEntry[seedB]; // May be null if seedB > n (BYE)

      // Guard against identical entries facing each other
      if (entryA != null && entryB != null) {
        final isSame = entryA.id == entryB.id ||
            (entryA.teamId != null && entryA.teamId == entryB.teamId) ||
            (entryA.userId != null && entryA.userId == entryB.userId);
        if (isSame) {
          throw StateError('Cannot pair an entrant against itself: ${entryA.displayName}');
        }
      }

      final isBye = (entryA != null && entryB == null) || (entryA == null && entryB != null);
      final activeEntry = entryA ?? entryB;

      final current = fixtures[key(1, pos)]!;
      if (isBye && activeEntry != null) {
        // Auto-complete bye fixture and advance winner immediately
        fixtures[key(1, pos)] = current.copyWith(
          isBye: true,
          entryAId: entryA?.id,
          entryBId: entryB?.id,
          status: FixtureStatus.completed,
          winnerEntryId: activeEntry.id,
          result: {
            'result_type': 'bye',
            'winner_entry_id': activeEntry.id,
            'margin': 'Bye',
          },
        );

        // Advance into next round slot directly
        if (current.nextFixtureId != null && current.nextSlot != null) {
          final nextPos = (pos + 1) ~/ 2;
          final nextFixture = fixtures[key(2, nextPos)]!;
          if (current.nextSlot == 'a') {
            fixtures[key(2, nextPos)] = nextFixture.copyWith(entryAId: activeEntry.id);
          } else {
            fixtures[key(2, nextPos)] = nextFixture.copyWith(entryBId: activeEntry.id);
          }
        }
      } else {
        // Normal playable match
        fixtures[key(1, pos)] = current.copyWith(
          entryAId: entryA?.id,
          entryBId: entryB?.id,
          status: (entryA != null && entryB != null) ? FixtureStatus.scheduled : FixtureStatus.pending,
        );
      }
    }

    // 5. Connect downstream source linkages
    for (int r = 2; r <= totalRds; r++) {
      final matchesInRound = size ~/ (1 << r);
      for (int pos = 1; pos <= matchesInRound; pos++) {
        final prevPosA = (pos - 1) * 2 + 1;
        final prevPosB = (pos - 1) * 2 + 2;

        final fixA = fixtures[key(r - 1, prevPosA)];
        final fixB = fixtures[key(r - 1, prevPosB)];
        final current = fixtures[key(r, pos)]!;

        final updated = TournamentFixture(
          id: current.id,
          tournamentId: current.tournamentId,
          stage: current.stage,
          round: current.round,
          position: current.position,
          roundLabel: current.roundLabel,
          entryAId: current.entryAId ?? (fixA?.status == FixtureStatus.completed ? fixA?.winnerEntryId : null),
          entryBId: current.entryBId ?? (fixB?.status == FixtureStatus.completed ? fixB?.winnerEntryId : null),
          sourceFixtureAId: fixA?.id,
          sourceFixtureBId: fixB?.id,
          sourceOutcomeA: 'winner',
          sourceOutcomeB: 'winner',
          status: (current.entryAId != null && current.entryBId != null) ? FixtureStatus.scheduled : FixtureStatus.pending,
          nextFixtureId: current.nextFixtureId,
          nextSlot: current.nextSlot,
        );

        fixtures[key(r, pos)] = updated;
      }
    }

    // 6. Optional Third-Place Playoff
    if (includeThirdPlace && totalRds >= 2) {
      final semi1 = fixtures[key(totalRds - 1, 1)]!;
      final semi2 = fixtures[key(totalRds - 1, 2)]!;

      final thirdPlaceId = '${tournamentId}_third_place';
      fixtures['third_place'] = TournamentFixture(
        id: thirdPlaceId,
        tournamentId: tournamentId,
        stage: FixtureStage.thirdPlace,
        round: totalRds,
        position: 2,
        roundLabel: 'Third-place Playoff',
        sourceFixtureAId: semi1.id,
        sourceFixtureBId: semi2.id,
        sourceOutcomeA: 'loser',
        sourceOutcomeB: 'loser',
        status: FixtureStatus.pending,
      );
    }

    return fixtures.values.toList();
  }
}
