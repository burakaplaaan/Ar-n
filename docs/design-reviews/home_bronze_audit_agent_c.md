# Home Screen Bronze Audit — Agent C

**Date:** 2026-06-15  
**Scope:** `home_page.dart`, `daily_namaz_wisdom_card.dart`, `home_namaz_ritual_section.dart`, `ornate_frame.dart` (+ downstream widgets referenced from home)  
**Reference:** Premium bronze/dark-green home mockups (header, wisdom card, namaz takibi, prayer-times grid)  
**Method:** Static code review vs reference craftsmanship criteria — ornamental consistency, visual hierarchy, spacing, stroke rhythm, glow discipline.

---

## Executive Summary

The home screen has successfully adopted the dark emerald + warm bronze palette, layered card surfaces, and a reusable `OrnateFrame` ornament system. The prayer-times grid and next-prayer highlight state are the closest match to the reference. The largest gaps are **typography (sans-only vs serif greeting)**, **SalatPrayerRow semantics (done vs current-window glow)**, **double-border stroke stacking**, **simplified L-bracket motifs vs reference flourishes**, and **inconsistent OrnateFrame parameters across cards**. Glow is mostly disciplined on prayer tiles but leaks into non-active states (Premium badge, completed triangles, wisdom shimmer).

**Overall craftsmanship grade:** B− (structure correct, micro-refinement needed)

---

## 1. Detailed Critique by Component

### 1.1 `OrnateFrame` (`ornate_frame.dart`)

| Finding | Severity | Detail |
|---------|----------|--------|
| Motif geometry is L-bracket only, not reference flourish | **High** | `_OrnateFramePainter` draws four orthogonal corner arms (`strokeWidth: 1.6`, `armLength` clamped). Reference shows delicate swirling/bracket corner ornaments with higher visual density. Current motifs read as "UI corner brackets," not "premium Islamic ornamental frame." |
| Double-border stacking with card containers | **Critical** | Every wrapped card also sets `Border.all(width: 1.1, alpha: 0.38–0.45)` on its `Container`. `OrnateFrame` adds a second inner hairline at `strokeWidth: 1.0, alpha: 0.30`. Result: two competing gold strokes at different insets — breaks stroke rhythm. |
| Bracket stroke heavier than hairline | **Medium** | Brackets at `1.6` vs hairline at `1.0`. Reference uses uniform ultra-thin (~1px) stroke throughout. Brackets currently dominate. |
| `topAccent` is flat diamond + tick lines | **Medium** | Countdown widget uses `topAccent: true`, but reference shows mihrab/dome peak protrusions at top **and** bottom of the countdown frame. Diamond reads as a generic badge, not architectural frame language. |
| No per-size motif scaling policy | **Medium** | Prayer tiles pass `inset: 4, armLength: 9` while section cards use `inset: 7–8, armLength: 15–18`. Brackets scale but visual density doesn't — small tiles feel sparse, large cards feel under-ornamented relative to reference. |
| `drawBorder: false` on tiles but container border remains | **Low** | `_PrayerTimeTile` disables OrnateFrame hairline but keeps a separate green/gold `Container` border. Ornamental language splits between painter brackets and Material border — acceptable but inconsistent with section cards. |

**Code targets:** `_OrnateFramePainter.paint()` (lines 97–181), constructor defaults (lines 42–51).

---

### 1.2 Header (`_HeaderSection` in `home_page.dart`)

| Finding | Severity | Detail |
|---------|----------|--------|
| Greeting uses sans-serif, not reference serif | **Critical** | `TextStyle(fontSize: 28, fontWeight: bold)` with default `PlusJakartaSans`. Reference: large elegant **serif** ("Hayırlı Geceler") as primary hierarchy anchor. |
| Guest name too large and wrong color weight | **High** | `fontSize: 20, w500, alpha: 0.55 white`. Reference: noticeably smaller, warm gold/bronze secondary label ("Misafir"). Current reads as co-primary, not subordinate. |
| Entire header wrapped in OrnateFrame card | **High** | Reference treats greeting area as open canvas with mosque watermark; only the countdown box is framed. Wrapping the full header adds visual weight and competes with downstream cards. |
| Premium badge uses green when non-premium | **High** | Non-premium state: `accentNeonGreen` fill/border (lines 259–268). Reference: always gold/bronze pill with crown — green reserved for time-sensitive prayer states. Violates glow/color discipline. |
| Countdown time undersized, no text glow | **High** | Countdown at `fontSize: 17`. Reference shows large luminous green time (`07:15` / `56:55`) as dominant element. No `Shadow`/`ShaderMask` glow on countdown digits. |
| Countdown frame lacks mihrab peaks | **Medium** | Nested `OrnateFrame(topAccent: true)` — diamond only. Reference has peaked top/bottom center on countdown frame. |
| Stray nightlight icon (top-left) | **Low** | `Icons.nightlight_round, size: 16` at `(8, 6)` — not in reference; adds noise to header composition. |
| Header inner padding tight on right | **Low** | `padding: fromLTRB(14, 10, 10, 10)` — countdown column feels cramped against frame edge vs reference breathing room. |

