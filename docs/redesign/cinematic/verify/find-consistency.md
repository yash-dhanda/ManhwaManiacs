# Cinematic DESIGN.md: internal-consistency audit

Scope: `cinematic/DESIGN.md` as revised after `critic.md`. Lens: every token, motion, haptic and sound value must be identical wherever it appears, every referenced name must be defined, and no two sections may contradict each other. Every "missing" claim below was checked by searching the whole file. Contrast figures were recomputed with the WCAG 2.x relative-luminance formula.

Totals: 2 high, 20 medium, 28 low.

---

### CONSISTENCY-1
- **Severity:** high
- **Section:** §2.7 (custom glyphs), §7.19 (badges), §7.24 (the 18+ gate), §7.25
- **Problem:** The 18+ certificate at 16 px and 20 px is defined three incompatible ways. The badge row gives a 1 px outline with Archivo numerals. The "Mark" gives a 2 px border with Bodoni Moda 900 numerals, at the same 16 and 20 px sizes. The §2.7 icon glyph is drawn at Phosphor stroke weights, which is 0.75 px (Light) or 1 px (Regular) at 16 px. An implementer cannot know which one to draw on posters, feature credits, the picker avatar or the Sources table.
- **Evidence:** §7.19: "18+ certificate | A square 16 × 16 (20 × 20 on feature pages) with a 1 px `proof` outline and `18` in `proof` Archivo `wdth` 62 `wght` 800". §7.24: "`certificate-18`: a square with a 2 px `proof` border and "18" set in Bodoni Moda Roman `wght` 900 in `proof`. Sizes 16 (badges), 20 (feature credits), 160 (the dialog)." §2.7: "`certificate-18` (a square seal with "18", the 18+ mark) … stroke 12 (Light) and 16 (Regular)".
- **Fix:** Keep one definition per size range. In §7.24 "Mark", replace the text with: "At 16 and 20 px the mark is the §7.19 badge: 1 px `proof` outline, "18" in Archivo `wdth` 62 `wght` 800 at 9 px (16 px box) or 11 px (20 px box). At 160 px (the dialog) it has a 4 px `proof` border and "18" in Bodoni Moda Roman `wght` 900 at 88 px. The §2.7 glyph `certificate-18` is used only as a 24 px icon in menus and settings rows." Keep §7.19 unchanged, and point §7.25 ("18+ marker on the picker: a 20 px certificate") at the §7.19 badge.

### CONSISTENCY-2
- **Severity:** high
- **Section:** §12.4 (splash timeline), §8.2 (pre-roll), §4.5 (Letter set, Rule draw), §4.2 (`dur.reel`)
- **Problem:** The cold-start reveal contradicts itself in four places:
  1. The wordmark letters cannot finish in their window. They start at 380 ms with a 20 ms stagger, 13 graphemes and 640 ms per letter, so the last letter ends at 380 + 12 × 20 + 640 = 1260 ms. The row says 380–1100, and the letters would still be rising during the 1180 ms "impression".
  2. The duration rule `max(dataReady, 900 ms)` lets the reveal end at 900 ms, before the Oxford rule (820–1180) and the impression (1180) have played.
  3. The desktop hand-off is a 320 ms flight that starts at 1180, so it ends at 1500 ms. That is past the 1400 ms cap and past its own 1180–1400 row.
  4. The 20 ms stagger and the 360 ms rule draw override `scalar.stagger.letter.item` (24) and Rule draw (480 ms) without being tokens. The row still says "Per-letter reveal (§10.1)".
- **Evidence:** §12.4: "380–1100 | Wordmark letters | Per-letter reveal (§10.1) with a 20 ms stagger (13 graphemes, 640 ms each)"; "1180–1400 | Hand-off | Desktop: … (shared element, 320 ms `turn`)"; "Duration rule: `max(dataReady, 900 ms)`, capped at 1400 ms". §8.2: "the reveal lasts `max(probe, 900 ms)` capped at 1400 ms".
- **Fix:** Retime the rows:
  - 300–1180: wordmark letters (start 300; stagger 20 ms, so the last letter starts at 540 and ends at 1180).
  - 820–1180: Oxford rule, 360 ms `settle`.
  - 1180: impression, 80 ms.
  - 1180–1400: hand-off. Desktop flight 220 ms `turn`; phone dissolve 220 ms.

  Change the duration rule in §12.4 and §8.2 to `max(dataReady, 1180 ms)` + the 220 ms hand-off, capped at `dur.reel` 1400 ms. Add two tokens and use them in §12.4: `scalar.stagger.letterSplash { item: 20 }` (Flutter `MotionStagger(item: 20)`) and `dur.rule.splash` 360 ms (`--mm-dur-rule-splash: 360ms`, `durRuleSplash`).

### CONSISTENCY-3
- **Severity:** medium
- **Section:** §7.11 (toasts) vs §2.1.1 and §2.4
- **Problem:** The toast surface is `paper.0` in the component spec, but the colour ramp and the elevation table both put toasts on `paper.2`. This also decides whether the raised-stock rule (ink.45 rendered as ink.60) applies inside toasts.
- **Evidence:** §7.11: "Surface | `paper.0` band with a 1 px `rule.2` border". §2.1.1: "`color.paper.2` … Sheets, menus, popovers, the command palette, toasts' band". §2.4: "Level 2 | `paper.2` | 1 px `rule.2` … | Sheets, menus, popovers, palette, toasts".
- **Fix:** In §7.11, set Surface to "`paper.2` band with a 1 px `rule.2` border (elevation level 2, `data-stock="raised"` / `CineStock.raised`)".

### CONSISTENCY-4
- **Severity:** medium
- **Section:** §7.15 (sidebar width) vs §1 conventions, §8.0.1, §8.0.9
- **Problem:** The width range that uses the collapsed spine is 768–1279 in the sidebar spec and 768–1023 everywhere else. Between 1024 and 1279 px the layout changes by 176 px of canvas.
- **Evidence:** §7.15: "Auto-spine at 768–1279." §1: "768–1023 is the desktop frame with the collapsed sidebar, called the *spine*". §8.0.9: "the desktop frame with the spine at 768–1023 px".
- **Fix:** In §7.15, write "Auto-spine at 768–1023; 248 px expanded from 1024". This matches the three other places and §8.0.1's 12-column grid from 1024.

### CONSISTENCY-5
- **Severity:** medium
- **Section:** §4.3 (curve "Use" column) vs §4.5, §8.14.2, §7.5, §7.12, §7.14, §7.30
- **Problem:** The curve table assigns curves to moves that the motion table and the component specs animate with other curves:
  - Wipes are `turn` in §4.3 but `settle` for the blades.
  - Rule slide is `set` in §4.3 but `settle` in §4.5, §7.5, §7.12 and §7.14.
  - The iris is `turn` in §4.3, but the iris out is `settle`.
  - Lightbox close is an exit, yet it uses `settle`, while §4.3 says exits use `lift`.
