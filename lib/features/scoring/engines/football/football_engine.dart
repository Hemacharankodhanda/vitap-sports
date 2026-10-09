/// VIT-AP Sports — Authoritative Football Scoring Engine.
library;

import '../../domain/match_event.dart';
import '../../domain/scoring_engine.dart';
import 'football_state.dart';

class FootballEngine extends ScoringEngine<FootballState, FootballConfig> {
  @override
  String get sport => 'Football';

  @override
  FootballState initialState(
    FootballConfig config, {
    required String homeId,
    required String awayId,
    Map<String, dynamic>? extra,
  }) {
    final homeLineup = (extra?['home_lineup'] as List<dynamic>?)?.cast<String>() ?? [];
    final awayLineup = (extra?['away_lineup'] as List<dynamic>?)?.cast<String>() ?? [];
    final homeBench = (extra?['home_bench'] as List<dynamic>?)?.cast<String>() ?? [];
    final awayBench = (extra?['away_bench'] as List<dynamic>?)?.cast<String>() ?? [];

    return FootballState(
      homeId: homeId,
      awayId: awayId,
      pitchPlayers: {
        homeId: homeLineup,
        awayId: awayLineup,
      },
      benchPlayers: {
        homeId: homeBench,
        awayId: awayBench,
      },
      currentPeriod: 'not_started',
    );
  }

  @override
  String? validate(FootballState state, MatchEvent event) {
    if (state.isCompleted) return 'Match is already completed';

    switch (event.type) {
      case 'period_start':
        final period = event.payload['period'] as String?;
        if (period == null) return 'Period name required';
        return null;

      case 'goal':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        final scorerId = event.playerId ?? event.payload['scorer'] as String?;
        if (teamId == null || scorerId == null) return 'Team and scorer required for goal';
        if (state.redCardedPlayers.contains(scorerId)) return 'Red-carded player cannot score';
        return null;

      case 'own_goal':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        final playerId = event.playerId ?? event.payload['player'] as String?;
        if (teamId == null || playerId == null) return 'Team and player required for own goal';
        return null;

      case 'yellow_card':
      case 'red_card':
        final playerId = event.playerId ?? event.payload['player'] as String?;
        if (playerId == null) return 'Player required for card';
        if (state.redCardedPlayers.contains(playerId)) return 'Player already sent off';
        return null;

      case 'substitution':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        final playerOut = event.payload['player_out'] as String?;
        final playerIn = event.payload['player_in'] as String?;
        if (teamId == null || playerOut == null || playerIn == null) {
          return 'Team, player_out, and player_in required for substitution';
        }
        final pitch = state.pitchPlayers[teamId] ?? [];
        final bench = state.benchPlayers[teamId] ?? [];
        final used = state.usedSubstitutes[teamId] ?? [];

        if (!pitch.contains(playerOut)) return 'Player out is not on the pitch';
        if (!bench.contains(playerIn)) return 'Player in is not on the bench';
        if (used.contains(playerIn)) return 'Player in has already been used';
        if (state.redCardedPlayers.contains(playerIn)) return 'Carded player cannot be substituted in';
        return null;

      case 'shootout_kick':
        if (state.shootoutCompleted) return 'Shootout already concluded';
        final teamId = event.teamId ?? event.payload['team'] as String?;
        final playerId = event.playerId ?? event.payload['player'] as String?;
        if (teamId == null || playerId == null) return 'Team and player required for shootout kick';
        return null;

      case 'forfeit':
      case 'walkover':
        final teamId = event.teamId ?? event.payload['team'] as String?;
        if (teamId == null) return 'Forfeiting team required';
        return null;

      default:
        return null;
    }
  }

