# Cinematic DESIGN.md: internal-consistency sweep

Lens: every token, motion, haptic and sound value identical everywhere it appears; every referenced name defined; no vague values; no contradictions between sections. Source of truth: `cinematic/DESIGN.md` (4,657 lines, read in full). Every "missing" claim below was checked with a grep over the whole file.

Checked and found consistent (not reported): every `color.*`, `dur.*`, `ease.*`, `spring.*`, `scalar.*`, `blur.*`, `scrim.*`, `rule.*`, `z.*`, `type.*` reference resolves to a row of §2.8 or §3.5; the colour hexes and Flutter ARGB alphas in §2.8.1 match §2.1 and §15.1; the §3.2 and §3.5 type tables, the `clamp()` formulas and the unitless line-height ratios agree; every contrast figure in §2.1, §7.19, §7.25, §8.16.3 and §14.2 recomputes within 0.05; the Column wipe totals (616 / 744 / 872 ms) and the Dip savings (176 / 304 / 432 ms) add up; the §5 haptic table, the §6 sound map and the §15.1 JSON agree event for event; the spring settle times (800 / 850 / 500 ms) match the installed motion-dom spring's done rule; the caret keyframes match 6 × 530 + 160 = 3,340 ms; the splash timeline (13 graphemes, last start 540, land 1,180) adds up.

---

## CONSISTENCY-1
- **Severity:** medium
- **Section:** §2.4 (Focus light), §2.8.2 (`focus.halo`), §7 intro (Focus), §14.4
- **Problem:** The one key `focus.halo` has two different values and geometries. Web: a 6 px black `box-shadow` spread from the control's edge (so the 2 px gap between control and ring is black, plus 2 px outside the ring). Flutter: `focusHaloWidth = 2.0`, a 2 px black stroke outside the bone ring only, so the 2 px gap under the ring is not painted. Over art (on-art buttons, posters on art) the Flutter ring touches the art on its inner edge, and §7.1's "on primary the ring sits outside a 2 px `#000` gap" only holds on the web.
- **Evidence:** §2.8.2: "`focus.halo` … halo 6 px `#000000` | `--mm-focus-halo: 0 0 0 6px #000` | … | `focusHaloWidth` = `2.0` (painted by `CineFocusRing` 2 px outside the bone stroke)". §14.4: "Flutter `CineFocusRing` paints the bone stroke, then a 2 px `#000000` stroke 2 px further out".
- **Fix:** One geometry on both clients: a solid `#000000` band from the control's edge out to 6 px, with the 2 px `ink.100` ring painted on top of it from 2 px to 4 px out. Flutter field renamed `focusHalo = 6.0` (outer extent, px); `CineFocusRing` paints `BorderSide(color: Color(0xFF000000), width: 6, strokeAlign: BorderSide.strokeAlignOutside)` first, then `BorderSide(color: colorInk100, width: 2)` offset 2 px outside the edge. §2.4, §2.8.2 and §14.4 then all read "halo 6 px".

## CONSISTENCY-2
- **Severity:** medium
- **Section:** §2.8.3 (`scrim.head`, `scrim.sole`) versus §2.1.4, §8.14.3 (Page tint), §9.4.4
- **Problem:** Three sections require the page tint to be mixed into the end colour of `scrim.head` and `scrim.sole`, but both token definitions (the web `@utility` gradients and the Flutter builders) hard-code pure black and take no tint input, so an implementer following §2.8.3 cannot produce the tinted scrim.
- **Evidence:** §2.1.4: "The §9.4.4 page-tint mix (25 % of `page.tint`) still applies to the end colours of `scrim.head` and `scrim.sole`." §9.4.4: "Applied to: the end colour of `scrim.head` and `scrim.sole` (mix 25 % tint into `#000`)". §2.8.3 `scrim-head`: "`linear-gradient(to bottom, rgb(0 0 0/.88) 0, <for i = 12 → 0: rgb(0 0 0/(.88 × kScrimAlpha[i])) …>`"; Flutter "`colors: [Color(0xE0000000), Color(0xE0000000), … Color(0xFF000000).withValues(alpha: .88 × kScrimAlpha[i])]`".
- **Fix:** Web: both utilities first set `--scrim-base: color-mix(in srgb, var(--page-tint, #000000) 25%, #000000)` and use `color-mix(in srgb, var(--scrim-base) (88 × kScrimAlpha[i])%, transparent)` for each stop (90 for `scrim-sole`); `--page-tint` is registered only on the reader chrome root (§2.1.5), so every other running head falls back to pure black. Flutter: `scrimHead(bar, fade, {Color tint = const Color(0xFF000000)})` and `scrimSole(...)` with `final base = Color.lerp(const Color(0xFF000000), tint, 0.25)!` and colours `base.withValues(alpha: 0.88)` / `base.withValues(alpha: 0.88 * kScrimAlpha[i])` (0.90 for sole); the reader chrome passes `CineTint` of `pageTint` at L 0.06.

