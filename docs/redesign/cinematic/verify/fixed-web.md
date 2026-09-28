# Cinematic DESIGN.md: fixes applied from the web coverage judge

## Round 1

Source: `cinematic/verify/judge-web.md`, section "Confirmed" (33 findings; WEB-23 and WEB-31 were refuted and are not applied). Every fix was applied as the judge rewrote it, except where noted. Section numbers refer to `cinematic/DESIGN.md`.

| ID | Sections changed |
|---|---|
| WEB-1 | §8.14.3 Auto-hide (reveal keys limited to `g` `,` `[` `]` `?` and focus entering the chrome; every other reader key listed as never revealing; auto-hide suspended while the chrome holds focus, focus moved to the reading surface before a hide); §14.4 Route changes (reader routes focus the reading surface, `role="region"`, plus a polite live region announcing the chapter) |
| WEB-2 | §1 Breakpoints (spine 768–1279, 8-column grid 768–1023); §7.15 Width (auto-spine 768–1279, expanded from 1280) and new rows `Below 1280` (overlay at `z.panel` over `scrim.modal`, `localStorage['mm.sidebar']`) and `Collapse toggle`; §8.0.1 Desktop frame row; §8.0.9 intro. **Note:** this supersedes the 768–1023 range that CONSISTENCY-4 wrote into §7.15 earlier in this round; every spine mention now reads 768–1279. |
| WEB-3 | §8.33.3 banner anchor (bottom-left of the content column, max 560); §7.11 new `Reader and Page frames` row |
| WEB-4 | §7.7 Wall caption mode (onboarding only); §8.22 Grid (caption mode Below, title 2 lines, no folio line) |
| WEB-5 | §8.8 Scrub the trailer (breadcrumb hides with the pinned strip; below 1440 the search trigger collapses and `Previously on` moves to an overflow; phone-frame strip layout) |
| WEB-6 | §8.0.1 line under the frames table (spine kept at any height; below 500 px the section list scrolls and footer items fold into `dots-three`) |
| WEB-7 | §7.15 new route table (which item lights, what the breadcrumb names) and the rule for feature, book and recap pages |
| WEB-8 | §8.0.6 new "The `g` sequence" paragraph (1500 ms arm, 600 ms second-digit wait, keycap chip, swallowed digits); §7.15 Folio jump row points at it |
| WEB-9 | §8.0.6 new "`Delete`" paragraph (`Delete` or `Backspace`, `⌫` / `Del` keycap) |
| WEB-10 | §8.23 new "Web activity and removal" paragraph (worker `mm-offline/state`, `Stop` / `Stop all`, no pause, deferred `remove-chapter` with 8000 ms Undo); §8.23 Keys (`p` app-only) |
| WEB-11 | §8.9 Phone layout (density counts per row, phone LIST row, COMPACT without captions) |
| WEB-12 | §7.7 corner rule and new state rows (Select mode unselected, Hover icons, Manual order handle, Favourited at rest); §8.9 Card behaviour and Manual order bullet point at them |
| WEB-13 | §8.10 Keys (`r` reloads, `c` runs Check now) |
| WEB-14 | §8.17 item 3 (At a glance aside from 1024 px, sticky offset `calc(56px + 48px + 16px)`) |
| WEB-15 | §8.14.12 new "Narrow desktops" bullet; §8.14.1 Desktop web row ("never less than 480 px") |
| WEB-16 | §8.14.11 new `Next chapter loading (strip)` row |
| WEB-17 | §7.10 arm-delay list (remove from library dropped) and new `Single unfollow` row |
| WEB-18 | §8.30.2 row 10 (web haptics switch, `localStorage['mm.haptics']`, `Feel it` app-only); §5 intro (web calls gated by the switch); §15.2 `haptics.ts` row |
| WEB-19 | §8.14.8 new `CONTROLS` Fullscreen (web) row; §8.15.5 new Fullscreen (web) row; §8.15.3 Top bar (`corners-out` / `corners-in` before `text-aa` on desktop) |
| WEB-20 | §8.0.5 Long-press on images row (callout suppression extended to every long-press target, `contextmenu` `preventDefault()`) |
| WEB-21 | §7 preamble new "Cursors (web)" bullet |
| WEB-22 | §8.14.5 new desktop click vs double-click bullet (250 ms, 24 px) |
| WEB-24 | §7.6 Letter card states; §8.20 genre tiles; §8.8 `Sources` hub tiles; §8.24 new Block states bullet; §9.3.2 dispatch rows; §7.21 Checkbox and Radio hover; §7.13 breadcrumb segments |
| WEB-25 | §8.30.1 new "Pushed pages on desktop" and "Folios" paragraphs |
| WEB-26 | §7.13 profile chip avatar 32 px. The "`type.ui` 15" in §7.11 and §7.13 had already been removed before this round reached it. |
| WEB-27 | §9.1.3 Picks aside at 1024–1439; §8.10 Updates aside (non-admins: none, columns 9–12 empty) |
| WEB-28 | §7.8 Preview slate row (centred then clamped 24 px inside the content columns). The focus half was already specified in the `Slate focus` row. |
| WEB-29 | §15.2 View transitions paragraph (`experimental: { viewTransition: true }`); §15.2 new "Web app manifest" paragraph (`src/app/manifest.ts`, `orientation` deleted); §12.3 Web bullet. The redirect gate was already in §15.2 "Home route" (two-cookie `missing` list), so it was not rewritten. |
| WEB-30 | §8.30.2 row 12 (registry groups: General, Navigation, one per screen in sidebar order, then Series page, Reader, Novel reader, Listen, Recap, The Annual); §8.33.2 points at it |
| WEB-32 | §7.26 (platform rule for shortcuts in copy); §7.13 search trigger; §8.32 404 deck (`Ctrl K` off Mac; phone-frame sentence) |
| WEB-33 | §8.15.5 desktop popover max height and sticky kicker; §8.15.3 desktop pointer reveal and click-vs-selection rule |
| WEB-34 | §8.9 toolbar `Clear filters`; §8.9 Continue reading as a 12-cutting rail; §8.0.3 `library` route note (`/library/browse` opens Filters on phones) |
| WEB-35 | §8.33.4 exclusion list |

