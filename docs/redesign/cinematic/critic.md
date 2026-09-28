# Cinematic DESIGN.md: completeness critique

Reviewed 2026-09-28 against `inventory/web.md` (32 screens, 503 rows, K1–K51), `inventory/mobile.md` (34 screens, 496 items, K01–K40), `inventory/capabilities.md` (111 endpoints), `inventory/00-decisions.md` and `stack-decision.md`. Every section of `cinematic/DESIGN.md` (3,627 lines, §1–§15 and Appendix A) was read. Contrast figures were recomputed with the WCAG 2.x formula.

The contract is unusually complete: every inventory screen has a home, every screen names its states, and the four new features have routes, entry points and backend contracts. What follows is only what is missing, vague, wrong or in conflict. Each item has a severity, the evidence, and a concrete fix.

Severity scale:
- **high**: blocks a release, breaks a binding owner decision or the stack decision, leaks gated content, or ships a signature animation that does not work as written.
- **medium**: an implementer has to invent behaviour, a state or a number, or two sections disagree.
- **low**: polish, copy, or an edge case.

Totals: 5 high, 36 medium, 36 low. A few cross-references (AC1, T2, SE1, DL1) point back to an item in another section and are not counted again.

---

## 0. Cross-cutting

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| X1 | **high** | **Nothing says what the edition picker does before Glass exists.** The stack decision ships Cinematic first, then the new features on Cinematic, then Glass (stack §4 risk 12), and the Cinematic flip release deletes `legacy`. But the edition picker (§8.30.3), onboarding step 1 (§8.7), the profile form's `Skin` row (§8.6), the command palette's `EDITION` group (§8.33.1), the Settings footer ("Changing the edition restarts the app") and the picker's restart-into-Glass (§8.5 step 4) all assume Glass can be chosen. The interim "debug row in Settings" from the stack's release model is not specified either. | stack-decision §3 "Release model", §4 #12 | Add a `glass_available` build flag (contract.json). While it is false: hide onboarding step 1 (4 steps, folio `1 / 4`), hide the profile-form `Skin` row and the palette `EDITION` group, and render the Glass card in Appearance → Edition as a disabled plate with kicker `NEXT ISSUE` and no preview iframe. Specify the debug-only `legacy` row under Settings → Diagnostics (app) or `?debug=1` (web). |
| X2 | **high** | **`ink.45` fails WCAG AA on every raised surface.** §14.2 and §15.7 claim `ink.45` text is ≥ 4.5:1 on `#000`, `paper.1` and `paper.2`. Recomputed: 4.70 on `#000000`, **4.41 on `paper.1`, 4.20 on `paper.2`, 3.90 on `paper.3`, 3.56 on `paper.4`**. `ink.45` is used for sheet kickers and input labels and placeholders inside sheets (`paper.2`, §7.3, §7.9), command-palette subtitles (`paper.2`), poster title cards (`paper.1`, §7.7), captions on selected or pressed rows (`paper.3`, §7.16) and menu shortcut text on hover (`paper.4`). | §2.1.1, §14.2, §15.7 | Rule: on `paper.1`–`paper.4`, secondary text uses `ink.60` (≥ 5.45:1 on all of them), or add a token `ink.50` `#8C897F` (6.00 / 5.63 / 5.36 / 4.98 / 4.54 on paper 0–4). Correct §14.2 and §15.7, and add a surface × ink pair loop to `tint.test.ts` and `tint_test.dart`. |
| X3 | **high** | **Downloaded and locally cached 18+ content survives the gate closing.** §7.24 only invalidates "every mature-gated query root". Local stores are not queries and are not server-filtered: the mobile sqflite downloads, the offline bookmark store, the offline follow cache (`manhwamaniacs:followed-series`), the web SW index and page cache, and the offline editions of Tonight (§8.8 "Saved on this device"), Library and Downloads. They would still draw mature series, which breaks "absence, never a lock". | §7.24, §8.8 offline, §8.23; capabilities §1 | Store `mature` / resolved `rating` with every local row (series and chapter). Every local read filters on the active profile's gate, and turning the gate off keeps the files but hides them. Show no caption or count about the hidden files, because either would reveal them. State that this filter runs client-side on both clients. |
| X4 | medium | **Per-page palettes contradict the stack decision.** The stack puts "per-cover and per-page dynamic palettes" on the backend (§2.6 item 2: logic that must agree across web and mobile). The design makes client-side sampling the primary path (§2.1.5, Appendix A graft 1), with two pickers kept in step by tests, and the backend only caches client reports. | stack §2.6; DESIGN §2.1.5, §9.4.4, §15.4 | Either record an explicit amendment to stack §2.6 (owner sign-off: "per-page tint is client-side, cover ambient stays server-side"), or make the backend the source and the client a fallback. Do not leave the conflict silent. |
| X5 | medium | **Stop the press does not match the stack's outgoing animation or budget.** Stack §2.5 says "Cinematic: 500 ms fade to `#000000` with the wordmark". The design uses ≤ 1,100–1,200 ms (§8.30.3), which leaves ≤ 300–400 ms of the 1.5 s confirm-to-splash budget for `location.replace` plus RSC and font load (web) or `AppRestart` plus provider rebuild (Flutter). Nothing says what happens if the budget is missed. | stack §2.5 step 4 and step 8; DESIGN §8.30.3, §4.5 | Either amend stack §2.5, or cut the sequence to 500 ms (rack 0–160, blades 80–456, masthead cut in at 456, restart at 500). Add a motion-timings overlay entry `SKIN RESTART` measured from confirm to the first splash frame, with a 1,500 ms budget. |
| X6 | medium | **Dependencies go beyond the stack's pinned list.** Web adds `@phosphor-icons/react` 2.1.10 and `@use-gesture/react` 10.3.1. Flutter adds `phosphor_flutter` 2.1.0, `flutter_soloud` 5.1.4, `audio_service` 0.18.19, `flutter_dynamic_icon_plus` 1.4.1, `custom_refresh_indicator` 4.0.2, `flutter_reorderable_grid_view` 5.7.0, `flutter_slidable` 4.0.3, `share_plus` 13.3.0, `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8. None of these was checked against the stack's constraint (resolves on Flutter 3.44.6 with `go_router` ≤ 17.5). Shake-to-extend (§8.16.6) also needs a sensor package that is not named anywhere (`sensors_plus` 7.1.0 in research). | stack §3 "Dependency changes"; DESIGN §15.2, §15.3 | Add a dependency ledger table to §15 (package, version, licence, native or pure Dart, why, stack status) and a one-off `flutter pub get` resolution check in CI. Add `sensors_plus` 7.1.0, or drop shake-to-extend. |
| X7 | medium | **The token source has two schemas.** §2.8 keys are `dur.*`, `ease.*`, `spring.*` and `motion.stagger.*`. The §15.1 JSON uses `motion.settle {ms, bezier}`, `letter {ms, blurMs, stagger, staggerCap}`, `paceByDialogue {...}` and `holdPanel {...}`. Stack §2.1 allows motion tokens that are only springs `{ms, bounce}` or curves `{ms, bezier}`. `"streak.milestone": "ahap:ignite+stamp"` is a compound pattern the generator has no rule for. §2.8's CI grep for Tailwind utilities is also beyond the stack's "~150 lines" `build.mjs`. | §2.8.4, §15.1; stack §2.1 | Rewrite §15.1 in the §2.8 key space (`dur`, `ease`, `spring` and a `scalar` group for letter rise, rubber, stagger and pace constants), and extend stack §2.1 with a `scalar` token kind. Define compound haptics as `["ahap:ignite", {"after": 520, "then": "ahap:stamp"}]`. |
| X8 | medium | **Profile-scoped first-paint attributes have no source.** §3.4 says `data-legible` is "stamped server-side from the profile payload alongside `data-skin`", and §14.1 does the same for `data-motion` ("Reduce motion in the app", per profile). The server has no profile at SSR: stack §2.4 gives it only the `mm-skin` cookie, which "holds only the last active profile's skin, never profile data". | §3.4, §14.1; stack §2.4 | Pick one: (a) a second device cookie `mm-a11y=legible,motion` mirrored like `mm-skin`, with an explicit amendment to stack §2.4, or (b) stamp both from `features/preferences/appearance-boot-source.ts` before paint. Specify the flash behaviour if neither is present. |
| X9 | low | **Web haptics contradict the stack.** Stack §2.1 says "the web maps them to nothing". §5, §8.0.5 and §15.2 map five events to `navigator.vibrate` on Android Chrome. | stack §2.1 | Amend one of the two documents. |
| X10 | medium | **ScreenId completeness does not hold on the web.** Stack §2.2 makes `screens` `satisfies Record<ScreenId, Screen>` on each skin, but `setup` is "App only" (§8.0.3). | stack §2.2; DESIGN §8.0.3 | Split into `SCREEN_IDS_COMMON`, `SCREEN_IDS_APP` and `SCREEN_IDS_WEB` in `contract.json`, or ship a web `setup` that redirects to `/login`. |
| X11 | medium | **The new screens do not say whether they follow the content mode.** The inventory lists what Manga/Novels filters today (mobile G5: Library, Sources, Search, Downloads, Updates, History, Bookmarks, Stats, Collections). The design has no rule for Tonight, Picks, Circle, The Annual or recaps, and no layout for a novel as Tonight's cover story (the book page has "no spread art", §8.18). | mobile G5; DESIGN §8.8, §8.18 | Add a table: Tonight follows the mode (the cover story and rails from that mode only); Picks, Circle and The Annual are mode-agnostic. Specify a typographic cover story for novels (the Bodoni title-page set of §8.18 in the 5 text columns, with the 168 × 248 plate centred in the art columns over `blur.bleed`). |

