# Recheck round 3: Glass accessibility, privacy and safety lens (`judge-a11y.md`, section "Confirmed")

Method: I re-checked all 31 confirmed findings against the live `glass/DESIGN.md` (4,612 lines, last modified 00:22:00 UTC; unchanged from the start of this check to the end). The judge refuted A11Y-7, A11Y-10 and A11Y-27, so they are not checked.

For the four findings that round 2 left open (A11Y-2, 3, 4, 20), I read every section that round 3 of `fixed-a11y.md` says it edited, in full: §2.1.2, the §2.1.7 `Lb` table, §7.1 Disabled, §7.4, §7.10 Desktop, §7.15 Dock, §7.16, §7.23, §8.7 step 4, §8.16.5, §9.2.2, §14.2 and §15.8. I checked each edit against the fix that `recheck-a11y-2.md` asked for. For the other 27 findings, I re-ran an anchor grep for every element of the judge's fix (98 anchors, each count ≥ 1). I then grepped for old values that should be gone, and for every other place that repeats a changed rule or value: the sidebar's `Lb` premise, the `768–1179` range, the exception list, `label4`, "not for me", and opacity dimming.

I recomputed every contrast figure that round 3 added with the WCAG 2.x formula, compositing in sRGB in the judge's order: backdrop, then scrim (`dimSheet` 0.28, `dimModal` 0.48, `dimContext` 0.55, `edgeSoft` 0.72), then `dimLegibility`, then the tier fill (T2 `rgba(255,255,255,0.07)`, T3 0.06, T4 `rgba(28,28,34,0.52)`, T5 `rgba(22,22,28,0.60)`), then the `rgba(0,0,0,0.60)` backing disc where there is one. Section numbers are authoritative. Line numbers refer to the 4,612-line state.

Result: **31 resolved, 0 unresolved.**

Round 3 made every edit that `recheck-a11y-2.md` asked for, and every figure it added reproduces exactly:

- **A11Y-2:** the sidebar `Lb` row is split into docked and overlay.
- **A11Y-3:** the stale "one exception" phrase is gone. The exception list and the glyph mapping are added, the Audiobook panel and the offline wifi-slash glyphs are on discs, and §15.8 has the new asserts.
- **A11Y-4:** `label4` is allowed only as disabled text, in §2.1.2, §7.1, §7.23 and §14.2.
- **A11Y-20:** the "not for me" bubble dims by role, and §14.2 has the disabled-control clause.

