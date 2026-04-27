# CoreX OS — Mobile (Flutter) UI Design System

> **The single source of truth for the CoreX OS Flutter mobile app.**
> Last updated: 2026-04-27
> Extends (does not contradict) the web spec in `UI_DESIGN_SYSTEM.md`. Where the web spec defines a token, role or pattern conceptually, this file defines the Flutter realisation. Anything not mentioned here inherits the **intent** of the web spec.

---

## How to read this spec

The web `UI_DESIGN_SYSTEM.md` is written in Blade/Tailwind/CSS. This app is a **Flutter** app — there are no `var(--surface)` custom properties, no `corex-btn-primary` class, no `<x-page-header>`. Instead:

- CSS tokens map to constants in [lib/theme.dart](lib/theme.dart) (`AppTheme.brand`, `AppTheme.surface(context)`, etc.).
- Blade components map to Flutter widgets in [lib/widgets/](lib/widgets/) and reusable patterns inside [lib/screens/](lib/screens/).
- Tailwind responsive breakpoints map to `MediaQuery.sizeOf(context).width` checks.
- Hover states do not exist — every interaction is touch.

If a rule here conflicts with the web spec **on intent** (token meaning, colour role, badge semantics), the web spec wins and this file is the bug. If a rule here adds a *Flutter realisation* of a web concept, this file is authoritative for the mobile app.

- **MUST / MUST NOT** — non-negotiable
- **SHOULD** — default; deviate only with reason
- **MAY** — allowed alternatives

---

## 1. BREAKPOINTS

This is a phone-first Flutter app. The layout is "mobile" by default — there is no desktop sidebar to collapse. Breakpoints are used only to scale up grids on tablet/large phone.

| Name      | Min width | Use                                              |
|-----------|-----------|--------------------------------------------------|
| `xs`      | 0         | Compact phone (≤ 360 dp). Single column.         |
| `sm`      | 360       | Standard phone. Default mobile layout.           |
| `md`      | 600       | Large phone / small tablet. 2-col grids allowed. |
| `lg`      | 840       | Tablet portrait. Master-detail patterns allowed. |
| `xl`      | 1024      | Tablet landscape / web preview. Mirror desktop.  |

**Mobile cutoff:** `< md` (i.e. width `< 600 dp`). All rules in this file apply at `< md` unless explicitly noted otherwise. At `md` and above, rules step toward the desktop spec (e.g. 2-col grids, persistent drawer).

Helper (place in `lib/utils/breakpoints.dart` if/when needed):

```dart
double w = MediaQuery.sizeOf(context).width;
final isCompact = w < 360;
final isMobile  = w < 600;
final isTablet  = w >= 600 && w < 1024;
```

---

## 2. LAYOUT ADAPTATIONS

### 2.1 Navigation shell

The mobile app does **not** have a desktop-style fixed sidebar. The web sidebar maps to **`BottomNavigationBar` (5-tab shell)** in [lib/screens/main_tabs_screen.dart](lib/screens/main_tabs_screen.dart) for the cockpit, plus full-page push routes for non-tab destinations (Properties, Settings, Profile).

Rules:
- **MUST** use `BottomNavigationBar` (`type: BottomNavigationBarType.fixed`) for the primary 4-tab cockpit (Today / Calendar / Tasks / Inbox). The 5th tab — if added — is a hub menu.
- Selected tab uses `AppTheme.brand`, unselected uses `AppTheme.textMuted(context)`.
- Tab labels visible at all times — `selectedFontSize: 11, unselectedFontSize: 11`.
- A top `border` between the body and the bottom bar (`Border(top: BorderSide(color: AppTheme.borderColor(context)))`) is required to match the web sidebar separation.
- For non-cockpit modules a hamburger-triggered `Drawer` MAY be used. If present:
  - Drawer width: `min(280, screenWidth * 0.85)`.
  - Backdrop: `Colors.black.withValues(alpha: 0.5)` (Material default).
  - Each item is a `ListTile` with `minVerticalPadding: 12` (= 48 dp tap target).
  - Active item: brand-tinted background (`AppTheme.brand.withValues(alpha: 0.12)`) and `AppTheme.brand` text/icon, weight 600.
