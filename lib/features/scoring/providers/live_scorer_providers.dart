/// VIT-AP Sports — Live Scorer Providers.
///
/// Riverpod state management for realtime event-sourced scoring,
/// optimistic updates, and viewer feeds.
library;

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/live_scorer_service.dart';
import '../domain/match_event.dart';
import '../domain/player_option.dart';
import '../domain/scoring_engine.dart';
import '../domain/sport_registry.dart';

/// Provider for LiveScorerService
final liveScorerServiceProvider = Provider<LiveScorerService>((ref) {
  return LiveScorerService(ref.watch(supabaseClientProvider));
});

/// Stream of raw match row from Supabase Realtime
final liveMatchStreamProvider =
    StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, matchId) {
  final service = ref.watch(liveScorerServiceProvider);
  return service.streamMatch(matchId);
});

/// Timeline events notifier that subscribes to Realtime first,
/// then loads initial events, tracks inserts and deletes, and cleans up.
class LiveEventsNotifier extends StateNotifier<AsyncValue<List<MatchEvent>>> {
  LiveEventsNotifier(this._service, this._matchId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  final LiveScorerService _service;
  final String _matchId;
  RealtimeChannel? _channel;
  final List<MatchEvent> _bufferedInserts = [];
  final Set<String> _deletedIds = {};
  bool _initialLoadDone = false;

  void _init() {
    // 1. Subscribe first to ensure no dropped events during network latency
    _channel = _service.subscribeToEvents(
      matchId: _matchId,
      onInsert: (event) {
        if (!_initialLoadDone) {
          _bufferedInserts.add(event);
        } else {
          _handleInsert(event);
        }
      },
      onDelete: (eventId) {
        if (!_initialLoadDone) {
          _deletedIds.add(eventId);
        } else {
          _handleDelete(eventId);
        }
      },
    );

    // 2. Fetch initial events
    _fetchInitial();
  }

  Future<void> _fetchInitial() async {
    try {
      final initial = await _service.fetchEvents(_matchId);
      final map = <String, MatchEvent>{};
      for (final e in initial) {
        if (!_deletedIds.contains(e.id)) {
          map[e.id] = e;
        }
      }
      for (final e in _bufferedInserts) {
        if (!_deletedIds.contains(e.id)) {
          map[e.id] = e;
        }
      }
      _bufferedInserts.clear();
      _deletedIds.clear();
      _initialLoadDone = true;

      final sorted = map.values.toList()..sort((a, b) => a.seq.compareTo(b.seq));
      state = AsyncValue.data(sorted);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _handleInsert(MatchEvent event) {
    state.whenData((currentList) {
      if (currentList.any((e) => e.id == event.id)) return;
      final updated = [...currentList, event]..sort((a, b) => a.seq.compareTo(b.seq));
      state = AsyncValue.data(updated);
    });
  }

  void _handleDelete(String eventId) {
    state.whenData((currentList) {
      final updated = currentList.where((e) => e.id != eventId).toList();
      state = AsyncValue.data(updated);
    });
  }

  Future<void> refresh() async {
    _initialLoadDone = false;
    await _fetchInitial();
  }

  @override
  void dispose() {
    if (_channel != null) {
      _service.unsubscribe(_channel!);
    }
    super.dispose();
  }
}

final liveEventsNotifierProvider = StateNotifierProvider.autoDispose
    .family<LiveEventsNotifier, AsyncValue<List<MatchEvent>>, String>((ref, matchId) {
  final service = ref.watch(liveScorerServiceProvider);
  return LiveEventsNotifier(service, matchId);
});

/// State of the active scorer screen session
class ScorerState {
  const ScorerState({
    required this.matchId,
    required this.sport,
    this.homeId = 'home',
    this.awayId = 'away',
    this.homeName = 'Home',
    this.awayName = 'Away',
    this.matchData,
    this.config = const {},
    this.scoringState,
    this.events = const [],
    this.pendingQueue = const [],
    this.isSyncing = false,
    this.isLoading = true,
    this.isAuthorized = false,
    this.currentScorerId,
    this.status = 'scheduled',
    this.syncError,
    this.participants = const [],
    this.homePlayers = const [],
    this.awayPlayers = const [],
  });

  final String matchId;
  final String sport;
  final String homeId;
  final String awayId;
  final String homeName;
  final String awayName;
  final Map<String, dynamic>? matchData;
  final Map<String, dynamic> config;
  final dynamic scoringState;
  final List<MatchEvent> events;
  final List<MatchEvent> pendingQueue;
  final bool isSyncing;
  final bool isLoading;
  final bool isAuthorized;
  final String? currentScorerId;
  final String status;
  final String? syncError;
  final List<Map<String, dynamic>> participants;
  final List<PlayerOption> homePlayers;
  final List<PlayerOption> awayPlayers;

  bool get isMatchLive => status == 'live';
  bool get isCompleted => status == 'completed' || status == 'abandoned';
  bool get hasPendingWrites => pendingQueue.isNotEmpty;

  List<PlayerOption> playersForTeam(String teamId) {
    if (teamId == homeId) return homePlayers;
    if (teamId == awayId) return awayPlayers;
    return [...homePlayers, ...awayPlayers];
  }

  List<ScoringAction> get availableActions {
    if (scoringState == null || sport.isEmpty) return const [];
    final engine = SportRegistry.getEngine(sport);
    return engine?.availableActions(scoringState) ?? const [];
  }

  ScorerState copyWith({
    String? matchId,
    String? sport,
    String? homeId,
    String? awayId,
    String? homeName,
    String? awayName,
    Map<String, dynamic>? matchData,
    Map<String, dynamic>? config,
    dynamic scoringState,
    List<MatchEvent>? events,
    List<MatchEvent>? pendingQueue,
    bool? isSyncing,
    bool? isLoading,
    bool? isAuthorized,
    String? currentScorerId,
    String? status,
    String? syncError,
    bool clearSyncError = false,
    List<Map<String, dynamic>>? participants,
    List<PlayerOption>? homePlayers,
    List<PlayerOption>? awayPlayers,
  }) {
    return ScorerState(
      matchId: matchId ?? this.matchId,
      sport: sport ?? this.sport,
      homeId: homeId ?? this.homeId,
      awayId: awayId ?? this.awayId,
      homeName: homeName ?? this.homeName,
      awayName: awayName ?? this.awayName,
      matchData: matchData ?? this.matchData,
      config: config ?? this.config,
      scoringState: scoringState ?? this.scoringState,
      events: events ?? this.events,
      pendingQueue: pendingQueue ?? this.pendingQueue,
      isSyncing: isSyncing ?? this.isSyncing,
      isLoading: isLoading ?? this.isLoading,
      isAuthorized: isAuthorized ?? this.isAuthorized,
      currentScorerId: currentScorerId ?? this.currentScorerId,
      status: status ?? this.status,
      syncError: clearSyncError ? null : (syncError ?? this.syncError),
      participants: participants ?? this.participants,
      homePlayers: homePlayers ?? this.homePlayers,
      awayPlayers: awayPlayers ?? this.awayPlayers,
    );
  }
}

/// Notifier driving the Scorer Screen shell, actions, undo, and offline queue.
class LiveScorerNotifier extends StateNotifier<ScorerState> {
  LiveScorerNotifier(
    this._service,
    this._currentUserId, {
    required String matchId,
  }) : super(ScorerState(matchId: matchId, sport: '')) {
    init();
  }

  final LiveScorerService _service;
  final String? _currentUserId;
  static const _uuid = Uuid();
  bool _isFlushing = false;

  (String homeId, String awayId, String homeName, String awayName) _extractSides(
      List<Map<String, dynamic>> participants) {
    String homeId = 'home';
    String awayId = 'away';
    String homeName = 'Home';
    String awayName = 'Away';

    for (final p in participants) {
      final side = p['side'] as String?;
      final team = p['teams'] as Map<String, dynamic>?;
      final user = p['users'] as Map<String, dynamic>?;
      final id = (p['team_id'] as String?) ?? (p['user_id'] as String?);
      final name = (team?['name'] as String?) ?? (user?['name'] as String?);

      if (side == 'home') {
        if (id != null) homeId = id;
        if (name != null) homeName = name;
      } else if (side == 'away') {
        if (id != null) awayId = id;
        if (name != null) awayName = name;
      }
    }
    return (homeId, awayId, homeName, awayName);
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, clearSyncError: true);
    try {
      final match = await _service.fetchMatch(state.matchId);
      if (match == null) {
        state = state.copyWith(
          isLoading: false,
          syncError: 'Match not found',
        );
        return;
      }

      final sportRecord = match['sports'] as Map<String, dynamic>?;
      final sportName = (sportRecord?['name'] as String? ?? 'cricket').toLowerCase();
      final config = (match['config'] as Map<String, dynamic>?) ?? {};
      final rawEvents = await _service.fetchEvents(state.matchId);

      // Extract participants and side identities
      final rawParticipants = (match['match_participants'] as List<dynamic>?)
              ?.map((p) => p as Map<String, dynamic>)
              .toList() ??
          [];
      final (homeId, awayId, homeName, awayName) = _extractSides(rawParticipants);

      // Check authorization
      final createdBy = match['created_by'] as String?;
      final scorerId = match['scorer_id'] as String?;
      final scorerIds = (match['scorer_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      bool isAuthorized = false;
      if (_currentUserId != null) {
        if (_currentUserId == createdBy ||
            _currentUserId == scorerId ||
            scorerIds.contains(_currentUserId)) {
          isAuthorized = true;
        } else if (scorerId == null && (match['status'] == 'scheduled' || match['status'] == 'upcoming')) {
          // Allow setup and start for scheduled/upcoming unassigned matches
          isAuthorized = true;
        } else {
          // Check if captain of participating team or individual participant
          for (final p in rawParticipants) {
            final team = p['teams'] as Map<String, dynamic>?;
            final userId = p['user_id'] as String?;
            if ((team != null && team['captain_id'] == _currentUserId) ||
                userId == _currentUserId) {
              isAuthorized = true;
              break;
            }
          }
        }
      }

      // Fetch team players from database (graceful fallback if offline or mock)
      List<Map<String, dynamic>> homeTeamRaw = const [];
      List<Map<String, dynamic>> awayTeamRaw = const [];
      try {
        if (homeId.isNotEmpty) {
          homeTeamRaw = await _service.fetchTeamPlayers(homeId);
        }
        if (awayId.isNotEmpty) {
          awayTeamRaw = await _service.fetchTeamPlayers(awayId);
        }
      } catch (_) {
        // Fallback gracefully
      }

      final homePlayerList = <PlayerOption>[];
      final awayPlayerList = <PlayerOption>[];

      // 1. From match_participants (squad assigned to match)
      for (final p in rawParticipants) {
        final userId = p['user_id'] as String?;
        final user = p['users'] as Map<String, dynamic>?;
        final side = p['side'] as String?;
        final teamId = p['team_id'] as String?;
        if (userId != null) {
          final opt = PlayerOption(
            id: userId,
            name: user?['name'] as String? ?? 'Player',
            teamId: teamId ?? (side == 'home' ? homeId : awayId),
            avatarUrl: user?['avatar_url'] as String?,
          );
          if (side == 'home' || teamId == homeId) {
            if (!homePlayerList.any((x) => x.id == opt.id)) homePlayerList.add(opt);
          } else if (side == 'away' || teamId == awayId) {
            if (!awayPlayerList.any((x) => x.id == opt.id)) awayPlayerList.add(opt);
          }
        }
      }

      // 2. From team_members
      for (final m in homeTeamRaw) {
        final user = m['users'] as Map<String, dynamic>?;
        final userId = m['user_id'] as String? ?? user?['id'] as String?;
        if (userId != null) {
          final opt = PlayerOption(
            id: userId,
            name: user?['name'] as String? ?? 'Player',
            teamId: homeId,
            role: m['role'] as String?,
            avatarUrl: user?['avatar_url'] as String?,
          );
          if (!homePlayerList.any((x) => x.id == opt.id)) homePlayerList.add(opt);
        }
      }

      for (final m in awayTeamRaw) {
        final user = m['users'] as Map<String, dynamic>?;
        final userId = m['user_id'] as String? ?? user?['id'] as String?;
        if (userId != null) {
          final opt = PlayerOption(
            id: userId,
            name: user?['name'] as String? ?? 'Player',
            teamId: awayId,
            role: m['role'] as String?,
            avatarUrl: user?['avatar_url'] as String?,
          );
          if (!awayPlayerList.any((x) => x.id == opt.id)) awayPlayerList.add(opt);
        }
      }

      // 3. Fallback defaults if teams have no players in DB yet
      if (homePlayerList.isEmpty) {
        for (int i = 1; i <= 11; i++) {
          homePlayerList.add(PlayerOption(
            id: 'home_p_$i',
            name: '$homeName Player $i',
            teamId: homeId,
          ));
        }
      }
      if (awayPlayerList.isEmpty) {
        for (int i = 1; i <= 11; i++) {
          awayPlayerList.add(PlayerOption(
            id: 'away_p_$i',
            name: '$awayName Player $i',
            teamId: awayId,
          ));
        }
      }

      final derivedState = SportRegistry.fold(
        sportName: sportName,
        configJson: config,
        events: rawEvents,
        homeId: homeId,
        awayId: awayId,
      );

      state = state.copyWith(
        sport: sportName,
        homeId: homeId,
        awayId: awayId,
        homeName: homeName,
        awayName: awayName,
        matchData: match,
        config: config,
        status: match['status'] as String? ?? 'scheduled',
        currentScorerId: scorerId,
        isAuthorized: isAuthorized,
        events: rawEvents,
        scoringState: derivedState,
        participants: rawParticipants,
        homePlayers: homePlayerList,
        awayPlayers: awayPlayerList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        syncError: 'Failed to load match: $e',
      );
    }
  }

  /// Optimistically applies an action and adds it to the persistent sync queue.
  Future<void> recordAction({
    required String type,
    String? teamId,
    String? playerId,
    Map<String, dynamic> payload = const {},
  }) async {
    if (!state.isAuthorized) {
      state = state.copyWith(syncError: 'Not authorized to score this match');
      return;
    }

    final engine = SportRegistry.getEngine(state.sport);
    if (engine == null) {
      state = state.copyWith(syncError: 'Unsupported sport: ${state.sport}');
      return;
    }

    final nextSeq = state.events.isEmpty
        ? 1
        : state.events.map((e) => e.seq).reduce(max) + 1;

    final event = MatchEvent(
      id: _uuid.v4(),
      matchId: state.matchId,
      seq: nextSeq,
      type: type,
      teamId: teamId,
      playerId: playerId,
      payload: payload,
      createdBy: _currentUserId,
    );

    // Validate against pure engine rules
    final validationError = engine.validate(state.scoringState, event);
    if (validationError != null) {
      state = state.copyWith(syncError: validationError);
      return;
    }

    // Pure local apply
    final newScoringState = engine.apply(state.scoringState, event);
    final updatedEvents = [...state.events, event];
    final updatedQueue = [...state.pendingQueue, event];

    // Optimistically update UI immediately
    state = state.copyWith(
      events: updatedEvents,
      scoringState: newScoringState,
      pendingQueue: updatedQueue,
      isSyncing: true,
      clearSyncError: true,
    );

    // Flush sync queue in background
    _flushQueue();
  }

  /// Flushes pending queue sequentially with idempotency.
  Future<void> _flushQueue() async {
    if (_isFlushing) return;
    _isFlushing = true;

    try {
      while (state.pendingQueue.isNotEmpty) {
        final currentEvent = state.pendingQueue.first;
        final snapshot = (state.scoringState as dynamic).toJson() as Map<String, dynamic>;

        try {
          await _service.recordEvent(
            matchId: state.matchId,
            event: currentEvent,
            snapshot: snapshot,
          );

          // Success: pop from pending queue
          final nextQueue = state.pendingQueue.sublist(1);
          state = state.copyWith(
            pendingQueue: nextQueue,
            isSyncing: nextQueue.isNotEmpty,
          );
        } catch (e) {
          // Failed to sync (e.g. offline) - stop flush and retain queue
          state = state.copyWith(
            isSyncing: false,
            syncError: 'Offline: event queued for sync ($e)',
          );
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Manually trigger queue flush (e.g., when connection restores).
  Future<void> retryPendingQueue() async {
    state = state.copyWith(isSyncing: true, clearSyncError: true);
    await _flushQueue();
  }

  /// Reverses the most recent action.
  Future<void> undo() async {
    if (state.events.isEmpty) return;
    if (!state.isAuthorized) {
      state = state.copyWith(syncError: 'Not authorized to score this match');
      return;
    }

    // If there is an unsynced event in the queue, remove it locally
    if (state.pendingQueue.isNotEmpty) {
      final lastPending = state.pendingQueue.last;
      final updatedQueue = state.pendingQueue.sublist(0, state.pendingQueue.length - 1);
      final updatedEvents = state.events.where((e) => e.id != lastPending.id).toList();
      final recalculatedState = SportRegistry.fold(
        sportName: state.sport,
        configJson: state.config,
        events: updatedEvents,
        homeId: state.homeId,
        awayId: state.awayId,
      );

      state = state.copyWith(
        events: updatedEvents,
        scoringState: recalculatedState,
        pendingQueue: updatedQueue,
        isSyncing: updatedQueue.isNotEmpty,
      );
      return;
    }

    // All events are on server: undo server event
    final lastEvent = state.events.last;
    final remainingEvents = state.events.sublist(0, state.events.length - 1);
    final previousState = SportRegistry.fold(
      sportName: state.sport,
      configJson: state.config,
      events: remainingEvents,
      homeId: state.homeId,
      awayId: state.awayId,
    );
    final previousSnapshot = (previousState as dynamic).toJson() as Map<String, dynamic>;

    // Optimistic rollback
    state = state.copyWith(
      events: remainingEvents,
      scoringState: previousState,
      isSyncing: true,
      clearSyncError: true,
    );

    try {
      await _service.undoEvent(
        matchId: state.matchId,
        eventId: lastEvent.id,
        snapshot: previousSnapshot,
      );
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      // Re-fetch accurate state if server undo failed
      await init();
      state = state.copyWith(
        syncError: 'Undo failed: $e',
      );
    }
  }

  /// Starts the match with sport-specific configuration and lineup setup.
  Future<void> startMatch({
    required Map<String, dynamic> config,
    Map<String, dynamic>? extra,
  }) async {
    if (!state.isAuthorized) {
      state = state.copyWith(syncError: 'Not authorized to start this match');
      return;
    }

    final initialSnapshot = SportRegistry.initialState(
      sportName: state.sport,
      configJson: config,
      homeId: state.homeId,
      awayId: state.awayId,
      extra: extra,
    );

    if (initialSnapshot == null) {
      state = state.copyWith(syncError: 'Could not initialize state for ${state.sport}');
      return;
    }

    state = state.copyWith(isSyncing: true, clearSyncError: true);
    try {
      await _service.startMatch(
        matchId: state.matchId,
        config: config,
        initialScore: (initialSnapshot as dynamic).toJson() as Map<String, dynamic>,
      );
      state = state.copyWith(
        status: 'live',
        config: config,
        scoringState: initialSnapshot,
        currentScorerId: _currentUserId,
        isAuthorized: true,
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to start match: $e',
      );
    }
  }

  /// Takes over scoring role for current user.
  Future<void> takeOverScoring() async {
    state = state.copyWith(isSyncing: true, clearSyncError: true);
    try {
      await _service.takeOverScoring(state.matchId);
      state = state.copyWith(
        currentScorerId: _currentUserId,
        isAuthorized: true,
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Take over failed: $e',
      );
    }
  }

  /// Finalizes and completes the match atomically.
  Future<void> finishMatch() async {
    if (!state.isAuthorized) {
      state = state.copyWith(syncError: 'Not authorized to finish this match');
      return;
    }

    // Flush any pending queue first
    if (state.pendingQueue.isNotEmpty) {
      await _flushQueue();
      if (state.pendingQueue.isNotEmpty) {
        state = state.copyWith(
          syncError: 'Cannot finish match while offline events are pending sync',
        );
        return;
      }
    }

    final engine = SportRegistry.getEngine(state.sport);
    if (engine == null) {
      state = state.copyWith(syncError: 'Engine not found for sport: ${state.sport}');
      return;
    }

    final result = engine.result(state.scoringState);
    final finalScore = (state.scoringState as dynamic).toJson() as Map<String, dynamic>;

    state = state.copyWith(isSyncing: true, clearSyncError: true);
    try {
      await _service.finishMatch(
        matchId: state.matchId,
        result: result,
        finalScore: finalScore,
      );
      state = state.copyWith(
        status: 'completed',
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: 'Failed to finish match: $e',
      );
    }
  }
}

final liveScorerNotifierProvider = StateNotifierProvider.autoDispose
    .family<LiveScorerNotifier, ScorerState, String>((ref, matchId) {
  final service = ref.watch(liveScorerServiceProvider);
  final authUser = ref.watch(currentUserProvider);
  return LiveScorerNotifier(
    service,
    authUser?.id,
    matchId: matchId,
  );
});
