/// VIT-AP Sports — Create tournament screen.
library;

import 'package:flutter/material.dart';

import '../presentation/widgets/create_tournament_sheet.dart';

class CreateTournamentScreen extends StatelessWidget {
  const CreateTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tournament')),
      body: const SafeArea(
        child: SingleChildScrollView(
          child: CreateTournamentSheet(),
        ),
      ),
    );
  }
}
