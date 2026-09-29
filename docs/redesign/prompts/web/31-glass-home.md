# Web Glass Home with AI rails

Track: web · Order 80 · Depends on: `docs/redesign/prompts/web/30-glass-auth-profiles-onboarding.md` · Runs in parallel with: `docs/redesign/prompts/mobile/31-glass-home.md` · Proof folder: `docs/redesign/proof/web-31/`

## Goal

Build the Glass skin's Home at `/` (ScreenId `tonight`) on the web client, exactly as `glass/DESIGN.md` §8.8 and §9.1.1 specify: the greeting typed at 50 ms per grapheme with its streak subline; the hero spotlight (up to six cards, a floating 2:3 card over its own blurred enlargement, the one lit action casting its caustic, tilt, one card per flick with projection, droplet page dots, the desktop stage) whose paging re-lights the whole screen (Light follows the story); Continue reading; the AI rails with the machine light and their `why` lines; throwing an AI card sideways for "Not interested" with Undo; dragging a poster onto a friend's orb to recommend it; the Updates bell with its count; the ambient field following the story; pull to refresh with `GET /home?refresh=1`; the Home items of the dock's long-press menu; and every state (loading, new profile, AI unavailable, offline, error, caught up, rate limited, stale). The data comes only through the shared `useHomeFeed()` (`frontend/src/features/home/`, built by `web/08`), extended here without changing Cinematic's behaviour. When you finish, `tonight` leaves the Glass `PENDING` set. Glass stays behind the debug row.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it: Home is Netflix / Crunchyroll browse with a hero spotlight, rails and continue reading; AI home with "because you read X" and the loading and "AI unavailable" states; the main headline typing reveal at 50 ms per character).
2. `docs/redesign/stack-decision.md` §2.6 (one data layer: `useHomeFeed()` with `state: 'loading' | 'ready' | 'empty' | 'unavailable'`; AI rails computed on the server).
3. `docs/redesign/glass/DESIGN.md`:
   - §8.8 (all of it), §9.1.1 (all of it), §9.1.3 (the recap offer thresholds and `mm.recap`), §9.1.5, §9.1.6, §9.2.2 (the streak states, at risk, Streak +1 and the Plus one move), §9.3.4 (the friend-orb gesture, its states, the 18+ rule).
   - §2.1.8 (Home 26 %, the hero enlargement 36 %, Light follows the story, text over bright fields uses `label2`), §2.1.7 (the hero controls' `Lb` is the spotlight palette's `lMax`; `dimClear` under clear glass when `Lb > 0.45`), §2.1.9 (machine, people and warmth lights), §2.4.1 rule 2 (the two page-level glass controls: the lit action and the "Details" secondary), §2.4.2 rules 5 and 8, §2.4.4 (caustic), §7.7 (continue stack, world card, stat card), §7.8, §7.9, §7.33, §7.38, §8.0.2 (Home in the IA), §8.0.4 (tab root arrival, zooms, dives), §8.0.8 (content mode, gate purge of cached payloads), §10.1 placements 2 and 3, §10.2 placement 1 and its Playwright check, §11 rows "Throw a lifted poster up", "Throw a lifted AI card sideways", "Drag a lifted poster onto a friend orb", "Horizontal swipe / Home spotlight", "Tilt the device", "Pull down at the top", §13 moments 3, 4, 11, 23, §15.7 (the phone budget), §15.8 ("Signature animations actually play").
   - §4.10 rows Spotlight drop, Field ripple, Light follows the story, Letter reveal (live), Typing reveal, Hero tilt, Throw, Wave, Surface from depth, Plus one, Meniscus refresh, Count pop, Zoom, Dive; the bell pendulum of §2.7's icon-motion table.
