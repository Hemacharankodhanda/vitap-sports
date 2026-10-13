/// VIT-AP Sports — Comprehensive Tournament Pure-Dart Engine Tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/engines/advancement_engine.dart';
import 'package:vitap_sports/features/tournaments/engines/group_stage_engine.dart';
import 'package:vitap_sports/features/tournaments/engines/knockout_bracket_engine.dart';
import 'package:vitap_sports/features/tournaments/engines/round_robin_engine.dart';
import 'package:vitap_sports/features/tournaments/engines/standings_engine.dart';

void main() {
  group('KnockoutBracketEngine Tests', () {
    const engine = KnockoutBracketEngine();

    test('bracket size and byes for N from 2 to 64', () {
      for (int n = 2; n <= 64; n++) {
        final entries = List.generate(
          n,
          (i) => TournamentEntry(
            id: 'team_${i + 1}',
            tournamentId: 't1',
            displayName: 'Team ${i + 1}',
            seed: i + 1,
          ),
        );

        final fixtures = engine.generateBracket(
          tournamentId: 't1',
          entries: entries,
        );

        final bracketSize = KnockoutBracketEngine.nextPowerOfTwo(n);
        final totalRounds = KnockoutBracketEngine.totalRounds(bracketSize);
        final byes = bracketSize - n;

        expect(bracketSize >= n, isTrue);
        expect((bracketSize & (bracketSize - 1)), 0); // is power of 2

        // Total matches in full tree = bracketSize - 1
        expect(fixtures.length, bracketSize - 1);

        // Check Round 1 byes
        final r1Fixtures = fixtures.where((f) => f.round == 1).toList();
        final completedByes = r1Fixtures.where((f) => f.isBye && f.status == FixtureStatus.completed).toList();
        expect(completedByes.length, byes);

        // Final round has exactly 1 fixture labeled 'Final'
        final finals = fixtures.where((f) => f.round == totalRounds).toList();
        expect(finals.length, 1);
        expect(finals.first.roundLabel, 'Final');
      }
    });

    test('desk-check: 6 entrants produces size 8 with seeds 1 and 2 on byes', () {
      final entries = List.generate(
        6,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
          seed: i + 1,
        ),
      );

      final fixtures = engine.generateBracket(
        tournamentId: 't1',
        entries: entries,
      );

      // Bracket size 8 -> Round 1 has 4 matches (pos 1, 2, 3, 4)
      final r1 = fixtures.where((f) => f.round == 1).toList()..sort((a, b) => a.position.compareTo(b.position));
      expect(r1.length, 4);

      // In size 8:
      // match 1 is 1 v 8 (8 is bye -> Seed 1 on bye, auto-advanced)
      // match 2 is 4 v 5 (played)
      // match 3 is 3 v 6 (played)
      // match 4 is 2 v 7 (7 is bye -> Seed 2 on bye, auto-advanced)
      expect(r1[0].isBye, isTrue);
      expect(r1[0].winnerEntryId, 'team_1');
      expect(r1[0].status, FixtureStatus.completed);

      expect(r1[1].isBye, isFalse);
      expect(r1[1].entryAId, 'team_4');
      expect(r1[1].entryBId, 'team_5');

      expect(r1[2].isBye, isFalse);
      expect(r1[2].entryAId, 'team_3');
      expect(r1[2].entryBId, 'team_6');

      expect(r1[3].isBye, isTrue);
      expect(r1[3].winnerEntryId, 'team_2');
      expect(r1[3].status, FixtureStatus.completed);

      // Round 2 (Semi-finals):
      // Semi 1: team_1 is pre-populated in slot a
      // Semi 2: team_2 is pre-populated in slot b
      final r2 = fixtures.where((f) => f.round == 2).toList()..sort((a, b) => a.position.compareTo(b.position));
      expect(r2.length, 2);
      expect(r2[0].entryAId, 'team_1');
      expect(r2[1].entryBId, 'team_2');

      // Seed 1 and Seed 2 are on opposite sides of the bracket and can only meet in Final
      expect(r2[0].nextFixtureId, r2[1].nextFixtureId); // meet in the Final
    });

    test('desk-check: 5 entrants produces size 8 with 3 byes (seeds 1, 2, 3)', () {
      final entries = List.generate(
        5,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
          seed: i + 1,
        ),
      );

      final fixtures = engine.generateBracket(
        tournamentId: 't1',
        entries: entries,
      );

      final r1 = fixtures.where((f) => f.round == 1).toList()..sort((a, b) => a.position.compareTo(b.position));
      expect(r1.length, 4);

      // Byes on match 1 (seed 1), match 3 (seed 3), match 4 (seed 2)
      // Only match 2 (4 v 5) is played in Round 1
      expect(r1[0].isBye, isTrue);
      expect(r1[0].winnerEntryId, 'team_1');

      expect(r1[1].isBye, isFalse);
      expect(r1[1].entryAId, 'team_4');
      expect(r1[1].entryBId, 'team_5');

      expect(r1[2].isBye, isTrue);
      expect(r1[2].winnerEntryId, 'team_3');

      expect(r1[3].isBye, isTrue);
      expect(r1[3].winnerEntryId, 'team_2');
    });

    test('includes third-place match taking losers of semi-finals', () {
      final entries = List.generate(
        4,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
          seed: i + 1,
        ),
      );

      final fixtures = engine.generateBracket(
        tournamentId: 't1',
        entries: entries,
        includeThirdPlace: true,
      );

      final thirdPlace = fixtures.where((f) => f.stage == FixtureStage.thirdPlace).toList();
      expect(thirdPlace.length, 1);
      expect(thirdPlace.first.roundLabel, 'Third-place Playoff');
      expect(thirdPlace.first.sourceOutcomeA, 'loser');
      expect(thirdPlace.first.sourceOutcomeB, 'loser');
    });

    test('random draw with same stored seed reproduces identical bracket', () {
      final entries = List.generate(
        8,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
        ),
      );

      final bracket1 = engine.generateBracket(
        tournamentId: 't1',
        entries: entries,
        randomSeed: 98765,
      );

      final bracket2 = engine.generateBracket(
        tournamentId: 't1',
        entries: entries,
        randomSeed: 98765,
      );

      for (int i = 0; i < bracket1.length; i++) {
        expect(bracket1[i].entryAId, bracket2[i].entryAId);
        expect(bracket1[i].entryBId, bracket2[i].entryBId);
      }
    });
  });

  group('RoundRobinEngine Tests', () {
    const engine = RoundRobinEngine();

    test('desk-check: 5 entrants produces 5 rounds and 10 fixtures', () {
      final entries = List.generate(
        5,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
        ),
      );

      final fixtures = engine.generateSchedule(
        tournamentId: 't1',
        entries: entries,
      );

      // Formula for N=5: C(5, 2) = 10 matches total, 5 rounds
      expect(fixtures.length, 10);

      final rounds = fixtures.map((f) => f.round).toSet();
      expect(rounds.length, 5);

      // Every round has exactly 2 matches (and 1 team resting)
      for (int r = 1; r <= 5; r++) {
        final matchesInR = fixtures.where((f) => f.round == r).toList();
        expect(matchesInR.length, 2);

        // No team plays twice in the same round
        final teamsInRound = <String>{};
        for (final m in matchesInR) {
          expect(teamsInRound.add(m.entryAId!), isTrue);
          expect(teamsInRound.add(m.entryBId!), isTrue);
        }
      }

      // Every pair meets exactly once
      final pairs = <String>{};
      for (final f in fixtures) {
        final sorted = [f.entryAId!, f.entryBId!]..sort();
        expect(pairs.add('${sorted[0]}_${sorted[1]}'), isTrue);
      }
      expect(pairs.length, 10);
    });

    test('desk-check: 6 entrants produces 5 rounds and 15 fixtures', () {
      final entries = List.generate(
        6,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
        ),
      );

      final fixtures = engine.generateSchedule(
        tournamentId: 't1',
        entries: entries,
      );

      // Formula for N=6: C(6, 2) = 15 matches total, 5 rounds
      expect(fixtures.length, 15);
      for (int r = 1; r <= 5; r++) {
        expect(fixtures.where((f) => f.round == r).length, 3);
      }
    });

    test('double round robin produces swapped second leg', () {
      final entries = List.generate(
        4,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
        ),
      );

      final fixtures = engine.generateSchedule(
        tournamentId: 't1',
        entries: entries,
        doubleRoundRobin: true,
      );

      // 4 teams: single is 6 matches, double is 12 matches (6 rounds)
      expect(fixtures.length, 12);
      expect(fixtures.map((f) => f.round).toSet().length, 6);

      // Check first leg vs second leg match swap
      final leg1Match = fixtures.first;
      final leg2Match = fixtures.firstWhere(
        (f) => f.entryAId == leg1Match.entryBId && f.entryBId == leg1Match.entryAId,
      );
      expect(leg2Match.round, leg1Match.round + 3);
    });
  });

  group('GroupStageEngine Tests', () {
    const engine = GroupStageEngine();

    test('snake distribution and cross-pairing for 2 groups of 4 with 2 qualifiers', () {
      final entries = List.generate(
        8,
        (i) => TournamentEntry(
          id: 'team_${i + 1}',
          tournamentId: 't1',
          displayName: 'Team ${i + 1}',
          seed: i + 1,
        ),
      );

      final result = engine.setupGroupStage(
        tournamentId: 't1',
        entries: entries,
        groupsCount: 2,
        qualifiersPerGroup: 2,
      );

      expect(result.groups.length, 2);
      expect(result.groups[0].name, 'Group A');
      expect(result.groups[1].name, 'Group B');

      // Snake allocation for 8 seeds into 2 groups:
      // Group A: Seed 1, 4, 5, 8
      // Group B: Seed 2, 3, 6, 7
      final grpAEntries = result.groupEntries[result.groups[0].id]!;
      final grpBEntries = result.groupEntries[result.groups[1].id]!;

      expect(grpAEntries.map((e) => e.seed).toList(), [1, 4, 5, 8]);
      expect(grpBEntries.map((e) => e.seed).toList(), [2, 3, 6, 7]);

      // Round-robin fixtures per group of 4: 6 matches per group = 12 total group matches
      expect(result.groupFixtures.length, 12);

      // Cross-pairing Knockout Stage:
      // Semi-final 1: A1 vs B2
      // Semi-final 2: B1 vs A2
      // Final: Winner SF1 vs Winner SF2
      expect(result.knockoutFixtures.length, 3);
      final sf1 = result.knockoutFixtures.firstWhere((f) => f.round == 1 && f.position == 1);
      final sf2 = result.knockoutFixtures.firstWhere((f) => f.round == 1 && f.position == 2);
      final fin = result.knockoutFixtures.firstWhere((f) => f.round == 2 && f.position == 1);

      expect(sf1.roundLabel, contains('A1 vs B2'));
      expect(sf2.roundLabel, contains('B1 vs A2'));
      expect(fin.roundLabel, 'Final');
    });
  });

  group('StandingsEngine Tests', () {
    const engine = StandingsEngine();

    test('Football standings: points 3/1/0, GD, and head-to-head tie-break', () {
      final teamA = const TournamentEntry(id: 'A', tournamentId: 't1', displayName: 'Arsenal');
      final teamB = const TournamentEntry(id: 'B', tournamentId: 't1', displayName: 'Chelsea');
      final teamC = const TournamentEntry(id: 'C', tournamentId: 't1', displayName: 'Spurs');

      final fixtures = [
        // Match 1: A beats B 2-1
        TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'A',
          entryBId: 'B',
          status: FixtureStatus.completed,
          result: {'football': {'goals_a': 2, 'goals_b': 1}},
        ),
        // Match 2: B beats C 3-0
        TournamentFixture(
          id: 'f2',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 2,
          position: 1,
          roundLabel: 'R2',
          entryAId: 'B',
          entryBId: 'C',
          status: FixtureStatus.completed,
          result: {'football': {'goals_a': 3, 'goals_b': 0}},
        ),
        // Match 3: C beats A 1-0
        TournamentFixture(
          id: 'f3',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 3,
          position: 1,
          roundLabel: 'R3',
          entryAId: 'C',
          entryBId: 'A',
          status: FixtureStatus.completed,
          result: {'football': {'goals_a': 1, 'goals_b': 0}},
        ),
      ];

      // All teams have 3 points (1 win, 1 loss each)
      // Goal Differences:
      // B: GF 4, GA 2 -> GD +2
      // A: GF 2, GA 2 -> GD 0
      // C: GF 1, GA 3 -> GD -2
      final standings = engine.calculateStandings(
        sport: 'football',
        entries: [teamA, teamB, teamC],
        fixtures: fixtures,
      );

      expect(standings[0].entryId, 'B'); // GD +2
      expect(standings[0].points, 3);
      expect(standings[0].goalDifference, 2);

      expect(standings[1].entryId, 'A'); // GD 0
      expect(standings[1].goalDifference, 0);

      expect(standings[2].entryId, 'C'); // GD -2
      expect(standings[2].goalDifference, -2);
    });

    test('Football walkover results default to 3-0 score', () {
      final teamA = const TournamentEntry(id: 'A', tournamentId: 't1', displayName: 'Team A');
      final teamB = const TournamentEntry(id: 'B', tournamentId: 't1', displayName: 'Team B');

      final fixtures = [
        TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'A',
          entryBId: 'B',
          status: FixtureStatus.walkover,
          winnerEntryId: 'A',
          result: {'result_type': 'walkover'},
        ),
      ];

      final standings = engine.calculateStandings(
        sport: 'football',
        entries: [teamA, teamB],
        fixtures: fixtures,
      );

      expect(standings[0].entryId, 'A');
      expect(standings[0].won, 1);
      expect(standings[0].points, 3);
      expect(standings[0].goalsFor, 3);
      expect(standings[0].goalsAgainst, 0);
      expect(standings[0].goalDifference, 3);

      expect(standings[1].entryId, 'B');
      expect(standings[1].lost, 1);
      expect(standings[1].points, 0);
      expect(standings[1].goalsAgainst, 3);
      expect(standings[1].goalDifference, -3);
    });

    test('Cricket NRR desk check: all-out rule counts full overs quota', () {
      final teamA = const TournamentEntry(id: 'A', tournamentId: 't1', displayName: 'India');
      final teamB = const TournamentEntry(id: 'B', tournamentId: 't1', displayName: 'Pakistan');

      // Example from specification:
      // Team A scores 120/6 in 10 overs.
      // Team B concedes and scores 100 ALL OUT in 8.2 overs in a 10-over match.
      // Team B was ALL OUT -> its overs faced count as the full quota of 10.0 overs!
      // NRR contribution for Team A:
      // Runs scored / overs faced = 120 / 10 = 12.0
      // Runs conceded / overs bowled = 100 / 10 = 10.0
      // NRR = 12.0 - 10.0 = +2.0
      final fixtures = [
        TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'A',
          entryBId: 'B',
          status: FixtureStatus.completed,
          result: {
            'cricket': {
              'a': {'runs': 120, 'wickets': 6, 'overs': 10.0, 'all_out': false},
              'b': {'runs': 100, 'wickets': 10, 'overs': 8.2, 'all_out': true},
            },
          },
        ),
      ];

      final standings = engine.calculateStandings(
        sport: 'cricket',
        entries: [teamA, teamB],
        fixtures: fixtures,
        config: {'match_overs': 10},
      );

      expect(standings[0].entryId, 'A');
      expect(standings[0].won, 1);
      expect(standings[0].points, 2);
      expect(standings[0].netRunRate, closeTo(2.0, 0.001));

      expect(standings[1].entryId, 'B');
      expect(standings[1].lost, 1);
      expect(standings[1].points, 0);
      expect(standings[1].netRunRate, closeTo(-2.0, 0.001));
    });

    test('Cricket balls to decimal overs conversion', () {
      // 3.4 overs = 22 balls = 22 / 6 = 3.66667
      expect(StandingsEngine.oversToDecimal(3.4), closeTo(3.6667, 0.001));
      // 8.2 overs = 50 balls = 50 / 6 = 8.33333
      expect(StandingsEngine.oversToDecimal(8.2), closeTo(8.3333, 0.001));
      // 10.0 overs = 60 balls = 10.0
      expect(StandingsEngine.oversToDecimal(10.0), closeTo(10.0, 0.001));
    });

    test('Badminton standings: match wins, game difference, and point difference', () {
      final playerA = const TournamentEntry(id: 'A', tournamentId: 't1', displayName: 'Player A');
      final playerB = const TournamentEntry(id: 'B', tournamentId: 't1', displayName: 'Player B');

      final fixtures = [
        // A beats B: 2 games to 1 (21-19, 18-21, 21-15) -> Games: 2-1 (+1 GD), Points: 60-55 (+5 PD)
        TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.group,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'A',
          entryBId: 'B',
          status: FixtureStatus.completed,
          result: {
            'badminton': {
              'games_won_a': 2,
              'games_won_b': 1,
              'points_a': 60,
              'points_b': 55,
            },
          },
        ),
      ];

      final standings = engine.calculateStandings(
        sport: 'badminton',
        entries: [playerA, playerB],
        fixtures: fixtures,
      );

      expect(standings[0].entryId, 'A');
      expect(standings[0].won, 1);
      expect(standings[0].points, 1);
      expect(standings[0].gameDifference, 1);
      expect(standings[0].pointDifference, 5);

      expect(standings[1].entryId, 'B');
      expect(standings[1].lost, 1);
      expect(standings[1].points, 0);
      expect(standings[1].gameDifference, -1);
      expect(standings[1].pointDifference, -5);
    });
  });

  group('AdvancementEngine Tests', () {
    const engine = AdvancementEngine();

    test('advances winner into next round slot and loser into third-place', () {
      final fixtures = [
        const TournamentFixture(
          id: 'sf1',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 1,
          roundLabel: 'Semi-final 1',
          entryAId: 'team_1',
          entryBId: 'team_2',
          nextFixtureId: 'final',
          nextSlot: 'a',
          status: FixtureStatus.scheduled,
        ),
        const TournamentFixture(
          id: 'final',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 2,
          position: 1,
          roundLabel: 'Final',
          status: FixtureStatus.pending,
        ),
        const TournamentFixture(
          id: 'third',
          tournamentId: 't1',
          stage: FixtureStage.thirdPlace,
          round: 2,
          position: 2,
          roundLabel: 'Third-place Playoff',
          sourceFixtureAId: 'sf1',
          sourceOutcomeA: 'loser',
          status: FixtureStatus.pending,
        ),
      ];

      final result = engine.advanceFixture(
        allFixtures: fixtures,
        completedFixtureId: 'sf1',
        result: {'winner_entry_id': 'team_1'},
      );

      expect(result.advancedEntryId, 'team_1');
      expect(result.thirdPlaceEntryId, 'team_2');

      final updatedFinal = result.updatedFixtures.firstWhere((f) => f.id == 'final');
      expect(updatedFinal.entryAId, 'team_1');

      final updatedThird = result.updatedFixtures.firstWhere((f) => f.id == 'third');
      expect(updatedThird.entryAId, 'team_2');
    });

    test('knockout match throws error if tied without shootout or super over', () {
      const fixture = TournamentFixture(
        id: 'f1',
        tournamentId: 't1',
        stage: FixtureStage.knockout,
        round: 1,
        position: 1,
        roundLabel: 'R1',
        entryAId: 'team_1',
        entryBId: 'team_2',
      );

      // Football tied 1-1 with no penalties
      expect(
        () => engine.determineKnockoutWinner(
          fixture: fixture,
          result: {
            'sport': 'football',
            'football': {'goals_a': 1, 'goals_b': 1},
          },
        ),
        throwsA(isA<StateError>()),
      );

      // Cricket tied 100-100 with no super over
      expect(
        () => engine.determineKnockoutWinner(
          fixture: fixture,
          result: {
            'sport': 'cricket',
            'cricket': {
              'a': {'runs': 100},
              'b': {'runs': 100},
            },
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('repeated advancement calls are idempotent', () {
      final fixtures = [
        const TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'team_1',
          entryBId: 'team_2',
          nextFixtureId: 'f2',
          nextSlot: 'a',
          status: FixtureStatus.scheduled,
        ),
        const TournamentFixture(
          id: 'f2',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 2,
          position: 1,
          roundLabel: 'Final',
          status: FixtureStatus.pending,
        ),
      ];

      final res1 = engine.advanceFixture(
        allFixtures: fixtures,
        completedFixtureId: 'f1',
        result: {'winner_entry_id': 'team_1'},
      );

      final res2 = engine.advanceFixture(
        allFixtures: res1.updatedFixtures,
        completedFixtureId: 'f1',
        result: {'winner_entry_id': 'team_1'},
      );

      expect(res1.updatedFixtures.length, res2.updatedFixtures.length);
      final f2_1 = res1.updatedFixtures.firstWhere((f) => f.id == 'f2');
      final f2_2 = res2.updatedFixtures.firstWhere((f) => f.id == 'f2');
      expect(f2_1.entryAId, f2_2.entryAId);
    });

    test('entry withdrawal converts remaining fixtures to walkovers and advances opponent', () {
      final fixtures = [
        const TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 1,
          roundLabel: 'R1',
          entryAId: 'team_1',
          entryBId: 'team_2',
          nextFixtureId: 'final',
          nextSlot: 'a',
          status: FixtureStatus.scheduled,
        ),
        const TournamentFixture(
          id: 'final',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 2,
          position: 1,
          roundLabel: 'Final',
          status: FixtureStatus.pending,
        ),
      ];

      // team_1 withdraws
      final updated = engine.handleEntryWithdrawal(
        allFixtures: fixtures,
        withdrawnEntryId: 'team_1',
        reason: 'Injury',
      );

      final f1 = updated.firstWhere((f) => f.id == 'f1');
      expect(f1.status, FixtureStatus.walkover);
      expect(f1.winnerEntryId, 'team_2'); // opponent advances

      final fin = updated.firstWhere((f) => f.id == 'final');
      expect(fin.entryAId, 'team_2');
    });

    test('correctFixtureResult blocked if downstream match already completed without reset', () {
      final fixtures = [
        const TournamentFixture(
          id: 'f1',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 1,
          position: 1,
          roundLabel: 'Semi-final',
          entryAId: 'team_1',
          entryBId: 'team_2',
          winnerEntryId: 'team_1',
          nextFixtureId: 'f2',
          nextSlot: 'a',
          status: FixtureStatus.completed,
        ),
        const TournamentFixture(
          id: 'f2',
          tournamentId: 't1',
          stage: FixtureStage.knockout,
          round: 2,
          position: 1,
          roundLabel: 'Final',
          entryAId: 'team_1',
          entryBId: 'team_3',
          winnerEntryId: 'team_1',
          status: FixtureStatus.completed, // Final was already played!
        ),
      ];

      // Attempt to change winner of f1 to team_2 without resetDownstream should throw
      expect(
        () => engine.correctFixtureResult(
          allFixtures: fixtures,
          fixtureId: 'f1',
          newResult: {'winner_entry_id': 'team_2'},
          resetDownstream: false,
        ),
        throwsA(isA<StateError>()),
      );

      // With resetDownstream = true, it succeeds
      final corrected = engine.correctFixtureResult(
        allFixtures: fixtures,
        fixtureId: 'f1',
        newResult: {'winner_entry_id': 'team_2'},
        resetDownstream: true,
      );

      final f1 = corrected.firstWhere((f) => f.id == 'f1');
      expect(f1.winnerEntryId, 'team_2');

      final f2 = corrected.firstWhere((f) => f.id == 'f2');
      expect(f2.entryAId, 'team_2');
    });
  });
}