- **Evidence:** §4.3: "`ease.turn` … Dissolves, match cuts, wipes, iris, colour changes"; "`ease.set` … State changes inside a component (toggle knob, rule slide, progress width)". §4.5: "Column wipe | … | blades `ease.settle`"; "Rule slide | 320 ms | `ease.settle`"; "Iris | close 480 ms, iris out 560 ms | close `ease.turn`, out `ease.settle`"; "Lightbox | … close by button 320 ms | … close `ease.settle`".
- **Fix:** Rewrite the §4.3 Use column:
  - `ease.settle`: "Every entrance, column-wipe blades (close and open), iris out, Rule slide".
  - `ease.turn`: "Dissolves, match cuts (including the Lightbox open and its reverse close), iris close, Stop the press rack, colour changes".
  - `ease.set`: "State changes inside a component (toggle knob, progress width, button impression)".

  In §4.5 and §7.30, change the Lightbox close by button to "320 ms `ease.turn` (a reverse match cut)".

### CONSISTENCY-6
- **Severity:** medium
- **Section:** §4.3 vs §2.8.4 (`ease.drift`)
- **Problem:** The Flutter value of `ease.drift` differs between the two tables. `Curves.easeInOutSine` in Flutter is `Cubic(0.445, 0.05, 0.55, 0.95)`, not `Cubic(0.37, 0, 0.63, 1)`, so Drift, flicker and the flame would move differently on the app and the web.
- **Evidence:** §4.3: "`ease.drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | `Curves.easeInOutSine`". §2.8.4: "`easeDrift` = `Cubic(0.37, 0, 0.63, 1)`".
- **Fix:** In §4.3, replace `Curves.easeInOutSine` with `Cubic(0.37, 0, 0.63, 1)`.

### CONSISTENCY-7
- **Severity:** medium
- **Section:** §3.2 (web fluid formulas) vs the §3.2 table and §3.5 Flutter `lines`
- **Problem:** The web gives fluid display roles a single unitless line height (cover 0.93, all others 1.0). The table, which Flutter uses, has different ratios per breakpoint:
  - headline 32/36 (1.125) and 44/48
  - section 24/28 (1.167) through 36/40
  - masthead 72/68 (0.944)
  - numeral 96/88 (0.917)

  So web headlines and H3s are set noticeably tighter than on the app, and the italic `type.section` descenders collide at 1.0. §3.5 leaves the value of `--mm-type-<role>-lh` blank for these roles.
- **Evidence:** §3.2: "Line heights for fluid roles are unitless (cover 0.93, the others 1.0)." Table: "`type.headline` … 32/36 | 44/48 | 56/56 | 64/64"; "`type.section` … 24/28 | 28/32 | 32/36 | 36/40".
- **Fix:** Keep the `clamp()` sizes and redefine `--mm-type-<role>-lh` per breakpoint media query as the table's ratio:

  | Role | phone | tablet | desktop | wide |
  |---|---|---|---|---|
  | cover | 1.0 | 0.9375 | 0.955 | 0.933 |
  | masthead | 1.0 | 1.0 | 0.944 | 0.955 |
  | headline | 1.125 | 1.091 | 1.0 | 1.0 |
  | section | 1.167 | 1.143 | 1.125 | 1.111 |
  | numeral | 1.0 | 1.0 | 0.917 | 0.933 |

  The `Measure` wrapper keeps the 4 px rounding.

### CONSISTENCY-8
- **Severity:** medium
- **Section:** §10.1.5 (web SetHeading) vs §10.1.6 (Flutter) and §4.6
- **Problem:** The letter stagger step differs between the clients for any heading with a space:
  - The web computes `n` from `graphemes(text).length`, which counts spaces. Spaces are not animated children, so the stagger is too short.
  - Flutter counts letters only, and uses integer division `560 ~/ (n − 1)`.

  Example: "Because you read Solo Leveling" gets a 19.3 ms step on the web and 22 ms on Flutter. A 40-letter title totals 560 ms on the web and 546 ms on Flutter.
- **Evidence:** §10.1.5: `custom={graphemes(text).length}` with `stagger(Math.min(0.024, 0.56 / Math.max(1, n - 1)))`. §10.1.6: `late final int _n = widget.text.characters.where((c) => c != ' ').length; late final int _step = _n < 2 ? 0 : math.min(24, 560 ~/ (_n - 1));`.
- **Fix:**
  - In §4.6 and §10.1.1, define `n` as "graphemes excluding spaces".
  - Web: `custom={graphemes(text).filter((g) => g !== " ").length}`.
  - Flutter: `late final double _step = _n < 2 ? 0 : math.min(24.0, 560 / (_n - 1));`, with `start = 120.0 + _step * i` and controller duration `(120 + _step * (_n - 1) + 640).round()` ms.

### CONSISTENCY-9
- **Severity:** medium
- **Section:** §10.1.5 (web SetHeading) vs §4.7, §10.1.1 and §15.6
- **Problem:** The reference web component leaves out three rules that other sections require. The Flutter version implements the first one, so the two clients differ.
  1. §4.7 requires a reveal that leaves the viewport to jump to its end state.
  2. §10.1.1 requires cover and feature titles to replay "every mount", but the component skips any id already in `seen`.
  3. §15.6 caps reveals at 60 graphemes with a word-level fallback.
- **Evidence:** §4.7: "A letter reveal that leaves the viewport before it finishes jumps to its end state". §10.1.1: "Cover and feature titles: every mount". §15.6: "letter reveals cap at 60 graphemes per heading (longer titles fall back to a word-level reveal with the same timings)". The §10.1.5 code has only `whileInView` with `once: true` and `initial={once ? false : "hidden"}`. The Flutter code has `if (_c.isAnimating && visible == 0) _c.value = 1;`.
- **Fix:** Add three things to both implementations:
  1. A `replay?: boolean` prop (Flutter `replay` field). When it is true, `seen` is neither read nor written. Covers, feature titles and book titles pass `true`.
  2. Web: use `useInView(ref, { amount: 0.5 })` with `useAnimate`. When the heading leaves the viewport mid-run, call `animate(scope.current.querySelectorAll(".set-letter"), { opacity: 1, y: 0, filter: "blur(0px)" }, { duration: 0 })`.
  3. When the letter count exceeds 60, split by word instead of grapheme, with the same 640 / 440 ms and the same stagger formula over words. Add this to the Flutter code too.

### CONSISTENCY-10
- **Severity:** medium
- **Section:** §10.2.1, §10.2.3, §10.2.4 (typing caret)
- **Problem:**
  1. The Flutter blink formula does not produce 530 ms halves. `Opacity((v * 6).floor().isEven …)` on a 3340 ms controller gives 556.7 ms halves across the full 3340 ms, not six 530 ms halves inside the first 3180 ms.
  2. On both clients the sequence ends on an "off" half, so the "160 ms opacity fade" runs from 0 to 0 and is invisible, which contradicts "fades out over 160 ms".