## CONSISTENCY-3
- **Severity:** medium
- **Section:** §9.1.5 (Skip recap, Actions, Auto-continue countdown) versus §9.1.5 Entry behaviours, §8.0.4, §8.14.2, §5 (`recap.countdown.end`), §6 map
- **Problem:** Three bullets of the recap layout say leaving the recap always plays the Column wipe, while the recap's own Entry behaviours paragraph, §8.0.4 and §8.14.2 say the wipe plays only when the recap was opened from Tonight or a feature or book page, a Dip otherwise, and a Dip back to the open page when opened from the reader chip. The haptic and sound tables also assume a wipe always follows the countdown.
- **Evidence:** §9.1.5: "`Skip recap →` … goes straight to the reader with the Column wipe"; "`split` primary `Continue │ CH 143` (Column wipe into the reader; usable from t = 0)"; "At zero the reader opens with the Column wipe." versus Entry behaviours: "from a recap opened anywhere else (a Library cutting's Quick look, for example), a Dip; from the reader's own chip, `Continue`, `Skip recap` and the countdown close the takeover with a Dip back to the open page". §5: "`recap.countdown.end` … none (the Column wipe's `reader.enter` follows)"; §6: "`recap.countdown.end` | — (`wipe` follows)".
- **Fix:** Replace "with the Column wipe" in the three §9.1.5 bullets by "by the recap's exit rule (Entry behaviours below: Column wipe 872 / 744 / 616 ms when the recap was opened from Tonight or a feature or book page; Dip 160 / 40 / 240 ms from anywhere else; Dip back to the open page from the reader chip)". §5 row: "none (`reader.enter` fires only when the exit is a Column wipe)". §6 cell: "— (`wipe` plays only on a Column wipe exit)".

## CONSISTENCY-4
- **Severity:** medium
- **Section:** §3.4 (face table, Hyperlegible option), §8.15.5 (Face)
- **Problem:** The Hyperlegible switch redefines `--mm-font-text` to Atkinson on `<html>`, but the novel reader's `newsreader` face is delivered through that same variable. With Hyperlegible on, a book whose stored face is `newsreader` (and the Type sheet's `Newsreader` tile, "each label set in its own face") renders in Atkinson, so the user cannot choose Newsreader, which §8.15.5 still offers.
- **Evidence:** §3.4 face table: "`newsreader` … Web delivery: already loaded (`--mm-font-text`)"; Hyperlegible: "the generated CSS redefines `--mm-font-text: var(--mm-font-atkinson)` under it". §8.15.5: "Face | Five tiles, each label set in its own face: `Newsreader`, … | Newsreader (Atkinson when Hyperlegible text is on)".
- **Fix:** Give Newsreader its own `next/font` variable `--mm-font-newsreader`; emit `--mm-font-text: var(--mm-font-newsreader)` in `[data-skin="cinematic"]` and override only `--mm-font-text` under `html[data-legible="on"]`. The novel reader's `newsreader` face and the Type sheet tile use `var(--mm-font-newsreader)` directly. Flutter: state that `CineType` swaps the family of `type.deck`, `type.body` and `type.body.italic` only, and the novel face `newsreader` always uses the `Newsreader` asset family.

## CONSISTENCY-5
- **Severity:** low
- **Section:** §3.4 (Hyperlegible option), §3.5
- **Problem:** Hyperlegible adds "line height +4 px" to three roles, but neither client's mechanism carries it: the web only swaps the family variable and Flutter only "swaps the family". The generated line-height properties and `CineTextRole.lines` have no legible variant.
- **Evidence:** §3.4: "render in Atkinson Hyperlegible Next (wght 400, italic 400) at the same sizes with line height +4 px" … "the generated CSS redefines `--mm-font-text: var(--mm-font-atkinson)` under it" … "Flutter: `CineType` swaps the family of the three roles when `legibleTextProvider` is true."
- **Fix:** Web: under `html[data-legible="on"]`, per breakpoint, `--mm-type-deck-lh` 28 / 32 / 32 / 36 px, `--mm-type-body-lh` and `--mm-type-body-italic-lh` 28 / 28 / 32 / 32 px (phone / tablet / desktop / wide). Flutter: `CineType` adds 4.0 to each entry of `lines` for those three roles when `legibleTextProvider` is true.

