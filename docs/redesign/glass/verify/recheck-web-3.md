# Recheck round 3: Glass web lens (`judge-web.md`, section "Confirmed")

Method: I checked all 21 confirmed findings against the live `glass/DESIGN.md` (4,606 lines), not only the two that round 2 left open (WEB-5, WEB-9). Other lenses' fix rounds are still editing the file, so an earlier fix could have been undone. For each finding I:

- read the edited sections in full and compared them with the judge's final fix;
- grepped for the old values the fix should have removed;
- grepped for every other place that repeats a changed value, to find contradictions.

The round-3 changes listed in `fixed-web.md` (WEB-5: the `offer` desktop form; WEB-9: the `swell` step count) were checked the same way. Section numbers are authoritative. Line numbers come from the 4,606-line state and may move.

Result: **21 resolved, 0 unresolved.** Both round-2 residuals are closed, and none of the 19 earlier fixes has regressed.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count |
|---|---|
| "auto-collapsing", "sidebar (≥ 1024)", "collapsed rail (768–1023)" | 0 / 0 / 0 |
| "sidebar collapsed tooltips" (the `tabLabel` row) | 0. l. 919 reads "`tabLabel` (dock labels)" |
| "Rails show 7" | 0 |
| "Library (6", "6 (1024)" | 0 |
| "cannot keep" (App Router and covered pages) | 0 |
| Intercepting or parallel routes, `@modal` as the mechanism | 0. The only mentions say they are *not* used (§15.2 l. 4187, §8.12 l. 2566) |
| "44 `glassThin` circles" (rail arrows) | 0 |
| Card focus "scale 1.03" | 0. The two remaining 1.03 values are the reorder lift (§7.35, l. 2043) and the pin lift (§8.10, l. 2543) |
| `aria-multiselectable` | 0 |
| "Chapters \| Storage \| Queue" | 0 |
| "Search scopes on desktop" in the §7.13 swipe list | 0 |
| "series sheet first" (recap deep link) | 0 |
| "1200 ms fill", "Hold fill 1,200", "1,200 ms linear" | 0 / 0 / 0 |
| `swell` "for 8 steps" | 0. The only "8 steps" hit is "§8.0.8 steps 5a" at l. 1948, a false positive |
| `offer` in the §7.10 "560 px window" row | 0 (l. 1736) |
| "desktop the right panel's Settings tab" (soundscape, with no reader qualifier) | 0 |
| Hard-coded "⌘K" | 0 outside `formatKeyCombo` sentences. The remaining "⌘" hits are these, and all are allowed:<br>• §7.4 l. 1653, §7.16 l. 1818 and l. 1825, §8.0.6 l. 2314 (all "⌘K on macOS, Ctrl K elsewhere")<br>• the §7.27 keycap glyph rule (l. 1965)<br>• "Ctrl/⌘ + wheel" as gesture prose (l. 2644, 2882, 3844, 3855) |

---

## Per finding