4. `docs/redesign/cinematic/DESIGN.md` §9.1.7 (the `GET /home` payload and the per-section item shapes: `continue`, `new_this_week`, `almost_there`, `where_were_we`, `sent_to_you`, `picked`, `because`, `first_picks`, `popular`, `circle`, `circle_top`, `sources`, `genres`, `numbers`), read with `docs/redesign/prompts/backend/04-ai-home-composition.md` §E (reasons, sections, `fallback`, `refresh`).
5. `docs/redesign/inventory/web.md` §7.1 (LS1–LS12: the landing role Home replaces), §2.5–§2.7 (G32–G40), §20 MO2, and `inventory/capabilities.md` §8 and §9 (continue reading, world recommendations, `WorldItem`, `available`).
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts-plan.json`: the `web/00` entry (its `TRACK RULE`) and this file's entry.
8. Code you build on:
   - The shared home data layer (`web/08`, `web/19`): `features/home/{types,api,use-home-feed,local-feed,offline-edition,continue-hidden,rerank}.ts` (`useHomeFeed()`, `homeFeedQueryKey()`, `homeApi.get`, `composeOfflineEdition`, `filterHidden`, `hideContinue`, `unhideContinue`, `rerankRails`, `noteOpenedFromRail`), `features/ai/{feedback,state}.ts` (`sendAiFeedback`, `aiState`, `staleDays`), `features/recap/recap-setting.ts`, `features/library/{hooks,streak,url-state,genre-weights}.ts` (`useGenreWeights`, `web/16`), `features/updates/hooks.ts` (`useUnreadNotificationCount`, `useMarkAllNotificationsRead`), `features/offline/{hooks,mature-filter}.ts`, `features/circle/hooks.ts` (`useRecipients`, `useSendLetter`, `useSharing`), `features/sources/cover-transition-name.ts`, `features/content-mode/`.
   - The Glass skin: `web/29`'s `useTopBar`, `NavRow`, `Toolbar`, `accessory-store.ts` (`setAccessoryContinue`), `dock-menus.ts` (`registerDockMenu`), `GlassLink`, `enter-reader.ts`, `SheetHost` (`openSheetRoute`), `sheet-registry.ts` (whether `offer` and `letter-note` are registered), `wave-origin.ts`, `useRefreshKey`, `error-surface.ts`, `useRateLimitCapsule`; `web/26`–`web/28` primitives: `TypedHeadline`, `LetterReveal` (`mode="live"`), `Button`, `IconButton`, `Badge`, `Chip`, `ChipRow`, `Poster` (lift, throw, `allowAway`, targets), `Rail`, `RailGroup`, `cards/{ContinueStack,WorldCard,StatCard}`, `Skeleton`, `wave.ts`, `ProfileOrb`, `Menu`, `ContextMenu`, `useContextPreview`, `showToast`, `PullToRefresh`, `ContentModeSwitch`, `ObjectLens`, `MachineBadge`, `ThinkingOrbit`, `AiNotice`, `AiStamp`, `copy/ai.ts`; `glass/{AmbientField,Caustic,useLb,useLightAngle}.ts(x)`, `physics/{project,magnet}.ts`.
   - Fixtures: `frontend/e2e/fixtures/home/` (`web/08`'s `GET /home` responses per state), `frontend/public/skin-preview/covers/` (demo covers).

## Preconditions (check before writing the plan)

- `git log --oneline -40` shows `web/30`; the Glass login, picker and onboarding specs pass.
- `ls frontend/src/features/home/` lists `use-home-feed.ts`, `api.ts`, `types.ts`, `offline-edition.ts`, `continue-hidden.ts`, `rerank.ts`; `grep -rn "skins/" frontend/src/features/home` is empty.
- `curl -s "http://127.0.0.1:8010/home?content_kind=manga&tz_offset_minutes=330&refresh=1"` with the demo session answers 200 once the dev stack runs (backend/04's `refresh` parameter); `grep -n '"palette"' -r backend/services | head -1` finds the palette field (backend/01).
- `ls frontend/e2e/fixtures/home/` lists the state fixtures.
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-31/plan.md` (commit it with the proof).
2. `superpowers:test-driven-development` for the pure files (`spotlights.ts`, `home-rails.ts`, `greeting.ts`, the `refresh` change in `features/home`): vitest first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 4 implementer subagents, split by family (data mapping and greeting; spotlight and field; rails, AI cards and the friend orbs; states, refresh and checks). Start each subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the screen (the art lights the room; one lit action; the machine light only on AI output; content never glass).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Files live in `frontend/src/skins/glass/screens/home/`; register `tonight: Home` in `skins/glass/index.ts` and remove `tonight` from `PENDING`. Every named move goes through `play()`; every live glass surface is a `GlassSurface` in the budget; everything repeated per item is content (cards, posters, chips, rail arrows). Sections cited are `glass/DESIGN.md` unless named otherwise. All copy below is exact.

### A. Data: the shared feed and its Glass mapping (`features/home/api.ts` and `use-home-feed.ts` additions; `screens/home/home-rails.ts`, `spotlights.ts`, `greeting.ts`)

