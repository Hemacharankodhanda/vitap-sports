/// VIT-AP Sports — Tournament Advancement & Lifecycle Engine.
///
/// Pure-Dart engine for knockout advancement, tie resolution, walkovers,
/// entry withdrawal, disqualification, and result correction safeguards.
library;

import '../domain/models/tournament_models.dart';

class AdvancementResult {
  const AdvancementResult({
    required this.updatedFixtures,
    this.advancedEntryId,
    this.thirdPlaceEntryId,
  });

  final List<TournamentFixture> updatedFixtures;
  final String? advancedEntryId;
  final String? thirdPlaceEntryId;
}

class AdvancementEngine {
  const AdvancementEngine();

  /// Resolves the winner of a knockout fixture given its [result] JSON.
  /// Throws [StateError] if the match is tied and knockout tie-breakers were not resolved.
  String determineKnockoutWinner({
    required TournamentFixture fixture,
    required Map<String, dynamic> result,
  }) {
    final entryA = fixture.entryAId;
    final entryB = fixture.entryBId;
    if (entryA == null || entryB == null) {
      throw StateError('Cannot determine winner when fixture is missing entries');
    }

    // Direct winner entry ID in result
    if (result['winner_entry_id'] != null) {
      return result['winner_entry_id'].toString();
    }

    final sport = result['sport']?.toString().toLowerCase() ?? '';

    if (sport.contains('football')) {
      final fb = result['football'] as Map<String, dynamic>?;
      final gA = (fb?['goals_a'] ?? result['home_score'] ?? result['score_a'] as num?)?.toInt() ?? 0;
      final gB = (fb?['goals_b'] ?? result['away_score'] ?? result['score_b'] as num?)?.toInt() ?? 0;

      if (gA > gB) return entryA;
      if (gB > gA) return entryB;

      // Tie: check penalties
      final pA = (fb?['penalties_a'] ?? result['penalties_a'] as num?)?.toInt() ?? 0;
      final pB = (fb?['penalties_b'] ?? result['penalties_b'] as num?)?.toInt() ?? 0;
      if (pA > pB) return entryA;
      if (pB > pA) return entryB;

      throw StateError('Knockout football match cannot end in a tie without penalties decided');
    } else if (sport.contains('cricket')) {
      final ckt = result['cricket'] as Map<String, dynamic>?;
      final cktA = ckt?['a'] as Map<String, dynamic>?;
      final cktB = ckt?['b'] as Map<String, dynamic>?;
      final runsA = (cktA?['runs'] ?? result['home_score'] ?? result['runs_a'] as num?)?.toInt() ?? 0;
      final runsB = (cktB?['runs'] ?? result['away_score'] ?? result['runs_b'] as num?)?.toInt() ?? 0;

      if (runsA > runsB) return entryA;
      if (runsB > runsA) return entryB;

      // Tie: check super over
      final soA = (ckt?['super_over_a'] ?? result['super_over_a'] as num?)?.toInt() ?? 0;
      final soB = (ckt?['super_over_b'] ?? result['super_over_b'] as num?)?.toInt() ?? 0;
      if (soA > soB) return entryA;
      if (soB > soA) return entryB;

      throw StateError('Knockout cricket match cannot end in a tie without a super over winner');
    } else {
      // Badminton or general
      final gWonA = (result['home_score'] ?? result['games_won_a'] ?? result['home_games_won'] as num?)?.toInt() ?? 0;
      final gWonB = (result['away_score'] ?? result['games_won_b'] ?? result['away_games_won'] as num?)?.toInt() ?? 0;
      if (gWonA > gWonB) return entryA;
      if (gWonB > gWonA) return entryB;

      throw StateError('Knockout match cannot end without a winner');
    }
  }

