/// VIT-AP Sports — Tournament Providers & Service Unit Tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitap_sports/features/tournaments/domain/models/tournament_models.dart';
import 'package:vitap_sports/features/tournaments/providers/tournament_providers.dart';

void main() {
  group('TournamentFilterState Tests', () {
    test('default state has sport=all and status=all', () {
      const state = TournamentFilterState();
      expect(state.sport, 'all');
      expect(state.status, 'all');
    });

    test('copyWith updates state correctly', () {
      const state = TournamentFilterState();
      final updated = state.copyWith(sport: 'cricket', status: 'live');
      expect(updated.sport, 'cricket');
      expect(updated.status, 'live');
    });
  });

  group('Tournament Domain Model JSON Serialization Tests', () {
    test('TournamentModel fromJson and toJson roundtrip', () {
      final json = {
        'id': 't1',
        'name': 'Inter-Hostel Cricket Trophy',
        'sport': 'cricket',
        'format': 'groups_knockout',
        'status': 'registration_open',
        'scope': 'hostel',
        'config': {'overs': 10},
        'eligibility': {'hostel_block': 'MH-1'},
        'is_official': true,
        'max_entries': 8,
      };

      final model = TournamentModel.fromJson(json);
      expect(model.id, 't1');
      expect(model.name, 'Inter-Hostel Cricket Trophy');
      expect(model.sport, 'cricket');
      expect(model.format, TournamentFormat.groupsKnockout);
      expect(model.status, TournamentStatus.registrationOpen);
      expect(model.scope, TournamentScope.hostel);
      expect(model.config['overs'], 10);
      expect(model.eligibility['hostel_block'], 'MH-1');
      expect(model.isOfficial, isTrue);
      expect(model.maxEntries, 8);

      final output = model.toJson();
      expect(output['format'], 'groups_knockout');
      expect(output['status'], 'registration_open');
      expect(output['scope'], 'hostel');
    });

    test('TournamentEntry fromJson and toJson roundtrip', () {
      final json = {
        'id': 'e1',
        'tournament_id': 't1',
        'kind': 'team',
        'team_id': 'tm1',
        'display_name': 'Block B Warriors',
        'seed': 1,
        'status': 'approved',
      };

      final entry = TournamentEntry.fromJson(json);
      expect(entry.id, 'e1');
      expect(entry.kind, EntryKind.team);
      expect(entry.teamId, 'tm1');
      expect(entry.seed, 1);
      expect(entry.status, EntryStatus.approved);

      final output = entry.toJson();
      expect(output['kind'], 'team');
      expect(output['status'], 'approved');
    });

    test('TournamentFixture fromJson and toJson roundtrip', () {
      final json = {
        'id': 'f1',
        'tournament_id': 't1',
        'stage': 'knockout',
        'round': 2,
        'position': 1,
        'round_label': 'Final',
        'entry_a_id': 'e1',
        'entry_b_id': 'e2',
        'status': 'scheduled',
        'is_bye': false,
      };

      final fix = TournamentFixture.fromJson(json);
      expect(fix.id, 'f1');
      expect(fix.stage, FixtureStage.knockout);
      expect(fix.roundLabel, 'Final');
      expect(fix.entryAId, 'e1');
      expect(fix.entryBId, 'e2');
      expect(fix.status, FixtureStatus.scheduled);

      final output = fix.toJson();
      expect(output['stage'], 'knockout');
      expect(output['status'], 'scheduled');
    });
  });

  group('tournamentStandingsProvider Derived Tests', () {
    test('computes derived football league standings on read without db drift', () async {
      const tournament = TournamentModel(
        id: 't_fb',
        name: 'VIT-AP Premier League',
        sport: 'football',
        format: TournamentFormat.league,
        status: TournamentStatus.live,
      );

      final entries = [
        const TournamentEntry(id: 'team_a', tournamentId: 't_fb', displayName: 'Team A'),
        const TournamentEntry(id: 'team_b', tournamentId: 't_fb', displayName: 'Team B'),
      ];

      final fixtures = [
        const TournamentFixture(
          id: 'f1',
          tournamentId: 't_fb',
          stage: FixtureStage.group,
          round: 1,
          position: 1,
          roundLabel: 'Match 1',
          entryAId: 'team_a',
          entryBId: 'team_b',
          status: FixtureStatus.completed,
          result: {
            'winner_entry_id': 'team_a',
            'football': {'goals_a': 3, 'goals_b': 1},
          },
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          tournamentDetailProvider('t_fb').overrideWith((ref) => Future.value(tournament)),
          tournamentEntriesProvider('t_fb').overrideWith((ref) => Stream.value(entries)),
          tournamentFixturesProvider('t_fb').overrideWith((ref) => Stream.value(fixtures)),
          tournamentGroupsProvider('t_fb').overrideWith((ref) => Future.value([])),
        ],
      );

      await container.read(tournamentDetailProvider('t_fb').future);
      await container.read(tournamentEntriesProvider('t_fb').future);
      await container.read(tournamentFixturesProvider('t_fb').future);
      await container.read(tournamentGroupsProvider('t_fb').future);
      await Future<void>.delayed(Duration.zero);

      final standingsAsync = container.read(tournamentStandingsProvider('t_fb'));
      expect(standingsAsync.hasValue, isTrue);

      final tables = standingsAsync.value!;
      expect(tables.containsKey('overall'), isTrue);

      final rows = tables['overall']!;
      expect(rows.length, 2);
      expect(rows[0].entryId, 'team_a');
      expect(rows[0].points, 3);
      expect(rows[0].goalsFor, 3);
      expect(rows[0].goalsAgainst, 1);
      expect(rows[0].goalDifference, 2);

      expect(rows[1].entryId, 'team_b');
      expect(rows[1].points, 0);
      expect(rows[1].goalDifference, -2);
    });
  });
}