  @override
  FootballState apply(FootballState state, MatchEvent event) {
    switch (event.type) {
      case 'lineups_set':
        final homeLineup = (event.payload['home_lineup'] as List<dynamic>?)?.cast<String>() ?? (state.pitchPlayers[state.homeId] ?? []);
        final awayLineup = (event.payload['away_lineup'] as List<dynamic>?)?.cast<String>() ?? (state.pitchPlayers[state.awayId] ?? []);
        final homeBench = (event.payload['home_bench'] as List<dynamic>?)?.cast<String>() ?? (state.benchPlayers[state.homeId] ?? []);
        final awayBench = (event.payload['away_bench'] as List<dynamic>?)?.cast<String>() ?? (state.benchPlayers[state.awayId] ?? []);
        return state.copyWith(
          pitchPlayers: {state.homeId: homeLineup, state.awayId: awayLineup},
          benchPlayers: {state.homeId: homeBench, state.awayId: awayBench},
        );

      case 'period_start':
        final period = event.payload['period'] as String? ?? 'first_half';
        final periodTimes = Map<String, String>.from(state.periodStartTimes);
        periodTimes[period] = event.createdAt.toIso8601String();
        return state.copyWith(
          currentPeriod: period,
          periodStartTimes: periodTimes,
        );

      case 'period_end':
        final period = event.payload['period'] as String? ?? state.currentPeriod;
        String nextPeriod = period;
        if (period == 'first_half') {
          nextPeriod = 'half_time';
        } else if (period == 'second_half') {
          nextPeriod = 'full_time';
        } else if (period == 'extra_time_1') {
          nextPeriod = 'extra_time_break';
        } else if (period == 'extra_time_2') {
          nextPeriod = 'full_time_extra';
        }
        return state.copyWith(currentPeriod: nextPeriod);

      case 'added_time':
        final period = event.payload['period'] as String? ?? state.currentPeriod;
        final minutes = event.payload['minutes'] as int? ?? 0;
        final times = Map<String, int>.from(state.addedTimeMinutes);
        times[period] = minutes;
        return state.copyWith(addedTimeMinutes: times);

      case 'goal':
        final teamId = event.teamId ?? event.payload['team'] as String;
        final scorerId = event.playerId ?? event.payload['scorer'] as String;
        final assistId = event.payload['assist'] as String?;
        final kind = event.payload['kind'] as String? ?? 'open_play';
        final minute = _deriveMinute(state, event);

        final newGoal = GoalRecord(
          teamId: teamId,
          scorerId: scorerId,
          assistId: assistId,
          kind: kind,
          minute: minute,
          isOwnGoal: false,
        );

        final isHome = teamId == state.homeId;
        return state.copyWith(
          homeScore: isHome ? state.homeScore + 1 : state.homeScore,
          awayScore: !isHome ? state.awayScore + 1 : state.awayScore,
          goals: [...state.goals, newGoal],
        );

      case 'own_goal':
        // Own goal: point goes to the OPPOSING team; credited to player as own goal
        final teamId = event.teamId ?? event.payload['team'] as String;
        final playerId = event.playerId ?? event.payload['player'] as String;
        final minute = _deriveMinute(state, event);

        final newGoal = GoalRecord(
          teamId: teamId,
          scorerId: playerId,
          kind: 'own_goal',
          minute: minute,
          isOwnGoal: true,
        );

        final isHomeScoredOwnGoal = teamId == state.homeId;
        // Point awarded to opposing team
        return state.copyWith(
          homeScore: isHomeScoredOwnGoal ? state.homeScore : state.homeScore + 1,
          awayScore: isHomeScoredOwnGoal ? state.awayScore + 1 : state.awayScore,
          goals: [...state.goals, newGoal],
        );

      case 'yellow_card':
        final teamId = event.teamId ?? event.payload['team'] as String;
        final playerId = event.playerId ?? event.payload['player'] as String;
        final currentCount = (state.yellowCards[playerId] ?? 0) + 1;
        final updatedYellows = Map<String, int>.from(state.yellowCards)..[playerId] = currentCount;

        // Second yellow card automatically creates red card
        if (currentCount >= 2) {
          final updatedReds = Set<String>.from(state.redCardedPlayers)..add(playerId);
          final updatedPitch = _removePlayerFromPitch(state.pitchPlayers, teamId, playerId);
          return state.copyWith(
            yellowCards: updatedYellows,
            redCardedPlayers: updatedReds,
            pitchPlayers: updatedPitch,
          );
        }
        return state.copyWith(yellowCards: updatedYellows);

      case 'red_card':
        final teamId = event.teamId ?? event.payload['team'] as String;
        final playerId = event.playerId ?? event.payload['player'] as String;
        final updatedReds = Set<String>.from(state.redCardedPlayers)..add(playerId);
        final updatedPitch = _removePlayerFromPitch(state.pitchPlayers, teamId, playerId);
        return state.copyWith(
          redCardedPlayers: updatedReds,
          pitchPlayers: updatedPitch,
        );

      case 'substitution':
        final teamId = event.teamId ?? event.payload['team'] as String;
        final playerOut = event.payload['player_out'] as String;
        final playerIn = event.payload['player_in'] as String;

        final pitchList = List<String>.from(state.pitchPlayers[teamId] ?? [])..remove(playerOut)..add(playerIn);
        final benchList = List<String>.from(state.benchPlayers[teamId] ?? [])..remove(playerIn);
        final usedList = List<String>.from(state.usedSubstitutes[teamId] ?? [])..add(playerIn);

        final newPitch = Map<String, List<String>>.from(state.pitchPlayers)..[teamId] = pitchList;
        final newBench = Map<String, List<String>>.from(state.benchPlayers)..[teamId] = benchList;
        final newUsed = Map<String, List<String>>.from(state.usedSubstitutes)..[teamId] = usedList;

        return state.copyWith(
          pitchPlayers: newPitch,
          benchPlayers: newBench,
          usedSubstitutes: newUsed,
        );

      case 'shootout_kick':
        final teamId = event.teamId ?? event.payload['team'] as String;
        final playerId = event.playerId ?? event.payload['player'] as String;
        final scored = event.payload['scored'] as bool? ?? false;

        final kick = ShootoutKick(teamId: teamId, playerId: playerId, scored: scored);
        final kicks = [...state.shootoutKicks, kick];

        final isHome = teamId == state.homeId;
        final homeScore = isHome && scored ? state.shootoutHomeScore + 1 : state.shootoutHomeScore;
        final awayScore = !isHome && scored ? state.shootoutAwayScore + 1 : state.shootoutAwayScore;

        // Check if shootout has finished
        final status = _evaluateShootout(kicks, state.homeId, state.awayId, homeScore, awayScore);

        return state.copyWith(
          shootoutKicks: kicks,
          shootoutHomeScore: homeScore,
          shootoutAwayScore: awayScore,
          shootoutCompleted: status.completed,
          winnerId: status.winnerId,
        );

      case 'walkover':
      case 'forfeit':
        final forfeitingTeam = event.teamId ?? event.payload['team'] as String;
        final winnerId = forfeitingTeam == state.homeId ? state.awayId : state.homeId;
        final isHomeWinner = winnerId == state.homeId;
        return state.copyWith(
          forfeitTeamId: forfeitingTeam,
          homeScore: isHomeWinner ? 3 : 0,
          awayScore: isHomeWinner ? 0 : 3,
          isCompleted: true,
          winnerId: winnerId,
          isDraw: false,
          currentPeriod: 'completed',
        );

      case 'finish_match':
        String? winner;
        bool isDraw = false;
        if (state.shootoutCompleted && state.winnerId != null) {
          winner = state.winnerId;
        } else if (state.homeScore > state.awayScore) {
          winner = state.homeId;
        } else if (state.awayScore > state.homeScore) {
          winner = state.awayId;
        } else {
          isDraw = true;
        }

        return state.copyWith(
          isCompleted: true,
          winnerId: winner,
          isDraw: isDraw,
          currentPeriod: 'completed',
        );

      default:
        return state;
    }
  }

