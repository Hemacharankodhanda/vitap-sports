/// VIT-AP Sports — Live Scorer & Queue Unit Tests.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitap_sports/features/scoring/data/live_scorer_service.dart';
import 'package:vitap_sports/features/scoring/domain/match_event.dart';
import 'package:vitap_sports/features/scoring/engines/football/football_state.dart';
import 'package:vitap_sports/features/scoring/providers/live_scorer_providers.dart';

class FakeRealtimeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel subscribe([void Function(RealtimeSubscribeStatus, Object?)? callback, Duration? timeout]) {
    return this;
  }
}

class FakeLiveScorerService extends Fake implements LiveScorerService {
  FakeLiveScorerService({
    required this.matchData,
    this.initialEvents = const [],
    this.shouldFailRecord = false,
  });

  final Map<String, dynamic>? matchData;
  final List<MatchEvent> initialEvents;
  bool shouldFailRecord;

  final List<MatchEvent> recordedEvents = [];
  final List<String> undoneEventIds = [];
  bool finishMatchCalled = false;
  bool startMatchCalled = false;
  DateTime? startedAt;
  Map<String, dynamic>? passedInitialScore;

  @override
  Future<void> startMatch({
    required String matchId,
    required Map<String, dynamic> config,
    required Map<String, dynamic> initialScore,
    DateTime? startTime,
  }) async {
    startMatchCalled = true;
    startedAt = startTime;
    passedInitialScore = initialScore;
  }

  @override
  Future<Map<String, dynamic>?> fetchMatch(String matchId) async => matchData;

  @override
  Future<List<MatchEvent>> fetchEvents(String matchId) async => [
        ...initialEvents,
        ...recordedEvents,
      ];

  @override
  Future<List<Map<String, dynamic>>> fetchTeamPlayers(String teamId) async => [];

