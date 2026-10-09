/// VIT-AP Sports — Selectable Player Option Model.
library;

class PlayerOption {
  const PlayerOption({
    required this.id,
    required this.name,
    this.teamId,
    this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? teamId;
  final String? role;
  final String? avatarUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerOption && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory PlayerOption.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>?;
    return PlayerOption(
      id: (json['user_id'] as String?) ?? (json['id'] as String? ?? ''),
      name: (user?['name'] as String?) ?? (json['name'] as String? ?? 'Player'),
      teamId: json['team_id'] as String?,
      role: json['role'] as String?,
      avatarUrl: (user?['avatar_url'] as String?) ?? (json['avatar_url'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'team_id': teamId,
        'role': role,
        'avatar_url': avatarUrl,
      };
}