1. **Refresh, skin-neutral:** add `refresh?: boolean` to `homeApi.get()` (sends `refresh=1`; Cinematic never passes it) and `refreshHomeFeed(queryClient, keyParts)` in `use-home-feed.ts`, which fetches with `refresh: true` and writes the result into `homeFeedQueryKey(profileId, matureEnabled, contentKind)` with `setQueryData`, returning `{ changed }` (true when `generated_at` or any section's item ids differ). Extend the existing tests; nothing else in `features/home/` changes.
2. **`home-rails.ts`** (pure, tested): maps `HomeFeed` + client inputs to Glass rails in this order, each `{ id, kind, title, subtitle?, items, state, ai: boolean, seeAll? }`; a rail with no items is omitted, except AI rails in the `unavailable` state:
   1. `first_picks` → "Start here" (only when present).
   2. `continue` → "Continue reading" (`ContinueStack` cards; rows passed through `filterHidden`); See all → `/library/history`.
   3. `new_this_week` → "Updated for you" (posters with "N NEW" badges); See all → `/updates`.
   4. `because` (one rail per section, up to 3) → "Because you read {seed.title}" (AI); See all → `/library/recommendations`.
   5. `picked` → "For you" with the subtitle "Picked from what you read" (AI); See all → `/library/recommendations`.
   6. `almost_there` → "Almost there" (posters captioned "2 chapters left" / "1 chapter left" from `chapters_left`); See all → the Library URL filtered to `reading_status=reading` (`features/library/url-state.ts`).
   7. `sent_to_you` + `circle` + `circle_top` → "From your Circle" (letters first, then friends' reads, de-duplicated by series); See all → `/circle?tab=letters`.
   8. `genres` → "Your genres" (a chip row, not a poster rail).
   9. `popular` → "Popular on your pinned sources" (new profiles only).
   10. `sources` → "New in your pinned sources" (a mini rail per pinned source; `suggested` sources captioned "Suggested sources"); See all → `/sources`.
   11. Client: "Ready offline" = the downloaded series from the offline index (`useOfflineState()`), through `filterMature`, most recently saved first, up to 12; See all → `/downloads`.
   12. Client: "Recently added to your library" = `useAllFollowedSeries()` sorted by `created_at` descending, the first 12 (in the current content mode); See all → the Library URL sorted by date added.
   13. `numbers` → the "This week" card.
   `where_were_we` feeds only the spotlight (A3 candidate 5). Apply `rerankRails()` to the AI rails' order (never above Continue). Offline (`origin === "offline"`): only "Ready offline" (the edition's `saved`) and "Continue reading" (its `continue`, downloaded only).
3. **`spotlights.ts`** (pure, tested; `composeSpotlights(feed, { now, offline })`, at most 6, de-duplicated by `source_id:series_key`), in this order:
   1. **Next up:** the first `continue` item with `new_count ≥ 1`, else the `cover` when its `reason` is `new_chapters` or `in_progress`: meta "Ch 143 is new · Manhwa" (new) or "Ch 142 · p. 18 of 40" (in progress; novels "42 % in"); primary "Continue Ch 143"; an unopened next chapter (`page_count == 0`) reads "Start Ch 143".
   2. **Because you read:** the first item of the first `because` section: meta "{format} · {status}" from the `WorldItem`, the `why` line with the machine sparkle; primary "Start reading" (an info-only item: "Search my sources").
   3. **A letter:** the first `sent_to_you` letter: a `bloom` chip "{from.name} thinks you'd like this"; primary "Start reading".
   4. **Newest update:** the first unused `new_this_week` item: meta "{n} new chapters" ("1 new chapter"); primary "Continue Ch {n}".
   5. **Previously on candidate:** the first `where_were_we` item, else a `continue` item with `paused_days ≥ 7`, whose `recap.available` is true: meta "Paused {n} days"; primary "Continue Ch {n}"; its secondary is "Previously on" (in place of "Details").
   6. **Wrapped** (local month 12 only): title "Your {year} in chapters", meta "Wrapped", primary "Open Wrapped" → `/library/statistics/annual/{year}`; its card face is the year in `display` on the brand aurora (no cover).
   **Caught up** (the `cover.reason` is `caught_up`, or no Next up and no newest update): the first card reads "You're caught up" with meta "Nothing new on your shelf" over the cover of candidate 5 (primary "Previously on") or of the AI pick (primary "Start reading"). **New profile** (nothing followed and nothing read): one card from the first `first_picks` or `popular` item, meta "Start here", primary "Start reading". **Offline:** one card for the most recently read downloaded series (the offline edition's cover).
4. **`greeting.ts`** (pure, tested): the greeting by local hour: "Good morning, {name}" (05–12), "Good afternoon, {name}" (12–17), "Good evening, {name}" (17–22), "Good night, {name}" (22–05), with the active profile's name; the subline pieces "{n} new chapters" ("1 new chapter", from `useUnreadNotificationCount()`) and the streak chip "{d}-day streak" (from `feed.streak.current_days`, shown from 1 day), joined by " · ", omitted when zero; **at risk** (local time 20:00 or later, `current_days >= 2`, nothing read today per `last_active_date`): the subline is "Read one chapter to keep your {d}-day streak" in `label1`, never red.

### B. The screen frame, greeting and chrome (`screens/home/Home.tsx`, `Greeting.tsx`, `HomeChrome.tsx`, §8.8)

1. **Redirect:** while the active profile's `onboarding_step` is not `"done"`, `router.replace("/welcome?step=" + resumeGlassStep(step))` (`web/30`) before any rail paints.
2. **Top bar** (`useTopBar`): phone nav row: leading the profile orb with its goal ring (tap → You, long-press → the switcher, `web/29`), `contentModeSwitch: true`, trailing a glass group of the **bell** (`bell-simple`, "Updates", the count badge "9+" above nine, → `/updates`; when the unread count rises while Home is mounted the bell swings as a pendulum about its top pivot, initial angular velocity 6 rad/s on `tick`; reduced motion: no swing) and ⋯ (a `Menu`: Refresh, Ask for something to read → `/library/recommendations`, Updates, Mark all read). Desktop toolbar: the title "Home" once the greeting scrolls away, trailing the bell and ⋯ (the shell appends the shortcuts button).
3. **Greeting:** `TypedHeadline as="h1"` in `largeTitle` (typed key `"{profileId}:home-greeting"`, once per app session), 16 px below the nav row (desktop: at the 76 px top inset); the subline in `footnote` `label2` (over the field's top 60 %, `label2` holds at 36 %), whose streak piece is a content chip (`fill2`, 32 tall in a 44 px hit, a 16 px `flame` Fill in `streak` `#FF8A3D` and the label) linking to `/library/statistics`; at risk the flame shrinks to 0.8 and loses its core colour (`streakCore` → `streak`). **Plus one:** not built here; `web/42` owns the streak events and adds the Plus one over this chip (the same split as `mobile/31`). Give the chip a stable `data-streak-chip` anchor for it.
4. **Ambient field:** the source is the focused spotlight's cover palette at 26 % (before data: the profile's mood); changing the spotlight runs Light follows the story (the three blobs, every glass rim tint and the dock droplet tint slide to the new palette over `tintShift` 900 ms; reduced motion: a 200 ms cross-fade). On the first paint of the feed, the Field ripple: a ring 12 % brighter than the field expands from the spotlight card's centre to the farthest screen corner over 600 ms on the `fadeIn` curve while fading to 0 (none under reduced motion).
5. **Signature moment:** the greeting types while the spotlight card drops into place on `lens` (scale 0.9 → 1 and 24 px above → 0, Spotlight drop), together with the field ripple; reduced motion: the text shows at once and the card fades in over 200 ms.
6. **Arrival:** as a tab root the destination cross-fades over 120 ms and the entrance wave radiates from `useWaveOrigin()` (the tapped tab); from the profile hand-off or onboarding the Shell materialises around the landing orb (`web/29` arrival) and Home runs its signature moment.
7. **Content mode:** switching refetches the feed for the new `content_kind` and the rails wave from `lastModeSwitchOrigin`.
8. **Dock long-press:** `registerDockMenu("home", …)` with Updates (→ `/updates`), Mark all read (`useMarkAllNotificationsRead()`, toast "Marked all as read"), Continue last read (the Dive into `useContinueReading(1)`'s item).
9. **Accessory:** while the spotlight region is outside the viewport (an `IntersectionObserver`, threshold 0), `setAccessoryContinue(firstContinueItem)`; cleared when it returns and on unmount.

### C. The hero spotlight (`screens/home/Spotlight.tsx`, `SpotlightCard.tsx`, `SpotlightStage.tsx`, `HeroField.tsx`, `useHeroTilt.ts`, §8.8)

1. **Phone:** a horizontal pager of cards (a CSS scroll-snap row with `scroll-snap-type: x mandatory; scroll-snap-stop: always; overscroll-behavior-x: contain`, so one card per flick; programmatic paging with Motion `animate(scrollLeft)` on `settle`; the index settles on `scrollend`). Each card: the cover 2:3 at 62 % of the screen width, radius 26, centred, in front of its own blurred enlargement (`HeroField`: the spotlight palette's three blobs at 36 % behind the card area, radial gradients on one element, no filter, content layer); under the card the title in `title1` through `LetterReveal mode="live"` (it re-reveals whenever the page changes; the old letters leave together over `fadeOut` with blur 4 px), the meta line in `footnote` `label2`, the `why` line in `footnote` italic `label2` after the `MachineBadge` when the pick is AI's, or the `bloom` chip for a letter. **Actions** sit over the card's lower edge (16 px from its bottom, centred, 8 px apart): the tinted M "Continue Ch 143" (the screen's one lit object, wrapped in `CausticWrap` so its caustic falls on the cover; `tap.primary`) and a `glassClear` "Details" (or "Previously on" for candidate 5) whose `Lb` is the spotlight palette's `lMax`, with `dimClear` `rgba(0,0,0,0.35)` beneath when `Lb > 0.45`. These two are the page's two allowed glass controls in scrolling content (§2.4.1 rule 2); while the spotlight is outside the viewport they render as their content twins, so they leave the budget. Below the text: droplet page dots (6 px `g500` dots; the current one an 18 × 6 `iris400` capsule sliding on `tab`), each a real 44 px button "Show spotlight 3 of 6".
2. **Tilt** (and the cursor: the spotlight card carries `data-cursor="grab"`, `grabbing` while lifted, the `web/26` §7.40 contract): the card tilts up to ±6° (`rotateX`/`rotateY` on `track`) from device orientation on mobile web (only with `mm.glass.prefs.lightFollowsDevice` on and, on iOS Safari, the motion permission granted) or from the pointer on desktop, its specular rim following (`useLightAngle`). Reduced motion or the switch off: no tilt.
3. **Paging** changes the ambient palette (B4), re-reveals the title and announces "2 of 6: Solo Leveling" in a polite live region. The rubber band at the first and last card is the browser's (iOS Safari), capped visually at 25 % of the width where the platform stretches.
4. **Desktop and tablet stage:** 440 px tall (tablet 360): the cover card 240 px wide at the left over the enlargement filling the stage width; at the right the title in `display` (`LetterReveal mode="live"`), meta, `why`, and the two actions; bottom-right a strip of the next four spotlight covers (48 × 72, radius 10, content buttons "Show {title}"); `←`/`→` (when the stage has focus) and the strip page it; hover tilts the card toward the pointer; it never auto-rotates.
5. **Opening:** tapping the card (its cover is a `GlassLink` beneath the actions) zooms into the series through the `feature` sheet route (`openSheetRoute` with `coverTransitionName`); the primary dives into the reader (`enterReader`) or opens the recap offer (E3); "Details" opens the series; "Open Wrapped" pushes Wrapped. **Long-press** lifts the card like a poster (the `web/26` lift and throw): throw up opens it with the throw's velocity (a hard throw lands at `large`), dropping it on a friend orb recommends it (F).
6. **Semantics:** the spotlight is `role="region"` `aria-roledescription="carousel"` `aria-label="Spotlight"`; each card `role="group"` `aria-roledescription="slide"` `aria-label="2 of 6: Solo Leveling"`; the dots are buttons; keyboard `←`/`→` when the region has focus, `Enter` opens, `p` opens "Previously on" for candidate 5, `.` opens the card's menu.

### D. Rails and cards (`screens/home/HomeRails.tsx`, `ContinueRail.tsx`, `AiRail.tsx`, `CircleRail.tsx`, `GenreChips.tsx`, `PinnedSourcesRail.tsx`, `ThisWeekCard.tsx`, §8.8, §9.1.1)

1. All rails sit in one `web/26` `RailGroup` (one tab stop per rail, `←`/`→` within, `↑`/`↓` between rails keeping the column); headers are `h2` in `title2` through `LetterReveal`, the first time each rail scrolls 25 % into view per session (`revealKey "{profileId}:tonight:{railId}"`); the first data paint runs the wave from the top-left; rails appended later (tier-two AI answers) surface from depth at the end.
2. **Continue reading:** `ContinueStack` cards (280 × 132 phone, 320 × 148 desktop; no horizontal swipe); the unopened next chapter reads "Up next · Ch 143", a track-only ring and "Start". Its long-press context menu opens with "Previously on" as the first row, then Continue, Details, "Remove from row" (`hideContinue`, toast "Removed from Continue reading" + Undo → `unhideContinue`), Mark read, Download next 10, Recommend to…; the trailing ⋯ (44 px on the stack's top-right) opens the same menu; `p` on a focused stack opens Previously on.
3. **Updated for you, Almost there, Ready offline, Recently added, Popular:** `Poster` rails (124 / 148 / 168 / 184 px by frame) with the badges and captions of A2; each poster opens its series through the sheet route with the zoom; long-press gives the context menu: Continue, Details, Add to collection, Mark read, Download next 10, Previously on (when the series has progress), Recommend to….
4. **AI rails (Because you read, For you):** the header carries the `MachineBadge` before the title; cards are `WorldCard ai` (the `machineRim`, the sparkle before the `why`): **available** opens the series on its first `available[]` source (a source-picker `Menu` when several have it: "On MangaSource", "On AsuraSource"); **info-only** shows "Not on your sources" with "Search my sources" (→ `/search?q={title}`) and "Read on {site}" (an external link; failure → the toast "Couldn't open {site}"). A card recommended by a friend also carries the friend's `bloom` chip. **Loading:** the header with a 28 px `ThinkingOrbit` beside the title and 4 skeleton cards whose sheen runs at 2,800 ms; it never blocks the rest of Home. **States** through `aiState()`: ready; stale (`AiStamp` "Picked 3 days ago" beside the title); partial (a failed AI rail is omitted); unavailable (the header plus `AiNotice` with the reason's short line from `copy/ai.ts`, and the section's `fallback` items beside it when the server sent them); offline (AI rails omitted).
5. **Not interested** (AI cards only): lift the card and throw it sideways (the `web/26` `away` decision: the projection past a side edge or `|vx| ≥ 1,200 px/s`), or ⋯ → "Not interested", or `Delete` (and `Backspace` outside a field) on a focused AI card: the card flies off on `dismiss` with its velocity, spinning up to 12° toward the throw, the rail closes the gap on `snappy`, `throw.commit` fires with the velocity-scaled intensity, and the toast "We'll show fewer like this" with "Undo" (10 s, draining rim) shows; `sendAiFeedback({ signal: "not_interested", anilist_id })` (or `source_id` + `series_key`), and Undo sends `signal: "undo"` and returns the card with the wave. ⋯ also offers "More like this one": `sendAiFeedback({ signal: "liked_pick", … })`, then the series' sheet route at `#more-like-this` (available) or `/library/recommendations` (info-only). Reduced motion: the card fades out over 150 ms.
6. **In-session re-rank:** opening a series from any rail calls `noteOpenedFromRail(topGenre)`; the next render of Home applies `rerankRails()`; a rail whose position changes moves on `snappy` (a Motion `layout` animation) only while both its old and new positions are outside the viewport; a rail inside the viewport keeps its place until it leaves it.
7. **From your Circle:** letters as cards with the `bloomRim` rim, the sender's 18 px orb and the `bloom` chip "{name} thinks you'd like this"; friends' reads as posters with an 18 px friend orb (the `bloom` ring) at the bottom-left and the caption "{name} is reading". No machine light here.
8. **Your genres:** a `ChipRow` of link chips in weight order ("Fantasy"), each → `/library/recommendations?genre={genre}`.
9. **New in your pinned sources:** for each source a mini rail: a header row (28 px logo or the monogram tile, the name in `headline`, "See all" → `/sources/{id}`), then its `latest_covers` (up to 3) as posters linking to `/sources/{id}?mode=latest`.
10. **This week:** a `surface1` slab, radius 26, padding 16: "This week" in `title3`, then three figures side by side, each a value in `title2` `label1` over a label in `footnote` `label2`: minutes read (`round(seconds_week / 60)`, label "min"), chapters (`chapters_week`, label "chapters"), the streak (a 16 px `flame` Fill in `streak` before the value `current_days`, label "day streak"); zero shows as "0"; the whole card links to `/library/statistics`.
11. **Continue with a recap:** every Continue on Home (spotlight primary, Continue stacks, the accessory) goes through `continueWithRecap(item, anchorEl)`: with `mm.recap.mode === "always"` it opens the `recap` sheet route first; with `"ask"`, when the series was last read `seriesDays` (7) or more days ago and is not in `skipSeries`, it opens `?sheet=offer&series={sourceId}:{seriesKey}` anchored to `anchorEl` if the global registry has `offer` (`web/41`), else it dives; otherwise it dives. This file is a stand-in with a fixed call shape: `web/41` replaces its body with `continueSeries(item, originEl)` from `parts/recap/useContinue.ts` (the one Continue path for every Glass surface) and deletes `continue-with-recap.ts`, so call it only through this one function and never inline the rule elsewhere.

### E. Recommend by dropping on a friend (`primitives/FriendOrbTargets.tsx`, `useRecommendDrop.ts`, §9.3.4)

A Glass primitive that Home mounts for its own lifts. `web/43` moves it to `parts/recommend/RecommendOrbs.tsx`, mounted once by the Shell and fed by a lift store for every poster, adds "Add a note" and the deferred-send helper `scheduleLetter`, and deletes this copy; keep `FriendOrbTargets` free of Home imports so that move is a rename:

1. During a lift of any Home poster, card or the spotlight card whose series has a source, when this profile shares (`useSharing(profileId).activity`) and `useRecipients(sourceId, seriesKey)` returns members with `can_receive: true`, their orbs (56 px `ProfileOrb`, a `glassThin` bezel and a `bloom` ring) materialise along the top at safe-top + 72 px, 72 px apart, centred; the orbs are one masked glass element in the budget; offline or with nobody eligible, no orbs appear.
2. Each orb is a magnet target (radius 64 px, pull 0.35 of the remaining distance per frame): entering it swells the orb to 1.2 and fires `magnet.capture`; releasing inside shrinks the poster into the orb on `zoom`, the orb pulses on `celebrate`, and `magnet.drop` and `recommend.send` fire with the `send` cue.
3. The toast "Recommended to {name}" with "Add a note" (only when the global sheet `letter-note` is registered, `web/43`) and "Undo" (10 s): the letter (`useSendLetter()` → `POST /circle/letters {to_profile_ids: [id], source_id, series_key, note: null}`) is sent when the toast leaves or is dismissed, and Undo cancels it before it is sent; a failed send shows "Couldn't send that" and a `recipient_unavailable` answer "{name} isn't taking recommendations any more.".
4. Info-only world cards have no source and therefore no orbs; a mature series lists only the members the server marks `can_receive`. Reduced motion: the drop completes with a 150 ms fade.

### F. Pull to refresh and refresh keys (§7.33, §8.8)

The page scroller is wrapped in the `web/27` `PullToRefresh` (touch only): `onRefresh` calls `refreshHomeFeed()` and resolves `{ changed }` (new rows run the wave; `refresh.done` only when changed). `r` (through `useRefreshKey`) and ⋯ → Refresh run the same with no droplet; a polite live region says "Updated" or the error.

### G. States (§8.8, §7.24, §9.1.5)

1. **Loading:** the greeting shows at once (the name is local); a spotlight skeleton card (2:3 at 62 % width, radius 26; the desktop stage skeleton at 440 px) and three rail skeletons (header + 5 posters), shown after 180 ms.
2. **New profile** (onboarding skipped, nothing followed and nothing read): the "Start here" spotlight, the rails "Popular on your pinned sources" and "For you", and below them the `ObjectLens` `books` "Nothing followed yet" with the primary "Browse sources" (→ `/sources`).
3. **AI unavailable:** AI rails show `AiNotice` with the reason's short line (and fallback items); everything else works.
4. **Offline** (`origin === "offline"`): the greeting, the shell's "Offline" capsule, one spotlight card for the most recent downloaded series, and only "Ready offline" and "Continue reading" (downloaded only).
5. **Error:** a rail whose section failed shows the `Rail` error card ("Couldn't load this row" + "Retry"); only when every section failed (`state === "unavailable"`) the whole screen is the error `ObjectLens` "Couldn't load your home" with "Try again".
6. **Caught up:** "Updated for you" is omitted and the spotlight opens with "You're caught up" (A3).
7. **Rate limited:** the `warning` capsule "Sources are busy. Retrying in 12 s" through `useRateLimitCapsule` with the automatic retry.
8. **Stale:** the AI stamps (D4).
9. **Empty** (`state === "empty"`): as the new-profile state.

### H. Keys and semantics

`mod+enter` continues the most recent read (shell); `←`/`→` page the spotlight when it has focus; `↑`/`↓` move between rails; `Enter` and `o` open the focused item; `.` and `shift+F10` open its menu; `p` opens Previously on for the spotlight's candidate card or the focused Continue stack; `r` refreshes; `Delete` marks a focused AI card Not interested; `g u` goes to Updates (shell). The page is `main` with the greeting as `h1` and each rail an `h2` section; route focus lands on the greeting without skipping its typing.

### I. Budget and performance (§15.7)

At the top of Home on a phone the live glass elements are the nav row group, the dock + orb, and the spotlight's two controls (4); scrolled, the controls become twins and the accessory appears (3); a sheet and a toast or menu on top stay within 5. Desktop: sidebar, toolbar group, the two spotlight controls, plus at most a toast and a menu, within 6. Per-letter reveals: at most two at once (the `web/26` queue); posters lazy-load below the fold; the hero field and the ambient field are gradients with no filter.

### J. Checks

- Vitest: `home-rails.test.ts` (the section → rail mapping and order, omission, the offline set, the re-rank floor under Continue), `spotlights.test.ts` (each candidate, de-duplication, caught up, new profile, offline, December, the unopened "Start" label), `greeting.test.ts` (the four time buckets at their boundaries, the subline pieces and plurals, the at-risk line), and the extended `features/home` tests for `refresh`.
- `frontend/e2e/glass-home.spec.ts` (dev stack, `mm-skin-debug=glass`, the demo account; states by `page.route("**/api/home**", …)` with `web/08`'s fixtures edited per state, a 3 s delayed route for loading, a 500 for error, `context.setOffline(true)` for offline): the spotlight is a carousel region with its slides and dot buttons; `→` pages it and the live region announces the slide; the primary dives into the reader (URL `/reader/…`); tapping a poster opens the `feature` sheet route with Home still mounted beneath; a lifted AI card thrown sideways (touch at 390 × 844) sends `POST /ai/feedback` with `not_interested` after the Undo window and Undo sends `undo`; the bell shows the count badge and links to `/updates`; pull to refresh sends `GET /home` with `refresh=1`; each state renders its copy (loading skeletons, new profile lens, AI unavailable notice with the short line, offline rails, the error lens only when every section fails, caught up, stale stamp); the Home dock menu lists Updates, Mark all read and Continue last read; with a friend eligible (fixture on `GET /circle/members`), a lift shows the orb row and a drop shows "Recommended to {name}"; every interactive element ≥ 44 × 44 px at 390 × 844; `window.__mmGlassBudget` stays within I.
- Extend `frontend/e2e/glass-reveals.spec.ts` with the §15.8 Home check on the real `/`: 200 ms after navigating, the greeting's 10th grapheme has computed `opacity` below 0.1 (route focus on the `h1` did not skip it); whenever grapheme 6 is visible the caret's computed `translate` is past grapheme 0; after 3 s every grapheme is at 1; a rail header below the fold stays `data-reveal="wait"` until scrolled 25 % into view; a second visit in the same session shows both at once.

## Out of scope here (owned by later steps; do not build)

- The series sheet and its "More like this" (`web/33`), the readers (`web/35`, `web/36`), the recap offer and deck (`web/41`), For you (`web/41`), Statistics and the physics flame (`web/42`), Circle, the recommend sheet and the `letter-note` sheet (`web/43`), Library (`web/32`), Updates (`web/32`). Home links to them; until they land they render pending inside the shell.

## File layout

```
frontend/src/features/home/api.ts, use-home-feed.ts (+ their tests)          A1 (skin-neutral additions only)
frontend/src/skins/glass/screens/home/
├── Home.tsx, HomeChrome.tsx, Greeting.tsx, greeting.ts (+ test)            B, A4
├── home-rails.ts (+ test), spotlights.ts (+ test)                          A2, A3
├── Spotlight.tsx, SpotlightCard.tsx, SpotlightStage.tsx, HeroField.tsx, useHeroTilt.ts   C
├── HomeRails.tsx, ContinueRail.tsx, AiRail.tsx, CircleRail.tsx, GenreChips.tsx,
│   PinnedSourcesRail.tsx, ThisWeekCard.tsx, continue-with-recap.ts          D
└── HomeStates.tsx                                                          G
frontend/src/skins/glass/primitives/FriendOrbTargets.tsx, useRecommendDrop.ts    E
frontend/src/skins/glass/index.ts                                           tonight wired; PENDING shrinks
frontend/e2e/glass-home.spec.ts; frontend/e2e/glass-reveals.spec.ts (Home check)   J
docs/redesign/proof/web-31/                                                 plan.md, screenshots, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**` and their own `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`. `features/home/` stays free of `src/skins/**` imports and of JSX. No CSS modules.

## Acceptance criteria

- [ ] `tonight` renders the Glass Home and is gone from Glass's `PENDING`; a profile with onboarding pending is sent to `/welcome`.
- [ ] Greeting: "Good {part}, {name}" by the four local-time buckets, typed at 50 ms per grapheme once per app session (not skipped by route focus), the subline pieces and the streak chip to Statistics, the at-risk line in `label1`. (The Plus one is `web/42`'s.)
- [ ] Spotlight: up to six cards in the §8.8 order with de-duplication and the caught-up, new-profile, offline and December rules; the phone card at 62 % width and radius 26 over its 36 % enlargement; the live title reveal on every page; the lit primary with its caustic and the `glassClear` secondary with `dimClear` over bright covers; one card per flick; droplet dots as 44 px buttons; tilt within ±6° only when allowed; Light follows the story over 900 ms; the desktop 440 px stage (tablet 360) with the next-four strip and `←`/`→`; carousel semantics with announced changes.
- [ ] Rails: the thirteen rails in order with their exact titles and See all targets; Continue stacks with the "Previously on" menu row, ⋯ and `p`, and "Remove from row" with Undo; AI rails with the machine light, the orbit and slow skeletons while thinking, stale stamps, partial omission and the unavailable notice with fallback items; letters and friends' reads in the people light; the genre chips to For you; pinned-source mini rails; Ready offline; Recently added; the This week card.
- [ ] Not interested by throw, ⋯ and `Delete`, with the 12° spin, the gap closing on `snappy`, the Undo toast and the `not_interested` / `undo` feedback calls; "More like this one" sends `liked_pick`.
- [ ] Friend orbs appear during a lift only when sharing is on and someone can receive, magnetise within 64 px, swell to 1.2, and a drop recommends with the deferred-send Undo toast.
- [ ] Continue actions respect the recap setting (always, ask after 7 days unless skipped, off) and fall back to the Dive while the offer sheet is not registered.
- [ ] Pull to refresh (touch), `r` and ⋯ → Refresh all call `GET /home?refresh=1` and announce the result; the bell swings on a new count; the dock's Home menu has its three items; the accessory shows Continue once the hero leaves the viewport.
- [ ] Every state of G renders with its exact copy; per-rail errors never take the whole screen unless every section failed.
- [ ] Every interactive element's own box is at least 44 × 44 px at 390 × 844 (touch), with at least 8 px between adjacent hit boxes; the keyboard model of H works with the two-tone focus ring, never clipped.
- [ ] Reduced motion (OS query and `data-motion="reduced"`): the greeting and titles show at once with no caret, the card fades in, no tilt, no ripple, no pendulum, palette changes cross-fade over 200 ms, throws and drops end with 150 ms fades, rails fade together; finger tracking stays 1:1.
- [ ] Solid glass: the nav row, dock, toolbar and the spotlight controls render their solid recipes (the lit action as solid `iris700` `#5B4AD1`), with no caustic (screenshots).
- [ ] Budget: `window.__mmGlassBudget` stays within I in the four moments (phone top, phone scrolled with a sheet and a toast, desktop at rest, desktop with a window and a menu).
- [ ] The §15.8 Home check in `glass-reveals.spec.ts` passes.
- [ ] Per-skin difference: nothing under `frontend/src/skins/cinematic/` changed; with `mm-skin-debug=cinematic` Tonight renders as before and its spec still passes (`e2e/cinematic/web-08-tonight.spec.ts`); the `features/home` change is additive (Cinematic never passes `refresh`).
- [ ] The vitest files and `glass-home.spec.ts` pass; the earlier Glass specs still pass.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (counts at or above the floor plus the new tests), `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, the dev stack, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report "RAM guard: N MB available" instead of running it. Run `pgrep -af "next build|vitest|flutter_tester|pytest"` first; never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running. Do not run `npm install`.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

Browser checks: start the dev stack as `backend/scripts/README-dev-stack.md` says (if `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` is not 200), then from `frontend/`:

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- -p 3010
# second shell, one spec at a time; credentials from backend/scripts/README-dev-stack.md, never committed
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/glass-home.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/glass-reveals.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-08-tonight.spec.ts --workers=1
```

**Visual proof** with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first) in the named session `web-31`, headless Chromium with the `mm-skin-debug=glass` cookie and the demo account (demo covers only, no real library), at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-31/`: `home-{desktop,phone}.png`, `home-full-{desktop,phone}.png` (full page), `home-tablet-1024x768.png`, `home-typing-200ms-phone.png`, `home-spotlight-drop-phone.png` (mid-drop with the ripple), `home-spotlight-page2-{desktop,phone}.png` (after Light follows the story), `home-spotlight-{caught-up,wrapped,letter}-phone.png`, `home-scrolled-accessory-phone.png`, `home-ai-thinking-desktop.png`, `home-ai-unavailable-desktop.png`, `home-ai-stale-desktop.png`, `home-not-interested-throw-phone.png` (mid-throw), `home-friend-orbs-phone.png` (a lift with the orb row), `home-pull-refresh-phone.png` (the droplet snapped), `home-{loading,new-profile,offline,error,rate-limited}-{desktop,phone}.png`, `home-at-risk-phone.png`, `home-novel-mode-desktop.png`, `home-dock-menu-phone.png`, and `home-solid-desktop.png`, `home-contrast-desktop.png`, `home-reduced-motion-desktop.png`. If you use `playwright-cli`, pass `-s=web-31`. Open the motion-timings overlay (`mod+shift+m`, development build) on a fresh session and capture `home-motion-timings-desktop.png` after the signature moment: no row may be `danger`. Write `docs/redesign/proof/web-31/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` and leave the dev stack as you found it.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (other sessions commit on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the `features/home` refresh addition with its test; the rail and spotlight mappings with their tests; the greeting; the spotlight; the rails; Not interested; the friend orbs; states; the specs; the proof (`feat(web-glass): Home spotlight with Light follows the story`). Stage your paths explicitly, never `git add -A` or `git add .`, because the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets (the demo credentials included), screenshots of a real account's library, or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by letter (A to J), and anything not done with the reason; confirm `tonight` left `PENDING`.
2. The exact change to `features/home/` and proof that Cinematic's Tonight spec still passes.
3. The screenshot folder `docs/redesign/proof/web-31/` and its file list.
4. Test counts: vitest files and cases before and after; each Playwright spec's result (including the §15.8 Home check); lint, build and `build.mjs --check` results; the `free -m` available figure before each build.
5. The live glass counts in the four budget moments, and the motion-timings figures for Typing reveal, Spotlight drop, Field ripple, Light follows the story, Letter reveal (live), Hero tilt, Throw, Wave and Meniscus refresh, with any raster-only move for the owner's hardware check.
6. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/32-glass-library-hub-downloads.md` (`docs/redesign/prompts/mobile/31-glass-home.md` runs in parallel).
