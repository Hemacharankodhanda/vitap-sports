/// VIT-AP Sports — Tournament detail screen.
library;

import 'package:flutter/material.dart';

import '../presentation/screens/tournament_detail_screen.dart' as p;

class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({required this.tournamentId, super.key});
  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return p.TournamentDetailScreen(tournamentId: tournamentId);
  }
}