**Code targets:** `_HeaderSection.build()` (lines 171–435), Premium badge decoration (lines 252–295), nested countdown `OrnateFrame` (lines 317–423).

---

### 1.3 Daily Wisdom Card (`daily_namaz_wisdom_card.dart`)

| Finding | Severity | Detail |
|---------|----------|--------|
| Section title color is white, not gold | **High** | `titleC` = white @ 0.92 on dark. Reference: "Bugünün hatırlatıcısı" in **gold** with sparkle icon — title should be ornament-colored, not body-colored. |
| Quotation marks too small and faint | **High** | `Icons.format_quote_rounded, size: 18, alpha: 0.28`. Reference: large, elegant gold double-quote marks as a focal typographic element above centered quote. |
| Quote body too small | **Medium** | `fontSize: 12, height: 1.34`. Reference quote occupies more vertical presence with comfortable line length. |
| Shimmer animation on load | **Medium** | `.shimmer(delay: 450ms, duration: 1.6s)` — reference is static, premium, no motion shimmer. Adds visual noise inconsistent with "glow discipline." |
| Icon choice | **Low** | `Icons.auto_awesome_rounded` vs reference four-point gold star/sparkle — minor semantic mismatch. |
| Padding slightly tight vertically | **Low** | `fromLTRB(16, 11, 16, 12)` — reference shows more vertical breathing room between title block and quote. |

**Code targets:** title row (lines 80–97), quote icon (lines 113–117), quote text (lines 119–137), `.animate().shimmer()` chain (lines 143–155).

---

### 1.4 Namaz Ritual Section (`home_namaz_ritual_section.dart`)

| Finding | Severity | Detail |
|---------|----------|--------|
| SalatPrayerRow highlights **completed** prayers, not **current window** | **Critical** | Reference: "İkindi" glows as the active/current prayer period. Implementation (`salat_prayer_row.dart`): green fill/glow only when `done == true`. Wrong semantic — breaks the "where am I in the day?" hierarchy the reference communicates. |
| Inactive triangle color is cream, not bronze | **High** | Dark mode inactive: `AppColors.creamBase @ 0.28`. Reference inactive icons: muted **gold/bronze** thin strokes, harmonized with ornament palette. |
| Notification sub-card breaks ornamental system | **High** | Nested `Container` with `Colors.black @ 0.22`, `border: white @ 0.06` (lines 286–303). Reference: notification row is inline within the same ornate card, gold bell icon, gold-bordered custom toggle — no nested gray panel. |
| Toggle is stock Material `Switch.adaptive` | **High** | `NamazAdhanReminderCard(compact: true)` uses default switch with green thumb. Reference: custom toggle with gold border and gold circular handle. |
| Reminder icon color is green, not gold | **Medium** | `Icons.notifications_active_outlined` with `accentNeonGreen`. Reference: thin-stroke **gold** bell. |
| Progress subtitle too faint on dark | **Medium** | `Colors.white @ 0.38` (line 256). Reference secondary line ("Bugün 1/5 • Detaylar için dokun") is readable muted gray, not near-invisible. |
| Setup vs active card surface mismatch | **Low** | Setup CTA uses gradient; active tracking uses flat `homeCardSurface @ 0.72`. Acceptable functionally, but surface treatment differs from wisdom/prayer cards' gradient pattern. |
| Asymmetric inner padding | **Low** | Tracking header `14,12,14,8` vs reminder wrapper `10,0,10,10` — vertical rhythm uneven. |