  @override
  List<ScoringAction> availableActions(FootballState state) {
    if (state.isCompleted) return const [];

    final actions = <ScoringAction>[];

    // Period controls
    if (state.currentPeriod == 'not_started') {
      actions.add(const ScoringAction(
        id: 'start_first_half',
        label: 'Start 1st Half',
        type: 'period_start',
        payload: {'period': 'first_half'},
        isPrimary: true,
      ));
      return actions;
    }

    if (state.currentPeriod == 'first_half') {
      actions.add(const ScoringAction(
        id: 'end_first_half',
        label: 'End 1st Half',
        type: 'period_end',
        payload: {'period': 'first_half'},
      ));
    } else if (state.currentPeriod == 'half_time') {
      actions.add(const ScoringAction(
        id: 'start_second_half',
        label: 'Start 2nd Half',
        type: 'period_start',
        payload: {'period': 'second_half'},
        isPrimary: true,
      ));
      return actions;
    } else if (state.currentPeriod == 'second_half') {
      actions.add(const ScoringAction(
        id: 'end_second_half',
        label: 'End 2nd Half',
        type: 'period_end',
        payload: {'period': 'second_half'},
      ));
    }

    // In play actions
    if (state.currentPeriod == 'first_half' || state.currentPeriod == 'second_half' || state.currentPeriod.startsWith('extra_time')) {
      actions.add(ScoringAction(
        id: 'goal_home',
        label: 'Goal (Home)',
        type: 'goal',
        teamId: state.homeId,
        isPrimary: true,
      ));
      actions.add(ScoringAction(
        id: 'goal_away',
        label: 'Goal (Away)',
        type: 'goal',
        teamId: state.awayId,
        isPrimary: true,
      ));
      actions.add(ScoringAction(
        id: 'own_goal_home',
        label: 'Own Goal by Home',
        type: 'own_goal',
        teamId: state.homeId,
      ));
      actions.add(ScoringAction(
        id: 'own_goal_away',
        label: 'Own Goal by Away',
        type: 'own_goal',
        teamId: state.awayId,
      ));
      actions.add(const ScoringAction(
        id: 'yellow_card',
        label: 'Yellow Card',
        type: 'yellow_card',
      ));
      actions.add(const ScoringAction(
        id: 'red_card',
        label: 'Red Card',
        type: 'red_card',
        isDestructive: true,
      ));
      actions.add(const ScoringAction(
        id: 'substitution',
        label: 'Substitution',
        type: 'substitution',
      ));
    }

    // Shootout actions
    if (state.currentPeriod == 'shootout' && !state.shootoutCompleted) {
      actions.add(ScoringAction(
        id: 'shootout_kick_home',
        label: 'Shootout Kick (Home)',
        type: 'shootout_kick',
        teamId: state.homeId,
        isPrimary: true,
      ));
      actions.add(ScoringAction(
        id: 'shootout_kick_away',
        label: 'Shootout Kick (Away)',
        type: 'shootout_kick',
        teamId: state.awayId,
        isPrimary: true,
      ));
    }

    // Finish match
    actions.add(const ScoringAction(
      id: 'finish_match',
      label: 'Finish Match',
      type: 'finish_match',
      isDestructive: true,
    ));

    return actions;
  }

