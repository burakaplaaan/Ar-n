# Home Page Bronze / Active-Green Style Audit (Agent B)

**Date:** 2026-06-15  
**Scope:** Token-level audit of home page sections against reference screenshots (dark mode, bronze ornaments + green active states).  
**Files inspected:**

| File | Symbol(s) |
|------|-----------|
| `lib/core/constants/app_colors.dart` | `AppColors.*` |
| `lib/presentation/shared/widgets/ornate_frame.dart` | `OrnateFrame`, `_OrnateFramePainter` |
| `lib/presentation/home/home_page.dart` | `HomePage`, `_HeaderSection`, `_PrayerTimesBlock`, `_PrayerTimesList`, `_PrayerTimeTile`, `_LocationRow`, skeleton/error |
| `lib/presentation/home/widgets/daily_namaz_wisdom_card.dart` | `DailyNamazWisdomCard`, `_DailyNamazWisdomBody` |
| `lib/presentation/home/widgets/home_namaz_ritual_section.dart` | `HomeNamazRitualSection` |
| *(embedded, out-of-scope but visible on home)* | `SalatPrayerRow`, `NamazAdhanReminderCard` (compact) |

**Reference intent (from screenshots):**

- **Bronze/brown (`ornamentGold` family):** card hairlines, corner brackets, inactive prayer tiles, meta text, decorative icons, Premium badge chrome, notification toggle chrome when off.
- **Neon green (`accentNeonGreen` family):** countdown digits, *next/current* prayer highlight, completed prayer ticks, switch thumb when ON.
- **Never mix:** green must not appear on static/decorative chrome; bronze must not appear on live “active window” indicators.

---

## 1. Color Token Inventory (Dark Mode Home Sections)

### 1.1 Palette constants referenced (`AppColors`)

| Token | Hex | Role on home |
|-------|-----|--------------|
| `homeGradientTop` | `#030806` | Shell background (via `ArinShellBackground`) |
| `homeGradientMid` | `#0A1610` | Shell background mid-stop |
| `homeGradientBottom` | `#050A07` | Shell background bottom-stop |
| `homeCardSurface` | `#142A22` | Card fill base |
| `ornamentGold` | `#B88E47` | Dark-shell ornament / inactive accent |
| `ornamentGoldDeep` | `#9D7438` | Light-shell ornament (not used on dark home) |
| `accentNeonGreen` | `#4ADE80` | Active / countdown / done / switch-on |
| `accentGlowGreen` | `#22C55E` | Active tile outer glow |
| `accentGreenOnLight` | `#2F8F68` | Light-theme active (not used on dark home) |
| `goldAccent` | `#FFD700` | Premium badge when subscribed |
| `emeraldDark` | `#1B4D3E` | Light-theme text only |
| `emeraldMid` | `#2D7A5F` | Error retry button bg |
| `textOnDark` | `#F5F0E8` | *(defined, not directly used — `Colors.white` used instead)* |
| `textOnDarkMuted` | `#B2C4B6` | Salat row inactive labels |
| `creamBase` | `#DAD4C9` | Salat row inactive triangle tint |
| `error` | `#C0392B` | Error card border |
| `warning` | `#B8860B` | Unavailable notification hint |

### 1.2 Inline / non-token colors

| Location | Value | Role |
|----------|-------|------|
| `_PrayerTimesList` gradient end | `#0A120E` @ 0.94 | Card gradient bottom |
| `_PrayerTimeTile` inactive bg | `#081A14` @ 0.90 / 0.98 | Tile fill |
| `_HeaderSection` urgent fajr | `#2A1710` @ 0.92, `#FFA726`, `#FFB74D`, `#FFCC80` | Urgent countdown variant |
| `HomeNamazRitualSection` setup gradient end | `#0F1612` @ 0.85 | Setup card gradient |
| `HomeNamazRitualSection` nested reminder well | `Colors.black` @ 0.22 | Inner well fill |
| `NamazAdhanReminderCard` compact | `Colors.white` @ 0.05 / 0.04 / 0.35 | Surfaces, borders, icons |

### 1.3 Alpha usage patterns (dark mode)

#### `OrnateFrame` / `_OrnateFramePainter` (`ornate_frame.dart`)