## CONSISTENCY-6
- **Severity:** medium
- **Section:** §8.0.7 (Onboarding row), §8.0.3 (`onboarding`), §8.7 (Resume, States, Backend), §8.0.9 (Onboarding row)
- **Problem:** Two step numberings are used for one stored value. While `glass_available` is false the URL steps are renumbered (1 = Formats), but the backend `step`, the `NULL` default, the states list, the offline paragraph and the tablet table all use the five-step numbering (1 = Edition). An implementation cannot tell whether `PUT /profiles/{id}/taste {step: 2}` means Formats or Genres, and the offline sentence ("step 1 works, its previews are bundled") is false when step 1 is Formats, which needs `GET /onboarding/catalog`.
- **Evidence:** §8.0.3: "`/welcome?step=1..5` | … `step=1..4` while `glass_available` is false". §8.0.7: "`/welcome?step=1..4` = Formats, Genres, Art style, Seeds". §8.7 Backend: "`step` is `1`–`5` or `"done"`"; "new profiles default to `NULL`, which means step 1". §8.7 States: "Catalog unreachable at steps 2 and 5"; "step 1 works (its previews are bundled) … the next online pick of the profile resumes at step 2".
- **Fix:** Use canonical step names everywhere: route `/welcome?step=edition|formats|genres|styles|seeds`, body `{step: "edition" | "formats" | "genres" | "styles" | "seeds" | "done"}`, `onboarding_step` the same enum; `NULL` means the first shown step (`formats` while `glass_available` is false, else `edition`). Only the visible folio renumbers (`1 / 4` or `1 / 5`). Rewrite the offline sentence: "the Edition step works offline (bundled previews); every catalog step shows the notice; the next online pick resumes at the first catalog step (`formats`)".

## CONSISTENCY-7
- **Severity:** medium
- **Section:** §1 conventions ("keys `K40`"), §8.14.8, §8.23, §8.30.2, §8.9, §8.14.11
- **Problem:** The web inventory keys (K1–K51) and the mobile inventory keys (K01–K40) share numbers, and the contract cites them without a platform prefix, so migrations point at the wrong setting. K30 is web "reader cinema" and mobile "mature content"; K19–K22 are the web update checker and mobile retention / Wi-Fi only / high refresh / theme; K13 is web source pins and mobile haptics; K15 is web narrator voice and mobile cover scale; K11 and K12 in the §8.14.8 column are mobile keys while every other row in that column is a web key.
- **Evidence:** §8.30.2 row 03: "cinema (K30)" and row 08: "Show mature content (18+) switch … (K1/K30)". Row 11: "admin (instance-wide, K19–K22)" versus §8.23: "`DELETE AFTER READING` … (K19; …)", "`Download on Wi-Fi only` switch (K20 …)" and §8.14.11 "K20 ("Download on Wi-Fi only")". Row 10: "Haptic feedback (K13; …)". §8.9: "Mobile's cover-size slider (K15)". §8.14.8: "Ground | … | K11 (mapped §2.1.6)", "Colour | … | K12" beside "K35", "K36", "K38". Inventories: `web.md` K30 = `mm.reader-settings.cinema`, K13 = source pins, K19 = update checker `enabled`; `mobile.md` K30 = `mature_content_enabled`, K13 = `settings_haptic_feedback`, K19 = retention.
- **Fix:** Prefix every key citation: `web K30` (cinema), `web K1 / mobile K30` (mature), `web K19–K22 / mobile K40` (update checker), `mobile K17`–`K20` (§8.23), `mobile K20` (§8.14.11), `mobile K13` (haptics), `mobile K15` (cover scale), `mobile K11` / `mobile K12` (§8.14.8 Ground, Colour), `mobile K21` (§8.30.7). Amend §1: "keys are cited as `web K40` or `mobile K40`".

## CONSISTENCY-8
- **Severity:** medium
- **Section:** §8.14.8 (Auto-scroll speed row, migration column)
- **Problem:** The migration treats the stored web K39 as pixels per second, but web K39 is an integer level 1–10 that the current web maps linearly to 20–220 px/s. "Old px/s ÷ 60" applied to the stored level turns the default 5 into 0.083 → clamped 0.50×, not the speed the reader had.
- **Evidence:** §8.14.8: "K39 (old px/s ÷ 60, clamped to 0.50–3.00, rounded to 0.05)". `inventory/web.md` K39: "`….autoScrollSpeed` | int | 1–10 (20–220 px/s) | 5". `frontend/src/features/reader/auto-scroll.ts`: "User-facing speed levels, 1 (slowest) to 10 (fastest)" with `MIN_RATE_PX_PER_S = 20`, `MAX_RATE_PX_PER_S = 220`.
- **Fix:** "web K39: `px = 20 + (level − 1) × 200 / 9`, then `speed = clamp(px / 60, 0.50, 3.00)` rounded to 0.05" (level 1 → 0.50×, 5 → 1.80×, 10 → 3.00×). Mobile auto-scroll speed is session-only (30 / 60 / 120 px/s, `mobile.md` A069), so nothing migrates on mobile; say so.

