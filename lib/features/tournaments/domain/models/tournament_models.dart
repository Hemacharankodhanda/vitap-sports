/// VIT-AP Sports — Tournament Domain Models.
///
/// Immutable, pure-Dart models for tournaments, entries, fixtures, groups, and standings.
library;

enum TournamentFormat {
  knockout,
  league,
  groupsKnockout;

  String get sqlValue {
    switch (this) {
      case TournamentFormat.groupsKnockout:
        return 'groups_knockout';
      default:
        return name;
    }
  }

  static TournamentFormat fromString(String val) {
    switch (val.toLowerCase()) {
      case 'league':
        return TournamentFormat.league;
      case 'groups_knockout':
      case 'groups':
        return TournamentFormat.groupsKnockout;
      case 'knockout':
      default:
        return TournamentFormat.knockout;
    }
  }
}

enum TournamentStatus {
  draft,
  registrationOpen,
  registrationClosed,
  ready,
  live,
  completed,
  cancelled;

  String get sqlValue {
    switch (this) {
      case TournamentStatus.registrationOpen:
        return 'registration_open';
      case TournamentStatus.registrationClosed:
        return 'registration_closed';
      default:
        return name;
    }
  }

  static TournamentStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'registration_open':
        return TournamentStatus.registrationOpen;
      case 'registration_closed':
        return TournamentStatus.registrationClosed;
      case 'ready':
        return TournamentStatus.ready;
      case 'live':
        return TournamentStatus.live;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      case 'draft':
      default:
        return TournamentStatus.draft;
    }
  }
}

enum TournamentScope {
  open,
  hostel,
  branch,
  year;

  static TournamentScope fromString(String val) {
    switch (val.toLowerCase()) {
      case 'hostel':
        return TournamentScope.hostel;
      case 'branch':
        return TournamentScope.branch;
      case 'year':
        return TournamentScope.year;
      case 'open':
      default:
        return TournamentScope.open;
    }
  }
}

enum EntryKind {
  team,
  player,
  pair;

  static EntryKind fromString(String val) {
    switch (val.toLowerCase()) {
      case 'player':
        return EntryKind.player;
      case 'pair':
        return EntryKind.pair;
      case 'team':
      default:
        return EntryKind.team;
    }
  }
}

enum EntryStatus {
  pending,
  approved,
  waitlisted,
  withdrawn,
  disqualified;

  static EntryStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'approved':
        return EntryStatus.approved;
      case 'waitlisted':
        return EntryStatus.waitlisted;
      case 'withdrawn':
        return EntryStatus.withdrawn;
      case 'disqualified':
        return EntryStatus.disqualified;
      case 'pending':
      default:
        return EntryStatus.pending;
    }
  }
}

enum FixtureStage {
  group,
  knockout,
  thirdPlace;

  String get sqlValue {
    switch (this) {
      case FixtureStage.thirdPlace:
        return 'third_place';
      default:
        return name;
    }
  }

  static FixtureStage fromString(String val) {
    switch (val.toLowerCase()) {
      case 'group':
        return FixtureStage.group;
      case 'third_place':
        return FixtureStage.thirdPlace;
      case 'knockout':
      default:
        return FixtureStage.knockout;
    }
  }
}

enum FixtureStatus {
  pending,
  scheduled,
  live,
  completed,
  walkover,
  cancelled;

  static FixtureStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'scheduled':
        return FixtureStatus.scheduled;
      case 'live':
        return FixtureStatus.live;
      case 'completed':
        return FixtureStatus.completed;
      case 'walkover':
        return FixtureStatus.walkover;
      case 'cancelled':
        return FixtureStatus.cancelled;
      case 'pending':
      default:
        return FixtureStatus.pending;
    }
  }
}

