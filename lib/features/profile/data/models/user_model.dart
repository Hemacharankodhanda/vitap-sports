/// VIT-AP Sports — User model.
library;

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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final sportsData = json['user_sports'] as List<dynamic>?;
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
      matchesPlayed: json['matches_played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      mvpCount: json['mvp_count'] as int? ?? 0,
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
