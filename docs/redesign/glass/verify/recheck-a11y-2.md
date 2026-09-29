# Recheck round 2: Glass accessibility, privacy and safety lens (`judge-a11y.md`, section "Confirmed")

Method: I re-checked all 31 confirmed findings against the live `glass/DESIGN.md` (4,611 lines, last modified 00:13:05 UTC). A11Y-7, A11Y-10 and A11Y-27 were refuted by the judge and are not checked. For the six findings that round 1 left open (A11Y-3, 4, 11, 14, 18, 20), I read each section that round 2 of `fixed-a11y.md` edited in full. For the other 25, I re-ran the anchor greps for every element of the judge's fix, because other lenses kept editing the file after round 1 (WEB-2's sidebar overlay, the STACK-6 sheet route, the main session's round 4). I then grepped for old values that should be gone and for every other place that repeats a changed rule or value.

Every contrast figure that round 2 added, and every figure behind a residual below, was recomputed with the WCAG 2.x formula. Compositing is in sRGB, in the judge's order: backdrop, then scrim (`dimSheet` 0.28, `dimModal` 0.48, `dimContext` 0.55, `edgeSoft` 0.72), then `dimLegibility`, then the tier fill (T2 `rgba(255,255,255,0.07)`, T3 0.06, T4 `rgba(28,28,34,0.52)`, T5 `rgba(22,22,28,0.60)`), then the backing disc `rgba(0,0,0,0.60)` where there is one. Section numbers are authoritative. Line numbers refer to the 4,611-line state.

Result: **27 resolved, 4 unresolved** (A11Y-2, A11Y-3, A11Y-4 and A11Y-20).

Round 2 applied all six of its edits exactly as `recheck-a11y-1.md` asked, and every figure it added reproduces. A11Y-11, A11Y-14 and A11Y-18 are now resolved. Four findings are open:

- **A11Y-3:** it keeps one stale phrase ("the one exception", §7.15). The new "No other state mark on glass goes without a disc" is also contradicted by undisced state marks that the exception list does not name. One of these fails: the desktop Audiobook panel's `danger` glyph measures 1.68:1 inside T4 at the floor dim.
- **A11Y-4:** it keeps a `label4` conflict. §2.1.2 bans `label4` inside T4/T5, but disabled menu rows (§7.23) and disabled alert buttons (§7.1) still use it.
- **A11Y-20:** it keeps one activatable element that is dimmed by opacity: the onboarding genre bubble's "not for me" state (§8.7).
- **A11Y-2 is reopened.** WEB-2 added a 768–1179 px overlay sidebar that covers content, but §2.1.7 still gives the sidebar "the field term alone", because "nothing scrolls under the sidebar". Over a white cover this puts the sidebar labels at 2.65:1.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count |
|---|---|
| `iris300` "accent text on glass" | 0 |
| toast "no close button" / "swipe or wait" | 0 / 0 |
| `g600` "meta text at 15 px" | 0 |
| `label3` "13 px and larger" / "13 px and up" | 0 / 0 |
| Single-key "every binding without a modifier" | 0 |
| download `mature` flag "at download time" | 0 |
| reader chrome "fixed sizes" | 0 |
| "Read this card", "Auto-advance stories" | 0 / 0 |
| purge of "`mature=1`" entries; `mm-img-v1`, `mm-downloads-v1`, `x-mm-mature` | 0; 0 / 0 / 0 |
| unknown backdrop `Lb = 0.5` | 0 |
| `dimClear` "never inside the glass" | 0 |
| input chip "hit 32", sidebar items "40 tall" | 0 / 0 |
| `overflow-wrap: anywhere` | 0 |
| toast wrap "from text scale AX1" (A11Y-11) | 0 (the two `AX1` hits are the §3.3 table row and rule 1's own mapping "`f ≥ 1.6` (AX1, Android 1.8)") |
| `mm.boot.a11y` "two extra keys" (A11Y-14) | 0 (§15.10 G4 now "three extra keys (`solid`, `contrast`, `sr`)", l. 4420; §8.0.8 "Glass reads all five", l. 2329) |
| Sources offline "rows dim to 70 %" (A11Y-20) | 0 |
| desktop poster bell and star on the 0.62 twin (A11Y-18) | 0 |
| palette `caption1` `label3` footer and group labels, player book title `label2` (A11Y-4) | 0 / 0 |
| "the one exception" to the backing-disc rule (A11Y-3) | **1** (§7.15, l. 1794) |
| `label4` inside T4/T5 glass (A11Y-4) | **2** (§7.23 disabled rows, l. 1906; §7.1 Disabled, l. 1604, which also covers alert button twins) |

## Round-2 figures, recomputed

| Claim in DESIGN.md | Recomputed |
|---|---|
| Gate glyph `mature` on the 40 px disc inside T4 under `dimModal`, dim 0.22, over white: 5.98 (3.53 without the disc) | 5.98 / 3.53 |
| Plateau exceptions: dock `iris400` 4.11 (T3); lowest `streak` at 80 % on the bare plateau, 3.07 | 4.11; T2 3.99, T3 bloom 5.19, streak80 T3 3.23, bare 3.07 |
| Field exceptions over a `#B7B7B7` blob at 36 %, T2 and T3: lowest `streak` at 80 % on T2, 3.31 | 3.31 (`danger` 3.34, `iris400` 4.24, `warning` 5.75, `bloom` 5.36) |
| Recommend orbs' `bloom` in T2 under `dimContext`: 3.09 | 3.09 |
| Palette `onGlass` on T4 under `dimModal` at 0.22: 9.23; `label3` 3.64 | 9.23; 3.64 (`label2` 4.65) |
| Full player `onGlass` on T5 under `dimSheet` at 0.22: 8.36; `label2` 4.32 | 8.36; 4.32 |
| Cover backing 0.86: followed bell `iris400` 6.54, star `streakCore` 10.81, play orb `label1` 13.96 (was 2.18 on the 0.62 twin) | 6.54, 10.81, 13.96 (0.62 twin: 2.18) |
| Wrapped frame `label2` over its 24 % field: 6.64 | 6.63 |

---

## Per finding

| ID | Verdict | Evidence |
|---|---|---|
| A11Y-1 | Resolved | §2.4.2 `glassClear` Dim cell ("`dimLegibility` inside the glass, as every tier … `dimClear` beneath the media region when the media's `Lb > 0.45`, unchanged"); hero and image-viewer rows read `lMax`; §15.8 **Clear glass** 5.72:1 and 4.56:1. Unchanged since round 1. |
| A11Y-2 | **Unresolved** (reopened: cross-lens contradiction, failing) | Every element of the judge's fix is still in place: `palette.lMax` and the `pTop`/`pMid`/`pBottom` p95 samples (§2.1.8), the reader rows and the "Every other surface over a reader page" row, menus, popovers, partial sheets and now the command palette reading `max(field term, lItems)`, unknown `Lb = 1.0`, and §15.8 `dimFor(lMax = 1.0) == 0.64` with the T2 5.05:1 and T4 4.55:1 cases. **Now contradicted:** §2.1.7 still gives the sidebar "The field term alone (nothing scrolls under the sidebar, whose content column starts at 304 px)" (l. 186). But §7.16 **Width rule**, added by WEB-2 after the judge wrote "the sidebar keeps the field term", says: "From 768 to 1179 px it starts collapsed. `mod+b` or the expand button opens the 280 px panel as an **overlay** over the content, with `dimSheet` behind it" (l. 1832). In that state covers do sit under the sidebar, and at 768–1179 px the content column starts at 100 px (§7.8 `sidebarOffset`). The overlay is a `glassRegular` (T3) panel. With the field term alone the dim stays at 0.22, so over a white cover under `dimSheet`, `onGlass` sidebar labels measure **2.65:1**. The same overlay also removes the "capped backdrop" premise of the §2.1.2 exception for the sidebar's badge dots and goal ring (see A11Y-3). |
| A11Y-3 | **Unresolved** (one stale phrase, plus undisced marks outside the exception list, one failing) | The round-2 fix is in: §2.1.2 gives the 8 px-wider disc rule (40 px behind the gate's 32 px glyph), the three exception groups with their reasons and lowest figures, and "No other state mark on glass goes without a disc" (l. 76). §7.25 puts the gate glyph on a 40 px disc (5.98:1, l. 1947). §14.2 names the exceptions (l. 4013). §15.8 asserts every exception and the gate disc (l. 4383). The round-1 parts are all still in place (§2.1.3 `iris300` role; §7.1, §7.2, §7.23, §8.14.2 discs; §7.16 active item on the disc). **Still contradicting:** (1) §7.15 Dock says the active glyph is "the one exception to the backing-disc rule of §2.1.2" (l. 1794), while §2.1.2 now lists several. (2) These state marks sit on glass with no disc and are not in the exception list, against "No other state mark on glass goes without a disc": (a) the desktop Audiobook panel (§7.10 puts `audiobook` in the 440 px `glassThick` panel list; §8.16.5 job rows, l. 2862) draws "Done (`success` droplet)" and "Failed (`danger`)" glyphs bare. Inside T4 over white at the floor dim 0.22 (the judge's own T4 disc case) they measure **1.68:1** (`danger`, fails 3:1) and **2.85:1** (`success`, fails). Nothing maps spec glyphs onto the disc when a sheet renders as a T4/T5 panel or window, as the new text mapping does for labels. (b) Friend orbs' `bloom` rings (§7.26, l. 1957) and the selected orb's 3 px `iris300` ring sit on the `medium` recommend sheet (T4, §9.3.4 menu path, l. 3420) and on the 560 px recommend and friend windows (§9.3.5, l. 3427). They pass (T4 under `dimSheet` at 0.22 over white: `bloom` 4.04:1, `iris300` 3.92:1), but they are not listed. (c) §7.4 Search, offline state: "a `warning` wifi-slash replaces the magnifier" (l. 1656) on the `glassRegular` search field (phone bottom field, desktop Search-screen capsule), with no disc: 3.29:1 at dim 0.64 over white. (d) §7.16 and §12: the sidebar wordmark's "two M's in `iris400`" (l. 1818, 3895) is iris *text* on sidebar glass, against "It is never text". It is a logotype, which WCAG 1.4.3 exempts; it measures 4.38:1 over the capped field. |
| A11Y-4 | **Unresolved** (`label4` residual) | The round-2 fix is in. §2.1.2 has the **Mapping for screen specs** sentence (`label2`/`label3` render `onGlass` at the same role size on T4/T5 bodies, opacity-dimmed text becomes `onGlass` `wght` 460, alpha labels only on `solid1`/`solid2`, and the Wrapped frame is excluded by name). §7.10 **Desktop** points to it (l. 1730). The §2.1.7 row now names the palette. §7.28 footer, group labels (600) and subtitles are `onGlass` (9.23:1). §8.16.2 titles are `onGlass` (8.36:1), and the desktop-window sentences are `onGlass` 420 / 700. §8.25.14 licence version and text are `onGlass` on the desktop window. The §8.29 shortcuts secondary combos are `onGlass` 460 with no opacity. The §7.1 aborted-hold helper is `onGlass` inside alerts. §15.8 has the **T4/T5 bodies** bullet with its negative case (l. 4385). **Still contradicting:** §2.1.2 says that inside T4 and T5 "`label2`, `label3` and `label4` are not used there" (l. 76), and the mapping maps only `label2` and `label3`. But §7.23 menus (`glassThick`, T4) give "disabled (`label4`, skipped)" for rows (l. 1906), and §7.1 **Disabled** gives "label `label4`" (l. 1604) to every button, including the alert button twins inside T4 (§7.11). A builder gets two opposite instructions for a disabled menu row. Disabled text is exempt from WCAG 1.4.3, so this is a wording contradiction, not a contrast failure. |
| A11Y-5 | Resolved | §9.2.4 mature sources, logos and genres are never drawn, the next eligible item takes the place, empty cards are omitted, and card 11 is never shared; §9.2.3 "Every card except 11"; §14.11 share-card line and the PNG source-string check. |
| A11Y-6 | Resolved | §8.0.8 step 5a (holders, `resolve_series_rating` order, `source.mature`, stored and refreshed `rating`, online no-op); step 3 `{item, gateOpen}`; step 4 `{ type: "gate-closed" }` (l. 2334); §7.25 "steps 5a and 6"; §14.11 item (10). |
| A11Y-7 | Refuted by the judge | Not checked. |
| A11Y-8 | Resolved | §8.0.8 step 4 (`mm-pages-{RUNTIME_VERSION}` dropped; `offlineCacheName(scope)` and the Flutter blob store never touched); step 6 refreshes the resolved `rating`; §8.9 `mm-novel-text-u{user}p{profile}`, and the Flutter join deletes rows only when no profile references them. |
| A11Y-9 | Resolved | §8.22 **Whose data each action touches**: "For everyone on this device", the reset alert body verbatim, no admin restriction, eviction only when every holding profile has read. |
| A11Y-10 | Refuted by the judge | Not checked. |
| A11Y-11 | Resolved | §7.12 now reads "from `f ≥ 1.6` (§3.3 rule 1) it wraps to as many lines as needed, radius 22" (l. 1764), which matches §3.3 rule 1 and §14.7. The §7 intro minimum-height rule (`min-h-8`, `min-h-6`, `min-h-11`, `ConstrainedBox(minHeight:)`) is unchanged. |
| A11Y-12 | Resolved (MOBILE-7's 1.3× clamp, as accepted in round 1) | §3.3 rules 4 and 5, §9.2.3 reflowing column, §3.7 `wrappedNumeral`, §14.7. |
| A11Y-13 | Resolved (equivalent mechanism, as in round 1) | §3.7 `GlassText`; §10.1 `Semantics(header: true)` on both paths, word or CJK-grapheme units, `withClampedTextScaling`; web CJK units without a `.word` wrapper. |
| A11Y-14 | Resolved | §15.10 G4 now says "Glass's three extra keys (`solid`, `contrast`, `sr`)" (l. 4420), which matches §8.0.8 `{legible, motion, solid, contrast, sr}` and "Glass reads all five; Cinematic reads `legible` and `motion`" (l. 2329). The §4.11 signal row, the Screen reader mode switch and the 30 s keyboard rule are unchanged. |
| A11Y-15 | Resolved | §7.12 close button and `onDismiss`, 10 s Undo, the `alt+n` region, Esc, and `mod+z` for 60 s; §8.0.6 rows. |
| A11Y-16 | Resolved | §8.0.6 and §14.4: printable characters with or without Shift. |
| A11Y-17 | Resolved | All eight widget semantics and the six polite live regions are still present (anchor counts ≥ 1 each). |
| A11Y-18 | Resolved | §8.17 Desktop: the hover bell and star are "32 px content-twin buttons on the cover-overlay backing (§7.8: a `rgba(0,0,0,0.86)` disc …)", followed bell 6.54:1, star 10.81:1 (l. 2886). §7.7 History tile play orb is on the 0.86 backing, 13.96:1 (l. 1695). §2.4.1 rule 1: "twins drawn on a cover use the cover-overlay backing `rgba(0,0,0,0.86)` instead of the fill below" (l. 356), so the §7.8 peek capsule, also a twin on the poster, follows it too. §15.8 **Cover overlays** gains both pairs. No other cover overlay names the 0.62 fill. |
| A11Y-19 | Resolved | §2.1.8 **Text over the brighter fields**; §14.2; §15.8 **Ambient field**. |
| A11Y-20 | **Unresolved** (one new residual) | Round 2 fixed §8.10 as asked: "rows keep their roles (nothing is dimmed by opacity, §14.2), a `caption1` `warning` 'Needs a connection' line replaces each row's description, and tapping a row opens the catalogue's offline lens". "No longer installed" rows are at full strength with only Unpin activatable (l. 2545). The judge's five sites (§8.21, §8.13, §8.16.2, §8.17, §9.2.1) are unchanged. **Still contradicting** §14.2's "Nothing activatable or readable is dimmed by opacity" (l. 4014) and the finding's own rule: §8.7 onboarding step 4, the genre field, where a long-pressed bubble "shrinks to 0.8 ×, dims to 50 % with a struck-through label (not for me …)" (l. 2490). The bubble stays a `role="button"` that Space, tap and the custom actions keep changing, so it is activatable and its label is readable. |
| A11Y-21 | Resolved | §7.5, §7.16, §8.9, §7.21 and §8.14.2 hit strips; §14.6. |
| A11Y-22 | Resolved | §9.2.3 pause always visible; §14.1; §11 row. |
| A11Y-23 | Resolved | §4.11 `glassTinted` → solid `iris700` (6.28:1), pressed `#4A3CB0` (8.19:1); `hcBorder` around discs. |
| A11Y-24 | Resolved (as in round 1) | §9.3.5 "posters only, with no progress lines"; §9.3.1 "never whether it was added". |
| A11Y-25 | Resolved | All 14 motion rows are present by name (Speaking orb pulse … Queued ring). |
| A11Y-26 | Resolved | §2.4.1 unmasked focus rings (`aria-hidden` layer), §2.6 `foregroundPainter`, §2.2 `requestFocusCallback` bands. |
| A11Y-27 | Refuted by the judge | Not checked. |
| A11Y-28 | Resolved | §7.15 Minimise (never with a screen reader; tab nodes kept, never `display: none`). |
| A11Y-29 | Resolved | §7.15 **Non-gesture paths**, §7.30 capsule close button, §11 rows. |
| A11Y-30 | Resolved | WEB-9 thresholds (`holdStart`, `holdClickSlop`, `holdConfirm`) and "visible for everyone". |
| A11Y-31 | Resolved | §7.1 assertive region, `assertive: true`; §7.27 WCAG 1.4.13. |
| A11Y-32 | Resolved | §8.14.2 and §7.21: 0.50 track with the 0.60 outline, white thumb with a 1.5 px black ring. |
| A11Y-33 | Resolved | §7.26 glyph colour per preset, §2.8.1 `color.avatar.<preset>.glyph`, §15.8 30/50/70 % samples. |
| A11Y-34 | Resolved | §2.1.1 `g600` non-text only; §2.1.2 `label3` at any size; §14.2 and §15.8 large text = 24 px, or 18.66 px at `wght` ≥ 700. |

---

## What each unresolved finding still needs

- **A11Y-2.** In §2.1.7, split the Sidebar row: "Sidebar, docked (expanded at ≥ 1180 px, or collapsed at 76 px): the field term alone (nothing scrolls under it). Sidebar as the 768–1179 px overlay (§7.16 **Width rule**): `max(field term, lItems under its rect)`, like menus and partial sheets." Then the §2.1.2 field exception covers only the docked sidebar. In overlay mode its `bloom` and `warning` dots and its goal ring take the backing disc: at dim 0.64 `bloom` bare measures 4.45:1 and `warning` 4.78:1, but the `streak` ring at 80 % measures only 2.83:1. Add "`onGlass` on T3 over `#FFFFFF` under `dimSheet` at dim 0.64 ≥ 4.5:1 (7.52:1)" to §15.8.
- **A11Y-3.**
  - In §7.15, replace "the one exception to the backing-disc rule of §2.1.2" with "one of the §2.1.2 plateau exceptions".
  - Add a glyph twin of the text mapping to §2.1.2: "Where a spec in §7 to §9 draws a state-coloured glyph, dot or ring on a sheet, panel, window, palette, alert or glass bar, it takes the backing disc whenever that surface is glass (T2 to T5), and stays bare on black, slabs, `solid1` and `solid2`." Add a pointer to it in §7.10 **Desktop**, as for labels. This covers the desktop Audiobook panel (1.68:1 → with the disc inside T4 at 0.22, `danger` 4.61:1, `success` 7.82:1) and the §7.4 offline wifi-slash on the search field.
  - Add the two passing groups to the exception list with their figures: friend orbs' `bloom` rings and the selected orb's `iris300` ring on sheets and windows (≥ 3.92:1 inside T4 under `dimSheet` at the floor over white), and the wordmark's `iris400` M's as a logotype (WCAG 1.4.3 exempt; 4.38:1 over the capped field). Assert both in §15.8.
- **A11Y-4.** In §2.1.2, change "`label2`, `label3` and `label4` are not used there" to "`label2` and `label3` are not used there, and `label4` appears only as disabled text (§7.1 Disabled, §7.23 disabled rows), which WCAG 1.4.3 exempts". Alternatively, state a glass-specific disabled recipe in both §7.1 and §7.23. Either way, the two sections must stop disagreeing.
- **A11Y-20.** In §8.7 step 4, replace "dims to 50 % with a struck-through label" with "its label turns `label2` with a strike-through (dimmed by role, never by opacity, §14.2; the bubble stays a button)". Keep the 0.8 × shrink as the shape signal.

---

## Observations (not blocking)

- **O1 (A11Y-20 wording).** §14.2 says "read, inactive and offline states dim by role". Taken literally, "inactive" and "offline" also cover the non-activatable offline chapter rows at 40 % (§8.12 and §8.14, l. 2697) and every "disabled (40 %)" state in §7. Those are disabled controls, which WCAG exempts, and round 1 accepted them. A clause such as "disabled controls (not activatable, `aria-disabled`) may dim to 40 %" would stop a builder from reading §14.2 as banning them.
- **O2 (A11Y-3, §15.8 wording).** The exceptions bullet opens with "over `#FFFFFF` at dim 0.22" and then lists the field cases "over a 0.475-luminance blob at 36 % field opacity". The backdrop for each group should be stated once, per group. The figures themselves reproduce.
- **O3 (search field above the keyboard).** On phones the search field rides on the keyboard, away from the bottom `edgeSoft` plateau, so its only floor is the `max(field term, lItems)` estimate. At the floor dim `onGlass` would be 1.46:1 over white, and it is 5.18:1 once `lItems` reads the cover. The estimate is specified, so this passes, but the §2.1.7 worked case ("the plateau, not the estimate, is the floor") does not hold for this bar.
- **Carried from round 1, still open:** O5 (`machine` is not in the disc rule's colour list; the "Previously" sparkle is 3.59:1 on T2 at 0.64), O8 (the `{ type: "gate-closed" }` worker message is in §8.0.8 step 4 but not in §15.2's service-worker protocol bullet), and O9 (the §2.4.2 `solid1` row still says "Reduce Transparency everywhere", while §4.11 exempts `glassTinted`).