## 1. Signature animations (binding, §10)

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| A1 | **high** | **The Flutter heading reveal cancels itself.** `SetHeading.build` calls `ref.watch(seenHeadingsProvider)` and then schedules `Future.microtask(() => ...update((s) => {...s, id}))`. The update rebuilds the widget, `seen.contains(id)` is now true, and the animated `Wrap` is replaced by the static `Text` one frame later, so the reveal never plays. It also marks the heading seen at build time, which in slivers happens up to `cacheExtent` before the heading is visible, while the spec says "when 50 % in view". | §10.1.6, §10.1.1 Trigger | Read with `ref.read` inside `initState` of a `StatefulWidget` (`_seenAtMount`). Add the id in the last letter's `onComplete`. Gate the start on a visibility check (`VisibilityDetector` at 0.5, or a `SliverLayoutBuilder` visible-fraction check). Add a widget test that pumps 1,300 ms and asserts letters were at opacity < 1 at t = 100 ms. |
| A2 | medium | **Skipping the web typing reveal does not work, and the keyboard cannot reach it.** `useTyped`'s `skip()` calls `setN(chars.length)` but leaves the `requestAnimationFrame` loop running, and the next `tick` sets `n` back to `floor(elapsed / 50)`. The text flashes complete for one frame and then keeps typing. `tabIndex={-1}` also means Tab never reaches the `<h1>`, so "Enter or Space completes it" (§4.7, §10.2.1, §8.8 keys) cannot happen. | §10.2.3 | Keep a `skipped` ref that the tick checks, and `cancelAnimationFrame` on skip. Make the headline container `tabIndex={0}` while typing (and `-1` once done), or bind `Enter` at page level through the key registry. |
| A3 | low | **Small mismatches between the clients.** Flutter's `slideY(begin: .42)` is a fraction of the glyph box height (about 1.0–1.17 em), not 0.42 em. The Column-wipe route durations are 900 / 620 ms in Flutter against 872 / 616 ms on the web. | §10.1.6, §8.14.2 | Use `moveY(begin: 0.42 * fontSize)`. Set the route durations to 872 / 616 ms. |

