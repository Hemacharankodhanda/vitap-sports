/// VIT-AP Sports — Tournament Detail Screen.
///
/// Comprehensive 6-tab hub for tournament overview, fixtures, standings,
/// interactive bracket, tournament stats, and team rosters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/tournament_models.dart';
import '../../providers/tournament_providers.dart';
import '../widgets/generate_draw_dialog.dart';
import '../widgets/knockout_bracket_view.dart';
import '../widgets/register_entry_sheet.dart';
import '../widgets/tournament_standings_table.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({
    required this.tournamentId,
    super.key,
  });

  final String tournamentId;

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final entriesAsync = ref.watch(tournamentEntriesProvider(widget.tournamentId));
    final fixturesAsync = ref.watch(tournamentFixturesProvider(widget.tournamentId));
    final isAdminAsync = ref.watch(isTournamentAdminProvider(widget.tournamentId));
    final standingsAsync = ref.watch(tournamentStandingsProvider(widget.tournamentId));

    return Scaffold(
      appBar: AppBar(
        title: tournamentAsync.when(
          data: (t) => Text(
            t?.name ?? 'Tournament',
            style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
          ),
          loading: () => const Text('Loading...'),
          error: (_, _) => const Text('Tournament'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(tournamentDetailProvider(widget.tournamentId));
              ref.invalidate(tournamentEntriesProvider(widget.tournamentId));
              ref.invalidate(tournamentFixturesProvider(widget.tournamentId));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accent,
          unselectedLabelColor: context.appColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fixtures'),
            Tab(text: 'Table'),
            Tab(text: 'Bracket'),
            Tab(text: 'Stats'),
            Tab(text: 'Teams'),
          ],
        ),
      ),
      body: tournamentAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(tournamentDetailProvider(widget.tournamentId)),
        ),
        data: (tournament) {
          if (tournament == null) {
            return const EmptyState(title: 'Tournament not found');
          }

          final entries = entriesAsync.valueOrNull ?? [];
          final fixtures = fixturesAsync.valueOrNull ?? [];
          final isAdmin = isAdminAsync.valueOrNull ?? false;

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Overview
              _buildOverviewTab(tournament, entries, fixtures, isAdmin),

              // Tab 2: Fixtures
              _buildFixturesTab(tournament, fixtures, entries, isAdmin),

              // Tab 3: Table (Standings)
              _buildStandingsTab(tournament, standingsAsync),

              // Tab 4: Bracket (CustomPaint)
              _buildBracketTab(tournament, fixtures, entries),

              // Tab 5: Stats
              _buildStatsTab(tournament, fixtures, entries),

              // Tab 6: Teams / Entries
              _buildTeamsTab(tournament, entries, isAdmin),
            ],
          );
        },
      ),
    );
  }

  // ─── TAB 1: OVERVIEW ───────────────────────────────────────────────────────
  Widget _buildOverviewTab(
    TournamentModel tournament,
    List<TournamentEntry> entries,
    List<TournamentFixture> fixtures,
    bool isAdmin,
  ) {
    final colors = context.appColors;
    final dateFormat = DateFormat('MMMM d, yyyy');
    final user = ref.watch(currentUserProvider);

    final isRegOpen = tournament.status == TournamentStatus.registrationOpen;
    final isAlreadyRegistered = user != null && entries.any((e) => e.playerIds.contains(user.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Registration & Action Callout
          if (isRegOpen) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.win.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.win, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.how_to_reg, color: colors.win, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Registration is Open',
                        style: AppTypography.headline.copyWith(
                          color: colors.win,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entries: ${entries.length}${tournament.maxEntries != null ? ' / ${tournament.maxEntries}' : ''}',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (isAlreadyRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'You are already registered for this tournament',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.win,
                        ),
                      ),
                    )
                  else
                    AppButton(
                      label: 'Register Entry',
                      onPressed: () => RegisterEntrySheet.show(context, tournament),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Admin Draw Trigger Banner
          if (isAdmin && (tournament.status == TournamentStatus.draft || tournament.status == TournamentStatus.registrationOpen || tournament.status == TournamentStatus.registrationClosed)) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: colors.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Organiser Controls',
                        style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate or regenerate bracket/fixtures from approved entries (${entries.length} available).',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Generate Draw',
                    onPressed: () => GenerateDrawDialog.show(
                      context,
                      tournament: tournament,
                      entries: entries,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tournament Information',
                  style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _detailRow('Sport', tournament.sport.toUpperCase()),
                _detailRow('Format', tournament.format.name.toUpperCase()),
                _detailRow('Status', tournament.status.name.toUpperCase()),
                _detailRow('Eligibility Scope', tournament.scope.name.toUpperCase()),
                if (tournament.startDate != null)
                  _detailRow('Start Date', dateFormat.format(tournament.startDate!)),
                if (tournament.endDate != null)
                  _detailRow('End Date', dateFormat.format(tournament.endDate!)),
                if (tournament.registrationDeadline != null)
                  _detailRow('Deadline', dateFormat.format(tournament.registrationDeadline!)),
                _detailRow('Official Event', tournament.isOfficial ? 'Yes (VIT-AP Sports)' : 'Open Tournament'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: colors.textSecondary)),
          Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── TAB 2: FIXTURES ───────────────────────────────────────────────────────
  Widget _buildFixturesTab(
    TournamentModel tournament,
    List<TournamentFixture> fixtures,
    List<TournamentEntry> entries,
    bool isAdmin,
  ) {
    final colors = context.appColors;
    if (fixtures.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'No fixtures generated',
          subtitle: 'Draw has not been conducted yet',
          actionLabel: isAdmin ? 'Generate Draw' : null,
          onAction: isAdmin
              ? () => GenerateDrawDialog.show(
                    context,
                    tournament: tournament,
                    entries: entries,
                  )
              : null,
        ),
      );
    }

    final entryMap = {for (final e in entries) e.id: e};

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: fixtures.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fix = fixtures[index];
        final nameA = fix.entryAId != null ? (entryMap[fix.entryAId]?.displayName ?? 'Entry A') : (fix.isBye ? 'Bye' : 'TBD');
        final nameB = fix.entryBId != null ? (entryMap[fix.entryBId]?.displayName ?? 'Entry B') : (fix.isBye ? 'Bye' : 'TBD');

        final isLive = fix.status == FixtureStatus.live;
        final isCompleted = fix.status == FixtureStatus.completed || fix.status == FixtureStatus.walkover;

        return AppCard(
          onTap: () {
            if (fix.matchId != null) {
              context.push('/matches/${fix.matchId}');
            } else if (isAdmin && fix.entryAId != null && fix.entryBId != null) {
              _showCreateMatchDialog(fix);
            }
          },
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    fix.roundLabel,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.live,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LIVE',
                        style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    Text(
                      fix.status.name.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? colors.win : colors.textTertiary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nameA,
                      style: AppTypography.body.copyWith(
                        fontWeight: fix.winnerEntryId == fix.entryAId ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'vs',
                    style: AppTypography.caption.copyWith(color: colors.textTertiary),
                  ),
                  Expanded(
                    child: Text(
                      nameB,
                      textAlign: TextAlign.end,
                      style: AppTypography.body.copyWith(
                        fontWeight: fix.winnerEntryId == fix.entryBId ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (fix.venue != null || fix.scheduledAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (fix.scheduledAt != null) ...[
                      Icon(Icons.schedule, size: 12, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(fix.scheduledAt!),
                        style: AppTypography.caption.copyWith(fontSize: 11, color: colors.textTertiary),
                      ),
                    ],
                    if (fix.venue != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_outlined, size: 12, color: colors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        fix.venue!,
                        style: AppTypography.caption.copyWith(fontSize: 11, color: colors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCreateMatchDialog(TournamentFixture fix) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Live Match'),
        content: const Text('Initialize this fixture as a live-scoreable match?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Start Match',
            onPressed: () async {
              Navigator.of(ctx).pop();
              final service = ref.read(tournamentServiceProvider);
              final matchId = await service.createMatchForFixture(fix.id);
              ref.invalidate(tournamentFixturesProvider(widget.tournamentId));
              if (mounted) {
                context.push('/matches/$matchId/score');
              }
            },
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: TABLE (STANDINGS) ──────────────────────────────────────────────
  Widget _buildStandingsTab(
    TournamentModel tournament,
    AsyncValue<Map<String, List<TournamentStandingsRow>>> standingsAsync,
  ) {
    return standingsAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (tables) {
        if (tables.isEmpty || tables.values.every((list) => list.isEmpty)) {
          return const Center(
            child: EmptyState(
              title: 'No standings data',
              subtitle: 'Standings will appear once matches conclude',
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: tables.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tables.length > 1) ...[
                    Text(
                      entry.key.toUpperCase(),
                      style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TournamentStandingsTable(
                    sport: tournament.sport,
                    rows: entry.value,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ─── TAB 4: BRACKET ────────────────────────────────────────────────────────
  Widget _buildBracketTab(
    TournamentModel tournament,
    List<TournamentFixture> fixtures,
    List<TournamentEntry> entries,
  ) {
    return KnockoutBracketView(
      fixtures: fixtures,
      entries: entries,
      onFixtureTap: (f) {
        if (f.matchId != null) {
          context.push('/matches/${f.matchId}');
        }
      },
    );
  }

  // ─── TAB 5: STATS ──────────────────────────────────────────────────────────
  Widget _buildStatsTab(
    TournamentModel tournament,
    List<TournamentFixture> fixtures,
    List<TournamentEntry> entries,
  ) {
    final colors = context.appColors;
    final completed = fixtures.where((f) => f.status == FixtureStatus.completed || f.status == FixtureStatus.walkover).length;
    final total = fixtures.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('$completed / $total', style: AppTypography.title.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Matches Played', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('${entries.length}', style: AppTypography.title.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Entrants', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tournament Progress', style: AppTypography.headline.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: total > 0 ? (completed / total) : 0,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  '${total > 0 ? ((completed / total) * 100).toInt() : 0}% completed',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 6: TEAMS / ENTRIES ────────────────────────────────────────────────
  Widget _buildTeamsTab(
    TournamentModel tournament,
    List<TournamentEntry> entries,
    bool isAdmin,
  ) {
    final colors = context.appColors;
    if (entries.isEmpty) {
      return const Center(child: EmptyState(title: 'No registered entries yet'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (entry.seed != null) ...[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${entry.seed}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  entry.displayName,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                entry.status.name.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: entry.status == EntryStatus.approved ? AppColors.win : colors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