- **MUST NOT** display a desktop-style persistent sidebar at any width below `lg` (840 dp).

### 2.2 Page header (`AppBar`)

The web `Pattern A` (branded) and `Pattern B` (back-button) collapse into a single Flutter pattern: the Material `AppBar`, themed in [lib/theme.dart](lib/theme.dart).

- **Background:** `AppTheme.surface(context)` (matches web `Pattern B` — branded surfaces are reserved for hero blocks below the AppBar, not the AppBar itself).
- **Title:** `fontSize: 18, fontWeight: w600`, colour `AppTheme.textPrimary(context)`. (One step down from desktop `text-xl`.)
- **Subtitle:** when needed, render below the AppBar inside the body, not in `AppBar.bottom`, at `fontSize: 12, color: textSecondary`.
- **Leading:** `IconButton(Icons.arrow_back_rounded)` for pushed pages. `null` (or hamburger) for root tabs.
- **Actions:** `IconButton`s (max 2 visible) + an overflow `PopupMenuButton` if there are more.
- **MUST NOT** put a primary "Create" button in the AppBar — use a `FloatingActionButton` (see §3.5).
- **MUST NOT** stack title + action vertically inside the AppBar. The action moves to a FAB or to the body (full-width primary button at the top of the form).

### 2.3 Body / content area