| Element | Base token | Alpha | Effective role |
|---------|-----------|-------|----------------|
| Hairline border | `ornamentGold` or override | **0.30** | Subtle card outline |
| Corner brackets | same | **0.72** | Visible L-brackets |
| Top diamond fill | same | **0.88** | Next-prayer card accent |
| Top diamond tick strokes | same | **0.50** | Decorative flanking lines |

#### `_HeaderSection` (`home_page.dart`)

| Element | Color source | Alpha |
|---------|-------------|-------|
| Card fill | `homeCardSurface` | 0.42 |
| Card border | `ornamentGold` | 0.32 |
| Mosque watermark | `Colors.white` | 0.06 |
| Night icon | `ornamentGold` | 0.34 |
| Subtitle | `Colors.white` | 0.55 |
| Premium badge fill/border/icon (non-premium) | `accentNeonGreen` | 0.15 / 0.45 / 1.0 |
| Next-prayer card fill | `homeCardSurface` | 0.85 |
| Next-prayer card border | `ornamentGold` | 0.56 |
| Next-prayer card shadow | `ornamentGold` | 0.18 |
| Badge label text | `Colors.white` | 0.55 |
| Prayer name text | `Colors.white` | 0.85 |
| **Countdown digits** | `accentNeonGreen` | **1.0** |

#### `DailyNamazWisdomCard` (`daily_namaz_wisdom_card.dart`)

| Element | Color source | Alpha |
|---------|-------------|-------|
| Card gradient top | `homeCardSurface` | 0.88 |
| Card gradient bottom | `#0A120E` | 0.94 |
| Border / shadow | `ornamentGold` | 0.38 / 0.16 |
| Title icon | `ornamentGold` | 0.95 |
| Title text | `Colors.white` | 0.92 |
| Source line | `Colors.white` | 0.56 |
| Quote icon | `ornamentGold` | 0.28 |
| Body text | `Colors.white` | 0.90 |
| Shimmer overlay | `ornamentGold` | 0.06 |

#### `HomeNamazRitualSection` (`home_namaz_ritual_section.dart`)

| Element | Color source | Alpha |
|---------|-------------|-------|
| Card fill (tracking) | `homeCardSurface` | 0.72 |
| Card border / shadow | `ornamentGold` | 0.35 / 0.15 |
| Title | `Colors.white` | 0.92 |
| Progress subtitle | `Colors.white` | 0.38 |
| Chevron | `Colors.white` | 0.35 |
| Inner reminder well fill | `Colors.black` | 0.22 |
| Inner well border | `Colors.white` | 0.06 |

#### `_PrayerTimesList` / `_PrayerTimeTile` (`home_page.dart`)

| Element | Color source | Alpha |
|---------|-------------|-------|
| Block gradient / border / shadow | `ornamentGold` | 0.88→0.94 / 0.38 / 0.16 |
| Schedule icon | `ornamentGold` | 0.95 |
| Meta row (location, date) | `Colors.white` | 0.45–0.90 |
| **Inactive tile** border | `ornamentGold` | 0.22 |
| **Inactive tile** icon bg / border / color | `ornamentGold` | 0.12 / 0.20 / 0.60 |
| **Inactive tile** time text | `Colors.white` | 0.90 |
| **Active tile** border | `accentNeonGreen` | 0.72 |
| **Active tile** time / hint | `accentNeonGreen` | 0.98 / 0.90 |
| **Active tile** icon bg / border | `accentNeonGreen` | 0.20 / 0.45 |
| **Active tile** glow | `accentGlowGreen` | 0.20 |

#### Embedded: `SalatPrayerRow` (via `HomeNamazRitualSection`)

| Element | Color source | Alpha |
|---------|-------------|-------|
| Done triangle + label | `accentNeonGreen` | 1.0 / 0.95 |
| Undone triangle | `creamBase` | 0.28 (tappable) / 0.12 |
| Undone label | `textOnDarkMuted` | 1.0 / 0.45 |

#### Embedded: `NamazAdhanReminderCard` compact

| Element | Color source | Alpha |
|---------|-------------|-------|
| Bell / EQ icons | `accentNeonGreen` | 0.88 |
| Switch thumb (on) | `accentNeonGreen` | 1.0 |
| Inner well border (via parent) | `Colors.white` | 0.06 |
| *(card itself has no bronze border — parent provides ornament)* | — | — |

