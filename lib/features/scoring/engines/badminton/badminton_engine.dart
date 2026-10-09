/// VIT-AP Sports — Authoritative BWF Badminton Scoring Engine.
library;

import '../../domain/match_event.dart';
import '../../domain/scoring_engine.dart';
import 'badminton_state.dart';

class BadmintonEngine extends ScoringEngine<BadmintonState, BadmintonConfig> {
  @override
  String get sport => 'Badminton';

  @override
  BadmintonState initialState(
    BadmintonConfig config, {
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final homePlayers = (extra?['home_players'] as List<dynamic>?)?.cast<String>() ?? [homeId];
    final awayPlayers = (extra?['away_players'] as List<dynamic>?)?.cast<String>() ?? [awayId];

    final firstServerTeamId = extra?['first_server_team_id'] as String? ?? homeId;
    final firstServerId = extra?['first_server_id'] as String? ?? (firstServerTeamId == homeId ? homePlayers.first : awayPlayers.first);
    final receivingTeamId = firstServerTeamId == homeId ? awayId : homeId;
    final firstReceiverId = extra?['first_receiver_id'] as String? ?? (receivingTeamId == homeId ? homePlayers.first : awayPlayers.first);

    // Initial court positions: Right court has player 0, Left has player 1 (if doubles)
    final homeCourt = {
      'right': homePlayers.isNotEmpty ? homePlayers[0] : homeId,
      'left': homePlayers.length > 1 ? homePlayers[1] : homeId,
    };
    final awayCourt = {
      'right': awayPlayers.isNotEmpty ? awayPlayers[0] : awayId,
      'left': awayPlayers.length > 1 ? awayPlayers[1] : awayId,
    };

    return BadmintonState(
      homeId: homeId,
      awayId: awayId,
      servingTeamId: firstServerTeamId,
      currentServerId: firstServerId,
      currentReceiverId: firstReceiverId,
      teamPlayers: {homeId: homePlayers, awayId: awayPlayers},
      courtPositions: {homeId: homeCourt, awayId: awayCourt},
      games: const [BadmintonGame()],
      currentGameIndex: 0,
    );
  }

  @override
  String? validate(BadmintonState state, MatchEvent event) {
    if (state.isCompleted) return 'Match is already completed';

    switch (event.type) {
      case 'rally_won':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        if (teamId == null) return 'Winning team is required';
        if (teamId != state.homeId && teamId != state.awayId) return 'Invalid team id';
        return null;

      case 'retire':
      case 'walkover':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        if (teamId == null) return 'Retiring/walkover team is required';
        return null;

      default:
        return null;
    }
  }

  @override
  BadmintonState apply(BadmintonState state, MatchEvent event) {
    switch (event.type) {
      case 'setup':
        final serverTeam = event.payload['first_server_team_id'] as String? ?? state.homeId;
        final serverId = event.payload['first_server_id'] as String?;
        final receiverId = event.payload['first_receiver_id'] as String?;
        return state.copyWith(
          servingTeamId: serverTeam,
          currentServerId: serverId ?? state.currentServerId,
          currentReceiverId: receiverId ?? state.currentReceiverId,
        );

      case 'dismiss_prompt':
        return state.copyWith(clearIntervalPrompt: true);

      case 'let':
        // Replay: no points, prompt cleared
        return state.copyWith(clearIntervalPrompt: true);

      case 'retire':
        final retiringTeam = event.teamId ?? event.payload['team'] as String;
        final winnerId = retiringTeam == state.homeId ? state.awayId : state.homeId;
        return state.copyWith(
          retireTeamId: retiringTeam,
          winnerId: winnerId,
          isCompleted: true,
          clearIntervalPrompt: true,
        );

      case 'walkover':
        final walkoverTeam = event.teamId ?? event.payload['team'] as String;
        final winnerId = walkoverTeam == state.homeId ? state.awayId : state.homeId;
        final isHome = winnerId == state.homeId;
        // Walkover recorded as 2-0 (21-0, 21-0)
        final walkoverGames = [
          BadmintonGame(homePoints: isHome ? 21 : 0, awayPoints: isHome ? 0 : 21, winnerId: winnerId, isCompleted: true),
          BadmintonGame(homePoints: isHome ? 21 : 0, awayPoints: isHome ? 0 : 21, winnerId: winnerId, isCompleted: true),
        ];
        return state.copyWith(
          walkoverTeamId: walkoverTeam,
          winnerId: winnerId,
          isCompleted: true,
          homeGamesWon: isHome ? 2 : 0,
          awayGamesWon: !isHome ? 2 : 0,
          games: walkoverGames,
          clearIntervalPrompt: true,
        );

      case 'rally_won':
        final winningTeam = event.teamId ?? event.payload['team'] as String;
        return _applyRallyWon(state, winningTeam);

      default:
        return state;
    }
  }

  BadmintonState _applyRallyWon(BadmintonState state, String winningTeam) {
    final currentGame = state.currentGame;
    final isHome = winningTeam == state.homeId;

    final newHomePts = isHome ? currentGame.homePoints + 1 : currentGame.homePoints;
    final newAwayPts = !isHome ? currentGame.awayPoints + 1 : currentGame.awayPoints;
    final winnerScore = isHome ? newHomePts : newAwayPts;
    final loserScore = isHome ? newAwayPts : newHomePts;

    // Check if this point wins the game
    // 21 pts lead by 2, or up to cap 30 (29-29 -> 30-29)
    final bool gameWon = (winnerScore >= 21 && (winnerScore - loserScore >= 2)) || (winnerScore >= 30);

    if (gameWon) {
      final updatedGame = currentGame.copyWith(
        homePoints: newHomePts,
        awayPoints: newAwayPts,
        winnerId: winningTeam,
        isCompleted: true,
      );

      final newGames = List<BadmintonGame>.from(state.games);
      newGames[state.currentGameIndex] = updatedGame;

      final newHomeGamesWon = isHome ? state.homeGamesWon + 1 : state.homeGamesWon;
      final newAwayGamesWon = !isHome ? state.awayGamesWon + 1 : state.awayGamesWon;

      // Best of 3 -> first to 2 games wins
      final bool matchWon = newHomeGamesWon >= 2 || newAwayGamesWon >= 2;

      if (matchWon) {
        return state.copyWith(
          games: newGames,
          homeGamesWon: newHomeGamesWon,
          awayGamesWon: newAwayGamesWon,
          isCompleted: true,
          winnerId: winningTeam,
          intervalPrompt: 'Match Won by ${isHome ? "Home" : "Away"}',
        );
      } else {
        // Next game begins; winner of previous game serves first
        final nextGameIndex = state.currentGameIndex + 1;
        newGames.add(const BadmintonGame());

        // Reset court positions for the new game
        final homePlayers = state.teamPlayers[state.homeId] ?? [];
        final awayPlayers = state.teamPlayers[state.awayId] ?? [];
        final newCourtPositions = {
          state.homeId: {
            'right': homePlayers.isNotEmpty ? homePlayers[0] : state.homeId,
            'left': homePlayers.length > 1 ? homePlayers[1] : state.homeId,
          },
          state.awayId: {
            'right': awayPlayers.isNotEmpty ? awayPlayers[0] : state.awayId,
            'left': awayPlayers.length > 1 ? awayPlayers[1] : state.awayId,
          },
        };

        return state.copyWith(
          games: newGames,
          currentGameIndex: nextGameIndex,
          homeGamesWon: newHomeGamesWon,
          awayGamesWon: newAwayGamesWon,
          servingTeamId: winningTeam,
          courtPositions: newCourtPositions,
          intervalPrompt: 'interval 120s - change ends',
        );
      }
    }

    // Game in progress: update court positions and serving player
    final wasServing = state.servingTeamId == winningTeam;
    final courtPositions = Map<String, Map<String, String>>.from(state.courtPositions);
    final teamCourt = Map<String, String>.from(courtPositions[winningTeam] ?? {});

    String? nextServerId;
    String? nextReceiverId;
    final receivingTeam = winningTeam == state.homeId ? state.awayId : state.homeId;
    final oppCourt = courtPositions[receivingTeam] ?? {};

    if (wasServing) {
      // Serving side won rally: SAME server continues, but serving pair SWAPS courts (Right <-> Left)
      final prevRight = teamCourt['right'] ?? '';
      final prevLeft = teamCourt['left'] ?? '';
      teamCourt['right'] = prevLeft;
      teamCourt['left'] = prevRight;
      courtPositions[winningTeam] = teamCourt;

      nextServerId = state.currentServerId;
      // Receiver is the player in the diagonal receiving court matching server's court
      final serverSideScore = isHome ? newHomePts : newAwayPts;
      final serverCourtKey = (serverSideScore % 2 == 0) ? 'right' : 'left';
      nextReceiverId = oppCourt[serverCourtKey];
    } else {
      // Receiving side won rally: They gain serve; NEITHER side swaps courts.
      // Server is the player standing in court corresponding to their NEW score parity
      final newServerScore = isHome ? newHomePts : newAwayPts;
      final serverCourtKey = (newServerScore % 2 == 0) ? 'right' : 'left';
      nextServerId = teamCourt[serverCourtKey];
      nextReceiverId = oppCourt[serverCourtKey];
    }

    // Check interval prompt at leading score = 11
    final leadingScore = newHomePts > newAwayPts ? newHomePts : newAwayPts;
    String? intervalMsg = state.intervalPrompt;
    final triggeredMap = Map<int, bool>.from(state.intervalTriggeredAt11);

    if (leadingScore == 11 && !(triggeredMap[state.currentGameIndex] ?? false)) {
      triggeredMap[state.currentGameIndex] = true;
      if (state.currentGameIndex == 2) {
        intervalMsg = 'interval 60s - change ends';
      } else {
        intervalMsg = 'interval 60s';
      }
    }

    final updatedGame = currentGame.copyWith(homePoints: newHomePts, awayPoints: newAwayPts);
    final newGames = List<BadmintonGame>.from(state.games);
    newGames[state.currentGameIndex] = updatedGame;

    return state.copyWith(
      games: newGames,
      servingTeamId: winningTeam,
      currentServerId: nextServerId,
      currentReceiverId: nextReceiverId,
      courtPositions: courtPositions,
      intervalPrompt: intervalMsg,
      intervalTriggeredAt11: triggeredMap,
    );
  }

  @override
  List<ScoringAction> availableActions(BadmintonState state) {
    if (state.isCompleted) return const [];

    final actions = <ScoringAction>[];

    actions.add(ScoringAction(
      id: 'point_home',
      label: 'Point Home',
      type: 'rally_won',
      teamId: state.homeId,
      isPrimary: state.servingTeamId == state.homeId,
    ));

    actions.add(ScoringAction(
      id: 'point_away',
      label: 'Point Away',
      type: 'rally_won',
      teamId: state.awayId,
      isPrimary: state.servingTeamId == state.awayId,
    ));

    actions.add(const ScoringAction(
      id: 'let',
      label: 'Let (Replay)',
      type: 'let',
    ));

    if (state.intervalPrompt != null) {
      actions.add(const ScoringAction(
        id: 'dismiss_prompt',
        label: 'Dismiss Interval Prompt',
        type: 'dismiss_prompt',
      ));
    }

    actions.add(ScoringAction(
      id: 'retire_home',
      label: 'Retire Home',
      type: 'retire',
      teamId: state.homeId,
      isDestructive: true,
    ));

    actions.add(ScoringAction(
      id: 'retire_away',
      label: 'Retire Away',
      type: 'retire',
      teamId: state.awayId,
      isDestructive: true,
    ));

    return actions;
  }

  @override
  bool isComplete(BadmintonState state) => state.isCompleted;

  @override
  Map<String, dynamic> result(BadmintonState state) {
    final scoresSummary = state.games.map((g) => '${g.homePoints}-${g.awayPoints}').join(', ');
    return {
      'home_games_won': state.homeGamesWon,
      'away_games_won': state.awayGamesWon,
      'games_summary': scoresSummary,
      'winner_team_id': state.winnerId,
      'is_draw': false,
      'retire_team_id': state.retireTeamId,
      'walkover_team_id': state.walkoverTeamId,
    };
  }

  @override
  Map<String, dynamic> toSnapshot(BadmintonState state) => state.toJson();

  @override
  BadmintonState fromSnapshot(Map<String, dynamic> json, BadmintonConfig config) =>
      BadmintonState.fromJson(json);
}