## 2. Motion and reduced motion

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| MO1 | medium | **The "authoritative" reduced-motion table (§4.8) misses named motions from §7–§9.** Missing: the thumb-notch and tab-rule slides (320 ms), sidebar width (320 ms), menu clip reveal (200 ms), toast rise (160 ms), chrome 8 px slide, preview-slate grow (320 ms), Circle letter unfold (480 ms), Index dot-leader draw (320 ms), the Listen and dialogue highlighter sweeps (200 ms), rail paddle paging (560 ms), programmatic smooth scrolls (scroll-to-top 400 ms, rail focus 320 ms, transcript follow 400 ms, tap-to-scroll 300 ms, settings search jump), and poster press scale 0.98. | §4.8 vs §7.8, §7.11, §7.14, §7.15, §7.22, §8.16.3, §8.24, §8.28, §9.3.2 | Add each as a row. The rule of thumb in §14.1 is right: slides become a 150 ms opacity change, sweeps show their end state, and scrolls jump. |
| MO2 | low | **§4.5 is not the complete move list.** The unfold, dot-leader draw, highlighter sweep, preview slate and paddle page are not named moves, so the motion-timings overlay (§15.9) cannot log them. | §4.5, §15.9 | Add them to §4.5 with names. |

## 3. Haptics and sound

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| HS1 | medium | **The event-to-cue map is incomplete and contradicts itself.** The §6 cue table does not include `skin.switch` (§8.30.3 plays `impress`) or `share.export` (§9.2.5 plays `set`). Events such as `undo`, `delete.confirm`, `chapter.next`, `listen.toggle`, `profile.select`, `sheet.detent`, `refresh.arm` and `autoscroll.*` are neither mapped nor declared silent. §15.1 lists only 4 of the 12 cues. | §6, §8.30.3, §9.2.5, §15.1 | Make §6 a full table over every haptic event in §5, with a cue or `—`. Mirror all 12 cues in §15.1 `sounds`. |
| HS2 | low | **The toggles have no stated scope.** Haptic feedback (mobile K13 is per device today) and UI sounds plus their volume: per device or per profile? | §8.30.2 row 10 | State per device for haptics and per profile for sounds (or both per device), and write it into the settings table. |