- **Evidence:** §10.2.4: "`AnimationController(duration: 3340.ms)` driving `Opacity((v * 6).floor().isEven ? 1 : 0)` for the first 3180 ms". §10.2.3: "six 530 ms halves (on, off, on, off, on, off) followed by a 160 ms opacity fade".
- **Fix:**
  - Blink order: off, on, off, on, off, on (the caret is solid while typing, so three blinks end visible), then fade 1 → 0 over 160 ms.
  - Web `caret-out`, 3340 ms with `steps(1)`: opacity 0 at 0 %, 1 at 15.87 %, 0 at 31.74 %, 1 at 47.60 %, 0 at 63.47 %, 1 at 79.34 %–95.21 %, then a linear fade to 0 at 100 %.
  - Flutter: `final ms = _blink.value * 3340; final o = ms < 3180 ? ((ms ~/ 530).isOdd ? 1.0 : 0.0) : 1 - (ms - 3180) / 160;`.

### CONSISTENCY-11
- **Severity:** medium
- **Section:** §8.14.2 (Flutter wipe route) vs §4.5 (Column wipe) and the §8.14.2 blade counts
- **Problem:** Tablets have 8 blades, so the wipe is 312 + 40 + 392 = 744 ms. The Flutter route is still told to run 872 ms "on tablets and wider", and §4.5 lists only the desktop and phone totals. The web at 600–1023 px also uses 8 blades, so the web total there is 744 ms, and "the same totals as the web" is false.
- **Evidence:** §8.14.2: "4 blades on phones, 8 on tablets, 12 on desktop"; "route duration 872 ms on tablets and wider, 616 ms on phones, the same totals as the web". §4.5: "desktop 376 + 40 + 456 = 872 ms; phone 248 + 40 + 328 = 616 ms".
- **Fix:**
  - §4.5 row: add "tablet (8 columns) 312 + 40 + 392 = 744 ms".
  - §8.14.2: "route duration = (200 + (c − 1) × 16) + 40 + (280 + (c − 1) × 16) ms for c blades: 616 (4), 744 (8), 872 (12)". Add "Dip reaches the first page 304 ms sooner on tablets".
  - §8.30.3: "tablets: blades close 80–392".

### CONSISTENCY-12
- **Severity:** medium
- **Section:** §2.1.5 (page seed picker) vs §9.4.4, §15.3, §15.6 and Appendix A
- **Problem:** The two clients feed the "identical" picker different inputs: the web samples 16 × 16 = 256 pixels, and Flutter samples a 64 px wide decode (64 × h pixels). The seed is "the pixel with the highest S", which depends on resolution, so the same page gives different tints on the two clients. The backend cache stores whichever client reports first "for any profile", so a series' chrome colour depends on which device read it first. The parity vectors (`tint-vectors.json`, all 16 × 16) never exercise Flutter's real input.
- **Evidence:** §2.1.5: "convert each of the 256 (web) or 64 × h (Flutter) pixels to HLS"; "`ResizeImage(provider, width: 64)`". §9.4.4: "a 64 px decode through the same picker on Flutter". §15.6: "a `compute()` isolate on a 64 px decode in Flutter".
- **Fix:** Use 16 × 16 on both clients. Flutter: `ResizeImage(provider, width: 16, height: 16, policy: ResizeImagePolicy.exact)`, 256 RGBA pixels. Web: unchanged, `drawImage(bitmap, 0, 0, 16, 16)` with `ctx.imageSmoothingQuality = "medium"`. Replace "64 px" with "16 × 16" in §2.1.5, §9.4.4, §15.3 (`page_tint.dart`), §15.6 and Appendix A (graft row 1 and the "Adapted" note).

### CONSISTENCY-13
- **Severity:** medium
- **Section:** §6 (playback), §8.16.10 (lock screen), §9.4.2 (soundscape), §14.9
- **Problem:** The iOS audio session is process-wide and holds one category at a time, but the contract assigns it three:
  - `.ambient` for UI cues.
  - "stays speech" for narration.
  - "the same `audio_session` (ambient category)" for the soundscape.

  The soundscape is required to play under narration, ducked to 30 %. That is impossible if the session is ambient, because narration would then be muted by the silent switch and stop in the background.
- **Evidence:** §6: "iOS uses the `.ambient` session category so the ring/silent switch mutes cues". §8.16.10: "the `audio_session` category stays speech". §9.4.2: "a second `just_audio` player … under the same `audio_session` (ambient category on iOS so the silent switch mutes it …)"; "Ducks to 30 % while Listen narration plays".
- **Fix:** Add one rule to §9.4.2 and reference it from §6 and §8.16.10. `AudioSession.instance` is configured only by `skin_audio.dart`:
  - While narration is active: `AudioSessionConfiguration.speech()`. The soundscape keeps playing at 30 % player volume (UI cues are suppressed anyway).
  - Otherwise: `AudioSessionConfiguration(avAudioSessionCategory: AVAudioSessionCategory.ambient, avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers)`.
  - Reconfigure on narration start and stop.
  - `flutter_soloud` is initialised after the session is configured and never sets a category itself.

### CONSISTENCY-14
- **Severity:** medium
- **Section:** §7.25 (avatars) and §2.8.1 (`color.avatar.*`)
- **Problem:** The contract claims the `ink.100` glyph is at least 4.5:1 on every avatar field. It is not on six of the twelve fields.

  | Field | Hex | Contrast of `#F3F0E8` on it |
  |---|---|---|
  | cyan | `#1F8FA8` | 3.32 |
  | amber | `#B87A12` | 3.16 |
  | emerald | `#1E8C60` | 3.71 |
  | ember | `#C24724` | 4.37 |
  | star | `#A8850F` | 3.06 |
  | reader | `#187C7C` | 4.38 |

- **Evidence:** §7.25: "a Phosphor Fill glyph at 45 % of the diameter in `ink.100` (≥ 4.5:1 on every field)".
- **Fix:** Darken the six fields in HLS lightness only, keeping hue and saturation. Update §7.25, §2.8.1 and the Flutter values:

  | Field | New hex | Contrast | Flutter |
  |---|---|---|---|
  | cyan | `#1A778C` | 4.54 | `Color(0xFF1A778C)` |
  | amber | `#95630F` | 4.53 | `Color(0xFF95630F)` |
  | emerald | `#1A7B54` | 4.60 | `Color(0xFF1A7B54)` |
  | ember | `#BE4523` | 4.54 | `Color(0xFFBE4523)` |
  | star | `#85690C` | 4.58 | `Color(0xFF85690C)` |
  | reader | `#177878` | 4.62 | `Color(0xFF177878)` |

