/// VIT-AP Sports — Team model.
library;

import '../../../profile/data/models/user_model.dart';

class TeamModel {
  const TeamModel({
    required this.id,
    required this.name,
    required this.sportId,
    this.sportName,
    this.logoUrl,
    this.description,
    required this.captainId,
    this.captainName,
    this.createdAt,
    this.members = const [],
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  final String id;
  final String name;
  final String sportId;
  final String? sportName;
  final String? logoUrl;
  final String? description;
  final String captainId;
  final String? captainName;
  final DateTime? createdAt;
  final List<TeamMember> members;
  final int wins;
  final int losses;
  final int draws;

  int get totalMatches => wins + losses + draws;

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    final sport = json['sports'] as Map<String, dynamic>?;
    final captain = json['captain'] as Map<String, dynamic>?;
    final membersData = json['team_members'] as List<dynamic>?;

    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sportId: json['sport_id'] as String,
      sportName: sport?['name'] as String?,
      logoUrl: json['logo_url'] as String?,
      description: json['description'] as String?,
      captainId: json['captain_id'] as String,
      captainName: captain?['name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      members: membersData
              ?.map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sport_id': sportId,
        'logo_url': logoUrl,
        'description': description,
        'captain_id': captainId,
      };
}

class TeamMember {
  const TeamMember({
    required this.userId,
    required this.teamId,
    this.userName,
    this.avatarUrl,
    this.role = 'member',
    this.position,
    this.joinedAt,
  });

  final String userId;
  final String teamId;
  final String? userName;
  final String? avatarUrl;
  final String role;
  final String? position;
  final DateTime? joinedAt;

  bool get isCaptain => role == 'captain';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return TeamMember(
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      userName: user?['name'] as String?,
      avatarUrl: user?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      position: json['position'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }
}