## 4. Brand assets (§12)

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| B1 | medium | **The "neutral" native splash is Cinematic's mark, and the splash and icon swap are unspecified.** §8.2 and §12.4 put `mm-mark` (the Cinematic monogram, §12.2) in a native splash "shared with the Glass skin", so Glass cannot own its launch frame. The Android 12+ system splash draws the launcher icon, which `flutter_dynamic_icon_plus` swaps per skin (§12.3), so icon and splash disagree after a switch. The Android activity-alias swap kills the task and breaks pinned shortcuts. On a shared device the icon flips on every profile switch between a Cinematic and a Glass profile. | §8.2, §12.3, §12.4 | Define a truly neutral native mark (for example a plain bone square on `#000000`) owned by neither skin, or accept one mark for both and tell the Glass contract. Specify Android behaviour: set `android:windowSplashScreenAnimatedIcon` to the neutral mark so it does not follow the alias, and change the icon only in Settings (not on a profile pick). State the iOS alert copy expectation. |
| B2 | medium | **There is no Android notification small icon.** `audio_service` (§8.16.10) needs a monochrome status-bar icon (24 dp, white on transparent, `res/drawable-*/ic_stat_mm.png`) and a notification accent colour. | §8.16.10, §12.7 | Add `ic_stat_mm` (the united monochrome monogram at 24 dp, 2 dp padding) to §12.2 and §12.7, with accent `#F4D03F`. |
| B3 | medium | **Bundled art and audio have no source or licence.** Onboarding step 4 needs "9 unlabelled panel crops from bundled sample art" (manga panels from the sources cannot be bundled). `design/previews/demo-feed.json` has "six public-domain demo covers". The soundscape loops are "CC0 or synthesis" with no chosen files. | §8.7, §8.30.3, §9.4.2 | Name the files, paths (`mobile/assets/onboarding/styles/01–09.webp`, `frontend/public/onboarding/...`), sources (public-domain comics such as Digital Comic Museum scans, or art drawn for the project) and licences, and add them to About → Licenses. |
| B4 | low | **The display name is too long for an iOS home screen.** "ManhwaManiacs" is 13 characters and truncates under an iOS icon. No PWA `short_name` or `CFBundleDisplayName` is given. The PWA `start_url` changes from `/library` (web inventory R0) to `/` (Tonight). No iOS PWA startup-image sizes or `favicon.ico` fallback are listed. | §12.3, §8.0.5 | Decide a short name (for example "Maniacs" or "MM"). List `manifest.webmanifest` fields and the startup-image set (1290 × 2796, 1179 × 2556, 1170 × 2532, 2048 × 2732). |
| B5 | low | **The ten custom glyphs are described in words only.** The monogram has grid coordinates (§12.2); `flame-1`, `flame-3`, `strip-scroll`, `panel-focus`, `bubble-search`, `certificate-18`, `voice-31`, `annual` and `highlighter` do not. | §2.7 | Give each a 256-grid construction (key points, stroke 12 at Light) or ship the SVG masters in `brand/cinematic/glyphs/`. |
| B6 | low | **Web grain has no recipe.** Flutter has `shaders/grain.frag`, but the web only says "grain at 0.06 (overlay blend)". | §8.8, §8.17, §9.2.4, §15.2 | Specify a 256 px tiling noise PNG (`frontend/src/skins/cinematic/assets/grain.png`, luminance noise σ 0.5, 8-bit) at `mix-blend-mode: overlay` with opacity 0.06, animated by `steps(4)` background-position jitter at 12 fps (static under reduced motion). |
| B7 | low | **The OG image and SideStore listing are vague.** "OG image 1200 × 630 uses the spread layout" gives no content. The SideStore source has no subtitle, screenshots or description. | §12.6, §12.3 | Specify the OG layout (wordmark at 72 px in the left 5 columns, the "Front pages" still in the right 7) and the SideStore `subtitle` / `screenshotURLs`. |

## 5. Accessibility (§14)

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| AC1 | (X2) | Contrast of `ink.45` on raised surfaces. | see X2 | |
| AC2 | medium | **The Annual on phones has only tap thirds and hold-to-pause.** There are no screen-reader actions and no visible previous/next controls, so VoiceOver and TalkBack users cannot page. The auto-advance pause for screen-reader users (§14.5) helps only if paging exists. | §9.2.4, §11 | Add `Semantics(customSemanticsActions: {Next page, Previous page, Pause})` and a web `role="group"` with `aria-roledescription="story"` plus visually hidden previous/next buttons, focusable in order. |
| AC3 | low | **The tab-bar label is small for a condensed face.** `type.nav` is 10/12 px at `wdth` 75 in `ink.45` on the tab bar. | §3.2, §7.14 | Raise the phone tab-bar label to 11/12 px, or keep inactive labels at `ink.60`. |
| AC4 | low | **Route changes have no focus rule.** Only the skip link is specified. Forced colours (`forced-colors: active`) and `prefers-contrast: more` are not handled. | §14.4 | On route change, move focus to the page `h1` (with `tabIndex=-1`) and announce the title. Under `forced-colors`, rules and focus rings use `CanvasText`. |
| AC5 | low | **Manga pages have no text alternative.** Pages are unlabelled images. When OCR text exists for the chapter, it could be the page's accessible description. | §14.5 | `aria-describedby` / `Semantics(hint:)` with that page's `page_texts` when available; otherwise "Page 18 of 40". |
| AC6 | low | **Voice samples have no caption.** `GET /novels/voices` returns `transcript`, which is not shown. | §8.16.5; capabilities §19.4 | Show the transcript under the playing row in `type.caption` (as `aria-live="polite"`). |

## 6. Platform coverage

