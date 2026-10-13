/// VIT-AP Sports — Standings Engine.
///
/// Pure-Dart deterministic engine for calculating tournament standings and
/// tie-break rankings for Football, Cricket, and Badminton.
library;

import '../domain/models/tournament_models.dart';

class StandingsEngine {
  const StandingsEngine();

  /// Converts cricket overs notation (e.g. 3.4 overs) to pure decimal overs.
  /// 3.4 overs = 3 complete overs + 4 balls = 22 balls = 22 / 6.0 = 3.6667 overs.
  static double oversToDecimal(num oversVal) {
    final str = oversVal.toString();
    final parts = str.split('.');
    final completeOvers = int.tryParse(parts[0]) ?? 0;
    final balls = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final totalBalls = completeOvers * 6 + balls;
    return totalBalls / 6.0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  /// Calculates standings for a list of [entries] given completed [fixtures].
  List<TournamentStandingsRow> calculateStandings({
    required String sport,
    required List<TournamentEntry> entries,
    required List<TournamentFixture> fixtures,
    Map<String, dynamic> config = const {},
  }) {
    final sportLower = sport.toLowerCase();
    if (sportLower.contains('football')) {
      return _calculateFootballStandings(entries, fixtures, config);
    } else if (sportLower.contains('badminton')) {
      return _calculateBadmintonStandings(entries, fixtures, config);
    } else {
      // Default to Cricket
      return _calculateCricketStandings(entries, fixtures, config);
    }
  }

  // ─── Football Standings ──────────────────────────────────────────────────

  List<TournamentStandingsRow> _calculateFootballStandings(
    List<TournamentEntry> entries,
    List<TournamentFixture> fixtures,
    Map<String, dynamic> config,
  ) {
    final winPts = (config['points_win'] as num?)?.toInt() ?? 3;
    final drawPts = (config['points_draw'] as num?)?.toInt() ?? 1;
    final lossPts = (config['points_loss'] as num?)?.toInt() ?? 0;

    // Initialize rows for all entries
    final rowMap = <String, TournamentStandingsRow>{};
    for (final e in entries) {
      rowMap[e.id] = TournamentStandingsRow(
        entryId: e.id,
        displayName: e.displayName,
        seed: e.seed,
      );
    }

    final validMatches = fixtures.where((f) =>
        (f.status == FixtureStatus.completed || f.status == FixtureStatus.walkover) &&
        f.entryAId != null &&
        f.entryBId != null &&
        rowMap.containsKey(f.entryAId) &&
        rowMap.containsKey(f.entryBId)).toList();

    for (final f in validMatches) {
      final aId = f.entryAId!;
      final bId = f.entryBId!;
      final res = f.result;

      int goalsA = 0;
      int goalsB = 0;

      if (f.status == FixtureStatus.walkover) {
        // Default walkover in football is 3-0
        final isAWin = f.winnerEntryId == aId;
        goalsA = isAWin ? 3 : 0;
        goalsB = isAWin ? 0 : 3;
      } else {
        final fb = res['football'] as Map<String, dynamic>?;
        goalsA = _toInt(fb?['goals_a'] ?? res['home_score'] ?? res['score_a']);
        goalsB = _toInt(fb?['goals_b'] ?? res['away_score'] ?? res['score_b']);
      }

      final rowA = rowMap[aId]!;
      final rowB = rowMap[bId]!;

      final isDraw = goalsA == goalsB;
      final aWon = goalsA > goalsB;

      rowMap[aId] = rowA.copyWith(
        played: rowA.played + 1,
        won: rowA.won + (aWon ? 1 : 0),
        drawn: rowA.drawn + (isDraw ? 1 : 0),
        lost: rowA.lost + (!aWon && !isDraw ? 1 : 0),
        points: rowA.points + (aWon ? winPts : (isDraw ? drawPts : lossPts)),
        goalsFor: rowA.goalsFor + goalsA,
        goalsAgainst: rowA.goalsAgainst + goalsB,
        goalDifference: (rowA.goalsFor + goalsA) - (rowA.goalsAgainst + goalsB),
      );

      rowMap[bId] = rowB.copyWith(
        played: rowB.played + 1,
        won: rowB.won + (!aWon && !isDraw ? 1 : 0),
        drawn: rowB.drawn + (isDraw ? 1 : 0),
        lost: rowB.lost + (aWon ? 1 : 0),
        points: rowB.points + (!aWon && !isDraw ? winPts : (isDraw ? drawPts : lossPts)),
        goalsFor: rowB.goalsFor + goalsB,
        goalsAgainst: rowB.goalsAgainst + goalsA,
        goalDifference: (rowB.goalsFor + goalsB) - (rowB.goalsAgainst + goalsA),
      );
    }

    final rows = rowMap.values.toList();
    return _sortFootballStandings(rows, validMatches);
  }

  List<TournamentStandingsRow> _sortFootballStandings(
    List<TournamentStandingsRow> rows,
    List<TournamentFixture> fixtures,
  ) {
    rows.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      return 0;
    });

