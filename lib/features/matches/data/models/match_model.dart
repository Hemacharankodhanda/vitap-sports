/// VIT-AP Sports — Match model.
library;

class MatchModel {
  const MatchModel({
    required this.id,
    required this.sportId,
    this.sportName,
    required this.venue,
    required this.scheduledAt,
    required this.status,
    this.format,
    required this.createdBy,
    this.scorerId,
    this.description,
    this.createdAt,
    this.participants = const [],
    this.homeTeamName,
    this.awayTeamName,
    this.homeScore,
    this.awayScore,
    this.config,
    this.score,
    this.result,
  });

  final String id;
  final String sportId;
  final String? sportName;
  final String venue;
  final DateTime scheduledAt;
  final String status; // upcoming, live, completed, cancelled
  final String? format;
  final String createdBy;
  final String? scorerId;
  final String? description;
  final DateTime? createdAt;
  final List<MatchParticipant> participants;
  final String? homeTeamName;
  final String? awayTeamName;
  final int? homeScore;
  final int? awayScore;
  final Map<String, dynamic>? config;
  final Map<String, dynamic>? score;
  final Map<String, dynamic>? result;

  String? get homeTeamId {
    for (final p in participants) {
      if (p.side == 'home' && p.teamId != null) return p.teamId;
    }
    return null;
  }

  String? get awayTeamId {
    for (final p in participants) {
      if (p.side == 'away' && p.teamId != null) return p.teamId;
    }
    return null;
  }

  String? get winnerTeamId {
    final wId = result?['winner_team_id'] ??
        result?['winner_id'] ??
        score?['winner_team_id'] ??
        score?['winner_id'];
    if (wId != null && wId.toString().isNotEmpty) {
      return wId.toString();
    }
    if (status == 'completed' && homeScore != null && awayScore != null) {
      if (homeScore! > awayScore!) return homeTeamId ?? 'home';
      if (awayScore! > homeScore!) return awayTeamId ?? 'away';
    }
    return null;
  }

  String? get resultMargin {
    final margin = result?['result_margin'] ??
        score?['result_margin'] ??
        score?['games_summary'];
    if (margin != null && margin.toString().isNotEmpty) {
      return margin.toString();
    }
    return null;
  }

  bool get isDraw {
    if (result?['is_draw'] == true ||
        result?['is_tie'] == true ||
        score?['is_draw'] == true ||
        score?['is_tie'] == true) {
      return true;
    }
    if (status == 'completed' &&
        homeScore != null &&
        awayScore != null &&
        homeScore == awayScore) {
      return true;
    }
    return false;
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final sport = json['sports'] as Map<String, dynamic>?;
    final participantsData = json['match_participants'] as List<dynamic>?;
    final resultData = json['result'] is Map
        ? Map<String, dynamic>.from(json['result'] as Map)
        : null;
    final scoreData = json['score'] is Map
        ? Map<String, dynamic>.from(json['score'] as Map)
        : null;
    final configData = json['config'] is Map
        ? Map<String, dynamic>.from(json['config'] as Map)
        : null;

    return MatchModel(
      id: json['id'] as String,
      sportId: json['sport_id'] as String,
      sportName: sport?['name'] as String?,
      venue: json['venue'] as String? ?? 'TBD',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      status: json['status'] as String? ?? 'upcoming',
      format: json['format'] as String?,
      createdBy: json['created_by'] as String,
      scorerId: json['scorer_id'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      participants: participantsData
              ?.map((e) => MatchParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      config: configData,
      score: scoreData,
      result: resultData,
    );
  }

  Map<String, dynamic> toJson() => {
        'sport_id': sportId,
        'venue': venue,
        'scheduled_at': scheduledAt.toIso8601String(),
        'status': status,
        'format': format,
        'created_by': createdBy,
        'scorer_id': scorerId,
        'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status &&
          homeScore == other.homeScore &&
          awayScore == other.awayScore &&
          winnerTeamId == other.winnerTeamId;

  @override
  int get hashCode => Object.hash(id, status, homeScore, awayScore, winnerTeamId);
}

class MatchParticipant {
  const MatchParticipant({
    required this.matchId,
    this.teamId,
    this.userId,
    required this.side,
    this.rsvpStatus,
    this.teamName,
    this.userName,
    this.userAvatar,
  });

  final String matchId;
  final String? teamId;
  final String? userId;
  final String side; // home, away, individual
  final String? rsvpStatus; // confirmed, declined, pending
  final String? teamName;
  final String? userName;
  final String? userAvatar;

  factory MatchParticipant.fromJson(Map<String, dynamic> json) {
    final team = json['teams'] as Map<String, dynamic>?;
    final user = json['users'] as Map<String, dynamic>?;
    return MatchParticipant(
      matchId: json['match_id'] as String,
      teamId: json['team_id'] as String?,
      userId: json['user_id'] as String?,
      side: json['side'] as String? ?? 'home',
      rsvpStatus: json['rsvp_status'] as String?,
      teamName: team?['name'] as String?,
      userName: user?['name'] as String?,
      userAvatar: user?['avatar_url'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchParticipant &&
          runtimeType == other.runtimeType &&
          matchId == other.matchId &&
          teamId == other.teamId &&
          userId == other.userId &&
          side == other.side;

  @override
  int get hashCode => Object.hash(matchId, teamId, userId, side);
}