| # | Sev | Gap | Evidence | Fix |
|---|---|---|---|---|
| P1 | medium | **Mobile web Downloads contradicts the owner.** "Desktop and mobile web layout. The same order in 12 columns" contradicts "Mobile web mirrors the phone app" and the 4-column phone grid below 768 px. | §8.23; decisions "Platforms" | Mobile web < 768 px uses the phone layout with web data (the SW meter copy, retention `2 DAYS · 7 DAYS · 30 DAYS · NEVER`, Protect storage), and the web aside stacks under the meter. |
| P2 | medium | **Most screens have no tablet layout.** The app uses the phone frame at every width on the tablet grid (§0 conventions). Tablet layouts exist only for Tonight, the reader, the catalogue and the library wall. Discover, the series page, Updates (8 + 4 aside?), Collections, Settings (TOC plus pane?), Circle, The Numbers, The Annual (a 9:16 story on a 10" screen?), Downloads and the picker have none. Landscape phones are covered only in the readers. | §8 | Add one "Tablet" line per screen: 8-column grid, whether the desktop aside appears, the sheet width (max 720), The Annual as a centred 9:16 column on black, and Settings as two panes from 900 px. |
| P3 | low | **Mobile web gesture conflicts are not handled.** iOS Safari long-press on posters opens the native image callout (needs `-webkit-touch-callout: none; user-select: none` on posters and pages). The iOS Safari edge-swipe back fights the in-reader horizontal chapter swipe (start the swipe detector 24 px in from the edge). | §11 | Add both as rules in §8.0.5. |
| P4 | low | **Desktop web Listen has no media keys.** The Media Session API is specified for mobile web only. | §8.16.10 | Use the same `navigator.mediaSession` handlers on desktop. |

---

## 7. Per screen

### 7.1 Setup (§8.1)
| # | Sev | Gap | Fix |
|---|---|---|---|
| S1 | low | **Some failure states are missing.** There is no device-offline state (no network at all), no "server reachable but not ManhwaManiacs" state (`/health` without `name`) and no TLS or certificate error copy. The HTTPS-required caption exists, but the error copy for an `http://` entry in release builds does not. | Add the three error lines under the field, for example "That address isn't a ManhwaManiacs server." and "This phone is offline. Connect, then try again." |

### 7.2 Splash (§8.2)
| # | Sev | Gap | Fix |
|---|---|---|---|
| SP1 | low | **The boot-time skin mismatch is not shown.** A remembered profile whose saved skin differs from the mirror restarts at boot (stack §2.4 step 4), but §8.2's outcomes do not show that path: pre-roll, then black, then the other skin's splash. | Add it as an outcome: the reveal is cut at the hand-off, then 200 ms of black, then restart. |

### 7.3 Login and Register (§8.3, §8.4)
| # | Sev | Gap | Fix |
|---|---|---|---|
| L1 | low | **Some server codes have no copy.** `invalid_username`, `bootstrap_window_expired`, `bootstrap_already_claimed` (capabilities §1). There is also no username-rules helper (allowed characters and length). | Write the three lines, and a helper under Username such as "3–32 letters, numbers, dots or underscores" (whatever the backend enforces). |

### 7.4 Profile picker (§8.5)
| # | Sev | Gap | Fix |
|---|---|---|---|
| PP1 | low | **Switch account has no place on phones.** `Switch account` is placed on desktop only; multi-account is a core model. | Put it in the phone running head's overflow (`dots-three` → "Switch account…", with the same dialog). |

### 7.5 Profile form and Manage (§8.6)
| # | Sev | Gap | Fix |
|---|---|---|---|
| PF1 | medium | **The `Skin` row is underspecified.** It has no control spec (segmented? cards?) and no behaviour when the edited profile is the active one: restart now through Stop the press, or on the next pick? | Use the segmented control (§7.5) `CINEMATIC │ GLASS`. If the edited profile is the active one, Save opens the §8.30.3 confirm and runs Stop the press; otherwise the change applies on the next pick. |
| PF2 | low | **Deleting the active profile has no outcome.** Nor does opening the certificate for a profile that has no name yet ("Show mature content on {profile}?"). | Deleting the active profile clears it and lands on the picker (Dip). The certificate uses "this profile" when the name is empty. |

### 7.6 Onboarding (§8.7)
| # | Sev | Gap | Fix |
|---|---|---|---|
| O1 | medium | **The section contradicts itself on the Glass restart.** Step 1 says "Choosing Glass here defers the restart to the end of onboarding", but Finish says "the restart into Glass happens on black after step 1". | Pick one (deferring is the better choice: taste is saved, then Stop the press, then Glass Tonight). |
| O2 | medium | **The 18+ gate is unspecified in onboarding.** New profiles default to gate off, so mature genres (for example Smut and Ecchi) must be absent from the genre paragraph and the seed wall. If the profile form turned the gate on first, are they included? | Genres and seeds come from gated server data, and the paragraph re-flows with 30–40 of whatever remains. |
| O3 | medium | **Some states are missing.** Loading for step 2 (format plates), step 3 (genre list) and step 5 (the wall's first page) is not specified. Resume after the app is killed mid-onboarding is not specified. Fully offline (not only "sources unreachable") is not specified. | Galley plates for steps 2 and 5, a greeked paragraph for step 3, a per-profile `onboarding_step` stored with the taste, and offline shows step 1 only, then "Finish when you're back online." |

### 7.7 Tonight (§8.8, §9.1.2)
| # | Sev | Gap | Fix |
|---|---|---|---|
| T1 | medium | **"Also in this issue" has no selection logic.** How are the three Feature cards picked, and what happens with fewer than 3? | A priority list (new chapters of a followed series, then Because you read, then a letter, then Almost there), de-duplicated against the cover story. With 2 cards: 6 + 6 columns. With 1: hide the row. |
| T2 | (X11) | Content mode, and a novel as the cover story. | see X11 | |

### 7.8 Library (§8.9)
| # | Sev | Gap | Fix |
|---|---|---|---|
| LB1 | medium | **Some sorts and filters have no backend.** Sorts `Recently read` and `Most unread` and the `NEW ONLY` filter are not supported by `GET /library/series` (sort ∈ `title, -title, sort_order, updated_at, created_at`), and are not in §15.5. Sorting client-side over the 200-row cap gives wrong results above 200 series. | Add `sort=last_read_at`, `sort=-new_count` and `new_only=true` to §15.5, or drop them. |
| LB2 | medium | **Tags are half designed.** §15.5 adds "tags on FollowedSeries list rows" for a "tag filter on the shelf", but the §8.9 toolbar has no tag filter, and there is no tag manager (rename, colour, delete through `DELETE /library/tags/{id}`) although the endpoints exist (capabilities §12). | Add a `TAGS ▾` menu to the toolbar (a multi-select slug list) and a Tags section in Settings → Reading or a feature-page `Tags…` sheet with rename and delete. |

### 7.9 Updates (§8.10)
| # | Sev | Gap | Fix |
|---|---|---|---|
| U1 | low | **Two small omissions.** `GET /updates/sources` (a source filter) is not designed, and the FOLLOWING tab has no empty state. | Add a `SOURCE ▾` compact select, and the FOLLOWING empty state "Nothing followed yet." + `Find something`. |

### 7.10 Collections (§8.11, §9.3.5)
| # | Sev | Gap | Fix |
|---|---|---|---|
| CO1 | medium | **Shared-shelf permissions are unspecified.** It does not say what a `VIEW ONLY` member sees in collection detail (which of Add, Edit, Reorder, Remove and Delete are hidden), or what the `Leave shelf` dialog says. The "Share" action when Circle sharing is off is not covered. | A table: owner has all actions; `CAN ADD` members have Add and Remove-own; `VIEW ONLY` members have none plus `Leave shelf` (arm-delay dialog). Share is hidden when the profile shares nothing, with a tooltip on the overflow item. |
| CO2 | low | **Two empty states are missing.** A smart shelf whose rules match nothing, and the plate mosaic for a shelf with zero members. | "Nothing matches these rules." + `Edit rules`; an empty plate shows the name over `paper.1` with a 1 px `rule.2` frame. |

### 7.11 History and Bookmarks (§8.12, §8.13)
| # | Sev | Gap | Fix |
|---|---|---|---|
| HB1 | low | **The note-editing call is not named.** Editing a bookmark note needs a server write. It exists as `POST /reader/bookmarks/batch` upsert with `note`, but the web client today only has `POST /reader/bookmark` and `DELETE`. | Name the call in §8.13 (web and mobile both use the batch upsert). |

### 7.12 Manga reader (§8.14)
| # | Sev | Gap | Fix |
|---|---|---|---|
| R1 | medium | **Phones and tablets have no chapter list inside the reader.** The Contents side panel is desktop only (§8.14.12). Phones and tablets get only previous/next and title → series page. The Webtoon reference has an in-reader episode list. | A `list-numbers` icon in the phone running head opens a `[0.5, 0.92]` Contents sheet with schedule rows (the current row in `spot.wash`, go-to field), and the same control opens the column panel on tablets. |
| R2 | medium | **Brightness and warmth are vague.** Brightness −75…100 defines only negative values (a black overlay). Positive values are not defined (screen brightness through a plugin? impossible on the web). Warmth 0–100 has no colour, maximum alpha or blend (mobile today uses `#FF8A00` up to 92 alpha; the web uses primary × 0.55). | Either limit brightness to −75…0 on the web and use `screen_brightness` (pin a version) on the app for 1…100, or drop positive values. Warmth: an overlay of `#FF8A00` at `v/100 × 0.36` alpha with `mix-blend-mode: multiply`, the same on both clients. |
| R3 | medium | **Unavailable-content states are missing.** `series_not_found`, `source_not_found` (a connector deleted under the "remove dead sources" rule), `source_not_browsable`, and a deep link, notification, bookmark, history row or letter that points at 18+ content after the gate closed. Today these would fall into the generic error "The source did not answer", which misstates the cause. | A `NOT IN THIS ISSUE` notice, "This series isn't available here any more." + `Back to Tonight`, used for every not-found. The same copy whether the series was removed or gated, so 18+ is never revealed. |
| R4 | medium | **The mobile horizontal-strip migration is unspecified.** Mobile K01 `leftToRight` / `rightToLeft` are continuous horizontal strips today. The design maps them only to Direction, and the resulting Layout is not said. | Migrate them to `SINGLE` with the matching direction, and show a one-time toast "Sideways strips are now pages. Change it in Reading setup." |
| R5 | low | **The guided-view `panel-focus` button is not in the running head's list** (§8.14.3 trailing items). | Add it after the bookmark, shown only when `panels_ready`. |
| R6 | low | **Tablet side-panel triggers are unspecified.** There is no keyboard on tablets, and the running head's panel toggles are "on desktop". | Show `sidebar-simple` and `note-pencil` on tablets too. |
| R7 | low | **`g` means two things in the reader.** The global `g` + number section jump (§8.0.6) and the reader's `g` (go to page) collide. | State that the global `g` sequence is disabled in reader frames. |

### 7.13 Novel reader and Listen (§8.15, §8.16)
| # | Sev | Gap | Fix |
|---|---|---|---|
| N1 | **high** | **Auto-scroll and soundscape have no way in on the novel page.** §9.4.1 says auto-scroll runs in "novel scroll mode" (1.00× = the measured wpm). But the novel chrome (§8.15.3), the Type sheet (§8.15.5) and the keys (§8.15.8, where `p` is Listen) give no entry, no speed control and no chip. The soundscape (§9.4.2) is reachable only from the manga setup sheet's AMBIENT tab. Owner decision 4 requires entry points and states for each new feature. | Add an `AMBIENT` group to the Type sheet (auto-scroll play and speed ruler 0.50–3.00×, soundscape, volume). Add a bottom-bar `play` + `strip-scroll` button, with key `a` (since `p` is Listen). Add the `waveform` indicator to the novel top bar. Auto-scroll pauses while Listen plays. |
| N2 | low | **Small gaps.** The `g` "Go to %" UI is not specified. The offline end state "End of the downloaded copy" (mobile S26 #9) is missing. The desktop novel reader has no right-hand panel (notes, Circle, voices), unlike the manga reader's "wide reader with side panels". There is no 18+ rating card for novels. | Specify a folio field `42 %` like the manga folio. Add the end state. Add a `]` Margins panel (`NOTES · CIRCLE · VOICES`). |
| N3 | low | **Listen gaps.** Non-owners' Audiobook button (hidden or disabled?), the `Pause the soundscape during narration` switch (§9.4.2) is missing from Settings → Ambient, and there is no desktop Media Session. | Hide `Audiobook` for non-owners, add the switch to row 06, and see P4. |

### 7.14 Series pages (§8.17, §8.18, §8.19)
| # | Sev | Gap | Fix |
|---|---|---|---|
| SE1 | (R3) | Not-found, removed-source and gated deep-link states. | see R3 | |
| SE2 | medium | **Enriched metadata has no source.** DETAILS shows "AniList rating, format, official platforms" for a series page, but only `WorldItem` carries them. There is no series-level enrichment endpoint, and nothing in §15.5. | Add `GET /series/enrichment?source&series` (an AniList match cached 30 days) to §15.5, or drop the row. |
| SE3 | low | **Novels have no repoint flow.** "Move to another source" (§8.17) is manga only, although novel sources die too. | State whether novels get repoint (by chapter number, the same mapping). |

### 7.15 Discover, Sources, catalogue (§8.20–§8.22)
| # | Sev | Gap | Fix |
|---|---|---|---|
| D1 | medium | **Two idle sections have no data source.** `04 Trending on your sources` has none (today's chips are fixed). `01 Browse by genre` tiles have no cross-source genre endpoint (genres exist per source, for 22 sources), so where a tile leads is undefined. | Trending: fixed curated terms, or `GET /search/trending` (new, §15.5). Genre tile: opens Discover `?q=` in genre-match mode, or a sheet listing the pinned sources that expose that genre. |
| D2 | medium | **Discover's keys collide.** The scope tabs are contents tabs (switched with `[` / `]`, §7.12), and `[` / `]` also jump between result groups (§8.20). | Scopes on `1`–`5`, groups on `[` / `]`. |
| D3 | low | **The Sources directory has no offline state.** | "The source list needs a connection." notice, with pinned rows from cache. |

### 7.16 Downloads (§8.23)
| # | Sev | Gap | Fix |
|---|---|---|---|
| DL1 | (P1, X3) | Mobile web layout, and the 18+ local filter. | | |
| DL2 | low | **The automatic-download mechanism is unspecified.** "Download new chapters of followed series automatically" does not say how this works when downloads run only in the foreground (G10), or whether it respects per-series `notify`. | On app open or resume, after the update poll, queue the new chapters of followed series with `notify` on, respecting Wi-Fi-only (K20) and the cap. |

### 7.17 Picks (§9.1.3)
| # | Sev | Gap | Fix |
|---|---|---|---|
| PK1 | low | **Two small gaps.** `POST /ai/feedback` accepts `liked_pick`, but there is no UI to send it. The copy after the 40 s timeout is not written. | Add a `thumbs-up` bare icon on World cards ("More like this", haptic `select`). Timeout copy: "The editors took too long. Try a shorter description." + `Try again`. |

### 7.18 The Numbers, The Annual, share cards (§9.2)
| # | Sev | Gap | Fix |
|---|---|---|---|
| ST1 | medium | **Sharing is incomplete.** The Numbers has no share entry, although the owner asked for "shareable stat cards". The share sheet (template × `STORY │ POST`, preview, rendering state, failure when `toBlob` fails or `navigator.share` rejects or aborts, the desktop download copy) is unspecified. The privacy rules mention "Circle cards", but there is no Circle template among the six. | Add `Share` to The Numbers masthead (opens the press run on the current range). Specify the sheet: a 240 px preview, a template slug line, a format segmented control, `Share` / `Save image`, a leader dial while rendering, and the error toast "Couldn't make the card. Try again." Add a 7th template, Circle (only when both profiles share), or delete the rule. |
| ST2 | low | **Previous Annuals cannot be reached.** There is no year picker (the route has `:year`), and horizontal swipe on story pages is not specified. | A year slug line on The Numbers banner (`2026 · 2025`) and swipe left/right = next/previous. |

### 7.19 Circle (§9.3)
| # | Sev | Gap | Fix |
|---|---|---|---|
| CI1 | medium | **Several states are missing.** The Pass-it-on sheet with zero eligible recipients (nobody has `Receive recommendations` on). Per-tab empty states (REACTIONS, LETTERS, SHELVES). A new-letter signal on phones (Circle lives under Index, and the thumb index has no Index badge). | Recipients empty: "Nobody is taking recommendations right now." Tab empties in the notice tone. Add an Index-tab count badge for unread letters (spot square as §7.14). |
| CI2 | low | **Unwritten rules.** Profile names can collide across accounts ("Yash" twice). Can a non-sharing viewer see others? It currently does, which is an owner decision to confirm. The "kept" letter state that Tonight's `Sent to you` reads has no action. | Disambiguate with an `@username` caption. Record the reciprocity rule. Add `Keep` to the Letter card. |

### 7.20 Index, What's new (§8.28, §8.29)
No gaps beyond CI1's badge.

### 7.21 Settings (§8.30)
| # | Sev | Gap | Fix |
|---|---|---|---|
| SG1 | medium | **One setting has no backend.** Row 11's per-profile "Notify me about new chapters" master has no backend field (only per-series `notify` and the admin, instance-wide `notify_enabled`), and nothing in §15.5. | Add `notify_enabled` on `reading_profiles` to §15.5, or drop the row. |
| SG2 | medium | **Server-backed sections have no loading, error or offline states.** Only the no-profile guard is specified, for Content 18+, Notifications, Circle & privacy, Password & security, Members and Backup. | Loading: greeked rows. Error: a `CORRECTION` line + Retry per section. Offline: controls disabled with "Needs a connection." (and on mobile, which changes queue in the outbox, for example the skin `PATCH`). |
| SG3 | low | **Several smaller gaps.** The `capabilities` flags from `GET /settings` (`ocr`, `collections`, `bookmarks`, `client_downloads`, …) are never used to hide sections. Settings → Server (app) does not say what happens to the session, caches and downloads when the server changes. Admin sections deep-linked by non-admins (`/settings/members`) have no state. Settings has no web keys (section navigation, `/` for search). | Hide sections by capability. On a server change: sign out, keep downloads under the old server's scope, and show the toast "Signed out: new server." Non-admins see the §8.31 `ADMINISTRATORS ONLY` notice. Keys: `/` search, `j`/`k` sections. |

### 7.22 System status and status screens (§8.31, §8.32)
| # | Sev | Gap | Fix |
|---|---|---|---|
| E1 | medium | **Status screens are specified for the web only.** Flutter has no unknown-route screen (go_router `errorBuilder`), no uncaught build error screen (`ErrorWidget.builder` in release) and no "backend unreachable mid-session" treatment. | Reuse the §8.32 404 and route-error notices in `CineErrorScreen` for `errorBuilder`. A release `ErrorWidget` is a `paper.1` box with `CORRECTION · This part of the page broke.` |
| E2 | low | **System status has no keys** (`r` refresh). | Add `r`. |

### 7.23 Global overlays (§8.33)
| # | Sev | Gap | Fix |
|---|---|---|---|
| G1 | low | **Two bottom-centre layers can overlap.** On phones the stop-press banner and toasts both sit bottom-centre, 16 px above the thumb index, at `z.toast`. | Toasts stack above the banner (the banner is in the toast stack as the oldest entry, max 2 visible). |

### 7.24 Public install page (§8.34)
No gaps (static, no states needed). The per-skin question is settled by B1.

---

## 8. Checked and complete (no action)

- Every inventory screen (web R1–R27, E1–E4, mobile S01–S34) maps to a §8 section, and every inventory dialog is either redesigned or deliberately removed (palette and preset pickers, the language picker).
- The four new features have routes, entry points, loading states and AI-unavailable states, and are gated on serve.
- The 18+ principle (absence, never a lock) is applied consistently to server data. Only local stores leak (X3).
- The haptic vocabulary is complete for §5's own events. Reduced-motion variants exist for every §4.5 named move.
- The gesture matrix gives a non-gesture alternative for every gesture listed.