**Code targets:** `home_namaz_ritual_section.dart` active branch (lines 198–311); downstream `salat_prayer_row.dart` color logic (lines 140–175); `namaz_adhan_reminder_card.dart` compact branch (lines 422–501).

---

### 1.5 Prayer Times Block (`_PrayerTimesBlock` in `home_page.dart`)

| Finding | Severity | Detail |
|---------|----------|--------|
| Border radius inconsistency | **High** | Section uses `borderRadius: 22` while wisdom/ritual/header use `20`. Reference maintains uniform corner language across all major cards. |
| Tile icons in filled circular badges | **Medium** | 24×24 circle with fill + border behind 14px Material icon. Reference: thin-line icons sitting directly on card surface without heavy circular containers — lighter icon weight. |
| Active tile glow is good but border+glow+shadow stack heavy | **Medium** | `border width: 1.5`, `accentGlowGreen shadow blur: 18`, plus OrnateFrame brackets. Reference glow is softer, border-integrated — less "neon UI component." |
| Section title hierarchy | **Low** | `fontSize: 13, w700, white` — reference title "Namaz Vakitleri" is slightly more prominent with clock icon; current is acceptable but secondary to greeting. |
| Location row underline | **Low** | City label has `TextDecoration.underline` — reference uses plain pin + label + date chevron without underline decoration. |
| Skeleton/error states skip OrnateFrame | **Low** | `_PrayerTimesSkeleton` and `_PrayerTimesError` lack `OrnateFrame` wrapper — loading/error breaks ornamental consistency. |
| Grid spacing | **Low** | `mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.92` — functional; reference tiles appear slightly taller with more internal padding (`8,8,8,7` current). |

**Code targets:** `_PrayerTimesList` OrnateFrame params (lines 498–501), `_PrayerTimeTile` icon container (lines 687–699), active glow (lines 672–679), `_PrayerTimesSkeleton` (lines 767–877).

---

### 1.6 Page-Level Layout (`home_page.dart` build)

| Finding | Severity | Detail |
|---------|----------|--------|
| Vertical spacing rhythm inconsistent | **Medium** | Header→Wisdom: `16`; Wisdom→Ritual: `12`; Ritual→PrayerTimes: `12`. Reference implies uniform card stack rhythm (~16px). |
| Horizontal page padding | **Low** | `horizontal: 24` — reasonable; reference appears ~20–24, acceptable. |
| Card order and information architecture | **None** | Matches reference: Header → Wisdom → Tracking → Prayer Times. ✓ |

**Code targets:** `Column` children spacing (lines 111–115).

---

## 2. What Already Matches the Reference

- **Color palette foundation:** Dark emerald shell (`homeCardSurface`, gradient stops) + warm bronze ornament tokens (`ornamentGold`, `ornamentGoldDeep`) align with reference's forest-green + gold/bronze language.
- **Card layering:** Gradient fills, subtle gold box-shadows, and mosque watermark silhouettes in header/prayer-times blocks echo reference depth.
- **Section order:** Greeting → daily reminder → namaz tracking → prayer times grid matches reference IA.
- **Prayer-times grid structure:** 3×2 grid with six vakit tiles, clock icon section header, location + date row — structurally correct.
- **Next-prayer tile highlight:** Green border, green time digits, "Sıradaki vakit" hint, and glow shadow on active tile — strongest reference match in the codebase.
- **Countdown widget concept:** Separate framed countdown with prayer name label and green time — correct component, needs shape/scale polish.
- **OrnateFrame as shared primitive:** Single decorator applied across cards — right architectural choice for consistency (params need unification).
- **Wisdom card content model:** Title + source subtitle ("Hadis-i Şerif") + centered quote — content hierarchy matches.
- **Namaz tracking chevron affordance:** Tappable row with title, progress line, and `chevron_right` — matches reference interaction pattern.
- **Thin stroke intent:** OrnateFrame hairline at 1.0px and bracket caps rounded — directionally aligned with reference fine-line aesthetic.

---

## 3. What Still Feels Off (Micro Details)

