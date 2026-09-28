# Cinematic DESIGN.md: judge of the internal-consistency audit

Input: `cinematic/verify/find-consistency.md` (50 findings). Method: for every finding I tried to refute it by grepping `cinematic/DESIGN.md` for the quoted text and for any other place that already settles the question, then checked the proposed fix against `inventory/00-decisions.md`, `stack-decision.md` and the rest of DESIGN.md. Contrast figures were recomputed with the WCAG 2.x relative-luminance formula (Python). Where the finder's fix was wrong, vague or offered two options, the fix below is rewritten; the rewritten fix is the one to apply.

Result: **49 confirmed, 1 refuted** (CONSISTENCY-18). Of the confirmed findings, 12 have a rewritten or amended fix (1, 2, 9, 10, 13, 15, 19, 26, 41, 47, 49, 50). Severities changed: 6, 17, 20 and 22 drop from medium to low.

---

## Verdicts

| ID | Verdict | Severity | Reason |
|---|---|---|---|
| 1 | Confirmed, fix rewritten | high | §7.19 (1 px outline, Archivo) and §7.24 (2 px border, Bodoni 900) both define the 16 and 20 px mark; the §2.7 glyph has no stated use. The finder's fix also changed the dialog border to 4 px, which nothing requires; that is dropped and the numeral sizes follow `type.micro`. |
| 2 | Confirmed, fix rewritten | high | Arithmetic checks out: 380 + 12 × 20 + 640 = 1260 > 1100 and > the 1180 impression; `max(dataReady, 900)` ends before the rule; 1180 + 320 = 1500 > 1400 (the phone's 240 ms dissolve also ends at 1420). The finder's fix adds two new tokens; the standard Letter set and Rule draw timings already fit the window, so the rewrite uses them and restates the duration rule so a slow probe holds instead of being "capped". |
| 3 | Confirmed | medium | §7.11 says `paper.0`; §2.1.1 and §2.4 say toasts are `paper.2`. `data-stock="raised"` and `CineStock.raised` exist in §2.1.1, so the fix is buildable. |
| 4 | Confirmed | medium | §7.15 "768–1279" against §1, §8.0.1 and §8.0.9 "768–1023". |
| 5 | Confirmed | medium | §4.3 Use column assigns wipes/iris to `turn` and rule slide to `set`; §4.5, §7.5, §7.12, §7.14 use `settle`. Lightbox close is a reverse match cut on `settle`. The rack in Stop the press is `turn` (§8.30.3) and the button impression is 80 ms `set` (§7.1), so the rewritten Use column is accurate. |
| 6 | Confirmed | low (was medium) | Flutter's `Curves.easeInOutSine` is `Cubic(0.445, 0.05, 0.55, 0.95)`, not `Cubic(0.37, 0, 0.63, 1)`. Only the §4.3 documentation row is wrong (build.mjs generates from the JSON bezier), and the visual difference on a 26 s drift is slight. |
| 7 | Confirmed | medium | §3.2 gives the web a single unitless line height (cover 0.93, others 1.0) while the table and Flutter use 36/32, 28/24 etc. Ratios in the fix recomputed and correct. |
| 8 | Confirmed | medium | Web `custom={graphemes(text).length}` counts spaces; Flutter filters them and uses `~/`. "Because you read Solo Leveling": 26 letters, web step 0.56 / 29 = 19.3 ms, Flutter 560 ~/ 25 = 22 ms. |
| 9 | Confirmed, fix amended | medium | §10.1.5 has `viewport={{ once: true }}` and a `seen` gate but no leave-viewport jump, no `replay` for covers (§10.1.1 "every mount") and no 60-grapheme fallback (§15.6). The finder's web fix mixed an imperative `animate()` on elements that variants also drive, which can be overridden by the running variant animation; the rewrite uses component state instead. |
| 10 | Confirmed, fix amended | medium | `(v * 6).floor()` on a 3340 ms controller gives 556.7 ms halves, and on/off ×3 ends "off", so the 160 ms fade is invisible. Amended: the web keyframe needs a per-keyframe `animation-timing-function: linear` for the fade, because the animation-level `steps(1)` would otherwise step it. |
| 11 | Confirmed | medium | 8 blades: 200 + 7 × 16 = 312, + 40, + 280 + 112 = 392 → 744 ms; §8.14.2 says 872 "on tablets and wider". Dip saving 744 − 440 = 304 ms checks out. |
| 12 | Confirmed | medium | §2.1.5 samples 256 px on the web and 64 × h on Flutter, with a resolution-dependent "highest S pixel" picker, while the vectors are all 16 × 16. Also found in §15.3 line "the 64 px sampler". |
| 13 | Confirmed, fix amended | medium | One process-wide iOS session is given three categories (§6 `.ambient`, §8.16.10 "stays speech", §9.4.2 "ambient" for a soundscape that must keep playing under narration). Amended: `flutter_soloud` (used for UI cues and voice samples) may set the category itself, so the fix requires a device check and a re-apply rather than asserting it never does. |
| 14 | Confirmed | medium | Recomputed: cyan 3.32, amber 3.16, emerald 3.71, ember 4.37, star 3.06, reader 4.38 against the "≥ 4.5:1 on every field" claim. New hexes recomputed: 4.54, 4.53, 4.60, 4.54, 4.58, 4.62, hue and saturation unchanged (HLS L only). |
| 15 | Confirmed, fix amended | medium | Eight raw colours used by components are absent from §2.8.1, `animate-caret-out` is defined nowhere, and the lint scope is undefined. Flutter alpha bytes recomputed (0xA3, 0x14, 0x0F, 0x38, 0xF5, 0xD9) and correct. Amended: the `@theme` entry needs its `@keyframes`, and the lint must accept `(--mm-*)` arbitrary values the contract itself uses (`duration-(--mm-dur-line)`, `bg-(--mm-scrim-modal)`). |
| 16 | Confirmed | medium | §11 "30 / 70 (guided): back / menu / next" against §9.4.3 "right 30 % next, left side previous" and "behave as in paged mode" (30 / 40 / 30 with a menu zone). |
| 17 | Confirmed | low (was medium) | §8.15.3 "fades 180 ms" matches no token and no §4.8 row; manga chrome is 240 in / 160 out. Cosmetic timing drift, so low. |
| 18 | **Refuted** | — | Already specified. §14.1 gives the general rule and a "rule of thumb for anything not in the table": slides (Set's 8 px rise, page-turn SLIDE) become a 150 ms opacity change, "countdowns become labels that update once per second" (the Listen dial), and "zooms … become an opacity change of 150–200 ms". Every case the finder lists is therefore determined. The proposed zoom row ("the scale jumps to its target at once") would contradict §14.1. |
| 19 | Confirmed, fix rewritten | medium | Three label sets for one field (§8.9, §8.17, §7.19), and `COMPLETED` collides with the publication-status badge. The rewrite ties each label to the stored enum (`unread, reading, completed, on_hold, plan_to_read, dropped`, inventory K8) and also fixes the §7.5 example slug line. |
| 20 | Confirmed | low (was medium) | §9.1.8 puts a `NOTE` kicker in `ink.45`; §2.1.3 and §7.23 define `NOTE` as spot. Two colours for one semantic kicker; low impact. |
| 21 | Confirmed | medium | Flutter `typeDropcap` has fixed `sizes: [72, 72, 84, 84]`, but the recap body is 20/32 (96 px drop cap) and the novel body is user-sized 14–40 px; the Flutter row also omits `opsz`. |
| 22 | Confirmed | low (was medium) | §7.9 names reader page actions a `[0.5, 0.92]` live-preview sheet; §8.14.13 says `[0.5]`. One array. |
| 23 | Confirmed | low | Seven scrolls, five durations; §8.30.1 and §8.20 give none for the settings jump and group jump. |
| 24 | Confirmed | low | §4.1 "0.7 × the entrance" is broken by Insert (160 vs 224), Rise (240 vs 252), Slate (200 vs 224), chrome (160 vs 168) and Lightbox close (320 vs 336). |
| 25 | Confirmed | low | 5200 ms toast hold matches no `dur.hold.toast*` token. |
| 26 | Confirmed, fix rewritten | low | Poster captions "`type.title` 14/20" and dialog titles "`type.subhead` 24/28" name sizes the roles do not have at every breakpoint. The finder offered two options; the rewrite picks the one that adds no role, and extends to two more instances of the same defect found while verifying (§7.11 toast text and §7.15 sidebar label "`type.ui` 15", but `type.ui` is 14 on desktop). |
| 27 | Confirmed | low | Thumb-index icon 22 against §2.7 sizes (24 for tabs); switch loading dial 12 against §7.18's 32/24/16. The switch knob is 16 × 16, so a 12 px dial fits. |
| 28 | Confirmed | low | 28 px (§7.13), 56 px (§8.6) and 112 px (§8.5) avatars are not in §7.25's size list. |
| 29 | Confirmed | low | §2.3 lists a scroll-to-top "dot" but §8.22 draws a 40 px square; the voice monogram circles (§8.16.5), radio ring (§7.21), Add-profile circle (§8.5) and 40 px countdown dial (§7.18) are round but unlisted. |
| 30 | Confirmed | low | Rail gaps (8/12/12/12/16) differ from gutters (12/16/24/24/32), and 3.2 posters over 4 columns cannot sit on column starts. |
| 31 | Confirmed | low | `sm` is "desktop dense rows only" but used on phones (§8.8 strip, §8.28 Index and APK banner, §8.16.5 `Hear`); `split` also lists no `sm` size although §8.8 uses one. |
| 32 | Confirmed | low | §14.2 bullet 4 claims every stock ≥ 13.4:1 / 5.8:1; the Issue stock is ≥ 13:1 / 5.5:1 (§2.1.6 and §14.2 bullet 2). |
| 33 | Confirmed | low | §3.2 gives `type.credit` a wght 500 label and wght 700 value; §3.5 emits only 700. |
| 34 | Confirmed | low | §12.4 fires "haptic `impress`", which is an AHAP pattern; §5 has no splash event and every haptic routes through an event name. |
| 35 | Confirmed | low | Success toasts get a `spot` edge though `color.set` is the success colour (§2.1.3). |
| 36 | Confirmed | low | §4.8 invents a separate label "Continuing in 12 s"; §9.1.5 keeps the folio `CH 143 · 12 S` counting. |
| 37 | Confirmed | low | §8.15.5 fixes 19/18 px at 1.60 for every face; §3.4 gives Atkinson 1.70 and Archivo 18/17. |
| 38 | Confirmed | low | Manga SLIDE 280 ms `settle`, novel SLIDE 300 ms `set`; neither is a token. |
| 39 | Confirmed | low | §8.16.3 phones use a 56 px `play`; §7.1 lists 64 and 36. |
| 40 | Confirmed | low | `spot.wash` already has alpha 0.16, yet its "opacity" runs 0.08–0.32; reduced motion is 0.2 in §8.16.5 and "static `spot.wash`" (0.16) in §4.8. |
| 41 | Confirmed, fix rewritten | low | `scrim.foot` ends at `ambient.tint`; §9.1.5 uses it "into black". The finder offered two options; only the new token works, because the recap page is `#000` (a tint end colour would leave a visible seam) and a web `--mm-scrim-foot` computed at the root cannot be re-pointed by overriding `--amb-tint` on a child. |
| 42 | Confirmed | low | "Poster" (§8.34) vs "Front pages" (§12.3, §12.6). |
| 43 | Confirmed | low | §15.2/§15.11 limit Embla to two pagers, but §11 also uses it for onboarding steps and Library Continue; §15.3 lists `flutter_animate` for "reveals" though §10.1.6 and §15.11 exclude the heading reveal. |
| 44 | Confirmed | low | `color.note` is named as a token in §2.1.3 but has no row in §2.8.1 and no JSON entry; `color.proof`, `color.set` and `color.info` all have rows. |
| 45 | Confirmed | low | CSS `radial-gradient(120% 90% …)` is an ellipse 1.2 w × 0.9 h; Flutter `RadialGradient(radius: 1.2)` is a circle of 1.2 × the shortest side. The `GradientTransform` fix is geometrically correct. |
| 46 | Confirmed | low | "page under the reading line" (§2.1.5) vs "page occupying ≥ 50 % of the viewport" (§9.4.4); the latter is undefined when several short pages share the viewport. |
| 47 | Confirmed, fix amended | low | "One hand" has a 20 % back strip against §14.6's 25 % minimum. The 12 % top band is full width and already large (≈ 100 px on an 844 px phone), so only the strip changes; §14.6 gains a height rule for bands. |
| 48 | Confirmed | low | §4.7/§7.17 dissolve data over a skeleton in 160 ms; §8.22 dissolves and also runs Set; §8.7 runs Set. The fix ties the choice to the existing 120 ms skeleton threshold. |
| 49 | Confirmed, fix rewritten | low | `viewportFraction: 0.86` (padEnds true) shows 7 % of each neighbour (27 px at 390 px), not "12 px peek". The finder's start-aligned fix was internally inconsistent (86 % of the viewport vs 86 % of the Embla container inside 16 px margins, and 6 px padding on a padEnds-false PageView does not produce a 16 px margin). The rewrite keeps PageView's default centred geometry on both clients. |
| 50 | Confirmed, fix amended | low | §15.1's five kinds cannot classify `z.*` (unitless, but "length" means px), `"linear"` (a string, not `{bezier}`), or the `font`, `type`, `grid`, `bp`, `haptics`, `sounds` groups. Amended: keep the `"linear"` literal (it already emits `linear` / `Curves.linear` in §2.8.4) instead of rewriting it as a bezier. |

---

## Confirmed

Final fixes, in the order to apply them. Section numbers refer to `cinematic/DESIGN.md`.

### CONSISTENCY-1 (high): one 18+ mark per size
- §7.24 "Mark", replace with: "`certificate-18` at 16 px (poster badges, rows, the Sources table, Discover credits) and 20 px (feature credits, the rating card, the picker's avatar marker) is the §7.19 badge: a 1 px `proof` outline and "18" in `proof` Archivo `wdth` 62 `wght` 800 at 10 px (16 px box) or 12 px (20 px box). At 160 px (the certificate dialog only) it has a 2 px `proof` border and "18" in Bodoni Moda Roman `wght` 900 at 88 px."
- §2.7, after `certificate-18`: "(the icon-slot form, for menu items and settings rows only; never drawn in place of the §7.19 badge)".
- §7.25 "a 20 px certificate" and §8.5 "the 20 px certificate": append "(the §7.19 badge)". §7.19 unchanged.

### CONSISTENCY-2 (high): splash timeline that fits its window
- §12.4 rows:
  - `252–1180` Wordmark letters: "**Letter set** (§10.1) at its standard timings: 640 ms per grapheme (blur 440), `scalar.stagger.letter` 24 ms, 13 graphemes, so the last letter starts at 540 and lands at 1180; the timeline start replaces `startDelay`."
  - `252–572` Monogram: fades out and scales 1.00 → 0.96 (`lift`) as the letters start.
  - `700–1180` Oxford rule: "**Rule draw** (480 ms `settle`), its first 12 % in `spot`".
  - `1180` The impression: unchanged (80 ms), but "haptic `splash.impress`" (see CONSISTENCY-34).
  - `1180–1400` Hand-off: "Desktop: the lockup flies to the sidebar head (shared element, 220 ms `turn`). Phone: the lockup dissolves over 220 ms as Tonight's headline starts typing."
- §12.4 duration rule, replace with: "The choreography runs 0–1180 ms regardless of the network. The 220 ms hand-off starts at `max(probeDone, 1180 ms)`, so the fastest cold start ends at 1400 ms (`dur.reel`); the reveal is never stretched. If the probe is still pending at 1180 ms the lockup holds after the impression, and after 2400 ms the 24 px leader dial and `CONNECTING` appear (§8.2)."
- §8.2 Pre-roll: replace "the reveal lasts `max(probe, 900 ms)` capped at 1400 ms. If the probe is still pending at 1400 ms the masthead holds" with "the reveal and hand-off follow §12.4's duration rule; if the probe is still pending at 1180 ms the masthead holds".
- No new tokens.

### CONSISTENCY-3 (medium): toast surface
§7.11 Surface: "`paper.2` band with a 1 px `rule.2` border (elevation level 2; its root carries `data-stock="raised"` / `CineStock.raised`, §2.1.1), a 2 px left edge rule (see CONSISTENCY-35)". Add "toast" to the list of raised-stock roots in §2.1.1.

### CONSISTENCY-4 (medium): spine range
§7.15 Width: "248 expanded; 72 collapsed (the *spine*). Auto-spine at 768–1023; expanded from 1024." (matches §1, §8.0.1, §8.0.9).

### CONSISTENCY-5 (medium): curve assignments
- §4.3 Use column:
  - `ease.settle`: "Every entrance, column-wipe blades (close and open), iris out, Rule slide".
  - `ease.lift`: "Every exit that is not a reversed match cut".
  - `ease.turn`: "Dissolves, match cuts in both directions (including the Lightbox open and close), iris close, the Stop-the-press rack, colour changes".
  - `ease.set`: "State changes inside a component (toggle knob, progress width, the 80 ms button impression)".
- §4.5 Lightbox row and §7.30 Dismiss: "close by button 320 ms `ease.turn` (a reverse match cut)".

### CONSISTENCY-6 (low): `ease.drift` in Flutter
§4.3 `ease.drift` Flutter column: `Cubic(0.37, 0, 0.63, 1)` (not `Curves.easeInOutSine`, which is `Cubic(0.445, 0.05, 0.55, 0.95)`).

### CONSISTENCY-7 (medium): web line heights for fluid roles
§3.2: replace "Line heights for fluid roles are unitless (cover 0.93, the others 1.0)" with "Fluid roles keep their `clamp()` sizes; `--mm-type-<role>-lh` is a unitless ratio redefined in each breakpoint media query from the table:" then

| Role | phone | tablet | desktop | wide |
|---|---|---|---|---|
| cover | 1.0 | 0.9375 | 0.955 | 0.933 |
| masthead | 1.0 | 1.0 | 0.944 | 0.955 |
| headline | 1.125 | 1.091 | 1.0 | 1.0 |
| section | 1.167 | 1.143 | 1.125 | 1.111 |
| numeral | 1.0 | 1.0 | 0.917 | 0.933 |

The `Measure` wrapper keeps the 4 px rounding. §3.5 names the same values for `--mm-type-<role>-lh`.

### CONSISTENCY-8 (medium): one letter-stagger formula
- §4.6 and §10.1.1: "`n` = graphemes excluding spaces".
- §10.1.5: `custom={graphemes(text).filter((g) => g !== " ").length}`.
- §10.1.6: `late final double _step = _n < 2 ? 0 : math.min(24.0, 560 / (_n - 1));`, `final start = 120.0 + _step * i++;`, controller `duration: Duration(milliseconds: (120 + _step * math.max(0, _n - 1) + 640).round())`.

### CONSISTENCY-9 (medium): reveal rules in both components
Add to §10.1.5 and §10.1.6:
1. **`replay`** prop (web `replay?: boolean`, Flutter `final bool replay` defaulting to false). When true, `seen` is neither read nor written. Cover, feature, book and recap titles pass `replay`. Web: `const once = !replay && seen.has(id)` and write `seen` only when `!replay`. Flutter: `late final bool _seenAtMount = !widget.replay && ref.read(seenHeadingsProvider).contains(widget.id);` and skip the provider update when `widget.replay`.
2. **Leaving mid-reveal** (web): drop `whileInView`/`viewport.once`; hold `const [phase, setPhase] = useState<"idle" | "run" | "done">(once ? "done" : "idle")`, `const half = useInView(ref, { amount: 0.5 })`, `const any = useInView(ref)` (both from `motion/react`). An effect sets `run` when `half && phase === "idle"` and `done` when `!any && phase === "run"`; `onAnimationComplete` sets `done`. The heading animates `animate={phase === "run" ? "show" : "hidden"}` and renders the static branch (the full string, kerning off) when `phase === "done"`, so an interrupted reveal jumps to its end state. `seen.add(id)` runs whenever `done` is reached, unless `replay`. Flutter already does this (`visible == 0`).
3. **Long headings**: when the letter count exceeds 60 (§15.6), both components split by word instead of grapheme with the same 640 / 440 ms timings and the same stagger formula over the word count.

### CONSISTENCY-10 (medium): caret blink that ends visible
- §10.2.1 Caret and §10.2.3: "when done it blinks off, on, off, on, off, on in 530 ms halves (3180 ms), then fades 1 → 0 over 160 ms".
- Web `caret-out` (3340 ms, `steps(1)`, `forwards`): `0% {opacity:0} 15.87% {opacity:1} 31.74% {opacity:0} 47.60% {opacity:1} 63.47% {opacity:0} 79.34% {opacity:1} 95.21% {opacity:1; animation-timing-function: linear} 100% {opacity:0}`. The per-keyframe `linear` is required; otherwise `steps(1)` would step the fade.
- §10.2.4 Flutter: `final ms = _blink.value * 3340; final o = ms < 3180 ? ((ms ~/ 530).isOdd ? 1.0 : 0.0) : 1 - (ms - 3180) / 160;` driving `Opacity(opacity: o)`.

### CONSISTENCY-11 (medium): tablet column wipe
- §4.5 Column wipe: add "tablet (8 blades) 312 + 40 + 392 = 744 ms".
- §8.14.2: "route duration = (200 + (c − 1) × 16) + 40 + (280 + (c − 1) × 16) ms for c blades: 616 (4, phones), 744 (8, tablets and web 600–1023), 872 (12, desktop)"; add "Dip reaches the first page 304 ms sooner on tablets".
- §8.30.3 Outgoing sequence: "tablets: blades close 80–392".

### CONSISTENCY-12 (medium): identical sampler input
Sample 16 × 16 on both clients. Flutter: `ResizeImage(provider, width: 16, height: 16, policy: ResizeImagePolicy.exact)`, then `toByteData(format: ui.ImageByteFormat.rawRgba)` (256 pixels) in the `compute()` isolate. Web unchanged (`drawImage(bitmap, 0, 0, 16, 16)`), with `ctx.imageSmoothingQuality = "medium"`. Replace "64 px" / "64 × h" with "16 × 16" in §2.1.5 (table row and picker text), §9.4.4, §15.3 (`page_tint.dart`, "the 16 × 16 sampler"), §15.6 and Appendix A graft row 1. The vectors in `design/tint-vectors.json` now match both clients' real input; small differences between the browser's and Skia's downscale filters are accepted.

### CONSISTENCY-13 (medium): one iOS audio session
Add to §9.4.2 and reference it from §6, §8.16.10 and §14.9: "The iOS `AVAudioSession` is process-wide, so only `mobile/lib/skins/skin_audio.dart` configures `AudioSession.instance` (`audio_session`). While narration is active: `AudioSessionConfiguration.speech()`; the soundscape keeps playing through its `just_audio` player at 30 % player volume, and UI cues are already suppressed. Otherwise: `AudioSessionConfiguration(avAudioSessionCategory: AVAudioSessionCategory.ambient, avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers)`, so the silent switch mutes UI cues and the soundscape. It reconfigures on narration start and stop. `flutter_soloud` is initialised after the first configuration; the iPhone device pass (§15.8) checks that `SoLoud.instance.init()` leaves the category unchanged, and if it does not, `skin_audio.dart` re-applies the configuration right after init." Replace "(ambient category on iOS …)" in §9.4.2 with a reference to this rule, and §8.16.10's "stays speech" with "is `speech()` while narration is active (§9.4.2)".

### CONSISTENCY-14 (medium): avatar fields that reach 4.5:1
Darken six fields in HLS lightness only (hue and saturation unchanged). Update §7.25, §2.8.1 and the Flutter values:

| Key | Old | New | `ink.100` contrast | Flutter |
|---|---|---|---|---|
| cyan | `#1F8FA8` (3.32) | `#1A778C` | 4.54 | `Color(0xFF1A778C)` |
| amber | `#B87A12` (3.16) | `#95630F` | 4.53 | `Color(0xFF95630F)` |
| emerald | `#1E8C60` (3.71) | `#1A7B54` | 4.60 | `Color(0xFF1A7B54)` |
| ember | `#C24724` (4.37) | `#BE4523` | 4.54 | `Color(0xFFBE4523)` |
| star | `#A8850F` (3.06) | `#85690C` | 4.58 | `Color(0xFF85690C)` |
| reader | `#187C7C` (4.38) | `#177878` | 4.62 | `Color(0xFF177878)` |

### CONSISTENCY-15 (medium): tokens, keyframes and lint scope
1. Add to §2.8.1 and the §15.1 JSON:

   | Token | Value | Flutter | Used by |
   |---|---|---|---|
   | `color.onart` | `rgba(0,0,0,0.64)` | `Color(0xA3000000)` | `on-art` buttons (§7.1, §7.2, §9.2.4), the dialogue-search subtitle band (§8.24) |
   | `color.hairline.art` | `rgba(243,240,232,0.08)` | `Color(0x14F3F0E8)` | poster inner hairline (§7.7) |
   | `color.galley` | `rgba(243,240,232,0.06)` | `Color(0x0FF3F0E8)` | skeleton text bars (§7.17) |
   | `color.leader.sweep` | `rgba(243,240,232,0.22)` | `Color(0x38F3F0E8)` | leader dial sweep (§7.18) |
   | `color.lightbox` | `rgba(0,0,0,0.96)` | `Color(0xF5000000)` | Lightbox barrier (§7.30) |
   | `color.matte.guided` | `rgba(0,0,0,0.85)` | `Color(0xD9000000)` | guided-view matte (§9.4.3) |
   | `color.warmth` | `#FF8A00` | `Color(0xFFFF8A00)` | reader warmth layer (§8.14.8) |

   Replace the raw values in those sections with the token names.
2. In `frontend/src/skins/cinematic/motion.css`, an `@theme` block with `--animate-caret-out: caret-out 3340ms steps(1) forwards;` and the `@keyframes caret-out` of CONSISTENCY-10 inside it.
3. §2.8, define the lint scope: `design/lint-utilities.mjs` checks only `bg-*`, `text-*` (colour and size), `border-*` colour, `outline-*` colour, `fill-*`, `stroke-*`, `font-*`, `tracking-*`, `leading-*`, `rounded-*`, `blur-*`, `ease-*`, `duration-*`, `z-*` and `animate-*`, and fails on names not in §2.8, §3.5 or the `@theme` block above, and on arbitrary colour values (`[#…]`, `[rgb…]`). Arbitrary `(--mm-*)` references are allowed. Layout, position and size utilities, including arbitrary em lengths, are out of scope.

### CONSISTENCY-16 (medium): guided-view tap zones
§9.4.3 Moving: "tap the right 30 % / swipe left / `→` / `j` → next panel; the left 30 % → previous; the centre 40 % toggles the chrome (mirrored for RTL)". §11 Tap zones: "30 / 40 / 30 (manga paged and guided view), 25 / 50 / 25 (novel)".

### CONSISTENCY-17 (low): novel chrome timing
§8.15.3 heading: "Chrome (tap anywhere toggles; fades in 240 ms `settle`, out 160 ms `lift`; no slide, because the bars are solid)". §4.8 row: "Reader chrome in / out (manga and novel)".

### CONSISTENCY-19 (medium): one reading-status vocabulary
One label per stored value (`reading_status`, inventory K8) everywhere: `unread` → `NOT STARTED`, `reading` → `READING`, `on_hold` → `ON HOLD`, `plan_to_read` → `PLAN TO READ` (badges may shorten this one to `PLAN`), `completed` → `DONE`, `dropped` → `DROPPED`. `COMPLETED` is reserved for publication status. Apply to: §8.9 slug line `ALL · READING · NOT STARTED · DONE · ON HOLD · PLAN TO READ · DROPPED` (keys `1`–`7` in that order) and its phone Filters sheet; §8.17 select `READING · PLAN TO READ · ON HOLD · DONE · DROPPED · NOT STARTED`; §7.19 badge row `READING`, `ON HOLD`, `PLAN`, `DROPPED`, `DONE`; §7.5's example slug line `ALL · READING · NOT STARTED · DONE · ★ FAVOURITES`.

### CONSISTENCY-20 (low): the NOTE kicker is always spot
§9.1.8 unavailable: "a `NOTE` kicker in `spot` (`color.note`) with the reason in `type.caption` `ink.60`; never `proof`, never an error rule". §7.8 inherits it. The recap slate's `RECAP UNAVAILABLE` kicker stays `ink.45` (it is not a `NOTE`).

### CONSISTENCY-21 (medium): drop cap follows its paragraph
§3.2 and §3.5: `type.dropcap` = Bodoni Moda Roman `wght` 800, size = 3 × the line height of the paragraph it opens, `opsz` = min(that size, 96). Web: `--mm-type-dropcap-size: calc(var(--para-lh) * 3)`, where the novel body, the recap and any other host set `--para-lh` on the paragraph. Flutter: replace the fixed `typeDropcap` with `CineType.dropcap(double paragraphLineHeightPx)` returning Bodoni Moda 800 at `3 × lh` with `FontVariation('opsz', math.min(3 * lh, 96))`, tracking −0.02 em; remove its `sizes` and `lines`.

### CONSISTENCY-22 (low): page-actions detents
§8.14.13: "A `[0.5, 0.92]` sheet (phone) or menu (desktop)".

### CONSISTENCY-23 (low): scroll durations
§4.8 row: "560 / 320 / 400 / 400 / 300 / 400 / 400 ms smooth scrolls". §8.30.1 settings search jump and §8.20 group jump: "scrolls 400 ms `settle`".

### CONSISTENCY-24 (low): exit durations
§4.1 principle 4: "Entrances use `settle`. Exits use `lift` and are shorter than their entrances; each exit's duration is the one given in §4.5." §8.0.4 Back: "the forward move's exit as given in §4.5 (Page 224 ms); a reversed match cut runs 336 ms `turn`".

### CONSISTENCY-25 (low): stale-bookmark toast hold
§8.14.11: "(`dur.hold.toast`, 3600 ms)".

### CONSISTENCY-26 (low): role sizes written as the role
- §7.7 Below: "`type.title` on 1 line (2 at text scale ≥ 1.3)", no explicit size (15/20 phone and tablet, 16/20 desktop and wide).
- §7.10 Title: "`type.subhead` (Bodoni Moda)", no explicit size.
- Same class, found while verifying: §7.11 Text "`type.ui` `ink.100`" and §7.15 Items label "`type.ui` `ink.60`" (drop "15"; `type.ui` is 14/20 on desktop).

### CONSISTENCY-27 (low): icon and dial sizes
§7.14 Cell: "Icon 24 (Light; Fill when active)". §7.18 Leader dial: "32 px circle (24 inline, 16 in controls, 12 inside a switch knob)".

### CONSISTENCY-28 (low): avatar size list
§7.25: "Circles (sizes 20, 24, 28, 32, 44, 56, 96, 112, 144)".

### CONSISTENCY-29 (low): round-shape allow-list
§2.3 `radius.round` Use: "Only: avatars and their reading-now ring, the Add-profile circle, voice monogram circles, radios (ring and dot), the Listen play button, the leader and countdown dials, the 30-day streak ring". Drop "the scroll-to-top dot on phones".

### CONSISTENCY-30 (low): rails and the grid
§2.2.2 first rule: "**Everything else snaps to columns.** Rails start on the first content column and end at the grid margin; poster width and gap follow §7.8 and do not snap to column starts."

### CONSISTENCY-31 (low): small buttons
§7.1 `primary` Size: "sm 32 visual height on every platform, hit area padded to 44 (iOS, web) / 48 (Android); for dense rows, slates, strips and banners". `split` Size: "lg 56 / md 48 / sm 32 (the now-showing strip)".

### CONSISTENCY-32 (low): stock contrast claim
§14.2 last bullet: "The six fixed stocks: ink ≥ 13.4:1, muted ≥ 5.8:1; the Issue stock: ink ≥ 13:1, muted ≥ 5.5:1 (§2.1.6)."

### CONSISTENCY-33 (low): credit label role
§3.5, new row `type.credit.label`: Archivo `wdth` 70, `wght` 500, UPPER, 12/16 · 12/16 · 12/16 · 13/16, +0.08 em, cap 1.5; web `--mm-type-credit-label-size|lh|tracking` + `type-credit-label`; Flutter `typeCreditLabel` = `CineTextRole(family: 'Archivo', italic: false, wght: 500, axes: {'wdth': 70}, sizes: [12, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.08, cap: 1.5)`. §3.2 `type.credit` row: "value wght 700 (`type.credit`), label wght 500 (`type.credit.label`)".

### CONSISTENCY-34 (low): splash haptic event
§5 event table: new row `splash.impress` | "The cold-start lockup's impression (§12.4)" | `impress` | `impress` | —. §15.1 `haptics`: `"splash.impress": "ahap:impress"`. §6 event map: `splash.impress` → — (the `reel` cue carries the hit). §12.4: "haptic `splash.impress`".

### CONSISTENCY-35 (low): toast edge colours
§7.11: "a 2 px left edge rule (`spot` for info, `set` for success and completion, `proof` for errors)".

### CONSISTENCY-36 (low): recap countdown under reduced motion
§4.8 Recap countdown, Reduced: "no draining rule; the split button's folio segment `CH 143 · 12 S` updates once per second".

### CONSISTENCY-37 (low): per-face type defaults
§8.15.5 Default column for Size and Line spacing: "the face's default in §3.4 (Newsreader, Literata, Source Serif: 19 desktop / 18 phone at 1.60; Atkinson: 19 / 18 at 1.70; Archivo: 18 / 17 at 1.60)".

### CONSISTENCY-38 (low): one SLIDE page turn
§8.14.7 and §8.15.4: `SLIDE` = 280 ms `ease.settle`, finger releases `spring.release`. New token `dur.pageturn` 280 ms (`--mm-dur-pageturn: 280ms`, `dur.pageturn = 0.28`, `durPageturn` = `Duration(milliseconds: 280)`) in §4.2, §2.8.4 and the §15.1 JSON.

### CONSISTENCY-39 (low): play button sizes
§7.1 `play` Size: "64 (Listen full player, desktop and tablet), 56 (full player, phones), 36 (mini player)".

### CONSISTENCY-40 (low): voice pulse band
§8.16.5: "a highlighter band in `color.spot` at alpha = 0.08 + 0.24 × RMS (RMS 0–1; attack 80 ms, release 240 ms)". Reduced motion in §8.16.5 and §4.8: "a static `color.spot` band at alpha 0.20 while the sample plays".

### CONSISTENCY-41 (low): recap scrim
Add `scrim.foot.black` to §2.1.4 and §2.8.3: the same 13 eased stops as `scrim.foot`, ending at `#000000`, over the bottom 60 % of its band; web `--mm-scrim-foot-black` (a complete `background-image` value) with `@utility scrim-foot-black`; Flutter `scrimFootBlack` = `LinearGradient(begin: Alignment(0, -0.2), end: Alignment.bottomCenter, stops: kScrimStops, colors: [for (final a in kScrimAlpha) Color(0xFF000000).withValues(alpha: a)])`. §9.1.5: "`scrim.foot.black` over the band's lower edge".

### CONSISTENCY-42 (low): screenshot set name
§8.34: "the "Front pages" screenshot set (§12.6)".

### CONSISTENCY-43 (low): package scopes
§15.2 and §15.11 Embla: "phone pagers: Also in this issue, Library Continue, onboarding steps, The Annual". §15.3: "`flutter_animate` 4.5.2 (rack focus, flicker, flame)".

### CONSISTENCY-44 (low): `color.note` token
§2.8.1 new row: `color.note` | `#F4D03F` (alias of `color.spot`) | `--mm-color-note: var(--mm-color-spot)` | `--color-note` (`text-note`) | `colorNote` = `Color(0xFFF4D03F)`. §15.1 JSON: `"note": "#F4D03F"` under `color`.

### CONSISTENCY-45 (low): vignette shape parity
§2.8.3 Flutter `scrimVignette`: `RadialGradient(center: Alignment(0, -0.2), radius: 1.0, stops: [.6, 1], colors: [Color(0x00000000), Color(0x73000000)], transform: const CssEllipse(rx: 1.2, ry: 0.9))`, where `CssEllipse` is a `GradientTransform` whose `transform(bounds)` returns translate(0.5 w, 0.4 h) · scale(1.2 × w / s, 0.9 × h / s) · translate(−0.5 w, −0.4 h), with s = the shortest side. This reproduces the CSS 1.2 w × 0.9 h ellipse.

### CONSISTENCY-46 (low): which page is sampled
§9.4.4 Sampling: "the page under the reading line, 38 % from the top of the viewport (paged and guided view: the current page), at most one sample per `dur.sample.tint` (600 ms)". §2.1.5 keeps its wording.

### CONSISTENCY-47 (low): One-hand preset and minimum zones
§8.15.4: "One hand" (left 25 % back, top 12 % menu across the full width, rest forward)". §14.6: "The reader's tap zones are at least 25 % of the screen width; a full-width band is at least 12 % of the screen height."

### CONSISTENCY-48 (low): skeleton hand-off
§4.6, add: "If a skeleton was shown (a wait over 120 ms, §7.17), the data dissolves in over 160 ms and does not run Set. If data arrives within 120 ms (no skeleton), it runs Set." §8.22: "Data arrival dissolves the plates into posters (160 ms)." §8.7: "replaced by posters with a 160 ms dissolve as they arrive".

### CONSISTENCY-49 (low): pager geometry
§8.8 item 3: "a horizontal pager of three Feature cards, each 86 % of the viewport width, centred, 12 px apart, so about 21 px of each neighbour shows at 390 px. Flutter: `PageView(controller: PageController(viewportFraction: 0.86))` (default `padEnds`), each page with 6 px horizontal padding. Web: Embla `align: "center"` with its viewport spanning the full screen width (outside the grid margins, like the PageView), slides `flex: 0 0 86%` with `padding-inline: 6px`." §8.9's Library Continue pager ("a pager of cuttings at 86 %") uses the same geometry.

### CONSISTENCY-50 (low): token kinds
§15.1: "Every value has one of six kinds": add "an **integer** (a unitless number: `z.*`, emitted as `--mm-z-page: 0` and a Dart `int`)"; the **curve** kind also accepts the literal `"linear"` (emitted as `linear` / `Curves.linear`, as §2.8.4 already shows). Add: "`font`, `type`, `grid`, `bp`, `rule`, `haptics`, `sounds` and `soundEvents` are structured groups, each emitted by its own rule with the shapes shown in §2.8.2, §3.5, §5 and §6."

---

## Refuted

- **CONSISTENCY-18** (reduced-motion rows for Set, the Listen countdown dial, page-turn SLIDE and zoom). §14.1 already determines each case: its general rule turns slides and zooms into a 150–200 ms opacity change and countdowns into labels that update once per second, and its "rule of thumb for anything not in the table" covers named moves missing from §4.8. The proposed zoom row ("the scale jumps to its target at once") would contradict §14.1.