### CONSISTENCY-15
- **Severity:** medium
- **Section:** §2.8 (utility lint) vs §7.1, §7.2, §7.7, §7.17, §7.18, §7.30, §8.14.8, §8.24, §9.4.3, §10.2.3
- **Problem:** §2.8 says a Cinematic screen uses only the names in the token tables, enforced by `lint-utilities.mjs` over `src/skins/cinematic/**`. Two things break that:
  1. The components use colours that are not tokens:
     - on-art fill `rgba(0,0,0,0.64)` (§7.1, §7.2, §9.2.4)
     - poster hairline `rgba(243,240,232,0.08)`
     - galley bar `rgba(243,240,232,0.06)`
     - leader sweep `rgba(243,240,232,0.22)`
     - Lightbox `#000000` at 96 %
     - subtitle band `#000000` at 64 %
     - guided matte at 85 %
     - warmth layer `#FF8A00`
  2. The contract's own `TypedHeadline` uses `animate-caret-out`, which is defined in no `@theme`, plus layout utilities (`inline-block`, `whitespace-nowrap`, `absolute`, `h-[0.86em]`) that no table lists.

  As written, the lint either fails the reference code or has an undefined scope.
- **Evidence:** §2.8: "a Cinematic screen uses only the names in this table (checked by `design/lint-utilities.mjs` … which greps `src/skins/cinematic/**` for utilities outside this list". §10.2.3: `className={`absolute bottom-[0.06em] … bg-spot ${done ? "animate-caret-out" : ""}`}`.
- **Fix:**
  1. Add colour tokens to §2.8.1 and §15.1:

     | Token | Value | Flutter |
     |---|---|---|
     | `color.onart` | `rgba(0,0,0,0.64)` | `Color(0xA3000000)`, also used for the subtitle band |
     | `color.hairline.art` | `rgba(243,240,232,0.08)` | `Color(0x14F3F0E8)` |
     | `color.galley` | `rgba(243,240,232,0.06)` | `Color(0x0FF3F0E8)` |
     | `color.leader.sweep` | `rgba(243,240,232,0.22)` | `Color(0x38F3F0E8)` |
     | `color.lightbox` | `rgba(0,0,0,0.96)` | `Color(0xF5000000)` |
     | `color.matte.guided` | `rgba(0,0,0,0.85)` | `Color(0xD9000000)` |
     | `color.warmth` | `#FF8A00` | `Color(0xFFFF8A00)` |

  2. Add `--animate-caret-out: caret-out 3340ms steps(1) forwards` to the `@theme` block.
  3. Define the lint scope. It checks only these utilities, and fails on names not in §2.8 or §3.5 and on arbitrary colour values `[#…]` / `[rgb…]`: `bg-*`, `text-*` (colour and size), `border-*` colour, `outline-*` colour, `fill-*`, `stroke-*`, `font-*`, `tracking-*`, `leading-*`, `rounded-*`, `blur-*`, `ease-*`, `duration-*`, `z-*`, `animate-*`. Layout, position and size utilities, including arbitrary em lengths, are out of scope.

### CONSISTENCY-16
- **Severity:** medium
- **Section:** §11 (gesture matrix, tap zones) vs §9.4.3 (guided view)
- **Problem:**
  1. Guided-view tap zones conflict. The matrix gives 30 / 70 (back / next), meaning left 30 % previous and right 70 % next. §9.4.3 gives right 30 % next and left side previous.
  2. Neither leaves a menu zone, but §9.4.3 says the chrome "behave[s] as in paged mode", and paged mode has a 40 % centre menu zone.
- **Evidence:** §11: "30 / 40 / 30 (manga), 25 / 50 / 25 (novel), 30 / 70 (guided): back / menu / next". §9.4.3: "tap the right 30 % / swipe left / `→` / `j` → next panel; left side → previous"; "the running head and folio bar behave as in paged mode".
- **Fix:** Make guided view 30 / 40 / 30 (previous / chrome / next, mirrored for RTL) in both places. In §9.4.3: "tap the right 30 %: next panel; the left 30 %: previous; the centre 40 %: chrome". In §11: "30 / 40 / 30 (manga and guided)".

### CONSISTENCY-17
- **Severity:** medium
- **Section:** §8.15.3 (novel chrome) vs §4.8, §8.14.3, §4.2
- **Problem:** Novel-reader chrome fades in 180 ms. That duration is not a token and matches neither the reader-chrome timing (240 in / 160 out) nor the reduced-motion row. The novel chrome is not covered by any §4.8 row, and 180 appears nowhere else as a motion value.
- **Evidence:** §8.15.3: "#### 8.15.3 Chrome (tap anywhere toggles; fades 180 ms)". §4.8: "Reader chrome in / out | 8 px slide + fade (240 / 160 ms) | fade only, same durations". §8.14.3: "Motion: in 240 ms `settle` … out 160 ms `lift`".
- **Fix:** In §8.15.3, write "(tap anywhere toggles; fades in 240 ms `settle` / out 160 ms `lift`, no slide because the bars are solid)". Extend the §4.8 row to "Reader chrome in / out (manga and novel)".

### CONSISTENCY-18
- **Severity:** medium
- **Section:** §4.8 (reduced motion, declared authoritative in §14.1) vs §4.5, §7.18, §8.14.7, §8.15.4, §8.14.5, §7.30
- **Problem:** Several named or spatial moves have no reduced-motion row, but §14.1 says the table "is authoritative for every named move":
  - **Set** (items rise 8 px with a stagger).
  - **Countdown**: the Listen 40 px dial sweep. Only the recap countdown has a row.
  - Page turn **SLIDE**: the manga reader slides the page 280 ms and the novel reader slides it 300 ms.
  - Double-tap and keyboard zoom: 240 ms `settle` in the reader and the Lightbox. §14.1 says zooms become an opacity change, which cannot apply to a scale change.
- **Evidence:** §14.1: "**The table in §4.8 is authoritative** for every named move." §4.5: "**Set** … Items fade 0 → 1 and rise 8 px → 0". "**Countdown** | … the dial sweeps (Listen)". The Set, Countdown-dial, Slide and zoom rows are absent from §4.8.
- **Fix:** Add rows to §4.8:
  - "Set | fade + 8 px rise, staggered | the whole block fades in once over 150 ms; no rise, no stagger".
  - "Countdown dial (Listen next) | 5 s sweep | a folio `NEXT IN 5 S` that updates once per second".
  - "Page turn SLIDE (manga, novel) | slide 280 ms | 150 ms opacity cross-fade".
  - "Double-tap / key zoom (reader, Lightbox) | 240 ms scale | the scale jumps to its target at once".

### CONSISTENCY-19
- **Severity:** medium
- **Section:** §8.9 (Library status filter), §8.17 (At a glance status select), §7.19 (reading-status badges)
- **Problem:** The same reading-status field is labelled three ways, so it is unclear which label maps to which stored value:
  - Library filter: "NOT STARTED, COMPLETED, PLAN TO READ".
  - At a glance: "UNREAD, DONE, PLAN".
  - Badges: "PLAN, DONE". The Library filter's "COMPLETED" also collides with the publication-status badge `COMPLETED`.