| ID | Verdict | Evidence |
|---|---|---|
| WEB-1 | Resolved | §15.2 **Sheet host** (l. 4186–4191) contains every part of the judge's mechanism:<br>• Glass-only `SheetHost` in `skins/glass/Shell.tsx`<br>• `pushState({ mmSheet: id, base })` for `feature`, `featureByFollow`, `recap`, `circleMember`, `profileNew` and `profileEdit`<br>• `startTransition`, `--sheet-progress`, and the recession values<br>• closing through `history.back()` / `popstate`<br>• the hard-load rule, including `recap`<br>• active item from `base`, focus with `preventScroll`, `mm.glass.stack`, and no `router.refresh()`<br><br>The "sheet route opened from a sheet" sub-bullet matches the two-sheet limit of §7.10 (l. 1729). The zoom name goes through `coverTransitionName(sourceId, seriesKey)`, the same helper used in §8.0.4 (l. 2229) and the Routes bullet (l. 4185).<br><br>The fix is repeated consistently in:<br>• §7.37 (l. 2067): "keeps only one covered page mounted (the sheet host's base page, §15.2)"<br>• the §7.37 recorder (l. 2072), which names the `SheetHost` `pushState`<br>• §8.12 Presentation (l. 2566)<br>• the `Shell.tsx` tree row (l. 4148)<br>• the §8.0.3 `recap` row (l. 2188) |
| WEB-2 | Resolved | §7.16 has the Geometry sentence (l. 1817), **Collapsed (76 px)** with all six sub-bullets (l. 1823–1829), **Width rule** (l. 1830–1833) and **Active item** (l. 1834).<br><br>The thresholds agree everywhere they appear:<br>• `threshold.sidebarCollapse` 1180 (l. 877)<br>• §8.0.1 Desktop (l. 2141): "280 px sidebar at ≥ 1180 px; collapsed 76 px from 1024 to 1179 px"<br>• §8.0.1 Tablet (l. 2140): collapsed 76 px<br>• `Shell.tsx` (l. 4148): "expanded ≥ 1180, collapsed 768–1179"<br>• the §7.27 tooltip delay (l. 1964): "150 ms (dock and sidebar collapsed)" |
| WEB-3 | Resolved | `toolbarHeight` 48 and `toolbarTop` 12 appear in §2.2 (l. 298–299) and §2.8.2 (l. 703–704), with the CSS, Tailwind and Flutter names.<br><br>§2.2 scroll insets (l. 304):<br>• the desktop top inset is 12 + 48 + 16 = **76 px**<br>• `scroll-padding-top: 76px` and `scroll-padding-bottom: 24px`<br><br>The `edgeSoft` desktop plateau is 60 (l. 171). §7.14 Desktop (l. 1789) has:<br>• sticky `top: 12px`<br>• the 0–60 px plateau plus a 24 px fade<br>• content starting at 76 px<br>• the fold rule below 900 px<br><br>No 24 px desktop top inset remains. |
| WEB-4 | Resolved | §7.8 has **Grids**, **Content width** and **Rails** (l. 1702–1704).<br><br>"Columns per §7.8" appears in:<br>• §8.9 (l. 2529, with 112 px result cards)<br>• §8.11 (l. 2552)<br>• §8.17 (l. 2886)<br>• §8.19 (l. 2920)<br><br>The rail counts repeat as follows:<br>• §8.8 Desktop (l. 2512): "about 4.8 … 5.4 … 6.9"<br>• §8.8 Tablet (l. 2513): 3.9 to 5.4<br>• §8.0.8 tablets (l. 2347): the 148 px minimum<br><br>The phone-only pinch split is still in place in §8.17 **Grid** (l. 2882) and in the §11 row (l. 3844).<br><br>The arithmetic still holds, with posters at 5 × 156 at 1024 px, 6 × 159 at 1440 px and 8 × 153 at 1920 px. |
| WEB-5 | **Resolved** (round-2 residual closed) | The §7.10 **Desktop form of every sheet** table (l. 1733–1737) no longer lists `offer` in the 560 px window row.<br><br>The note under the table (l. 1739) says `offer` "stays the 420 px T4 (`glassThick`) popover of §9.1.3, blooming on `morph` from and anchored to the Continue button that opened it", and that it is still URL state (`?sheet=offer`). §9.1.3 (l. 3214), "a T4 offer sheet … as a 420 px popover on desktop", now agrees, and T4 is `glassThick` per §2.4 (l. 340, 380). The §4.10 Bloom row (l. 1197) lists the recap offer as a bloom. §8.0.3 (l. 2214) keeps `offer` in the id list.<br><br>The rest of the fix is intact:<br>• 440 px panel, 560 px window and 960 px window rows, tied to `layout.sidePanel` / `layout.window` / `layout.detailWindow` (l. 710–712)<br>• **Desktop sizes** (l. 1741–1746)<br>• the §7.28 palette `max-height: 70vh` and `calc(70vh - 88px)` (l. 1969)<br>• §9.4.2 **Entry** (l. 3452), with soundscape in the reader panel or the 440 px panel<br><br>Every sheet that names its own desktop form matches its row: the recap (l. 3218), `how-it-works` (l. 3235), `run` (l. 2944), `collection-edit` (l. 2911), `move-source` (l. 2576) and the profile form (l. 2470). |
| WEB-6 | Resolved | The desktop placements are all intact:<br>• §7.12 Position (l. 1765): bottom-left; `bottom: 88px` over the desktop bars; top-centre 60 px inside the desktop readers; one queue with the new-chapters capsule<br>• §7.30 (l. 1998–2000): the status capsule inside the toolbar's single masked glass; the new-chapters capsule at top 72 px, max 480, in the queue; the app-update capsule waits while a bar shows<br>• §7.35 (l. 2044): `bottom: 24px`, max 720, 52 tall, the six-slot list<br>• §8.25 "Unsaved changes" (l. 3056): the same placement<br>• §15.7 Desktop row: 6, with the renamed slots |
| WEB-7 | Resolved | Each collision is still fixed:<br>• §8.13 (l. 2594): "no bare `g`"<br>• §8.12 (l. 2581): `d` = the focused row, `shift+d` = next 10<br>• §7.35 (l. 2043), §8.0.6 (l. 2311), §8.17 (l. 2892) and §11 (l. 3842): `alt+↑/↓`, `alt+shift+←/→` and `alt+shift+↑/↓`, with bare `alt+←/→` never bound<br>• §8.9 (l. 2536): `shift+j` / `shift+k`<br>• §9.3.1 (l. 3399): `[`/`]`, "no bare `l`"<br>• §8.14.7 (l. 2690): `o` = the overlay plus the Dialogue tab, `shift+o` = the panel only<br>• §8.14.11 (l. 2713): "`,`, `shift+o` and `shift+c` open them" |
| WEB-8 | Resolved | The §8.0.6 row (l. 2307) reads "`Delete` or `Backspace`", with Backspace only outside fields. The paragraph under the table (l. 2314) sets:<br>• `allowInInput` = exactly `mod+k`, `mod+b` and `Esc`<br>• `alt+` matching on `event.code` in `lib/keyboard/match.ts`<br>• every visible combo through `formatKeyCombo`<br><br>§14.4 (l. 4028) repeats the same set. |
| WEB-9 | **Resolved** (round-2 residual closed) | §5.3 `swell` (l. 1502) now reads "T every 0.150 s for **7 steps** (t = 0 to 0.900 s from the fill's start …, before `hold.done`), I 0.20 → 0.80 and S 0.60 → 0.90 linearly". The steps land at 0, 0.15, … 0.90 s, so the last is inside the 1000 ms fill and the ramp reaches I 0.80.<br><br>Every place that repeats the timing agrees:<br>• §4.6 (l. 1134): "every 150 ms from the fill's start, rising 0.2 → 0.8"<br>• §5.2 `hold.ramp` (l. 1434): step by step<br>• §7.1 (l. 1609)<br>• `threshold.holdConfirm` / `holdStart` / `holdClickSlop` (l. 860–862)<br>• §4.10 Hold fill (l. 1236): 1,000 ms after the 200 ms start<br>• §7.25 (l. 1947)<br>• §14.8 (l. 4059)<br><br>The §15.1 JSON (l. 4120) lists only `holdConfirm: 1200`. It is labelled "an excerpt of its shape" (l. 4088), so it does not conflict. The inside-alert and outside-alert Alternative is intact. |
| WEB-10 | Resolved | The fix is present in all four places:<br>• §7.2 **Toggle semantics** (l. 1630)<br>• the §7.3 Password row (l. 1639): fixed name "Show password", `aria-pressed`, and the glyph swaps while the name does not<br>• §7.23 `menuitemcheckbox` (l. 1905)<br>• §7.35 **Select-mode semantics** (l. 2045) |
| WEB-11 | Resolved | §8.14.11 has **Fit**, **Semantics** and **Focus** (l. 2715–2717). The fit numbers hold: 300 + 360 + 2 × 24 = 708, and 708 + 24 + 480 = 1212. The Esc order is the same in §8.14.7 (l. 2690) and §8.14.11.<br><br>§8.15.2 (l. 2758) has:<br>• **Fit**: `min(measure, … − 40)` with the 48 ch floor<br>• **Semantics and focus**: `t`, `,`, `v`; `F6` |
| WEB-12 | Resolved | The §7.15 bullet **Hidden while the on-screen keyboard is open** (l. 1802) covers:<br>• `(pointer: coarse)`<br>• `dematerialize` 350 ms and `inert`<br>• return 100 ms after the last `focusout`<br>• all five objects<br>• the safe area + 16 px inset and `scroll-padding-bottom: 16px`<br>• Flutter `viewInsetsOf` |
| WEB-13 | Resolved | §8.0.8 **Mobile web gesture hygiene** (l. 2346) sets `-webkit-touch-callout`, `user-select`, touch `contextmenu` suppression, Glass's own timer, and `ContextMenu` for right-click and `shift+F10` only.<br><br>The novel reader's mobile-web action capsule appears in §8.15.3 (l. 2771), in the §11 "Long-press text" row (l. 3859) and in the §11 press-and-hold row (l. 3830). |
| WEB-14 | Resolved | §8.0.8 (l. 2346) sets `touch-action: pan-x pan-y` on the grid, the novel column and the guided-view camera, and ignores these pinches while `visualViewport.scale > 1`.<br><br>The §15.2 Dependencies note (l. 4184) and the §15.11 ledger (l. 4443) both name "Library grid, novel column and guided-view pinch". |
| WEB-15 | Resolved | §7.9 Desktop (l. 1718) specifies the arrows as content twins:<br>• `rgba(19,19,23,0.62)` fill<br>• 0.5 px `rgba(255,255,255,0.22)` rim<br>• hover `rgba(40,40,48,0.72)`<br>• `fadeIn` in and out 300 ms after leave<br>• outside the budget<br><br>§8.8 (l. 2512) points to §7.9. |
| WEB-16 | Resolved | The §7.8 **Corner conflicts** bullet (l. 1707) is in place. §8.17 Desktop (l. 2886) repeats the same corners, the 120 ms fade and the 18+ capsule moving to the bottom-right. |
| WEB-17 | Resolved | §7.6 Web (l. 1678) makes Updates and Statistics a `tablist` with no pager and no swipe. The **Vertical variant** is at l. 1679.<br><br>§7.13 **Where** (l. 1777) lists Chapters \| Queue \| Storage and routes Updates, Statistics and Search scopes to §7.6. The Downloads screen (l. 2953) matches.<br><br>The vertical variant's indicator is "`glassFilm` clear", not the judge's "`glassThin`". The consistency lens made this change on purpose: `fixed-consistency.md` CONSISTENCY-3 names every droplet "`glassFilm` clear" (§2.4.2, l. 377). It is a sanctioned refinement, not a regression. |
| WEB-18 | Resolved | §7.7 sets the focus scale to 1.04 (l. 1697), and §7.8 Keyboard (l. 1710) repeats it. The §2.6 append rule is at l. 475. The §2.8.3 `border.focusRing` Tailwind cell (l. 745) is marked "content-layer elements only". |
| WEB-19 | Resolved | The §8.0.3 `index` row (l. 2197) makes `/more` "a page at every width (no viewport-dependent redirect)". §8.24 Desktop and tablet (l. 2985) uses two columns, at most 880 px wide and centred. |
| WEB-20 | Resolved | §7.40 (l. 2110–2123) has all eight rows and the Tailwind 4 preflight note. |
| WEB-21 | Resolved | §8.25 Desktop (l. 2992) has:<br>• the 36 px `fill3` "Search settings" capsule<br>• in-place grouped results<br>• "No settings match “{q}”"<br>• Enter or click with the Row pulse<br>• Esc clears the field, and `/` focuses it<br><br>The **Keys** line (l. 2995) "Esc returns to the section list" applies once the field is empty, so the two do not conflict. |