## CONSISTENCY-9
- **Severity:** medium
- **Section:** §2.8 (lint rule), §2.8.4, §4.2, §4.5, §7, §9.2.2, §9.4.3
- **Problem:** §2.8 says a Cinematic screen uses only the names in §2.8 and the lint fails `duration-*` names outside it, and §4.5 says every named move is started by `play(name)`, yet many choreography and component durations have no `dur.*` token, so each client must hard-code them separately (the drift §2.8 exists to prevent) and the web cannot express them within the lint. Several loops are also missing from the §4.5 name list, so the motion-timings overlay (§15.9, "all names in §4.5") cannot log them.
- **Evidence:** Untokenised values: 40 ms (Dip hold), 120 ms (row hover, check fill, menu exit, loading cross-fades, sidebar label fade, slate grace, wipe skip), 200 ms (poster and card hover, Insert barrier, menu clip, Slate collapse, highlight band, blade reverse), 224 ms (Page out), 280 ms (sibling dim), 336 ms (match cut back), 360 ms (Rise in), 400 ms (Ignite, scroll to top, transcript follow, group jump, rating card in), 500 ms (Stop the press), 520 ms (Rack focus, Develop, guided dolly), 560 ms (Iris out, Paddle page), 1200 ms (indeterminate rule loop, zoom chip), 2000 ms (error hold, flame flicker), 800 ms (at-risk flicker), 24 s (streak ring), 900 ms (sparks). §2.8.1 lint: "fails on names not in §2.8, §3.5 or the `@theme` block of `…/motion.css`". The flame flicker, ring, sparks (§9.2.2) and the guided-view dolly (§9.4.3, "over 520 ms `turn`") are not rows of §4.5.
- **Fix:** Add to §4.2, §2.8.4 and §15.1: `dur.hold.dip` 40, `dur.snap` 120, `dur.hover` 200, `dur.page.out` 224, `dur.dim` 280, `dur.match.back` 336, `dur.rise` 360, `dur.scroll` 400, `dur.press` 500, `dur.rack` 520, `dur.iris.out` 560, `dur.loop.rule` 1200, `dur.hold.error` 2000, `dur.flame.flicker` 2000, `dur.flame.risk` 800, `dur.flame.ring` 24000, `dur.flame.spark` 900 (web `--mm-dur-*`, Motion seconds, Flutter `Duration`), and replace each literal in §4.5 and §7–§9 with its token. Add §4.5 rows `Flame` (flicker, at-risk flicker, ring, sparks) and `Dolly` (guided view, 520 ms `ease.turn`) so `play()` logs them.

## CONSISTENCY-10
- **Severity:** medium
- **Section:** §4.8 (reduced-motion table) versus §4.5 (Set, Countdown, Unseal), §14.1
- **Problem:** §14.1 declares the §4.8 table authoritative for every named move, but it has no row for `Set`, the most common move (fade plus 8 px rise with a stagger), none for the Listen countdown dial, and none for `Unseal`. The dial is a leader-dial variant, and the last §4.8 row keeps the leader dial running unchanged, while §14.1 says countdowns become once-per-second labels, so the two rules disagree for it.
- **Evidence:** §4.5 Set: "Items fade 0 → 1 and rise 8 px → 0 in reading order"; Countdown: "the dial sweeps (Listen)". §4.8 has "Recap countdown" but no Set, Listen countdown or Unseal row; last row: "Progress indicators: leader dial (§7.18) … unchanged". §7.18: "Countdown dial | The leader dial at 40 px with a `spot` sweep over 5000 ms". §14.1: "countdowns become labels that update once per second".
- **Fix:** Add §4.8 rows: "Set (content entrance) | 320 ms fade + 8 px rise, 32 / 64 / 24 ms stagger | one 150 ms opacity fade of the whole block, no rise, no stagger"; "Listen countdown dial (§8.16.7) | `spot` sweep over 5 s | no sweep: the dial shows `5 S` … `1 S`, updated once per second; the 5 s timing is unchanged"; "Unseal (§9.3.3) | 160 ms glyph fade, 40 ms apart | glyphs appear at once".