| Area | Micro-detail gap |
|------|------------------|
| Corner motifs | Reference corners have curved/swirling density; code draws 3-segment L-brackets only |
| Line thickness | Cards: 1.1px container + 1.0px OrnateFrame + 1.6px brackets = three weights; reference: one uniform hairline |
| Padding | Header right column cramped; wisdom quote vertical space tight; ritual reminder nested inset breaks outer card padding grid |
| Icon weight | Prayer tile icons heavy (filled circle bg); salat triangles 1.6px stroke but only 12px in compact — reference icons are uniform thin gold outlines |
| Icon color | Functional icons (bell, schedule, sparkle) lean green or white; reference keeps decorative icons in gold family |
| Typography | Zero serif on home; reference greeting is unmistakably serif/display |
| Glow discipline | Green on: countdown ✓, next tile ✓, but also: done triangles ✗, non-premium badge ✗, switch thumb ✗, wisdom shimmer ✗ |
| Frame shape | Countdown lacks mihrab peaks; header shouldn't share same frame language as content cards |
| Toggle craft | Stock `Switch.adaptive` vs reference bespoke gold-bordered pill toggle |
| Surface nesting | Reminder row sits in a second inner card (`black @ 0.22`) — creates a "card inside card" seam absent in reference |
| Border radius | 20 vs 22 vs 18 (countdown) vs 12 (tiles) — four radii on one screen |
| Animation | Wisdom card fade+slide+shimmer — reference feels still and confident |
| Text alpha ladder | Too many similar white alphas (0.92, 0.9, 0.88, 0.55, 0.38) — hierarchy muddied vs reference's clear white/gold/muted-gray tiers |

---

## 4. Prioritized Fix Backlog

### P0 — Identity-breaking (fix first)

| # | Fix | Concrete code target |
|---|-----|---------------------|
| P0-1 | **Remove double-border:** Choose one stroke owner — either OrnateFrame hairline OR Container border, not both. Prefer OrnateFrame as single source; drop `Border.all` from card containers or set `drawBorder: false` everywhere and unify. | All `OrnateFrame` consumers in `home_page.dart`, `daily_namaz_wisdom_card.dart`, `home_namaz_ritual_section.dart`; `_OrnateFramePainter` alpha/width |
| P0-2 | **SalatPrayerRow: glow current prayer window, not done state** (or dual: done=fill, current=glow). Add `currentPrayerIndex` from `prayerTimesProvider` / `nextPrayer` logic. | `salat_prayer_row.dart` lines 140–175; wire from `home_namaz_ritual_section.dart` line 278 |
| P0-3 | **Header greeting → serif display face** (Playfair Display or existing `AppTextStyles` serif token). Demote guest name to ~14–15px gold-muted. | `home_page.dart` `_HeaderSection` lines 221–238 |
| P0-4 | **Premium badge: always gold/bronze** — remove green from non-premium state. | `home_page.dart` lines 257–269 |
| P0-5 | **Wisdom card title → gold ornament color** | `daily_namaz_wisdom_card.dart` lines 36–38, 88–96 |

### P1 — Noticeable craftsmanship gaps

| # | Fix | Concrete code target |
|---|-----|---------------------|
| P1-1 | **Unify OrnateFrame params** across section cards: `borderRadius: 20, inset: 7, armLength: 15` everywhere (prayer-times currently 22/8/18). | `home_page.dart` `_PrayerTimesList` line 498–501 |
| P1-2 | **Enlarge + glow countdown digits** (`fontSize: 22–24`, green `Shadow` blur). | `home_page.dart` lines 403–418 |
| P1-3 | **Enlarge wisdom quotation marks** (28–32px, `ornamentGold @ 0.55–0.70`), reduce quote to secondary visual weight. | `daily_namaz_wisdom_card.dart` lines 113–117 |
| P1-4 | **Flatten reminder row into parent card** — remove nested dark container; inline gold bell + custom toggle. | `home_namaz_ritual_section.dart` lines 284–303; `namaz_adhan_reminder_card.dart` compact branch |
| P1-5 | **Unwrap header from OrnateFrame** — keep frame only on countdown widget. | `home_page.dart` `_HeaderSection` lines 171–435 |
| P1-6 | **Inactive salat triangles → ornamentGold muted stroke** instead of creamBase. | `salat_prayer_row.dart` lines 144–150 |
| P1-7 | **Remove wisdom card shimmer** animation. | `daily_namaz_wisdom_card.dart` lines 151–155 |
| P1-8 | **Prayer tile icons: drop filled circle**, use thin gold/green outline icon directly. | `home_page.dart` `_PrayerTimeTile` lines 687–699 |
| P1-9 | **Implement mihrab peak path** on countdown OrnateFrame (`topAccent` → architectural peak top+bottom). | `ornate_frame.dart` `topAccent` block lines 160–181 |

