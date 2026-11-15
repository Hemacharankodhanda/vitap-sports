# VIT-AP Sports — Apple UI Redesign Design Specification

## 1. Design Direction & Core Philosophy
The redesign of VIT-AP Sports transitions the application to a calm, spacious, content-first aesthetic inspired by Apple design language.
- **Monochrome Foundation:** Stark black and white contrasted with subtle, velvety gray surfaces (`#F5F5F7` light, `#1C1C1E` dark).
- **Zero Decorative Noise:** No emojis, gradients, glows, skeuomorphic bevels, or heavy drop shadows. Elevation is strictly `0` across cards, dialogs, and sheets.
- **Hairline Surface Separation:** Depth and boundaries are articulated using surface tonal contrast and 0.5px–1.0px hairline dividers (`#D2D2D7` light, `#38383A` dark).
- **Typography as Interface:** High-legibility Inter typeface with tighter tracking on large titles and tabular figures on all numerical statistics.
- **Tactile, Responsive Motion:** Smooth cubic bezier transitions with haptic feedback and strict respect for system reduced-motion preferences.

---

## 2. Color Palette & Semantic Tokens

### Monochrome Palette
| Token | Light Value | Dark Value | Purpose |
| :--- | :--- | :--- | :--- |
| `background` | `#FFFFFF` | `#000000` | Global scaffold and viewport background |
| `surface` | `#F5F5F7` | `#1C1C1E` | Cards, text field fills, grouped tables |
| `surfaceElevated` | `#FFFFFF` | `#2C2C2E` | Modals, bottom sheets, dialogs, popups |
| `fillSecondary` | `#E8E8ED` | `#2C2C2E` | Secondary buttons, segmented track, unselected chips |
| `textPrimary` | `#1D1D1F` | `#F5F5F7` | Headlines, primary text, prominent stats |
| `textSecondary` | `#6E6E73` | `#A1A1A6` | Captions, subtitles, secondary metadata |
| `textTertiary` | `#86868B` | `#86868B` | Placeholders, disabled states only |
| `divider` | `#D2D2D7` | `#38383A` | Hairline dividers (0.5 to 1.0 px) |
| `primaryFill` | `#1D1D1F` | `#F5F5F7` | Primary pill buttons, selected chip, active switch track |
| `onPrimary` | `#FFFFFF` | `#1D1D1F` | Text and icons placed on primary fill |
| `scrim` | `Color(0x66000000)` | `Color(0x66000000)` | 40% black overlay behind dialogs & sheets |

### Semantic Status Tokens
Used only where state conveys functional meaning (never as large decorative fills):
- **Live / Active:** `#FF3B30` (Light) / `#FF453A` (Dark). Container: 10% alpha (Light) / 16% alpha (Dark).
- **Win / Success:** `#248A3D` (Light) / `#30D158` (Dark). Container: 10% alpha (Light) / 16% alpha (Dark).
- **Loss / Error:** `#D70015` (Light) / `#FF453A` (Dark). Container: 10% alpha (Light) / 16% alpha (Dark).
- **Warning / Paused:** `#B25000` (Light) / `#FF9F0A` (Dark). Container: 10% alpha (Light) / 16% alpha (Dark).
- **Medal Badges:** Gold (`#D97706`), Silver (`#64748B`), Bronze (`#B45309`).

---

## 3. Typography Scale (Inter)
All numerals enforce `FontFeature.tabularFigures()` so sports scoreboards, clocks, and tables remain perfectly aligned without jitter during updates.

| Style Name | Size / Line Height | Weight | Tracking (Letter Spacing) | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `displayXL` | 48 / 52 | w700 | -1.0 px (-2%) | Large hero scores, timer numbers |
| `largeTitle` | 34 / 40 | w700 | -0.7 px (-2%) | Screen top titles (collapsing header) |
| `title` | 24 / 30 | w600 | -0.5 px (-2%) | Section headers, card titles |
| `headline` | 17 / 24 | w600 | -0.2 px (-1%) | Primary buttons, row titles |
| `body` | 16 / 24 | w400 | 0.0 px | Body text, descriptions |
| `callout` | 15 / 22 | w400 / w600 | 0.0 px | Compact button labels, chip text |
| `footnote` | 13 / 18 | w400 | 0.0 px | Secondary metadata, helper text |
| `caption` | 12 / 16 | w500 / w600 | 0.0 px | Status badges, timestamps |

*Invariant:* All text styles survive up to 200% dynamic text scale (`TextScaler.linear(2.0)`) without vertical clipping or horizontal row overflow.

---

## 4. Spacing, Radii & Grid System