- **Evidence:** §8.9: "`ALL · READING · NOT STARTED · COMPLETED · ON HOLD · PLAN TO READ · DROPPED`". §8.17: "(`READING · PLAN · ON HOLD · DONE · DROPPED · UNREAD`)". §7.19: "Reading status `READING`, `ON HOLD`, `PLAN`, `DROPPED`, `DONE`"; "Status `ONGOING`, `COMPLETED`, …".
- **Fix:** Use one label set everywhere for reading status: `READING · NOT STARTED · ON HOLD · PLAN TO READ · DONE · DROPPED`. Badges may abbreviate only `PLAN TO READ` → `PLAN`. `COMPLETED` is reserved for publication status. Apply this in §8.9 (slug line and `1`–`7` keys), §8.17 and §7.19.

### CONSISTENCY-20
- **Severity:** medium
- **Section:** §9.1.8 (AI unavailable), §7.8 (rail AI unavailable) vs §2.1.3 (`color.note`) and §7.23 (NOTE tone)
- **Problem:** The `NOTE` kicker is defined as spot-coloured caution semantics, but the AI "unavailable" state specifies a `NOTE` kicker in `ink.45`. That gives two colours for one semantic kicker.
- **Evidence:** §2.1.3: "`color.note` | `color.spot` + the kicker `NOTE` | … Cautions … Always carries a text kicker". §7.23: "`NOTE` (caution, in `spot`)". §9.1.8: "A static slate or a `NOTE` kicker line in `ink.45`; never `proof`".
- **Fix:** In §9.1.8, write "a `NOTE` kicker in `spot` (`color.note`) with the reason in `type.caption` `ink.60`; never `proof`, never an error rule". §7.8 inherits this. The recap slate's `RECAP UNAVAILABLE` kicker stays `ink.45`, because it is not a `NOTE`.

### CONSISTENCY-21
- **Severity:** medium
- **Section:** §3.2 and §3.5 (`type.dropcap`) vs §8.15.2 (novel opener), §9.1.5 (recap)
- **Problem:** The drop cap is defined as three lines of `type.body`: 72 or 84 px, fixed in Flutter's `sizes`. Two surfaces use it on other text:
  - Recap paragraphs are Newsreader 20/32, so three lines is 96 px.
  - The novel reader's body is user-sized (14–40 px at 1.30–2.10 leading).

  Flutter's fixed `[72, 72, 84, 84]` cannot produce either. The Flutter row also omits the `opsz` 96 axis that §3.2 gives the role.
- **Evidence:** §3.5: "`typeDropcap` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 800, sizes: [72, 72, 84, 84], lines: [72, 72, 84, 84] …)`". §9.1.5: "Newsreader 20/32 … with a Bodoni drop cap". §8.15.2: "a Bodoni Moda **drop cap** 3 lines tall".
- **Fix:** Define the drop cap as 3 × the line height of the paragraph it opens, on both clients. Web: `--mm-type-dropcap-size: calc(var(--para-lh) * 3)`, where each paragraph sets `--para-lh`. Flutter: `CineType.dropcap(double paragraphLineHeightPx)` returning Bodoni Moda 800 at `3 × lh` with `FontVariation('opsz', min(3 × lh, 96))`. Remove the fixed `sizes` and `lines` from `typeDropcap`.

### CONSISTENCY-22
- **Severity:** medium
- **Section:** §8.14.13 (page actions) vs §7.9 (sheet detents)
- **Problem:** The page-actions sheet detents conflict. §7.9 names reader page actions as a live-preview sheet with `[0.5, 0.92]`, while §8.14.13 gives it a single `[0.5]` detent.
- **Evidence:** §7.9: "Live-preview sheets (reader settings, novel type, reader page actions) use `[0.5, 0.92]`". §8.14.13: "A `[0.5]` sheet (phone) or menu (desktop)".
- **Fix:** In §8.14.13, write "A `[0.5, 0.92]` sheet (phone)".

### CONSISTENCY-23
- **Severity:** low
- **Section:** §4.8 (row "Paddle page, rail focus scroll, …")
- **Problem:** The row lists seven scrolls but only five durations, and §8.30.1 and §8.20 never state the durations of the settings search jump and the group jump.
- **Evidence:** §4.8: "Paddle page, rail focus scroll, scroll to top, transcript follow, tap to scroll, settings search jump, group jump | 560 / 320 / 400 / 400 / 300 ms smooth scrolls".
- **Fix:** "560 / 320 / 400 / 400 / 300 / 400 / 400 ms". Add "scrolls 400 ms `settle`" to the settings search jump in §8.30.1 and the group jump in §8.20.

### CONSISTENCY-24
- **Severity:** low
- **Section:** §4.1 principle 4 and §8.0.4 (Back) vs §4.5
- **Problem:** The rule that exits last 0.7 × the entrance is contradicted by most exits in the motion table:
  - Insert: 160 ms out (0.7 × 320 = 224)
  - Rise: 240 ms out (0.7 × 360 = 252)
  - Slate collapse: 200 ms (0.7 × 320 = 224)
  - Chrome: 160 ms out (0.7 × 240 = 168)
  - Lightbox close: 320 ms (0.7 × 480 = 336)
- **Evidence:** §4.1: "Exits use `lift` at 0.7 × the entrance duration." §8.0.4: "Back | The reverse of the forward move at 0.7 × duration". §4.5 rows for Insert, Rise, Slate and Lightbox.
- **Fix:** In §4.1, write "Exits use `lift`; each exit's duration is the one given in §4.5". In §8.0.4, write "Back | the forward move's exit as given in §4.5 (Page 224 ms, Match cut reversed 336 ms `turn`)".

### CONSISTENCY-25
- **Severity:** low
- **Section:** §8.14.11 (stale bookmark toast) vs §7.11 and §2.8.4 hold tokens
- **Problem:** The stale-bookmark toast holds for 5200 ms, which is not one of the four hold tokens.
- **Evidence:** §8.14.11: "Toast "That page moved. Opened at the nearest one." (5200 ms)". §7.11: "Hold | 3600 ms; errors 6000; with an action 8000; skin undo 10000".
- **Fix:** Use `dur.hold.toast` (3600 ms).

### CONSISTENCY-26
- **Severity:** low
- **Section:** §7.7 (poster captions), §7.10 (dialog title) vs §3.2
- **Problem:** Two components use a type role with a size that role does not have at that breakpoint:
  - Poster captions are "`type.title` 14/20", but `type.title` is 15/20 on phones and 16/20 on desktop.
  - Dialog titles are "`type.subhead` 24/28", which is the desktop size only. Phones would be 20/24.
