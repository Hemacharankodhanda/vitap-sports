import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_theme_provider.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenMargin),
        children: [
          Text('APPEARANCE', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          _buildModeTile(
            context: context,
            title: 'System Default',
            icon: Icons.brightness_auto,
            isSelected: themeState.themeMode == ThemeMode.system,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.system),
          ),
          _buildModeTile(
            context: context,
            title: 'Light',
            icon: Icons.light_mode,
            isSelected: themeState.themeMode == ThemeMode.light,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.light),
          ),
          _buildModeTile(
            context: context,
            title: 'Dark',
            icon: Icons.dark_mode,
            isSelected: themeState.themeMode == ThemeMode.dark,
            onTap: () => themeNotifier.setThemeMode(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.xxl),
          
          Text('ACCENT COLOR', style: AppTypography.overline),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: AppAccentColor.values.map((colorMode) {
              final isSelected = themeState.accentColor == colorMode;
              return GestureDetector(
                onTap: () => themeNotifier.setAccentColor(colorMode),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorMode.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isSelected ? Theme.of(context).colorScheme.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title, 
        style: AppTypography.body.copyWith(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )
      ),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.inputRadius)),
      tileColor: isSelected ? (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant) : null,
    );
  }
}