class TournamentModel {
  const TournamentModel({
    required this.id,
    required this.name,
    required this.sport,
    this.sportId,
    this.format = TournamentFormat.knockout,
    this.status = TournamentStatus.draft,
    this.config = const {},
    this.scope = TournamentScope.open,
    this.eligibility = const {},
    this.organiserId,
    this.isOfficial = false,
    this.registrationDeadline,
    this.maxEntries,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String sport;
  final String? sportId;
  final TournamentFormat format;
  final TournamentStatus status;
  final Map<String, dynamic> config;
  final TournamentScope scope;
  final Map<String, dynamic> eligibility;
  final String? organiserId;
  final bool isOfficial;
  final DateTime? registrationDeadline;
  final int? maxEntries;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    return TournamentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Untitled Tournament',
      sport: json['sport'] as String? ?? 'cricket',
      sportId: json['sport_id'] as String?,
      format: TournamentFormat.fromString(json['format'] as String? ?? 'knockout'),
      status: TournamentStatus.fromString(json['status'] as String? ?? 'draft'),
      config: json['config'] is Map
          ? Map<String, dynamic>.from(json['config'] as Map)
          : {},
      scope: TournamentScope.fromString(json['scope'] as String? ?? 'open'),
      eligibility: json['eligibility'] is Map
          ? Map<String, dynamic>.from(json['eligibility'] as Map)
          : {},
      organiserId: json['organiser_id'] as String?,
      isOfficial: json['is_official'] as bool? ?? false,
      registrationDeadline: json['registration_deadline'] != null
          ? DateTime.tryParse(json['registration_deadline'].toString())
          : null,
      maxEntries: (json['max_entries'] as num?)?.toInt(),
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sport': sport,
        if (sportId != null) 'sport_id': sportId,
        'format': format.sqlValue,
        'status': status.sqlValue,
        'config': config,
        'scope': scope.name,
        'eligibility': eligibility,
        if (organiserId != null) 'organiser_id': organiserId,
        'is_official': isOfficial,
        if (registrationDeadline != null)
          'registration_deadline': registrationDeadline!.toIso8601String(),
        if (maxEntries != null) 'max_entries': maxEntries,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
      };
}

class TournamentEntry {
  const TournamentEntry({
    required this.id,
    required this.tournamentId,
    this.kind = EntryKind.team,
    this.teamId,
    this.playerIds = const [],
    required this.displayName,
    this.seed,
    this.groupId,
    this.status = EntryStatus.pending,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final EntryKind kind;
  final String? teamId;
  final List<String> playerIds;
  final String displayName;
  final int? seed;
  final String? groupId;
  final EntryStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TournamentEntry.fromJson(Map<String, dynamic> json) {
    return TournamentEntry(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      kind: EntryKind.fromString(json['kind'] as String? ?? 'team'),
      teamId: json['team_id'] as String?,
      playerIds: (json['player_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      displayName: json['display_name'] as String? ?? 'Entry',
      seed: (json['seed'] as num?)?.toInt(),
      groupId: json['group_id'] as String?,
      status: EntryStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: (json['created_at'] ?? json['registered_at']) != null
          ? DateTime.tryParse((json['created_at'] ?? json['registered_at']).toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournament_id': tournamentId,
        'kind': kind.name,
        'team_id': teamId,
        'player_ids': playerIds,
        'display_name': displayName,
        'seed': seed,
        'group_id': groupId,
        'status': status.name,
      };

  TournamentEntry copyWith({
    String? id,
    String? tournamentId,
    EntryKind? kind,
    String? teamId,
    List<String>? playerIds,
    String? displayName,
    int? seed,
    String? groupId,
    EntryStatus? status,
  }) {
    return TournamentEntry(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      kind: kind ?? this.kind,
      teamId: teamId ?? this.teamId,
      playerIds: playerIds ?? this.playerIds,
      displayName: displayName ?? this.displayName,
      seed: seed ?? this.seed,
      groupId: groupId ?? this.groupId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class TournamentGroup {
  const TournamentGroup({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.position,
  });

  final String id;
  final String tournamentId;
  final String name;
  final int position;

  factory TournamentGroup.fromJson(Map<String, dynamic> json) {
    return TournamentGroup(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Group',
      position: (json['position'] as num?)?.toInt() ??
          (json['order_index'] as num?)?.toInt() ??
          1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournament_id': tournamentId,
        'name': name,
        'position': position,
      };
}

class TournamentFixture {
  const TournamentFixture({
    required this.id,
    required this.tournamentId,
    required this.stage,
    this.groupId,
    required this.round,
    required this.position,
    required this.roundLabel,
    this.entryAId,
    this.entryBId,
    this.sourceFixtureAId,
    this.sourceFixtureBId,
    this.sourceOutcomeA,
    this.sourceOutcomeB,
    this.isBye = false,
    this.scheduledAt,
    this.venue,
    this.status = FixtureStatus.pending,
    this.matchId,
    this.result = const {},
    this.winnerEntryId,
    this.nextFixtureId,
    this.nextSlot,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String tournamentId;
  final FixtureStage stage;
  final String? groupId;
  final int round;
  final int position;
  final String roundLabel;
  final String? entryAId;
  final String? entryBId;
  final String? sourceFixtureAId;
  final String? sourceFixtureBId;
  final String? sourceOutcomeA; // 'winner' or 'loser'
  final String? sourceOutcomeB; // 'winner' or 'loser'
  final bool isBye;
  final DateTime? scheduledAt;
  final String? venue;
  final FixtureStatus status;
  final String? matchId;
  final Map<String, dynamic> result;
  final String? winnerEntryId;
  final String? nextFixtureId;
  final String? nextSlot; // 'a' or 'b'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TournamentFixture.fromJson(Map<String, dynamic> json) {
    return TournamentFixture(
      id: json['id']?.toString() ?? '',
      tournamentId: json['tournament_id']?.toString() ?? '',
      stage: FixtureStage.fromString(json['stage'] as String? ?? 'knockout'),
      groupId: json['group_id'] as String?,
      round: (json['round'] as num?)?.toInt() ?? 1,
      position: (json['position'] as num?)?.toInt() ?? 1,
      roundLabel: json['round_label'] as String? ?? 'Round 1',
      entryAId: json['entry_a_id'] as String?,
      entryBId: json['entry_b_id'] as String?,
      sourceFixtureAId: json['source_fixture_a_id'] as String?,
      sourceFixtureBId: json['source_fixture_b_id'] as String?,
      sourceOutcomeA: json['source_outcome_a'] as String?,
      sourceOutcomeB: json['source_outcome_b'] as String?,
      isBye: json['is_bye'] as bool? ?? false,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      venue: json['venue'] as String?,
      status: FixtureStatus.fromString(json['status'] as String? ?? 'pending'),
      matchId: json['match_id'] as String?,
      result: json['result'] is Map
          ? Map<String, dynamic>.from(json['result'] as Map)
          : {},
      winnerEntryId: json['winner_entry_id'] as String?,
      nextFixtureId: json['next_fixture_id'] as String?,
      nextSlot: json['next_slot'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournament_id': tournamentId,
        'stage': stage.sqlValue,
        'group_id': groupId,
        'round': round,
        'position': position,
        'round_label': roundLabel,
        'entry_a_id': entryAId,
        'entry_b_id': entryBId,
        'source_fixture_a_id': sourceFixtureAId,
        'source_fixture_b_id': sourceFixtureBId,
        'source_outcome_a': sourceOutcomeA,
        'source_outcome_b': sourceOutcomeB,
        'is_bye': isBye,
        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
        'venue': venue,
        'status': status.name,
        'match_id': matchId,
        'result': result,
        'winner_entry_id': winnerEntryId,
        'next_fixture_id': nextFixtureId,
        'next_slot': nextSlot,
      };

  TournamentFixture copyWith({
    String? entryAId,
    String? entryBId,
    bool? isBye,
    FixtureStatus? status,
    String? matchId,
    Map<String, dynamic>? result,
    String? winnerEntryId,
    DateTime? scheduledAt,
    String? venue,
    String? nextFixtureId,
    String? nextSlot,
    String? sourceFixtureAId,
    String? sourceFixtureBId,
  }) {
    return TournamentFixture(
      id: id,
      tournamentId: tournamentId,
      stage: stage,
      groupId: groupId,
      round: round,
      position: position,
      roundLabel: roundLabel,
      entryAId: entryAId ?? this.entryAId,
      entryBId: entryBId ?? this.entryBId,
      sourceFixtureAId: sourceFixtureAId ?? this.sourceFixtureAId,
      sourceFixtureBId: sourceFixtureBId ?? this.sourceFixtureBId,
      sourceOutcomeA: sourceOutcomeA,
      sourceOutcomeB: sourceOutcomeB,
      isBye: isBye ?? this.isBye,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      venue: venue ?? this.venue,
      status: status ?? this.status,
      matchId: matchId ?? this.matchId,
      result: result ?? this.result,
      winnerEntryId: winnerEntryId ?? this.winnerEntryId,
      nextFixtureId: nextFixtureId ?? this.nextFixtureId,
      nextSlot: nextSlot ?? this.nextSlot,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Standings Table Row across Football, Cricket, and Badminton
class TournamentStandingsRow {
  const TournamentStandingsRow({
    required this.entryId,
    required this.displayName,
    this.seed,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.tied = 0,
    this.noResult = 0,
    this.points = 0,
    // Football metrics
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.goalDifference = 0,
    // Cricket metrics
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.runsConceded = 0,
    this.ballsBowled = 0,
    this.netRunRate = 0.0,
    // Badminton metrics
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.gameDifference = 0,
    this.pointsWon = 0,
    this.pointsLost = 0,
    this.pointDifference = 0,
    // Tie-break trail and flags
    this.tieBreakNotes = const [],
    this.needsOrganiserDecision = false,
  });

  final String entryId;
  final String displayName;
  final int? seed;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int tied;
  final int noResult;
  final int points;

  // Football
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  // Cricket
  final int runsScored;
  final int ballsFaced;
  final int runsConceded;
  final int ballsBowled;
  final double netRunRate;

  // Badminton
  final int gamesWon;
  final int gamesLost;
  final int gameDifference;
  final int pointsWon;
  final int pointsLost;
  final int pointDifference;

  final List<String> tieBreakNotes;
  final bool needsOrganiserDecision;

  TournamentStandingsRow copyWith({
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? tied,
    int? noResult,
    int? points,
    int? goalsFor,
    int? goalsAgainst,
    int? goalDifference,
    int? runsScored,
    int? ballsFaced,
    int? runsConceded,
    int? ballsBowled,
    double? netRunRate,
    int? gamesWon,
    int? gamesLost,
    int? gameDifference,
    int? pointsWon,
    int? pointsLost,
    int? pointDifference,
    List<String>? tieBreakNotes,
    bool? needsOrganiserDecision,
  }) {
    return TournamentStandingsRow(
      entryId: entryId,
      displayName: displayName,
      seed: seed,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      tied: tied ?? this.tied,
      noResult: noResult ?? this.noResult,
      points: points ?? this.points,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      goalDifference: goalDifference ?? this.goalDifference,
      runsScored: runsScored ?? this.runsScored,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      runsConceded: runsConceded ?? this.runsConceded,
      ballsBowled: ballsBowled ?? this.ballsBowled,
      netRunRate: netRunRate ?? this.netRunRate,
      gamesWon: gamesWon ?? this.gamesWon,
      gamesLost: gamesLost ?? this.gamesLost,
      gameDifference: gameDifference ?? this.gameDifference,
      pointsWon: pointsWon ?? this.pointsWon,
      pointsLost: pointsLost ?? this.pointsLost,
      pointDifference: pointDifference ?? this.pointDifference,
      tieBreakNotes: tieBreakNotes ?? this.tieBreakNotes,
      needsOrganiserDecision:
          needsOrganiserDecision ?? this.needsOrganiserDecision,
    );
  }
}

/// Podium Honour Rank
enum HonourRank {
  champion,
  runnerUp,
  thirdPlace;

  String get label {
    switch (this) {
      case HonourRank.champion:
        return 'Champion';
      case HonourRank.runnerUp:
        return 'Runner-Up';
      case HonourRank.thirdPlace:
        return '3rd Place';
    }
  }
}

/// Tournament Trophy / Medal Honour for Player Profiles
class TournamentHonour {
  const TournamentHonour({
    required this.tournamentId,
    required this.tournamentName,
    required this.sport,
    required this.rank,
    required this.year,
    required this.teamOrEntryName,
    this.isOfficial = false,
  });

  final String tournamentId;
  final String tournamentName;
  final String sport;
  final HonourRank rank;
  final String year;
  final String teamOrEntryName;
  final bool isOfficial;

  factory TournamentHonour.fromJson(Map<String, dynamic> json) {
    HonourRank r = HonourRank.champion;
    final rStr = (json['rank'] as String?)?.toLowerCase();
    if (rStr == 'runner_up' || rStr == 'runnerup') {
      r = HonourRank.runnerUp;
    } else if (rStr == 'third_place' || rStr == 'thirdplace') {
      r = HonourRank.thirdPlace;
    }

    return TournamentHonour(
      tournamentId: json['tournament_id'] as String? ?? '',
      tournamentName: json['tournament_name'] as String? ?? 'Tournament',
      sport: json['sport'] as String? ?? 'cricket',
      rank: r,
      year: json['year']?.toString() ?? '2026',
      teamOrEntryName: json['team_or_entry_name'] as String? ?? 'Entry',
      isOfficial: json['is_official'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'tournament_id': tournamentId,
    'tournament_name': tournamentName,
    'sport': sport,
    'rank': rank.name,
    'year': year,
    'team_or_entry_name': teamOrEntryName,
    'is_official': isOfficial,
  };
}