    // Resolve ties among entries with identical points
    final result = <TournamentStandingsRow>[];
    int i = 0;
    while (i < rows.length) {
      int j = i + 1;
      while (j < rows.length && rows[j].points == rows[i].points) {
        j++;
      }

      final tiedGroup = rows.sublist(i, j);
      if (tiedGroup.length == 1) {
        result.add(tiedGroup.first);
      } else {
        // Resolve tie using head-to-head mini-table, GD, GF
        final resolved = _resolveFootballTie(tiedGroup, fixtures);
        result.addAll(resolved);
      }
      i = j;
    }

    return result;
  }

  List<TournamentStandingsRow> _resolveFootballTie(
    List<TournamentStandingsRow> tiedEntries,
    List<TournamentFixture> allFixtures,
  ) {
    final tiedIds = tiedEntries.map((e) => e.entryId).toSet();
    final miniMatches = allFixtures.where((f) =>
        tiedIds.contains(f.entryAId) && tiedIds.contains(f.entryBId)).toList();

    // Compute mini-table points and mini-table GD
    final miniPoints = <String, int>{for (final id in tiedIds) id: 0};
    final miniGF = <String, int>{for (final id in tiedIds) id: 0};
    final miniGA = <String, int>{for (final id in tiedIds) id: 0};

    for (final f in miniMatches) {
      final aId = f.entryAId!;
      final bId = f.entryBId!;
      final fb = f.result['football'] as Map<String, dynamic>?;
      final int gA = _toInt(fb?['goals_a'] ?? f.result['home_score']);
      final int gB = _toInt(fb?['goals_b'] ?? f.result['away_score']);

      miniGF[aId] = miniGF[aId]! + gA;
      miniGA[aId] = miniGA[aId]! + gB;
      miniGF[bId] = miniGF[bId]! + gB;
      miniGA[bId] = miniGA[bId]! + gA;

      if (gA > gB) {
        miniPoints[aId] = miniPoints[aId]! + 3;
      } else if (gB > gA) {
        miniPoints[bId] = miniPoints[bId]! + 3;
      } else {
        miniPoints[aId] = miniPoints[aId]! + 1;
        miniPoints[bId] = miniPoints[bId]! + 1;
      }
    }

    final sorted = List<TournamentStandingsRow>.from(tiedEntries);
    sorted.sort((a, b) {
      // 1. Head-to-Head points
      final h2hPtsA = miniPoints[a.entryId] ?? 0;
      final h2hPtsB = miniPoints[b.entryId] ?? 0;
      if (h2hPtsB != h2hPtsA) return h2hPtsB.compareTo(h2hPtsA);

      // 2. Head-to-Head goal difference
      final h2hGDA = (miniGF[a.entryId] ?? 0) - (miniGA[a.entryId] ?? 0);
      final h2hGDB = (miniGF[b.entryId] ?? 0) - (miniGA[b.entryId] ?? 0);
      if (h2hGDB != h2hGDA) return h2hGDB.compareTo(h2hGDA);

      // 3. Overall goal difference
      if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      }

      // 4. Overall goals for
      if (b.goalsFor != a.goalsFor) {
        return b.goalsFor.compareTo(a.goalsFor);
      }

      return 0;
    });

    // Check if any remain tied
    return List.generate(sorted.length, (idx) {
      final current = sorted[idx];
      final isStillTiedWithPrev = idx > 0 &&
          sorted[idx - 1].goalDifference == current.goalDifference &&
          sorted[idx - 1].goalsFor == current.goalsFor &&
          (miniPoints[sorted[idx - 1].entryId] ?? 0) == (miniPoints[current.entryId] ?? 0);

      final isStillTiedWithNext = idx < sorted.length - 1 &&
          sorted[idx + 1].goalDifference == current.goalDifference &&
          sorted[idx + 1].goalsFor == current.goalsFor &&
          (miniPoints[sorted[idx + 1].entryId] ?? 0) == (miniPoints[current.entryId] ?? 0);

      if (isStillTiedWithPrev || isStillTiedWithNext) {
        return current.copyWith(
          needsOrganiserDecision: true,
          tieBreakNotes: [...current.tieBreakNotes, 'Head-to-head and goal difference equal. Organiser decision required.'],
        );
      }
      return current;
    });
  }

  // ─── Cricket Standings & NRR ─────────────────────────────────────────────

  List<TournamentStandingsRow> _calculateCricketStandings(
    List<TournamentEntry> entries,
    List<TournamentFixture> fixtures,
    Map<String, dynamic> config,
  ) {
    final winPts = (config['points_win'] as num?)?.toInt() ?? 2;
    final tiePts = (config['points_tie'] as num?)?.toInt() ?? 1;
    final nrPts = (config['points_no_result'] as num?)?.toInt() ?? 1;
    final matchOversQuota = (config['match_overs'] as num?)?.toInt() ?? 10;

    final rowMap = <String, TournamentStandingsRow>{};
    for (final e in entries) {
      rowMap[e.id] = TournamentStandingsRow(
        entryId: e.id,
        displayName: e.displayName,
        seed: e.seed,
      );
    }

    // Cumulative stats for NRR: total runs and total decimal overs
    final runsScoredMap = <String, int>{for (final e in entries) e.id: 0};
    final oversFacedMap = <String, double>{for (final e in entries) e.id: 0.0};
    final runsConcededMap = <String, int>{for (final e in entries) e.id: 0};
    final oversBowledMap = <String, double>{for (final e in entries) e.id: 0.0};

    final validMatches = fixtures.where((f) =>
        (f.status == FixtureStatus.completed || f.status == FixtureStatus.walkover) &&
        f.entryAId != null &&
        f.entryBId != null &&
        rowMap.containsKey(f.entryAId) &&
        rowMap.containsKey(f.entryBId)).toList();

    for (final f in validMatches) {
      final aId = f.entryAId!;
      final bId = f.entryBId!;
      final res = f.result;
      final resultType = res['result_type']?.toString();

      final rowA = rowMap[aId]!;
      final rowB = rowMap[bId]!;

      if (resultType == 'no_result' || resultType == 'abandoned') {
        rowMap[aId] = rowA.copyWith(
          played: rowA.played + 1,
          noResult: rowA.noResult + 1,
          points: rowA.points + nrPts,
        );
        rowMap[bId] = rowB.copyWith(
          played: rowB.played + 1,
          noResult: rowB.noResult + 1,
          points: rowB.points + nrPts,
        );
        continue;
      }

      final ckt = res['cricket'] as Map<String, dynamic>?;
      final cktA = ckt?['a'] as Map<String, dynamic>?;
      final cktB = ckt?['b'] as Map<String, dynamic>?;

      final int runsA = _toInt(cktA?['runs'] ?? res['home_score'] ?? res['runs_a']);
      final int runsB = _toInt(cktB?['runs'] ?? res['away_score'] ?? res['runs_b']);

      final isAllOutA = cktA?['all_out'] == true || (cktA?['wickets'] as num?)?.toInt() == 10;
      final isAllOutB = cktB?['all_out'] == true || (cktB?['wickets'] as num?)?.toInt() == 10;

      // Calculate overs faced according to ICC NRR rules
      final rawOversA = (cktA?['overs_faced'] ?? cktA?['overs'] as num?) ?? matchOversQuota;
      final rawOversB = (cktB?['overs_faced'] ?? cktB?['overs'] as num?) ?? matchOversQuota;

      // If a team is all out, count the full innings quota of overs!
      final decimalOversA = isAllOutA ? matchOversQuota.toDouble() : oversToDecimal(rawOversA);
      final decimalOversB = isAllOutB ? matchOversQuota.toDouble() : oversToDecimal(rawOversB);

      // Accumulate NRR totals
      runsScoredMap[aId] = runsScoredMap[aId]! + runsA;
      oversFacedMap[aId] = oversFacedMap[aId]! + decimalOversA;
      runsConcededMap[aId] = runsConcededMap[aId]! + runsB;
      oversBowledMap[aId] = oversBowledMap[aId]! + decimalOversB;

      runsScoredMap[bId] = runsScoredMap[bId]! + runsB;
      oversFacedMap[bId] = oversFacedMap[bId]! + decimalOversB;
      runsConcededMap[bId] = runsConcededMap[bId]! + runsA;
      oversBowledMap[bId] = oversBowledMap[bId]! + decimalOversA;

      final isTie = runsA == runsB;
      final aWon = runsA > runsB;

      rowMap[aId] = rowA.copyWith(
        played: rowA.played + 1,
        won: rowA.won + (aWon ? 1 : 0),
        tied: rowA.tied + (isTie ? 1 : 0),
        lost: rowA.lost + (!aWon && !isTie ? 1 : 0),
        points: rowA.points + (aWon ? winPts : (isTie ? tiePts : 0)),
        runsScored: runsScoredMap[aId]!,
        runsConceded: runsConcededMap[aId]!,
      );

      rowMap[bId] = rowB.copyWith(
        played: rowB.played + 1,
        won: rowB.won + (!aWon && !isTie ? 1 : 0),
        tied: rowB.tied + (isTie ? 1 : 0),
        lost: rowB.lost + (aWon ? 1 : 0),
        points: rowB.points + (!aWon && !isTie ? winPts : (isTie ? tiePts : 0)),
        runsScored: runsScoredMap[bId]!,
        runsConceded: runsConcededMap[bId]!,
      );
    }

    // Compute NRR for each entry
    for (final e in entries) {
      final rFor = runsScoredMap[e.id] ?? 0;
      final oFor = oversFacedMap[e.id] ?? 0.0;
      final rAgainst = runsConcededMap[e.id] ?? 0;
      final oAgainst = oversBowledMap[e.id] ?? 0.0;

      final runRateFor = oFor > 0 ? (rFor / oFor) : 0.0;
      final runRateAgainst = oAgainst > 0 ? (rAgainst / oAgainst) : 0.0;
      final nrr = runRateFor - runRateAgainst;

      rowMap[e.id] = rowMap[e.id]!.copyWith(netRunRate: nrr);
    }

    final rows = rowMap.values.toList();
    rows.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.won != a.won) return b.won.compareTo(a.won);
      // NRR comparison
      return b.netRunRate.compareTo(a.netRunRate);
    });

    return rows;
  }

  // ─── Badminton Standings ─────────────────────────────────────────────────

  List<TournamentStandingsRow> _calculateBadmintonStandings(
    List<TournamentEntry> entries,
    List<TournamentFixture> fixtures,
    Map<String, dynamic> config,
  ) {
    final winPts = (config['points_win'] as num?)?.toInt() ?? 1;

    final rowMap = <String, TournamentStandingsRow>{};
    for (final e in entries) {
      rowMap[e.id] = TournamentStandingsRow(
        entryId: e.id,
        displayName: e.displayName,
        seed: e.seed,
      );
    }

    final validMatches = fixtures.where((f) =>
        (f.status == FixtureStatus.completed || f.status == FixtureStatus.walkover) &&
        f.entryAId != null &&
        f.entryBId != null &&
        rowMap.containsKey(f.entryAId) &&
        rowMap.containsKey(f.entryBId)).toList();

    for (final f in validMatches) {
      final aId = f.entryAId!;
      final bId = f.entryBId!;
      final res = f.result;

      final rowA = rowMap[aId]!;
      final rowB = rowMap[bId]!;

      int gWonA = 0;
      int gWonB = 0;
      int ptsA = 0;
      int ptsB = 0;

      if (f.status == FixtureStatus.walkover) {
        final aWon = f.winnerEntryId == aId;
        gWonA = aWon ? 2 : 0;
        gWonB = aWon ? 0 : 2;
        ptsA = aWon ? 42 : 0;
        ptsB = aWon ? 0 : 42;
      } else {
        final bm = res['badminton'] as Map<String, dynamic>?;
        gWonA = _toInt(bm?['games_won_a'] ?? res['home_score'] ?? res['home_games_won']);
        gWonB = _toInt(bm?['games_won_b'] ?? res['away_score'] ?? res['away_games_won']);
        ptsA = _toInt(bm?['points_a'] ?? res['home_total_points']);
        ptsB = _toInt(bm?['points_b'] ?? res['away_total_points']);
      }

      final aWon = gWonA > gWonB;

      rowMap[aId] = rowA.copyWith(
        played: rowA.played + 1,
        won: rowA.won + (aWon ? 1 : 0),
        lost: rowA.lost + (aWon ? 0 : 1),
        points: rowA.points + (aWon ? winPts : 0),
        gamesWon: rowA.gamesWon + gWonA,
        gamesLost: rowA.gamesLost + gWonB,
        gameDifference: (rowA.gamesWon + gWonA) - (rowA.gamesLost + gWonB),
        pointsWon: rowA.pointsWon + ptsA,
        pointsLost: rowA.pointsLost + ptsB,
        pointDifference: (rowA.pointsWon + ptsA) - (rowA.pointsLost + ptsB),
      );

      rowMap[bId] = rowB.copyWith(
        played: rowB.played + 1,
        won: rowB.won + (aWon ? 0 : 1),
        lost: rowB.lost + (aWon ? 1 : 0),
        points: rowB.points + (aWon ? 0 : winPts),
        gamesWon: rowB.gamesWon + gWonB,
        gamesLost: rowB.gamesLost + gWonA,
        gameDifference: (rowB.gamesWon + gWonB) - (rowB.gamesLost + gWonA),
        pointsWon: rowB.pointsWon + ptsB,
        pointsLost: rowB.pointsLost + ptsA,
        pointDifference: (rowB.pointsWon + ptsB) - (rowB.pointsLost + ptsA),
      );
    }

    final rows = rowMap.values.toList();
    rows.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.gameDifference != a.gameDifference) {
        return b.gameDifference.compareTo(a.gameDifference);
      }
      if (b.pointDifference != a.pointDifference) {
        return b.pointDifference.compareTo(a.pointDifference);
      }
      return 0;
    });

    return rows;
  }
}
