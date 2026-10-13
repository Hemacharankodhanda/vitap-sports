/// VIT-AP Sports — Round Robin Generator Engine.
///
/// Pure-Dart circle method engine for generating single and double round-robin schedules.
library;

import '../domain/models/tournament_models.dart';

class RoundRobinEngine {
  const RoundRobinEngine();

  /// Generates round-robin fixtures using the standard circle method.
  ///
  /// - Handles odd [N] by rotating with a rest bye, giving each team exactly 1 rest per round.
  /// - Supports [doubleRoundRobin] where the second half swaps home/away sides.
  /// - Groups fixtures by round (1..R).
  List<TournamentFixture> generateSchedule({
    required String tournamentId,
    required List<TournamentEntry> entries,
    String? groupId,
    bool doubleRoundRobin = false,
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
      throw ArgumentError('Round-robin requires at least 2 distinct entries');
    }

    final n = uniqueEntries.length;
    final isOdd = n % 2 != 0;
    final totalTeams = isOdd ? n + 1 : n;
    final roundsCount = totalTeams - 1;
    final matchesPerRound = totalTeams ~/ 2;

    // Build working list of entries (null represents rest bye for odd n)
    final teamList = List<TournamentEntry?>.from(uniqueEntries);
    if (isOdd) {
      teamList.add(null);
    }

    final fixtures = <TournamentFixture>[];

    // Single Round-Robin generation (First Leg)
    for (int r = 1; r <= roundsCount; r++) {
      int posInRound = 1;

      for (int m = 0; m < matchesPerRound; m++) {
        final home = teamList[m];
        final away = teamList[totalTeams - 1 - m];

        // If neither is the rest bye, schedule the fixture
        if (home != null && away != null) {
          final fixId = '${tournamentId}_${groupId ?? "lg"}_r${r}_p$posInRound';
          fixtures.add(TournamentFixture(
            id: fixId,
            tournamentId: tournamentId,
            stage: FixtureStage.group,
            groupId: groupId,
            round: r,
            position: posInRound,
            roundLabel: 'Round $r',
            entryAId: home.id,
            entryBId: away.id,
            status: FixtureStatus.scheduled,
          ));
          posInRound++;
        }
      }

      // Rotate entries around fixed position 0
      final last = teamList.removeLast();
      teamList.insert(1, last);
    }

    // Double Round-Robin generation (Second Leg - inverted sides)
    if (doubleRoundRobin) {
      final leg1Fixtures = List<TournamentFixture>.from(fixtures);
      for (final f in leg1Fixtures) {
        final leg2Round = f.round + roundsCount;
        final fixId = '${tournamentId}_${groupId ?? "lg"}_r${leg2Round}_p${f.position}';

        fixtures.add(TournamentFixture(
          id: fixId,
          tournamentId: tournamentId,
          stage: FixtureStage.group,
          groupId: groupId,
          round: leg2Round,
          position: f.position,
          roundLabel: 'Round $leg2Round',
          entryAId: f.entryBId, // Swapped home/away
          entryBId: f.entryAId,
          status: FixtureStatus.scheduled,
        ));
      }
    }

    return fixtures;
  }
}