- **Evidence:** §7.7: "`type.title` 14/20 on 1 line". §7.10: "Title | `type.subhead` (Bodoni Moda) 24/28". §3.2: "`type.title` … 15/20 | 15/20 | 16/20 | 16/20"; "`type.subhead` … 20/24 | 22/28 | 24/28 | 24/28".
- **Fix:** Pick one of two options for posters. Either write "Below: `type.title` (breakpoint size)", or add a role `type.title.sm`: Archivo wdth 100, wght 600, 14/20 at every breakpoint, −0.005em, cap 2.0, Flutter `typeTitleSm`. For dialogs, write "Title | `type.subhead` (breakpoint size)".

### CONSISTENCY-27
- **Severity:** low
- **Section:** §2.7 (icon sizes), §7.14 (thumb index), §7.18 (leader dial), §7.21 (switch loading)
- **Problem:** Two components use sizes that are not in their own component's size lists:
  - The thumb-index icon is 22 px Light. §2.7 allows 16, 20, 24 and 32 px, puts tabs at 24, and says Light only at 24.
  - The switch loading state uses a 12 px leader dial. §7.18 lists 32, 24 and 16 px.
- **Evidence:** §7.14: "Icon 22 (Light; Fill when active)". §2.7: "**Sizes:** 16 …, 20 …, 24 (bars, tabs), 32". §7.21: "knob replaced by a 12 px leader dial". §7.18: "32 px circle (24 inline, 16 in controls)".
- **Fix:** In §7.14, write "Icon 24 (Light; Fill when active)". In §7.18, write "32 px circle (24 inline, 16 in controls, 12 inside a switch knob)".

### CONSISTENCY-28
- **Severity:** low
- **Section:** §7.25 (avatar sizes) vs §7.13, §8.0.9, §8.5, §8.6
- **Problem:** Avatars are used at 28, 56 and 112 px, but the avatar size list is 20, 24, 32, 44, 96 and 144.
- **Evidence:** §7.13: "profile chip (28 px avatar + name". §8.5: "a 2-column grid of 112 px avatars". §8.6: "the 12 avatars at 56 px". §7.25: "Circles (sizes 20, 24, 32, 44, 96, 144)".
- **Fix:** In §7.25, write "sizes 20, 24, 28, 32, 44, 56, 96, 112, 144".

### CONSISTENCY-29
- **Severity:** low
- **Section:** §2.3 (radius.round allow-list) vs §8.22, §8.16.5, §7.21, §8.5
- **Problem:** The "only" list of round shapes has both an extra item and missing items:
  - It includes a phone scroll-to-top **dot**, but the only scroll-to-top control is a 40 px **square** (§8.22).
  - It omits the 40 px voice monogram circle, the radio's 20 px outer ring (only "radio dots" are listed) and the 144 px Add-profile circle.

  §2.3 says any other rounding "is a bug".
- **Evidence:** §2.3: "Only: avatars …, radio dots, the Listen play button, the leader-sweep dial, the 30-day streak ring, the scroll-to-top dot on phones". §8.22: "A floating `TOP` square button (40 px …)". §8.16.5: "a 40 px monogram circle". §7.21: "Radio | 20 px circle (round allowed)". §8.5: "a 144 px circle outlined 1 px `ink.45`".
- **Fix:** Replace the §2.3 list with: "avatars and their reading-now ring, the Add-profile circle, voice monogram circles, radios (ring and dot), the Listen play button, the leader and countdown dials, the 30-day streak ring". Drop "the scroll-to-top dot".

### CONSISTENCY-30
- **Severity:** low
- **Section:** §2.2.2 (grid rules) vs §7.8 (rails)
- **Problem:** §2.2.2 claims rails align posters with column starts, but that cannot hold:
  - Rail gaps (phone 8, tablet 12, desktop 12, wide 12, cinema 16) differ from the grid gutters (12, 16, 24, 24, 32).
  - 3 posters over 4 columns cannot sit on column starts.

  The two sections describe different rails.
- **Evidence:** §2.2.2: "A poster rail's visible count is chosen so posters align with column starts at rest (phone 3.2 posters: 3 posters span the 4 columns …)". §7.8: "Gap | phone 8 · tablet 12 · desktop 12 · wide 12 · cinema 16"; "Poster width | `(content width − (visible_floor × gap)) / visible`".
- **Fix:** Replace the §2.2.2 sentence with: "Rails start on the first content column and end at the grid margin; poster width and gap follow §7.8 and do not snap to column starts."

### CONSISTENCY-31
- **Severity:** low
- **Section:** §7.1 (button sizes) vs §8.8, §8.28, §8.16.5, §8.29
- **Problem:** `sm` buttons are restricted to "desktop dense rows only", but phones use them in several places:
  - the now-showing strip `split` sm on phones
  - the Index `Switch profile` (secondary sm)
  - the voice `Hear` (secondary sm)
  - the APK banner `Download update` (primary sm)
- **Evidence:** §7.1: "sm 32 (desktop dense rows only)". §8.28: "`Switch profile` (secondary sm)"; "`Download update` (primary sm)". §8.8: "a `split` primary at size sm (32 px)" in the phone strip.
- **Fix:** In §7.1, write "sm 32 visual height on every platform, hit area padded to 44 (iOS, web) / 48 (Android); for dense rows, slates, strips and banners".

### CONSISTENCY-32
- **Severity:** low
- **Section:** §14.2 (paper stocks) vs §2.1.6 (Issue stock)
- **Problem:** §14.2 says every stock reaches ink ≥ 13.4:1 and muted ≥ 5.8:1. The Issue stock is only guaranteed ≥ 13:1 and ≥ 5.5:1.
- **Evidence:** §14.2: "Paper stocks: every stock's ink ≥ 13.4:1 and muted ≥ 5.8:1 (§2.1.6)." §2.1.6: "Issue … until ≥ 13:1 … until 5.5:1".
- **Fix:** In §14.2, write "The six fixed stocks: ink ≥ 13.4:1, muted ≥ 5.8:1; the Issue stock: ink ≥ 13:1, muted ≥ 5.5:1 (§2.1.6)".

### CONSISTENCY-33
- **Severity:** low
- **Section:** §3.2 vs §3.5 (`type.credit`)
- **Problem:** §3.2 gives `type.credit` two weights and two colours (label wght 500 `ink.45`, value wght 700 `ink.100`). The name map carries only the 700 value, so the label has no token on either client.
- **Evidence:** §3.2: "`type.credit` | Archivo, wdth 70; label wght 500 `ink.45`, value wght 700 `ink.100`". §3.5: "`typeCredit` = `CineTextRole(family: 'Archivo', … wght: 700 …)`".
- **Fix:** Add a §3.5 row `type.credit.label` with the same sizes, lines, tracking +0.08em and cap 1.5, at wght 500: web `--mm-type-credit-label-*` + `type-credit-label`, Flutter `typeCreditLabel` = `CineTextRole(family: 'Archivo', italic: false, wght: 500, axes: {'wdth': 70}, sizes: [12, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.08, cap: 1.5)`.

