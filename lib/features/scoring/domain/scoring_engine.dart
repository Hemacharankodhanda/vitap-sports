/// VIT-AP Sports — Pure Dart Scoring Engine Interface.
///
/// Single source of truth for match rules and immutable event folding.
library;

import 'match_event.dart';

class ScoringAction {
  const ScoringAction({
    required this.id,
    required this.label,
    this.subLabel,
    this.type = 'action',
    this.teamId,
    this.playerId,
    this.payload = const {},
    this.isPrimary = false,
    this.isDestructive = false,
    this.isUndo = false,
  });

  final String id;
  final String label;
  final String? subLabel;
  final String type; // maps to MatchEvent.type
  final String? teamId;
  final String? playerId;
  final Map<String, dynamic> payload;
  final bool isPrimary;
  final bool isDestructive;
  final bool isUndo;

  MatchEvent toEvent({
    required String eventId,
    required String matchId,
    required int seq,
    String? createdBy,
  }) {
    return MatchEvent(
      id: eventId,
      matchId: matchId,
      seq: seq,
      type: type,
      teamId: teamId,
      playerId: playerId,
      payload: payload,
      createdBy: createdBy,
    );
  }
}

abstract class ScoringEngine<TState, TConfig> {
  String get sport;

  TState initialState(
    TConfig config, {
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  });

  TState apply(TState state, MatchEvent event);

  String? validate(TState state, MatchEvent event);

  List<ScoringAction> availableActions(TState state);

  bool isComplete(TState state);

  Map<String, dynamic> result(TState state);

  Map<String, dynamic> toSnapshot(TState state);

  TState fromSnapshot(Map<String, dynamic> json, TConfig config);

  /// Folds a list of immutable match events sequentially starting from initial state.
  TState fold(
    TConfig config,
    List<MatchEvent> events, {
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final sorted = List<MatchEvent>.from(events)
      ..sort((a, b) => a.seq.compareTo(b.seq));

    TState current = initialState(
      config,
      homeId: homeId,
      awayId: awayId,
      extra: extra,
    );

    for (final event in sorted) {
      current = apply(current, event);
    }
    return current;
  }
}