## CONSISTENCY-11
- **Severity:** low
- **Section:** §4.1 principle 4 versus §7.11 (Toast motion) and §7.24 (Rating card)
- **Problem:** The principle says every exit is shorter than its entrance, but the toast exits in 240 ms after a 160 ms entrance and the rating card fades out over 600 ms after a 400 ms fade-in. The rating card fades also have no easing.
- **Evidence:** §4.1: "Exits use `lift` and are shorter than their entrances". §7.11: "In: fade + 8 px rise 160 ms `settle`. Out: fade 240 ms `lift`." §7.24: "fades in 400 ms, holds `dur.hold.rating`, fades out 600 ms".
- **Fix:** Toast: in 240 ms (`dur.line`) `ease.settle`, out 160 ms (`dur.beat`) `ease.lift`; update §4.2 (`dur.beat` "toast out", `dur.line` "toast in") and the §4.8 row ("240 ms rise"). Rating card: in 480 ms (`dur.spread`) `ease.settle`, out 240 ms (`dur.line`) `ease.lift`.

## CONSISTENCY-12
- **Severity:** low
- **Section:** §14.5 versus §10.1.1, §10.1.5 (code), §4.5, §7.8
- **Problem:** §14.5 says section heads are `h2` and that `SetHeading` is given `as="h2"`, but the web component defaults to `h3`, the whole document calls them "H3 section heads", and Flutter gives them level 2. A web call site that relies on the default ships `h3` while the app announces level 2.
- **Evidence:** §14.5: "section heads (design role `type.section`) are `h2` (the `SetHeading` component is given `as="h2"`)". §10.1.5: "`export function SetHeading({ text, id, as: Tag = "h3", …`". §10.1.6: "`final int level; // 1 masthead, 2 `type.section` head, 3 subsection`".
- **Fix:** §10.1.5: `as: Tag = "h2"`. Add to §1 conventions: "'H3' in this contract is the design name of the `type.section` head; its semantic level is 2 (web `h2`, Flutter `headingLevel: 2`)".

## CONSISTENCY-13
- **Severity:** low
- **Section:** §2.7 (Custom glyphs) versus §7.24 (Mark)
- **Problem:** §2.7 says the `certificate-18` glyph is for icon slots only and is never drawn in place of the §7.19 badge; §7.24 names the 16 px and 20 px poster, row and credit marks `certificate-18` and says they are the §7.19 badge. An implementer cannot tell whether poster badges render the glyph or the drawn box.
- **Evidence:** §2.7: "`certificate-18` (… the icon-slot form, for menu items and settings rows only; never drawn in place of the §7.19 badge)". §7.24: "`certificate-18` at 16 px (poster badges, rows, the Sources table, Discover credits) and 20 px (…) is the §7.19 badge".
- **Fix:** §7.24: "The certificate mark at 16 px (…) and 20 px (…) is the §7.19 badge, a drawn box with the `18` numeral, never the `certificate-18` glyph; the glyph appears only in icon slots (menu items, settings rows, §2.7)".

## CONSISTENCY-14
- **Severity:** low
- **Section:** §6 (UI sounds, file budget)
- **Problem:** The size budget contradicts the specified format and lengths. The twelve cues total 3,700 ms (10 + 60 + 140 + 160 + 420 + 300 + 450 + 220 + 180 + 40 + 120 + 1,600) of 48 kHz 16-bit mono WAV, which is 96,000 B/s, so about 355 KB, not ≤ 260 KB. Even a 1,300 ms `reel` (its hit lands at 1,180 ms) gives about 326 KB.
- **Evidence:** §6: "48 kHz 16-bit mono WAV, 5 ms fades, total set ≤ 260 KB"; cue lengths in the §6 table; `reel` "≤ 1600 ms".
- **Fix:** "total set ≤ 360 KB (3,700 ms × 96,000 B/s = 355,200 B plus twelve 44-byte headers)".

## CONSISTENCY-15
- **Severity:** medium
- **Section:** §9.4.2 (Picker, `MATCH THE MOOD`), §2.1.6 (mood defaults), §8.14.8, §8.15.5, §8.30.2 row 06
- **Problem:** `MATCH THE MOOD` "chooses by the series' first genre", but no genre-to-loop table exists anywhere; only the mood fallback is defined. The picker also needs "a one-line description" per loop, and only Projector room has one.
- **Evidence:** §9.4.2: "plus `MATCH THE MOOD` (chooses by the series' first genre, falling back to the profile mood's default in §2.1.6)"; "a list of the eight as rows (name in `type.title`, a one-line description in `type.caption`, …)". Grep for a genre → loop mapping finds none.
- **Fix:** Add a table (case-insensitive, first series genre that matches): Romance, Josei, Shoujo → Rain on glass; Action, Martial Arts, Murim, Sports → Low drone; Comedy, Slice of Life, School → Café; Horror, Thriller, Mystery, Psychological → Night wind; Fantasy, Isekai, Regression, Cultivation, Historical → Temple bells; Drama, Crime, Sci-Fi → Night city; Adventure, Seinen → Afternoon park; no match → the profile mood's default (§2.1.6; `default` → Projector room). Descriptions: Projector room "A soft hum with distant reel ticks."; Rain on glass "Steady rain on a window."; Night city "Distant traffic after dark."; Café "Low voices and cups."; Night wind "Wind across an empty street."; Low drone "A deep, even hum."; Afternoon park "Birds and far-off voices."; Temple bells "Slow bells over a quiet courtyard."

