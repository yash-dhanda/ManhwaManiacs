# Cinematic DESIGN.md: consistency recheck, round 1

Input: the "Confirmed" section of `cinematic/verify-sweep/judge-consistency.md` (27 findings; CONSISTENCY-13 and CONSISTENCY-22 were refuted and are out of scope) and the fixer's log `cinematic/verify-sweep/fixed-consistency.md`. Each final fix was checked against `cinematic/DESIGN.md` (4,737 lines) by reading the edited passages and grepping for the old values and for every other place the changed value is repeated. Key citations were checked against `inventory/web.md` (web K1–K51) and `inventory/mobile.md` (mobile K01–K40). Arithmetic was re-run (auto-scroll mapping, sound budget, ×3 mood hexes, Hyperlegible line heights, Post card sizes). DESIGN.md was not edited.

Result: **24 resolved, 3 unresolved** (CONSISTENCY-9, CONSISTENCY-14, CONSISTENCY-16). All three are low-severity residues: the requested edits were made, but each leaves a second place in the contract that now disagrees with the edit.

---

## Verdicts

| ID | Verdict | Evidence |
|---|---|---|
| 1 | Resolved | §2.4 Focus light row (line 281), §2.8.2 `focus.*` row (line 474: `focusHalo` = `6.0`, black `BorderSide` width 6 then ink ring on the rect inflated 2 px, both `strokeAlignOutside`), §7 intro (line 1042), §14.4 (line 4234: "paints the bone stroke over a `#000000` band from the edge out to 6 px"). No `focusHaloWidth` and no "2 px further out" left anywhere. §7.1's primary Focused state ("ring outside a 2 px `#000` gap") agrees with the 0–6 px band. |
| 2 | Resolved | §2.8.3 `scrim.head` / `scrim.sole` rows (lines 494–495): every stop is `color-mix(in srgb, var(--scrim-base, #000000) P%, transparent)`, flat stop 88 % / 90 %, P written as a literal; `--scrim-base` unregistered, set only on the reader chrome root while page-tinted chrome is on; Flutter `scrimHead(bar, fade, {Color? tint})` / `scrimSole(…)` with `Color.lerp(black, tint, 0.25)`. Pointers updated in §2.1.4 (line 119), §8.14.3 Page tint (line 2259), §9.4.4 Applied to (line 3621). §15.7 over-art row added (line 4502). §2.1.5 (line 179) still writes `--page-tint` on the chrome root, which is where `--scrim-base` reads it. |
| 3 | Resolved | §9.1.5 Skip recap, Continue and countdown bullets (lines 3226–3228) all use the entry rule; Entry behaviours (line 3237) states the same three cases. §5 `recap.countdown.end` (line 966) and §6 map cell (line 1010) carry the "only when the exit is a Column wipe" wording. §4.5 Column wipe row ("or a recap opened from them") agrees. |
| 4 | Resolved | `Newsreader(… variable: "--mm-font-newsreader")` in §3.1 Delivery (line 595) and §15.2 `fonts.ts` (line 4395); skin block `--mm-font-text: var(--mm-font-newsreader)` (lines 595, 695, 727, 4393); Hyperlegible overrides only `--mm-font-text` (line 695); novel face row (line 687) and Type sheet tile (line 2487) use `var(--mm-font-newsreader)` directly; Flutter swaps only the three roles and pins `newsreader` to the asset family (line 695). |
| 5 | Resolved | §3.4 (line 695) and §15.2 (line 4393): under `html[data-legible="on"][data-skin="cinematic"]`, `--mm-type-deck-lh` 28 / 32 / 32 / 36 px, body and body-italic 28 / 28 / 32 / 32 px; these equal §3.5's 24/28/28/32 and 24/24/28/28 (lines 711–713) + 4. Flutter adds 4.0 to each `lines` entry. |
| 6 | Resolved | §8.0.3 `onboarding` row (line 1651), §8.0.7 Onboarding row (line 1768), §8.7 intro (line 1960, including the canonical-numbering sentence), States offline (line 1985), Backend NULL rule (line 1987), Appendix B (line 4711). `PUT /profiles/{id}/taste` still documents `step` 1–5, consistent with the canonical numbering. |
| 7 | Resolved | Conventions (line 15) require `web K40` / `mobile K40`. A scan of every `K\d+` finds no bare citation; the only unprefixed tokens continue a prefixed list (`mobile K01–K03, K06 and K09–K12`, `web K24, K25, mobile K22, K23`) or sit inside a prefixed formula (`mobile K09 (v = −round((1 − K09) …))`). Spot-checked mappings all match the inventories: web K30 cinema, web K1 / mobile K30 mature, web K19–K22 / mobile K40 update checker, mobile K13 haptics, mobile K15 cover scale, mobile K17–K20 downloads, mobile K21 high refresh, web K40 / mobile K26 stock, web K44 / mobile K25 face, web K8 / mobile K36 status, web K48 / mobile K27 remembered profile. |
| 8 | Resolved | §8.14.8 Auto-scroll speed row (line 2351). Re-computed: level 1 → 20 px/s → 0.33 → 0.50×; level 5 → 108.9 px/s → 1.815 → 1.80×; level 10 → 220 px/s → 3.67 → 3.00×. No other migration statement for web K39 exists. |
| 9 | **Unresolved** | The 19 keys are in §4.2 (lines 766–786), §2.8.4 (lines 537–555) and §15.1 (lines 4341–4347) with identical values; §4.5 gained **Flame** and **Dolly** (lines 842–843); every literal of the listed durations that is a motion duration now names its key; no `dur.*` or `dur…` Dart name is used without a definition. But the fix also added a completeness claim to §4.2 (line 788: "Every motion duration in §4.5, §4.8 and §7–§9 is one of these keys and is written with it", with an exemption list for debounces, dial waits, tooltips, timeouts, thresholds, auto-next, auto-scroll resume and stagger spacings), and several motion durations and display holds in that range still have no key that names them. See "Residue" below. |
| 10 | Resolved | §4.8 Listen countdown dial row (line 898); last row now reads "leader dial (§7.18; not the countdown dial)" (line 917); §7.18 Countdown dial row points to §4.8 (line 1450). |
| 11 | Resolved | §7.11 Motion (line 1306): in 240 ms `dur.line` `ease.settle`, out 160 ms `dur.beat` `ease.lift`. §7.24 Rating card (line 1547): in 480 ms `dur.spread`, out 240 ms `dur.line`. §4.2 uses updated (lines 746, 747, 749). §4.8 toast row "240 ms rise, 240 ms push" (line 907). No stale 160 ms toast-in, 400 ms or 600 ms rating-card value remains. |
| 12 | Resolved | §10.1.5 `as: Tag = "h2"` (line 3740); conventions line 17 defines "H3" as the design name with semantic level 2; §14.5 (line 4244) agrees. |
| 14 | **Unresolved** | §6 (line 984) now reads "total set ≤ 384 KB (13 files, the twelve cues with `toggle` as on and off: 3,740 ms × 96,000 B/s = 359,040 B plus 13 × 44-byte headers …)". The arithmetic checks (cue lengths sum to 3,700 ms, + 40 ms for the second toggle = 3,740 ms; 359,040 + 572 = 359,612 B). But §15.1's `sounds` map (lines 4378–4382) still lists 12 files with one `"toggle": "press/toggle.wav"`, and §6's event map sends `toggle.on` / `toggle.off` and `reader.unlock` to the single cue `toggle` (lines 1007, 1018). An implementer following §15.1 ships 12 files and has no file for one of the two pitches. See "Residue" below. |
| 15 | Resolved | §9.4.2 (lines 3571–3596): case-insensitive first-match rule, the eight-row genre table with the §2.1.6 fallback, and the eight one-line descriptions. The fallback agrees with the §2.1.6 mood table (lines 186–193). |
| 16 | **Unresolved** | The `/NN` sentence is in §2.8 Lint scope (line 342) with the Flutter `.withValues(alpha: …)` rule and "No token exists per alpha". But two of its examples, `bg-(--stock-page)/90` and `border-(--stock-muted)/30`, name variables that appear nowhere else in the contract (the stock colours exist only as `--mm-color-stock-<stock>-{page,ink,muted}`, §2.8.1 lines 396–413, and the Issue stock is computed at runtime), and the sentence just before it allows only `(--mm-*)` arbitrary references, so the base utility would itself fail the lint. See "Residue" below. |
| 17 | Resolved | §8.14.3 Title bullet (line 2236) and §9.4.2 Indicator (line 3600): the `waveform` glyph follows the chapter folio's `caret-down` in the title group, with its own 44 / 48 hit, outside the four trailing buttons (line 2237 still caps trailing buttons at four). |
| 18 | Resolved | §8.15.6 (line 2514): `[0.5, 0.92]` sheet on phones, pre-scrolled, matching §8.14.3. No "85 %" sheet remains (the two remaining "85 %" hits are the lock-mode tap area and the guided-view matte). |
| 19 | Resolved | §7.1 `split` size (line 1070): "lg 56 / md 44 (desktop), 48 (phone) / sm 32 …, as primary", equal to `primary` (line 1069). |
| 20 | Resolved | §2.6 `rule.oxford` row (line 319) states that every Oxford rule is 3 + 2 + 1 px scaled in ratio; §7.15 Head (line 1369) uses `rule.oxford`; §12.3 (line 4143) 24 + 16 + 8 px on the 1024 master; §12.6 (line 4173) 9 + 6 + 3 px at DPR 3. No "1 px Oxford rule" remains. |
| 21 | Resolved | §10.2.2 (lines 3982–3984) lists the Circle letter's sender kicker, the Circle & privacy preview line and a reaction stamp's changing count. §10.1.2 unchanged, as judged. |
| 23 | Resolved | §9.2.7 (line 3431): `(profile_id, mature_content_enabled, year, tz_offset_minutes)`, with the reason `content_kind` is not part of it. §15.5 (line 4464) repeats the same key; `/home` keeps `(…, content_kind, …)`. |
| 24 | Resolved | §8.6 Mood (line 1939): re-computed per-channel ×3 of the §2.1.6 grades gives exactly `#4E2130`, `#4E2718`, `#45391E`, `#2D1E27`, `#2D3624`, `#362448`. §8.18 (line 2707): columns 9–12 duotone copy at `blur.bleed` 56 px, `ambient.duo`, as §8.0.8. §8.22 (line 2803): hue = 32-bit FNV-1a of the UTF-8 source id (§8.0.4's hash) mod 360, S 0.35, L 0.06. |
| 25 | Resolved | §2.8.3 `scrim.foot` row (line 492): `scrimFoot(double solidAtPx, double height)`, `end: Alignment(0, 2 * solidAtPx / height - 1)`, `solidAtPx = height` with no text block. No `Alignment(0, solidAt)` remains. |
| 26 | Resolved | §8.33.1 (line 3100): "The index field (§7.4, `type.field`)"; "Bodoni Italic 28" is gone. §7.4 `index` (line 1144) is `type.field` at 28–40 px, matching §3.5 (line 710). |
| 27 | Resolved | §9.2.5 Card anatomy (line 3413): Story 360 / 48 px, Post 252 / 32 px with the × 1350 / 1920 note; margin, wordmark and Plex Mono 24 shared. |
| 28 | Resolved | §8.14.8 intro (line 2319): desktop right side panel (§8.14.12: 3 columns, min 320 px, `paper.0`, 1 px `rule.1` inner edge), hides Margins while open. §8.14.12 (lines 2432–2434) and the desktop frame row (line 2208: 3 columns, min 320) agree. No "right column panel" wording remains for Reading setup. |
| 29 | Resolved | §8.0.3 root navigator row (line 1684): overlay route with no path, `opaque: false`, web `?view=milestone`, back closes with its Dip out. §9.2.2 Actions (line 3370) adds Android back and browser back. Appendix B Streak row (line 4718) updated. |

---

## Residue

### CONSISTENCY-9: motion durations and holds still without a key

§4.2's new closing sentence (line 788) says every motion duration in §4.5, §4.8 and §7–§9 is a `dur.*` key, and exempts only the listed behaviour timings and stagger spacings. These remain:

| Where | Literal | Kind | Why no current key fits |
|---|---|---|---|
| §8.2 Pre-roll (line 1847) | monogram fade-in "100 ms `settle`" | motion | no key has 100 ms |
| §8.14.6 Pull to continue (line 2295) | "a 250 ms fade through black" | motion (web needs it too) | the only 250 ms key is `dur.hold.panel.word`, a per-OCR-word hold |
| §8.14.7 Tap zones (line 2310) | bands "fade out over 1000 ms after 1500 ms" | motion + hold | the only 1000 ms key is `dur.arm` (destructive arm delay); 1500 ms has no key |
| §7.18 Leader dial (line 1449) | "one revolution per 1000 ms linear" | motion loop | same: only `dur.arm` |
| §7.3 Inputs, Success (line 1138) | `check` shown "for 1600 ms" | display hold | no key has 1600 ms, while the analogous error hold got `dur.hold.error` |
| §7.30 Lightbox Zoom (line 1610), §8.14.5 Zoom (line 2280) | zoom chip "top-centre for 1200 ms" | display hold | 1200 ms keys are `dur.loop.rule` and `dur.hold.panel.base`, both unrelated |
| §4.8 Highlight sweep (line 912), §8.30.1 (line 2933) | settings flash "for 1200 ms" | display hold | same |

Because the lint fails any `duration-*` name outside §2.8, the 250 ms and 1000 ms web fades cannot be written as specified. **Fix:** add keys and name them at each literal, for example `dur.fade.first` 100 (§8.2), `dur.fade.cut` 250 (§8.14.6), `dur.fade.hint` 1000 plus `dur.hold.hint` 1500 (§8.14.7), `dur.leader` 1000 (§7.18), `dur.hold.success` 1600 (§7.3), `dur.hold.chip` 1200 (§7.30, §8.14.5) and `dur.hold.flash` 1200 (§4.8, §8.30.1), each as a row in §4.2, §2.8.4 and §15.1. The alternative for the holds only is to add "display holds" to §4.2's exemption list, but that would contradict `dur.hold.error`, `dur.hold.toast` and `dur.hold.rating` being tokens, so keys are the consistent choice.

### CONSISTENCY-14: the sound file map still has one toggle file

§6 promises 13 files; §15.1 `sounds` (lines 4378–4382) lists 12, with one `"toggle": "press/toggle.wav"`; §6's event map (lines 1007, 1018) sends `toggle.on` / `toggle.off` and `reader.unlock` to the one cue `toggle`. **Fix:** in §15.1 replace the entry with `"toggle.on": "press/toggle-on.wav", "toggle.off": "press/toggle-off.wav"`; in §6's cue table split the `toggle` row into `toggle.on` (2.6 kHz, 40 ms) and `toggle.off` (1.9 kHz, 40 ms), map `toggle.on` → `toggle.on`, `toggle.off` → `toggle.off`, and name the variant `reader.unlock` plays (`toggle.on`).

### CONSISTENCY-16: the stock examples name undefined variables

`bg-(--stock-page)/90` and `border-(--stock-muted)/30` (line 342) reference `--stock-page` and `--stock-muted`, which no other passage defines, and the same paragraph allows only `(--mm-*)` arbitrary references. An implementer cannot tell what the novel reader's active-stock variables are called or whether the lint accepts them. **Fix:** add the active stock to §2.8.1's runtime colours (line 430): the novel reader root sets `--stock-page`, `--stock-ink`, `--stock-muted` from the chosen `color.stock.*` token (or the Issue computation), mapped through `@theme inline { --color-stock-page: var(--stock-page); … }` like `--page-tint`; then write the examples as `bg-stock-page/90` and `border-stock-muted/30`, which are §2.8 names and need no change to the `(--mm-*)` rule.

---

## Notes (no action needed for this finding set)

- Line 4393 (§15.2 `tokens.generated.css`) lists `--mm-font-text: var(--mm-font-newsreader)` inside the `@property` registrations sentence; "in the skin block" disambiguates it, but a comma-separated reading suggests it is registered. Rewording to "…`--page-light`; the skin block's `--mm-font-text: var(--mm-font-newsreader)`; and the …" would remove the ambiguity.
- Line 2707 (§8.18) ends the new clause with "…as the novel cover story's field (§8.0.8), as a soft field", a leftover phrase from the old text.
- `dur.tapscroll` (300 ms) also times the splash's reduced-motion masthead fade-in (§4.2 line 774, §8.2 line 1853). It is declared, so it is not a contradiction, but the name reads as scroll-only.
- The milestone title card is a takeover with Dip in and out, but §8.0.2's Takeover row (line 1627) and §8.0.4's "Takeovers (Annual, recap, onboarding)" row (line 1704) do not name it. Both read as example lists, so this is optional tidying.
