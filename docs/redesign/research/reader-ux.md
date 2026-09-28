# Reader UX research: manhwa, manga and novel readers, plus listen mode

Research for the ManhwaManiacs 0-to-100 redesign (two skins: **Cinematic** and **Glass**, dark only, AMOLED `#000000` base). This file lists patterns from other readers. It does not describe or keep the current look. The only thing taken from the current app is its **feature inventory** (section 2), because the redesign must still cover those capabilities.

Date: 2026-09-29. Author: reader-ux research agent.

## 0. Sources, confidence and licences

Every number carries one of these tags:

| Tag | Meaning |
|---|---|
| **[src]** | Read in the app's own source code this session. The file path is given. Treat it as exact. |
| **[doc]** | Official documentation or a store listing fetched this session. |
| **[web]** | A third-party article or search result fetched this session. |
| **[obs]** | Widely known behaviour of a closed-source app, **not re-measured this session**. Check it on a device before copying an exact number. |

Reference clones (all under `/srv/manhwamaniacs/dev/design-ref/`, `git clone --depth 1`):

| Repo | URL | Licence | What it gave us |
|---|---|---|---|
| Mihon | https://github.com/mihonapp/mihon | Apache-2.0 | Tap-zone geometry, webtoon scroll/zoom constants, chapter transition card, slider haptics, brightness/filters |
| Kavita | https://github.com/Kareadita/Kavita | **GPL-3.0** | Web keybinds, menu auto-close timer, click zones, pull-to-load chapter boundary, book themes |
| Komga | https://github.com/gotson/komga | MIT | Web reader shortcuts, side-padding presets, paged click zones |
| Readest | https://github.com/readest/readest | **AGPL-3.0** | TTS mini/full player, speed tick ruler, sleep timer list, lyrics-style follow view, page curl/slide timing, font/line-height ranges, dark paper palettes |
| foliate-js | https://github.com/johnfactotum/foliate-js | MIT | Paginator snap animation, column layout defaults |

**Licence rule:** Kavita (GPL-3.0) and Readest (AGPL-3.0) are for studying patterns only. Do not paste their code into `yash-dhanda/ManhwaManiacs`, which is a public repo. Numbers and interaction ideas are fine to reuse. Code from Mihon (Apache-2.0), Komga (MIT) and foliate-js (MIT) can be adapted if the licence notice is kept.

---

## 1. The twelve decisions that matter most