  @override
  bool isComplete(FootballState state) => state.isCompleted;

  @override
  Map<String, dynamic> result(FootballState state) {
    return {
      'home_score': state.homeScore,
      'away_score': state.awayScore,
      'shootout_home_score': state.shootoutHomeScore,
      'shootout_away_score': state.shootoutAwayScore,
      'winner_team_id': state.winnerId,
      'is_draw': state.isDraw,
      'forfeit_team_id': state.forfeitTeamId,
      'shootout_completed': state.shootoutCompleted,
      'goals': state.goals.map((g) => g.toJson()).toList(),
    };
  }

  @override
  Map<String, dynamic> toSnapshot(FootballState state) => state.toJson();

  @override
  FootballState fromSnapshot(Map<String, dynamic> json, FootballConfig config) =>
      FootballState.fromJson(json);

  int _deriveMinute(FootballState state, MatchEvent event) {
    if (event.payload['minute'] != null) {
      return event.payload['minute'] as int;
    }
    final periodStartTimeStr = state.periodStartTimes[state.currentPeriod];
    if (periodStartTimeStr == null) return 1;
    final start = DateTime.tryParse(periodStartTimeStr);
    if (start == null) return 1;
    final diffMinutes = event.createdAt.difference(start).inMinutes;
    final baseMinute = state.currentPeriod == 'second_half' ? 45 : 0;
    return (baseMinute + diffMinutes).clamp(1, 130);
  }

  Map<String, List<String>> _removePlayerFromPitch(
    Map<String, List<String>> pitch,
    String teamId,
    String playerId,
  ) {
    final list = List<String>.from(pitch[teamId] ?? [])..remove(playerId);
    return Map<String, List<String>>.from(pitch)..[teamId] = list;
  }

  ({bool completed, String? winnerId}) _evaluateShootout(
    List<ShootoutKick> kicks,
    String homeId,
    String awayId,
    int homeScore,
    int awayScore,
  ) {
    final homeKicks = kicks.where((k) => k.teamId == homeId).length;
    final awayKicks = kicks.where((k) => k.teamId == awayId).length;

    // Standard 5 kicks each
    if (homeKicks <= 5 && awayKicks <= 5) {
      final homeRemaining = 5 - homeKicks;
      final awayRemaining = 5 - awayKicks;

      // Mathematical impossibility check
      if (homeScore > awayScore + awayRemaining) {
        return (completed: true, winnerId: homeId);
      }
      if (awayScore > homeScore + homeRemaining) {
        return (completed: true, winnerId: awayId);
      }

      if (homeKicks == 5 && awayKicks == 5) {
        if (homeScore > awayScore) return (completed: true, winnerId: homeId);
        if (awayScore > homeScore) return (completed: true, winnerId: awayId);
        // Tied after 5 kicks -> Sudden death continues
        return (completed: false, winnerId: null);
      }
      return (completed: false, winnerId: null);
    }

    // Sudden death in equal pairs
    if (homeKicks == awayKicks && homeKicks > 5) {
      if (homeScore > awayScore) return (completed: true, winnerId: homeId);
      if (awayScore > homeScore) return (completed: true, winnerId: awayId);
    }

    return (completed: false, winnerId: null);
  }
}
