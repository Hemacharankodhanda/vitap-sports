/// VIT-AP Sports — Spacing constants on 8pt grid.
///
/// Every margin, padding, and gap in the app must use one of these values.
/// No arbitrary spacing values allowed.
library;

class AppSpacing {
  AppSpacing._();

  // Base grid unit
  static const double grid = 8.0;

  // Spacing scale (8pt grid)
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Screen edge margin — consistent across all screens
  static const double screenMargin = 20.0;

  // Component-specific spacing
  static const double cardPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double cardElevation = 1.0;

  static const double buttonHeightPrimary = 48.0;
  static const double buttonHeightSecondary = 40.0;
  static const double buttonRadius = 12.0;

  static const double inputHeight = 52.0;
  static const double inputRadius = 12.0;

  static const double chipHeight = 40.0;
  static const double chipRadius = 20.0;

  // Touch target minimums (HIG requirement)
  static const double minTouchTarget = 44.0;

  // Icon sizes — consistent per context
  static const double iconNav = 24.0;
  static const double iconInline = 18.0;
  static const double iconLarge = 32.0;

  // Avatar sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 48.0;
  static const double avatarLarge = 72.0;
  static const double avatarXLarge = 96.0;

  // Bottom nav bar
  static const double bottomNavHeight = 64.0;

  // Section spacing
  static const double sectionGap = 24.0;
  static const double groupGap = 12.0;
}
