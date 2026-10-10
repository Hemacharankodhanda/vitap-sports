/// VIT-AP Sports — Immutable Match Event.
///
/// Core building block of the event-sourced scoring architecture.
library;

class MatchEvent {
  MatchEvent({
    required this.id,
    required this.matchId,
    required this.seq,
    required this.type,
    this.teamId,
    this.playerId,
    this.payload = const {},
    this.createdBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String matchId;
  final int seq;
  final String type;
  final String? teamId;
  final String? playerId;
  final Map<String, dynamic> payload;
  final String? createdBy;
  final DateTime createdAt;

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      seq: (json['seq'] as num).toInt(),
      type: json['type'] as String,
      teamId: json['team_id'] as String?,
      playerId: json['player_id'] as String?,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'match_id': matchId,
        'seq': seq,
        'type': type,
        'team_id': teamId,
        'player_id': playerId,
        'payload': payload,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  MatchEvent copyWith({
    String? id,
    String? matchId,
    int? seq,
    String? type,
    String? teamId,
    String? playerId,
    Map<String, dynamic>? payload,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return MatchEvent(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      seq: seq ?? this.seq,
      type: type ?? this.type,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      payload: payload ?? this.payload,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

