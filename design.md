# Build Prompt: VIT-AP Sports — HIG-Grade Design Pass (Flutter + Supabase)

Copy everything below into Antigravity. This applies Apple Human Interface Guidelines-style rigor to a Flutter/Android app — the platform is Android/Material, but the design discipline (spacing, hierarchy, motion, accessibility) follows Apple's standard of polish.

---

## Project Overview

Build/refine **"VIT-AP Sports"** (Flutter + Supabase) to meet Apple HIG-level design quality: clarity, deference, depth. Every screen should feel intentional, calm, and precise — never cluttered, never ambiguous, never inconsistent.

---

## Core HIG Principles to Apply

**1. Clarity**
- Text must be legible at every size used — no caption text below 12sp, no body text below 14sp.
- Icons must be immediately recognizable and used only for their conventional meaning (don't repurpose a "heart" icon for something other than favorite/like).
- Only essential UI is visible by default — secondary actions live behind a clear but unobtrusive affordance (overflow menu, long-press, swipe), never crowding the primary view.

**2. Deference**
- UI defers to content: scores, team names, and match data are the visual focus — chrome (borders, dividers, background decoration) stays minimal and never competes with content.
- Avoid heavy shadows or borders around every element; use whitespace and subtle elevation instead to separate content.

**3. Depth**
- Use layering purposefully: modals/sheets should feel like they sit above the base layer (subtle scrim + elevation), and transitions between layers should reflect that spatial relationship (slide up for sheets, not fade).

---

## Spacing & Layout (non-negotiable, apply to every screen)

- 8pt grid system for all spacing and sizing — no arbitrary padding values.
- Minimum touch target: 44x44pt for every tappable element (buttons, icons, list rows) — no exceptions, even for dense list rows.
- Consistent screen margins: 16-20pt from screen edge on every screen, matched exactly across the whole app.
- Related elements grouped with tighter spacing (8-12pt); unrelated sections separated with larger spacing (24-32pt) — spacing itself should communicate grouping, not just dividers.
- Align all elements to a shared vertical rhythm — labels, icons, and values in a row must share the same baseline/center alignment, with zero pixel drift between similar rows (e.g., every row in a leaderboard list must align identically).

---

## Typography

- One typeface family app-wide (e.g., Inter via Google Fonts) with a clear, limited type scale: Large Title / Title / Headline / Body / Caption — no ad hoc font sizes outside this scale.
- Consistent font weight usage per role (e.g., headlines always semibold, body always regular) — never vary weight arbitrarily for the same content type.
- Left-align body text and lists by default; center-align only short, standalone content (empty states, onboarding).

---

## Color & Contrast

- One accent color used only for primary actions, active states, and live/real-time indicators — never decoratively.
- Neutral grayscale for backgrounds, cards, dividers, and secondary text.
- Text-to-background contrast must meet at least 4.5:1 for body text, 3:1 for large text — check this for both light and dark mode.
- Never convey status (live/upcoming/completed, win/loss) through color alone — pair color with an icon or label for accessibility.

---

## Motion

- Motion should be purposeful and reflect real-world physics: use `Curves.easeOutCubic` app-wide as the standard curve — no bounce, no elastic overshoot.
- Transitions should communicate spatial relationships: pushing into a detail screen slides in from the right; presenting a sheet/modal slides up from the bottom; dismissing reverses the same path.
- Keep transition durations short: 200-300ms for screen transitions, 150-200ms for micro-interactions (button press, toggle, chip selection).
- Respect reduced-motion: check `MediaQuery.disableAnimations` and fall back to instant/cross-fade transitions when it's set.
- Live score updates animate via count-up (`TweenAnimationBuilder`), never a hard snap-to-new-value.

---

## Navigation

- Use a persistent bottom navigation bar (Home/Teams/Matches/Leaderboard/Profile) with no more than 5 destinations — HIG discourages overloading primary navigation.
- Each tab retains its own navigation stack/state when switching away and back (don't reset scroll position or reload data unnecessarily).
- Back navigation must always be predictable: system back button and any in-app back arrow must lead to the same place a user would expect.

---

## Accessibility

- All interactive elements need a `Semantics` label for screen readers (TalkBack) — icon-only buttons especially.
- Support Dynamic Type-equivalent scaling: text should scale gracefully with system font size settings without breaking layout (test at 130% scale).
- Never rely on a single sensory cue (color, sound, or shape alone) to convey critical information (e.g., match live status, win/loss).

---

## Component Consistency

- Build one internal design-system widget layer (`AppButton`, `AppCard`, `AppTextField`, `AppChip`, `SectionHeader`, `AppBottomSheet`) and use these exclusively across every screen — no one-off hand-rolled buttons or cards.
- Every card type (team card, match card, player card) shares identical corner radius, padding, and elevation.
- Every button of the same semantic role (primary CTA, secondary, destructive) shares identical height, corner radius, and typography app-wide.

---

## Apply This To VIT-AP Sports Screens Specifically

- **Profile screen:** avatar + name + stats laid out with strict vertical rhythm; badges grid uses equal-sized cells with consistent gutter.
- **Team screen:** roster list rows must align identically (avatar, name, role, stat — same x-positions every row); captain badge uses icon + label, not color alone.
- **Match screen:** live/upcoming/completed status uses icon + color + label together; scorecard numbers animate on update.
- **Leaderboard:** rank, avatar, name, stat columns perfectly aligned across every row, no drift as names vary in length (use fixed-width containers, not just Row with mainAxisAlignment).
- **Bottom nav:** icon + label pairs vertically centered, consistent icon size (24pt) and label size across all 5 tabs, smooth color transition on tab switch.

---

## Build Instruction

Before writing any screen, build the shared widget layer above first. Then implement each screen using only those shared components. After each screen is built, verify it against the Spacing & Layout and Typography sections above before moving to the next screen — do not defer this check to a final polish pass.