#### Page chrome

| Element | Color source | Alpha |
|---------|-------------|-------|
| `RefreshIndicator` color | `accentNeonGreen` | 1.0 |
| `RefreshIndicator` background | `homeCardSurface` | 1.0 |

---

## 2. Green Used Where Bronze Should Be (Mis-assignments)

| # | Location | Symbol / lines | Current | Expected (per reference) | Severity |
|---|----------|----------------|---------|--------------------------|----------|
| **G-1** | `_HeaderSection` Premium badge (non-premium) | `home_page.dart` ~L258–279 | `accentNeonGreen` @ 0.15 fill, 0.45 border, full icon | `ornamentGold` or `goldAccent` @ similar alphas; crown icon gold/bronze | **High** — only decorative CTA, not a live state |
| **G-2** | `NamazAdhanReminderCard` compact (off state) | `namaz_adhan_reminder_card.dart` ~L402–446 | Bell icon + row chrome use `accentNeonGreen` @ 0.88 even when `displayOn == false` | Bronze ornament for icon/border when off; green only for ON switch thumb + enabled subtitle | **High** — screenshot shows bronze bell + bronze toggle track when off |
| **G-3** | `NamazAdhanReminderCard` compact inner border | Parent well in `home_namaz_ritual_section.dart` L296–299 | `Colors.white` @ 0.06 | `ornamentGold` @ ~0.22–0.30 for nested bronze hairline | **Medium** — reads as neutral grey, not warm ornament |
| **G-4** | `SalatPrayerRow` undone triangle tint | `salat_prayer_row.dart` ~L148–149 | `creamBase` @ 0.28 / 0.12 | `ornamentGold` @ ~0.35–0.45 stroke (matches inactive prayer tile icons) | **Medium** — cream reads cool/grey on dark green shell, breaks bronze family |
| **G-5** | `_PrayerTimesSkeleton` placeholder glow | `home_page.dart` ~L848–854 | `accent.withValues(alpha: 0.22)` on skeleton tile index 4 | Acceptable (bronze accent) — **not a mis-assignment**; listed for completeness | Low |

### Notes on G-1 vs screenshots

Both reference screenshots show the Premium control with **bronze border and gold crown**, not neon green. The current implementation treats non-premium as a green-accent chip, conflating marketing chrome with prayer-active semantics.

### Notes on G-2 vs screenshots

Screenshot 2 explicitly describes the notification row as bronze-toned when off (“bronze bell icon”, “toggle with bronze border”, slider in bronze/grey). Current code assigns the same green `accent` variable regardless of `displayOn`.

---

## 3. Bronze Used Where Active-Green Should Be (Regressions)

| # | Location | Finding | Verdict |
|---|----------|---------|---------|
| **B-1** | `_PrayerTimeTile` when `isNext == true` | Border, time, hint, icon, glow all use `accentNeonGreen` / `accentGlowGreen` | **Correct** — matches screenshot active tile (Yatsı green glow) |
| **B-2** | `_HeaderSection` countdown | `accentNeonGreen` full opacity | **Correct** |
| **B-3** | `SalatPrayerRow` done state | Green fill/stroke on triangle + label | **Correct for completed** |
| **B-4** | Current prayer window highlight in `SalatPrayerRow` | **Not implemented** — only `done` toggles green; screenshot shows **İkindi** highlighted as current period (with glow) while progress is 1/5 | **Gap, not a bronze regression** — missing feature rather than wrong color |
| **B-5** | `_PrayerTimeTile` inactive time text | `Colors.white` @ 0.90 instead of bronze | **Acceptable** — screenshot shows time digits in muted tan/bronze on inactive tiles; white @ 0.90 is slightly cooler/brighter than reference but not a green→bronze regression |
| **B-6** | Active prayer name in header next card | `Colors.white` @ 0.85, not green | Screenshot shows prayer name in cream/white and **only countdown in green** — **Correct** |

**Conclusion:** No confirmed case of active-green being accidentally replaced by bronze in live-state indicators. The primary risk is the inverse (G-1, G-2).

---

## 4. Contrast & Readability (Dark Mode)