## CONSISTENCY-16
- **Severity:** low
- **Section:** §2.8.1 (colour map), §2.8 lint scope, and the uses in §7.1, §8.6, §8.14.6, §8.15.3, §9.4.1, §15.9
- **Problem:** Several colours are specified as a token or black at an alpha that has no token, while the lint bans arbitrary colour values and does not say whether Tailwind's `/NN` opacity modifier on a §2.8 name is allowed, and Flutter has no field for them. Each client will write its own literal.
- **Evidence:** §7.1 on-art: "1 px `ink.100` 40 % outline"; §8.14.6 and §2.1.4: "a `#000000` band at 0.84"; §9.4.1: "`paper.2` at 90 %"; §15.9: "`paper.2` at 92 %"; §8.15.3: "page colour at 90 %", "a 1 px rule in the stock's muted colour at 30 %"; §8.5: "a 50 % black disc". §2.8.1 lint: "fails … on arbitrary colour values (`[#…]`, `[rgb…]`)".
- **Fix:** Add tokens: `color.onart.outline` `rgba(243,240,232,0.40)` / `Color(0x66F3F0E8)`; `color.band.coming` `rgba(0,0,0,0.84)` / `Color(0xD6000000)`; `color.chip` `rgba(18,18,17,0.90)` / `Color(0xE6121211)`; `color.debug.panel` `rgba(18,18,17,0.92)` / `Color(0xEB121211)`; `color.disc.manage` `rgba(0,0,0,0.50)` / `Color(0x80000000)`. For the stock-relative ones, state in §2.8 that the Tailwind opacity modifier on a stock variable is allowed by the lint (`bg-(--stock-page)/90`, `border-(--stock-muted)/30`) and Flutter uses `.withValues(alpha: 0.90)` / `0.30`.

## CONSISTENCY-17
- **Severity:** low
- **Section:** §8.14.3 (Trailing) versus §9.4.2 (Indicator)
- **Problem:** The manga running head allows at most four trailing buttons on phones, but §9.4.2 adds a tappable `waveform` indicator to the manga running head while a soundscape plays, which makes five (download, bookmark, guided view, waveform, settings), and §8.14.3 does not list it.
- **Evidence:** §8.14.3: "At most four trailing buttons show on phones: download, bookmark, guided view when ready, settings." §9.4.2: "a 16 px `waveform` glyph in the reader's running head (manga) … while a soundscape plays; tap → the AMBIENT tab or group".
- **Fix:** §8.14.3: "while a soundscape plays, a 16 px `waveform` glyph follows the chapter folio's `caret-down` inside the title group (its own 44 (48 Android) hit, not one of the four trailing buttons); tap opens Reading setup at `AMBIENT`". Mirror the sentence in §9.4.2.

## CONSISTENCY-18
- **Severity:** low
- **Section:** §8.15.6 (Contents sheet) versus §7.9 (Detents), §8.14.3 (manga Contents)
- **Problem:** The novel Contents sheet is "an 85 % sheet", a detent that exists nowhere in the sheet rules (content-fit up to 0.92, or `[0.5, 0.92]`), and the manga Contents sheet is `[0.5, 0.92]`.
- **Evidence:** §8.15.6: "Inside the novel reader: an 85 % sheet (phone)". §7.9: "Content-fit up to 0.92 of the screen by default … `[0.5, 0.92]`". §8.14.3: "on phones a `[0.5, 0.92]` sheet with the chapter list".
- **Fix:** §8.15.6: "a `[0.5, 0.92]` sheet (phone), pre-scrolled to the current chapter", matching the manga reader.

## CONSISTENCY-19
- **Severity:** low
- **Section:** §7.1 (Buttons: `split` versus `primary`)
- **Problem:** `split` is defined as "a `primary` whose right segment carries a folio", but its md size is 48 on every platform while `primary` md is 44 on desktop, so a desktop row mixing them misaligns and the implementer must guess which wins.
- **Evidence:** §7.1 primary: "md 44 (desktop) / 48 (phone); lg 56 (hero); sm 32". split: "lg 56 / md 48 / sm 32".
- **Fix:** split: "lg 56 / md 44 (desktop), 48 (phone) / sm 32, as primary".

