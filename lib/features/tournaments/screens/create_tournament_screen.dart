/// VIT-AP Sports — Create tournament screen.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/widgets/frosted_bar.dart';
import '../presentation/widgets/create_tournament_sheet.dart';

class CreateTournamentScreen extends StatelessWidget {
  const CreateTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: Text('Create Tournament')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxReadingWidth),
            child: const SingleChildScrollView(
              child: CreateTournamentSheet(),
            ),
          ),
        ),
      ),
    );
  }
}
