# Cinematic DESIGN.md: judge of the internal-consistency sweep

Input: `cinematic/verify-sweep/find-consistency.md` (29 findings). Each finding was checked against `cinematic/DESIGN.md` (grep plus a read of every cited passage), `inventory/00-decisions.md`, `stack-decision.md`, `inventory/web.md`, `inventory/mobile.md` and, for CONSISTENCY-8, `frontend/src/features/reader/auto-scroll.ts`. DESIGN.md was not edited.

Result: **27 confirmed** (8 of them with a rewritten or corrected fix, 3 narrowed), **2 refuted** (CONSISTENCY-13, CONSISTENCY-22). One more half-finding was refuted inside CONSISTENCY-21, which stays confirmed for its other half.

---

## Verdicts

| ID | Verdict | Severity | Reason |
|---|---|---|---|
| 1 | Confirmed | low (was medium) | §2.8.2 row 473 gives web `--mm-focus-halo: 0 0 0 6px #000` (black from the control edge out to 6 px, the outline at 2–4 px painted over it) and Flutter `focusHaloWidth = 2.0`, a black stroke outside the bone ring only; §14.4 even says "2 px further out". The 0–2 px gap is black on the web and unpainted in Flutter, which shows over art (on-art buttons, §15.7's "the black halo must show" check). Lowered: Flutter focus shows only with a hardware keyboard. Fix kept, restated with Flutter painting terms. |
| 2 | Confirmed, fix rewritten | medium | §2.1.4, §8.14.3 (line 2215) and §9.4.4 require the 25 % page-tint mix in the scrim end colour, but the `scrim-head` / `scrim-sole` utilities and `scrimHead` / `scrimSole` hard-code black. The proposed web fix is wrong: `--page-tint` is registered with `@property` and an initial value (the `color.ambient.fallback.*` tokens, §2.8.1 line 429), so `var(--page-tint, #000000)` never falls back, and every running head outside the reader would be tinted. It also ignores the page-tinted chrome switch. Rewritten below. |
| 3 | Confirmed, fix tightened | medium | §9.1.5 bullets (lines 3182–3184) say the Column wipe always follows; Entry behaviours (line 3193) and §4.5 Column wipe say Dip from anywhere but Tonight or a series page, and a Dip back to the page from the reader chip. §5 and §6 assume `reader.enter`/`wipe` always follow, but `reader.enter` is defined as "Column wipe blades land". Fix kept; the durations quoted in the finding were dropped so the bullets point at the rule instead of copying numbers. |
| 4 | Confirmed | medium | `next/font` gives Newsreader the variable `--mm-font-text` (§15.2 `fonts.ts`), the novel face `newsreader` is delivered through it (§3.4), and Hyperlegible redefines it to Atkinson on `<html>`. A book stored as `newsreader`, and the Type sheet's Newsreader tile, then render in Atkinson. The fix is correct. |
| 5 | Confirmed | low | §3.4 promises "line height +4 px" for the three roles, but the web mechanism only swaps the family variable and Flutter "swaps the family". Deck 24/28/28/32 and body 24/24/28/28 (§3.5) +4 give the numbers in the fix. Selector tightened so it outranks the skin block. |
| 6 | Confirmed, fix rewritten | medium | §8.0.3 and §8.0.7 renumber the URL (1 = Formats) while `glass_available` is false, but §8.7's table, States, Backend (`step` 1–5, NULL = step 1) use 1 = Edition, and "step 1 works offline (bundled previews)" is false when step 1 is Formats. Named steps would work, but they change the route contract, the backend enum and Appendix B. Keeping the five-step numbering canonical and renumbering only the folio is the smaller correct fix. |
| 7 | Confirmed | low (was medium) | Web and mobile key spaces overlap (web K30 = cinema, mobile K30 = mature; web K13 = source pins, mobile K13 = haptics; web K19–K22 = update checker, mobile K19–K22 = retention / Wi-Fi only / high refresh / theme). The contract mixes styles: "mobile K22", "mobile K14", "Migration of mobile K11" versus bare "K13", "K15", "K19–K22", "K21". Context disambiguates most rows, so lowered. Fix kept. |
| 8 | Confirmed | medium | `inventory/web.md` K39 is an integer level 1–10; `auto-scroll.ts` maps it linearly to 20–220 px/s (`MIN_RATE_PX_PER_S = 20`, `MAX_RATE_PX_PER_S = 220`). §8.14.8's "old px/s ÷ 60" applied to the stored level turns the default 5 into 0.50×. The fix's arithmetic checks: level 1 → 0.33 → 0.50×, 5 → 108.9 px/s → 1.80×, 10 → 3.00×. `mobile.md` A069 confirms mobile speed is session-only. |
| 9 | Confirmed, fix rewritten | medium | §2.8.4 has no key for 40, 120, 200, 224, 280, 300, 336, 360, 400, 500, 520, 560, 1200, 2000 ms or the flame loops (800 ms, 2 s, 24 s, 900 ms), all used in §4.5, §4.8 and §7–§9; the lint (§2.8 "Lint scope") fails `duration-*` names outside §2.8, so CSS transitions at those values cannot be written on the web, and each client hard-codes the rest. Flame loops and the guided-view dolly are not §4.5 rows, so `play()` cannot log them (§15.9). The finding's names collide: `dur.scroll` 400 sits beside `ease.scroll`, whose own tap-to-scroll is 300 ms and also untokenised; `dur.press` reads like the 80 ms pressed state. Rating-card 400 ms goes away with CONSISTENCY-11. Rewritten. |
| 10 | Confirmed, narrowed | low (was medium) | **Set** and **Unseal** are already covered by the §14.1 rule of thumb for moves not in the table ("a slide becomes a 150 ms opacity change"; Unseal is already opacity only), so that half is refuted. The **Listen countdown dial** is a real contradiction: §14.1 says countdowns become once-per-second labels, while the last §4.8 row keeps the "leader dial (§7.18)" running unchanged, and §7.18 defines the countdown dial as "the leader dial at 40 px". Only the dial row is kept. |
| 11 | Confirmed | low | §4.1 principle 4: exits are shorter than entrances. §7.11 toast: in 160, out 240. §7.24 rating card: in 400, out 600, with no easing. The fix uses existing tokens (`dur.line`, `dur.beat`, `dur.spread`) and the §4.2 / §4.8 cross-references it names exist. |
| 12 | Confirmed | low | §14.5 says section heads are `h2` and `SetHeading` is given `as="h2"`, yet the canonical §10.1.5 code defaults to `"h3"` and no call site in the contract passes `as`. Flutter's `level` is required, so it cannot drift. Changing the web default is a one-token fix. |
| 13 | **Refuted** | — | No real ambiguity. §2.7 says the `certificate-18` glyph is never drawn in place of the §7.19 badge, and §7.24 describes the poster, row and credit mark as "the §7.19 badge: a 1 px `proof` outline and "18" in `proof` Archivo `wdth` 62 `wght` 800 at 10 px". Both passages call for the drawn box. The shared name is loose wording, not a contradiction an implementer could act on wrongly. |
| 14 | Confirmed, fix corrected | low | The twelve cue lengths add up to 3,700 ms, and `toggle` has two recipes (on 2.6 kHz, off 1.9 kHz), so 13 files and 3,740 ms. At 48 kHz 16-bit mono (96,000 B/s) that is 359,040 B plus 13 × 44-byte headers ≈ 360 KB. The finding's "≤ 360 KB" leaves no margin at all. Corrected to 384 KB. |
| 15 | Confirmed | medium | §9.4.2 `MATCH THE MOOD` "chooses by the series' first genre", but no genre → loop table exists anywhere (§2.1.6 has only the mood defaults). Only Projector room has a one-line description, although the picker needs one per loop. The fix supplies both and is consistent with §2.1.6. |
| 16 | Confirmed, fix rewritten | low | The alpha values are all given explicitly (`ink.100` 40 %, black 0.84, `paper.2` 90 % and 92 %, stock colours 90 % and 30 %, black 50 %), so there is no value drift. The real gap is that the lint (§2.8, which checks `border-*`, `bg-*` colour names and bans `[#…]`/`[rgb…]`) does not say whether Tailwind's `/NN` opacity modifier is allowed, so a correct `border-ink-100/40` may fail CI. Five new tokens are not needed; one lint sentence covers every case. |
| 17 | Confirmed | low | §8.14.3 caps phone trailing buttons at four (download, bookmark, guided view, settings) and does not list the `waveform` indicator that §9.4.2 puts in the manga running head. The novel top bar (§8.15.3) already places it in its title area. Fix kept. |
| 18 | Confirmed | low | "An 85 % sheet" (§8.15.6) matches neither §7.9 detent rule (content-fit up to 0.92, or `[0.5, 0.92]`); the manga Contents sheet is `[0.5, 0.92]`. Fix kept. |
| 19 | Confirmed | low | `split` is "a `primary` whose right segment carries a folio" but its md is 48 everywhere, while `primary` md is 44 on desktop; a `split` beside a `secondary` ("as primary") on a desktop feature page misaligns by 4 px. Fix kept. |
| 20 | Confirmed, extended | low | `rule.oxford` is 3 + 2 + 1 px, but §12.3 and §12.6 ask for "a 1 px bone Oxford rule", and §7.15's sidebar head (line 1325) has the same "1 px Oxford rule", which the finding missed. Fix extended to §7.15. |
| 21 | Confirmed, narrowed | low | **§10.1.2 half refuted:** its Mastheads bullet states the rule "every page title", and §7.27 gives every masthead the letter reveal, so collection detail, member page and profile-form titles are already covered; the parenthetical is a list of examples. **§10.2.2 half confirmed:** the typed Circle letter sender kicker (§9.3.2, §13 moment 15) and the Circle & privacy preview line (§9.3.6, "A preview line types what others will see") are missing from a list declared exhaustive. The reaction-stamp count (§9.3.3, "its count types the new value") is missing as well and has been added. |
| 22 | **Refuted** | — | Each of the two breakpoints is used by one client only, so there is no cross-client value to keep identical. 1280 px drives the desktop sidebar (§7.15), which exists only on the web. 900 px appears only in §8.0.9's tablet table, which applies to the app: the web shows the phone frame only up to 767 px and follows desktop layouts from 768 px (§8.0.9 intro). The existing `bp.*` tokens are also "documentation only; media queries use the literal" on the web, so a new token would not change how the web writes it. Flutter can keep a local `const`. |
| 23 | Confirmed, fix adjusted | low | §8.0.8 lists The Annual as mode-agnostic and `GET /library/annual` takes no `content_kind`, but §9.2.7 and §15.5 key its cache by `content_kind`. The finding's §15.5 rewrite made up a full `/home` key (`tz_offset_minutes, local hour`) that the contract does not define, so `/home` keeps its existing "…". |
| 24 | Confirmed, fix adjusted | low | "Brightened 3×", "a duotone copy at 3× blurred" and "hashed from its id, L 0.06" cannot be computed as written. The per-channel ×3 hexes check (for example `#1A0B10` → `#4E2130`). For §8.18 the finding's 504 × 744 px field would overflow the 4-column slot. The contract already has the pattern for this field in the novel cover story (§8.0.8: "a field of the same cover at `blur.bleed`, duotoned to `ambient.duo`"), so the fix reuses it. FNV-1a is the hash already used in §8.0.4. |
| 25 | Confirmed | low | Web `--scrim-solid-at` is px from the element's top, while Flutter's `end: Alignment(0, solidAt)` takes −1..1 with no conversion. `Alignment(0, -0.2)` = 40 % down confirms the mapping y = 2·px/h − 1. Fix kept. |
| 26 | Confirmed, fix rewritten | low | §7.4 lists the command palette under `index` / `type.field` (36/44 on desktop), while §8.33.1 says "Bodoni Italic 28". The finding fixes the palette at 28/36, but the lint checks `text-*` sizes and has no palette-size variant, so that needs a new override mechanism. The smaller fix is to drop the stray "28" and use `type.field` as §7.4 says. The palette is desktop-only (`mod+k`) and 720 px wide, so it fits. |
| 27 | Confirmed, numbers corrected | low | Only Story sizes are given. The finding's derivation is wrong: 360 × 1350/1920 = 253.1 → 252 on the 4 px baseline (not 256), and 48 × 0.703 = 33.75 → 32 (not 36). |
| 28 | Confirmed | low | §8.14.8 calls Reading setup a desktop "right column panel" (§7.9: 4 columns, min 400, `paper.2`), but §8.14.12 has it take the right side-panel slot (3 columns, min 320, `paper.0`). The narrow-desktop 480 px rule depends on which one applies. Fix kept. |
| 29 | Confirmed | low | The milestone title card (§9.2.2) is a takeover with Dip in and out, but it is neither in the §8.0.3 route contract nor in the root-navigator overlay list, and its Android back and browser back behaviour is undefined (it gives only tap outside, swipe down and `Esc`). The Lightbox's `?view=cover` pattern (§7.30) already solves this. Fix kept. |

---

## Confirmed

### CONSISTENCY-1 (low): one focus-halo geometry on both clients
§2.4, §2.8.2 and §14.4 all read: a solid `#000000` band from the control's edge out to 6 px, with the 2 px `ink.100` ring painted over it from 2 to 4 px out. Web is unchanged (`outline: 2px solid var(--mm-color-ink-100); outline-offset: 2px; box-shadow: 0 0 0 6px #000`). Flutter: rename the field `focusHaloWidth = 2.0` to `focusHalo = 6.0` (outer extent in px). `CineFocusRing` first paints the control's rect with `BorderSide(color: Color(0xFF000000), width: 6, strokeAlign: BorderSide.strokeAlignOutside)`, then paints the rect inflated by 2 px with `BorderSide(color: colorInk100, width: 2, strokeAlign: BorderSide.strokeAlignOutside)`. §14.4: replace "then a 2 px `#000000` stroke 2 px further out" with "over a `#000000` band from the edge out to 6 px".

### CONSISTENCY-2 (medium): the page tint reaches the scrims
- **Web (§2.8.3).** Both utilities read an unregistered local variable with a black fallback. Each stop becomes `color-mix(in srgb, var(--scrim-base, #000000) P%, transparent)`, where `build.mjs` writes P = 88 × `kScrimAlpha[i]` (90 × for `scrim-sole`) as a literal and the flat stop uses 88 % (90 %). The reader chrome root, and only while page-tinted chrome is on, sets `--scrim-base: color-mix(in srgb, var(--page-tint) 25%, #000000)`. `--scrim-base` must stay unregistered: `--page-tint` is registered with an initial value (§2.8.1), so `var(--page-tint, #000)` would never fall back, and every other running head would pick up the ambient fallback tint. Because `--scrim-base` is re-substituted on the chrome root every frame, the 800 ms `--page-tint` transition still drives it.
- **Flutter.** Change the builders to `scrimHead(bar, fade, {Color? tint})` and `scrimSole(bar, fade, {Color? tint})`, with `final base = tint == null ? const Color(0xFF000000) : Color.lerp(const Color(0xFF000000), tint, 0.25)!` and colours `base.withValues(alpha: 0.88)` / `base.withValues(alpha: 0.88 * kScrimAlpha[i])` (0.90 for sole). The reader chrome passes the `page.tint` role colour (§2.1.5: `h`, L 0.06, S ≤ 0.35) only while page-tinted chrome is on, animated by the existing `TweenAnimationBuilder<Color?>`.
- Add one row to §15.7's over-art table: running head and folio bar at the most saturated `page.tint`.

### CONSISTENCY-3 (medium): recap exit follows the entry rule
§9.1.5: in the `Skip recap →`, `Continue │ CH 143` and "At zero the reader opens…" bullets, replace "with the Column wipe" with "by the recap's way into the reader (Entry behaviours below: Column wipe when the recap was opened from Tonight or a series page, Dip from anywhere else, and a Dip back to the open page when it was opened from the reader's chip)". §5 `recap.countdown.end` haptic cell: "none (`reader.enter` fires only when the exit is a Column wipe)". §6 map cell: "— (`wipe` plays only when the exit is a Column wipe)".

### CONSISTENCY-4 (medium): Hyperlegible no longer hijacks Newsreader
§3.4, §3.5 and §15.2: give Newsreader its own `next/font` variable, `--mm-font-newsreader`, with its class on `<html>` like the other faces. The skin block emits `--mm-font-text: var(--mm-font-newsreader)` under `[data-skin="cinematic"]`, and only `--mm-font-text` is overridden under `html[data-legible="on"]`. The novel reader's `newsreader` face and the Type sheet's `Newsreader` tile use `var(--mm-font-newsreader)` directly. Flutter: state that `CineType` swaps the family of `type.deck`, `type.body` and `type.body.italic` only, and that the novel face `newsreader` always uses the `Newsreader` asset family.

### CONSISTENCY-5 (low): Hyperlegible line height is carried
Web: under `html[data-legible="on"][data-skin="cinematic"]` (which outranks the skin block), set these per breakpoint media query (phone / tablet / desktop / wide): `--mm-type-deck-lh` 28 / 32 / 32 / 36 px, and `--mm-type-body-lh` and `--mm-type-body-italic-lh` 28 / 28 / 32 / 32 px. Flutter: `CineType` adds 4.0 to each `lines` entry of those three roles when `legibleTextProvider` is true. §3.4 names both mechanisms.

### CONSISTENCY-6 (medium): one onboarding step numbering
The five-step numbering (1 Edition, 2 Formats, 3 Genres, 4 Art style, 5 Seeds) is canonical for the route, the backend `step` and `onboarding_step`. Only the visible folio renumbers.
- §8.0.3 `onboarding` row: "`/welcome?step=1..5`; while `glass_available` is false step 1 is never shown, the route runs `step=2..5` and the folio reads `1 / 4` … `4 / 4`".
- §8.0.7 Onboarding row: "Step 1 (Edition) is skipped: `/welcome?step=2..5` (Formats, Genres, Art style, Seeds), folio `1 / 4`, four progress rules".
- §8.7 Backend: "new profiles default to `NULL`, which means the first shown step (1, or 2 while `glass_available` is false)".
- §8.7 States, fully offline: "the Edition step works when it is shown (its previews are bundled); every catalog step (2–5) shows the notice … ; the saved step is kept, so the next online pick resumes at the saved step, or at step 2 if none was saved".

### CONSISTENCY-7 (low): platform-prefixed key citations
Amend §1 conventions: "keys are cited as `web K40` or `mobile K40`". Then prefix every bare citation:
- `web K30` for cinema (§8.14.8, §8.30.2 row 03);
- `web K1 / mobile K30` for mature (row 08);
- `web K19–K22 / mobile K40` for the update checker (row 11);
- `mobile K17`–`K20` in §8.23;
- `mobile K20` in §8.14.11;
- `mobile K13` for haptics (row 10);
- `mobile K15` for cover scale (§8.9);
- `mobile K11` / `mobile K12` for Ground and Colour (§8.14.8);
- `mobile K21` for high refresh rate (§8.30.7);
- `mobile K01`–`K12` wherever §8.14.8 lists them;
- `web K29`, `K31`, `K34`–`K39` where §8.30.2 and §8.14.8 cite them.

### CONSISTENCY-8 (medium): auto-scroll speed migration
§8.14.8 Auto-scroll speed, migration column: "web K39 (a level 1–10): `px = 20 + (level − 1) × 200 / 9`, then `speed = clamp(px / 60, 0.50, 3.00)` rounded to 0.05 (level 1 → 0.50×, 5 → 1.80×, 10 → 3.00×). Mobile speed is session-only today (`mobile.md` A069), so nothing migrates on mobile."

### CONSISTENCY-9 (medium): every duration is a token
Add one `dur.*` key per distinct duration that §4.5, §4.8 and §7–§9 use without one, as a row each in §4.2, §2.8.4 (web `--mm-dur-*`, Motion seconds, Flutter `Duration`) and §15.1. Then replace every literal with its key. The names below avoid the existing `ease.scroll` and the pressed state:

| Key | ms | Used by |
|---|---|---|
| `dur.hold.dip` | 40 | Dip hold, wipe hold |
| `dur.snap` | 120 | Row hover, check fill, menu exit, loading cross-fades, sidebar label fade, slate grace, wipe skip |
| `dur.reduced` | 150 | §4.8 reduced cross-fades |
| `dur.clip` | 200 | Poster and card hover, Insert barrier, menu clip, Slate collapse, highlight band, blade reverse, §4.8 200 ms cross-fades |
| `dur.page.out` | 224 | |
| `dur.dim` | 280 | |
| `dur.tapscroll` | 300 | Tap-to-scroll with `ease.scroll` |
| `dur.match.back` | 336 | |
| `dur.rise` | 360 | |
| `dur.glide` | 400 | Ignite, scroll to top, transcript follow, group jump, settings jump |
| `dur.stoppress` | 500 | |
| `dur.rack` | 520 | Rack focus, Develop, dolly |
| `dur.iris.out` | 560 | Iris out, Paddle page |
| `dur.loop.rule` | 1200 | Indeterminate rule, button loading segment |
| `dur.hold.error` | 2000 | |
| `dur.flame.flicker` | 2000 | |
| `dur.flame.risk` | 800 | |
| `dur.flame.ring` | 24000 | |
| `dur.flame.spark` | 900 | |

Add §4.5 rows:
- `Flame`: flicker 2 s, at-risk flicker 800 ms, ring 24 s `ease.linear`, sparks 900 ms, all `ease.drift` except the ring (§9.2.2);
- `Dolly`: 520 ms `ease.turn`, the guided-view camera (§9.4.3).

Both then start through `play()`, so the §15.9 overlay logs them.

### CONSISTENCY-10 (low, narrowed): the Listen countdown dial under reduced motion
Add one §4.8 row: "Listen countdown dial (§7.18, §8.16.7) | `spot` sweep over 5 s | no sweep: the dial shows its ring with a `5 S` … `1 S` folio label updated once per second; the 5 s timing is unchanged". Then change the last §4.8 row to "leader dial (§7.18; not the countdown dial)". Set and Unseal need no row, because the §14.1 rule of thumb already covers them.

### CONSISTENCY-11 (low): exits shorter than entrances
§7.11 toast motion: "In: fade + 8 px rise 240 ms (`dur.line`) `ease.settle`. Out: fade 160 ms (`dur.beat`) `ease.lift`." §4.2: `dur.beat` use "toast out" instead of "toast in", and `dur.line` adds "toast in". §4.8 toast row: "240 ms rise, 240 ms push". §7.24 rating card: "fades in 480 ms (`dur.spread`) `ease.settle`, holds `dur.hold.rating`, fades out 240 ms (`dur.line`) `ease.lift`".

### CONSISTENCY-12 (low): SetHeading defaults to h2
§10.1.5: `as: Tag = "h2"`. §1 conventions gain: "'H3' in this contract is the design name of the `type.section` head (from `inventory/00-decisions.md`); its semantic level is 2 (web `h2`, Flutter `level: 2`)."

### CONSISTENCY-14 (low): sound set budget
§6: "48 kHz 16-bit mono WAV, 5 ms fades, total set ≤ 384 KB (13 files, the twelve cues with `toggle` as on and off: 3,740 ms × 96,000 B/s = 359,040 B plus 13 × 44-byte headers; the listed lengths include each cue's reverb tail)."

### CONSISTENCY-15 (medium): MATCH THE MOOD genre table and loop descriptions
Add this table to §9.4.2. Matching is case-insensitive: take the series' genres in order and use the first one that appears in the table.

| Genres | Loop |
|---|---|
| Romance, Josei, Shoujo | Rain on glass |
| Action, Martial Arts, Murim, Sports | Low drone |
| Comedy, Slice of Life, School | Café |
| Horror, Thriller, Mystery, Psychological | Night wind |
| Fantasy, Isekai, Regression, Cultivation, Historical | Temple bells |
| Drama, Crime, Sci-Fi | Night city |
| Adventure, Seinen | Afternoon park |
| No match | The profile mood's default (§2.1.6; `default` → Projector room) |

One-line picker descriptions (`type.caption`):

| Loop | Description |
|---|---|
| Projector room | "A soft hum with distant reel ticks." |
| Rain on glass | "Steady rain on a window." |
| Night city | "Distant traffic after dark." |
| Café | "Low voices and cups." |
| Night wind | "Wind across an empty street." |
| Low drone | "A deep, even hum." |
| Afternoon park | "Birds and far-off voices." |
| Temple bells | "Slow bells over a quiet courtyard." |

### CONSISTENCY-16 (low): opacity modifiers are allowed by the lint
Add to §2.8 "Lint scope": "Tailwind's `/NN` opacity modifier is allowed on any §2.8 colour name and on an arbitrary `(--…)` colour reference (`border-ink-100/40`, `bg-paper-0/84`, `bg-paper-2/90`, `bg-paper-2/92`, `bg-paper-0/50`, `bg-(--stock-page)/90`, `border-(--stock-muted)/30`). Flutter applies the same alpha with `.withValues(alpha: …)` on the `CineTokens` colour." No new tokens.

### CONSISTENCY-17 (low): the soundscape indicator in the manga running head
§8.14.3 Title bullet: "while a soundscape plays, a 16 px `waveform` glyph follows the chapter folio's `caret-down` inside the title group (its own 44 (iOS, web) / 48 (Android) hit, not one of the four trailing buttons); a tap opens Reading setup at `AMBIENT`". Mirror the sentence in §9.4.2 Indicator.

### CONSISTENCY-18 (low): novel Contents sheet detents
§8.15.6: "Inside the novel reader: a `[0.5, 0.92]` sheet (phone), pre-scrolled to the current chapter, or the left column panel (desktop) in the stock colours", matching the manga Contents sheet.

### CONSISTENCY-19 (low): split sizes follow primary
§7.1 `split` size: "lg 56 / md 44 (desktop), 48 (phone) / sm 32, as primary; at text scale ≥ 1.5 …".

### CONSISTENCY-20 (low): the Oxford rule has one shape
Every Oxford rule is `rule.oxford` (3 + 2 + 1 px at DPR 1).
- §7.15 Head: "Wordmark (Bodoni masthead at 20 px) with `rule.oxford` under it".
- §12.3: "a bone Oxford rule of 24 + 16 + 8 px on the 1024 master (the 3 : 2 : 1 ratio), 18 % below the monogram, 40 % wide, centred".
- §12.6: "with a bone Oxford rule at the capture's DPR 3 (9 + 6 + 3 px) between band and capture".

### CONSISTENCY-21 (low, narrowed): the typing-reveal list
Add to §10.2.2:
- "the Circle letter's sender kicker when it unfolds (§9.3.2, §13 moment 15)";
- "the Circle & privacy preview line (§9.3.6)";
- "a reaction stamp's count when it changes (§9.3.3)".

§10.1.2 is unchanged, because "every page title" already covers the mastheads the finding listed.

### CONSISTENCY-23 (low): The Annual cache key
§9.2.7: "cached per day under the key `(profile_id, mature_content_enabled, year, tz_offset_minutes)`". §15.5: "Per-profile composed caches: `/home` keyed by `(profile_id, mature_content_enabled, content_kind, …)`; `/library/annual` by `(profile_id, mature_content_enabled, year, tz_offset_minutes)` (mode-agnostic, §8.0.8)".

### CONSISTENCY-24 (low): computable colour and image values
- §8.6: "a 10 × 10 square of the grade colour with each sRGB channel × 3: romantic `#4E2130`, action `#4E2718`, comedy `#45391E`, horror `#2D1E27`, slice_of_life `#2D3624`, fantasy `#362448` (`default` shows no square)".
- §8.18: "a duotone copy of the cover filling columns 9–12 behind the plate (cover fit), at `blur.bleed` (56 px), duotoned to `ambient.duo`, as the novel cover story's field (§8.0.8)".
- §8.22: "a background wash with hue = the 32-bit FNV-1a of the UTF-8 source id (the hash of §8.0.4) mod 360, S 0.35, L 0.06".

### CONSISTENCY-25 (low): scrim.foot solid point in Flutter
§2.8.3: `scrimFoot(double solidAtPx, double height)` = `LinearGradient(begin: Alignment(0, -0.2), end: Alignment(0, 2 * solidAtPx / height - 1), …)`, where `height` is the painted element's laid-out height (web `--scrim-solid-at` is the same px from that element's top edge; with no text block, `solidAtPx = height`).