## CONSISTENCY-20
- **Severity:** low
- **Section:** §12.3 (Cinematic icon), §12.6 (Screenshot set) versus §2.6 (`rule.oxford`)
- **Problem:** `rule.oxford` is 3 px + 2 px gap + 1 px, but the icon and the screenshot frames call for "a 1 px bone Oxford rule", which is either a single hairline or not an Oxford rule.
- **Evidence:** §2.6: "`rule.oxford` | 3 px `ink.100` + 2 px gap + 1 px `ink.100`". §12.3: "a 1 px bone Oxford rule 18 % below the monogram, 40 % wide". §12.6: "with a 1 px bone Oxford rule between band and capture".
- **Fix:** §12.3: "a bone Oxford rule of 24 + 16 + 8 px on the 1024 master (the 3 : 2 : 1 ratio), 18 % below the monogram, 40 % wide". §12.6: "a bone Oxford rule at the capture's DPR 3 (9 + 6 + 3 px)".

## CONSISTENCY-21
- **Severity:** low
- **Section:** §10.1.2 and §10.2.2 ("exhaustive" lists) versus §7.27, §8.6, §8.11, §9.3.2, §9.3.6, §9.3.7, §13
- **Problem:** Both lists are declared exhaustive but miss places the screen specs animate. §7.27 says every masthead block reveals its title, yet §10.1.2 omits the collection detail name, the member page name and the profile form and Manage profiles mastheads. §10.2.2 omits the Circle letter's sender kicker and the Circle & privacy preview line, both of which "type" in their sections.
- **Evidence:** §7.27: "Masthead block (top of every page): … `type.masthead` title with the letter reveal". §8.11: "name in `type.masthead`"; §9.3.7: "name in `type.masthead` italic"; §8.6: "Masthead: kicker `CASTING`, title "New profile"". §9.3.2: "the sender's kicker types itself"; §13 moment 15 likewise; §9.3.6: "A preview line types what others will see".
- **Fix:** §10.1.2 Mastheads: add "collection detail name (§8.11), member page name (§9.3.7), profile form and Manage profiles titles (§8.6)". §10.2.2: add "the Circle letter's sender kicker when it unfolds (§9.3.2)" and "the Circle & privacy preview line (§9.3.6)".

## CONSISTENCY-22
- **Severity:** low
- **Section:** §2.8.2 (`bp.*`) versus §7.15, §8.0.9, §8.14.12, §8.17, §9.1.3
- **Problem:** Two breakpoints drive layout on both clients but are not tokens: 1280 px (sidebar expanded, stored sidebar state) and 900 px (every tablet two-pane rule in §8.0.9). With no `bp` key, no Tailwind variant and no Flutter field, each client hard-codes them.
- **Evidence:** §7.15: "Auto-spine at 768–1279; expanded from 1280". §8.0.9: "from 900 px" in ten rows. §2.8.2 lists only `bp.tablet` 600, `bp.frame` 768, `bp.desktop` 1024, `bp.wide` 1440, `bp.cinema` 1920.
- **Fix:** Add `bp.split` 900 px (`--mm-bp-split: 900px`, `--breakpoint-split: 56.25rem`, variant `split:`, `bpSplit = 900.0`) and `bp.spine` 1280 px (`--mm-bp-spine: 1280px`, `--breakpoint-spine: 80rem`, variant `spine:`, `bpSpine = 1280.0`), and cite them in §7.15 and §8.0.9.

## CONSISTENCY-23
- **Severity:** low
- **Section:** §9.2.7 (The Annual cache key), §15.5 (per-profile caches) versus §8.0.8
- **Problem:** The Annual is mode-agnostic and its request has no `content_kind` parameter, yet its cache key includes `content_kind`, so the server cannot know which value to key by.
- **Evidence:** §8.0.8: "Mode-agnostic (both kinds together): … The Annual". §9.2.7: "`GET /library/annual?year=&tz_offset_minutes=`" and "cached per day under the key `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`". §15.5: "Per-profile composed caches (`/home`, `/library/annual`) keyed by `(profile_id, mature_content_enabled, content_kind, …)`".
- **Fix:** §9.2.7 key: `(profile_id, mature_content_enabled, year, tz_offset_minutes)`. §15.5: "`/home` keyed by `(profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local hour)`; `/library/annual` by `(profile_id, mature_content_enabled, year, tz_offset_minutes)`".

