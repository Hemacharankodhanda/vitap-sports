/// VIT-AP Sports — Group Stage & Multi-Stage Tournament Engine.
///
/// Pure-Dart engine for snake group distribution, per-group round-robin fixtures,
/// and cross-group knockout qualification generation.
library;

import '../domain/models/tournament_models.dart';
import 'knockout_bracket_engine.dart';
import 'round_robin_engine.dart';

class GroupStageResult {
  const GroupStageResult({
    required this.groups,
    required this.groupEntries,
    required this.groupFixtures,
    required this.knockoutFixtures,
  });

  final List<TournamentGroup> groups;
  final Map<String, List<TournamentEntry>> groupEntries; // groupId -> entries
  final List<TournamentFixture> groupFixtures;
  final List<TournamentFixture> knockoutFixtures;
}

class GroupStageEngine {
  const GroupStageEngine({
    this.roundRobinEngine = const RoundRobinEngine(),
    this.knockoutEngine = const KnockoutBracketEngine(),
  });

  final RoundRobinEngine roundRobinEngine;
  final KnockoutBracketEngine knockoutEngine;

  /// Allocates entries into [groupsCount] groups using snake distribution,
  /// generates the round-robin schedule for each group, and creates the
  /// cross-pairing knockout stage slots.
  GroupStageResult setupGroupStage({
    required String tournamentId,
    required List<TournamentEntry> entries,
    int groupsCount = 2,
    int qualifiersPerGroup = 2,
    bool doubleRoundRobin = false,
    bool includeThirdPlace = false,
  }) {
    if (groupsCount < 2) {
      throw ArgumentError('Group stage requires at least 2 groups');
    }

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

    if (uniqueEntries.length < groupsCount * 2) {
      throw ArgumentError('Not enough distinct entries to form $groupsCount groups (minimum 2 per group)');
    }

    // 1. Sort entries by seed (assigning default 1..N if null)
    final sortedEntries = List<TournamentEntry>.from(uniqueEntries);
    sortedEntries.sort((a, b) {
      if (a.seed != null && b.seed != null) return a.seed!.compareTo(b.seed!);
      if (a.seed != null) return -1;
      if (b.seed != null) return 1;
      return 0;
    });

    final seededEntries = <TournamentEntry>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      seededEntries.add(sortedEntries[i].copyWith(seed: sortedEntries[i].seed ?? (i + 1)));
    }

    // 2. Instantiate Group models (Group A, Group B, ...)
    final groups = <TournamentGroup>[];
    for (int g = 1; g <= groupsCount; g++) {
      final name = 'Group ${String.fromCharCode(64 + g)}'; // 1 -> A, 2 -> B...
      groups.add(TournamentGroup(
        id: '${tournamentId}_grp_$g',
        tournamentId: tournamentId,
        name: name,
        position: g,
      ));
    }

    // 3. Snake distribution across groups
    final groupEntries = <String, List<TournamentEntry>>{};
    for (final grp in groups) {
      groupEntries[grp.id] = [];
    }

    int entryIndex = 0;
    int rowIndex = 0;

    while (entryIndex < seededEntries.length) {
      final isEvenRow = rowIndex % 2 == 0;
      final groupOrder = isEvenRow
          ? List.generate(groupsCount, (i) => i) // 0, 1, 2...
          : List.generate(groupsCount, (i) => groupsCount - 1 - i); // G-1, G-2... 0

      for (final gIdx in groupOrder) {
        if (entryIndex < seededEntries.length) {
          final entry = seededEntries[entryIndex];
          final targetGroup = groups[gIdx];
          final updatedEntry = entry.copyWith(groupId: targetGroup.id);
          groupEntries[targetGroup.id]!.add(updatedEntry);
          entryIndex++;
        }
      }
      rowIndex++;
    }

    // 4. Generate Round-Robin fixtures for each group
    final allGroupFixtures = <TournamentFixture>[];
    for (final grp in groups) {
      final entriesInGroup = groupEntries[grp.id]!;
      final fixtures = roundRobinEngine.generateSchedule(
        tournamentId: tournamentId,
        groupId: grp.id,
        entries: entriesInGroup,
        doubleRoundRobin: doubleRoundRobin,
      );
      allGroupFixtures.addAll(fixtures);
    }