### CONSISTENCY-34
- **Severity:** low
- **Section:** §12.4 (splash impression) vs §5 (event table), §6, §15.1
- **Problem:** The splash fires "haptic `impress`", but `impress` is an AHAP pattern name, not an event. §5 has no splash event. Every haptic routes through event names in `contract.json`, so this call has no name to route through.
- **Evidence:** §12.4: "1180 | The impression | … haptic `impress`; sound `reel` lands its hit if on". §5: "Event table (event names go into `design/contract.json`…)". The table has no splash row.
- **Fix:** Add the event `splash.impress` to §5 (iOS `impress`, Android `impress`, web —) and to the §15.1 haptics map as `"splash.impress": "ahap:impress"`. In §6's event map, set `splash.impress` → — (the `reel` cue carries the hit). In §12.4, write "haptic `splash.impress`".

### CONSISTENCY-35
- **Severity:** low
- **Section:** §7.11 (toast edge rule) vs §2.1.3
- **Problem:** Success toasts get a `spot` edge, but §2.1.3 makes `set` the success colour. The same toast table also gives `set` to "completion", as a separate category.
- **Evidence:** §7.11: "a 2 px left edge rule (`spot` for info and success, `proof` for errors, `set` for completion)". §2.1.3: "`color.set` | `#57D68D` | … Success: downloaded, synced, saved".
- **Fix:** In §7.11, write "(`spot` for info, `set` for success and completion, `proof` for errors)".

### CONSISTENCY-36
- **Severity:** low
- **Section:** §4.8 (recap countdown) vs §9.1.5
- **Problem:** The reduced-motion replacement for the recap countdown is worded two ways: a label "Continuing in 12 s" in §4.8, and the split button's folio `CH 143 · 12 S` in §9.1.5.
- **Evidence:** §4.8: "a static label "Continuing in 12 s" that updates once per second". §9.1.5: "Reduced motion: no draining rule; the folio label updates once per second" (folio reads `CH 143 · 12 S`).
- **Fix:** In §4.8, write "no draining rule; the split button's folio segment `CH 143 · 12 S` updates once per second".

### CONSISTENCY-37
- **Severity:** low
- **Section:** §8.15.5 (Type sheet defaults) vs §3.4 (per-face defaults)
- **Problem:** §3.4 gives Atkinson a 1.70 default leading and Archivo an 18 / 17 px default size. The Type sheet sets fixed defaults of 1.60 and 19 / 18 px for every face.
- **Evidence:** §3.4: "`atkinson` … 19 / 1.70 desktop, 18 / 1.70 phone"; "`archivo` … 18 / 1.60 desktop, 17 / 1.60 phone". §8.15.5: "Size | 14–40 px … | 19 desktop / 18 phone"; "Line spacing | 1.30–2.10 step 0.05 | 1.60".
- **Fix:** In §8.15.5, set the Default column for Size and Line spacing to "the face's default in §3.4 (Newsreader, Literata, Source Serif 19 / 18 px at 1.60; Atkinson 19 / 18 px at 1.70; Archivo 18 / 17 px at 1.60)".

### CONSISTENCY-38
- **Severity:** low
- **Section:** §8.14.7 (manga SLIDE) vs §8.15.4 (novel SLIDE)
- **Problem:** The same named page-turn option has different timings: 280 ms `settle` in the manga reader and 300 ms `set` in the novel reader. Neither value is a token.
- **Evidence:** §8.14.7: "`Slide` (… 280 ms `settle`…)". §8.15.4: "`SLIDE` (300 ms `set`, finger-tracked with `spring.release`)".
- **Fix:** Use 280 ms `ease.settle` for both. Add token `dur.pageturn` 280 ms (`--mm-dur-pageturn: 280ms`, `durPageturn`).

### CONSISTENCY-39
- **Severity:** low
- **Section:** §7.1 (`play` button) vs §8.16.3
- **Problem:** The Listen full player on phones uses a 56 px play button, a size §7.1 does not list.
- **Evidence:** §7.1: "`play` | Circle 64 px … | 64 (Listen full player), 36 (mini player)". §8.16.3: "Transport | … the 64 px round `play` … | same, 56 px play".
- **Fix:** In §7.1, write "64 (Listen full player, desktop), 56 (full player, phones), 36 (mini player)".

### CONSISTENCY-40
- **Severity:** low
- **Section:** §8.16.5 (voice pulse) vs §4.8 and §2.1.2
- **Problem:** The pulse band's opacity is ambiguous: the band is `spot.wash`, which already has 0.16 alpha, yet its "opacity follows … 0.08 … to 0.32". The reduced-motion value is 0.2 in §8.16.5 and "a static `spot.wash` band" (0.16) in §4.8.
- **Evidence:** §8.16.5: "a `spot.wash` highlighter band … its opacity follows the audio's RMS level (0.08 at silence to 0.32 at full level …)"; "Reduced motion: a static band at 0.2". §4.8: "a static `spot.wash` band while the sample plays".
- **Fix:** In §8.16.5, write "band colour `color.spot` with alpha = 0.08 + 0.24 × RMS (0–1)". Set reduced motion to "a static `color.spot` band at alpha 0.20" in both §8.16.5 and §4.8.

### CONSISTENCY-41
- **Severity:** low
- **Section:** §9.1.5 (recap background) vs §2.1.4 (`scrim.foot`)
- **Problem:** `scrim.foot` is defined with the end colour `ambient.tint`, but the recap uses "`scrim.foot` into black", which is a different gradient than the token.
- **Evidence:** §2.1.4: "`scrim.foot` | … | Eased stops, end colour `ambient.tint`". §9.1.5: "`scrim.foot` into black".
- **Fix:** Either use `scrim.foot` as defined (into `ambient.tint`), or add `scrim.foot.black`: the same 13 eased stops ending at `#000000`, with web `--mm-scrim-foot-black` and Flutter `scrimFootBlack`. Reference it in §9.1.5.

### CONSISTENCY-42
- **Severity:** low
- **Section:** §8.34 vs §12.6
- **Problem:** The screenshot set is called "Poster" in §8.34 and "Front pages" in §12.6 and §12.3.
- **Evidence:** §8.34: "the "Poster" screenshot set (§12.6)". §12.6: "### 12.6 Screenshot set ("Front pages")".
- **Fix:** In §8.34, write "the "Front pages" screenshot set (§12.6)".

### CONSISTENCY-43
- **Severity:** low
- **Section:** §15.2 and §15.11 (Embla scope), §15.3 vs §15.11 (`flutter_animate`)
- **Problem:** Two package-scope statements disagree with the rest of the file:
  1. Embla is limited to two pagers ("only"), but §11 also uses it for the onboarding steps and the Library Continue pager.
  2. §15.3 lists `flutter_animate` for "reveals", while the ledger and §10.1.6 say it is not used for the heading reveal.
