/// VIT-AP Sports — Theme Settings Screen (Apple Design System).
///
/// Clean monochrome appearance switcher with AppSegmented control (System / Light / Dark),
/// preview surfaces, and accent color selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_provider.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_segmented.dart';
import '../../../core/widgets/frosted_bar.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: FrostedAppBar(
        title: Text(
          'Appearance',
          style: AppTypography.title.copyWith(color: colors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenMargin,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Section: Appearance Mode
          Text(
            'APPEARANCE',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // AppSegmented control for System / Light / Dark
          AppSegmented<ThemeMode>(
            options: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
            selected: themeState.themeMode,
            height: 44,
            labelBuilder: (mode) {
              switch (mode) {
                case ThemeMode.system:
                  return 'System';
                case ThemeMode.light:
                  return 'Light';
                case ThemeMode.dark:
                  return 'Dark';
              }
            },
            iconBuilder: (mode) {
              IconData icon;
              switch (mode) {
                case ThemeMode.system:
                  icon = Icons.brightness_auto_rounded;
                case ThemeMode.light:
                  icon = Icons.light_mode_rounded;
                case ThemeMode.dark:
                  icon = Icons.dark_mode_rounded;
              }
              return Icon(icon, size: 16);
            },
            onSelected: (mode) => themeNotifier.setThemeMode(mode),
          ),
          const SizedBox(height: AppSpacing.md),

          // Detailed Grouped Card for Modes
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildModeRow(
                  context: context,
                  title: 'System Default',
                  subtitle: 'Match system light and dark schedule',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: themeState.themeMode == ThemeMode.system,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
                ),
                Divider(height: 1, thickness: 0.5, indent: 56, color: colors.divider),
                _buildModeRow(
                  context: context,
                  title: 'Light',
                  subtitle: 'Crisp white surfaces with dark typography',
                  icon: Icons.light_mode_rounded,
                  isSelected: themeState.themeMode == ThemeMode.light,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
                ),
                Divider(height: 1, thickness: 0.5, indent: 56, color: colors.divider),
                _buildModeRow(
                  context: context,
                  title: 'Dark',
                  subtitle: 'Deep OLED black with soft gray surfaces',
                  icon: Icons.dark_mode_rounded,
                  isSelected: themeState.themeMode == ThemeMode.dark,
                  onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Section: Accent Tint
          Text(
            'ACCENT TINT',
            style: AppTypography.caption.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          AppCard(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: AppAccentColor.values.map((colorMode) {
                final isSelected = themeState.accentColor == colorMode;
                return GestureDetector(
                  onTap: () => themeNotifier.setAccentColor(colorMode),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorMode.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: colors.textPrimary.withAlpha(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.fillSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: colors.textPrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.footnote.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, color: colors.primaryFill, size: 20),
          ],
        ),
      ),
    );
  }
}
