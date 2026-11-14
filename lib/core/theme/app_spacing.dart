/// VIT-AP Sports — Spacing and Radius Scale (Apple Design System).
///
/// 8pt grid (4 only for internal alignment): 4, 8, 16, 24, 32, 40, 56.
library;

class AppSpacing {
  AppSpacing._();

  // Base 8pt Grid
  static const double grid = 8.0;

  // Spacing Scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 56.0;

  // Screen Padding
  static const double screenMarginCompact = 24.0;
  static const double screenMarginMedium = 32.0;
  static const double screenMarginExpanded = 40.0;
  static const double screenMargin = screenMarginCompact;

  // Section & Card Spacing
  static const double sectionGap = 40.0;
  static const double sectionGapLarge = 56.0;
  static const double groupGap = 16.0;
  static const double cardPadding = 20.0;
  static const double cardPaddingLarge = 24.0;
  static const double cardElevation = 0.0;

  // Control Radii
  static const double radiusButton = 999.0; // Pill
  static const double radiusInput = 14.0;
  static const double radiusCard = 24.0;
  static const double radiusCardInner = 16.0;
  static const double radiusSheet = 28.0; // Top
  static const double radiusDialog = 24.0;
  static const double radiusChip = 999.0; // Pill
  static const double radiusSegmented = 999.0; // Pill
  static const double radiusAvatarTeam = 12.0;

  // Backward-compatible radius aliases
  static const double buttonRadius = radiusButton;
  static const double cardRadius = radiusCard;
  static const double inputRadius = radiusInput;
  static const double chipRadius = radiusChip;
  static const double radiusSheetTop = radiusSheet;
  static const double radiusFull = 999.0;
  static const double sheetPadding = 24.0;

  // Sizing & Heights
  static const double buttonHeightPrimary = 48.0;
  static const double buttonHeightCompact = 40.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonHeightSecondary = 40.0;
  static const double inputHeight = 52.0;
  static const double chipHeight = 36.0;
  static const double statusBadgeHeight = 24.0;
  static const double minTouchTarget = 48.0;
  static const double scorerKeyHeightMin = 64.0;
  static const double scorerKeyHeightMax = 80.0;

  // Icon Sizes
  static const double iconNav = 24.0;
  static const double iconInline = 18.0;
  static const double iconLarge = 32.0;

  // Avatar Sizes
  static const double avatarSmall = 32.0;
  static const double avatarMedium = 40.0;
  static const double avatarLarge = 56.0;
  static const double avatarXLarge = 72.0;

  // Bars
  static const double bottomNavHeight = 64.0;
  static const double topBarHeight = 56.0;
}
