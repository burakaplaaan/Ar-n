# Home Screen Bronze Ornament Parity Audit — Agent A

**Date:** 2026-06-15  
**Scope:** Dark-shell home screen bronze/brown ornamental details  
**Reference assets:**
- `image-604733a4` — primary bronze-detail reference (cropped mock; filigree corners, bronze typography, specialty next-prayer frame)
- `image-7841c589` — full-page build reference (layout completeness, tile grid, green active states)

**Implementation inspected (read-only):**
- `lib/presentation/home/home_page.dart`
- `lib/presentation/home/widgets/daily_namaz_wisdom_card.dart`
- `lib/presentation/home/widgets/home_namaz_ritual_section.dart`
- `lib/presentation/shared/widgets/ornate_frame.dart`
- `lib/core/constants/app_colors.dart`

**Related child widgets (ornament-adjacent):**
- `lib/presentation/willpower/widgets/salat_prayer_row.dart`
- `lib/presentation/willpower/widgets/namaz_adhan_reminder_card.dart` (compact mode)

---

## Executive Summary

The implementation has a **shared `OrnateFrame` overlay** applied across all major home cards and prayer tiles, with centralized bronze tokens (`AppColors.ornamentGold` / `ornamentGoldDeep`). This is the correct architectural direction.

However, bronze parity with the reference is **incomplete and stylistically simplified**:

1. **Motif geometry** — reference uses filigree / vine-like corner flourishes; code draws plain L-brackets (`_OrnateFramePainter`).
2. **Bronze color routing** — reference applies bronze to titles, chevrons, bells, toggles, and usernames; code routes most labels to white/grey and accents to neon green.
3. **Specialty frames** — the next-prayer box reference has a scalloped top arch and bottom-center diamond; code uses a rectangular frame with a **top-center** diamond (`topAccent: true`).
4. **Secondary ornaments** — shell-level top-left filigree, reminder-card bottom-right flourish, and double-line card borders are absent.

**Pixel-parity score (bronze ornament focus): 54 / 100** — see §Score at end.

---

## 1. Header (`_HeaderSection`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| H-1 | **High** | Reference shows a large **top-left shell filigree flourish** (vine/leaf curves) sitting on the page background, outside any card. Implementation has no shell-level ornament — only a 16px `Icons.nightlight_round` pinned inside the header card (`home_page.dart` L201–212). | Missing background ornament layer in `ArinShellBackground` / `HomePage`; header uses Material icon placeholder instead of custom painter or SVG asset. | Add a positioned `CustomPaint` or vector asset on the home scroll layer (top-left, ~48–64dp) using `AppColors.ornamentGold` at α≈0.55–0.70. Do not substitute another Material icon. |
| H-2 | **High** | Username **"Misafir"** is bronze/brown in reference; implementation renders it as **muted white** (`subtitleC = Colors.white @ 55%`, `home_page.dart` L164–166, L231–238). | `subtitleC` intentionally uses neutral white, not `ornamentGold`. | Set guest-name / subtitle color to `AppColors.ornamentGold.withValues(alpha: 0.85)` on dark shell (keep white only for non-ornament secondary meta if needed). |
| H-3 | **Medium** | Greeting **"Hayırlı Geceler"** in reference uses a **warm gold/serif** display face; implementation uses **bold white sans-serif** at 28px (`home_page.dart` L221–228) with no bronze tint or display font. | `titleC = Colors.white`; no `fontFamily` from display/serif stack. | Apply bronze-tinted serif (e.g. existing display family if any) at `color: ornament.withValues(alpha: 0.92)` or white with subtle gold `ShaderMask`; match reference weight and letter-spacing. |
| H-4 | **Critical** | **Premium pill** in reference has thin **bronze/gold border** and gold crown. Implementation uses **neon-green** border/fill when not premium (`accentNeonGreen @ 15%` fill, `@ 45%` border — `home_page.dart` L257–270). | Hard-coded `isPremium ? goldAccent : accentNeonGreen` branch. | Always use bronze ornament palette for Premium CTA on home: `ornamentGold` border (α≈0.55), crown icon `goldAccent` or `ornamentGold`, neutral text — regardless of premium state. Reserve green for prayer/active states only. |
| H-5 | **Medium** | Entire header is wrapped in `OrnateFrame` (L171–435). Reference crop (`604733a4`) shows greeting area **without** a enclosing card frame — ornament is ambient on shell, not a full-width bordered panel. Full-page ref (`7841c589`) does show a header card frame. | `_HeaderSection` always wraps in `OrnateFrame`. | Reconcile with design owner: if `604733a4` is canonical, remove outer `OrnateFrame` from header and keep only shell flourish + inner next-prayer frame. If `7841c589` is canonical, keep frame but upgrade corner motif (see OrnateFrame section). |
| H-6 | **Low** | Mosque watermark placement differs slightly (reference: left background in header; code: `Icons.mosque_rounded` at left:-10, bottom:-18). | Position constants in `Stack`. | Minor offset tweak after motif fix; not blocking. |