    // 5. Generate Knockout Stage cross-pairing fixtures
    final totalQualifiers = groupsCount * qualifiersPerGroup;
    final knockoutFixtures = <TournamentFixture>[];

    if (groupsCount == 2 && qualifiersPerGroup == 2) {
      // Classic 2 groups of qualifiers:
      // Semi-final 1: A1 vs B2 (Round 1, pos 1) -> advances to Final pos 1 (slot a)
      // Semi-final 2: B1 vs A2 (Round 1, pos 2) -> advances to Final pos 1 (slot b)
      final finalId = '${tournamentId}_ko_r2_p1';
      final sf1Id = '${tournamentId}_ko_r1_p1';
      final sf2Id = '${tournamentId}_ko_r1_p2';

      knockoutFixtures.add(TournamentFixture(
        id: sf1Id,
        tournamentId: tournamentId,
        stage: FixtureStage.knockout,
        round: 1,
        position: 1,
        roundLabel: 'Semi-final 1 (A1 vs B2)',
        status: FixtureStatus.pending,
        nextFixtureId: finalId,
        nextSlot: 'a',
      ));

      knockoutFixtures.add(TournamentFixture(
        id: sf2Id,
        tournamentId: tournamentId,
        stage: FixtureStage.knockout,
        round: 1,
        position: 2,
        roundLabel: 'Semi-final 2 (B1 vs A2)',
        status: FixtureStatus.pending,
        nextFixtureId: finalId,
        nextSlot: 'b',
      ));

      knockoutFixtures.add(TournamentFixture(
        id: finalId,
        tournamentId: tournamentId,
        stage: FixtureStage.knockout,
        round: 2,
        position: 1,
        roundLabel: 'Final',
        sourceFixtureAId: sf1Id,
        sourceFixtureBId: sf2Id,
        sourceOutcomeA: 'winner',
        sourceOutcomeB: 'winner',
        status: FixtureStatus.pending,
      ));

      if (includeThirdPlace) {
        knockoutFixtures.add(TournamentFixture(
          id: '${tournamentId}_third_place',
          tournamentId: tournamentId,
          stage: FixtureStage.thirdPlace,
          round: 2,
          position: 2,
          roundLabel: 'Third-place Playoff',
          sourceFixtureAId: sf1Id,
          sourceFixtureBId: sf2Id,
          sourceOutcomeA: 'loser',
          sourceOutcomeB: 'loser',
          status: FixtureStatus.pending,
        ));
      }
    } else {
      // General knockout tree for other group configurations
      // Generate standard bracket placeholders
      final dummyQualifiers = List.generate(
        totalQualifiers,
        (i) => TournamentEntry(
          id: 'qualifier_${i + 1}',
          tournamentId: tournamentId,
          displayName: 'Qualifier ${i + 1}',
          seed: i + 1,
        ),
      );

      final genFixtures = knockoutEngine.generateBracket(
        tournamentId: tournamentId,
        entries: dummyQualifiers,
        includeThirdPlace: includeThirdPlace,
      );

      // Clear the dummy IDs from slots so they start unassigned
      for (final f in genFixtures) {
        knockoutFixtures.add(TournamentFixture(
          id: f.id,
          tournamentId: f.tournamentId,
          stage: f.stage,
          round: f.round,
          position: f.position,
          roundLabel: f.roundLabel,
          sourceFixtureAId: f.sourceFixtureAId,
          sourceFixtureBId: f.sourceFixtureBId,
          sourceOutcomeA: f.sourceOutcomeA,
          sourceOutcomeB: f.sourceOutcomeB,
          status: FixtureStatus.pending,
          nextFixtureId: f.nextFixtureId,
          nextSlot: f.nextSlot,
        ));
      }
    }

    return GroupStageResult(
      groups: groups,
      groupEntries: groupEntries,
      groupFixtures: allGroupFixtures,
      knockoutFixtures: knockoutFixtures,
    );
  }
}
