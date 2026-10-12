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
      if (p.side == 'home' && (p.teamId != null || p.userId != null)) {
        return p.teamId ?? p.userId;
      }
    }
    return null;
  }

  String? get awayTeamId {
    for (final p in participants) {
      if (p.side == 'away' && (p.teamId != null || p.userId != null)) {
        return p.teamId ?? p.userId;
      }
    }
    return null;
  }

  String? get resolvedHomeTeamName {
    if (homeTeamName != null && homeTeamName!.isNotEmpty) return homeTeamName;
    for (final p in participants) {
      if (p.side == 'home') {
        if (p.teamName != null && p.teamName!.isNotEmpty) return p.teamName;
        if (p.userName != null && p.userName!.isNotEmpty) return p.userName;
      }
    }
    return null;
  }

  String? get resolvedAwayTeamName {
    if (awayTeamName != null && awayTeamName!.isNotEmpty) return awayTeamName;
    for (final p in participants) {
      if (p.side == 'away') {
        if (p.teamName != null && p.teamName!.isNotEmpty) return p.teamName;
        if (p.userName != null && p.userName!.isNotEmpty) return p.userName;
      }
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

    // Cricket innings check
    final inningsRaw = (score?['innings'] ?? result?['innings']);
    if (inningsRaw is List && inningsRaw.length >= 2) {
      final inn1 = inningsRaw[0];
      final inn2 = inningsRaw[1];
      if (inn1 is Map && inn2 is Map) {
        final r1 = (inn1['total_runs'] as num?)?.toInt() ?? 0;
        final r2 = (inn2['total_runs'] as num?)?.toInt() ?? 0;
        if (r1 > r2) return inn1['batting_team_id']?.toString() ?? homeTeamId ?? 'home';
        if (r2 > r1) return inn2['batting_team_id']?.toString() ?? awayTeamId ?? 'away';
      }
    }

    // Direct score check
    if (status == 'completed' && homeScore != null && awayScore != null) {
      if (homeScore! > awayScore!) return homeTeamId ?? 'home';
      if (awayScore! > homeScore!) return awayTeamId ?? 'away';
    }

    // Badminton games check
    if (score != null) {
      final hGames = (score!['home_games_won'] as num?)?.toInt();
      final aGames = (score!['away_games_won'] as num?)?.toInt();
      if (hGames != null && aGames != null) {
        if (hGames > aGames) return homeTeamId ?? 'home';
        if (aGames > hGames) return awayTeamId ?? 'away';
      }
    }
    return null;
  }

  String? get winningTeamName {
    final explicit = result?['winner_team_name']?.toString() ??
        result?['winner_name']?.toString() ??
        score?['winner_team_name']?.toString() ??
        score?['winner_name']?.toString();
    if (explicit != null &&
        explicit.trim().isNotEmpty &&
        explicit.trim().toLowerCase() != 'winner') {
      return explicit.trim();
    }

    final hName = resolvedHomeTeamName ?? 'Team 1';
    final aName = resolvedAwayTeamName ?? 'Team 2';

    final wId = winnerTeamId;
    if (wId != null) {
      if (wId == 'home' || wId == homeTeamId) return hName;
      if (wId == 'away' || wId == awayTeamId) return aName;

      for (final p in participants) {
        if (p.teamId == wId || p.userId == wId) {
          if (p.teamName != null && p.teamName!.isNotEmpty) return p.teamName;
          if (p.userName != null && p.userName!.isNotEmpty) return p.userName;
          if (p.side == 'home') return hName;
          if (p.side == 'away') return aName;
        }
      }
    }

    // Check cricket innings
    final inningsRaw = (score?['innings'] ?? result?['innings']);
    if (inningsRaw is List && inningsRaw.length >= 2) {
      final inn1 = inningsRaw[0];
      final inn2 = inningsRaw[1];
      if (inn1 is Map && inn2 is Map) {
        final r1 = (inn1['total_runs'] as num?)?.toInt() ?? 0;
        final r2 = (inn2['total_runs'] as num?)?.toInt() ?? 0;
        if (r1 > r2) {
          final bId = inn1['batting_team_id']?.toString();
          if (bId == 'away' || bId == awayTeamId) return aName;
          return hName;
        } else if (r2 > r1) {
          final bId = inn2['batting_team_id']?.toString();
          if (bId == 'home' || bId == homeTeamId) return hName;
          return aName;
        }
      }
    }

    if (status == 'completed' && homeScore != null && awayScore != null) {
      if (homeScore! > awayScore!) return hName;
      if (awayScore! > homeScore!) return aName;
    }

    if (resultMargin != null) {
      final m = resultMargin!.toLowerCase();
      if (hName.isNotEmpty && m.contains(hName.toLowerCase())) return hName;
      if (aName.isNotEmpty && m.contains(aName.toLowerCase())) return aName;
    }

    return hName;
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

    String? homeName;
    String? awayName;
    if (participantsData != null) {
      for (final p in participantsData) {
        if (p is Map) {
          final side = p['side'] as String?;
          final team = p['teams'] as Map?;
          final user = p['users'] as Map?;
          final name = team?['name']?.toString() ?? user?['name']?.toString();
          if (side == 'home' && name != null && name.isNotEmpty && homeName == null) {
            homeName = name;
          } else if (side == 'away' && name != null && name.isNotEmpty && awayName == null) {
            awayName = name;
          }
        }
      }
    }

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
      homeTeamName: homeName,
      awayTeamName: awayName,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      config: configData,
      score: scoreData,
      result: resultData,
    );
  }

  MatchModel copyWith({
    String? id,
    String? sportId,
    String? sportName,
    String? venue,
    DateTime? scheduledAt,
    String? status,
    String? format,
    String? createdBy,
    String? scorerId,
    String? description,
    DateTime? createdAt,
    List<MatchParticipant>? participants,
    String? homeTeamName,
    String? awayTeamName,
    int? homeScore,
    int? awayScore,
    Map<String, dynamic>? config,
    Map<String, dynamic>? score,
    Map<String, dynamic>? result,
  }) {
    return MatchModel(
      id: id ?? this.id,
      sportId: sportId ?? this.sportId,
      sportName: sportName ?? this.sportName,
      venue: venue ?? this.venue,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      format: format ?? this.format,
      createdBy: createdBy ?? this.createdBy,
      scorerId: scorerId ?? this.scorerId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      config: config ?? this.config,
      score: score ?? this.score,
      result: result ?? this.result,
    );
  }

  /// Merges a raw Supabase Realtime matches row into this model
  MatchModel updateFromRealtime(Map<String, dynamic>? raw) {
    if (raw == null) return this;
    final newScore = raw['score'] is Map
        ? Map<String, dynamic>.from(raw['score'] as Map)
        : score;
    final newResult = raw['result'] is Map
        ? Map<String, dynamic>.from(raw['result'] as Map)
        : result;
    final newConfig = raw['config'] is Map
        ? Map<String, dynamic>.from(raw['config'] as Map)
        : config;
    final newScheduledAt = raw['scheduled_at'] != null
        ? DateTime.tryParse(raw['scheduled_at'].toString()) ?? scheduledAt
        : scheduledAt;

    return copyWith(
      scheduledAt: newScheduledAt,
      status: raw['status'] as String? ?? status,
      homeScore: raw['home_score'] is num
          ? (raw['home_score'] as num).toInt()
          : homeScore,
      awayScore: raw['away_score'] is num
          ? (raw['away_score'] as num).toInt()
          : awayScore,
      score: newScore,
      result: newResult,
      config: newConfig,
    );
  }

  /// Returns a concise single-line live score string based on sport and scoring engine snapshot
  String? get liveScoreSummary {
    final sportLower = (sportName ?? '').toLowerCase();

    // 1. Cricket: Extract runs/wickets (overs ov)
    if (sportLower == 'cricket' && score != null) {
      final inningsRaw = score!['innings'];
      if (inningsRaw is List && inningsRaw.isNotEmpty) {
        final parts = <String>[];
        for (final inn in inningsRaw) {
          if (inn is Map) {
            final runs = inn['total_runs'] ?? 0;
            final wickets = inn['total_wickets'] ?? 0;
            final legalBalls = (inn['legal_balls'] as num?)?.toInt() ?? 0;
            final overs = '${legalBalls ~/ 6}.${legalBalls % 6}';
            final bId = inn['batting_team_id']?.toString();
            String? teamPrefix;
            if (bId != null) {
              if (bId == 'home' || bId == homeTeamId) {
                teamPrefix = resolvedHomeTeamName;
              } else if (bId == 'away' || bId == awayTeamId) {
                teamPrefix = resolvedAwayTeamName;
              }
            }
            if (teamPrefix != null && teamPrefix.isNotEmpty) {
              parts.add('$teamPrefix: $runs/$wickets ($overs ov)');
            } else {
              parts.add('$runs/$wickets ($overs ov)');
            }
          }
        }
        if (parts.isNotEmpty) {
          return parts.join('  •  ');
        }
      }
    }

    // 2. Badminton: games won or current game score
    if (sportLower == 'badminton' && score != null) {
      final hGames = (score!['home_games_won'] as num?)?.toInt();
      final aGames = (score!['away_games_won'] as num?)?.toInt();
      final gamesRaw = score!['games'];
      if (gamesRaw is List && gamesRaw.isNotEmpty) {
        final curIdx = (score!['current_game_index'] as num?)?.toInt() ?? (gamesRaw.length - 1);
        if (curIdx >= 0 && curIdx < gamesRaw.length && gamesRaw[curIdx] is Map) {
          final cur = gamesRaw[curIdx] as Map;
          final hp = (cur['home_points'] as num?)?.toInt() ?? 0;
          final ap = (cur['away_points'] as num?)?.toInt() ?? 0;
          if (hGames != null && aGames != null) {
            return '$hGames - $aGames  ($hp - $ap)';
          }
          return '$hp - $ap (Game ${curIdx + 1})';
        }
      }
      if (hGames != null && aGames != null) {
        return '$hGames - $aGames';
      }
    }

    // 3. Football & general: check snapshot or direct columns
    final hScore = (score?['home_score'] as num?)?.toInt() ?? homeScore;
    final aScore = (score?['away_score'] as num?)?.toInt() ?? awayScore;
    if (hScore != null && aScore != null) {
      return '$hScore - $aScore';
    }

    return null;
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
