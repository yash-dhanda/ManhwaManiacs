# Glass DESIGN.md: fixes applied from the web coverage judge

## Round 1

Source: `glass/verify/judge-web.md`, section "Confirmed" (21 findings, none refuted). Every fix was applied as the judge rewrote it, except where noted. Section numbers refer to `glass/DESIGN.md`.

| ID | Sections changed |
|---|---|
| WEB-1 | §15.2 new **Sheet host** bullet under Routes (Glass-only `SheetHost` in `Shell.tsx`, `history.pushState({mmSheet, base})`, closing via `history.back()`, hard-load rule, active item follows `base`, focus, `mm.glass.stack`, no `router.refresh()`); §15.2 `Shell.tsx` tree row names `SheetHost`; §7.37 Back menu opening sentence ("keeps only one covered page mounted"); §8.12 Presentation (web keeps the covered page mounted through the sheet host) |
| WEB-2 | §7.16 Geometry sentence plus new **Collapsed (76 px)**, **Width rule** (expanded ≥ 1180 px, overlay with `dimSheet` from 768 to 1179 px, `sessionStorage['mm.glass.sidebar']`) and **Active item** bullets; §3.2 `tabLabel` row (collapsed-sidebar tooltips removed; they are `footnote` per §7.27); §8.0.1 Desktop app row; §15.2 `Shell.tsx` row (expanded ≥ 1180, collapsed 768–1179); §2.8.5 `threshold.sidebarCollapse` meaning |
| WEB-3 | §2.2 fixed lengths (`toolbarHeight` 48, `toolbarTop` 12) and scroll insets (desktop top inset 76 px, `scroll-padding-top: 76px`, `scroll-padding-bottom: 24px`); §2.8.2 rows `layout.toolbarHeight` and `layout.toolbarTop`; §2.1.7 `edgeSoft` (desktop plateau 60 px); §7.14 Desktop (sticky `top: 12px`, plateau 0–60 px plus 24 px fade, fold rule below 900 px of content width) |
| WEB-4 | §7.8 new **Grids**, **Content width** and **Rails** bullets (one `auto-fill` rule, `--grid-min` 148 / 152 / 112, 20 px gap, rail counts 4.8 / 5.4 / 6.9); per-screen counts replaced by "columns per §7.8" in §8.8 (rail count), §8.9 desktop, §8.11 desktop, §8.17 desktop, §8.19 desktop |
| WEB-5 | §7.10 new **Desktop form of every sheet** table (440 px panel, 560 px window, 960 px window) and **Desktop sizes** (panel height, window top `max(12vh, 48px)` and `max-height: min(80dvh, 880px)`, series window `calc(100dvh - 48px)`, palette 70 vh, stacking); §7.28 Open (`max-height: 70vh`, results `calc(70vh - 88px)`) |
| WEB-6 | §7.12 Position (toasts rise to `bottom: 88px` over the desktop bars; top-centre 60 px inside desktop readers; shared queue with the new-chapters capsule); §7.30 Status capsule (desktop placement inside the toolbar's masked glass), Global new-chapters capsule (desktop and tablet top 72 px, max 480 px, one queue with toasts), App update capsule (waits while a desktop bar shows); §7.35 Bulk selection (desktop toolbar fixed at `bottom: 24px`, max 720 px); §8.25 "Unsaved changes" bar (same placement); §15.7 Desktop budget row (slots renamed so the total stays 6) |
| WEB-7 | §8.13 Keys (`g` dropped, `/` focuses go-to); §8.12 Keys (`d` = focused row, `shift+d` = next 10); §7.35 Reorder, §8.0.6 reorder row, §8.17 Keys and §11 drag-to-reorder row (`alt+shift+←/→` in grids, bare `alt+←/→` never bound); §8.9 Keys (`shift+j` / `shift+k`); §9.3.1 Keys (`l` dropped, `[`/`]`); §8.14.7 Keys (`o` overlay plus Dialogue tab, `shift+o` panel only); §8.14.11 Right panel ("`,`, `shift+o` and `shift+c` open them") |
| WEB-8 | §8.0.6 row actions (`Delete` or `Backspace`, Backspace outside fields) and the paragraph under the table (the `allowInInput` set `mod+k`, `mod+b`, `Esc`; `Backspace` wherever a screen binds `Delete`; `alt+` matching on `event.code` in the shared `lib/keyboard/match.ts`; every visible combo through `formatKeyCombo`); §7.4 Desktop search capsule, §7.16 Order and §8.28 404 hint (no hard-coded "⌘K"); §14.4 `allowInInput` sentence |
| WEB-9 | §7.1 Hold-to-confirm (200 ms start threshold, click below 200 ms and 8 px, aborted hold drains with the helper "Keep holding, or click once to confirm" for 2 s, Enter/Space = click; Alternative split into outside-alert and inside-alert rules); §7.25 Turning it on (explicit button always visible, no screen-reader detection); §14.8 hold-to-confirm sentence. **Note:** the 1200 ms fill token is unchanged; the fill starts after the 200 ms threshold, so an aborted hold is any release after 200 ms and before the fill completes. |
| WEB-10 | §7.2 new **Toggle semantics** paragraph (`aria-pressed` only with a constant label, fixed names; changing labels take none, WCAG 2.5.3; menu toggles `menuitemcheckbox`); §7.3 Password row (fixed name "Show password"); §7.23 Keyboard (`menuitemcheckbox`); §7.35 new **Select-mode semantics** bullet (`role="group"` + `role="checkbox"`, `aria-checked`, suspended `href`, Space/Enter toggle, `shift+Space` range, `aria-disabled` saved rows, polite "{n} selected") |
| WEB-11 | §8.14.11 new **Fit**, **Semantics** and **Focus** bullets (strip `min(clamp(…), viewport − Σ(panel + 24) − 24)`, one panel at a time below 480 px, `complementary` landmarks, `F6` cycle, Esc order); §8.14.7 Esc order; §8.15.2 Desktop panels (**Fit** for the novel column with the 48 ch floor, **Semantics and focus**); §8.15.8 Esc order (no fullscreen step, since the novel reader has none) |
| WEB-12 | §7.15 new **Hidden while the on-screen keyboard is open** bullet (web `(pointer: coarse)` focus rule with `inert`, Flutter `viewInsetsOf`, bottom inset safe area + 16 px) |
| WEB-13 | §8.0.8 Mobile web gesture hygiene (every §11 long-press target, touch `contextmenu` suppression, Glass's timer owns touch long-press, Base UI `ContextMenu` only for right-click and `shift+F10`); §8.15.3 Long-press (mobile web action capsule replaces the bottom capsule, native selection toolbar kept); §11 press-and-hold row (mobile web column) |
| WEB-14 | §8.0.8 Mobile web gesture hygiene (`touch-action: pan-x pan-y` on the Library grid, novel column and guided-view camera; ignored while `visualViewport.scale > 1`); §15.2 Dependencies note and §15.11 ledger row for `@use-gesture/react` |
| WEB-15 | §7.9 Desktop (content-twin arrows: `rgba(19,19,23,0.62)` fill, 0.5 px rim, hover `rgba(40,40,48,0.72)`, `fadeIn` in, out 300 ms after leave, outside the budget); §8.8 desktop layout sentence points at §7.9 |
| WEB-16 | §7.8 new **Corner conflicts** bullet (hover and focus swap, 18+ capsule to bottom-right, select mode hides the corner marks, count kept in the accessible name); §8.17 desktop hover sentence |
| WEB-17 | §7.13 Where (Updates, Statistics and Search scopes removed; Downloads Chapters · Queue · Storage); §7.6 Web (`tablist` for Updates and Statistics) and new **Vertical variant**; §8.9 desktop filter column points at it; §11 horizontal-swipe row (Updates and Statistics removed) |
| WEB-18 | §7.7 card focus scale 1.04; §2.6 focus paragraph (glass surfaces append the glow to `var(--glass-shadow), var(--glass-inner-light)`); §2.8.3 `border.focusRing` Tailwind cell (content-layer only) |
| WEB-19 | §8.0.3 `index` row; §8.24 Desktop and tablet (no redirect, two columns at most 880 px) |
| WEB-20 | New §7.40 **Pointer cursors (web only)** table |
| WEB-21 | §8.25 Desktop (36 px `fill3` "Search settings" capsule heading the section list, in-place results, "No settings match", Row pulse, Esc and `/`) |

No screens were added or removed, so Appendix B (Coverage) is unchanged.

## Round 2

Source: `glass/verify/judge-web.md` "Confirmed" plus the residuals in `glass/verify/recheck-web-1.md` (WEB-4, WEB-5, WEB-9 and WEB-13 were unresolved; the other 17 were resolved in round 1 and are unchanged).

| ID | Sections changed |
|---|---|
| WEB-4 | §8.17 **Grid** (pinch: 2 ↔ 3 ↔ 4 ↔ 5 columns and List on phones only; at ≥ 768 px it steps Comfortable ↔ Compact ↔ List, `--grid-min` 148 tablet / 152 desktop ↔ 112 ↔ rows, columns per §7.8; Ctrl/⌘ + wheel on desktop web; non-gesture path split into the phone column slider and the tablet/desktop segmented control); §11 "Pinch the grid" row (phone, tablet and desktop web cells); §8.25.3 Library density migration row (pinch column count is phones only) |
| WEB-5 | §9.4.2 **Entry** (desktop: inside a reader, the reader's right panel, Settings tab; elsewhere the 440 px right panel of §7.10) |
| WEB-9 | Chose option (a): the fill runs **1000 ms** after the 200 ms start, so a completed hold stays **1200 ms in all**. §7.1 Hold-to-confirm (1000 ms fill, `threshold.holdStart`, `threshold.holdClickSlop`, new **cancel** rule: moving 8 px or more before 200 ms, or `pointercancel`, does nothing on release; `hold.ramp` from the fill's start); §2.8.5 `threshold.holdConfirm` meaning (whole press) plus new rows `threshold.holdStart` 200 ms and `threshold.holdClickSlop` 8 px (CSS, Flutter names); §4.6 Hold to confirm row (200 ms start + 1000 ms fill, click, cancel and aborted-hold rules); §4.10 **Hold fill** row (1,000 ms linear after the 200 ms start); §7.25 Turning it on ("1200 ms in all: the 200 ms start, then the 1000 ms fill") |
| WEB-13 | §11 "Long-press text" row, Mobile web cell (native selection with the browser's toolbar keeping Copy; Bookmark · Play from here · React · Recommend in the `glassThick` action capsule that replaces the bottom capsule, §8.15.3) |
| WEB-1 (recheck O1) | §8.0.3 `recap` route row: a deep link or hard load renders the series as a full page with the recap sheet over it, matching the §15.2 sheet host's hard-load rule |

No screens were added or removed, so Appendix B (Coverage) is unchanged. Recheck observations O2 to O4 are outside the judge's fixes and were left for the owner.

## Round 3

Source: `glass/verify/judge-web.md` "Confirmed" plus the two residuals in `glass/verify/recheck-web-2.md` (WEB-5 and WEB-9 unresolved; the other 19 were resolved and are unchanged). A grep of the live file for the old values listed in recheck round 2 ("auto-collapsing", "Rails show 7", "1200 ms fill", "cannot keep", "Chapters | Storage | Queue", `aria-multiselectable`, "series sheet first" and the rest) still returns 0, so no earlier fix has regressed.

| ID | Sections changed |
|---|---|
| WEB-5 | §7.10 **Desktop form of every sheet**: `offer` removed from the 560 px window row; a note under the table says `offer` keeps the 420 px T4 (`glassThick`) popover of §9.1.3, blooming on `morph` from and anchored to the Continue button, still URL state (`?sheet=offer`, closed by Esc, an outside click or browser back). §9.1.3 is unchanged and now agrees. |
| WEB-9 | §5.3 `swell` pattern: "T every 0.150 s for **7 steps** (t = 0 to 0.900 s from the fill's start, so the last step lands inside the 1000 ms fill, before `hold.done`)", I 0.20 → 0.80, S 0.60 → 0.90. §4.6 ("every 150 ms from the fill's start, rising 0.2 → 0.8") and the `hold.ramp` row of §5.2 already match and are unchanged. |

No screens were added or removed, so Appendix B (Coverage) is unchanged. Recheck observations O2 to O6 are outside the judge's fixes and were left for the owner (O6: `player` could be listed in the §7.10 table, but its 88 vh max height differs from the window rule, so it was not added).