Coverage appendix: no screens were added or removed, so Appendix B is unchanged.

## Round 2

Source: `cinematic/verify/recheck-web-1.md` (31 resolved, 2 unresolved) and `cinematic/verify/judge-web.md` "Confirmed". The 31 resolved fixes were spot-checked by marker grep on the live file and are still in place, so only the two open findings were rewritten, plus two consistency follow-ups the recheck noted for WEB-16 and WEB-22.

| ID | Sections changed |
|---|---|
| WEB-1 | §14.4 Route changes: one announcement string, "Chapter 143, The Return · Solo Leveling" (chapter number, chapter title, series title; the title part is dropped when the chapter has none), with the reading-surface `aria-label` example moved to chapter 143 to match; the bullet says it is the only chapter announcement string. §14.5: the reader announces chapter changes through the §14.4 live region with the §14.4 string (the old "Chapter 143, The Return" format is gone). |
| WEB-30 | §8.30.2 row 12: registry groups reordered to the §7.15 sidebar order (Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status), with a note that Sources and Catalogue sit under Discover as in the §7.15 route table. §8.33.2 already points at row 12 and needed no change. |
| WEB-16 (follow-up) | §9.4.1 Chapter boundaries: continuous auto-scroll still rolls through seams but pauses at an unloaded next chapter (the §8.14.11 `Next chapter loading (strip)` band) and resumes when its pages land. |
| WEB-22 (follow-up) | §8.14.10 Gestures by platform, Double tap row, and §11 gesture matrix, Double tap / Reader row: the desktop column now carries the §8.14.5 exception (250 ms / 24 px click rule in the strip; a double-click on a paged side zone turns two pages and never zooms). |

Not changed: the §8.23 web status "Paused — this browser is out of room" is quoted from the inventory as a worker quota state, not a control, so it stays. The §8.33.3 Updates/novel-reader wording predates the web fixes and belongs to another lens.

Coverage appendix: no screens were added or removed, so Appendix B is unchanged.