1. **Manhwa chrome is scroll-driven, not timer-driven.** Hide the chrome when the reader scrolls down past a small threshold. Show it when they scroll up past a larger one, and always at chapter end. An idle timer is only for chrome that a tap opened (3000 ms, as in Kavita).
2. **Tap zones are thirds, mirrored for RTL, with a first-run overlay.** Every OSS reader uses 25-33 % edge bands. Mihon paints the zones in colour once and fades the overlay out over 1000 ms.
3. **The chapter boundary is a designed moment, not a gap.** Mihon uses a "Finished / Next" card. Kavita uses a pull-to-continue strip that arms after 100 ms idle at the boundary. Netflix uses post-play. Pick one per skin and give it motion and haptics.
4. **Scrubbers tick.** Mihon fires a haptic on every page step of its slider. Adopt this everywhere: one tick per page, a stronger bump at chapter boundaries.
5. **Brightness goes below the system minimum.** Mihon's range is -75..100. Negative values draw a black overlay at `|value|/100` alpha. On AMOLED this is the right night control.
6. **Settings sheets cover the bottom half only,** so the text changes live above them (the Kindle Aa menu).
7. **Typography ranges:** font 8-30 px (default 16-18). Line height 0.8-2.4 in 0.1 steps (default 1.6). Margins run from a small value to a large one in a 10-step slider (Readest). Add Apple Books' character spacing, word spacing, bold text and justify.
8. **Page turns:** default 450 ms. Tap-turns ease with easeInOutQuad. Finger releases settle with easeOutCubic, sped up by fling velocity. The curl radius is 0.16 x page width and shrinks as the page lifts (Readest). Snap-to-page is 300 ms easeOutQuad (foliate-js).
9. **Listen mode needs a follow/decouple state machine.** Follow the spoken sentence. When the user scrolls away, stop following and show a "Back to voice" pill. In the lyrics view, return automatically after 4000 ms idle (Readest).
10. **Speed is a tick ruler, 0.5-3.0x in 0.05 steps,** with labelled marks at 0.5/1/1.5/2/2.5/3 (Readest). Touch-and-hold resets to 1x (Apple Books).
11. **The sleep timer must include "End of chapter".** Every audiobook app has it (Apple Books, Audible, Spotify's "end of episode", Readest). Add Audible's "Shake to extend".
12. **Web readers are keyboard-first,** with a `?` overlay. Use the union of the Kavita, Komga and current-app keys (section 4.13) so no muscle memory breaks.

---

## 2. What the redesign must cover (feature inventory, not look)

Taken from `/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/src/features/{reader,novels}` and `mobile/lib/features/{reader,novels}`. Read-only.

- **Manhwa/manga reader:** continuous vertical strip (`ContinuousStrip`), paged view (`PagedView`), and a **Read-All** mode that plays a whole series as one scroll (`ReadAllReader.tsx`: "if it have 30 chapter ill watch it in 1 chapter without feeling it"). Also a scrub bar, auto-scroll, a cinema mode that hides all chrome, fullscreen, zoom (+/-/0), bookmarks, configurable tap zones (left/center/right bands, default edge ratio 0.28), and RTL mirroring.
- **Novel reader:** paper palettes, typography panel, reading-time estimate, paragraph anchors for resume, and bookmarks ("B").
- **Novel audio:** audio is **pre-rendered** per chapter, not live TTS. It is fetched on the first press of play. A segment timing map drives **sentence and word highlight**, and the highlight shows nothing rather than guessing. There are **31 named voices** that each introduce themselves. A **cast** assigns characters to voices automatically (by gender, then speaking order), and the user can re-cast. **Speaker tint** colours quoted dialogue per speaker. The cast panel must stay small: character/world extraction was permanently abandoned (`NovelCastPanel.tsx` header), so it shows only name, tint colour and how much each character speaks.
- **Current key vocabulary** (functional, keep it): →/D and ←/A turn pages by direction, J/K next/previous page, Space and Shift+Space one screen, Home/End, F fullscreen, C cinema, P auto-scroll, H/L previous/next chapter, S series page, B bookmark, `=`/`+`/`-`/`0` zoom, Esc, `?` help. The novel reader adds T for the type panel and `=`/`-` for text size.
- **Owner-requested new reader features** (from `/srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/inventory/00-decisions.md`): auto-scroll with speed control, ambient soundscape, panel-by-panel guided view, chrome tinted by the current page's dynamic colour, a "previously on" recap before continuing, and reactions on chapters.

---

## 3. App-by-app teardown

### 3.1 WEBTOON (LINE Webtoon / Naver) — the manhwa reference

- **Layout [obs]:** full-bleed vertical strip with panels edge to edge and no gaps. The **top bar** has back, the episode title ("Ep. 57 – …"), and a list/share/overflow cluster. The **bottom bar** has a like heart with count, a comment bubble with count, and ‹ / › previous/next episode arrows.
- **Auto-hide [obs]:** the chrome slides away on downward scroll, comes back on upward scroll or a tap, and always comes back at the end of the episode. There is no idle timer. You have to act to see the chrome.
- **Tap [doc]:** "tap any panel to show the top menu". Webtoon **removed its old tap-to-scroll** in v2.0.5 because it got in the way of other viewer actions (WEBTOON notice 739). The lesson: in a vertical reader, a tap should toggle the chrome by default. Tap-to-scroll should be opt-in.
- **End of episode [obs]:** in order, a creator's note card, a large like button next to Subscribe, a preview of the top comments, a full-width **Next Episode** button, then recommendation rails. The chrome is pinned visible here.
- **Auto-scroll:** not native in the Webtoon app [web]. Lezhin ships it with three presets, **1x / 1.5x / 2x** [web].
- **Source image width:** Canvas uploads are 800 px wide slices [obs]. Plan the desktop strip width around 800 px x DPR, not full-bleed on a 2560 px monitor.

### 3.2 Tapas

- Same vertical strip [doc]. The lower navigation bar has a **Next** button, and **iOS adds a right-to-left swipe to go to the next episode** from inside the vertical reader (Tapas help, "What is 1-Tap"). That makes a horizontal swipe the chapter-level gesture while the vertical scroll stays page-level. Worth adopting: it does not conflict with vertical reading.
- Unlock timers and paid currency are out of scope (private app).

### 3.3 MANGA Plus (Shueisha)

- Horizontal paging, **right-to-left** by default, with a vertical-scroll option and an image-quality setting [web: app listing via search]. RTL click zones: the **left half advances, the right half goes back** (the Frank Manga+ desktop client copies this) [web].
- End of chapter [obs]: a final page with the chapter's comments entry and the **next chapter's release date**. For caught-up series, a "next update" date/countdown on the last page is a good end state for us too.
- Desktop client ideas [web]: `D` cycles single / double / double-with-cover. `F` cycles **four sepia night-filter levels "without flattening the contrast"**. The next chapter prefetches and is appended to the scroll.

### 3.4 Mihon (Tachiyomi fork) — the most detailed reference, all [src]

Paths below are relative to `mihon/app/src/main/java/eu/kanade/`.

**Tap zones** (`tachiyomi/ui/reader/viewer/navigation/*.kt`, rects in fractions of width and height):

```
L-shaped (default)        Kindle-ish               Edge                     Right-and-Left
+----+----+----+          +----+----+----+         +----+----+----+         +----+----+----+
| P  | P  | P  |  0-.33   | M  | M  | M  |         | N  | N  | N  |         | L  | M  | R  |
+----+----+----+          +----+----+----+         +----+----+----+         +----+----+----+
| P  | M  | N  | .33-.66  | P  | N  | N  |         | N  | M  | N  |         | L  | M  | R  |
+----+----+----+          +----+----+----+         +----+----+----+         +----+----+----+
| N  | N  | N  | .66-1    | P  | N  | N  |         | N  | P  | N  |         | L  | M  | R  |
+----+----+----+          +----+----+----+         +----+----+----+         +----+----+----+
```

- Columns and rows split at **0.33 / 0.66**. Zones can be inverted horizontally, vertically or both. "Disabled" makes every tap open the menu.
- Zone overlay colours (alpha `0xCC` = 80 %): menu `#95818D`, previous `#FF7733`, next `#84E296`, left `#7D1128`, right `#A6CFD5`. The overlay **fades out over 1000 ms** (`ReaderNavigationOverlayView.kt`, `FADE_DURATION = 1000L`). It shows for new users and optionally on every start.
- Long-tap opens page actions (save, share, set as cover). Volume keys can turn pages, with an invert option.

**Chrome** (`presentation/reader/appbars/ReaderAppBars.kt`): bars **slide 200 ms** (`tween(200)`) and **fade 150 ms**. The background is the elevation-3 surface at **90 % alpha** in dark mode.

**Webtoon viewer** (`tachiyomi/ui/reader/viewer/webtoon/`):
- **Hide-on-scroll threshold** is compared against each scroll event's `dy`. Presets: HIGHEST 5 px, HIGH 13 px, LOW 31 px, LOWEST 47 px (`ReaderPreferences.ReaderHideThreshold`). Above the threshold, the menu hides.
- **Tap-scroll distance = 3/4 of screen height** (`scrollDistance = heightPixels * 3 / 4`), animated with `smoothScrollBy`.
- **Zoom:** min 0.5x (zoom out, can be disabled), max **3x**. Zoom animation **200 ms DecelerateInterpolator**. A fling while zoomed runs **400 ms** decelerate with distance = 0.4 x velocity / 2. Double-tap zoom default **500 ms EASE_IN_OUT_QUAD** (pref `doubleTapAnimSpeed`), scaled by the system animator scale.
- **Side padding 0-25 %** of width (`WEBTOON_PADDING_MIN/MAX`). Optional crop of page borders.

**Chapter transition** (`presentation/reader/ChapterTransition.kt`): an inline item between chapters. The top label reads "Finished: <chapter>" and the bottom label "Next: <chapter>", with chapter names at **20 sp** and a downloaded icon at 22 sp. Max width **460 dp**, 24 dp vertical spacers. An outlined card warns when chapters are **missing** between the two, with 16 x 12 dp padding. It shows always or only when needed (`alwaysShowChapterTransition`). The next chapter preloads when the transition item comes into view.

**Bottom bar and scrubber** (`presentation/reader/components/ChapterNavigator.kt`): previous/next chapter `FilledIconButton`s flank a pill slider with **24 dp corner radius**. **`HapticFeedbackType.TextHandleMove` fires on every page step.** Webtoon mode can use an optional **vertical** slider on the left or right edge with adjustable height. Tablets get 24 dp side padding, phones 8 dp.

**Page number** (`ReaderPageIndicator.kt`): text `#EBEBEB` with a `#2D2D2D` stroke and 1 sp letter spacing, drawn twice so it reads on any page.

**Brightness and filters** (`presentation/reader/settings/ColorFilterPage.kt`, `ReaderContentOverlay.kt`): custom brightness **-75..100**. At 1..100 it sets window brightness. At -75..-1 it draws a black overlay at alpha `|v|/100`. The colour filter is RGBA 0-255 with blend modes Default, Multiply, Screen, Overlay, Lighten and Darken. Grayscale and inverted colours are also available. Keep-screen-on is a flag. There is an e-ink **flash on page change**: black, white or both, with duration in 100 ms units and an every-N-pages interval.

**New WebGPU viewer transitions** (`ReaderPreferences.TransitionAnimation`): Basic, Flip, Flip-Left/Right, Stack L/R/Up/Down, Sphere, Cube inside/outside, Fade, Fade-white, None. Continuous-mode gap defaults to 10.

### 3.5 Kavita (web, Angular) — all [src], `Kavita/UI/Web/src/app/`

- **Menu auto-close: 3000 ms** (`OVERLAY_AUTO_CLOSE_TIME`). The timer resets on interaction and never runs while settings are open. It can be turned off per reading profile (`autoCloseMenu`).
- **Click zones:** left 25 % / center 50 % / right 25 % (`manga-reader.component.scss`: `$side-width: 25%`, `$center-width: 50%`). When the menu opens, hint overlays show for **3000 ms** (`CLICK_OVERLAY_TIMEOUT`).
- **Pull-to-continue at chapter boundaries** (`shared/_components/pull-to-load/`): a 20 px (1.25 rem) resting strip sits at the end of the strip. After **100 ms idle at the boundary** it arms and grows to **300 px on desktop / 150 px on mobile**, giving a scroll-through region. A **3 px progress track** fills (`transition: width 60ms linear`), and crossing the end loads the next chapter. The title has animated double chevrons.
- **Continuous scroller:** scroll debounce 20 ms, scroll-end debounce 100 ms on Safari (no `scrollend`). Failed images retry 3 times. The IntersectionObserver threshold is 0.01.
- **Default keybinds** (`_services/key-bind.service.ts`): ←/→ page, ↑/↓ page, Space toggles the menu, F fullscreen, G go-to-page, H help, Ctrl+B bookmark, O offset double page, Ctrl+←/→ first/last page, **Ctrl+Shift+←/→ previous/next chapter**, Ctrl+K search. Double-click bookmarks. Every bind can be remapped in settings.
- **Book themes:** Dark `#292929` / text `#efefef` (default), Black `#000000`, White, and Paper with drawer `#F1E4D5`.

### 3.6 Komga (web, Vue) — all [src], `komga/komga-webui/src/`

- Shortcuts (`functions/shortcuts/*.ts`): ←/→ (mirrored for RTL), ↑/↓, Home/End first/last. **L / R / V / W** switch reading direction (LTR, RTL, vertical, webtoon). **C** cycles scale, **F** fullscreen, **M** toolbars, **S** settings, **T** thumbnails, **H** help, Esc close. In continuous mode, **P** cycles side padding and **N** cycles page margin. The EPUB reader uses Space / Ctrl+Space for next/previous.
- Side padding presets **0, 5, 10, 15, 20, 25, 30, 35, 40 %**. Page margins **0, 5, 10, 15 px** (`types/enum-reader.ts`).
- The paged reader uses **25 % left and right click bands** (`components/readers/PagedReader.vue`: `.left-quarter` / `.right-quarter`, `width: 25%`).

### 3.7 Apple Books — the novel reference

Official iPhone guide, iOS 27 edition [doc: support.apple.com/guide/iphone/read-books-iphc1af7c57/ios]:
- **Page turns:** tap the right margin or swipe right-to-left to go forward, the left margin to go back. The setting **"Both Margins Advance"** lets either margin go forward (one-handed reading).
- **Back to previous location:** after a jump, a **rounded-arrow chip** appears top-left. Tapping it goes back, and a mirrored chip top-right returns. Adopt this for every "go to page / chapter / bookmark" jump.
- **Themes & Settings** opens from a single **Reading Menu button** at the bottom. Its side (left or right) is a setting: "Reading Menu Position". Inside: small A / large A for size, **page turn style: Curl, Fast Fade or Scroll** (Slide is the plain default added in iOS 16), background mode, a **brightness bar**, and page themes (**Original, Quiet, Paper, Bold, Calm, Focus** [obs for the full list; doc names Quiet and Bold]).
- **Customize:** font picker, **Bold Text**, and under "Accessibility & Layout Options" sliders for **line spacing, character spacing, word spacing, margins**, plus **Justify Text** and **Reset Theme**.
- **Close the book by swiping down** from the top of the page (not in vertical scrolling).
- **TOC scrub:** touch and hold Contents, then drag left or right to scrub through the book and release to jump.
- **Line Guide:** dims everything except the current line. Tap above or below it, or tap a margin, to move it. Drag it directly. The dim level is adjustable.
- **Bookmarks:** the place is saved automatically. Bookmarks are extra and live under "Bookmarks & Highlights".

Apple Books audiobook player [doc: support.apple.com/guide/iphone/listen-to-audiobooks-iphac1971248/27/ios/27]:
- Rounded-arrow **skip buttons** with a configurable number of seconds (Settings > Apps > Books > Skip Forward / Skip Back). Touch and hold them to scrub.
- **Speed:** tap "1x" in the lower left, then **drag a dial up or down**. **Touch and hold the speed to reset to 1x.**
- Sleep timer, chapters list, AirPlay, and a volume slider under Pause.
- **Mini player:** swipe down anywhere (or tap the chevron) to collapse it. Tap the mini player to expand. Touch and hold it for "Close Audio Player".

### 3.8 Kindle

- **Aa menu [web]:** covers the **lower half of the screen** so layout changes are visible live above it. It has four tabs: **Themes, Font, Layout, More**. Font size has **14 marked levels**. Layout holds line spacing, alignment, orientation lock and background colour (White, Sepia, Green, Black [obs]). Saved themes store font, spacing, margins and brightness. **More** holds the clock, reading progress, and the **page-turn animation toggle**.
- **Reading progress [obs]:** tap the bottom-left label to cycle Location → Page → **Time left in chapter** → **Time left in book** → none.
- **EasyReach tap zones (e-reader) [web, manual]:** the next-page zone is **~80 %** of the screen. Previous page is a **narrow left strip**. The **top band is ~1.25 in (~3.2 cm) high** and opens the toolbars. On Kindle Touch, the top-right corner toggles a bookmark. Swipes: left/right turn pages, **up/down change chapter**.

### 3.9 Moon+ Reader (Android) [doc: Play Store listing]

- **24 customisable operations** (screen taps, swipes, hardware keys) mapped onto **15 events** (search, bookmark, themes, navigation, font size…).
- **5 auto-scroll modes:** "rolling blind", by pixel, by line, by page, with **real-time speed control**.
- **Brightness by sliding a finger along the left edge.**
- Real page-turn (curl) effect with customisable speed, colour and transparency. **5 page-flip animations.**
- A **reading ruler** in 6 styles. Day/Night switcher, 10+ themes, dual page in landscape, "Shake the phone to speak (TTS)" in Pro.

### 3.10 Readest (bonus: the best open TTS reader UI) — all [src], `readest/apps/readest-app/src/`

- **Mini player** (`app/reader/components/tts/TTSMiniPlayer.tsx`): **56 px tall** (`h-14`), **16 px corner radius** (`rounded-2xl`), inset 16 px on phones, max width **448 px** centred on larger screens, shadow-lg. A **3 px progress line** runs along the bottom edge: track at 15 % alpha, buffered at 35 %, played in the primary colour. Contents: a 40 px cover (8 px radius), the title (14 px), then "elapsed · remaining" or "N left in chapter" in tabular numbers. Opacity/position transition **300 ms**.
- **Auto-hide rule** (`useMiniPlayerAutoHide.ts`): the "full" mini card rides with the reader chrome and **lingers 5000 ms** after the toolbar hides, so a dismissing tap doesn't yank it away mid-glance. The "minimal" style stays for the whole session.
- **Full player sheet** (`TTSPlayerSheet.tsx`): views main / speed / voice / timer / chapters. The main view has the title, "N left in chapter", five transport buttons (**Previous paragraph, Previous sentence, Play/Pause 56 px circle, Next sentence, Next paragraph**; when the audio is a timeline, these become previous chapter / back 15 s / forward 30 s / next chapter), then a row of three **56 px tiles** (Speed, Voice, Sleep timer) that drill into sub-views, then "Offline audio" (download chapters).
- **Sleep timer options:** No timeout, **End of chapter**, 1, 3, 5, 10, 20, 30, 45 min, 1, 2, 3, 4, 6, 8 h. The label counts down live.
- **Speed ruler** (`SpeedRuler.tsx`, `TickRuler.tsx`): **0.5-3.0x, step 0.05**, taller labelled ticks at 0.5/1.0/1.5/2.0/2.5/3.0. The bright current value sits over the active tick, and a mark label hides when within 8 % of it. An invisible native range input drives it (drag, tap and keyboard for free). **The value previews while dragging and commits only on release.**
- **Lyrics view** (`TTSLyricsView.tsx`): the chapter as a list of sentences, like Apple Music lyrics, **auto-centred on the spoken sentence**. The active sentence is semibold on a tinted rounded rect. The line under the seek row is 70 % alpha, all others 40 %. Sentences are 14 px, `leading-snug`, 56 px gutters. **A user scroll decouples and shows a seek row** (page label plus a 28 px play-from-here button). **After 4000 ms idle (`SEEK_IDLE_MS`) it slides back** to the spoken sentence. If the target is more than 2 viewports away, the jump is instant instead of smooth.
- **Follow indicator** (`TTSFollowIndicator.tsx`): states idle / following / syncing / **decoupled** / paused / unsupported. The decoupled state is a pill with a glyph and text, and tapping it resumes. "Never nag": idle renders nothing.
- **Page turns** (`app/reader/utils/capturedTurn.ts`, `utils/pageCurl.ts`, `types/book.ts`): styles **push / slide / curl**, where slide and curl lay the outgoing page over the incoming one "Apple Books style". **Default duration 450 ms.** Programmatic turns use easeInOutQuad. Release after a drag settles with easeOutCubic; velocity speeds playback up to 2x (slide/push) or 1.5x (curl), but never under 90 ms. The release velocity window is 90 ms. The **curl radius is `0.16 × leafWidth × (1 − progress²)`**, and the back of the curling page is painted with the theme's paper colour and texture. On two-column spreads only the outer leaf curls, hinged at the spine.
- **Library route transition** (`styles/globals.css`): View Transitions, **300 ms `cubic-bezier(0.4, 0, 0.2, 1)`**, slide-and-fade by navigation direction.
- **Font panel** (`footerbar/FontLayoutPanel.tsx`): font size **8-30** (default 16). Line spacing **0.8-2.4** (slider 8-24 ÷ 10, default 1.6). Page margin runs Small→Large in a 10-step slider (default top margin 44 px, gap 5 %).
- **Middle-click autoscroll (web)** (`app/reader/utils/autoscroller.ts`): 12 px dead zone, **10 px/s per px** of pointer offset, max 4000 px/s, sub-pixel carry so slow speeds still move. Wheel page-turn idle reset is 200 ms (`wheelGesture.ts`).
- **Dark theme palettes** (`styles/themes.ts`, dark variants): Sepia `#342e25`/`#ffd595`, Grass `#333627`/`#d8deba`, Cherry `#462f32`/`#e5c4c8`, Sky `#282e47`/`#babee1`, Solarized `#002b36`/`#93a1a1`, Gruvbox `#282828`/`#ebdbb2`, Nord `#2e3440`/`#d8dee9`, Contrast `#000000`/`#ffffff`, Sunset `#3c2b25`/`#f6e1d7`.

### 3.11 foliate-js — [src], `foliate-js/paginator.js`

- Defaults: gap **7 %**, margin **48 px**, max inline size **720 px**, max 2 columns (1 in portrait).
- **Snap animation 300 ms easeOutQuad** (`1 − (1 − x)²`). Swipe velocity picks the target page. Past the last page, it moves on to the adjacent section (the chapter boundary).

### 3.12 Spotify (the mini/full player reference) [web + obs]

- **Now Playing bar [obs]:** a floating rounded card (~56-64 dp) above the tab bar. The **background is tinted with a colour extracted from the artwork**. A **~2 dp progress line** runs along its bottom edge. **Swipe it left or right to skip**, tap to expand into the full player, which slides up. The full player has an artwork-coloured gradient background and a lyrics card below the controls that expands to full-screen lyrics (the past line dims, the current line is bright).
- **Sleep timer [web]:** 5, 10, 15, 30, 45 min, 1 h, **end of track/episode**.
- **Podcast speed [web]:** 0.5x to 3.5x, with presets such as 0.5/0.8/1/1.5/2/3. The "1x" chip sits next to Play.

### 3.13 Speechify [web]

- **Synced highlight of line and word** as it reads. Highlighting can be turned off.
- **Speed shown as both x and WPM:** 0.5x = 100 wpm to **4.5x = 900 wpm** (so 1x = 200 wpm).
- **Skip ±15 s**; tap repeatedly to skip further. Tap any word, line or paragraph to start reading from there.
- **Floating widget** that can be moved, docked or hidden.
- 200+ voices, including celebrity partners, picked with a preview.

### 3.14 Audible [web]

- **Speed 0.5-3.5x** with quick presets and fine steps of **0.05x** (the cloud player uses 0.1x).
- **Sleep timer** presets plus **End of chapter**, and **"Shake to Extend"** to add time without looking.
- **Custom skip intervals**, clips (bookmarks with short audio excerpts and notes), a **car mode** with oversized controls, **four configurable shortcut slots** at the bottom of the player, and a toggle between **chapter progress and total-book progress** plus a remaining-time display.

---

## 4. Pattern catalogue by topic (with numbers to build from)

### 4.1 Chrome auto-hide timing

| App | Show | Hide | Motion |
|---|---|---|---|
| Mihon [src] | tap menu zone | scroll event `dy` > 5/13/31/47 px (preset) | slide 200 ms + fade 150 ms |
| Kavita [src] | tap center 50 % | **3000 ms** idle after open (off while settings open) | — |
| Readest [src] | hover/tap | TTS card lingers **5000 ms** after toolbar | 300 ms |
| Webtoon [obs] | tap, scroll up, episode end | scroll down | slide |
| Apple Books / Kindle [obs] | tap center / top band | page turn, tap | fade |
| Netflix player [obs] | pointer move / tap | ~3-5 s inactivity | fade |

**Recommendation (shared logic, both skins):**
- **Hide** when the cumulative downward scroll since the last direction change is ≥ **24 dp** (between Mihon's HIGH and LOW). Use a cumulative delta, not a per-event one, so slow trackpad scrolls behave the same as flicks.
- **Show** after a cumulative upward scroll of ≥ **56 dp**, at chapter end, on pointer movement into the top or bottom 72 px (desktop), and on a center tap.
- **Idle auto-hide 3000 ms** only when a tap or hover opened the chrome. Pause the timer while any sheet, scrubber drag or menu is open. Restart it on interaction.
- Never hide the chrome in the first **800 ms** after a chapter loads (orientation moment). Always show it for the first frame after a jump.
- `prefers-reduced-motion`: swap slides for a 120 ms opacity fade.

### 4.2 Tap zones

| Reader | Split |
|---|---|
| Mihon [src] | thirds at 0.33/0.66, 5 layouts (L, Kindle-ish, Edge, Right-and-Left, Disabled), invert H/V |
| Kavita [src] | 25 / 50 / 25 |
| Komga [src] | 25 % bands |
| Current app | 28 % edge bands (functional default, not a look) |
| Kindle e-reader [web] | ~80 % next, narrow left strip back, ~1.25 in top band for menu |
| Apple Books [doc] | left margin back, right margin forward, "Both Margins Advance" |
| MANGA Plus [web] | RTL: left half forward, right half back |

**Recommendation (shared logic):**
- **Vertical manhwa (default "Tap = chrome"):** the whole screen toggles the chrome, as in Webtoon. An opt-in "Tap to scroll" mode uses Mihon's L-shape: the top third plus the left-middle scrolls back, the bottom third plus the right-middle scrolls forward, and the centre toggles the menu. It scrolls **75 % of the viewport** in **300 ms easeOutQuad** (`cubic-bezier(0.5, 1, 0.89, 1)`).
- **Paged manga:** **30 / 40 / 30** columns, mirrored for RTL. The centre toggles the chrome.
- **Novel paged:** **25 / 50 / 25**, plus Apple's "Both margins advance" and a Kindle one-hand preset: left 20 % back, top 12 % menu, the rest forward.
- **First run:** paint the zones with a translucent colour overlay and short labels ("Back", "Menu", "Next"). Fade it out over **1000 ms** after 1500 ms. Show it again whenever the tap layout changes.
- **Double-tap:** zoom to 2x at the tap point in 250 ms. **Long-press 450 ms:** page or panel actions.
- **Horizontal swipe in vertical mode = chapter change** (Tapas iOS), with a 72 dp commit threshold and a rubber band before commit.

### 4.3 Vertical scroll physics

- **Native momentum only.** Do not scroll-jack the reader. On web, no Lenis or smooth-scroll libs in the reader, because trackpads and wheels must feel native. Use `overscroll-behavior-y: contain`. Reserve every panel's box from its image dimensions (`aspect-ratio`) so nothing jumps. Use `content-visibility: auto` with `contain-intrinsic-size` for off-screen panels.
- **Flutter:** Glass uses `BouncingScrollPhysics` (iOS rubber band) on **both** platforms. Cinematic uses `ClampingScrollPhysics` with the Android 12 **stretch** overscroll (`StretchingOverscrollIndicator`) on both. The physics is part of each skin's personality.
- **iOS reference:** `UIScrollView.DecelerationRate.normal` = 0.998 per ms, `.fast` = 0.99 per ms [obs]. Keep normal for reading.
- **Zoom:** 1x-3x (Mihon max 3). Glass may allow 0.6x zoom-out to show an "overview" of several panels. Zoom 200 ms decelerate, fling while zoomed 400 ms decelerate (Mihon).
- **Side padding presets:** 0 / 5 / 10 / 15 / 20 / 25 % (Mihon 0-25; Komga goes to 40). **Desktop:** strip width `clamp(480px, 50vw, 900px)`, with side panels in the rest of the width.
- **Auto-scroll:** Lezhin presets 1 / 1.5 / 2x. Proposed base = **60 dp/s at 1x**, with steps 0.5, 0.75, 1, 1.5, 2, 3x (30-180 dp/s). A touch pauses it. It resumes **800 ms** after release. The speed ramps in over 400 ms so it never lurches. On web desktop, add Readest-style middle-click autoscroll (12 px dead zone, 10 px/s per px, max 4000 px/s).

### 4.4 Chapter boundaries and "next chapter" cards

Three proven models:
1. **Inline transition card** (Mihon): "Finished: X / Next: Y", max width 460 dp, 20 sp names, a missing-chapters warning, and a preload trigger when the card comes into view.
2. **Pull-to-continue** (Kavita): a 20 px strip arms after 100 ms idle at the end, expands to 150 px (mobile) / 300 px (desktop), and fills a 3 px track at 60 ms linear. Crossing the end loads the next chapter.
3. **Post-play** (Netflix [web]): the credits shrink, and the next title's card and synopsis appear with a countdown (up to ~15 s, auto-plays by default).

Plus the end-of-episode social block (Webtoon: creator note, like, top comments, Next) and the release-date end state (MANGA Plus).

**Rules for us (shared):**
- The next chapter's first 3 pages **start preloading when the reader passes 70 %** of the current chapter. Full preload starts when the boundary card enters the viewport (`rootMargin: 150% 0px`).
- **Caught up:** show "You're caught up". If the source has a schedule, add the next expected date. Offer "Notify me" (update tracking) and "Similar series".
- **Missing chapters** between two chapters get a warning row (Mihon).
- **Read-All mode:** the boundary is a slim divider band, not a card, to match "without feeling it".
- The **haptic "medium" bump** fires the moment the boundary is crossed.

### 4.5 Progress indicators and scrubbers

- **Page label:** Mihon draws `#EBEBEB` text with a `#2D2D2D` stroke so it reads on any art. Kindle cycles page / location / time-left-in-chapter / time-left-in-book on tap. Audible toggles chapter vs total progress.
- **Scrubber:** Mihon's pill slider with a **haptic on every page step**, flanked by previous/next chapter buttons. Apple Books' touch-and-hold-Contents-then-drag scrubs the whole book. Readest's 3 px line on the mini player shows buffered at 35 % alpha.
- **Time left:** use the reader's own rolling pace (per-profile WPM for novels, panels per minute for manhwa), shown as "6 min left in chapter". Stay silent until there are at least 2 minutes of samples. Never show a made-up estimate.
- **Haptics:** a selection tick per page (iOS `UISelectionFeedbackGenerator` / Flutter `HapticFeedback.selectionClick()`), a light impact at every 10 %, a medium impact at a chapter boundary.

### 4.6 Brightness and reading-mode controls

- **Range -75..100** (Mihon). Negative values = black overlay at `|v|/100` alpha on top of the lowest system brightness. On AMOLED this is the true night mode.
- **Edge gesture:** a vertical swipe along the **left edge** (12 % band) changes brightness (Moon+ Reader, and every video player). A capsule HUD shows the level and fades 600 ms after release.
- **Filters:** warm tint (colour overlay with Multiply), grayscale, invert (Mihon), and four night-sepia levels "without flattening the contrast" (Frank Manga+).
- **Line Guide / reading ruler** for novels (Apple Books Line Guide; Moon+ has 6 ruler styles): dim everything outside the current line band. Tap above or below to move it, or drag it.
- **Keep screen on** in both readers (mobile already has `wakelock_plus ^1.2.8`). Brightness on Flutter: `screen_brightness` from pub.dev (sets window brightness without the system permission; check the current version at build time).

### 4.7 Novel typography controls

| Control | Range / values | Default | Source |
|---|---|---|---|
| Font size | 8-30 px (Kindle: 14 marked steps) | 18 px phone, 20 px desktop | Readest [src], Kindle [web] |
| Line height | 0.8-2.4, step 0.1 | 1.6 | Readest [src] |
| Margins | 10-step slider Small→Large | 24 px phone / measure-driven desktop | Readest [src] |
| Measure (desktop) | 52-80 ch | 66 ch (≈ foliate 720 px) | foliate-js [src] |
| Character spacing | −0.02 to +0.10 em | 0 | Apple Books [doc] (slider) |
| Word spacing | 0 to +0.30 em | 0 | Apple Books [doc] |
| Paragraph spacing | 0-1.2 em | 0.6 em | proposal |
| Bold text | on/off (swap to the 500-600 weight) | off | Apple Books [doc] |
| Justify + hyphenate | on/off (`hyphens: auto`, `text-wrap: pretty`) | off, ragged-right | Apple Books [doc], Moon+ [doc] |
| Page turn | Slide / Curl / Fast fade / Scroll | per skin (section 5) | Apple Books [doc] |

Put the whole panel in a **bottom sheet that covers ≤ 50 % of the height**, so the page updates live above it (Kindle). Add a **"Reset theme"** action (Apple).

### 4.8 Paper themes (dark only, computed contrast)

Pure white on pure black halates on OLED, so the text is off-white at about **13-15:1**. All themes pass WCAG AAA (≥ 7:1). The muted colour, used for headers, page numbers and footnotes, stays ≥ 4.5:1.

| Theme | Background | Text | Contrast | Muted | Contrast |
|---|---|---|---|---|---|
| Void (AMOLED) | `#000000` | `#D9D6D0` | 14.48:1 | `#8A877F` | 5.85:1 |
| Ink | `#0B0B0C` | `#E6E3DD` | 15.36:1 | `#8F8C86` | 5.87:1 |
| Night Paper (warm sepia) | `#15110C` | `#E8D8BE` | 13.42:1 | `#9C8E78` | 5.87:1 |
| Dusk (cool) | `#0D1117` | `#D3DAE3` | 13.43:1 | `#8590A0` | 5.85:1 |
| Moss (Kindle-green analogue) | `#0E130F` | `#D5DECF` | 13.57:1 | `#879384` | 5.84:1 |
| Rosewood | `#160E10` | `#EBD5D8` | 13.62:1 | `#A08A8E` | 5.90:1 |

For comparison: Readest dark sepia `#342e25`/`#ffd595` = 9.72:1; Kavita dark `#292929`/`#efefef` = 12.65:1. Values were computed with the WCAG relative-luminance formula this session.

### 4.9 Page-turn animations

| Style | Timing | Easing | Notes |
|---|---|---|---|
| Push/slide | 280-450 ms | tap: easeInOutQuad; release: easeOutCubic sped up by velocity, ≥ 90 ms | Readest [src] |
| Curl | 450 ms | same; radius `0.16·w·(1−p²)` | WebGL mesh (Readest), back = paper colour |
| Fast fade | 120-180 ms | linear or ease-out | Apple Books [doc] |
| Snap to page | 300 ms | easeOutQuad | foliate-js [src] |
| 3D (cube/flip/stack/sphere) | — | — | Mihon WebGPU [src]; novelty, not for reading |

Implementation notes:
- **Web:** paginate with CSS multi-column (the foliate-js approach). Slide and fade via the **View Transitions API**. Curl via a WebGL fragment shader over a captured bitmap (Readest's pipeline: capture, turn the live view instantly underneath, animate the capture).
- **Flutter:** use `FragmentProgram` runtime shaders for the curl (no dependency). Use `AnimatedSwitcher`/`PageView` for slide.

### 4.10 Zoom

Pinch 1-3x. Double-tap toggles 1x ↔ 2x at the tap point. Animations 200-250 ms decelerate. Fling while zoomed 400 ms decelerate (Mihon). Web desktop: Ctrl/Cmd+wheel zooms around the cursor, `+`/`-`/`0` zoom with the keyboard, and the zoom level shows in a transient chip for 1200 ms.

### 4.11 Bookmarks

- The position is always saved automatically (Apple Books). Bookmarks are **extra and intentional**.
- Toggle with `B` or a bookmark glyph. Kindle Touch also toggles a bookmark by tapping the top-right corner.
- Novels bookmark a **paragraph anchor**. Manhwa bookmarks a **page plus a scroll offset fraction**.
- Show bookmarks as **ticks on the scrubber track**. The list offers "jump", and after a jump the "back to where you were" chip appears (Apple Books).

### 4.12 Listen mode (31 named voices, cast, pre-rendered audio)

**Surfaces**
1. **In-reader mini player.** A 56 dp card with a 16 dp radius, a 3 dp bottom progress line (buffered at 35 %), cover, chapter title, "5:12 · −18:40" or "18 min left in chapter", and play/pause plus ±15 s buttons (Readest, Spotify). It rides with the chrome and **lingers 5000 ms** after the chrome hides (Readest), unless the user pins it. Swipe it horizontally to go to the previous/next chapter (Spotify's skip gesture).
2. **Full player sheet.** Title, big play (56-72 dp), transport, and three tiles: **Speed, Voice/Cast, Sleep**. Below them, a **lyrics-style sentence list** auto-centred on the spoken sentence (Readest / Apple Music). A user scroll decouples it and shows a "play from here" row. It returns automatically after **4000 ms** idle.
3. **Lock screen / notification / headset.** `just_audio ^0.9.40` plus `audio_session ^0.1.25` are already in the mobile app. Lock-screen controls need `audio_service` or `just_audio_background` from pub.dev (check versions at build time). Set the session as **speech**, as today.

**Highlight-as-read** (Speechify line+word, Readest active sentence)
- **Sentence:** a background band at 12-16 % alpha of the speaker tint (narration uses the neutral accent), with a 6 px radius, padded 2 px x 4 px, cross-fading 120 ms between sentences.
- **Word:** text brightens to 100 % plus a 2 px underline in the tint colour, stepping without animation (animating 4 times a second looks laggy).
- **Follow:** keep the active sentence at **38 % of the viewport height** (reading line). Scroll with 400 ms ease-out only when it leaves the 20-70 % band. Jump instantly if it is more than 2 viewports away (Readest).
- **Decouple:** when the user scrolls manually, stop following and show a **"Back to voice" pill** with glyph plus text (Readest `decoupled`). No auto-return in the page view (the user may be re-reading). Auto-return after 4000 ms in the lyrics view only.
- **Refuse rather than guess:** if the text no longer matches the timing map, highlight nothing and show a 1-line quiet notice "Highlight paused: text changed" (from `audio-follow.ts`).

**Speed:** a tick ruler **0.5-3.0x, step 0.05**, labelled marks at 0.5/1/1.5/2/2.5/3. The value previews while dragging and commits on release (Readest). Preset chips 0.8 / 1 / 1.25 / 1.5 / 2. **Touch-and-hold resets to 1x** (Apple Books). Show the WPM equivalent under the x value (Speechify; 1x ≈ the chapter's measured narration WPM). Keep pitch: on web `HTMLMediaElement.preservesPitch` (default true); on Flutter `just_audio.setSpeed` keeps pitch on both platforms.

**Sleep timer:** Off, 5, 10, 15, 30, 45, 60 min, **End of chapter**, **End of next chapter**, Custom. **Fade the volume out over the last 8 s.** **Shake to extend +5 min** on mobile (Audible). The countdown sits live on the Sleep tile and the mini player.

**Voice picker for 31 named voices + cast**
- **Picker:** a searchable grid (2 columns on phone, 4 on desktop) of voice cards: monogram avatar in the voice's own hue, **name**, gender, a timbre tag (warm / bright / deep / youthful…), and a **play-intro button** that plays the voice introducing itself (these clips exist). Filter chips: All / Female / Male / In use. The selected voice gets a check and a ring.
- **Cast panel (keep it small):** rows of *Character — tint swatch — voice name — share of lines (%)*. Narrator is pinned on top. Tapping a row opens the picker filtered to that gender. After a change, re-render that character's lines from the next sentence and label the row "Re-voicing…". Only these columns, never descriptions (see section 2).
- **Chapter boundary in listen mode:** here a **Netflix-style post-play countdown is right**. Show a "Next chapter in 5" card with a ring. Tapping cancels, "Play now" skips ahead. The chrome shows during the countdown.

### 4.13 Keyboard shortcuts (web, both skins, both readers)

The union of the current app's keys, Kavita [src] and Komga [src]. Existing bindings keep their meaning.

| Key | Manhwa / manga | Novel | Listen mode | Origin |
|---|---|---|---|---|
| → / D, ← / A | page turn by reading direction | next / prev page | — | current, Kavita, Komga |
| J / K | next / prev page | next / prev page | — | current |
| ↓ / ↑ | small scroll (native) | small scroll | — | native |
| Space / Shift+Space | forward / back one screen | page forward / back | — | current, Komga EPUB |
| Home / End | first / last page | chapter start / end | — | Komga, current |
| H / L | prev / next chapter | prev / next chapter | prev / next chapter | current |
| Ctrl+Shift+← / → | prev / next chapter (alias) | same | — | Kavita |
| G | go to page / % | go to % | — | Kavita |
| F | fullscreen | fullscreen | — | Kavita, Komga, current |
| C | cinema: hide all chrome | same | — | current |
| M | show/hide chrome | same | — | Komga |
| P | auto-scroll play/pause | — | **play/pause audio** | current |
| Shift+, / Shift+. (`<` `>`) | auto-scroll slower / faster | — | speed −/+ 0.1x | video-player convention |
| [ / ] | — | — | prev / next sentence | proposal |
| Shift+[ / Shift+] | — | — | back 15 s / forward 15 s | proposal |
| B | bookmark | bookmark paragraph | bookmark sentence | current |
| T | thumbnails / chapter list | type & page settings | — | Komga, current |
| , | reader settings | reader settings | — | proposal (Cmd+, convention) |
| S | series page | series page | — | current |
| = / + / − / 0 | zoom in / out / reset | text size + / − / reset | — | current |
| W / V / R | webtoon / vertical / RTL paged | — | — | Komga (L/R/V/W) |
| Esc | close overlay → leave fullscreen → exit | same | collapse player | current, Kavita |
| ? | shortcut overlay | same | same | current (Kavita/Komga use H, which is taken) |
| Middle-click | autoscroll anchor (12 px dead zone, 10 px/s per px, max 4000) | same | — | Readest |

Wheel in paged mode = one page per gesture, with a 200 ms idle reset (Readest). All bindings go through one remappable table (Kavita remaps every bind, and reserves Ctrl/Cmd+R).

---

## 5. Patterns to adopt

Shared **behaviour** (thresholds, zones, preload, state machines, keys) lives in section 4 and is the same in both skins, because it is the data/interaction layer. What follows is how each skin **looks, moves and feels**, plus the screen implementations that differ.

### 5.1 Cinematic skin (dark cinematic: Netflix / Apple TV+ / Crunchyroll)

Motion language: no bounce, film-like. Enter `cubic-bezier(0.16, 1, 0.3, 1)` (expo-out). Exit `cubic-bezier(0.7, 0, 0.84, 0)` (expo-in). Durations are short and confident. Where a spring is needed, use a critically damped one (response 0.30 s, damping 1.0 → stiffness 439, damping 41.9, mass 1).

1. **Chrome = scrims, not bars.** Top: a 112 px `linear-gradient(#000 0%, rgba(0,0,0,.72) 45%, transparent)` with back (44 px target), the series title in the display face (15-17 px, 600, tracking −0.01 em), and "CH 124" in the accent. Bottom: a 96 px reversed gradient. In: 220 ms opacity plus 8 px translate (expo-out). Out: 160 ms (expo-in).
2. **Video-player timeline scrubber.** A full-bleed **3 px rail** that grows to 6 px when touched. The thumb grows from 12 to 20 px. The track is `rgba(255,255,255,.2)`, the fill is the accent, with a 2 px gap between chapter segments in Read-All mode (like YouTube chapters). On desktop hover, show a **panel thumbnail preview** (120 px wide) above the thumb with "Page 18 / 64". To the right: "7 MIN LEFT" in small caps. Haptics: selection tick per page, medium bump at chapter segments.
3. **Always-on micro progress.** When the chrome is hidden, a 2 px accent line stays at the very bottom (Readest's 3 px mini-player line and Netflix's scrub line). Turn it off with cinema mode (C).
4. **Dynamic page colour.** Sample the dominant colour of the panel in view every 600 ms. Cross-fade over 900 ms into a **glow under the bottom rail** and a 24 % tint in the top scrim (the owner's "chrome tinted by dynamic color").
5. **End of chapter = "credits" sequence.** After the last panel: 96 px of black, then "END OF CHAPTER 124" using the required **letter-by-letter fade-up-unblur reveal**, then a reactions row (social feature), then an **"UP NEXT" hero card**. The card is 16:9, shows the next chapter's first panel cropped and blurred 24 px behind a sharp inset thumbnail, a title line, "Chapter 125 · 42 panels · ~6 min", and a solid accent **Read next** button (48 px, radius 6). Past the card, a Kavita-style **pull-to-continue** region (150 px mobile / 300 px desktop) fills a 3 px accent track. Crossing it gives a medium haptic, then a 250 ms **fade-through-black cut** into the next chapter, whose title types in at 50 ms per character.
6. **Read-All divider:** a 48 px band with a hairline, "CHAPTER 125" (letter reveal) and the chapter title. No card, no pause.
7. **Brightness HUD:** left-edge vertical swipe → a 6 x 140 px capsule HUD with a sun glyph, in the style of a movie player. Below 0 it becomes a "NIGHT −40" black overlay. **Right-edge vertical swipe changes auto-scroll speed** while auto-scroll runs (the volume-gesture analogue), with a "1.5×" HUD.
8. **Auto-scroll as playback.** A floating "▶ 1.5×" chip bottom-right, and P / Space to play or pause. Speed changes are shown with a 700 ms HUD.
9. **Novel page turns:** default **Slide/push, 300 ms `cubic-bezier(0.2, 0, 0, 1)`**, plus **"Cut"**: a 140 ms cross-fade with 12 px parallax (a film cut). No curl in this skin. Cinematic is about motion pictures, not paper.
10. **Novel typography chrome:** the settings sheet is a dark `#0A0A0A` panel covering ≤ 50 % height, with segmented controls in the display face and live preview above. Themes appear as "film stock" swatches: Void, Ink, Night Paper, Dusk, Moss, Rosewood (section 4.8).
11. **Listen mode = "Now Showing".** The full player uses the cover art as a full-bleed background, blurred 40 px with a 60 % black scrim and the dynamic colour glow. The lyrics-style sentence list sits in large type (20 px): the active sentence is 100 %, the others 35 %, like cinema subtitles. The mini player is a flat `#141414` bar pinned above the bottom scrim, with a 2 px accent progress line along its top edge (Spotify-style colour tint from the cover).
12. **Voice picker = casting board.** A horizontal rail of tall 3:4 "headshot" cards (monogram on a hue gradient), with name, timbre tag and a play-intro button. The cast panel is a "credits" list: *Character ....... Voice*.
13. **Listen chapter boundary = Netflix post-play:** a card with a 5 s ring countdown, "Play now" and "Cancel", and the next chapter's title typed in.
14. **Haptics feel physical and short:** a light impact on chrome show (none on hide), selection ticks on the scrubber, a medium impact at chapter boundaries, a heavy impact once when auto-scroll hits the end.

### 5.2 Glass skin (Apple Liquid Glass / visionOS depth)

Motion language: springs everywhere, with some bounce. Chrome response 0.35 s, damping 0.80 (stiffness 322, damping 28.7). Sheets 0.50 s, 0.86 (158, 21.6). Scrubber thumb 0.25 s, 0.70 (632, 35.2). Page settle 0.42 s, 0.92 (224, 27.5). All springs use mass 1; the stiffness/damping values work in Flutter `SpringDescription` and framer-motion 12 `type:"spring"`.

1. **Floating capsules instead of bars.** Top-left: a 44 px circular glass back button. Top-centre: a title capsule (series · Ch 124). Bottom: a **56 px capsule toolbar, 28 px radius, inset 16 px** from the sides plus the safe area. **Legibility floor over busy art** (NN/G found Liquid Glass fails over images): backdrop `blur(28px) saturate(180%)`, a mandatory tint of `rgba(0,0,0,.38)`, a 0.5 px inner stroke `rgba(255,255,255,.18)`, and a 1 px top specular highlight `rgba(255,255,255,.35)`. Label text stays ≥ 4.5:1 against the darkest possible backdrop.
2. **Minimise instead of vanish.** On scroll down, the bottom capsule **morphs into a small pill** (page count only, 32 px tall), the way iOS 26 `tabBarMinimizeBehavior(.onScrollDown)` minimises the tab bar. On scroll up it springs back to full size. The top capsules fade and blur out (8 px blur, 0.92 scale) and fade back in.
3. **Mini player = tab-bar accessory.** In listen mode, the mini player is a glass row above the toolbar capsule. When the toolbar minimises, the mini player **slides down inline next to the pill**, exactly as iOS 26 `tabViewBottomAccessory` behaves.
4. **Liquid scrubber.** A glass capsule slider, 44 px tall. The thumb **stretches in the drag direction** (width 1.0 → 1.25 at speed, back via the thumb spring). A **magnifier lens** above the thumb shows the page number and a mini panel preview. Haptics: selection per page, rigid impact at chapter ends, soft impact on release.
5. **Sheets with detents for everything** (typography, reader settings, chapter list, cast, voice). Medium detent ≈ 50 % (Kindle's live-preview rule). At medium the sheet **floats inset 12 px with a 36 px concentric radius**. At large it goes edge to edge. The page behind scales to 0.94 with a 20 px radius (depth).
6. **Novel page turn = Curl by default.** 450 ms, finger-tracked, settle on the page spring. Curl radius `0.16·w·(1−p²)`. The back of the page is paper colour at 92 % with the mirrored text ghosted at 6 %. Options: Slide (spring), Fast Fade (160 ms), Scroll. On web: WebGL shader over a captured page. On Flutter: a `FragmentProgram` shader.
7. **Chapter end = rising glass card.** Past the last panel, the scroll **rubber-bands** (bouncing physics). At **90 px** of overscroll a glass "Next chapter" card rises from the bottom as a medium-detent sheet. It shows the next chapter's first page as a tilted 3D thumbnail (visionOS depth, 8° tilt that follows the device gyro ±4°), the title, and "Continue". Release past the threshold → soft-then-rigid haptic → the card expands to full screen (shared-element zoom) into the next chapter.
8. **Read-All divider:** a floating glass chip "Chapter 125" that sticks to the top for 1.2 s as the boundary scrolls under it, then melts away (blur plus fade).
9. **Brightness in a Control-Center-style tile.** In the reading sheet, a tall 72 x 160 px glass fill-slider with a sun glyph that fills from the bottom. Night filter and Line Guide are tiles beside it. The Line Guide is frosted bands (blur 6 px, 55 % black) above and below the current line.
10. **Depth-based tap feedback.** A tap in a zone shows a soft radial light (a 120 px glow at 10 % white) that fades in 300 ms, the way visionOS highlights on gaze/tap. The first-run zone overlay is made of three glass panes with labels.
11. **Novel typography sheet:** glass controls, live preview above. Paper themes are round "orbs" (same palettes as section 4.8) with a specular highlight. Sliders tick with haptics at every step (font size, line height, margins).
12. **Listen full player = floating glass window.** Artwork on a glass card with parallax (the gyro tilts the art ±6 px). The lyrics-style sentence list sits on glass, with the active sentence on a brighter glass lozenge that **morphs** from sentence to sentence (shared layout animation, 280 ms spring) instead of cross-fading. The "Back to voice" pill is a small glass capsule.
13. **Voice picker = orbit carousel.** The 31 voices sit on a horizontally scrolling carousel with depth: the centre card is at 1.0 scale, the neighbours at 0.86 and 60 % opacity. The centred voice **auto-plays its intro after 400 ms of rest**. A grid view is one tap away (searchable, filterable). The cast panel is a sheet of glass rows.
14. **Speed dial like Apple Books.** Tap "1x" to open a vertical dial capsule and drag up or down (0.05 steps, labelled marks, a haptic per 0.25). Touch and hold resets to 1x. Sleep options appear as a glass menu with the live countdown in the tile.
15. **Haptics feel soft and springy:** a soft impact on capsule expand/minimise, selection ticks on sliders and dials, a rigid impact at chapter ends, a success notification when a bookmark is added.

### 5.3 Both skins (non-negotiable)

- The same thresholds, tap layouts, keymap, preload rules, follow/decouple logic, and sleep and speed ranges (section 4). A skin switch never changes what a key or zone does.
- `prefers-reduced-motion` / iOS Reduce Motion / Android "Remove animations": every spring and slide becomes a 120 ms opacity fade. Curl falls back to fast fade. Letter reveals show the text at once. The 3D tilt turns off.
- **Tap targets ≥ 44 x 44 pt** even inside compact glass capsules (NN/G: crowding was the other Liquid Glass failure).

---

## 6. Open questions for the owner

1. **Light paper for novels?** The decisions say "dark only". Apple Books and Kindle readers often read on light paper at night with low brightness. The proposal keeps every paper dark (section 4.8). Confirm there is no light paper, even inside the novel page.
2. **Default manhwa tap behaviour:** "tap = chrome" (Webtoon) is proposed as the default, with tap-to-scroll opt-in. Confirm.
3. **Listen-mode auto-advance:** is a 5 s post-play countdown right, or should the next chapter start seamlessly (true audiobook)?
4. **Shake to extend the sleep timer:** on or off by default?

---

## 7. Sources

Code (read this session):
- Mihon: `app/src/main/java/eu/kanade/tachiyomi/ui/reader/viewer/navigation/*.kt`, `viewer/webtoon/WebtoonViewer.kt`, `WebtoonRecyclerView.kt`, `setting/ReaderPreferences.kt`, `ReaderNavigationOverlayView.kt`, `presentation/reader/ChapterTransition.kt`, `components/ChapterNavigator.kt`, `ReaderPageIndicator.kt`, `appbars/ReaderAppBars.kt`, `settings/ColorFilterPage.kt`, `ReaderContentOverlay.kt`, `viewer/ReaderPageImageView.kt`
- Kavita: `UI/Web/src/app/_services/key-bind.service.ts`, `manga-reader/_components/manga-reader/manga-reader.component.{ts,scss}`, `manga-reader/_components/infinite-scroller/infinite-scroller.component.ts`, `shared/_components/pull-to-load/*`, `book-reader/_components/reader-settings/reader-settings.component.ts`
- Komga: `komga-webui/src/functions/shortcuts/*.ts`, `types/enum-reader.ts`, `components/readers/PagedReader.vue`, `views/DivinaReader.vue`
- Readest: `apps/readest-app/src/app/reader/components/tts/{TTSMiniPlayer,TTSPlayerSheet,TTSLyricsView,TTSFollowIndicator,SpeedRuler,TickRuler}.tsx`, `useMiniPlayerAutoHide.ts`, `app/reader/utils/{capturedTurn,autoscroller,wheelGesture}.ts`, `utils/pageCurl.ts`, `components/footerbar/FontLayoutPanel.tsx`, `styles/{themes.ts,globals.css}`, `types/book.ts`
- foliate-js: `paginator.js`
- ManhwaManiacs (feature inventory only): `frontend/src/features/reader/{keymap,use-reader-shortcuts}.ts`, `features/novels/{use-novel-shortcuts,audio-follow,speaker-tint}.ts`, `features/novels/components/{NovelVoicePicker,NovelCastPanel,NovelAudioPlayer}.tsx`, `features/reader/components/ReadAllReader.tsx`, `mobile/pubspec.yaml`

Web:
- [Apple Support — Read books in the Books app on iPhone (iOS 27)](https://support.apple.com/guide/iphone/read-books-iphc1af7c57/ios)
- [Apple Support — Listen to audiobooks in Books on iPhone](https://support.apple.com/guide/iphone/listen-to-audiobooks-iphac1971248/27/ios/27)
- [The eBook Reader — Kindle's new Aa menu](https://blog.the-ebook-reader.com/2020/04/09/this-is-what-the-kindles-new-aa-menu-looks-like/)
- [Good e-Reader — Kindle saves preferred fonts & layout](https://goodereader.com/blog/kindle/amazon-kindle-can-now-save-preferred-fonts-layout-settings)
- [ManualsLib — Kindle Paperwhite tap zones](https://www.manualslib.com/manual/1039286/Amazon-Kindle-Paperwhite.html?page=15)
- [Thomas Park — Kindle Touch gestures](https://thomaspark.co/2012/01/kindle-touch-gestures/)
- [WEBTOON notice 739](https://www.webtoons.com/en/notice/detail?noticeNo=739), [WEBTOON Help Center](https://help2.line.me/LINE_WEBTOON/android/categoryId/20006011/3/pc?lang=en)
- [Grokipedia — Auto-scrolling apps for webtoons (Lezhin presets)](https://grokipedia.com/page/Auto-scrolling_apps_for_webtoons)
- [Tapas — What is 1-Tap](https://help.tapas.io/hc/en-us/articles/360033559694-What-is-1-Tap)
- [AkitaOnRails — Frank Manga+ (MANGA Plus desktop client)](https://akitaonrails.com/en/2026/05/30/manga-plus-shueisha-on-the-desktop-frank-manga-plus/)
- [Moon+ Reader — Google Play listing](https://play.google.com/store/apps/details?id=com.flyersoft.moonreader)
- [Android Authority — Audible listening settings](https://www.androidauthority.com/audible-listening-settings-3667303/), [Audible — Narration Speed](https://www.audible.com/ep/NarrationSpeed)
- [Speechify — Listening features](https://speechify.com/blog/listening-features/), [Speechify App Store listing](https://apps.apple.com/us/app/speechify-text-to-speech-pdf/id1209815023)
- [Free Your Music — Spotify sleep timer](https://freeyourmusic.com/blog/how-to-set-spotify-sleep-timer), [Viwizard — Spotify playback speed](https://www.viwizard.com/spotify-music-tips/change-spotify-playback-speed.html)
- [TechJunkie — Netflix autoplay next episode](https://www.techjunkie.com/how-to-stop-netflix-from-automatically-playing-the-next-episode/), [TechCrunch — Netflix Post-Play](https://techcrunch.com/2012/08/15/netflix-post-play/)
- [Donny Wals — iOS 26 tab bars](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/), [WWDC25 — Build a UIKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/284/), [Create with Swift — tab bar bottom accessory](https://www.createwithswift.com/enhancing-the-tab-bar-with-a-bottom-accessory/)
- [NN/G — Liquid Glass is cracked, and usability suffers in iOS 26](https://www.nngroup.com/articles/liquid-glass/)