### 8pt Spatial Grid
- Spacings: `4` (xs - micro), `8` (sm), `16` (md), `24` (lg), `32` (xl), `40` (xxl), `56` (section).
- Screen Horizontal Margins:
  - Compact (`< 600 dp`): `24 dp`
  - Medium (`600–1023 dp`): `32 dp`
  - Expanded (`≥ 1024 dp`): `40 dp`
- Maximum Content Reading Constraint:
  - Text & Form Columns: `680 dp`
  - Grids & Full Tables: `1120 dp`

### Corner Radii
- Pill buttons & Chips: `999 dp` (`StadiumBorder`)
- Text Input Fields: `14 dp`
- Standard Cards: `24 dp` (Compact inner cards: `16 dp`)
- Bottom Sheets: `28 dp` (Top left & Top right)
- Dialogs: `24 dp`
- Avatars: `Circle` for players; `12 dp` squircle for teams

---

## 5. Motion & Haptics Specification

- **Standard Timing Curve:** Apple standard ease curve `Cubic(0.28, 0.11, 0.32, 1.0)`.
- **Duration Scale:**
  - Press Feedback (`press`): `120 ms`
  - State Changes & Segmented Thumb Slide (`stateChange`): `250 ms`
  - Page & Sheet Transitions (`pageOrSheet`): `350 ms`
- **Reduced Motion Support:**
  - Checked via `AppMotion.shouldReduceMotion(context)`.
  - When active, all durations collapse to `Duration.zero` via `AppMotion.duration(context, duration)`.
- **Haptics:**
  - Primary button taps: `HapticFeedback.lightImpact()`.
  - Segmented option selection: `HapticFeedback.selectionClick()`.
  - Scorer live input keys: `HapticFeedback.lightImpact()`.

---

## 6. Component Specification

### AppButton
- Full pill (`StadiumBorder`). Minimum touch target 48x48dp.
- Pressed state: animated scale `0.98` with subtle highlight overlay.
- Variants:
  - `primary`: `primaryFill` with `onPrimary` text.
  - `secondary`: `fillSecondary` with `textPrimary` text.
  - `outlined`: transparent background with 1.0px `divider` border.
  - `text`: borderless, text link style.
  - `destructive`: loss-tinted container with loss text; solid loss fill in confirmation dialogs.
- Accessibility: Exposes `Semantics(button: true, enabled: isEnabled, label: label)`.

### AppCard & AppGroupedCard
- Radius 24, filled with `colors.surface`, borderless, elevation 0.
- Tappable cards receive smooth `onTap` highlight without ink splatter.
- Grouped cards: Inset hairline dividers (0.5px) separating list rows.
- No card inside a card: nested sections use `fillSecondary` or hairline separators.

### AppTextField
- Radius 14, height 52, filled with `colors.surface`.
- Borderless at rest; 1.5px `textPrimary` outline on focus; 1px `loss` outline on validation error.
- Stacked `callout` label above; `footnote` error/helper below.

### AppSegmented
- Pill container in `fillSecondary` with 3dp inset.
- Animated sliding white thumb (light) / elevated gray thumb (dark) with 250ms cubic curve.
- 2 to 4 options; selection click haptic feedback on change; collapses to zero duration under reduced motion.

### AppSwitch
- Apple standard styling: `primaryFill` active track with `onPrimary` thumb; `fillSecondary` inactive track with soft gray thumb.

### StatusLabel
- Height 24 pill.
- `Live`: `liveContainer` background, live text, pulsing 6px live dot.
- `Upcoming`: `fillSecondary` background, primary text.
- `Completed`: `surface` background, secondary text.
- `Paused`: `warningContainer` background, warning text.

### FrostedBar & FrostedAppBar
- 80% opacity background with backdrop blur (`sigma: 20.0`).
- Hairline border divider (0.5px).
- Wrapped in `RepaintBoundary` to prevent full widget tree repaints during scrolling.

### AdaptiveScaffold
- Responsive navigation shell:
  - Compact (`< 600 dp`): Bottom frosted bar with 24px icons and always-visible labels.
  - Medium (`600–1023 dp`) and Expanded (`≥ 1024 dp`): Left navigation rail with hairline divider.

---

## 7. Voice, Tone & Writing Style
- **Zero Emojis:** Prohibited in all UI strings, labels, alerts, snackbars, and empty states. Emojis are replaced with semantic typography or clean vector icons (`Icons.*`).
- **Sentence Case:** All titles, buttons, and section headers use clean Sentence case (e.g., "Create tournament", "Live matches", "Player performance").
- **Clarity & Brevity:** Crisp, factual notifications (e.g., "Match concluded", "Draw generated", "Squad saved").
