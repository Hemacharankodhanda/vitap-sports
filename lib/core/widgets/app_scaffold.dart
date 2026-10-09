/// VIT-AP Sports — AppScaffold.
///
/// Base scaffold ensuring consistent screen margins (20px horizontal).
/// Wraps every screen to enforce layout consistency.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: body,
    );
  }
}

/// Extension for consistent padding across screens.
extension ScreenPadding on Widget {
  Widget withScreenPadding() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMargin,
      ),
      child: this,
    );
  }

  Widget withScreenPaddingAll() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: this,
    );
  }
}