None of these edits contradicts another rule. The observations below are wording gaps or issues outside the judge's fixes. None of them fails a confirmed finding.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count |
|---|---|
| `iris300` "accent text on glass" | 0 |
| toast "no close button" / "swipe or wait" | 0 / 0 |
| `g600` "meta text at 15 px" | 0 |
| `label3` "13 px and larger" / "13 px and up" | 0 / 0 |
| Single-key "without a modifier" | 0 |
| download `mature` flag "at download time" | 0 |
| reader chrome "fixed sizes" | 0 |
| "Read this card", "Auto-advance stories" | 0 / 0 |
| `mature=1`; `mm-img-v1`, `mm-downloads-v1`, `x-mm-mature` | 0; 0 / 0 / 0 |
| unknown backdrop `Lb = 0.5` | 0 |
| `dimClear` "never inside the glass" | 0 |
| input chip "hit 32", sidebar items "40 tall" | 0 / 0 |
| `overflow-wrap: anywhere` | 0 |
| toast wrap "from text scale AX1" | 0 |
| `mm.boot.a11y` "two extra keys" | 0 |
| Sources offline "rows dim to 70 %" | 0 |
| a 0.62 fill on a cover overlay | 0 (the 9 hits of `0.62` are the §2.4.1 content-twin fill, which rule 1 replaces with 0.86 on covers, the §7.9 rail arrows, the §7.34 swipe pills, a haptic intensity and the stack-overview scale) |
| "the one exception" to the backing-disc rule (A11Y-3, round 2 residual) | **0** (§7.15 l. 1795 now reads "one of the §2.1.2 plateau exceptions to the backing-disc rule") |
| "`label2`, `label3` and `label4` are not used there" (A11Y-4, round 2 residual) | **0** (§2.1.2 l. 76 now reads "`label2` and `label3` are not used there, and `label4` appears only as disabled text") |
| onboarding bubble "dims to 50 %" (A11Y-20, round 2 residual) | **0** (the one "dims to 50 %" left is the §8.14.9 page image under the dialogue overlay, which is an image, not text) |
| sidebar "the field term alone" without the docked qualifier (A11Y-2, round 2 residual) | **0** (both hits of "field term alone" are the docked row l. 186 and §2.1.2's contrast text; §7.16 Width rule states the overlay reads `max(field term, lItems)`) |

## Round-3 figures, recomputed

| Claim in DESIGN.md | Where | Recomputed |
|---|---|---|
| Overlay sidebar `onGlass` on T3 over `#FFFFFF` under `dimSheet` at dim 0.64: 7.52; at the floor 0.22: 2.65 | §2.1.7 l. 187, §15.8 | 7.52 / 2.65 |
| Overlay sidebar `streak` ring at 80 % on the disc inside T3 under `dimSheet` at 0.22: 3.57; bare at 0.64: 2.83 | §2.1.2, §15.8 | 3.57 / 2.83 (the other overlay marks on the disc at 0.22: `bloom` 5.85, `warning` 6.28) |
| Friend orb rings inside T4 under `dimSheet` over white at 0.22: `iris300` 3.92, `bloom` 4.04 | §2.1.2, §15.8 | 3.92 / 4.04 (the 560 px windows can snap to T5, which is darker: 4.79 / 4.95, so T4 is the floor) |
| Wordmark `iris400` over the capped field (a 0.475-luminance blob at 36 %, T3, dim 0.22): 4.38 | §2.1.2, §15.8 | 4.38 |
| Audiobook panel on the disc inside T4 over white at 0.22: `danger` 4.61, `success` 7.82; bare 1.68 / 2.85 | §2.1.2, §8.16.5, §15.8 | 4.61 / 7.82; 1.68 / 2.85. These leave out the `dimSheet` that §7.10 now puts behind panels, so they are the conservative bound: with `dimSheet` the disc figures are 5.29 / 8.98 and the bare ones 2.52 / 4.28, and bare `danger` still fails |
| Offline `warning` wifi-slash on the disc on the `glassRegular` search field at 0.64: 8.32 (bare 3.29) | `fixed-a11y.md`; §7.4 states no figure | 8.32 / 3.29 on T3 (on T2: 8.25 / 3.21) |

---

## Per finding

| ID | Verdict | Evidence |
|---|---|---|
| A11Y-1 | Resolved | §2.4.2 `glassClear` Dim cell ("`dimLegibility` inside the glass, as every tier (§2.1.7) … `dimClear` beneath the media region when the media's `Lb > 0.45`, unchanged"). The hero and image-viewer rows read `lMax`. §15.8 **Clear glass** has 5.72:1 and 4.56:1. |
| A11Y-2 | **Resolved** (round 2 residual fixed) | §2.1.7 now has two rows. "Sidebar, docked (expanded at ≥ 1180 px, or collapsed at 76 px)" reads the field term alone, with content at 304 px or at 100 px beside the rail, which matches §7.8 `sidebarOffset` 304/100 (l. 1704). "Sidebar as the 768–1179 px overlay" reads `max(field term, lItems under its rect)`, at 7.52:1 over white and 2.65:1 at the floor (l. 187). The menus row names "their desktop panels and windows, §7.10" and the palette. §7.16 **Width rule** (l. 1833) repeats the overlay reading and puts the dots and goal ring on the disc. §9.2.2 says the goal ring takes no disc on the plateau or the docked sidebar, and a disc 8 px wider than the ring in the overlay (l. 3309). §2.1.2 limits the field exception to the **docked** sidebar and gives the overlay figures. §15.8 has an **Overlay sidebar** bullet with both cases. The `768–1179` range matches §8.0.1 Frames (tablet 768–1023 and desktop 1024–1179 both start with the collapsed rail) and `threshold.sidebarCollapse` 1180 (l. 878). The rest of the judge's fix is still in place: `palette.lMax` and `pTop`/`pMid`/`pBottom` (§2.1.8), the reader rows, the "Every other surface over a reader page" row, the unknown backdrop at `Lb = 1.0`, `dimFor(lMax = 1.0) == 0.64`, T2 at 5.05:1 and T4 at 4.55:1. |
| A11Y-3 | **Resolved** (round 2 residuals fixed) | (1) §7.15 Dock: "one of the §2.1.2 plateau exceptions to the backing-disc rule". "One exception" now counts 0. (2) §2.1.2 has a **Glyph mapping for screen specs**: any state-coloured glyph, dot or ring on T2–T5 glass sits on the disc even if the spec does not say so, and stays bare on black, slabs, `solid1` and `solid2`. §7.10 **Desktop** (l. 1731) states the `dimSheet` backdrop and points to both mappings. (2a) §8.16.5 job rows (l. 2863): on the 440 px desktop panel the `success` and `danger` glyphs are on the disc (7.82:1 and 4.61:1) and the clock is `onGlass`. On phones the sheet is `large`, so it is `solid1` and the glyphs stay bare. (2b) The exception list gains the friend orbs' `bloom` rings and the selected orb's 3 px `iris300` ring on the `medium` recommend sheet and on the 560 px recommend and friend windows (on phones the friend sheet is `large`, so `solid1`). (2c) §7.4 offline: "a `warning` wifi-slash on the backing disc, §2.1.2" (l. 1657), and the same for the §7.30 status capsule (l. 1999). (2d) The wordmark's `iris400` M's are listed as a logotype exempt under 1.4.3, at 4.38:1. §14.2 (l. 4014) names every exception group and the glyph mapping. §15.8 (l. 4384) asserts the orb rings, the wordmark guard, the Audiobook glyphs and the negative case (a bare state glyph on T2–T5 outside the exceptions fails the gate). The round-1 and round-2 parts are unchanged: §2.1.3 `iris300` role; §7.1 Selected (4.95:1), Destructive and Error; §7.2; §7.23 `danger` (4.61:1) and check (5.86:1); §8.14.2 bookmark (6.14:1) and download states (`iris500` 4.59:1); §7.25 gate glyph on the 40 px disc (5.98:1); §7.16 active item on the disc. |
| A11Y-4 | **Resolved** (round 2 residual fixed) | §2.1.2 (l. 76): "`label2` and `label3` are not used there, and `label4` appears only as disabled text (§7.1 **Disabled**, including the alert button twins; §7.23 disabled rows), which WCAG 1.4.3 exempts". §7.1 Disabled (l. 1605) and §7.23 (l. 1907) cite the allowance in matching words ("the one use of `label4` on glass"), and so does §14.2 (l. 4014). The other `label4` uses, §7.13 disabled tabs (l. 1781) and §7.17 disabled rows (l. 1844), are disabled text too, so the rule covers them. The §15.8 T4/T5 negative case names only `label2`/`label3`, so it does not conflict. The rest of the fix is unchanged: `wellOnGlass` (`rgba(0,0,0,0.35)`, `Color(0x59000000)`, `label2` inside at 5.20:1), the **Mapping for screen specs**, and the palette and full-player figures (9.23:1, 8.36:1). |
| A11Y-5 | Resolved | §9.2.4: mature sources, logos and genres are never drawn, the next eligible item takes the place, and empty cards are omitted. §9.2.3: "Every card except 11". §14.11 has the share-card line and the PNG source-string check. |
| A11Y-6 | Resolved | §8.0.8 step 5a (the `resolve_series_rating` order and `source.mature`), step 3 `{item, gateOpen}`, step 4 `{ type: "gate-closed" }` (l. 2335). §7.25 cites "steps 5a and 6". §14.11 has item (10). |
| A11Y-7 | Refuted by the judge | Not checked. |
| A11Y-8 | Resolved | §8.0.8 step 4 leaves `offlineCacheName(scope)` and the Flutter blob store untouched. Step 6 refreshes the resolved `rating`. §8.9 has `mm-novel-text-u{user}p{profile}` and the Flutter join. |
| A11Y-9 | Resolved | §8.22 has "For everyone on this device" and the reset alert body word for word. |
| A11Y-10 | Refuted by the judge | Not checked. |
| A11Y-11 | Resolved | §7 intro: heights are minimums (`min-h-8`, `ConstrainedBox(minHeight:)`). §7.12 toast wrap "from `f ≥ 1.6`". |
| A11Y-12 | Resolved (MOBILE-7's 1.3× clamp, accepted in round 1) | §3.3 rules 4 and 5, §9.2.3 reflowing column, §3.7 `wrappedNumeral`, §14.7. |
| A11Y-13 | Resolved (equivalent mechanism, accepted in round 1) | §3.7 `GlassText`; §10.1 `Semantics(header: true)` on both paths, with word or CJK-grapheme units. |
| A11Y-14 | Resolved | §4.11 `accessibleNavigation` through `glassAssistiveProvider`; **Screen reader mode** and `data-sr="on"`; §15.10 G4 "three extra keys". |
| A11Y-15 | Resolved | §7.12 close button and `onDismiss`, the `aria-label="Notifications"` region, `alt+n`, `mod+z` for 60 s. |
| A11Y-16 | Resolved | §8.0.6 and §14.4: printable characters, with or without Shift. |
| A11Y-17 | Resolved | All eight widget semantics (carousel, `role="meter"`, jump bar, split button, transport strings, soundscape, "Step 3 of 7", avatar group) and the six polite live regions are present. |
| A11Y-18 | Resolved | §7.8 and §7.20 put everything on the 0.86 backing (`mature` 5.35:1). §8.17 bell and star, §7.7 play orb. No cover overlay names a 0.62 fill. |
| A11Y-19 | Resolved | §2.1.8 **Text over the brighter fields**; §14.2; §15.8 **Ambient field** (`#B7B7B7`). |
| A11Y-20 | **Resolved** (round 2 residual fixed) | §8.7 step 4 (l. 2491): the long-pressed bubble "shrinks to 0.8 × and its label turns `label2` with a strike-through (`onGlass` at `wght` 460 with the strike-through where the bubble is glass …); it is dimmed by role, never by opacity (§14.2), and stays a button". The §11 row (l. 3879) and the semantics ("Horror, not for me") do not mention dimming. §14.2 (l. 4015) adds "not for me" to the by-role states and "Only disabled controls (not activatable, `aria-disabled`; exempt from contrast) may dim to 40 %", which closes round 2's O1. The judge's five sites and §8.10 are unchanged: TOC read rows at 4.93:1, "Last updated 2 h ago", and §8.16.2 inactive sentences in `label2`, 6.08:1 on `solid2`, which reproduces. |
| A11Y-21 | Resolved | §7.5 has a 44 × 44 hit (48 on Android) and hit padding; §7.16 items are 44 tall (48); §8.9; §14.6 "means 44". |
| A11Y-22 | Resolved | §9.2.3 pause/play is always visible (l. 3350); §14.1; §11 row (l. 3877). |
| A11Y-23 | Resolved | §4.11 `glassTinted` becomes solid `#5B4AD1`, pressed `#4A3CB0`; `hcBorder` around the discs. |
| A11Y-24 | Resolved (as in round 1) | §9.3.5 "posters only, with no progress lines"; §9.3.1 never shows whether a letter was added. |
| A11Y-25 | Resolved | All 14 moves are present by name (the five that already existed under Count pop, Count-up, Quick type, Orb breathe and Queued ring). |
| A11Y-26 | Resolved | §2.4.1 **Focus rings are never masked**, §2.6 `foregroundPainter`, §2.2 `requestFocusCallback`. |
| A11Y-27 | Refuted by the judge | Not checked. |
| A11Y-28 | Resolved | §7.15 Minimise: the dock never minimises with a screen reader on; the tab nodes stay, hidden with `clip-path`. |
| A11Y-29 | Resolved | §7.15 **Non-gesture paths** ("Hide for this session"), §7.30 capsule close button, §11 rows. |
| A11Y-30 | Resolved | WEB-9 thresholds (`holdClickSlop` and the others) and "visible for everyone". |
| A11Y-31 | Resolved | §7.1 `role="alert"` and `assertive: true`; §7.27 WCAG 1.4.13. |
| A11Y-32 | Resolved | §8.14.2 and §7.21: 0.50 track with the 0.60 outline; the thumb has a 1.5 px `#000000` ring. |
| A11Y-33 | Resolved | §7.26 glyph colour per preset, `color.avatar.<preset>.glyph`, §15.8 samples at 30/50/70 % (3.58:1 minimums). |
| A11Y-34 | Resolved | §2.1.1 `g600` is non-text only; §2.1.2 `label3` at any size; §14.2 and §15.8 define large text as 24 px, or 18.66 px at `wght` ≥ 700. |

---

## What each unresolved finding still needs

Nothing. No confirmed finding is open.

---

## Observations (not blocking)

These came up in the contradiction sweep. None of them reverses a confirmed fix or fails a judge figure. N1 to N4 are wording gaps next to the round-3 edits. N5 and N6 predate the fixes and fall outside the 31 findings, so the main session should route them.

- **N1 (A11Y-3, wordmark in the overlay sidebar).** §2.1.2 files the wordmark's `iris400` M's under "Exceptions (no disc, because their backdrop is capped …)", at 4.38:1 over the capped field. But the 280 px panel that carries the wordmark is also the 768–1179 px overlay, whose backdrop is not capped. There it measures 3.53:1 over white under `dimSheet` once the overlay's `lItems` estimate lands (dim 0.64), and 1.24:1 at the floor dim. Nothing fails, because the logotype exemption holds everywhere. However, the §15.8 guard checks only the capped field. A clause such as "(in the overlay, 3.53:1 over white at dim 0.64; the guard asserts both)" would make the stated reason and the guard cover both states.
- **N2 (A11Y-3, Circle orb pickers).** The exception covers orb rings on "the `medium` recommend sheet and the 560 px recommend and friend windows". §9.3.3's `collection-share` sheet is also `medium` T4 over `dimSheet` with "Circle members as orb toggles", which is the same pattern, but the exception does not name it. Under the glyph mapping its rings take the disc, while the identical rings on the recommend sheet do not. Both pass, and the spec does not contradict itself, but the two render differently. Name "every Circle orb picker on a sheet or window (§9.3.3, §9.3.4, §9.3.5)" in the exception, or drop that exception and let the mapping disc all of them.
- **N3 (A11Y-4 and A11Y-20, disabled text on T4/T5).** §2.1.2's mapping says "Text that a spec dims by opacity inside such a surface uses `onGlass` at `wght` 460 instead". §14.2's new sentence lets disabled controls dim to 40 %, and §7.26 orbs are "disabled (40 %)" inside the T4 recommend sheet ("{name} isn't taking recommendations"). A builder gets two instructions for a disabled orb's name there, and the mapping's version would erase the disabled cue. Adding "(disabled controls excepted: they keep their 40 % or `label4`, §14.2)" to the mapping sentence settles it. Disabled text is exempt from contrast, so this is wording only.
- **N4 (A11Y-20, §8.12 offline chapter rows).** §8.12 States (l. 2581) says "the rest dimmed with 'Needs a connection'" but does not say the rows are not activatable. §14.2's new clause allows opacity dimming only for disabled controls (`aria-disabled`). §8.14.8 (l. 2698) states it in full ("every other row at 40 % … and not activatable") and calls these "the §8.12 chapter-section states". Copying "at 40 %, not activatable (`aria-disabled`)" into §8.12 would make it self-contained.
- **N5 (outside the confirmed findings: reaction picker glyphs on glass).** §9.3.2 and the §2.7 icon row (l. 493) draw the reactions you did not choose in `label2` inside the picker's T2 glass bubbles. The bubbles sit over the reader page (the §2.1.7 row reads `p*`), so the dim reaches 0.64 over white, where a `label2` glyph measures **2.97:1**, below 3:1. `onGlass` measures 5.05:1. This is an alpha glyph on glass, against §2.1.2's base rule ("every glyph on glass is `onGlass`"). Your chosen reaction is "`bloom` on a `bloomWash` disc", which measures 2.53:1 inside T2 over white at 0.64. By its wording ("even if the spec does not say so") the glyph mapping puts it on the 0.60 backing disc instead (7.68:1), but §9.3.2 still names the other disc. Fix: "others in `label2` on black and slabs, `onGlass` inside the picker's glass bubbles; your reaction in `bloom` on the backing disc inside the bubbles, on `bloomWash` elsewhere".
- **N6 (A11Y-3 rule scope, wording).** §2.1.2's first sentence says "A state colour … appears on glass only as a glyph or ring drawn on a backing disc", and ends with "No other state mark on glass goes without a disc". Read literally, this also covers colour fills on glass that the spec rightly keeps: the Selected wash (part of A11Y-3's own fix), `glassTinted`, the switch's on track, and slider and progress fills. The round-3 glyph mapping is scoped correctly ("glyph, dot or ring"). Using the same words in the first sentence ("A state-coloured glyph, dot or ring …") would remove the over-reach. A related case: the §7.15 accessory's 2 px progress line has no colour stated. If it takes §7.19's Hairline (`iris500` at 80 %), it measures 2.49:1 over the bottom plateau on white (3.08:1 at full `iris500`).
- **N7 (A11Y-2, wording).** §7.16 Geometry (l. 1818) still says "content scrolls beneath it (the page's content column starts at 304 px)". §2.1.7's docked row says "nothing scrolls under a docked sidebar". The parenthetical makes the meaning clear (content scrolls beside the fixed panel, not under it), and §8.8 confirms "content column beside the sidebar" with rails inset by the screen margin. Still, "beneath" is the one place that repeats the sidebar premise in words that contradict it.
- **Carried from earlier rounds, still open:** O2 (§15.8's exception bullet opens "over `#FFFFFF` at dim 0.22" but lists field cases over a blob; the §2.1.2 header "each is asserted … over white at the floor dim" has the same slip, and now also covers the wordmark, whose reason is the logotype, not the backdrop). O3 (the phone search field above the keyboard is off the plateau, so the §2.1.7 worked case does not hold for it). O5 (`machine` is not in the disc rule's colour list; the "Previously" sparkle is 3.59:1 on T2 at 0.64). O8 (`{ type: "gate-closed" }` is in §8.0.8 step 4, l. 2335, but not in §15.2's service-worker protocol). O9 (the §2.4.2 `solid1` row, l. 385, still says "Reduce Transparency everywhere", while §4.11 exempts `glassTinted`).