### P2 — Polish and consistency

| # | Fix | Concrete code target |
|---|-----|---------------------|
| P2-1 | Reduce bracket `strokeWidth` from 1.6 → 1.0–1.2; increase `armLength` slightly for density without heaviness. | `ornate_frame.dart` line 122 |
| P2-2 | Normalize vertical section gaps to uniform `16`. | `home_page.dart` lines 111–115 |
| P2-3 | Remove header stray `nightlight_round` icon. | `home_page.dart` lines 201–212 |
| P2-4 | Remove location row underline; use plain muted text. | `home_page.dart` `_LocationRow` lines 1015–1022 |
| P2-5 | Add `OrnateFrame` to skeleton/error prayer-times states. | `home_page.dart` `_PrayerTimesSkeleton`, `_PrayerTimesError` |
| P2-6 | Standardize text alpha ladder: primary white, secondary gold @ 0.55, tertiary gray @ 0.45 — reduce intermediate alphas. | All four scoped files |
| P2-7 | Optional: richer corner motif paths (quadratic curves) in `_OrnateFramePainter` for reference flourish density. | `ornate_frame.dart` `_OrnateFramePainter` |
| P2-8 | Bump wisdom quote to `fontSize: 13–14`, increase card vertical padding. | `daily_namaz_wisdom_card.dart` lines 52, 119–127 |
| P2-9 | Custom gold-bordered toggle widget shared by reminder card. | New widget or extend `namaz_adhan_reminder_card.dart` |
| P2-10 | Progress subtitle alpha 0.38 → 0.50–0.55 on dark. | `home_namaz_ritual_section.dart` line 256 |

---

## 5. Stroke & Spacing Reference Sheet (Current vs Target)

| Token | Current (code) | Reference intent | Action |
|-------|----------------|------------------|--------|
| Section card radius | 20 (most), 22 (prayer times) | Uniform ~20 | Unify to 20 |
| Tile radius | 12 | ~12 | OK |
| Countdown radius | 18 | ~16–18 with peaks | Add peaks |
| Outer card border | 1.1px @ 0.38α | Single 1.0px gold hairline | Remove duplicate |
| Ornate hairline | 1.0px @ 0.30α | ~1.0px @ 0.45α | Single owner, raise alpha |
| Bracket stroke | 1.6px @ 0.72α | ~1.0px @ 0.65α | Lighten |
| Section vertical gap | 16 / 12 / 12 | ~16 uniform | Normalize |
| Card inner padding | 14–18px | ~16px uniform | Minor tune |
| Countdown time size | 17px | ~22–24px + glow | Enlarge |
| Greeting size | 28px sans | ~28–32px serif | Font swap |

---

## 6. Glow Discipline Matrix

| Element | Reference | Current | Verdict |
|---------|-----------|---------|---------|
| Countdown digits | Green glow | Green flat text | ⚠ Partial |
| Next prayer tile | Green border glow | Green border + shadow | ✓ Good |
| Current prayer in tracking row | Green icon glow | No current-window glow | ✗ Wrong |
| Completed prayer ticks | Subtle fill, no glow | Green fill + label | ✗ Over-glow |
| Premium badge | Gold static | Green when free | ✗ Wrong color |
| Wisdom card | Static | Shimmer pass | ✗ Unnecessary |
| Notification switch | Gold handle | Green Material switch | ✗ Off-palette |

---

## 7. Recommended Implementation Order

1. **Stroke unification** (P0-1) — single pass across all home cards; immediate visual coherence gain.
2. **Typography + color hierarchy** (P0-3, P0-4, P0-5) — cheap changes, high reference fidelity.
3. **SalatPrayerRow semantics** (P0-2) — requires provider wiring but fixes misleading UX.
4. **Header restructure** (P1-5, P1-2, P1-9) — countdown becomes hero framed element.
5. **Reminder row inline** (P1-4, P2-9) — removes nested-card seam.
6. **Ornament polish** (P1-1, P2-1, P2-7) — incremental painter improvements.

---

*End of Agent C audit. No code changes made.*