### CONSISTENCY-26 (low): command palette field size
§8.33.1: "The index field (§7.4, `type.field`) with the placeholder…", with the stray "Bodoni Italic 28" removed.

### CONSISTENCY-27 (low): share card sizes for Post
§9.2.5 Card anatomy: "Story: key figure 360 px, caption 48 px. Post: key figure 252 px, caption 32 px (Story × 1350 / 1920 ≈ 0.70, rounded to the 4 px baseline). The 64 px margin, the 40 px wordmark with its Oxford rule and Plex Mono 24 are the same in both."

### CONSISTENCY-28 (low): Reading setup on desktop
§8.14.8: "A `[0.5, 0.92]` sheet on phones … and on desktop the right side panel (§8.14.12: 3 columns, min 320 px, `paper.0`, 1 px `rule.1` inner edge), which hides Margins while it is open."

### CONSISTENCY-29 (low): the milestone title card is a routed overlay
§8.0.3 root-navigator list: add "the milestone title card (an overlay route with no path, `opaque: false`, like the Lightbox; on the web a `?view=milestone` history entry like the Lightbox's `?view=cover`, so browser back and Android back close it with its Dip out)". §9.2.2 Actions: add "Android back and browser back" to "Tap outside, swipe down or `Esc` closes".

---

## Refuted (2)

- **CONSISTENCY-13**: §2.7 and §7.24 agree that poster, row and credit marks are the drawn §7.19 badge, never the glyph. §7.24 spells out the drawing.
- **CONSISTENCY-22**: 1280 px is used only by the web and 900 px only by the app, so there is no cross-client value to keep identical. The web `bp.*` tokens are documentation-only anyway.

Partial refutations inside confirmed findings: CONSISTENCY-10 (Set and Unseal are covered by §14.1's rule of thumb) and CONSISTENCY-21 (§10.1.2's "every page title" already covers the listed mastheads).
