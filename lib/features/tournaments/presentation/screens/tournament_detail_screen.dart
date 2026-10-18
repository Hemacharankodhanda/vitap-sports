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
import '../../../teams/providers/team_providers.dart';
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
  String _teamsFilter = 'all';
  String? _actionInProgressEntryId;

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

  Future<void> _updateStatus(TournamentModel tournament, TournamentStatus newStatus) async {
    try {
      final service = ref.read(tournamentServiceProvider);
      await service.updateTournamentStatus(
        tournamentId: tournament.id,
        status: newStatus,
      );
      ref.invalidate(tournamentDetailProvider(tournament.id));
      ref.invalidate(tournamentsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tournament status changed to ${newStatus.name.toUpperCase()}'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    }
  }

  Future<void> _approveEntry(TournamentModel tournament, TournamentEntry entry) async {
    setState(() => _actionInProgressEntryId = entry.id);
    try {
      final service = ref.read(tournamentServiceProvider);
      await service.approveEntry(
        tournamentId: tournament.id,
        entryId: entry.id,
      );
      ref.invalidate(tournamentEntriesProvider(tournament.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved "${entry.displayName}" to join ${tournament.name}'),
            backgroundColor: AppColors.win,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving entry: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgressEntryId = null);
      }
    }
  }

  Future<void> _rejectEntry(TournamentModel tournament, TournamentEntry entry) async {
    final isApproved = entry.status == EntryStatus.approved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApproved ? 'Remove Team?' : 'Decline Application?'),
        content: Text(
          isApproved
              ? 'Are you sure you want to remove "${entry.displayName}" from this tournament? Any matches drawn with this team will also be deleted.'
              : 'Are you sure you want to decline "${entry.displayName}" from joining this tournament?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.loss),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isApproved ? 'Remove' : 'Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _actionInProgressEntryId = entry.id);
    try {
      final service = ref.read(tournamentServiceProvider);
      await service.rejectEntry(
        tournamentId: tournament.id,
        entryId: entry.id,
      );
      ref.invalidate(tournamentEntriesProvider(tournament.id));
      ref.invalidate(tournamentFixturesProvider(tournament.id));
      ref.invalidate(tournamentStandingsProvider(tournament.id));
      ref.invalidate(tournamentDetailProvider(tournament.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved
                  ? 'Removed "${entry.displayName}" and deleted drawn matches'
                  : 'Declined "${entry.displayName}" application',
            ),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining entry: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.loss,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgressEntryId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentDetailProvider(widget.tournamentId));
    final entriesAsync = ref.watch(tournamentEntriesProvider(widget.tournamentId));
    final fixturesAsync = ref.watch(tournamentFixturesProvider(widget.tournamentId));
    final isAdminAsync = ref.watch(isTournamentAdminProvider(widget.tournamentId));
    final standingsAsync = ref.watch(tournamentStandingsProvider(widget.tournamentId));

    final entries = entriesAsync.valueOrNull ?? [];
    final isAdmin = isAdminAsync.valueOrNull ?? false;
    final pendingCount = entries.where((e) => e.status == EntryStatus.pending).length;

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
          tabs: [
            const Tab(text: 'Overview'),
            const Tab(text: 'Fixtures'),
            const Tab(text: 'Table'),
            const Tab(text: 'Bracket'),
            const Tab(text: 'Stats'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Teams'),
                  if (pendingCount > 0 && isAdmin) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.loss,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
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
              _buildBracketTab(tournament, fixtures, entries, isAdmin),

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
    final userTeamsAsync = ref.watch(userTeamsProvider);
    final userTeamIds = userTeamsAsync.valueOrNull?.map((t) => t.id).toSet() ?? <String>{};

    final isRegOpen = tournament.status == TournamentStatus.registrationOpen;
    final userEntry = user == null
        ? null
        : entries.cast<TournamentEntry?>().firstWhere(
            (e) =>
                e != null &&
                (e.playerIds.contains(user.id) ||
                    e.userId == user.id ||
                    e.registeredBy == user.id ||
                    (e.teamId != null && userTeamIds.contains(e.teamId))),
            orElse: () => null,
          );

    final approvedEntries = entries.where((e) => e.status == EntryStatus.approved).toList();
    final pendingCount = entries.where((e) => e.status == EntryStatus.pending).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Organiser Pending Applications Alert Banner
          if (isAdmin && pendingCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade700, width: 1.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.notification_important, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$pendingCount Team Application${pendingCount > 1 ? 's' : ''} Pending',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          'Review and approve teams before generating tournament draws.',
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber.shade900,
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      setState(() => _teamsFilter = 'pending');
                      _tabController.animateTo(5);
                    },
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                    'Approved: ${approvedEntries.length}${tournament.maxEntries != null ? ' / ${tournament.maxEntries}' : ''}'
                    '${pendingCount > 0 ? ' ($pendingCount awaiting approval)' : ''}',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (userEntry != null) ...[
                    if (userEntry.status == EntryStatus.pending)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_top, color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Application Pending Approval',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  Text(
                                    'Your entry for "${userEntry.displayName}" has been submitted. Awaiting organiser approval.',
                                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (userEntry.status == EntryStatus.approved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.win.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.win, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: colors.win, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registered & Approved',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.win,
                                    ),
                                  ),
                                  Text(
                                    'Your team "${userEntry.displayName}" is confirmed for this tournament.',
                                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (userEntry.status == EntryStatus.rejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.loss.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.loss, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: colors.loss, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your application for "${userEntry.displayName}" was declined by the organiser.',
                                style: AppTypography.caption.copyWith(color: colors.loss, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    AppButton(
                      label: 'Apply to Join',
                      onPressed: () => RegisterEntrySheet.show(context, tournament),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Organiser Controls Banner
          if (isAdmin) ...[
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
                      const Spacer(),
                      _buildStatusBadge(
                        tournament.status == TournamentStatus.registrationOpen || tournament.status == TournamentStatus.live
                            ? EntryStatus.approved
                            : EntryStatus.pending,
                        colors,
                        customLabel: tournament.status.name.toUpperCase(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${tournament.status.name.toUpperCase()} • '
                    '${approvedEntries.length} approved entry${approvedEntries.length == 1 ? '' : 'ies'}'
                    '${pendingCount > 0 ? ', $pendingCount awaiting review' : ''}.',
                    style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (tournament.status == TournamentStatus.draft)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.win,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.how_to_reg, size: 18),
                          label: const Text('Open Registration'),
                          onPressed: () => _updateStatus(tournament, TournamentStatus.registrationOpen),
                        )
                      else if (tournament.status == TournamentStatus.registrationOpen)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_clock, size: 18),
                          label: const Text('Close Registration'),
                          onPressed: () => _updateStatus(tournament, TournamentStatus.registrationClosed),
                        )
                      else if (tournament.status == TournamentStatus.registrationClosed)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.lock_open, size: 18),
                          label: const Text('Reopen Registration'),
                          onPressed: () => _updateStatus(tournament, TournamentStatus.registrationOpen),
                        ),
                      if (tournament.status == TournamentStatus.live)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.win,
                            side: BorderSide(color: colors.win),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Mark Completed'),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Complete Tournament?'),
                                content: const Text('Mark this tournament as completed and finalize standings & honours?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.win,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Complete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _updateStatus(tournament, TournamentStatus.completed);
                            }
                          },
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.account_tree_outlined, size: 18),
                        label: Text(fixtures.isEmpty ? 'Generate Draw' : 'Regenerate Draw'),
                        onPressed: () => GenerateDrawDialog.show(
                          context,
                          tournament: tournament,
                          entries: approvedEntries,
                        ),
                      ),
                      if (pendingCount > 0)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.pending_actions, size: 18),
                          label: Text('Review Pending ($pendingCount)'),
                          onPressed: () {
                            setState(() => _teamsFilter = 'pending');
                            _tabController.animateTo(5);
                          },
                        ),
                    ],
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
                context.push('/matches/$matchId');
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
    bool isAdmin,
  ) {
    if (tournament.format == TournamentFormat.league) {
      return const Center(
        child: EmptyState(
          icon: Icons.table_chart_outlined,
          title: 'League Format Tournament',
          subtitle: 'League tournaments do not use knockout elimination brackets. Check the Table and Fixtures tabs for round-robin standings and matches.',
        ),
      );
    }

    return KnockoutBracketView(
      fixtures: fixtures,
      entries: entries,
      onFixtureTap: (f) {
        if (f.matchId != null) {
          context.push('/matches/${f.matchId}');
        } else if (isAdmin && f.entryAId != null && f.entryBId != null) {
          _showCreateMatchDialog(f);
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

    final pendingEntries = entries.where((e) => e.status == EntryStatus.pending).toList();
    final approvedEntries = entries.where((e) => e.status == EntryStatus.approved).toList();

    final filteredEntries = entries.where((e) {
      if (_teamsFilter == 'pending') return e.status == EntryStatus.pending;
      if (_teamsFilter == 'approved') return e.status == EntryStatus.approved;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter row when organiser or multiple statuses exist
        if (isAdmin || pendingEntries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All (${entries.length})'),
                    selected: _teamsFilter == 'all',
                    onSelected: (_) => setState(() => _teamsFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        if (pendingEntries.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pendingEntries.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: _teamsFilter == 'pending',
                    onSelected: (_) => setState(() => _teamsFilter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('Approved (${approvedEntries.length})'),
                    selected: _teamsFilter == 'approved',
                    onSelected: (_) => setState(() => _teamsFilter = 'approved'),
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: filteredEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No ${_teamsFilter} entries found.',
                      style: AppTypography.body.copyWith(color: colors.textSecondary),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEntries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = filteredEntries[index];
                    final isProcessing = _actionInProgressEntryId == entry.id;

                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (entry.seed != null) ...[
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
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
                                const SizedBox(width: 10),
                              ] else ...[
                                Icon(
                                  entry.kind == EntryKind.team ? Icons.groups_outlined : Icons.person_outline,
                                  color: colors.accent,
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: InkWell(
                                  onTap: entry.teamId != null
                                      ? () => context.push('/teams/${entry.teamId}')
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.displayName,
                                        style: AppTypography.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: entry.teamId != null ? colors.accent : colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        entry.kind == EntryKind.team ? 'Team Entrant' : 'Solo Entrant',
                                        style: AppTypography.caption.copyWith(color: colors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildStatusBadge(entry.status, colors),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (entry.teamId != null)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.info_outline, size: 16),
                                  label: const Text('Team Info'),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: () => context.push('/teams/${entry.teamId}')
                                ),
                              const Spacer(),
                              if (isAdmin && entry.status == EntryStatus.pending) ...[
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.loss),
                                  label: const Text('Decline', style: TextStyle(color: AppColors.loss)),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    side: const BorderSide(color: AppColors.loss, width: 0.8),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  ),
                                  onPressed: isProcessing ? null : () => _rejectEntry(tournament, entry),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  icon: isProcessing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.check, size: 16),
                                  label: const Text('Approve'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.win,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  onPressed: isProcessing ? null : () => _approveEntry(tournament, entry),
                                ),
                              ] else if (isAdmin && entry.status == EntryStatus.approved) ...[
                                TextButton.icon(
                                  icon: const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.loss),
                                  label: Text('Remove', style: AppTypography.caption.copyWith(color: AppColors.loss)),
                                  onPressed: isProcessing ? null : () => _rejectEntry(tournament, entry),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(EntryStatus status, AppColorsExtension colors, {String? customLabel}) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case EntryStatus.approved:
        bg = colors.win.withValues(alpha: 0.12);
        fg = colors.win;
        label = 'APPROVED';
        break;
      case EntryStatus.pending:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade900;
        label = 'PENDING';
        break;
      case EntryStatus.rejected:
        bg = colors.loss.withValues(alpha: 0.12);
        fg = colors.loss;
        label = 'DECLINED';
        break;
      case EntryStatus.waitlisted:
        bg = colors.surface;
        fg = colors.textSecondary;
        label = 'WAITLISTED';
        break;
      case EntryStatus.withdrawn:
        bg = colors.surface;
        fg = colors.textSecondary;
        label = 'WITHDRAWN';
        break;
      case EntryStatus.disqualified:
        bg = colors.loss.withValues(alpha: 0.12);
        fg = colors.loss;
        label = 'DISQUALIFIED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        customLabel ?? label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