**Parity notes (no mismatch / acceptable):**
- Mosque silhouette presence — **match** (decorative, low-alpha).
- Header horizontal padding 24 — **acceptable**.

---

## 2. Next Prayer Box (`_HeaderSection` → nested `OrnateFrame`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| N-1 | **Critical** | Reference next-prayer widget has **scalloped / arched top edge** (architectural bracket shape), not a rounded rectangle. Implementation is a **plain `BorderRadius.circular(18)`** rect (`home_page.dart` L322–343). | No custom `ShapeBorder` or `CustomPainter` clip for arch; standard `BoxDecoration`. | Replace container clip with custom `ShapeBorder` (e.g. `NextPrayerFrameShape`) drawing concave top scallops; keep bronze stroke. |
| N-2 | **High** | Reference places a **solid bronze diamond at bottom-center** of the frame. Implementation draws diamond at **top-center** via `OrnateFrame(topAccent: true)` (`ornate_frame.dart` L160–181, `home_page.dart` L321). | `topAccent` flag paints diamond at `cy = inset` (top), not bottom. | Add `bottomAccent` (or `accentPosition` enum) to `OrnateFrame`; move diamond + tick marks to bottom edge center to match reference. |
| N-3 | **Medium** | Reference frame reads as a **shield/badge** with continuous bronze outline following the special shape. Implementation stacks **OrnateFrame L-brackets + separate `Border.all`** — corners feel like two systems. | Dual decoration: painter brackets + container border (`home_page.dart` L344–351). | Unify into single custom painter path for specialty box; remove redundant `Border.all` or align both to same path geometry. |
| N-4 | **Low** | Countdown color **neon green** — **matches** both references. Badge label "Sıradaki" muted white — **matches**. | `AppColors.accentNeonGreen` — correct for time digits. | No change for countdown color. |
| N-5 | **Medium** | Box width fixed at **124px** (`home_page.dart` L323); reference appears slightly wider relative to prayer name length. | Hard-coded width. | Consider `intrinsic` width with `minWidth: 124` or scale to content. |

---

## 3. Reminder Card (`DailyNamazWisdomCard`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| R-1 | **High** | Title **"Bugünün hatırlatıcısı"** is **bronze/brown** in reference; implementation uses **near-white** (`titleC = Colors.white @ 92%`, `daily_namaz_wisdom_card.dart` L36–38, L88–96). | Title color not tied to ornament palette. | Set title `color: accent` (`ornamentGold`) at α≈0.90 on dark shell. |
| R-2 | **High** | Reference shows a **large, prominent bronze opening quote** centered above body text. Implementation uses small `Icons.format_quote_rounded` at **18px, α=0.28** (`daily_namaz_wisdom_card.dart` L113–117) — barely visible. | Low alpha + small icon size. | Increase to 28–32px; α≈0.65–0.80; consider custom glyph or text `"` in bronze with display font. |
| R-3 | **Medium** | Reference has **bottom-right interior corner flourish** (faded filigree). Implementation has **no secondary corner ornament** inside card. | No `Stack` overlay / painter in `_DailyNamazWisdomBody`. | Add `Positioned(right: 8, bottom: 8)` decorative painter (mirror of top-left shell motif, α≈0.12–0.18). |
| R-4 | **Medium** | Reference star is a **four-pointed bronze star**; implementation uses `Icons.auto_awesome_rounded` (multi-ray sparkle). | Icon choice L82–86. | Swap to custom 4-point star painter or closest single-color star asset in bronze. |
| R-5 | **Medium** | Reference describes **double-line bronze border**; implementation has container `Border.all` (α≈0.38) **plus** faint inner `OrnateFrame` hairline (α=0.30). Combined effect is a **single faint line + L-brackets**, not crisp double rails. | `borderC` alpha too low; `drawBorder` inner radius inset makes lines hard to read as double. | Raise outer border to α≈0.50–0.55; add explicit second inset stroke in `_OrnateFramePainter` (offset +1.5dp) or `BoxDecoration` with two borders. |
| R-6 | **Low** | Quote body text: reference uses **italic serif**; code uses `AppTextStyles.primaryFontFamily` medium 12px, non-italic (`daily_namaz_wisdom_card.dart` L119–137). | No `fontStyle: FontStyle.italic`. | Add italic serif for quote body on dark shell. |
| R-7 | **Low** | Shimmer animation on card (`.shimmer(...)`) — not in reference; may dilute bronze static ornament read. | `flutter_animate` shimmer L151–155. | Disable shimmer on dark home or restrict to non-ornament layer. |