- **Outer scroll container:** `CustomScrollView` (slivers) for tabs that mix sections (Today), `ListView`/`SingleChildScrollView` for simple pages.
- **Horizontal padding:** **16 dp** for narrow lists, **20 dp** for content with internal cards (see Today, [lib/screens/today/today_screen.dart](lib/screens/today/today_screen.dart#L105)). Web `p-4` (16) and `p-6` (24) compress to **16 / 20**.
- **Vertical rhythm between sections:** 16 dp (mirrors web `space-y-4`). 24 dp between major bands.
- **MUST NOT** allow horizontal scroll on the page (only horizontally-scrollable widgets, see §3.7).
- **MUST** wrap the body in `SafeArea` (top for screens with no AppBar, always for bottom on FAB-heavy screens).

---

## 3. COMPONENT MOBILE ADAPTATIONS

For every web component, define the Flutter equivalent and the mobile-specific behaviour. If a component is not listed here, fall back to Material defaults themed by [lib/theme.dart](lib/theme.dart).

### 3.1 KPI / stat tiles

Web: `<x-corex-kpi-card>` in a `.corex-kpi-grid`. Flutter: a custom card widget (not yet a shared widget — see §7) inside a `GridView.count` or `Wrap`.

- **Grid:** `crossAxisCount: 2` at mobile (< `md`). At `xs` (< 360 dp) drop to `1` if the value would truncate.
- **Tile padding:** 12 dp inside, 12 dp `mainAxisSpacing` / `crossAxisSpacing`.
- **Value:** `fontSize: 20, fontWeight: w600`. (Web `1.625rem` = 26 px → 20 sp on mobile.)
- **Label:** `fontSize: 11, color: textMuted`.
- **Trend arrow:** ▲ green `#22c55e` (up), ▼ crimson `#dc2626` (down). Never invert for "down is bad/good" — just describe direction.
- **MUST NOT** render an unformatted float. Use `NumberFormat` from `intl` or a project-wide `formatZar()` helper. Missing values render as `'—'`, never `'NaN'` / `'null'`.
- **MUST NOT** clip or overflow. Use `FittedBox(fit: BoxFit.scaleDown)` on the value if dynamic content varies wildly.

### 3.2 Cards (property, deal, contact, timeline row)

Web: `rounded-md p-4 bg-surface border-border`. Flutter: `Card` (themed) **or** an inline `Container` with the same recipe.

Standard card recipe:
```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppTheme.surface(context),
    borderRadius: BorderRadius.circular(AppTheme.radius), // 6
    border: Border.all(color: AppTheme.borderColor(context)),
  ),
  child: ...,
)
```

- **Single-column** stack at mobile. Never 2-up at < `md`.
- **Image area:** `ClipRRect` with `BorderRadius.circular(6)`. Aspect ratio preserved via `AspectRatio` or fixed `width: 72, height: 72` for thumbnails (see [property_list_screen.dart:507](lib/screens/properties/property_list_screen.dart#L507)).
- **Status badge:** see §3.4. Always `nowrap` (single line) — clip with ellipsis before allowing wrap.
- **Tap target:** the entire card is tappable via `InkWell` wrapped inside a `Material`/`Card`. Card height MUST be ≥ 48 dp.
- **Inline action icons** (View / Edit / Delete): icon-only on mobile, each in an `IconButton` with default `48x48 dp` tap area. **MUST NOT** render a row of three labelled buttons inside a card on mobile — overflow into a `PopupMenuButton` instead.
- **MUST NOT** use `BoxShadow` larger than `BoxShadow(blurRadius: 8, color: black.withAlpha(0x14))`. Default state is **no shadow** — rely on the border. Hover/elevated state is not relevant on touch.

### 3.3 Filter bar

Web: horizontal `<x-list-header>` row. Flutter: search `TextField` at the top of the body + filter triggered from an AppBar action that opens a **bottom sheet** (see [property_list_screen.dart:99](lib/screens/properties/property_list_screen.dart#L99)).

- **Search input:** full-width `TextField` with `prefixIcon: Icons.search`, `suffixIcon: clear button` when text is present.
- **Filters trigger:** `IconButton(Icons.filter_list)` in the AppBar, with a small badge dot showing the active filter count.
- **Filter sheet:** `showModalBottomSheet(isScrollControlled: true)` with `DraggableScrollableSheet(initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95)`. Contains chip groups (`ChoiceChip`), price range inputs, and an `Apply` ElevatedButton (full width, 48 dp tall) at the bottom.
- **Result count:** rendered between the search and the list as a single line — `'{filtered} of {total} match'`, fontSize 12, textSecondary. Visible only when filters are active.
- **Clear filters:** `TextButton.icon(Icons.close, 'Clear filters')` to the right of the count.
- **MUST NOT** stack horizontal dropdowns at mobile width — always sheet-based.
- **MUST NOT** allow horizontal scroll of the filter row.

### 3.4 Badges / status chips

Web: `.ds-badge` pill. Flutter: a minimal helper `Container` (or the existing [lib/widgets/priority_badge.dart](lib/widgets/priority_badge.dart) and [lib/widgets/pillar_tag_chip.dart](lib/widgets/pillar_tag_chip.dart)).

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: roleColour.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(999), // pill
  ),
  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: roleColour)),
)
```

- **Shape:** pill (`BorderRadius.circular(999)`). Rectangular `rounded-md` only when used as a header pill in a card row (e.g. `'N need action'`, see [main_tabs_screen.dart:60](lib/screens/main_tabs_screen.dart#L60)).
- **Text:** `maxLines: 1`, `overflow: TextOverflow.ellipsis`, ≤ 20 characters.
- **Colour roles** (mirror web spec):
  - success → `Color(0xFF22c55e)` / `Color(0xFF059669)`
  - warning → `Color(0xFFf59e0b)`
  - danger → `Color(0xFFdc2626)` / `Color(0xFFef4444)` — destructive only, **never** for low scores
  - info → `AppTheme.brand`
  - default → `AppTheme.textMuted(context)`
- **MUST NOT** wrap to a second line. **MUST NOT** allow > 2 words.

### 3.5 Buttons

Theme-driven (`elevatedButtonTheme` already enforces brand background + 48 dp height + 6 dp radius — see [theme.dart:108](lib/theme.dart#L108)).

| Variant     | Widget                                    | Use                                |
|-------------|-------------------------------------------|------------------------------------|
| Primary     | `ElevatedButton`                          | Form submit, primary CTA           |
| Outline     | `OutlinedButton`                          | Cancel, secondary                  |
| Text        | `TextButton`                              | Inline links, "Clear", "View all"  |
| FAB         | `FloatingActionButton`                    | Primary "Create" action on a list  |
| Icon-only   | `IconButton` (size 48×48 dp)              | AppBar/row actions                 |
| Danger      | `ElevatedButton(style: bg=#dc2626)`       | Destructive confirm                |

- **Default minimum size:** `Size(double.infinity, 48)` for primary buttons in forms (already in theme). Inline `ElevatedButton`s (e.g. inside the reschedule strip in [today_screen.dart:546](lib/screens/today/today_screen.dart#L546)) MAY override `minimumSize` but tap target stays ≥ 36 dp tall and the parent `InkWell`/`GestureDetector` MUST extend the hitbox to 44 dp.
- **MUST NOT** use raw `Color(0xFF0EA5E9)` — call `AppTheme.brand`.
- **MUST NOT** put two primary `ElevatedButton`s in the same screen header. One primary; secondary is `OutlinedButton`.

### 3.6 Modals → bottom sheets

**Mobile-specific rule: there are no centred modal dialogs.** Web `<x-modal>` maps to one of:

- **Bottom sheet** (preferred for inputs): `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` with `DraggableScrollableSheet` for tall content. Top corners `BorderRadius.vertical(top: Radius.circular(12))`.
- **Full-screen route** (preferred for ≥ 6 form fields): `Navigator.push(MaterialPageRoute(fullscreenDialog: true))` — slides up from the bottom, has its own AppBar with × close.
- **AlertDialog** ONLY for destructive confirmations (`Discard changes?`, `Delete property?`) with one paragraph of body text and two short buttons.

- Sheet header: title `fontSize: 18, fontWeight: w700`, with a leading drag handle `Container(width: 36, height: 4, color: borderColor, radius: 2)` for sheets that use `DraggableScrollableSheet`.
- Body: scrollable. Footer (Apply / Save) pinned with a `SizedBox(height: 48, width: double.infinity)` ElevatedButton.
- **MUST NOT** float a 600 dp wide centred dialog on phone.
- **MUST NOT** stack two modal sheets simultaneously.

### 3.7 Tables → list rows

Mobile **does not render tables**. Tabular data in the web app collapses to a `ListView.separated` of cards, one record per card, on mobile. See the property list (`_PropertyCard` in [property_list_screen.dart:473](lib/screens/properties/property_list_screen.dart#L473)) for the canonical pattern.

If multi-column data must be preserved (rare, e.g. a financial breakdown):
- Wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal)`. The table widget is a fixed-width `DataTable` inside.
- The leftmost column (label) MUST stick via a custom approach (e.g. `TableView` from `two_dimensional_scrollables`) or split into two side-by-side scroll views.
- A faint right-edge gradient hints there's more content to scroll. **MUST NOT** silently truncate.
- The action column (if any) lives outside the scroll container, pinned right with a separator border.

**MUST NOT** ever cause full-page horizontal scroll.

### 3.8 Forms

- **Labels above inputs.** Use `InputDecoration(labelText:)` (floating) or render a `Text` above with `fontSize: 13, fontWeight: w500, color: textSecondary`. **Never** side-by-side label + input on mobile.
- **Input height ≥ 48 dp.** Theme already enforces `contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14)` (≈ 50 dp tall with default font). Do not override smaller.
- **Error messages** rendered via `InputDecoration(errorText:)` immediately below the input, `fontSize: 12, color: #dc2626`.
- **Required marker:** trailing `' *'` in the label, coloured `#dc2626`.
- **Submit button:** full-width `ElevatedButton` at the bottom of the form **or** in a `Persistent` bottom bar (`bottomNavigationBar: SafeArea(child: Padding(...))`). For long forms, keep the submit pinned.
- **Keyboard:** set `textInputAction` (`next` / `done`) and `keyboardType` (`number`, `email`, `phone`) appropriately. Use `MediaQuery.viewInsets.bottom` padding inside sheets so the keyboard does not cover inputs (see [property_list_screen.dart:134](lib/screens/properties/property_list_screen.dart#L134)).

### 3.9 Alerts / notice blocks

Web `Alert` block becomes an inline coloured `Container` at the top of the body, full bleed within page padding.

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: tint.withValues(alpha: 0.10),
    borderRadius: BorderRadius.circular(AppTheme.radius),
    border: Border.all(color: tint.withValues(alpha: 0.30)),
  ),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 18, color: tint),
    const SizedBox(width: 10),
    Expanded(child: Text(message, style: TextStyle(fontSize: 13))),
  ]),
)
```

Tints: success `#22c55e`, warning `#f59e0b`, danger `#dc2626`, info `AppTheme.brand`.

For ephemeral feedback (toasts), use `ScaffoldMessenger.of(context).showSnackBar(...)` with a 4 s default. Errors: 6 s, action button visible, danger colour.

### 3.10 Empty states

- Centre-aligned `Column(mainAxisSize: MainAxisSize.min)` inside a `Center`.
- Icon: 48–64 dp, `AppTheme.textMuted(context)` or a brand-tinted circle background (see [today_screen.dart:611](lib/screens/today/today_screen.dart#L611)).
- Heading: `fontSize: 15–18, fontWeight: w600, color: textPrimary`. One line.
- Body: `fontSize: 13, color: textSecondary`. One line, directive ("Tap + to add your first property"), not apologetic ("Nothing to show").
- CTA: full-width `ElevatedButton` **or** brand-tinted `TextButton` (preferred when nested inside a sliver). MUST exist when the user has permission to create.

### 3.11 Scorecard / progress

- Linear progress: `Container` with `height: 4–8`, background `surface2`, child `FractionallySizedBox` filled with `AppTheme.brand` or semantic colour. See `_FooterStrip` ([today_screen.dart:701](lib/screens/today/today_screen.dart#L701)).
- Circular ring: existing [lib/widgets/score_circle.dart](lib/widgets/score_circle.dart). Min diameter 56 dp on mobile.
- **MUST NOT** use red for a neutral score. < 100% → brand or amber, never crimson.
- Metric label truncates with `overflow: TextOverflow.ellipsis`; the value is never truncated.

### 3.12 Drawer nav items

Used only when a screen has a hamburger drawer (cockpit uses bottom tabs instead).

- `ListTile` with `leading: Icon`, `title: Text`, optional `trailing` for a count/badge.
- `minVerticalPadding: 12` (= 48 dp tap target).
- Active state: `tileColor: AppTheme.brand.withValues(alpha: 0.12)`, `textColor: AppTheme.brand`, `iconColor: AppTheme.brand`.
- Sub-items: `ExpansionTile` (accordion), never a hover flyout.
- **MUST NOT** nest more than 2 levels.

---

## 4. TOUCH & INTERACTION RULES

- **Minimum tap target: 48×48 dp** (Material standard; Apple HIG specifies 44 pt — 48 dp covers both). Apply via `IconButton`'s default `splashRadius`/padding, `ListTile.minVerticalPadding`, or wrap with `SizedBox(width: 48, height: 48)`.
- **No hover-only interactions.** No `MouseRegion`-only behaviour. Every action that exists must be reachable by tap.
- **No tooltips on tap targets.** Use `Tooltip` only for icon-only AppBar actions; the tooltip displays on long-press, never on hover.
- **Swipe gestures:** the canonical pattern is `Dismissible` with `DismissDirection.horizontal`, two `_SwipeBg` backgrounds, and `confirmDismiss: (dir) async { ... return false; }` so the row resets after the action. See [today_screen.dart:387](lib/screens/today/today_screen.dart#L387). Right-swipe = positive (Done/green), left-swipe = neutral action (Reschedule/brand). **Never** left-swipe to delete without an explicit second confirmation.
- **Long-press:** reserved for context menus (`showMenu`) on rows where right-click would be expected on desktop.
- **Pull-to-refresh:** `RefreshIndicator(color: AppTheme.brand, backgroundColor: AppTheme.surface(context))` on every list/feed.
- **Haptics:** `HapticFeedback.selectionClick()` on segmented switches, `lightImpact` on swipe-complete.

---

## 5. TYPOGRAPHY ADAPTATIONS

Font: `GoogleFonts.interTextTheme` (set in [theme.dart:88](lib/theme.dart#L88)). Web uses Figtree; mobile uses Inter as a near-equivalent geometric sans. Both have weights 400–700.

Mobile size scale (sp; Flutter respects user's `textScaleFactor` automatically):

| Role                    | sp | weight | Web equivalent           |
|-------------------------|----|--------|--------------------------|
| Caption / micro         | 10 | w600   | `text-[0.6875rem]` (11)  |
| Meta / helper / badge   | 11 | w500   | `text-xs` (12)           |
| Body small / table cell | 12 | w400   | `text-[13px]`            |
| Body                    | 13 | w400   | `text-sm` (14)           |
| Body emphasised         | 13 | w500   | `text-sm font-medium`    |
| AppBar title            | 18 | w600   | `text-lg` (18)           |
| Section title           | 16 | w600   | `text-lg`                |
| Page hero / section H1  | 20 | w700   | `text-xl` (20)           |
| KPI value               | 20 | w600   | `text-[1.625rem]` (26)   |
| KPI hero                | 24 | w700   | `text-[1.75rem]` (28)    |

Rules:
- **Step-down at < `md`:** desktop `text-xl` → 18 sp on AppBar, `text-2xl` (KPI) → 20 sp.
- **Line height:** rely on Flutter defaults (1.4–1.5). For multi-line content use `height: 1.4`.
- **`maxLines` + `overflow: TextOverflow.ellipsis`** on every `Text` that holds dynamic content inside a fixed-width parent (card titles, badge labels, list subtitles).
- **Numeric alignment:** for monetary values in tables/lists use `GoogleFonts.jetBrainsMono` or `FontFeature.tabularFigures()`.
- **Never** allow text to overflow its container or force horizontal scroll.

---

## 6. MOBILE-SPECIFIC BUG-CLASS RULES

These must never appear on any screen at any phone width:

1. **Horizontal page scroll** caused by any element. Diagnose with the Flutter Inspector's "Debug Paint" / "RenderFlex overflowed" warnings.
2. **Tap targets smaller than 48×48 dp** (Material) — equally accessible to 44 pt iOS HIG.
3. **Text overflow / clipping** in cards, tiles, badges. Always set `maxLines` + `ellipsis`.
4. **Centred floating dialogs** at phone width. Modals are bottom sheets or full-screen routes (§3.6).
5. **Persistent desktop sidebar** at any width below `lg` (840 dp).
6. **Tables that horizontally scroll the entire page** (vs. a contained `SingleChildScrollView`).
7. **Form inputs shorter than 48 dp**.
8. **Hover-only behaviour** (e.g. tooltips that only appear on `MouseRegion`).
9. **Hard-coded brand hex** (`Color(0xFF0EA5E9)`) — use `AppTheme.brand`.
10. **Red used for neutral / low scores** — use amber or brand.
11. **Auto-popups on launch** (per memory: cockpit UX rules).
12. **"9+" overflow badges** — use a small dot or a horizontal pill with the exact number (per memory).
13. **Orphan rows** — every row must have a tap target and at least one action.
14. **Inline reschedule that requires navigating away** — keep it inline (per memory; pattern in [today_screen.dart:507](lib/screens/today/today_screen.dart#L507)).
15. **Raw floats / `null` / `NaN`** rendered to users — format or fall back to `'—'`.
16. **`onTap` on the parent that fires for child actions** — wrap children in `GestureDetector(behavior: HitTestBehavior.opaque)` or use an explicit `IconButton`. (Web equivalent: stopPropagation on row actions, per memory.)

---

## 7. MOBILE COMPONENT INVENTORY

Components currently in [lib/widgets/](lib/widgets/) and how they fit this spec.

| Widget                          | File                                              | Status                                                              |
|---------------------------------|---------------------------------------------------|---------------------------------------------------------------------|
| `CollapseMenu`                  | [collapse_menu.dart](lib/widgets/collapse_menu.dart) | Top utility menu on home hub. Conforms.                          |
| `EventCard`                     | [event_card.dart](lib/widgets/event_card.dart)    | Calendar row card. Verify `maxLines`/ellipsis on title.             |
| `FeatureSquare`                 | [feature_square.dart](lib/widgets/feature_square.dart) | Hub grid tile. Conforms — uses brand + 6 dp radius.            |
| `GreetingCard`                  | [greeting_card.dart](lib/widgets/greeting_card.dart) | Home greeting block. Conforms.                                    |
| `PillarLink`                    | [pillar_link.dart](lib/widgets/pillar_link.dart)  | Cross-pillar nav helper. Pure logic; no UI rules apply.            |
| `PillarTagChip`                 | [pillar_tag_chip.dart](lib/widgets/pillar_tag_chip.dart) | Pillar badge. Confirm pill shape + nowrap.                   |
| `PriorityBadge`                 | [priority_badge.dart](lib/widgets/priority_badge.dart) | Priority badge (high/critical). Confirm pill + nowrap.          |
| `ScoreCircle`                   | [score_circle.dart](lib/widgets/score_circle.dart) | Circular score. Min 56 dp on mobile (verify).                     |
| `StatPill`                      | [stat_pill.dart](lib/widgets/stat_pill.dart)      | Inline stat pill. Conforms when used inside Today footer.          |
| `TaskCard`                      | [task_card.dart](lib/widgets/task_card.dart)      | Task row card. Must not exceed 1-line title with ellipsis.         |

**Missing shared widgets** (currently inlined in screens, candidates for extraction):

- `KpiCard` — duplicated KPI tile recipe; not yet shared.
- `EmptyState` — reimplemented in [today_screen.dart:611](lib/screens/today/today_screen.dart#L611), [property_list_screen.dart:420](lib/screens/properties/property_list_screen.dart#L420), and others.
- `AlertBlock` — no shared widget yet for §3.9.
- `FilterBottomSheet` — duplicated in property list; extract into `lib/widgets/filter_sheet.dart`.
- `SectionHeader` — reimplemented as small helpers in Today and Tasks.

**Known violations / refactor targets** (snapshot, 2026-04-27):

- [property_list_screen.dart:118](lib/screens/properties/property_list_screen.dart#L118) hardcodes `AppTheme.darkBackground` as the bottom-sheet background — breaks light theme. Replace with `AppTheme.surface(context)`.
- [property_list_screen.dart:275](lib/screens/properties/property_list_screen.dart#L275) hardcodes `AppTheme.darkSurface2` for `ChoiceChip.backgroundColor` — same theme-break.
- [main_tabs_screen.dart:60](lib/screens/main_tabs_screen.dart#L60) hardcodes `Color(0xFFef4444)` for the inbox-warning pill. Acceptable as a semantic literal but extract into `AppTheme.danger` (or move to a shared `Semantics` map).
- [today_screen.dart:333](lib/screens/today/today_screen.dart#L333) uses `Color(0xFF6b7280)` literal as fallback stripe colour; extract to a `palette` constant.
- The MainTabs AppBar shows a back arrow (`Navigator.pop`) on a root tab destination ([main_tabs_screen.dart:44](lib/screens/main_tabs_screen.dart#L44)). On a tab home, leading should be `null` or a hamburger — pop on a root tab can drop the user out of the app.
- No shared `AppTheme.success` / `AppTheme.warning` / `AppTheme.danger` constants exist — semantic colours are scattered as raw hex throughout.

---

## 8. Acceptance criteria for new mobile UI

Before any new screen is marked done:

- [ ] Uses `Scaffold` themed by [lib/theme.dart](lib/theme.dart) — no inline `Theme()` overrides.
- [ ] All colours come from `AppTheme.*` (or documented semantic literal).
- [ ] Border-radius is `AppTheme.radius` (6) unless documented exception.
- [ ] All tap targets ≥ 48 dp.
- [ ] Every list has `RefreshIndicator` and a directive empty state.
- [ ] Every form input ≥ 48 dp tall, label above, validation below.
- [ ] No fixed-width content forces horizontal scroll at 360 dp.
- [ ] Works in both light and dark theme (toggle via `ThemeProvider`).
- [ ] No raw floats / `null` / `NaN` rendered.
- [ ] FAB (not AppBar button) used for the primary "Create" action on lists.
- [ ] `flutter analyze` passes with zero new warnings.
- [ ] Manually verified at 360 dp width in the iOS Simulator / Android emulator.

---

## 9. Source of truth

- Web `UI_DESIGN_SYSTEM.md` defines **roles, tokens, colour semantics, badge meanings**. This file does NOT redefine them.
- This file defines **how those roles render in Flutter on phones**.
- When a rule conflicts: token semantics → web spec wins. Flutter realisation → this file wins.
- Commit changes here in the same PR as the screens that depend on them.