| Area | Foreground | Background (approx.) | Est. contrast | Concern |
|------|-----------|----------------------|---------------|---------|
| Header greeting | `#FFFFFF` | `#142A22` @ 42% over `#030806` ≈ `#0E1A15` | ~15:1 | ✅ Excellent |
| Header subtitle | `#FFFFFF` @ 55% | same | ~7:1 | ✅ Good |
| Progress subtitle (namaz section) | `#FFFFFF` @ 38% | `#142A22` @ 72% | ~3.2:1 | ⚠️ **Below WCAG AA (4.5:1)** for 11px body |
| Wisdom source line | `#FFFFFF` @ 56% | card ≈ `#101E18` | ~4.8:1 | ✅ Borderline AA for 9.5px |
| Quote icon | `ornamentGold` @ 28% on `#101E18` | ~2.5:1 | ⚠️ Decorative only — OK |
| Ornate hairline | `ornamentGold` @ 30% | dark card | ~1.8:1 | ⚠️ Very subtle; matches reference “hairline” intent |
| Inactive prayer tile time | `#FFFFFF` @ 90% | `#081A14` @ 90% | ~12:1 | ✅ Strong (brighter than reference muted bronze) |
| Inactive tile icon | `ornamentGold` @ 60% | `#081A14` | ~4.0:1 | ⚠️ Slightly below AA for 14px icon |
| Active tile time | `#4ADE80` @ 98% | `#081A14` | ~9:1 | ✅ Excellent |
| Location meta row | `#FFFFFF` @ 45% | card surface | ~4.6:1 | ✅ AA for 12px |
| Namaz reminder subtitle (off) | `textOnDarkMuted` `#B2C4B6` | `#000` @ 22% well | ~5:1 | ✅ Acceptable |

### Readability themes

1. **Ornament opacity stack is consistent** (0.30 hairline → 0.72 brackets → 0.88 diamond) but hairlines may disappear on low-brightness OLED; reference accepts this.
2. **`Colors.white` alphas are used ad hoc** instead of `textOnDark` / `textOnDarkMuted` tokens — makes systematic contrast tuning harder.
3. **Progress line at 38% white** is the weakest readable text on the home scroll surface.
4. **Green-on-dark active states** have strong contrast; no readability issue.

---

## 5. Recommended Normalized Palette

Proposed tokens to consolidate scattered inline alphas. Values tuned to reference screenshots (`~#C5A059` ornament family, `~#26E58B` active family) while staying close to existing `AppColors` naming.

| Semantic role | Token name (proposed) | Hex | Typical alpha (dark) | Used for |
|---------------|----------------------|-----|----------------------|----------|
| **Shell background** | `homeGradientTop` *(keep)* | `#030806` | 1.0 | Page gradient |
| **Shell background mid** | `homeGradientMid` *(keep)* | `#0A1610` | 1.0 | Page gradient |
| **Card surface** | `homeCardSurface` *(keep)* | `#142A22` | 0.72–0.88 | Card fills |
| **Card surface deep** | `homeCardSurfaceDeep` *(new)* | `#0A120E` | 0.94 | Gradient end stop |
| **Ornament base** | `ornamentGold` *(shift)* | `#C5A059` | 1.0 | Brackets, icons — slightly warmer than current `#B88E47` |
| **Ornament deep** | `ornamentGoldDeep` *(keep, retune)* | `#A88442` | 1.0 | Light theme |
| **Ornament hairline** | — | `ornamentGold` | **0.28–0.32** | `OrnateFrame` border, card `Border.all` |
| **Ornament bracket** | — | `ornamentGold` | **0.70–0.75** | Corner L-brackets |
| **Ornament icon (muted)** | — | `ornamentGold` | **0.55–0.65** | Inactive prayer icons, chevrons |
| **Ornament icon (strong)** | — | `ornamentGold` | **0.90–0.95** | Section header icons, mosque setup icon |
| **Ornament shadow/glow** | — | `ornamentGold` | **0.14–0.18** | Card `BoxShadow` |
| **Ornament nested border** | — | `ornamentGold` | **0.22–0.30** | Reminder well, toggle track (off) |
| **Active base** | `accentNeonGreen` *(keep)* | `#4ADE80` | 1.0 | Countdown, active tile text/icon |
| **Active alt** | `accentGlowGreen` *(keep)* | `#22C55E` | 1.0 | Glow color base |
| **Active border** | — | `accentNeonGreen` | **0.65–0.75** | Next prayer tile outline |
| **Active glow** | — | `accentGlowGreen` | **0.18–0.22** | `BoxShadow` on active tile |
| **Active icon well** | — | `accentNeonGreen` | **0.18–0.22** | Circle behind active prayer icon |
| **Active subtle bg** | — | `accentNeonGreen` | **0.10–0.12** | Done triangle fill, switch track on |
| **Premium gold** | `goldAccent` *(keep)* | `#FFD700` | 0.15–1.0 | Premium badge |
| **Text primary on dark** | `textOnDark` *(use consistently)* | `#F5F0E8` | 0.92–1.0 | Titles |
| **Text secondary on dark** | `textOnDarkMuted` *(use consistently)* | `#B2C4B6` | 1.0 | Subtitles — replace `Colors.white` @ 0.38 |
| **Text tertiary on dark** | *(new)* `textOnDarkSubtle` | `#F5F0E8` | **0.55–0.60** | Meta, guest name |