**Parity notes:**
- `OrnateFrame` wrapper with `borderRadius: 20, inset: 7, armLength: 15` — **structurally correct placement**.
- Gradient card surface — **acceptable match** to reference depth.

---

## 4. Namaz Tracking Card (`HomeNamazRitualSection`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| T-1 | **High** | Navigation **chevron** is bronze/gold in reference; implementation uses **grey/white** (`Colors.white @ 35%` dark, `textSecondary @ 70%` light — `home_namaz_ritual_section.dart` L266–274). | Chevron not using `ornamentAccent`. | `color: ornamentAccent.withValues(alpha: 0.75)`. |
| T-2 | **Medium** | Inactive prayer **triangles** in reference read as **muted bronze**; `SalatPrayerRow` uses `creamBase @ 28%` stroke (`salat_prayer_row.dart` L144–150) — cooler/greyer, not warm bronze. | Triangle color not mapped to `ornamentGold`. | Inactive stroke: `AppColors.ornamentGold.withValues(alpha: 0.35–0.45)`. |
| T-3 | **Medium** | Reference shows **green star/indicator above active prayer** (İkindi); compact row may not render star pointer — depends on `SalatPrayerRow` active styling (not bronze-related but layout parity). | Active state styling in `salat_prayer_row.dart` beyond line 150. | Verify active column adds green star/caret above triangle per reference (out of bronze scope but affects section parity). |
| T-4 | **Low** | Card uses flat `color:` surface on active tracking path (L206–208) vs gradient on reminder card — subtle depth mismatch vs reference. | Different `BoxDecoration` strategy between sibling cards. | Align to same gradient recipe as `DailyNamazWisdomCard` for visual family consistency. |
| T-5 | **Low** | `OrnateFrame` parameters (`inset: 7, armLength: 15`) — **consistent** with reminder card. | Shared widget — OK. | Keep; fix motif geometry globally in `OrnateFrame`. |

**Parity notes:**
- Outer `OrnateFrame` on tracking card — **match**.
- Progress subtitle styling — **acceptable**.

---

## 5. Vakit Bildirimi Sub-block (inside tracking card)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| V-1 | **High** | Title **"Vakit bildirimi"** is **bronze** in reference; compact `NamazAdhanReminderCard` uses `primaryText = AppColors.creamBase` (dark) / `emeraldDark` (light) — `namaz_adhan_reminder_card.dart` L405, L456–460. | Reminder card not wired to ornament palette in compact mode. | Title color → `AppColors.ornamentGold.withValues(alpha: 0.88)` on dark shell. |
| V-2 | **High** | Bell icon is **bronze/gold** in reference; compact mode uses **`accentNeonGreen @ 88%`** (L444–447). | Icon color tied to prayer accent green. | Bell → `ornamentGold @ 0.85`; reserve green for switch thumb when ON only. |
| V-3 | **High** | Toggle track in reference has **thin bronze outline**; implementation uses default `Switch.adaptive` theming (L490–497) with **no bronze track border**. | No `Theme`/`SwitchThemeData` override for home compact embed. | Wrap switch in `Theme(data: SwitchThemeData(trackOutlineColor: ornamentGold …))` or custom bronze-outlined toggle. |
| V-4 | **Medium** | Nested sub-panel border in reference is bronze-family; implementation uses `Colors.white @ 6%` / `creamDark @ 55%` (`home_namaz_ritual_section.dart` L291–300). | `decoration.border` not ornament-colored. | Sub-container border → `ornamentAccent.withValues(alpha: 0.22–0.30)`. |

