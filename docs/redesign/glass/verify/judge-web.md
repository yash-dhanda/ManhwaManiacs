# Judge: Glass web coverage findings (`find-web.md`)

Method: for each of the 21 findings I tried to refute the claim by grepping `glass/DESIGN.md` (4,184 lines) for the missing rule and by reading the cited lines, `inventory/00-decisions.md`, `stack-decision.md`, `inventory/web.md` and, where the fix touches shared code, the checkout (`frontend/src/app/**`, `frontend/src/lib/keyboard/{match,format}.ts`). A finding is confirmed only when the defect exists and the fix is correct; where the finder's fix was wrong, incomplete or offered a choice, the final fix below replaces it.

Result: **21 confirmed, 0 refuted.** Six fixes were rewritten (WEB-1, WEB-4, WEB-6, WEB-9, WEB-10, WEB-11), four were narrowed or corrected in part (WEB-8, WEB-13, WEB-18, WEB-2), and the rest stand as written with small edits.

---

## Verdicts and reasons

| ID | Verdict | Reason |
|---|---|---|
| WEB-1 | Confirmed, fix rewritten | Lines 1981, 2296, 2020 present `feature`, `featureByFollow`, `recap`, `circleMember` and the profile form "over the recessed page", line 1886 says the App Router cannot keep covered pages mounted, and §15.2 (lines 3766–3810) gives no mechanism: no `intercept`, `parallel`, `@modal` or `pushState` anywhere. The finder's fix is wrong for this codebase: `app/` route files are shared by both skins (`stack-decision.md` §2.2), so intercepting routes in `app/` would also intercept every Cinematic navigation to a series, which Cinematic presents as a page (`cinematic/DESIGN.md` line 1610); and the `(app)` layout it names does not exist (`frontend/src/app/` has no route groups). The mechanism must live in the Glass skin. |
| WEB-2 | Confirmed, fix edited | Line 1658 ("Collapsed: 76 wide (icons only), auto-collapsing below 1180 px") is the only description of the collapsed sidebar; line 1942 gives Desktop (≥ 1024) the 280 px sidebar and §15.2 line 3790 says "sidebar (≥ 1024), collapsed rail (768–1023)", both contradicting §7.16. No re-expand control, overlay-or-push rule or collapsed rendering of the wordmark, search, mode switch, Library children, pinned sources or profile capsule exists. Line 858 names `tabLabel` for collapsed tooltips while §7.27 (line 1793) says tooltips are `footnote`. Inventory G16 and G29e confirm the elements. Fix adopted with §15.2 added to the corrections. |
| WEB-3 | Confirmed | Line 295 sets the desktop top inset to 24 px while line 1631 makes the toolbar row 48 px tall with an `edgeSoft` plateau, i.e. content scrolls beneath it; with `scroll-padding-block` = 24 the first 24 px of content and a focused element can sit under the toolbar, the WCAG 2.4.11 failure the same line claims to prevent. §2.8.2 (lines 638–682) has no toolbar key. The fix's geometry is consistent with `sidebarInset` 12 and with the `edgeSoft` definition (line 170: plateau to the far edge of the bar group, then a 24 px fade). |
| WEB-4 | Confirmed, fix tightened | Checked the arithmetic. At 1440 px the content is 1440 − 304 − 80 = 1056 px, so 184 px rail posters with a 16 px gap show 5.4, not "7 (1440 px)" (line 2243). The Library's "6 (1024)" columns (line 2586) give posters of about 126 px even with the collapsed sidebar, below the tablet minimum of 148 px (line 2100). Catalogue, History and Search use three more rules (lines 2282, 2619, 2260). The finder's `auto-fill` values reproduce: 5 columns of 156 px at 1024 (collapsed sidebar, 860 px content), 6 of 159 px at 1440, 8 of 153 px at 1920. I removed the "or change `wide` to 136 px" alternative, because a spec must pick one. |
| WEB-5 | Confirmed | Line 1594 defines a 440 px panel and a 560 px window, but `layout.sidePanel` (line 675) is used by no sheet, and `filters`, `tags`, `manage-tags`, `add-series`, `collection-share`, `recommend`, `letter-note`, `note`, `audiobook`, `whats-new`, and `voices` / `cast` / `soundscape` outside a reader never name a desktop form. Only `run`, `licenses`, `how-it-works`, the recap, the friend sheet, collection edit and the profile form do. No window or panel has a height rule, and the palette (§7.28, line 1798) lost the inventory's 70 vh cap (CP2). |
| WEB-6 | Confirmed, fix corrected | Line 1828: the new-chapters capsule "drops in at the top", placed only for phones (line 1609). Line 1827: the status capsule lives in the phone nav row. Line 1864: the bulk toolbar "replaces the bottom accessory slot", which does not exist on desktop, and the same holds for the "Unsaved changes" bar (line 2747). Line 1608 puts desktop toasts bottom-left beside a sidebar the readers do not have. The desktop budget (line 3960) is already 6 without the capsule. The finder's fix left two conflicts: bottom-left toasts overlap a bottom-centred bulk toolbar at 1440 px (toasts span x 328–748, the toolbar x 512–1232), and "72 px from the top (between the two top groups)" is self-contradictory. Both are corrected below. |
| WEB-7 | Confirmed | Each collision checks out: Book page `g` (line 2321) against the `g` chord prefix (line 2057), with chords switched off only in the readers (line 2408); Series detail `d` = "download next 10" (line 2308) against global `d` = download the focused row (line 2067); `alt+←/→` reorder (lines 1863, 2069) against "`alt+←` stays the browser's" (line 2045); Search `j`/`k` source groups (line 2266) against `h j k l` grid movement (line 2063); Circle `l` (line 3079) against grid movement on Shelves; reader `o` = overlay (line 2408) against `o` = the right panel's Dialogue tab (line 2431). The replacement bindings are unused on those screens. |
| WEB-8 | Confirmed, fix narrowed | `frontend/src/lib/keyboard/match.ts` matches on `event.key`, so `alt+1` never fires on macOS, where Option+1 reports "¡" (line 2898 binds it). Mac laptops have no forward-delete key. The formatter already exists (`lib/keyboard/format.ts` renders ⌘ on Mac and Ctrl elsewhere), so the "⌘K" literals (lines 1522, 1659, 2836) only need to be routed through it. The `allowInInput` set is never listed (lines 2072, 3655). I removed `mod+enter` and `mod+\` from the finder's allowlist: `mod+enter` is "Continue the most recent read" globally and should not fire from arbitrary fields. |
| WEB-9 | Confirmed, fix rewritten for the in-alert case | Line 1482 says both "releasing early drains the fill" and "a plain click opens an alert", with no threshold between them. For the 18+ gate (line 1776) the hold button is already in an alert, so the §7.1 rule would open an alert over an alert. The finder's "the explicit button is always present for keyboard and screen-reader users" cannot be implemented on the web, which cannot detect a screen reader, so the final fix makes the explicit button visible to everyone inside an alert. |
| WEB-10 | Confirmed, fix corrected | No `aria-checked`, `role="checkbox"`, `aria-multiselectable` in DESIGN.md; `aria-pressed` only on the password eye (line 1510); select mode says only "each tap toggles" (line 1864). Two parts of the finder's fix were invalid ARIA. `aria-multiselectable` is only allowed on `grid`, `listbox`, `tablist` and `tree`, not on a group of checkboxes. `aria-pressed` must not sit on buttons whose visible label changes with state ("Add to library" / "In library", line 2300), because WCAG 2.5.3 requires the name to follow the visible label. The password eye (line 1510) already breaks this rule (changing label plus `aria-pressed`). |
| WEB-11 | Confirmed, fix rewritten | At 1024 px, 300 + 360 + four 12 px insets leave 316 px for a strip whose minimum is 480 (line 291), yet line 2432 says "panels push the strip, never cover it". The finder's 1188 px threshold is wrong, because the strip is `clamp(480px, 50vw, 900px)` and never narrows. With both panels open (708 px) it collides at every width below 1416 px (e.g. at 1300: strip 650 px, room 592 px). The novel column also fails with **one** panel at 1024 px (68 ch at 20 px ≈ 707 px against 640 px of room), which the finder's rule never allows for. Line 2408's Esc order omits panels, and focus and landmark behaviour are unspecified (no `aria-modal`, `complementary` or `F6`). |
| WEB-12 | Confirmed, Flutter mechanism added | Line 3804 sets `interactive-widget=resizes-content` app-wide, so on Chrome for Android the layout viewport shrinks and the fixed dock, orb and accessory (about 150 px) ride up over the focused field. Only the orb's own field is handled (line 1521), and line 1643's hide list has no keyboard case. Flutter has the same problem through `Scaffold.resizeToAvoidBottomInset`. |
| WEB-13 | Confirmed, novel part rewritten | Line 2099 covers only posters, pages and orbs. Line 3461 (§11) extends `-webkit-touch-callout: none` to rows and cards, but that property is iOS-only, and nothing prevents Android Chrome's `contextmenu` on long-pressed links (grep "contextmenu": no hit). Base UI ContextMenu (line 3805) adds its own touch long-press. The novel menu "above the selection" (line 2476) collides with the native selection toolbar on mobile browsers. The finder's "12 px below the last line" would sit on the selection end handle, so the final fix moves Glass's actions to a bottom capsule instead. |
| WEB-14 | Confirmed | §11 promises pinch on mobile web for the Library grid (line 3475), novel text (line 3486) and guided view (line 3487); the only `touch-action` rule is the manga strip's `pan-y` (line 2436), and the dependency note and ledger limit `@use-gesture/react` to the reader (lines 3805, 4022). Without `touch-action`, iOS Safari page-zooms instead. |
| WEB-15 | Confirmed | Line 1582 draws the rail arrows as `glassThin` glass inside scrolling content. They repeat per rail (rule 1, line 347) and exceed rule 2's two page-level controls, which Home's hero already uses (line 348). The fix uses the content-twin recipe already defined in §2.4.1 rule 1. |
| WEB-16 | Confirmed | On hover the follow bell and star go "at its top corners" (line 2586), where the status tag, 18+ capsule and "N new" badge already sit (line 1571), and select mode's check orb is top-right too (line 1565). Inventory LB13 hides the status badge while selecting. |
| WEB-17 | Confirmed | Line 1619 lists Updates, Statistics ranges and desktop Search scopes as swipeable tab strips, while their screens specify segmented controls (lines 2638, 2962) and a vertical segmented list that §7.6 does not define (line 2260). Line 3478 lists Updates and Statistics as pagers. Downloads is "Chapters \| Storage \| Queue" at line 1619 and "Chapters · Queue · Storage" at line 2652. |
| WEB-18 | Confirmed, fix narrowed | Cards focus at 1.03 (line 1565) and posters at 1.04 (line 1574), yet the series card *is* a poster. The `focus-visible:shadow-(--mm-focus-glow)` utility (line 709) replaces the glass surface's own `box-shadow` list (shadow plus the §2.4.3 inset inner light, line 402) while focused. I dropped the finder's new 1.02 row scale, which fixes nothing: §7.17 rows have no focus scale and need none. |
| WEB-19 | Confirmed | Line 1998 and line 2679 make `/more` redirect to `/settings` "on desktop". The server cannot know the viewport, so this becomes a post-paint client redirect that also fires on window resize. Cinematic renders `/more` at every width (`cinematic/DESIGN.md` line 2868). |
| WEB-20 | Confirmed | "cursor" occurs only as a pagination parameter (line 3115), yet line 2080 requires hover states on everything interactive, and Tailwind 4's preflight sets buttons to `cursor: default`. Cinematic specifies cursors (`cinematic/DESIGN.md` line 1003); Glass does not. |
| WEB-21 | Confirmed | Line 2686 places the settings search only on phones (a full-screen overlay); the desktop layout is a 240 px section list plus a panel, with no search field, although line 2689 binds `/` to "searches settings". |

---

## Confirmed

### WEB-1 · high · Sheet and window routes on the web keep the covered page mounted

In §15.2 **Routes**, add a **sheet host** paragraph, and amend §7.37 line 1886 and §8.12 **Presentation**:

- **Mechanism (Glass skin only, no change to the shared `app/`).** Intercepting and parallel routes are not used: `app/` route files are shared by both skins, and an interception there would also turn Cinematic's series pages into overlays. Instead, `skins/glass/Shell.tsx` owns a `SheetHost`. A Glass link whose target is a sheet route (`feature` `/sources/:sourceId/series/:seriesKey`, `featureByFollow` `/library/:followedId`, `recap` `/recap/:sourceId/:seriesKey`, `circleMember` `/circle/:profileId`, and `profileNew` / `profileEdit` from the picker) does not call `router.push`. It calls `window.history.pushState({ mmSheet: id, base: currentPath }, "", href)`, which Next 16 syncs into `usePathname` / `useSearchParams` without re-rendering the route tree, and then renders `skins.glass.screens[id]` inside the host inside `startTransition`. The covered page stays mounted and keeps its scroll, so the recession (desktop: scale 0.97, blur 8, dim 50 %; phone and mobile web: the §7.10 recession) is driven by a `--sheet-progress` custom property the host writes on the Shell root. The poster zoom keeps `ViewTransition name="cover-{sourceId}-{seriesKey}"`, because both elements are now in the DOM during the same transition.
- **Closing.** The close button, Esc, a downward drag and a backdrop click call `history.back()`. The host closes when `popstate` removes the `mmSheet` entry (Next restores the covered page's tree, which is unchanged). Forward re-opens it.
- **Hard load.** A reload or a deep link to the same URL renders the full page through the normal thin route file (the existing "deep link without a parent" rule). `recap` on a hard load renders the series page with the recap sheet over it.
- **While a sheet route is open:** the sidebar's active item and the dock's selected tab follow the host's `base` path, not `usePathname`. Focus moves to the sheet title (`preventScroll: true`) and returns to the trigger on close. The back-menu recorder (`mm.glass.stack`) records each sheet route as one level. Glass never calls `router.refresh()` while a sheet route is open; data refreshes go through the shared hooks.
- **§7.37 line 1886:** rewrite to "The web keeps only one covered page mounted (the sheet host's base page), so it never fans live screens (no plane stack). Instead:".

### WEB-2 · high · The collapsed 76 px sidebar and the 1024–1179 px contradiction

Add a **Collapsed (76 px)** block to §7.16:

- **Top:** the `mm-mark` at 32 px, centred, 16 px from the panel top (tooltip "ManhwaManiacs"). Below it, the expand button: a 44 px plain icon, `caret-right`, `aria-label="Expand sidebar"`, `aria-expanded="false"`.
- **Search:** a 44 px `magnifying-glass` icon button. Its tooltip is the formatter's shortcut ("Search · ⌘K" on macOS, "Search · Ctrl K" elsewhere), and it opens the palette.
- **Content-mode control:** two stacked 44 px icon buttons (`strip-scroll`, `book-open`) sharing one droplet that travels vertically on `tab`.
- **Items:** each is a 44 × 44 icon cell, radius 12, with an active droplet of 52 × 44. Library and Home (For you) open a `glassThick` flyout menu of their children to the right of the cell, on hover after 150 ms or on Enter or `→`.
- **Other entries:** pinned sources as 32 px favicon cells; the Updates count as the §7.20 count badge at the icon's top-right (offset −4, −4); the profile capsule becomes the 44 px orb.
- **Tooltips:** every icon cell has a tooltip in `footnote` 13/18 `onGlass` at the 150 ms delay of §7.27. Delete "sidebar collapsed tooltips" from the `tabLabel` row of §3.2 (line 858).
- **Width rule:**
  - At 1180 px and wider the sidebar starts expanded, and `mod+b` or the chevron collapses and expands it, pushing the content.
  - From 768 to 1179 px it starts collapsed. `mod+b` or the expand button opens the 280 px panel as an **overlay** over the content, with `dimSheet` behind it. Esc, an outside click or choosing an item collapses it, and focus moves to its first item on open and back to the expand button on close.
  - The manual choice is kept for the browser tab only, in `sessionStorage['mm.glass.sidebar']`.
- **Active item:** on `/sources/:id` of a pinned source, the pinned entry is active and Sources is not.
- **Corrections:**
  - §8.0.1 Desktop row: "280 px sidebar at ≥ 1180 px; collapsed 76 px from 1024 to 1179 px (§7.16)".
  - §15.2 `Shell.tsx`: "sidebar (expanded ≥ 1180, collapsed 768–1179)".

### WEB-3 · medium · Desktop top inset versus the toolbar row

- Add `layout.toolbarHeight` 48 and `layout.toolbarTop` 12 to §2.2's fixed lengths and to §2.8.2 (`--mm-layout-toolbar-height: 48px`, `--mm-layout-toolbar-top: 12px`; Tailwind `h-toolbar-height`, `top-toolbar-top`; Flutter `layoutToolbarHeight` = `48.0`, `layoutToolbarTop` = `12.0`).
- The toolbar row is `position: sticky; top: 12px` inside the content column, aligned with the sidebar's top edge, with no horizontal inset beyond the screen margin.
- Line 295: desktop top inset = 12 + 48 + 16 = **76 px**. The desktop large title (40/46; wide 44/50) starts at 76 px. On desktop, `scroll-padding-top: 76px` and `scroll-padding-bottom: 24px`.
- The desktop `edgeSoft` plateau runs from 0 to 60 px, then fades over 24 px.
- When the toolbar's controls do not fit (Library below 900 px of content width: search, five chips, sort, density), the status chips fold into a "Filters" menu, and the search well becomes a 44 px icon button that expands to 240 px on focus.

### WEB-4 · medium · One grid rule and correct rail counts

- **In §7.8, one grid rule:** grids are `grid-template-columns: repeat(auto-fill, minmax(var(--grid-min), 1fr))` with a 20 px gap (`s7`) on tablet and desktop and 12 px on phone.
- **`--grid-min`:** 148 px on tablet; 152 px on desktop and wide at Comfortable density; 112 px at Compact. The Search section grids use the 112 px result card (§7.7).
- **Resulting Comfortable columns:** 5 at 1024 px (156 px posters, collapsed sidebar), 6 at 1440 px (159 px), 8 at 1920 px (153 px).
- **Per-screen counts:** replace them in §8.9 (line 2260), §8.11 (line 2282), §8.17 (line 2586) and §8.19 (line 2619) with "columns per §7.8".
- **Content width:** state it once. `W = min(viewport − sidebarOffset, contentMax) − 2 × margin`, where `sidebarOffset` is 304 (expanded) or 100 (collapsed) and `margin` is 32 (desktop) or 40 (wide).
- **Rails** keep §7.8's 168 px (desktop) and 184 px (wide) posters with a 16 px gap. Replace line 2243's "Rails show 7 (1440 px) to 9 (1920 px) posters" with "Rails show about 4.8 posters at 1024 px, 5.4 at 1440 px and 6.9 at 1920 px; the last one peeks".

### WEB-5 · medium · Desktop form, size and position of every sheet

Add to §7.10 a **Desktop form** table and size rules:

- **440 px right panel:** `filters`, `manage-tags`, `audiobook`, and `voices`, `cast` and `soundscape` when opened outside a reader (book page ⋯, the listen player's ⋯, Settings). Inside a desktop reader, these stay in the reader's own right panel.
- **560 px window:** `tags`, `add-series`, `collection-new`, `collection-share`, `recommend`, `letter-note`, `note`, `whats-new`, `shortcuts`, `save-files`, `offer`, `app-update`, plus those already stated (`run`, `licenses`, `how-it-works`, `collection-edit`, the recap, the friend, the profile form).
- **Panels:** full window height minus the 12 px insets. The header is sticky at 56 px, and the body scrolls.
- **Windows:** centred horizontally on the content column. The top sits at `max(12vh, 48px)`, `max-height: min(80dvh, 880px)`, the header is sticky at 56 px, and the body scrolls.
- **The 960 px series window:** top 24 px, `height: calc(100dvh - 48px)`. The window itself is the scroll container, so the left column's `position: sticky; top: 24px` works.
- **Palette:** `max-height: 70vh`. The results list scrolls between the 56 px field and the 32 px footer (`max-height: calc(70vh - 88px)`).
- **Stacking:** a panel or window opened from inside the series window stacks over it (the two-sheet limit of §7.10).

### WEB-6 · medium · Desktop and desktop-reader positions of the floating layers

- **New-chapters capsule (desktop and tablet):** top-centre of the content column, 12 px below the toolbar row (top 72 px), max width 480 px. On desktop it shares one queue with toasts: a toast waits while the capsule shows, which keeps the budget at 6.
- **Status capsule ("Offline", "Saved copy", "Syncing") on desktop:** in the toolbar row, 12 px after the page title, or at the toolbar's leading edge while the large title is still visible. It is 32 px tall and drawn inside the toolbar's single masked glass element, so it adds nothing to the budget.
- **Bulk-selection toolbar and "Unsaved changes" bar on desktop:**
  - They sit fixed at `bottom: 24px`, centred on the content column, max width 720 px, 52 px tall.
  - While either shows, toasts rise to `bottom: 88px` (24 + 52 + 12) and the app-update capsule waits, so the desktop budget stays at 6: sidebar, toolbar group, bar, toast, palette or window or panel, and menu.
- **Toasts inside the desktop readers:** top-centre, 60 px from the top (below the 8 + 44 px top chrome band, as on phones), never bottom-left.

### WEB-7 · medium · Key collisions

- **Book page (§8.13):** drop `g`. `/` focuses the go-to field, as on §8.12.
- **Series detail (§8.12):** `d` downloads the focused chapter row (the global row action). `shift+d` downloads the next 10.
- **Reorder:**
  - `alt+↑/↓` moves one slot vertically, `alt+shift+←/→` moves one slot horizontally in grids, and `alt+shift+↑/↓` moves to the top or bottom.
  - Bare `alt+←/→` is never bound, because it stays the browser's back and forward.
  - Update §7.35 (line 1863), §8.0.6 (line 2069) and §11 (line 3473).
- **Search (§8.9):** `shift+j` / `shift+k` jump between source groups. Bare `h j k l` stay grid movement.
- **Circle (§9.3):** drop `l`. Tabs are `[` / `]`.
- **Manga reader (§8.14.2 keys, §8.14.11):** `o` toggles the dialogue overlay and, when the right panel is open, also switches it to its Dialogue tab. `shift+o` opens the right panel on its Dialogue tab without the overlay. Change line 2431 to "`,`, `shift+o` and `shift+c` open them".

### WEB-8 · low · Platform key matching, labels and the `allowInInput` set

- `alt+` combinations match on `event.code` (`Digit1` to `Digit3`, `KeyX`), a change to the shared `lib/keyboard/match.ts`, because `event.key` for Option+1 on macOS is "¡".
- "Remove" (`Delete` in §8.0.6, §8.17, §8.18, §9.1.2) is bound to `Delete` or `Backspace`. Backspace counts only when focus is not in a field.
- Every visible shortcut string, including the sidebar capsule ("Search  ⌘K", lines 1522 and 1659) and the 404 hint (line 2836), renders through the shared `formatKeyCombo`: "⌘K" on macOS, "Ctrl K" elsewhere.
- List the set in §8.0.6: `allowInInput` = `mod+k`, `mod+b` and `Esc`. No single key and no other combination fires while focus is in an `input`, `textarea`, `select` or `[contenteditable]`. The Ask box's own Enter handler belongs to the field, not the registry.

### WEB-9 · medium · Hold-to-confirm: click versus aborted hold, and holds inside alerts

Replace the release sentence and the **Alternative** of §7.1 (line 1482):

- **Starting the fill:** pointer down starts the fill only after 200 ms.
- **A click:** a release before 200 ms with less than 8 px of movement is a click.
- **An aborted hold:** a release between 200 and 1200 ms drains the fill on `dismiss` and shows the helper line "Keep holding, or click once to confirm" in `footnote` `label2` for 2 s.
- **Keyboard:** Enter or Space is always treated as a click.
- **Outside an alert** (sign out everywhere, delete collection, remove all downloads, and so on), a click opens the §7.11 confirm alert with an explicit confirm button.
- **Inside an alert** (the 18+ gate, line 1776; delete profile; delete member), the alert always shows, visibly and to everyone, the explicit confirm button ("I am 18 or older, enable") as a secondary button under the hold button. A click on the hold button moves focus to that button and shows the helper "Hold, or use the button below"; it never opens a second alert. Rewrite line 1776's last sentence to say this, since the web cannot detect a screen reader.

### WEB-10 · medium · Web semantics for select mode and toggle buttons

- **Select mode (§7.35):**
  - The grid or list becomes `role="group"` with `aria-label="Select series"` ("Select chapters", "Select downloads"). Each item becomes `role="checkbox"` with `aria-checked`, and its link `href` is suspended.
  - Space and Enter both toggle, and Enter never opens while selecting. `shift+Space` selects the range from the last toggled item (as `shift+x`).
  - Already-saved chapter rows are `aria-disabled="true"`, with "Already on this device" in `aria-describedby`.
  - A polite live region announces "{n} selected" after each change.
- **Toggle buttons with a constant label** (favourite star, pin, notify bell, bookmark, reaction, the password eye) carry `aria-pressed`, with a fixed accessible name ("Favourite", "Pin source", "Notify me", "Bookmark", "Show password").
  - Change line 1510 to a fixed label "Show password" with `aria-pressed`.
- **Toggle buttons whose visible label changes** ("Add to library" / "In library") take no `aria-pressed`, and their accessible name follows the visible label (WCAG 2.5.3).
- **Menu toggles** ("Hide from my Circle", Content rating) are `role="menuitemcheckbox"` with `aria-checked`.

### WEB-11 · medium · Desktop reader side panels: fit, focus and Esc

In §8.14.11 and §8.15.2:

- **Fit, manga.** While panels are open, the strip is `min(clamp(480px, 50vw, 900px), viewport − Σ(open panel width + 24) − 24)`. If that would fall below 480 px, opening a second panel closes the first with the same `sheet` spring and a `caption1` toast "One panel at a time at this window size". With both panels (708 px) this allows both from 1212 px, and the strip narrows instead of being covered.
- **Fit, novel.** The column renders at `min(measure, viewport − Σ(open panel width + 24) − 40)` and re-flows around the current paragraph anchor. The user's stored measure is unchanged. If the column would fall below 48 ch at the current size, opening a second panel closes the first.
- **Semantics.** Panels are non-modal `<aside>` landmarks (`role="complementary"`) labelled "Chapters" and "Reader settings" (novel: "Contents" and "Type, voices and listen").
- **Focus.**
  - Opening a panel by key (`t`, `,`, `shift+o`, `shift+c`, `v`) moves focus to its current row or first control. Opening one by pointer leaves focus where it was.
  - `F6` / `shift+F6` cycle strip (or column) → left panel → right panel.
  - Esc inside a panel closes it and returns focus to the strip.
- **Esc order** (line 2408 and the novel keys): menu or popover → panel → fullscreen → cinema → leave the reader.

### WEB-12 · medium · Floating chrome while the on-screen keyboard is open

In §7.15 **Hidden**:

- **Web.** While an `input`, `textarea` or `[contenteditable]` other than the orb's search field has focus under `(pointer: coarse)`, the dock, orb, accessory, bulk toolbar and "Unsaved changes" bar dematerialise (`dematerialize`, 350 ms) and become `inert`. They return 100 ms after the last `focusout`.
- **Flutter.** The same happens while `MediaQuery.viewInsetsOf(context).bottom > 0`.
- **Meanwhile** the bottom scroll inset drops to safe area + 16 px, and the focused field scrolls into view with `scroll-padding-bottom: 16px` (Flutter: `Scrollable.ensureVisible` with 16 px).

### WEB-13 · medium · Long-press hygiene on mobile web

- **Every long-press target** listed in §11 (posters, rows, chapter rows, cards, history tiles, orbs, dock tabs, the back button, Continue buttons, the reaction button, the hero card) gets `-webkit-touch-callout: none; -webkit-user-select: none; user-select: none` and stays a real `<a href>` or `<button>`. Extend line 2099 to say so.
- **Android context menu.** Glass calls `preventDefault()` on `contextmenu` when the preceding `pointerdown` had `pointerType === "touch"`, which suppresses Android Chrome's link menu.
- **Who owns long-press.** Glass's own 150 / 450 ms timer owns touch long-press and opens the Base UI `Menu` in controlled mode, anchored to the lifted item. Base UI `ContextMenu` handles only right-click and `shift+F10` / the Menu key.
- **Novel reader on mobile web.** The native selection toolbar is kept (it owns Copy). Glass's other actions (Bookmark this paragraph, Play from here, React, Recommend) appear in a `glassThick` action capsule that replaces the bottom capsule while a selection exists, so nothing sits over the selection toolbar or the handles. It is dismissed when the selection clears. Apps and desktop keep the menu above the selection as in line 2476.

### WEB-14 · low · Pinch outside the manga reader on mobile web

- Change the `@use-gesture/react` note in §15.2 (line 3805) and the ledger row (line 4022) to "reader, Library grid, novel column and guided-view pinch".
- Set `touch-action: pan-x pan-y` on the Library grid, the novel column and the guided-view camera, so these pinches reach the app. Browser pinch-zoom stays available everywhere else.
- The grid and novel pinch are ignored while `visualViewport.scale > 1`.

### WEB-15 · low · Desktop rail arrows are content twins, not glass

Replace line 1582's "glass arrow buttons (44 `glassThin` circles)" with content-twin arrows (§2.4.1 rule 1):

- **Shape:** 44 px circles with a `rgba(19,19,23,0.62)` fill, a 0.5 px `rgba(255,255,255,0.22)` rim and the inner light, and no backdrop read.
- **Hover:** the fill brightens to `rgba(40,40,48,0.72)`.
- **Show and hide:** they fade in over `fadeIn` when the pointer enters the rail and fade out 300 ms after it leaves.
- **Budget:** they do not count toward the budget.

### WEB-16 · low · Poster corner conflicts on hover and in select mode

- **On desktop hover and on keyboard focus:** the status tag and "N new" badge fade out over 120 ms while the favourite star (top-left, 8 px inset) and follow bell (top-right, 8 px inset) fade in. The 18+ capsule moves to the bottom-right while the buttons show.
- **In select mode:** the status tag, "N new" badge, star and bell are hidden (as inventory LB13), and the check orb takes the top-right. The new-chapter count stays in the accessible name ("Solo Leveling, 3 new").

### WEB-17 · low · Tabs versus segmented controls

- **Updates and Statistics** use the §7.6 segmented control (`role="tablist"`, no pager, no swipe). Remove them from §7.13 "Where" (line 1619) and from the §11 horizontal-swipe row (line 3478).
- **Desktop Search scopes** are a vertical list in the 220 px column:
  - 40 px rows, `role="tablist"` with `aria-orientation="vertical"`.
  - The `glassThin` droplet indicator travels vertically on `tab`, and `↑`/`↓` move between scopes.
  - Add this vertical variant to §7.6 and remove "Search scopes on desktop" from line 1619.
- **Downloads** order is Chapters · Queue · Storage everywhere (line 1619 corrected).

### WEB-18 · low · Focus scale and a focus glow that keeps the glass shadow

- The keyboard focus scale is 1.04 for posters and cards alike; change "scale 1.03" in §7.7 (line 1565).
- On glass surfaces, `:focus-visible` appends to the surface's own shadow list instead of replacing it: `box-shadow: 0 0 0 2px #000, 0 0 0 6px rgba(188,176,255,0.28), var(--glass-shadow), var(--glass-inner-light)`, with the outline ring unchanged.
- The Tailwind `focus-visible:shadow-(--mm-focus-glow)` utility of line 709 is for content-layer elements only; say so in that row.

