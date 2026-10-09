/// VIT-AP Sports — Player selection dialog for scoring.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../matches/data/models/match_model.dart';

class PlayerSelectionDialog extends StatelessWidget {
  const PlayerSelectionDialog({
    super.key,
    required this.title,
    required this.participants,
    required this.onSelected,
  });

  final String title;
  final List<MatchParticipant> participants;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: participants.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('No players available in this squad.'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final player = participants[index];
                  // Only show users who are confirmed in the squad
                  if (player.userId == null || player.rsvpStatus != 'confirmed') {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(player.userName ?? 'Unknown Player'),
                    onTap: () {
                      onSelected(player.userId!);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