---

## 6. Prayer Times Block (`_PrayerTimesList`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| P-1 | **Medium** | Section title **"Namaz Vakitleri"** is white in implementation (`titleC`, L494–496); reference leans warm (white acceptable) but **clock icon is bronze** — implementation **does** use `accent` for clock (L562–565) — **partial match**. | Icon uses ornament; title does not. | Optional: title could stay white; ensure icon α≥0.90 (currently 0.95 — **OK**). |
| P-2 | **Medium** | Location row chevron/meta uses `meta` grey (L1026–1029), not bronze. Reference doesn't emphasize bronze here. | `_LocationRow` styling. | **Low priority** — optional bronze chevron. |
| P-3 | **Low** | `OrnateFrame(borderRadius: 22, inset: 8, armLength: 18)` — **present and consistent**. | — | Upgrade painter geometry only. |
| P-4 | **Low** | Loading skeleton `_PrayerTimesSkeleton` **omits `OrnateFrame`** (L767–877) — bronze ornaments disappear during load. | Skeleton uses plain `ClipRRect` only. | Wrap skeleton in matching `OrnateFrame` params. |

**Parity notes:**
- Outer ornate container around full grid — **match** with full-page reference.
- Mosque + moon decorative icons — **acceptable**.

---

## 7. Individual Prayer Tiles (`_PrayerTimeTile`)

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| PT-1 | **High** | Reference keeps **bronze ornate border on active tile** with **green glow overlay**; active tile switches border to **neon green** (`borderColor = activeAccent @ 72%`, L641–643) — bronze frame visually **lost** on next prayer. | `isNext` branch replaces accent with green. | Keep bronze `OrnateFrame` + container border always; add green `boxShadow` / outer glow only for active state. |
| PT-2 | **Medium** | Tiles use `OrnateFrame(drawBorder: false)` (L662–666) — reference tiles show **full miniature ornate frame** including hairline. | `drawBorder: false` removes inner hairline on small tiles. | Set `drawBorder: true` for tiles; reduce `inset` to 3 and stroke α to avoid clutter. |
| PT-3 | **Medium** | Corner flourishes on tiles in reference are **filigree**; implementation inherits simplified **L-brackets** at `armLength: 9`. | Shared `_OrnateFramePainter`. | Extend painter with `detailLevel` parameter (compact filigree for tiles). |
| PT-4 | **Low** | Inactive tile icon circle border uses `accent @ 20%` (L693–696) — **acceptable** bronze family. | — | Slight α bump to 0.28 for visibility. |
| PT-5 | **Low** | Active time green + "Sıradaki vakit" label — **matches** full-page reference (`7841c589`). | `activeAccent` — correct. | No change. |
| PT-6 | **Low** | Tile uses circular icon container; reference shows simpler icon without heavy circle on some tiles. | `BoxDecoration` circle L687–699. | Optional simplify to icon-only for closer match. |

---

## 8. Cross-Cutting: `OrnateFrame` & `AppColors`

| # | Severity | UI Symptom | Likely Code Cause | Fix Suggestion |
|---|----------|------------|-------------------|----------------|
| X-1 | **Critical** | All corner ornaments are **geometric L-brackets** (3-segment paths, `strokeWidth: 1.6`, α=0.72). Reference requires **curved filigree / vine flourishes** with bud details at vertices. | `_OrnateFramePainter` L127–158 — only straight lines. | Replace or augment bracket paths with Bezier-based flourish asset; consider SVG `CustomPaint` per corner. |
| X-2 | **High** | Ornament stroke often **too faint** against dark green: inner hairline α=**0.30** (`ornate_frame.dart` L108), container borders α=**0.32–0.38**. Reference shows **crisp 1–1.5px bronze** lines with higher contrast. | Conservative alpha choices across files. | Standardize dark-shell bronze strokes: hairline α≈0.48–0.55, brackets α≈0.78–0.85. |
| X-3 | **Medium** | `ornamentGold = #B88E47` and `ornamentGoldDeep = #9D7438` — warm bronze family is **reasonable** vs reference aged brass; no alternate metallic gradient/sheen. | Flat `Color` constants in `app_colors.dart` L110–114. | Optional: subtle linear gradient shader on ornament strokes (lighter highlight on top edge). |
| X-4 | **Medium** | `OrnateFrame` is **non-interactive overlay** (`IgnorePointer`) — correct. Container borders underneath sometimes **misalign visually** with painter inset geometry. | Dual-layer border systems. | Derive container border radius/inset from shared constants exported by `OrnateFrame`. |
| X-5 | **Low** | Parameter drift across cards: header `armLength: 16`, reminder `15`, prayer block `18`, tiles `9`, next-prayer `11`. Reference suggests **uniform motif scale** per card size tier only. | Per-widget tuning. | Document two tiers: large card (arm 16–18), small tile (arm 8–10); avoid ad-hoc values. |