  @override
  Future<Map<String, dynamic>> recordEvent({
    required String matchId,
    required MatchEvent event,
    required Map<String, dynamic> snapshot,
  }) async {
    if (shouldFailRecord) {
      throw Exception('Network unreachable');
    }
    recordedEvents.add(event);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> undoEvent({
    required String matchId,
    required String eventId,
    required Map<String, dynamic> snapshot,
  }) async {
    undoneEventIds.add(eventId);
    recordedEvents.removeWhere((e) => e.id == eventId);
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> finishMatch({
    required String matchId,
    required Map<String, dynamic> result,
    required Map<String, dynamic> finalScore,
  }) async {
    finishMatchCalled = true;
    return {'success': true};
  }

  @override
  RealtimeChannel subscribeToEvents({
    required String matchId,
    required void Function(MatchEvent event) onInsert,
    required void Function(String eventId) onDelete,
  }) {
    return FakeRealtimeChannel();
  }

  @override
  Future<void> unsubscribe(RealtimeChannel channel) async {}
}

void main() {
  group('LiveScorerNotifier & Offline Queue Tests', () {
    const testMatchId = 'm-123';
    const testUserId = 'u-scorer';

    final fakeMatchData = {
      'id': testMatchId,
      'sports': {'name': 'Football'},
      'created_by': testUserId,
      'status': 'live',
      'config': {'players_per_side': 7, 'half_length_minutes': 20},
      'match_participants': [
        {'side': 'home', 'team_id': 'team-a', 'teams': {'name': 'Team Alpha'}},
        {'side': 'away', 'team_id': 'team-b', 'teams': {'name': 'Team Beta'}},
      ],
    };

    test('Initializes state, verifies authorization, and folds initial events', () async {
      final fakeService = FakeLiveScorerService(
        matchData: fakeMatchData,
        initialEvents: [
          MatchEvent(
            id: 'ev-1',
            matchId: testMatchId,
            seq: 1,
            type: 'goal',
            teamId: 'team-a',
          ),
        ],
      );

      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );

      await notifier.init();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.isAuthorized, isTrue);
      expect(notifier.state.sport, 'football');
      expect(notifier.state.homeName, 'Team Alpha');
      expect(notifier.state.awayName, 'Team Beta');
      expect(notifier.state.events.length, 1);

      final state = notifier.state.scoringState as FootballState;
      expect(state.homeScore, 1);
      expect(state.awayScore, 0);
    });

    test('Optimistic local apply immediately reflects action and flushes to service', () async {
      final fakeService = FakeLiveScorerService(matchData: fakeMatchData);
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      await notifier.recordAction(
        type: 'goal',
        teamId: 'team-a',
        payload: {'kind': 'open_play'},
      );

      // Verify immediate local apply
      expect(notifier.state.events.length, 1);
      final footballState = notifier.state.scoringState as FootballState;
      expect(footballState.homeScore, 1);

      // Flush queue finished
      expect(fakeService.recordedEvents.length, 1);
      expect(fakeService.recordedEvents.first.type, 'goal');
      expect(notifier.state.pendingQueue, isEmpty);
      expect(notifier.state.isSyncing, isFalse);
    });

    test('Offline error retains action in pendingQueue and allows manual retry', () async {
      final fakeService = FakeLiveScorerService(
        matchData: fakeMatchData,
        shouldFailRecord: true, // Network down
      );
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      await notifier.recordAction(
        type: 'goal',
        teamId: 'team-b',
        payload: {'kind': 'penalty'},
      );

      // State is optimistically updated for user
      final footballState = notifier.state.scoringState as FootballState;
      expect(footballState.awayScore, 1);

      // Retained in queue due to simulated network failure
      expect(notifier.state.pendingQueue.length, 1);
      expect(notifier.state.hasPendingWrites, isTrue);
      expect(notifier.state.syncError, contains('Offline: event queued'));
      expect(fakeService.recordedEvents, isEmpty);

      // Restore network and retry queue
      fakeService.shouldFailRecord = false;
      await notifier.retryPendingQueue();

      expect(notifier.state.pendingQueue, isEmpty);
      expect(fakeService.recordedEvents.length, 1);
      expect(notifier.state.isSyncing, isFalse);
    });

    test('Undoing un-synced event removes it locally without server call', () async {
      final fakeService = FakeLiveScorerService(
        matchData: fakeMatchData,
        shouldFailRecord: true,
      );
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      await notifier.recordAction(
        type: 'goal',
        teamId: 'team-a',
      );
      expect(notifier.state.pendingQueue.length, 1);
      expect((notifier.state.scoringState as FootballState).homeScore, 1);

      // Undo local un-synced action
      await notifier.undo();

      expect(notifier.state.pendingQueue, isEmpty);
      expect(notifier.state.events, isEmpty);
      expect((notifier.state.scoringState as FootballState).homeScore, 0);
      expect(fakeService.undoneEventIds, isEmpty); // No server call needed!
    });

    test('Undoing synced event issues server undo RPC and restores previous state', () async {
      final fakeService = FakeLiveScorerService(matchData: fakeMatchData);
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      await notifier.recordAction(
        type: 'goal',
        teamId: 'team-a',
      );
      expect(fakeService.recordedEvents.length, 1);

      await notifier.undo();

      expect(fakeService.undoneEventIds.length, 1);
      expect(notifier.state.events, isEmpty);
      expect((notifier.state.scoringState as FootballState).homeScore, 0);
    });

    test('Unauthorized user is rejected from scoring or finishing', () async {
      final fakeService = FakeLiveScorerService(matchData: fakeMatchData);
      final notifier = LiveScorerNotifier(
        fakeService,
        'unauthorized-stranger',
        matchId: testMatchId,
      );
      await notifier.init();

      expect(notifier.state.isAuthorized, isFalse);

      await notifier.recordAction(type: 'goal', teamId: 'team-a');
      expect(notifier.state.syncError, contains('Not authorized'));
      expect(fakeService.recordedEvents, isEmpty);

      await notifier.finishMatch();
      expect(fakeService.finishMatchCalled, isFalse);
    });

    test('startMatch sets scheduled_at to current timestamp and transitions status to live', () async {
      final fakeService = FakeLiveScorerService(matchData: {
        ...fakeMatchData,
        'status': 'scheduled',
        'scheduled_at': '2026-10-10T10:00:00.000Z',
      });
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      final before = DateTime.now().subtract(const Duration(seconds: 2));
      await notifier.startMatch(config: {'half_length_mins': 45});
      final after = DateTime.now().add(const Duration(seconds: 2));

      expect(fakeService.startMatchCalled, isTrue);
      expect(fakeService.startedAt, isNotNull);
      expect(notifier.state.status, 'live');

      final updatedScheduledAt = DateTime.parse(notifier.state.matchData!['scheduled_at'] as String);
      expect(updatedScheduledAt.isAfter(before), isTrue);
      expect(updatedScheduledAt.isBefore(after), isTrue);
    });

    test('cricket startMatch sanitizes Batter 1 & 2 placeholders and embeds player_names', () async {
      final fakeCricketMatch = {
        ...fakeMatchData,
        'sports': {'name': 'Cricket'},
        'status': 'scheduled',
      };
      final fakeService = FakeLiveScorerService(matchData: fakeCricketMatch);
      final notifier = LiveScorerNotifier(
        fakeService,
        testUserId,
        matchId: testMatchId,
      );
      await notifier.init();

      await notifier.startMatch(
        config: {'overs_per_innings': 20},
        extra: {
          'striker_id': 'Batter 1',
          'non_striker_id': 'Batter 2',
          'opening_bowler_id': 'Bowler 1',
        },
      );

      expect(fakeService.startMatchCalled, isTrue);
      final initialScore = fakeService.passedInitialScore;
      expect(initialScore, isNotNull);
      expect(initialScore!['player_names'], isA<Map>());

      final innings = initialScore['innings'] as List;
      expect(innings, isNotEmpty);
      final firstInning = innings.first as Map;

      // Striker and nonStriker must be sanitized to real squad player IDs (not literal "Batter 1")
      expect(firstInning['striker_id'], isNot('Batter 1'));
      expect(firstInning['non_striker_id'], isNot('Batter 2'));
      expect(firstInning['current_bowler_id'], isNot('Bowler 1'));
    });
  });
}
