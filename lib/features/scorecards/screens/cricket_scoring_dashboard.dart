/// VIT-AP Sports — Cricket Scoring Dashboard.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../matches/data/models/match_model.dart';
import '../data/models/cricket_scorecard_model.dart';
import '../providers/scorecard_providers.dart';

class CricketScoringDashboard extends ConsumerStatefulWidget {
  const CricketScoringDashboard({
    super.key,
    required this.match,
    required this.initialState,
  });

  final MatchModel match;
  final CricketScorecardState? initialState;

  @override
  ConsumerState<CricketScoringDashboard> createState() =>
      _CricketScoringDashboardState();
}

class _CricketScoringDashboardState
    extends ConsumerState<CricketScoringDashboard> {
  late CricketScorecardState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? CricketScorecardState();
    
    // Parse overs from match format if possible (e.g. "20 Overs - Friendly")
    if (_state.totalOvers == null && widget.match.format != null) {
      final matchStr = widget.match.format!.toLowerCase();
      if (matchStr.contains('overs')) {
        final numStr = matchStr.split(' ')[0];
        _state = CricketScorecardState(
          totalOvers: int.tryParse(numStr),
          currentInnings: _state.currentInnings,
          innings: _state.innings,
        );
      }
    }
  }

  Future<void> _saveState() async {
    setState(() {}); // trigger rebuild instantly for UI responsiveness
    
    try {
      await ref.read(scorecardServiceProvider).updateScorecardData(
            widget.match.id,
            _state.toJson(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save scorecard: $e')),
        );
      }
    }
  }
  
  void _startInnings() {
    final homeTeamId = widget.match.participants.where((p) => p.side == 'home').firstOrNull?.teamId;
    final awayTeamId = widget.match.participants.where((p) => p.side == 'away').firstOrNull?.teamId;
    
    if (homeTeamId == null || awayTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select playing squads for both teams first.')),
      );
      return;
    }
    
    final newInnings = CricketInnings(
      battingTeamId: homeTeamId, // Hardcoded to home team for 1st innings simplicity
      bowlingTeamId: awayTeamId,
    );
    
    setState(() {
      final newInningsList = List<CricketInnings>.from(_state.innings)..add(newInnings);
      _state = CricketScorecardState(
        totalOvers: _state.totalOvers,
        currentInnings: newInningsList.length - 1,
        innings: newInningsList,
      );
    });
    _saveState();
  }

  void _addRun(int runs) {
    final active = _state.activeInnings;
    if (active == null || active.isComplete) return;

    final newEvent = BallEvent(runs: runs);
    
    final updatedOver = List<BallEvent>.from(active.currentOver)..add(newEvent);
    
    // Simplified: Just add runs to total, no individual tracking for now
    final updatedInnings = CricketInnings(
      battingTeamId: active.battingTeamId,
      bowlingTeamId: active.bowlingTeamId,
      totalRuns: active.totalRuns + runs,
      totalWickets: active.totalWickets,
      totalOvers: active.totalOvers, // Need logic to increment overs
      currentOver: updatedOver,
      extras: active.extras,
      fallOfWickets: active.fallOfWickets,
    );
    
    _state.innings[_state.currentInnings] = updatedInnings;
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildScoreHeader(isDark),
        const SizedBox(height: AppSpacing.lg),
        if (_state.activeInnings == null)
          AppButton(
            label: 'Start 1st Innings',
            onPressed: _startInnings,
          )
        else ...[
          _buildCurrentOver(),
          const SizedBox(height: AppSpacing.lg),
          _buildScoringKeypad(),
        ],
      ],
    );
  }
  
  Widget _buildScoreHeader(bool isDark) {
    final active = _state.activeInnings;
    return AppCard(
      child: Column(
        children: [
          Text(
            'Cricket Scorecard',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (active != null) ...[
             Text(
              '${active.totalRuns}/${active.totalWickets}',
              style: AppTypography.headline.copyWith(fontSize: 36),
            ),
            Text(
              'Overs: ${active.totalOvers} ${active.totalOvers > 0 ? '' : '(${active.currentOver.length} balls)'}',
              style: AppTypography.title,
            ),
          ] else 
             Text('Match hasn\'t started', style: AppTypography.headline),
        ],
      ),
    );
  }
  
  Widget _buildCurrentOver() {
    final active = _state.activeInnings;
    if (active == null) return const SizedBox.shrink();
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Over', style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: active.currentOver.map((e) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: e.isWicket ? Colors.red : (e.runs >= 4 ? Colors.green : Colors.grey.shade300),
                child: Text(
                  e.displayString,
                  style: TextStyle(
                    color: e.isWicket || e.runs >= 4 ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoringKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreButton(label: '0', onTap: () => _addRun(0)),
            _ScoreButton(label: '1', onTap: () => _addRun(1)),
            _ScoreButton(label: '2', onTap: () => _addRun(2)),
            _ScoreButton(label: '3', onTap: () => _addRun(3)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreButton(label: '4', onTap: () => _addRun(4), color: Colors.green),
            _ScoreButton(label: '6', onTap: () => _addRun(6), color: Colors.blue),
            _ScoreButton(label: 'W', onTap: () {
               // Wicket logic placeholder
            }, color: Colors.red),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(child: AppButton(label: 'Undo Last', variant: AppButtonVariant.secondary, onPressed: () {})),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: AppButton(label: 'End Over', onPressed: () {})),
          ],
        )
      ],
    );
  }
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({required this.label, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: EdgeInsets.zero,
        minimumSize: const Size(64, 64),
        backgroundColor: color,
        foregroundColor: color != null ? Colors.white : null,
      ),
      child: Text(label, style: AppTypography.title.copyWith(color: color != null ? Colors.white : null)),
    );
  }
}