---

## Section Parity Checklist (Quick Reference)

| Section | Bronze frame present? | Motif accuracy | Bronze typography/icons | Overall |
|---------|----------------------|----------------|-------------------------|---------|
| Header | Yes (disputed vs crop ref) | L-bracket only | Premium green mismatch; subtitle white | **Partial** |
| Next Prayer box | Yes | Wrong shape; diamond top not bottom | Bronze border OK-ish | **Poor** |
| Reminder card | Yes | L-bracket only | Title white; quote faint | **Partial** |
| Namaz tracking | Yes | L-bracket only | Chevron not bronze | **Partial** |
| Vakit bildirimi | Nested panel only | No ornate sub-frame | Title/bell/switch not bronze | **Poor** |
| Prayer Times block | Yes | L-bracket only | Clock icon OK | **Good–Partial** |
| Prayer tiles | Yes (no hairline) | L-bracket only | Active border loses bronze | **Partial** |

---

## Pixel-Parity Score: **54 / 100**

### Scoring rubric (bronze ornament focus)

| Criterion | Weight | Score | Notes |
|-----------|--------|-------|-------|
| Ornate frame coverage (all sections wrapped) | 15 | 13 | Skeleton/error states excluded |
| Corner motif fidelity (filigree vs L-bracket) | 20 | 6 | Largest visual delta |
| Bronze color routing (text, icons, controls) | 20 | 8 | Many elements still white/green |
| Specialty next-prayer frame | 15 | 5 | Shape + diamond position wrong |
| Secondary ornaments (shell flourish, inner flourishes) | 10 | 2 | Mostly absent |
| Stroke visibility / double-border treatment | 10 | 6 | Too faint; not true double-line |
| Consistency / token centralization | 10 | 14 | `AppColors` + `OrnateFrame` reuse is solid |
| **Total** | **100** | **54** | |

### Reasoning

The implementation earns credit for **systematic application** of `OrnateFrame` and centralized `ornamentGold` tokens across every major home surface, including per-tile ornaments — a non-trivial engineering baseline that many apps skip entirely.

It loses substantial points because the **ornament language itself is not the reference language**: straight L-brackets cannot pass as filigree corners, the next-prayer widget misses its signature scalloped/arch geometry and bottom diamond, and numerous UI elements that read as bronze in the reference (username, section titles, chevrons, bell, toggle chrome, Premium pill) are still rendered in **white or neon-green** channels.

Raising α values alone might reach ~65; reaching **85+** requires custom flourish geometry, specialty next-prayer shape, and a bronze-first typography/icon routing pass on home.

---

## Recommended Fix Priority (ornament-only)

1. **P0** — Redesign `_OrnateFramePainter` corner paths (filigree) + increase stroke contrast (`X-1`, `X-2`).
2. **P0** — Next-prayer custom shape + bottom diamond accent (`N-1`, `N-2`).
3. **P1** — Premium pill bronze treatment (`H-4`).
4. **P1** — Bronze routing for reminder title/quote, tracking chevron, notification title/bell/toggle (`R-1`, `R-2`, `T-1`, `V-1`–`V-3`).
5. **P1** — Active prayer tile: preserve bronze border under green glow (`PT-1`).
6. **P2** — Shell top-left flourish + reminder bottom-right accent (`H-1`, `R-3`).
7. **P2** — Double-line border spec (`R-5`); skeleton `OrnateFrame` (`P-4`).

---

## Agent A Certification

- **Code modified:** None (audit-only).
- **References used:** Both attached screenshots; primary bronze detail cues from `image-604733a4`, layout/active-state cues from `image-7841c589`.
- **Reviewer stance:** Strict — generic "needs more polish" findings avoided; each item ties to file/symbol.

*End of report — Agent A*