## CONSISTENCY-24
- **Severity:** low
- **Section:** §8.6 (Mood chips), §8.18 (cover plate field), §8.22 (Opening state wash)
- **Problem:** Three colour or image values are given without a computable number: "brightened 3×" (in which colour space?), "a duotone copy at 3× blurred" (3× what, blurred by how much?) and "the source's hue (hashed from its id, `L 0.06`)" (no hash, no saturation).
- **Evidence:** §8.6: "a 10 × 10 square of the grade colour (brightened 3× for visibility)". §8.18: "a duotone copy at 3× blurred behind it as a soft field". §8.22: "a background wash in the source's hue (hashed from its id, `L 0.06`)".
- **Fix:** §8.6: each sRGB channel × 3, giving romantic `#4E2130`, action `#4E2718`, comedy `#45391E`, horror `#2D1E27`, slice_of_life `#2D3624`, fantasy `#362448` (default: no square). §8.18: "a duotone copy scaled to 3× the plate (504 × 744 px) at `blur.bleed` (56 px)". §8.22: "hue = the 32-bit FNV-1a of the source id (the §8.0.4 helper) mod 360, S 0.35, L 0.06".

## CONSISTENCY-25
- **Severity:** low
- **Section:** §2.8.3 (`scrim.foot`)
- **Problem:** The solid point is a pixel offset on the web (`--scrim-solid-at`, "px from that element's top edge") but an `Alignment` y value in Flutter (`end: Alignment(0, solidAt)`, range −1..1), and no conversion is given, so a Flutter component passing the measured pixel value paints the wrong ramp.
- **Evidence:** §2.8.3 web: "the component sets `--scrim-solid-at` (px from that element's top edge)"; Flutter: "`scrimFoot(solidAt)` = `LinearGradient(begin: Alignment(0, -0.2), end: Alignment(0, solidAt), …)`".
- **Fix:** Flutter signature `scrimFoot(double solidAtPx, double height)` with `end: Alignment(0, 2 * solidAtPx / height - 1)`.

## CONSISTENCY-26
- **Severity:** low
- **Section:** §8.33.1 (Command palette field) versus §7.4 (`index` search field)
- **Problem:** §7.4 defines the `index` field as `type.field` (28–40 px by breakpoint, 36 px on desktop) and lists the command palette among its uses; §8.33.1 sets the palette's field at Bodoni Italic 28 on desktop.
- **Evidence:** §7.4: "`index` (big) | `type.field` (Bodoni Moda Italic) at 28–40 px … | Discover, Dialogue, command palette, Picks ask field". §8.33.1: "The index field (Bodoni Italic 28)".
- **Fix:** §8.33.1: "The index field (`type.field` at its phone size, 28/36, fixed in the palette at every breakpoint)", and add "(the command palette fixes it at 28/36)" to the §7.4 row.

## CONSISTENCY-27
- **Severity:** low
- **Section:** §9.2.5 (Card anatomy)
- **Problem:** Two formats exist (Story 1080 × 1920, Post 1080 × 1350), but the key-figure and caption sizes are given for Story only.
- **Evidence:** §9.2.5: "centre: the key figure in Bodoni Moda Roman at 360 px (Story) with its caption in Newsreader Italic 48".
- **Fix:** "Story: figure 360 px, caption 48 px. Post: figure 256 px, caption 36 px (× 0.70, the height ratio 1350 / 1920, rounded to the 4 px baseline); the 64 px margin, the 40 px wordmark and Plex Mono 24 are the same in both".

## CONSISTENCY-28
- **Severity:** low
- **Section:** §8.14.8 (Reading setup on desktop) versus §7.9 (column panels) and §8.14.12 (side panels)
- **Problem:** Reading setup is "a right column panel on desktop", and column panels are 4 columns (min 400 px), but §8.14.12 says it takes the right side-panel slot, whose panels are 3 columns (min 320 px). The narrow-desktop rule (`viewport − 2 × margin − open panels` ≥ 480 px) depends on which width applies.
- **Evidence:** §8.14.8: "a right column panel on desktop". §7.9: "Sheets become column panels: 4 columns wide (min 400 px)". §8.14.12: "each 3 columns (min 320 px)"; "Reading setup (§8.14.8) takes the right slot".
- **Fix:** §8.14.8: "on desktop it opens in the right side-panel slot at 3 columns (min 320 px), §8.14.12".

## CONSISTENCY-29
- **Severity:** low
- **Section:** §9.2.2 (Milestone title cards) versus §8.0.3 (route contract, root navigator list)
- **Problem:** The milestone title card is a full-screen takeover with Dip in and Dip out, but it is neither a route in the §8.0.3 contract nor listed as an overlay (the Lightbox is listed on the root navigator), so back behaviour and deep-link handling have to be guessed. Appendix B only says "takeover".
- **Evidence:** §9.2.2: "opens a takeover title card (Dip in, Dip out; never inside a reader)". §8.0.3 root navigator: "`setup`, `login`, … `onboarding`, the other `profiles*` routes, the Lightbox". Appendix B: "Streak flame and milestone title card | Streaks | takeover".
- **Fix:** §8.0.3 root navigator: add "the milestone title card (an overlay route with no path; web `?view=milestone` history entry like the Lightbox's `?view=cover`, so browser back and Android back close it)".
