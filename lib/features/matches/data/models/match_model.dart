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

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final sport = json['sports'] as Map<String, dynamic>?;
    final participantsData = json['match_participants'] as List<dynamic>?;

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
      config: json['config'] as Map<String, dynamic>?,
      score: json['score'] as Map<String, dynamic>?,
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
}
