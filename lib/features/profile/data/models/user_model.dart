import 'dart:convert';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    this.branch,
    this.year,
    this.hostelBlock,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.sports = const [],
    this.matchesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.mvpCount = 0,
    this.careerStatsRaw,
  });

  final String id;
  final String name;
  final String? branch;
  final String? year;
  final String? hostelBlock;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<UserSport> sports;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int mvpCount;
  final List<Map<String, dynamic>>? careerStatsRaw;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final sportsData = json['user_sports'] as List<dynamic>?;
    
    int totalMatches = (json['matches_played'] as num?)?.toInt() ?? 0;
    int totalWins = (json['wins'] as num?)?.toInt() ?? 0;
    int totalLosses = (json['losses'] as num?)?.toInt() ?? 0;
    int totalMvps = (json['mvp_count'] as num?)?.toInt() ?? 0;
    
    final careerStats = json['career_stats'] as List<dynamic>?;
    if (careerStats != null && careerStats.isNotEmpty) {
      int derivedMatches = 0;
      int derivedWins = 0;
      int derivedLosses = 0;
      int derivedMvps = 0;
      for (final row in careerStats) {
        if (row is Map) {
          final rowMatches = (row['matches_played'] as num?)?.toInt() ?? 0;
          var counters = row['career_counters'];
          if (counters is String) {
            try {
              counters = jsonDecode(counters);
            } catch (_) {}
          }
          final countersMap = (counters as Map<String, dynamic>?) ?? {};
          final w = (countersMap['matches_won'] as num?)?.toInt() ??
              (countersMap['wins'] as num?)?.toInt() ??
              (countersMap['won'] as num?)?.toInt() ??
              (row['wins'] as num?)?.toInt() ??
              (row['matches_won'] as num?)?.toInt() ??
              0;
          final l = (countersMap['matches_lost'] as num?)?.toInt() ??
              (countersMap['losses'] as num?)?.toInt() ??
              (countersMap['lost'] as num?)?.toInt() ??
              (row['losses'] as num?)?.toInt() ??
              (row['matches_lost'] as num?)?.toInt() ??
              0;
          final mvp = (countersMap['mvps'] as num?)?.toInt() ??
              (countersMap['mvp_count'] as num?)?.toInt() ??
              (row['mvp_count'] as num?)?.toInt() ??
              0;

          final effMatches = rowMatches < (w + l) ? (w + l) : rowMatches;
          derivedMatches += effMatches;
          derivedWins += w;
          derivedLosses += l;
          derivedMvps += mvp;
        }
      }
      if (derivedMatches > 0) {
        totalMatches = derivedMatches;
        totalWins = derivedWins;
        totalLosses = derivedLosses;
        if (derivedMvps > 0) totalMvps = derivedMvps;
      }
    }

    // Mathematical guarantee: matches played can never be less than wins + losses
    if (totalMatches < (totalWins + totalLosses)) {
      totalMatches = totalWins + totalLosses;
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      branch: json['branch'] as String?,
      year: json['year'] as String?,
      hostelBlock: json['hostel_block'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      sports: sportsData
              ?.map((e) => UserSport.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchesPlayed: totalMatches,
      wins: totalWins,
      losses: totalLosses,
      mvpCount: totalMvps,
      careerStatsRaw: careerStats?.cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'branch': branch,
        'year': year,
        'hostel_block': hostelBlock,
        'avatar_url': avatarUrl,
      };

  UserModel copyWith({
    String? name,
    String? branch,
    String? year,
    String? hostelBlock,
    String? avatarUrl,
    List<UserSport>? sports,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      hostelBlock: hostelBlock ?? this.hostelBlock,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sports: sports ?? this.sports,
      matchesPlayed: matchesPlayed,
      wins: wins,
      losses: losses,
      mvpCount: mvpCount,
      careerStatsRaw: careerStatsRaw,
    );
  }
}

class UserSport {
  const UserSport({
    required this.sportId,
    required this.sportName,
    required this.skillLevel,
  });

  final String sportId;
  final String sportName;
  final String skillLevel;

  factory UserSport.fromJson(Map<String, dynamic> json) {
    final sport = json['sports'] as Map<String, dynamic>?;
    return UserSport(
      sportId: json['sport_id'] as String,
      sportName: sport?['name'] as String? ?? 'Unknown',
      skillLevel: json['skill_level'] as String? ?? 'Beginner',
    );
  }
}