### Decision matrix (apply when implementing)

```
Decorative chrome (frames, chevrons, inactive icons, off-state controls) → ornamentGold @ tier
Live prayer state (next vakit, countdown, done tick, switch ON)         → accentNeonGreen @ tier
Marketing premium chrome                                                 → goldAccent / ornamentGold (never green)
```

---

## 6. Section-by-Section Compliance Summary

| Section | Ornament compliance | Active-green compliance | Top issue |
|---------|--------------------|-------------------------|-----------|
| Shell / scroll | N/A (gradient only) | RefreshIndicator green OK | — |
| Header + OrnateFrame | ✅ Bronze borders/brackets | ✅ Countdown green | Premium badge uses green (G-1) |
| Daily wisdom card | ✅ Full bronze accent | N/A (no active state) | Quote icon very faint (0.28) |
| Namaz ritual section | ✅ Card chrome bronze | ⚠️ Embedded reminder uses green when off (G-2) | Reminder row color role |
| Prayer times grid | ✅ Inactive bronze, active green | ✅ Correct split | Inactive time text is white not bronze (minor) |
| Salat prayer row | ⚠️ Undone uses cream not bronze (G-4) | ✅ Done = green; ⚠️ no current-window green | Missing current-prayer highlight vs screenshot |

---

## 7. Priority Fix List (Recommendations Only — No Code Changes)

1. **P0 — Premium badge (`_HeaderSection`):** Swap non-premium accent from `accentNeonGreen` → `ornamentGold` / `goldAccent`.
2. **P0 — Notification row off-state (`NamazAdhanReminderCard` compact):** Branch icon/border color on `displayOn`; bronze when off, green when on.
3. **P1 — Salat undone triangles:** Replace `creamBase` inactive tint with `ornamentGold` stroke alphas to match prayer tile icons.
4. **P1 — Progress subtitle contrast:** Raise from `Colors.white` @ 0.38 → `textOnDarkMuted` or white @ ≥0.50.
5. **P2 — Token hygiene:** Replace scattered `Colors.white.withValues(alpha: …)` with named text tokens.
6. **P2 — Current prayer window in `SalatPrayerRow`:** Add third visual state (current period glow) distinct from done/not-done — reference screenshot expectation.
7. **P3 — Ornament hue tune:** Evaluate `#B88E47` → `#C5A059` for closer screenshot match (A/B on device).

---

## 8. Reviewer Sign-off (Agent B)

This audit is **read-only**; no application code was modified. Findings are based on static analysis of the listed files and comparison against the two attached reference screenshots emphasizing bronze ornament vs green active-state separation.

**Overall assessment:** The home page architecture correctly routes ornament through `OrnateFrame` + `ornamentGold` and reserves `accentNeonGreen` for prayer-time active tiles and countdown. **Two high-severity mis-assignments** remain (Premium badge, notification off-state). **No active-green → bronze regressions** were found in live-state indicators. Contrast is generally strong except the namaz progress subtitle and very faint ornament hairlines.

— **Agent B (Independent Reviewer)**