### WEB-19 · low · `/more` without a viewport redirect

- `/more` renders the You screen at every width, and no viewport-dependent redirect exists.
- **Desktop and tablet layout:** the profile block and cards in two columns, at most 880 px wide and centred, with the grouped lists beneath.
- Fix §8.0.3 (line 1998) and §8.24 (line 2679).

### WEB-20 · low · Pointer cursors

Add a cursor table to §7 (web only):

| Cursor | Where |
|---|---|
| `pointer` | Every activatable element, including buttons (Tailwind 4 preflight resets them to `default`), posters, cards, rows, orbs and chips |
| `grab` / `grabbing` | Reorder handles, the speed dial, the voice orbit, slider and switch thumbs, and the spotlight card |
| `ns-resize` | The reader's scrub rail |
| `zoom-in` / `zoom-out` | The image viewer: `zoom-in` at 1×, `zoom-out` when zoomed in |
| `text` | The novel column and fields |
| `none` | Over the manga strip after 3000 ms without pointer movement while the chrome is hidden; restored on move |
| `all-scroll` | While the middle-click autoscroll anchor is active |
| `not-allowed` | Disabled controls |

### WEB-21 · low · Settings search on desktop

In §8.25 **Desktop**:

- A 36 px `fill3` search capsule, "Search settings", heads the 240 px section list.
- Typing replaces the section list in place with the matching rows, grouped by section. When nothing matches it shows "No settings match “{q}”".
- Enter, or a click on a result, opens that section at right and flashes the row (Row pulse, §4.10).
- Esc clears the field and restores the list, and `/` focuses the field.
