/// VIT-AP Sports — Badminton State & Config.
library;

class BadmintonConfig {
  const BadmintonConfig({
    this.format = 'singles', // 'singles' or 'doubles'
    this.bestOfGames = 3,
    this.pointsPerGame = 21,
    this.cap = 30,
  });

  final String format;
  final int bestOfGames;
  final int pointsPerGame;
  final int cap;

  bool get isDoubles => format == 'doubles';
  int get gamesToWin => (bestOfGames / 2).ceil();

  factory BadmintonConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BadmintonConfig();
    return BadmintonConfig(
      format: json['format'] as String? ?? 'singles',
      bestOfGames: json['best_of_games'] as int? ?? 3,
      pointsPerGame: json['points_per_game'] as int? ?? 21,
      cap: json['cap'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
        'format': format,
        'best_of_games': bestOfGames,
        'points_per_game': pointsPerGame,
        'cap': cap,
      };
}

class BadmintonGame {
  const BadmintonGame({
    this.homePoints = 0,
    this.awayPoints = 0,
    this.winnerId,
    this.isCompleted = false,
  });

  final int homePoints;
  final int awayPoints;
  final String? winnerId;
  final bool isCompleted;

  BadmintonGame copyWith({
    int? homePoints,
    int? awayPoints,
    String? winnerId,
    bool? isCompleted,
  }) {
    return BadmintonGame(
      homePoints: homePoints ?? this.homePoints,
      awayPoints: awayPoints ?? this.awayPoints,
      winnerId: winnerId ?? this.winnerId,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'home_points': homePoints,
        'away_points': awayPoints,
        'winner_id': winnerId,
        'is_completed': isCompleted,
      };

  factory BadmintonGame.fromJson(Map<String, dynamic> json) => BadmintonGame(
        homePoints: (json['home_points'] as num?)?.toInt() ?? 0,
        awayPoints: (json['away_points'] as num?)?.toInt() ?? 0,
        winnerId: json['winner_id']?.toString(),
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}

class BadmintonState {
  const BadmintonState({
    required this.homeId,
    required this.awayId,
    this.currentGameIndex = 0,
    this.games = const [BadmintonGame()],
    this.homeGamesWon = 0,
    this.awayGamesWon = 0,
    this.servingTeamId,
    this.currentServerId,
    this.currentReceiverId,
    this.teamPlayers = const {},
    this.courtPositions = const {},
    this.intervalPrompt,
    this.intervalTriggeredAt11 = const {},
    this.isCompleted = false,
    this.winnerId,
    this.retireTeamId,
    this.walkoverTeamId,
    this.playerStats = const {},
  });

  final String homeId;
  final String awayId;
  final int currentGameIndex;
  final List<BadmintonGame> games;
  final int homeGamesWon;
  final int awayGamesWon;
  final String? servingTeamId;
  final String? currentServerId;
  final String? currentReceiverId;
  final Map<String, List<String>> teamPlayers;
  // teamId -> {'right': playerId, 'left': playerId}
  final Map<String, Map<String, String>> courtPositions;
  final String? intervalPrompt;
  final Map<int, bool> intervalTriggeredAt11; // gameIndex -> triggered
  final bool isCompleted;
  final String? winnerId;
  final String? retireTeamId;
  final String? walkoverTeamId;
  final Map<String, Map<String, int>> playerStats; // playerId -> {'points_won': 0, 'service_points_won': 0}

  BadmintonGame get currentGame =>
      currentGameIndex < games.length ? games[currentGameIndex] : const BadmintonGame();

  BadmintonState copyWith({
    String? homeId,
    String? awayId,
    int? currentGameIndex,
    List<BadmintonGame>? games,
    int? homeGamesWon,
    int? awayGamesWon,
    String? servingTeamId,
    String? currentServerId,
    String? currentReceiverId,
    Map<String, List<String>>? teamPlayers,
    Map<String, Map<String, String>>? courtPositions,
    String? intervalPrompt,
    bool clearIntervalPrompt = false,
    Map<int, bool>? intervalTriggeredAt11,
    bool? isCompleted,
    String? winnerId,
    String? retireTeamId,
    String? walkoverTeamId,
    Map<String, Map<String, int>>? playerStats,
  }) {
    return BadmintonState(
      homeId: homeId ?? this.homeId,
      awayId: awayId ?? this.awayId,
      currentGameIndex: currentGameIndex ?? this.currentGameIndex,
      games: games ?? this.games,
      homeGamesWon: homeGamesWon ?? this.homeGamesWon,
      awayGamesWon: awayGamesWon ?? this.awayGamesWon,
      servingTeamId: servingTeamId ?? this.servingTeamId,
      currentServerId: currentServerId ?? this.currentServerId,
      currentReceiverId: currentReceiverId ?? this.currentReceiverId,
      teamPlayers: teamPlayers ?? this.teamPlayers,
      courtPositions: courtPositions ?? this.courtPositions,
      intervalPrompt: clearIntervalPrompt ? null : (intervalPrompt ?? this.intervalPrompt),
      intervalTriggeredAt11: intervalTriggeredAt11 ?? this.intervalTriggeredAt11,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerId: winnerId ?? this.winnerId,
      retireTeamId: retireTeamId ?? this.retireTeamId,
      walkoverTeamId: walkoverTeamId ?? this.walkoverTeamId,
      playerStats: playerStats ?? this.playerStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'home_id': homeId,
        'away_id': awayId,
        'current_game_index': currentGameIndex,
        'games': games.map((g) => g.toJson()).toList(),
        'home_games_won': homeGamesWon,
        'away_games_won': awayGamesWon,
        'serving_team_id': servingTeamId,
        'current_server_id': currentServerId,
        'current_receiver_id': currentReceiverId,
        'team_players': teamPlayers,
        'court_positions': courtPositions,
        'interval_prompt': intervalPrompt,
        'interval_triggered_at_11': intervalTriggeredAt11.map((k, v) => MapEntry(k.toString(), v)),
        'is_completed': isCompleted,
        'winner_id': winnerId,
        'retire_team_id': retireTeamId,
        'walkover_team_id': walkoverTeamId,
        'player_stats': playerStats,
      };

  factory BadmintonState.fromJson(Map<String, dynamic> json) {
    final gamesRaw = json['games'];
    final gamesList = (gamesRaw is List)
        ? gamesRaw
            .whereType<Map>()
            .map((g) => BadmintonGame.fromJson(Map<String, dynamic>.from(g)))
            .toList()
        : const [BadmintonGame()];

    final courtPos = (json['court_positions'] is Map)
        ? (json['court_positions'] as Map).map(
            (k, v) => MapEntry(
              k.toString(),
              (v is Map)
                  ? (v).map((k2, v2) => MapEntry(k2.toString(), v2.toString()))
                  : <String, String>{},
            ),
          )
        : const <String, Map<String, String>>{};

    final triggered = (json['interval_triggered_at_11'] is Map)
        ? (json['interval_triggered_at_11'] as Map).map(
            (k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, v as bool? ?? false),
          )
        : const <int, bool>{};

    final pStats = <String, Map<String, int>>{};
    if (json['player_stats'] is Map) {
      (json['player_stats'] as Map).forEach((k, v) {
        if (v is Map) {
          final statsMap = <String, int>{};
          v.forEach((k2, v2) {
            if (v2 is num) {
              statsMap[k2.toString()] = v2.toInt();
            } else if (v2 != null) {
              final parsed = int.tryParse(v2.toString());
              if (parsed != null) {
                statsMap[k2.toString()] = parsed;
              }
            }
          });
          pStats[k.toString()] = statsMap;
        }
      });
    }

    return BadmintonState(
      homeId: json['home_id']?.toString() ?? 'home',
      awayId: json['away_id']?.toString() ?? 'away',
      currentGameIndex: (json['current_game_index'] as num?)?.toInt() ?? 0,
      games: gamesList,
      homeGamesWon: (json['home_games_won'] as num?)?.toInt() ?? 0,
      awayGamesWon: (json['away_games_won'] as num?)?.toInt() ?? 0,
      servingTeamId: json['serving_team_id']?.toString(),
      currentServerId: json['current_server_id']?.toString(),
      currentReceiverId: json['current_receiver_id']?.toString(),
      teamPlayers: (json['team_players'] is Map)
          ? (json['team_players'] as Map).map(
              (k, v) => MapEntry(
                k.toString(),
                (v is List) ? v.map((e) => e.toString()).toList() : <String>[],
              ),
            )
          : const {},
      courtPositions: courtPos,
      intervalPrompt: json['interval_prompt']?.toString(),
      intervalTriggeredAt11: triggered,
      isCompleted: json['is_completed'] as bool? ?? false,
      winnerId: json['winner_id']?.toString(),
      retireTeamId: json['retire_team_id']?.toString(),
      walkoverTeamId: json['walkover_team_id']?.toString(),
      playerStats: pStats,
    );
  }
}