- **Evidence:** §15.2: "`embla-carousel-react` 8.6.0 (the phone Also-in-this-issue pager and the Annual story pager only …)". §11: "Tonight "Also in this issue", onboarding steps …, Library continue pager | Pager | … | Embla pager". §15.3: "`flutter_animate` 4.5.2 (reveals, rack focus, flicker, flame)". §15.11: "Rack focus, flicker, flame (not the heading reveal, §10.1.6)".
- **Fix:** In §15.2 and §15.11, write "phone pagers: Also in this issue, Library Continue, onboarding steps, The Annual". In §15.3, write "`flutter_animate` 4.5.2 (rack focus, flicker, flame)".

### CONSISTENCY-44
- **Severity:** low
- **Section:** §2.1.3 vs §2.8.1 (token map)
- **Problem:** `color.note` is written as a token but is missing from the name map and the JSON, so no `--mm-color-note` or `colorNote` exists to reference.
- **Evidence:** §2.1.3: "`color.note` | `color.spot` + the kicker `NOTE`". The §2.8.1 table and the §15.1 JSON have no `note` entry.
- **Fix:** Add a §2.8.1 row: `color.note` | `#F4D03F` (alias of `color.spot`) | `--mm-color-note: var(--mm-color-spot)` | `--color-note` (`text-note`) | `colorNote` = `Color(0xFFF4D03F)`. Add `"note": "#F4D03F"` to the JSON.

### CONSISTENCY-45
- **Severity:** low
- **Section:** §2.1.4 and §2.8.3 (`scrim.vignette`)
- **Problem:** The web and Flutter vignettes are different shapes. CSS draws an ellipse 120 % of the width by 90 % of the height. Flutter's `RadialGradient(radius: 1.2)` is a circle of 1.2 × the shortest side, so on a 390 × 844 phone it is about 468 px round where CSS is 468 × 760 px.
- **Evidence:** §2.8.3: "`radial-gradient(120% 90% at 50% 40%, …)`" vs "`RadialGradient(center: Alignment(0, -0.2), radius: 1.2, stops: [.6, 1], …)`".
- **Fix:** Flutter: `RadialGradient(center: Alignment(0, -0.2), radius: 1.0, stops: [.6, 1], colors: […], transform: const CssEllipse(rx: 1.2, ry: 0.9))`. `CssEllipse` is a `GradientTransform` that scales x by `1.2 × w / s` and y by `0.9 × h / s` (s = shortest side) about the point (0.5 w, 0.4 h).

### CONSISTENCY-46
- **Severity:** low
- **Section:** §9.4.4 (sampling) vs §2.1.5
- **Problem:** The two sections give different page-selection rules for sampling: "the page under the reading line" in §2.1.5, and "the page occupying ≥ 50 % of the viewport" in §9.4.4.
- **Evidence:** §2.1.5: "When the page under the reading line changes, at most one sample every 600 ms". §9.4.4: "the page occupying ≥ 50 % of the viewport (paged: the current page; guided view: the current page)".
- **Fix:** In §9.4.4, write "the page under the reading line, 38 % from the top of the viewport (paged and guided view: the current page), at most one sample per `dur.sample.tint` (600 ms)". §2.1.5 keeps its wording.

### CONSISTENCY-47
- **Severity:** low
- **Section:** §8.15.4 ("One hand" preset) vs §14.6
- **Problem:** The "One hand" preset has zones smaller than the minimum in §14.6: a 20 % back strip and a 12 % menu band, against "at least 25 %".
- **Evidence:** §8.15.4: "One hand" (left 20 % back, top 12 % menu, rest forward)". §14.6: "The reader's tap zones are at least 25 % of the screen width."
- **Fix:** Change the preset to "left 25 % back, top 15 % menu, rest forward". Reword §14.6 to "at least 25 % of the width, or 15 % of the height for a full-width band".

### CONSISTENCY-48
- **Severity:** low
- **Section:** §4.6, §4.7, §7.17 vs §8.22, §8.7
- **Problem:** When data replaces a skeleton, the file says both "dissolve 160 ms" and "run **Set**". Some screens then do both, so the first-paint entrance is undefined whenever a skeleton was shown.
- **Evidence:** §4.7: "Data that arrives while a skeleton is flickering dissolves over 160 ms". §4.6: "**Only on first data paint.**" (Set). §8.22: "Data arrival dissolves the plates into posters (160 ms) and the grid runs **Set**". §8.7: "replaced by posters with **Set** as they arrive".
- **Fix:** Add to §4.6: "If a skeleton was shown (a wait over 120 ms), data dissolves in over 160 ms and does not run Set. If data arrives within 120 ms (no skeleton), it runs Set." Change §8.22 to "dissolves the plates into posters (160 ms)" and §8.7 to "replaced by posters with a 160 ms dissolve as they arrive".

### CONSISTENCY-49
- **Severity:** low
- **Section:** §8.8 (phone Also-in-this-issue pager)
- **Problem:** The pager geometry is contradictory. "86 % width with 12 px peek" cannot both hold: with `viewportFraction: 0.86` each neighbour shows 7 % (27 px at 390 px), not 12 px.
- **Evidence:** §8.8: "a horizontal pager of three Feature cards at 86 % width with 12 px peek (Embla on web, `PageView` with `viewportFraction: 0.86` in Flutter)".
- **Fix:** "cards 86 % of the viewport width, start-aligned on the 16 px margin, 12 px gap. Web: Embla `align: "start"`, slide `flex: 0 0 86%`, `gap: 12px`. Flutter: `PageView(viewportFraction: 0.86, padEnds: false)` with 6 px horizontal padding per page."

### CONSISTENCY-50
- **Severity:** low
- **Section:** §15.1 (token kinds)
- **Problem:** §15.1 says every value is one of five kinds, and "length" is a number in logical px. The file also holds z-indexes, which are unitless numbers and would be emitted as `10px` under the length rule. It also holds `font`, `type`, `grid`, `haptics` and `sounds` objects, which are none of the five kinds, and a curve given as the string `"linear"`. `build.mjs` "needs one rule per kind" and cannot classify these.
- **Evidence:** §15.1: "Every value has one of five kinds …: a **colour** …, a **length** (a number in logical px), a **curve** …, a **spring** …, and a **scalar**". JSON: `"z": { "page": 0, "sticky": 10, … }`, `"ease": { … "linear": "linear" }`, `"grid": { "phone": [4, 16, 12] … }`.
- **Fix:** Add "an **integer** (unitless: `z.*`)" as a sixth kind, and write `"linear": { "bezier": [0, 0, 1, 1] }`. State that `font`, `type`, `grid`, `haptics` and `sounds` are structured groups, each emitted by a dedicated rule, with the shapes shown in §2.8.2, §3.5, §5 and §6.