---

## What each unresolved finding still needs

Nothing. All 21 findings are resolved.

---

## Observations (not blocking, outside the judge's final fixes)

All are unchanged from round 2 except O8, which is new. The owner or a later sweep can pick them up.

- **O2 (open since round 1).** The §8.0.1 Tablet row (l. 2140) puts the accessory "as a floating capsule bottom-centre of the content column". §7.16 (l. 1819) shrinks the accessory to a 56 px orb in the collapsed sidebar, and tablets always have the collapsed sidebar. One of the two should name the tablet case.
- **O3 (open since round 1).** The resting position of the favourite star is unspecified. §8.17 (l. 2883) says it is "always visible when favourited", but §7.8 **Overlays** puts only the status tag and the 18+ capsule top-left at rest. The star's top-left position is defined only for hover and focus.
- **O4 (open since round 1).** `allowInInput` is exactly `mod+k`, `mod+b` and `Esc`, so §9.1.2's `alt+1` to `alt+3` ("fill an example", l. 3207) cannot fire while focus is in the Ask box. §9.1.2 could say that they work from outside the box.
- **O5 (open since round 2).** The Flutter tree row `shell.dart` (l. 4206) still says "collapsed rail for ≥ 768". To match `Shell.tsx` (l. 4148) and §8.0.1, it should read "sidebar (expanded ≥ 1180, collapsed 768–1179)".
- **O6 (open since round 2).** The §7.10 table leaves out `player`. The fixer explains why in `fixed-web.md`: it uses a T5 560 px window with its own height rule (§8.16.2, l. 2835). There is no conflict.
- **O7 (open since round 2).** The web Downloads screen has only "tabs Chapters · Storage" (l. 2958). §7.13 **Where** (l. 1777) lists Chapters \| Queue \| Storage with no platform qualifier. The order agrees, but §7.13 could add "(web: Chapters \| Storage)".
- **O8 (new, WEB-5 neighbour).** The §8.0.3 URL-state rule (l. 2208) exempts "popovers such as the go-to-page popover" from history entries. The §7.10 note (l. 1739) keeps the desktop `offer` popover as URL state (`?sheet=offer`). The more specific §7.10 note wins, and `offer` is in the §8.0.3 id table, so this is not a contradiction. Still, §8.0.3 could add "(the recap offer's desktop popover keeps `?sheet=offer`, §7.10)" so that a reader of §8.0.3 alone does not drop its history entry.