  /// Advances the winner (and optional semi-final loser for third-place) to downstream fixtures.
  AdvancementResult advanceFixture({
    required List<TournamentFixture> allFixtures,
    required String completedFixtureId,
    required Map<String, dynamic> result,
  }) {
    final fixturesMap = {for (final f in allFixtures) f.id: f};
    final fixture = fixturesMap[completedFixtureId];
    if (fixture == null) {
      throw ArgumentError('Fixture $completedFixtureId not found');
    }

    final winnerId = determineKnockoutWinner(fixture: fixture, result: result);
    final loserId = (fixture.entryAId == winnerId) ? fixture.entryBId : fixture.entryAId;

    // Idempotency check: if already completed with same winner, return unchanged
    if (fixture.status == FixtureStatus.completed && fixture.winnerEntryId == winnerId) {
      return AdvancementResult(
        updatedFixtures: allFixtures,
        advancedEntryId: winnerId,
        thirdPlaceEntryId: loserId,
      );
    }

    // 1. Mark completed fixture
    final updatedCompleted = fixture.copyWith(
      status: FixtureStatus.completed,
      winnerEntryId: winnerId,
      result: result,
    );
    fixturesMap[completedFixtureId] = updatedCompleted;

    // 2. Advance winner into next fixture slot
    if (fixture.nextFixtureId != null) {
      final next = fixturesMap[fixture.nextFixtureId];
      if (next != null) {
        final slot = fixture.nextSlot;
        final updatedNext = TournamentFixture(
          id: next.id,
          tournamentId: next.tournamentId,
          stage: next.stage,
          groupId: next.groupId,
          round: next.round,
          position: next.position,
          roundLabel: next.roundLabel,
          entryAId: slot == 'a' ? winnerId : next.entryAId,
          entryBId: slot == 'b' ? winnerId : next.entryBId,
          sourceFixtureAId: next.sourceFixtureAId,
          sourceFixtureBId: next.sourceFixtureBId,
          sourceOutcomeA: next.sourceOutcomeA,
          sourceOutcomeB: next.sourceOutcomeB,
          isBye: next.isBye,
          scheduledAt: next.scheduledAt,
          venue: next.venue,
          status: (slot == 'a' ? (next.entryBId != null ? FixtureStatus.scheduled : next.status) : (next.entryAId != null ? FixtureStatus.scheduled : next.status)),
          matchId: next.matchId,
          result: next.result,
          winnerEntryId: next.winnerEntryId,
          nextFixtureId: next.nextFixtureId,
          nextSlot: next.nextSlot,
        );
        fixturesMap[next.id] = updatedNext;
      }
    }

    // 3. Advance loser into third-place playoff (if this was a semi-final)
    for (final f in fixturesMap.values) {
      if (f.stage == FixtureStage.thirdPlace && loserId != null) {
        if (f.sourceFixtureAId == completedFixtureId) {
          fixturesMap[f.id] = f.copyWith(entryAId: loserId);
        } else if (f.sourceFixtureBId == completedFixtureId) {
          fixturesMap[f.id] = f.copyWith(entryBId: loserId);
        }
      }
    }

    return AdvancementResult(
      updatedFixtures: fixturesMap.values.toList(),
      advancedEntryId: winnerId,
      thirdPlaceEntryId: loserId,
    );
  }

  /// Handles entry withdrawal or disqualification mid-tournament.
  /// Converts all remaining unplayed fixtures of the entry into walkovers for the opponent.
  List<TournamentFixture> handleEntryWithdrawal({
    required List<TournamentFixture> allFixtures,
    required String withdrawnEntryId,
    String reason = 'Withdrawal',
  }) {
    final fixturesMap = {for (final f in allFixtures) f.id: f};

    for (final f in allFixtures) {
      final isPending = f.status == FixtureStatus.pending || f.status == FixtureStatus.scheduled;
      if (!isPending) continue;

      final isEntryA = f.entryAId == withdrawnEntryId;
      final isEntryB = f.entryBId == withdrawnEntryId;

      if (isEntryA || isEntryB) {
        final opponentId = isEntryA ? f.entryBId : f.entryAId;
        final walkoverWinner = opponentId;

        // Apply walkover to this fixture
        final updated = f.copyWith(
          status: FixtureStatus.walkover,
          winnerEntryId: walkoverWinner,
          result: {
            'result_type': 'walkover',
            'winner_entry_id': walkoverWinner,
            'withdrawn_entry_id': withdrawnEntryId,
            'reason': reason,
            'margin': 'Walkover ($reason)',
          },
        );
        fixturesMap[f.id] = updated;

        // Advance opponent if knockout stage and opponent exists
        if (f.nextFixtureId != null && walkoverWinner != null) {
          final next = fixturesMap[f.nextFixtureId];
          if (next != null) {
            final slot = f.nextSlot;
            fixturesMap[next.id] = TournamentFixture(
              id: next.id,
              tournamentId: next.tournamentId,
              stage: next.stage,
              groupId: next.groupId,
              round: next.round,
              position: next.position,
              roundLabel: next.roundLabel,
              entryAId: slot == 'a' ? walkoverWinner : next.entryAId,
              entryBId: slot == 'b' ? walkoverWinner : next.entryBId,
              sourceFixtureAId: next.sourceFixtureAId,
              sourceFixtureBId: next.sourceFixtureBId,
              sourceOutcomeA: next.sourceOutcomeA,
              sourceOutcomeB: next.sourceOutcomeB,
              status: next.status,
              nextFixtureId: next.nextFixtureId,
              nextSlot: next.nextSlot,
            );
          }
        }
      }
    }

    return fixturesMap.values.toList();
  }

  /// Safeguard check before correcting a fixture result.
  /// Throws [StateError] if downstream matches have already been completed unless [resetDownstream] is true.
  List<TournamentFixture> correctFixtureResult({
    required List<TournamentFixture> allFixtures,
    required String fixtureId,
    required Map<String, dynamic> newResult,
    bool resetDownstream = false,
  }) {
    final fixturesMap = {for (final f in allFixtures) f.id: f};
    final fixture = fixturesMap[fixtureId];
    if (fixture == null) throw ArgumentError('Fixture $fixtureId not found');

    // Check downstream fixtures
    if (fixture.nextFixtureId != null) {
      final next = fixturesMap[fixture.nextFixtureId];
      if (next != null && next.status == FixtureStatus.completed && !resetDownstream) {
        throw StateError(
          'Downstream match (${next.roundLabel}) has already been played. '
          'Correcting this result requires explicit reset of downstream fixtures.',
        );
      }
    }

    // Re-advance with the corrected result
    return advanceFixture(
      allFixtures: allFixtures,
      completedFixtureId: fixtureId,
      result: newResult,
    ).updatedFixtures;
  }
}
