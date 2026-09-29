# Web 22: Cinematic Circle (social for two or three readers)

## Goal

Build new feature 3, the **Circle**, for the Cinematic skin on the web client (`frontend/`), exactly as `docs/redesign/cinematic/DESIGN.md` §9.3 specifies, on top of the server half from `backend/08` and `backend/09`: the Circle screen at `/circle` (the magazine's letters page: the readers strip with the reading-now ring and `NOW` badges that follow the server's `now`, the activity column of dispatches, letters, shared shelves, tabs and keys `1`–`5`), **reactions on chapters** (the five Cinematic stamps plus `HYPE` and `WRECKED` rendered in the same stamp style, the spoiler guard that seals reactions on chapters the viewer has not finished and unseals them on `chapterCompleted`, in the reader credits, the novel end matter, page actions, the reader and feature-page `CIRCLE` panels and the schedule rows), **Recommend to "Pass it on"** and the **letters** it sends (with `Keep`), **shared shelves** inside Collections, **Settings → Circle & privacy** (every switch), the **member page** at `/circle/:profileId`, and the Circle rails on Tonight (`Sent to you`, `From the Circle`, `Most read in the circle`) with every badge and count. Every 18+ and isolation state is the server's (gate on serve); the client never shows a count, a placeholder or a hint for what it hides. Deliver desktop web (768 px and up), tablet widths and mobile web (below 768 px), reduced motion and keyboard access. When you finish, the ScreenIds `circle` and `circleMember` leave the Cinematic `PENDING` set. The mobile session runs `docs/redesign/prompts/mobile/22-cinematic-circle.md` in parallel on Flutter; do not touch `mobile/`.

## Read first

DESIGN.md is binding; where this prompt and DESIGN.md disagree, DESIGN.md wins and you note the conflict in your report.

- `docs/redesign/cinematic/DESIGN.md`:
  - **§9.3 entire** (§9.3.1 model and privacy, the shareable activity set S; §9.3.2 the Circle screen and its states table; §9.3.3 reactions and the spoiler guard; §9.3.4 Pass it on and letters; §9.3.5 shared shelves; §9.3.6 Settings → Circle & privacy; §9.3.7 the member page; §9.3.8 backend shapes, polling and the `409` race).
  - §8.27, §8.8 (sections `sent_to_you`, `circle`, `circle_top`; Also in this issue `letter`), §8.11 (Collections: `SHARED WITH YOU`, the permission table, Leave shelf, sharing off, smart shelves), §8.14.6 (credits step 3), §8.14.12 (the reader `CIRCLE` panel and its guard), §8.14.13 (`React to this chapter`), §8.15.2 (novel end matter reactions), §8.15.3 (novel margins `CIRCLE` tab), §8.17 (feature page: the `paper-plane-tilt` Recommend button, `04 CIRCLE` tab, schedule-row reaction count), §8.28 (Index `Circle ...... 2 NEW`), §8.30.1 (server-backed section states), §8.30.2 row 09, §8.0.3 (routes `circle`, `circleMember`; branch 4), §8.0.4 (Circle → reader by Dip), §8.0.10.
  - §7 intro (semantics table row Reaction stamps), §7.6 (Letter card, Collection plate), §7.9, §7.10 (the arm), §7.11, §7.12, §7.14 and §7.15 (badges and counts), §7.16 (row states), §7.19, §7.21 (switch states), §7.22 (Quick look `Recommend to…`), §7.23, §7.25 (avatars and the **reading-now ring**), §7.29 (spoken folios).
  - §4.5 rows Unfold, Unseal, Dissolve (the Circle avatar relight), Rise, Insert, Page, Match cut, Dip, Set; §4.8 rows Unfold, Circle avatar relight, Typing reveal; §5 events `reaction.send` (`stamp`), `recommend.send` (`pass`), `follow.add`, `select`, `toggle.on/off`, `delete.confirm`; §6 cues `impress`, `pass`, `tick`.
  - §10.2.2 (typed: the letter sender kicker on unfold, the privacy preview line, a stamp's count, the `Sent to you` note), §11 (rows Circle reader avatars long-press, pull to reprint on Circle), §13 moments 7, 15, 19, §14 entire (especially §14.3 and §14.11), §15.5 Circle rows, §15.7 (spoiler guard checks on an unread, a half-read and a finished chapter), §15.10 owner call *Circle reciprocity*.
- `docs/redesign/glass/DESIGN.md` §15.6 rows **Reaction kinds** (one enum of seven; Cinematic renders `hype` and `wrecked` as two more stamps), **Presence** (`now` is `null` unless the member's `show_presence` is on, for both skins), **Sharing switches** (Cinematic leaves `show_presence` and `share_streak` untouched), **Recommendation recipients** (`can_receive`).
- `backend/docs/circle-api.md` (the wire contract, from backend/08 and backend/09).
- `docs/redesign/inventory/capabilities.md` §26 row "Social for 2-3 users", `docs/redesign/inventory/00-decisions.md` (new feature 3), `docs/redesign/stack-decision.md` §2.2 and §2.6, `docs/redesign/00-baseline.md`, and the `prompts-plan.json` entry for this file.

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native` (`git branch --show-current`; otherwise stop and report). Run `git status --porcelain` and note files other sessions have modified; never stage them.
2. This step depends on `docs/redesign/prompts/web/21-cinematic-numbers-streak-annual.md`, `docs/redesign/prompts/backend/08-circle-core-sharing-presence.md` and `docs/redesign/prompts/backend/09-circle-reactions-letters-shelves.md`. Check; if any check fails, stop and report which dependency is missing:
   - `grep -rn "prefix=\"/circle\"\|/circle/" backend/routes/circle.py` finds the Circle routes; `grep -rn "sealed" backend/services/circle_service.py` finds the spoiler flag; `grep -rn "can_receive" backend/services/circle_service.py` finds recipient eligibility; `grep -rn "include_shared" backend/routes/library.py` finds the shared-shelves list mode; `ls backend/docs/circle-api.md` exists (read it in full: it is the exact wire contract you code against, including the additive fields `followed_by_viewer`, `content_kind`, `sealed`, `total`, `mine`, `role`).
   - `grep -n "circle" frontend/src/skins/cinematic/index.ts` shows `circle` and `circleMember` still in `PENDING`; thin routes `frontend/src/app/(app)/circle/page.tsx` and `frontend/src/app/(app)/circle/[profileId]/page.tsx` exist (web/00).
   - `git log --oneline | grep "web-21:"` shows the previous step.
3. Inventory and reuse; never re-implement a primitive in a screen. Read what exists before writing: `frontend/src/features/circle/api.ts` and `hooks.ts` (web/13 created a minimal `useCircleSeries`; extend them, never fork them); `frontend/src/skins/cinematic/screens/reader/CircleReaders.tsx`, `Credits.tsx` (its optional `reactions` slot), `PageActions.tsx`, `MarginsPanel.tsx` (web/12, web/13); the novel reader's end matter and margins panel (web/14, `grep -rln "End of chapter" frontend/src/skins/cinematic/screens`); the feature and book pages and their `04 CIRCLE` tab and schedule rows (web/11); the Collections screens (web/10); Settings section 09 (web/18, `grep -rln "Circle & privacy" frontend/src/skins/cinematic`); Tonight's section registry and `parts/quick-look-actions.ts` (web/08); the Index (web/17); the Shell's thumb-index badge and sidebar counts (web/06). Primitives from web/04 and web/05: `Avatar.tsx` (with the reading-now ring if built; add it if not), `cards/LetterCard.tsx`, `cards/CollectionPlate.tsx`, `Poster.tsx`, `Rail.tsx`, `Sheet`, `Dialog` (with the 1000 ms arm), `Switch`, `Segmented`, contents tabs, `Menu`, `Notice`, `Skeleton`, `Badge`, `Toast` host, pull to reprint, `SetHeading`, `TypedHeadline`, `useTyped`, `play()`. The engine event `onChapterCompleted` (web/12 A2): `grep -rn "onChapterCompleted" frontend/src/features/reader`.
4. Record the start-of-step Vitest totals after the RAM guard: `cd frontend && npm run test 2>&1 | tail -5`.

## Skills to invoke

1. `superpowers:writing-plans` before any code: the plan goes to `docs/redesign/proof/web-22/plan.md`.
2. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline), with `superpowers:test-driven-development` for every pure module of A. Subagents get scope-locked prompts naming their files, `model: "opus"` explicitly, and are checked against `git status` and `git diff`, never their reports.
3. `frontend-design:frontend-design` for the web UI; `impeccable:impeccable` and `taste-skill:taste-skill` on the proof screenshots; critiques never override a token, duration, copy string or layout rule DESIGN.md fixes.
4. `superpowers:verification-before-completion` before claiming done.

## Scope

Cinematic only (Glass's Circle is web/43). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`.

### A. Shared data layer: `frontend/src/features/circle/` (skin-neutral; Glass web/43 imports it)

No JSX, no `src/skins/**` import, a Vitest beside every file with logic.

1. `types.ts`: `ProfileRef {profile_id, name, avatar_key, username}`; `CircleNow {source_id, series_key, chapter_key, chapter_number, title, ambient, since}`; `CircleMember {…ProfileRef, shares: {activity, reactions, shelves, recommendations}, now: CircleNow | null, last_active_at, streak, can_receive?}`; `FeedItem {id, kind: "started" | "finished_chapter" | "finished_series" | "reacted", actor: ProfileRef, source_id, series_key, title, cover_url, ambient, content_kind, chapter_key, chapter_number, reaction: ReactionKind | null, sealed: boolean | null, followed_by_viewer, created_at}`; `ReactionKind = "loved" | "shook" | "laughed" | "tears" | "chefs_kiss" | "hype" | "wrecked"`; `ChapterReactions {chapter_key, chapter_number, counts: Record<ReactionKind, number>, total, by: [{…ProfileRef, kind, created_at}], mine: ReactionKind | null, sealed: boolean}`; `Letter {id, from: ProfileRef, source_id, series_key, title, cover_url, ambient, content_kind, note, state: "new" | "read" | "kept" | "dismissed", created_at}`; `Sharing {activity, reactions, shelves, recommendations, include_mature, show_presence, share_streak, excluded_series: [{source_id, series_key, title}]}`; `MemberPage` (the `GET /circle/members/{profile_id}` shape); `CircleSeriesInfo {followers: ProfileRef[], readers: [{profile, chapter_key, chapter_number, last_read_at}]}`. Match `backend/docs/circle-api.md` field for field.
2. `api.ts` (extend web/13's file) through `services/http.ts`: `members({sourceId?, seriesKey?})` → `GET /circle/members` (with both ids it carries `can_receive`), `member(profileId)`, `feed({cursor, limit: 50, kind?, profileId?})`, `series(sourceId, seriesKey)`, `reactions(sourceId, seriesKey)`, `react(body)` → `POST /circle/reactions`, `unreact(body)` → `DELETE /circle/reactions` with the body `{source_id, series_key, chapter_key}`, `letters()`, `sendLetter({to_profile_ids, source_id, series_key, note})`, `patchLetter(id, state)`, `sharing(profileId)`, `patchSharing(profileId, partial)`, `clearActivity()` → `DELETE /circle/activity`. Collections additions go in `features/library/api.ts`: `collectionsWithShared()` → `GET /library/collections?include_shared=true` (`{collections, shared_with_me}`; the legacy list call stays a bare array), `shareCollection(id, {profile_ids, mode})`, `unshareMember(id, profileRef)` (`me` to leave).
3. `hooks.ts` (extend): `useCircleMembers({enabled})` (React Query key `["circle", "members", profileId, matureEnabled]`, `refetchInterval: 60_000`, `refetchIntervalInBackground: false`: polled every 60 s only while a Circle surface is mounted and visible, §9.3.8); `useRecipients(sourceId, seriesKey)` (members with `can_receive`); `useCircleMember(profileId)` (poll as members); `useCircleFeed(kind?)` (infinite query on `next_cursor`); `useCircleSeries`; `useChapterReactions(sourceId, seriesKey)`; `useReact()` (optimistic: `mine`, `counts` and `total` update at once, rolled back on failure); `useLetters()` (poll 60 s while mounted), `useSendLetter()`, `usePatchLetter()` (optimistic, restores on failure); `useSharing(profileId)`, `usePatchSharing()`; `useClearActivity()`. Every Circle key includes the active profile id and its `mature_content_enabled`, and web/07's gate-change invalidation list gains the `["circle"]` prefix and the collections keys.
4. `reaction-kinds.ts`: the seven kinds in stored order with `{label, glyph, offered}`: `loved` "Loved" `heart`, `shook` "Shook" `lightning`, `laughed` "Laughed" `smiley`, `tears` "Tears" `drop`, `chefs_kiss` "Chef's kiss" `sparkle` (all `offered: true`), `hype` "Hype" text stamp `HYPE`, `wrecked` "Wrecked" text stamp `WRECKED` (`offered: false`: shown only when their count is above zero). `pressReaction(mine, kind)` → `{op: "set", kind}` or `{op: "clear"}` (pressing the same kind removes it, another kind moves it). Test.
5. `spoiler-guard.ts`: `isGuarded({isOwn, sealed, completedLocally, completedThisSession})` → `false` for the viewer's own reaction, `false` when the chapter is completed locally (`useSeriesProgress` rows with `is_completed`, the same data the chapter list reads) or completed this session (`onChapterCompleted`), otherwise the server's `sealed` (and `true` when `sealed` is unknown, offline included: err towards hiding); a module-level `completedThisSession` set with `markCompleted(sourceId, seriesKey, chapterKey)` and a subscribe function the skin uses to play Unseal. Test: unread, half-read and finished chapters; own reactions; the session set.
6. `dispatch.ts`: `dispatchParts(item, guarded)` → an ordered list of `{text, italic?, reaction?}` runs for the sentences of §9.3.2: started "{Actor} started {Title}."; finished_chapter "{Actor} finished chapter {n} of {Title}."; finished_series "{Actor} finished {Title}."; reacted "{Actor} reacted {glyph} to chapter {n} of {Title}." or, guarded, "{Actor} reacted to chapter {n} of {Title}." (`n` printed without a trailing `.0`; a null number reads "a chapter of {Title}"); `dayGroups(items, now)` → `TODAY`, `YESTERDAY`, then `MON 21 SEP` in local time. Test.
7. `letters.ts`: `newCount(letters)` (the badge: `state == "new"`), `sendToast(names)` → "Sent to Riya." / "Sent to Riya and Arjun." / "Sent to Riya, Arjun and Mei."; `readRule` constants (50 % visible for 2000 ms, B6). Test.
8. `sharing.ts`: `sharingPatch(before, after)` → only the keys that changed (so `show_presence` and `share_streak`, which Cinematic never shows, are never sent, glass §15.6); `excluded_series` sent as the whole list when it changed. Test.
9. `reaction-outbox.ts`: offline reactions (§9.3.3 "queued and sent on reconnect, drawn immediately") in scoped `localStorage` `mm.circle.reaction-outbox` as `[{source_id, series_key, chapter_key, kind | null, at}]`, last write per chapter wins; `flushOutbox()` on the `online` event and on window focus. Test: coalescing, flush order, scope isolation.
10. `presence.ts`: `ringColour(now)` → `now.ambient.duo` or the fallback `#B8B2A4`; `nowLabel(now, viewerProgressKeys)` → "Reading Omniscient Reader · CH 212" when the viewer has any stored progress on `now.chapter_key`, else "Reading Omniscient Reader" (the spoiler guard for the folio, §9.3.2). Test.

### B. The Circle screen (`frontend/src/skins/cinematic/screens/circle/`, ScreenId `circle`, §9.3.2)

Wire `screens.circle` to `CircleScreen` and remove `circle` from `PENDING`. `document.title` "The Circle · ManhwaManiacs". Desktop: the sidebar item `11 Circle` lit, the running-head folio `No. 11 · CIRCLE`. Phone: the Index branch (pushed with Page from Index, back arrow).

1. **Masthead** (§7.27): kicker `No. 11 — THE CIRCLE`, title "The Circle" (`SetHeading` `trigger="mount"`, `as="h1"`, `type.masthead`), deck "What the other readers on this server are reading." (`type.deck` `ink.60`), the Oxford rule on desktop / `rule.heavy` on phones.
2. **Readers strip**: every member from `useCircleMembers()` as a 44 px avatar (§7.25 presets) over its name in `type.ui` (the name in `ink.100`); when two members share a name, each also carries `@username` in `type.caption` `ink.45` under the name, and so does every place a member is named (dispatches, letters, pickers). Members with `now` wear the **reading-now ring**: 2 px at 3 px offset in `ringColour(now)` (`box-shadow: 0 0 0 3px #000, 0 0 0 5px <colour>`), which dissolves to a new colour over 800 ms `ease.turn` when the series changes and fades out over 800 ms when `now` becomes null (a `transition: box-shadow 800ms cubic-bezier(0.65, 0, 0.35, 1)`), plus a `NOW` micro badge (§7.19: `type.micro`, `#000000` on a `spot` fill, 16 px tall) beside the name. Hover (desktop) or long-press 450 ms (phones) shows the tooltip `nowLabel()`. A click opens the member page (Page transition). Desktop: one row, 24 px apart; phones: a horizontal scroller with the trailing 24 px fade. Members whose `now` is null show no ring and no `NOW`. The ring colour updates on each 60 s poll.
3. **Tabs** (§7.12 contents tabs, Rule slide 320 ms `ease.settle`): `ALL · READING · REACTIONS · LETTERS · SHELVES`, the LETTERS count as a raised folio (`LETTERS²`, §7.5 counts, spoken "Letters, 2") when `newCount > 0`; stored in `?tab=all|reading|reactions|letters|shelves` with `router.replace`. ALL and READING and REACTIONS read `useCircleFeed()` with no kind, `reading` and `reaction`; LETTERS reads `useLetters()`; SHELVES reads the `shared_with_me` shelves plus the viewer's own shared shelves (`collectionsWithShared()`) as collection plates.
4. **Activity column** (desktop columns 1–8): dispatches grouped by day under date rules (`TODAY`, `YESTERDAY`, `MON 21 SEP` in `type.kicker` `ink.45` over a `rule.hair`). Each dispatch is a §7.16 standard row: the actor's 32 px avatar → the sentence from `dispatchParts()` in Newsreader 16 (`type.body`), names and titles in italic, a reacted item showing the reaction's 16 px glyph inline (with its name as visually hidden text) only when not guarded → the time folio `2 H` (`type.folio` `ink.45`, spoken "2 hours ago" through `folioLabel()`) → a 40 × 60 cover at the right (click → the feature page by the match cut) → a `quiet` `Read it too` when `followed_by_viewer` is false, which follows the series (`POST /library/follow`, haptic `follow.add` = the `stamp` pattern, `[12]` on Android Chrome; sound `impress`; toast "Following {title}." with `Read` opening the feature page, 8000 ms) and then becomes the caption `FOLLOWING`. Row hover: a 2 px `ink.100` left bar and text `ink.100` (120 ms `dur.snap`); pressed: `paper.3`. `Enter` on a focused row opens the feature page. Infinite paging on `next_cursor`: appended pages use one 160 ms fade (no stagger, §4.6). The first page runs Set (24 ms per row, capped at 360 ms).
5. **Letters aside** (desktop columns 9–12): the `new` letters, newest first, as §7.6 Letter cards: a duotone cover strip 3:2 on the left (to the letter's `ambient.duo`, fallback `#B8B2A4`); on the right the kicker `FROM RIYA` (with `@username` when names collide), the title as the headline (`type.subhead`), the note in Newsreader italic in quotes, and the actions `Read`, `Add`, `Keep`, `Dismiss` (§9.3.4). New: a `spot` 6 × 6 px square dot before the kicker.
6. **Letters behave** (§9.3.4, §13 moment 15): a `new` letter the first time it renders in this session **unfolds**: `clip-path: inset(0 0 100% 0)` → `inset(0)` over 480 ms `ease.settle` (the Unfold move) while its sender kicker types at 50 ms per grapheme; it becomes `read` (`PATCH {state: "read"}`) once it has been at least 50 % visible for 2000 ms after the unfold (IntersectionObserver), or on any action; the `spot` dot then fades over 160 ms. `Read` opens the series (feature page) and marks it read; `Add` follows it (`follow.add`) and marks it read; `Keep` sets `kept` (it stays in Tonight's `Sent to you` until dismissed) with the toast "Kept. It stays in Sent to you."; `Dismiss` sets `dismissed` and removes the card (Cut, the column closing the gap). A failed action shows the toast "Couldn't update the letter." and the card restores (optimistic rollback).
7. **Phone layout**: the strip scrolls horizontally; the tabs scroll; dispatches full width with the cover at the right; letters are only the LETTERS tab (full width cards), with the count. **Tablet** (768–1023): activity across 8 columns and letters as the tab; from 900 px activity 5 columns and letters 3. Pull to reprint on phones (§7.29), `r` and an overflow `Refresh` on desktop.
8. **States** (§9.3.2 table, exact copy; tab empties use the notice tone at subhead size, left-aligned in the activity column):

   | State | Presentation |
   |---|---|
   | Nothing shared yet (no member at all) | Notice `THE CIRCLE IS QUIET`: typed headline "Nobody has shared their reading yet. Turn on sharing to be the first." + `Sharing settings` (→ `/settings/circle`) |
   | This profile doesn't share (`activity` off) | A `NOTE` banner strip (§7.29) "You're reading privately. Others can't see your activity." + `Share` (turns `activity` on through `usePatchSharing`, toast "Sharing is on."); others' activity still shows (reciprocity, §15.10) |
   | Only me (the viewer shares, no other member) | "You're the only reader sharing so far." |
   | Tab empty: READING | "Nobody is reading right now." |
   | Tab empty: REACTIONS | "No reactions yet. They appear here when someone stamps a chapter." |
   | Tab empty: LETTERS | "No letters yet. When someone passes a series to you, it lands here." |
   | Tab empty: SHELVES | "No shared shelves yet." + `New shelf` (→ Collections with the New shelf dialog open and `Share with the circle` on) |
   | Loading | Six greeked dispatches (avatar disc, two text bars, a 40 × 60 plate), flickering |
   | Offline | The last cached feed, read-only, with the `OFFLINE EDITION` badge; letter actions disabled with the tooltip "Needs a connection."; reactions keep their queued behaviour |
   | Error | `CORRECTION` "The circle didn't load." + `Try again` |

9. **Counts elsewhere** (§9.3.2, §7.14, §7.15, §8.28): the thumb index's Index tab badge (a `spot` square, `#000` Plex Mono 10, "99+" cap), the sidebar `11 Circle` count, and the Index row `Circle ...... 2 NEW` all read `newCount(useLetters())`; wire them in web/06's Shell and web/17's Index if they are placeholders.
10. **Keys** (`useShortcut`, group "Circle"): `j`/`k` next and previous dispatch, `Enter` open, `1`–`5` tabs, `l` letters (desktop: focus the first letter card in the aside; phone and tablet: switch to LETTERS), `r` reprint. Listed in the `?` sheet; never delivered while the `g` sequence is armed.

### C. Reactions on chapters (§9.3.3)

1. **`parts/ReactionStamps.tsx`** (Cinematic): a row of square stamps, 8 px apart. Each stamp is min 44 × 44 px with a 1 px `rule.2` outline: the glyph (Phosphor 20 Regular `ink.100`: `heart`, `lightning`, `smiley`, `drop`, `sparkle`) or, for `hype` and `wrecked`, the words `HYPE` and `WRECKED` in `type.micro` (a text stamp grows horizontally to its label + 12 px), then its count as a folio (`type.folio` `ink.60`) under the glyph; under each stamp, the 20 px avatars of the members who pressed it (overlapping by 6 px, at most 3, then a `+2` folio). The five offered stamps always show; `HYPE` and `WRECKED` appear only when their count is above zero (they are pressable like the others). The viewer's own stamp (`mine`) is filled `ink.100` with a `#000000` glyph and count.
   - **Pressing** (`pressReaction`): the stamp translates 1 px down (80 ms `ease.set`, back 160 ms `ease.settle`), fills `ink.100`, its count types the new value at 50 ms per grapheme; haptic `reaction.send` (the `stamp` pattern; no vibration on the web), sound `impress`. One reaction per chapter per profile: another stamp moves it, the same stamp clears it (`DELETE`). Offline: the change is drawn at once and queued in the outbox.
   - **Semantics** (§7 table): a `radiogroup` labelled "Reactions to chapter 142"; each stamp `role="radio"` with `aria-checked` and the name "Loved, 3 reactions, selected"; arrow keys move, `Space` presses.
   - **Guarded** (`isGuarded` true for every other member's reaction on this chapter): the stamps show their glyphs as buttons (the viewer can still react), but **no counts and no avatars**; above the row a line with the reacting members' 20 px avatars and the total only, "2 reactions" (`type.caption` `ink.45`); the group's name reads "2 reactions, hidden until you finish the chapter". The viewer's own stamp still shows filled.
   - **Unseal** (§4.5, §13 moment 7): when the chapter completes (`onChapterCompleted` from the engine for manga; the novel reader's completion signal for novels), every guarded row visible at that moment unseals: counts and avatars (in lists, the glyph and its name) fade in over 160 ms `ease.settle`, 40 ms apart. `markCompleted()` records it so other surfaces unseal too.
2. **Where reactions appear**, each wired to `useChapterReactions` and the guard:
   - Manga credits (§8.14.6 step 3): pass `ReactionStamps` into the `reactions` slot of web/12's `Credits.tsx`, followed by a `quiet` `Pass it on` (D). The credits appear only once the chapter is complete, so they render unsealed and play Unseal on the rows that were guarded elsewhere.
   - Novel end matter (§8.15.2): the same row in the stock colours (outline in the stock's muted colour at 30 %, glyphs in the stock ink, the selected fill the stock ink with the page colour as the glyph).
   - Page actions (§8.14.13): `React to this chapter` in web/13's `PageActions.tsx` opens a `[0.5]` sheet (kicker `REACT`, title "Chapter 142") holding `ReactionStamps` (guarded while the chapter is unfinished).
   - Reader `CIRCLE` panel (§8.14.12, web/13's `CircleReaders.tsx`) and the novel margins `CIRCLE` tab (§8.15.3): swap the kind labels for the stamp glyph (16 px) + name; guarded rows read "reacted to Ch. 142" with the 20 px avatar; members further on read "Riya is on Ch. 150" with no detail; add `Recommend this series…` (`quiet`, opens D).
   - Feature and book pages (§8.17): schedule rows gain a reaction count folio, the `total` in `type.folio` `ink.45` followed by the `users-three` 16 Regular glyph (spoken "3 circle reactions"), shown when `total > 0`; its tooltip (desktop hover, 500 ms) and long-press list (phones, a small `[0.5]` sheet) list each member as "Riya · Loved" or, guarded, "Riya reacted to Ch. 142". The `04 CIRCLE` tab: who follows or read it (`useCircleSeries`: followers as 32 px avatars with names; readers as "Riya is on Ch. 150"), reactions per chapter (newest first, each chapter a compact `ReactionStamps` summary, guarded per chapter), and `Recommend to…`. The tab is disabled (`aria-disabled`, `ink.30`) with the tooltip "Turn on sharing in Settings → Circle & privacy to see the circle here." when this profile's `activity` is off (§8.17).
   - Circle dispatches (B4) and the member page's `Their reactions` rail (F).
   - Book page "In the circle" (§8.18 columns 9–12, the slot web/11 left under the cover plate): when `useCircleSeries` lists followers or readers other than the viewer, 12 px under the plate a kicker `IN THE CIRCLE` (`type.kicker`, rendered `ink.60` because it sits on the duotone field, the raised-stock rule of §2.1.1) over up to 5 avatars at 32 px, 8 px apart, then a `+2` folio (`type.folio` `ink.60`) for the rest; each avatar is a button opening the member page, named and tooltipped "Riya is on Ch. 150" ("Riya follows this" when she has not started it); absent when nobody else follows or read it and when this profile's `activity` is off. Phones show the same row under the front matter's actions.

### D. Recommend to ("Pass it on") and letters (§9.3.4)

1. **Entry points**: the feature and book page `paper-plane-tilt` icon button (tooltip "Recommend to…"; on phones it joins the feature page's labelled icon row as `SEND`, making it `FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND`, §8.17 phone layout, the slot web/11 left for it), Quick look `Recommend to…` (add to `parts/quick-look-actions.ts`), the reader `CIRCLE` panel `Recommend this series…`, the credits `Pass it on`, and the member page `Recommend something to Riya`. Each renders only when `useCircleMembers()` returns at least one member.
2. **`parts/PassItOnSheet.tsx`**: a content-fit sheet on phones (§7.9, Rise 360 ms `dur.rise` `ease.settle`), a 4-column panel from the right on desktop (min 400 px, `paper.2`, 1 px `rule.2` left edge, Panel 320 ms). Header kicker `PASS IT ON`, title "Recommend", `quiet` `Done`. Body: the series cover 48 × 72 + title (`type.title`); recipients from `useRecipients(sourceId, seriesKey)`, only `can_receive: true` members, as avatar toggles (44 px avatar, name under it, selected = the 2 px `spot` ring at 3 px offset, `aria-pressed`), listed without explanation and with nothing saying anyone is left out (§7.24); a note field in Newsreader Italic 17/28 with the placeholder "Add a line…", max 140 characters, with the counter `12 / 140` (`type.folio` `ink.45`, `ink.100` from 130); `Send` (`primary`), enabled with at least one recipient.
   - Send: `POST /circle/letters`; haptic `recommend.send` (the `pass` pattern), sound `pass`; the toast `sendToast()` ("Sent to Riya."); the sheet closes.
   - No eligible recipient: the recipients row becomes the line "Nobody is taking recommendations right now." (`type.body` `ink.60`), `Send` disabled, `Done` closes.
   - Offline: `Send` disabled with the caption "Sending needs a connection."
   - `409 recipient_unavailable` (`details.profile_ids`): those recipients are deselected and removed, with the toast "Riya isn't taking recommendations any more."; the note is kept.
   - Other failures: the toast "Couldn't send to Riya. Try again." (6000 ms); the sheet stays open and the note is kept.
3. **Receiving**: letters on the Circle screen (B5, B6), the counts (B9), Tonight's `Sent to you` and Also-in-this-issue `letter` card (H).

### E. Shared shelves inside Collections (§9.3.5, §8.11)

Extend web/10's Collections screens; switch their list query to `collectionsWithShared()` (the new skins only).

1. **Plates**: shared plates show the `SHARED` badge and the members' 20 px avatars bottom-right (§7.6 Collection plate); the deck reads "9 shelves · 2 shared · 1 shared with you" when any exist.
2. **`SHARED WITH YOU`**: a second group under a `type.kicker` `ink.45` slug over a `rule.hair`, with the owner's 20 px avatar and a `CAN ADD` or `VIEW ONLY` caption on each plate; not in `Custom order`, not counted in the shelf count.
3. **Detail** (`/library/collections/:id`): header credits `SHARED WITH: RIYA, ARJUN`; each member poster shows the adder's 20 px avatar bottom-left when another profile added it (`added_by_profile_id`); a shared shelf renders every row from the shelf's own `title`, `cover_url` and `ambient`, never from the viewer's library, and never shows `NO LONGER FOLLOWED`. Actions follow the §8.11 permission table from the payload's `role`, **hiding** what the viewer cannot do (owner: everything; `can_add`: Add series from their own library, Remove only rows they added, Leave shelf; `view_only`: open and read, Leave shelf).
4. **Share sheet** (owner; `Share` in the action row): kicker `SHARE SHELF`, title the shelf name; members with `shares.shelves` true as avatar toggles; the mode as a segmented control `CAN ADD │ VIEW ONLY` (40 px, the `spot` underline sliding 320 ms); `Save` (`primary`) → `POST …/share`; an empty selection unshares. Errors: `409 member_unavailable` deselects the listed profiles and shows the inline `CORRECTION` line "Couldn't update who can see this shelf." with `Try again`; any other failure shows the same line. No eligible member: "Nobody can be added to shelves right now." with `Done`.
5. **Sharing off**: when the owner's `activity` is off, `Share` is removed from the action row and the overflow keeps a disabled `Share…` item captioned "Turn on sharing in Settings → Circle & privacy to share shelves." Smart shelves: `Share` disabled with the tooltip "Smart shelves follow your own library, so they can't be shared."
6. **Leave shelf** (non-owners, overflow): dialog "Leave {shelf}? It disappears from your Collections. The series stay in your library." with `Leave shelf` (`destructive`, the 1000 ms arm, a 2 px `proof` rule filling under it) and `Cancel`; `DELETE …/share/me`; toast "Left {shelf}."; back to Collections by Page.
7. **New shelf dialog**: the `Share with the circle` switch; when on, the Share sheet opens right after `Create`.
8. 18+ rows of a shared shelf are absent for gated viewers and the counts reflect only what they can see (server); nothing mentions them.

### F. The member page (`screens/circle-member/`, ScreenId `circleMember`, §9.3.7)

Wire `screens.circleMember` and remove it from `PENDING`. Route `/circle/:profileId`; the running-head folio `No. 11 · CIRCLE / RIYA`; `document.title` "Riya · The Circle · ManhwaManiacs".

- Masthead: the member's 96 px avatar (with the reading-now ring when `now` is set) and the name in `type.masthead` italic (`SetHeading` `trigger="mount"`, `as="h1"`); the deck "Reading 4 series · shares activity and reactions" (`reading.length`, then the `shares` flags that are true, joined with commas and "and").
- Rails (§7.8, `SetHeading` H3s): `Now reading` (`reading`), `Recently finished` (`finished`), `Their reactions` (posters with the reaction glyph badge, or guarded "reacted to Ch. 212" captions), then shared shelves as collection plates. Only what the member shares is shown; an empty rail is not rendered.
- `Recommend something to Riya` (`secondary`): a sheet with a search field over the viewer's library (the existing `/library/search` hook), rows with 48 × 72 covers; choosing one opens the Pass-it-on sheet with Riya preselected (when she can receive that series).
- States: not sharing any more (`404 circle_member_not_sharing`): kicker `NOTE`, typed headline "Riya isn't sharing right now." + `Back to the Circle`; loading (masthead galley + two rail plates); error (`CORRECTION` + `Try again`); offline: kicker `OFFLINE EDITION`, "The circle needs a connection." Polls with the members' 60 s rule while visible.

### G. Settings → Circle & privacy (section `circle`, §9.3.6, §8.30.2 row 09)

Register the section in web/18's `frontend/src/skins/cinematic/screens/settings/registry.ts` (slug `circle`, title "Circle & privacy", placed between `content` and `feedback`, with its rows and keywords for the settings search; the folios renumber on their own) and build the section body in web/18's Settings screen (`/settings/circle`), a server-backed section with the §8.30.1 states (loading: greyed rows at their exact heights; error: a `CORRECTION` line under the header with `Retry`; offline: last values, controls disabled, caption "Needs a connection."). Settings rows (§7.16: label `type.ui`, description `type.caption` `ink.45`, trailing switch §7.21 44 × 24 with the 16 px knob; loading knob a 12 px leader dial; error: the outline turns `proof` for 2000 ms, the switch reverts, and the line "Couldn't save. Try again." appears):

| Row | Description | Notes |
|---|---|---|
| `Share what I'm reading` | "Others on this server see what you start and finish." | The master: when off, the next four switches keep their values but are disabled, captioned "Turn on sharing first." |
| `Show my reactions` | "Your stamps on chapters appear to others." | |
| `Let others add me to shared shelves` | "Others can invite you to shelves they share." | |
| `Receive recommendations` | "Others can pass series to you." | |
| `Include 18+ titles in my activity` | "Only readers whose own 18+ setting is on can see these." | Rendered only while this profile's gate is open; default off |
| `Hide this series from my activity` | "Hidden series never appear in your shared activity." | A list of rows (40 × 60 cover, title, `quiet` `Remove`), then `quiet` `Add a series` opening a library search sheet; every change sends the whole `excluded_series` list |
| `Clear my shared activity` | "Removes everything you've shared so far." | `destructive` button; dialog "Clear everything you've shared? Others stop seeing your past activity. Your library isn't touched." with `Clear` (`destructive`, 1000 ms arm) and `Cancel`; `DELETE /circle/activity`; toast "Cleared your shared activity."; failure toast "Couldn't clear your activity." |

Above the rows, the **preview line**, typed at 50 ms per grapheme in `type.body` (a `p`): "Others see: *Yash* finished chapter 142 of *Omniscient Reader*." built from the latest row of the reading history (completed → "finished chapter N of T"; otherwise "started T"); with sharing off, "Others see nothing. You're reading privately."; with no history, "Others see nothing yet. Read a chapter and it appears here." Every `PATCH` sends only `sharingPatch()` keys; haptics `toggle.on` / `toggle.off` (sounds `toggle.on` / `toggle.off` if on).

### H. Tonight, Index and Quick look

1. Tonight (web/08's section registry): render the section types web/08 skipped, in the server's order and folio numbering:
   - `sent_to_you` "Sent to you": posters of the letters' series with the sender's 20 px avatar at the bottom-left; under the H3, the section `note` typed at 50 ms per grapheme in `type.body.italic` `ink.60` as "Riya: you'll love the tower arc." (at most 140 characters); a poster opens the series and marks its letter read; `See all` → `/circle?tab=letters`.
   - `circle` "From the Circle": posters with an avatar stack (20 px, overlapping 6 px, at most 3) at the bottom-left; `See all` → `/circle`. While this section is in view, `useCircleMembers({enabled: true})` keeps the 60 s poll.
   - `circle_top` "Most read in the circle": ranked posters (a Bodoni Moda Roman numeral in `ink.45`, 1.0 × the poster height, half behind the poster's left edge, the accessible name "Number 3, Solo Leveling").
   - The Also-in-this-issue `letter` card now opens `/circle?tab=letters`.
2. Index (web/17): the `Circle` row folio `2 NEW` (`newCount`), hidden at zero.
3. Quick look (`parts/quick-look-actions.ts`): `Recommend to…` on followed posters, cuttings and World items with an available source, when members exist.

### I. Accessibility, motion and platform rules (§14)

- Hit targets: 44 × 44 px on coarse pointers with 8 px spacing (stamps are 44 px squares 8 px apart), 32 × 32 px on a fine pointer.
- Every icon-only control has a label and a tooltip; colour is never the only signal (a reaction has a glyph and a name; the guard uses words, §14.3).
- Reduced motion (§4.8): Unfold becomes a 150 ms (`dur.reduced`) fade; the ring colour swaps without the dissolve; Unseal shows the end state at once; typed kickers, counts and the preview line appear whole; Page, Rise and Insert become 150 ms fades; the tab rule fades.
- Screen readers: dispatches are list items with the full sentence; the ring and `NOW` are announced in the member's accessible name ("Riya, reading now"); counts through `folioLabel()`.
- Every gesture has an alternative: long-press tooltips have hover and the member page; the schedule-row long-press list has the `04 CIRCLE` tab.
- Content safety (§14.11): nothing counts, lists, blurs or hints at 18+ items the viewer's gate hides; the client never computes eligibility itself (it reads `can_receive`, the feed and the reactions as served).

### J. Out of scope here

Glass's Circle (web/43), the Glass-only sharing switches `show_presence` and `share_streak` (never shown here, never sent), any change under `mobile/`, `backend/` or `design/`.

## File layout

```
frontend/src/features/circle/{types,api,hooks,reaction-kinds,spoiler-guard,dispatch,letters,sharing,reaction-outbox,presence}.ts
frontend/src/features/circle/{reaction-kinds,spoiler-guard,dispatch,letters,sharing,reaction-outbox,presence}.test.ts
frontend/src/features/library/{api,hooks}.ts                (collectionsWithShared, share, leave)
frontend/src/skins/cinematic/index.ts                       (circle and circleMember out of PENDING)
frontend/src/skins/cinematic/screens/circle/CircleScreen.tsx
frontend/src/skins/cinematic/screens/circle/{ReadersStrip,ActivityColumn,Dispatch,LettersAside,CircleTabs,CircleStates}.tsx, use-circle-keys.ts
frontend/src/skins/cinematic/screens/circle-member/CircleMemberScreen.tsx
frontend/src/skins/cinematic/parts/{ReactionStamps,PassItOnSheet,LibraryPickSheet,ShareShelfSheet}.tsx
frontend/src/skins/cinematic/primitives/Avatar.tsx          (reading-now ring and NOW badge, if missing)
frontend/src/skins/cinematic/primitives/cards/LetterCard.tsx (Unfold, read rule)
frontend/src/skins/cinematic/screens/reader/{Credits,PageActions,CircleReaders}.tsx      (reactions, React, Recommend)
frontend/src/skins/cinematic/screens/<web/14's novel end matter and margins files>       (reactions in stock colours, CIRCLE tab)
frontend/src/skins/cinematic/screens/<web/11's feature and book page files>              (Recommend button, 04 CIRCLE tab, schedule-row counts)
frontend/src/skins/cinematic/screens/<web/10's collections files>                        (shared shelves)
frontend/src/skins/cinematic/screens/<web/18's settings section 09 file>                 (Circle & privacy)
frontend/src/skins/cinematic/screens/tonight/sections/{SentToYou,FromTheCircle,MostReadInCircle}.tsx
frontend/src/skins/cinematic/parts/quick-look-actions.ts
frontend/src/skins/cinematic/Shell.tsx and <web/17's Index file>                         (counts, only if placeholders)
frontend/src/features/novels/<the novel reader controller>                               (onChapterCompleted, only if missing)
frontend/src/app/(preview)/skin-preview/[skin]/primitives/…                               (gallery: stamps in every state, the ring, Unfold)
frontend/e2e/cinematic/web-22-circle.spec.ts
frontend/e2e/support/seed-circle.ts
frontend/e2e/fixtures/circle/{members,feed,letters,reactions-guarded,reactions-open,member,sharing}.json
docs/redesign/proof/web-22/…
```

Follow the naming web/08–web/21 used for screen folders. Skin files import only data files from `@/features/**`, `@/lib/**`, `@/services/**`, `@/skins/contract.generated` and their own skin folder; utilities use only §2.8 and §3.5 names.

## Work order and commits

One commit per working step after typecheck, lint, test and build (RAM guard first), then push. Messages start with `web-22:`.

1. `web-22: circle data layer` (A with tests).
2. `web-22: The Circle screen, readers strip and letters` (B).
3. `web-22: reaction stamps and the spoiler guard across readers and series pages` (C).
4. `web-22: Pass it on` (D).
5. `web-22: shared shelves in collections` (E).
6. `web-22: member page and Settings Circle & privacy` (F, G).
7. `web-22: Circle rails on Tonight, Index counts, Quick look` (H).
8. `web-22: circle e2e and proof`.

## Acceptance criteria

- [ ] `circle` and `circleMember` are out of the Cinematic `PENDING` set; the Vitest completeness test passes.
- [ ] With two sharing profiles (the seed of Verification), `/circle` as Aarav shows Riya in the readers strip, her dispatches grouped by day with the exact sentences, the time folios, the 40 × 60 covers, and `Read it too` only for series Aarav does not follow; `j`/`k`/`Enter`/`1`–`5`/`l` work.
- [ ] With Riya's `show_presence` on and a read within 15 minutes, her avatar wears the 2 px ring in the series' `ambient.duo` and a `NOW` badge; the tooltip withholds the chapter folio when Aarav has not opened that chapter; after the next poll with `now: null` the ring fades out over 800 ms (fixture); with `show_presence` off there is no ring and no `NOW`.
- [ ] Spoiler guard (§15.7): on an unread, a half-read and a finished chapter, the credits, the reader `CIRCLE` panel, the feature page schedule-row list, a Circle dispatch and the member rail show respectively "reacted to Ch. N" with no glyph, the same, and the full reaction; completing the chapter in the reader unseals the visible rows (counts and avatars fade in 160 ms, 40 ms apart) without a reload; the viewer's own reaction is never guarded.
- [ ] Stamps: five offered stamps, `HYPE` and `WRECKED` only with counts above zero; pressing one fills it, types the count, posts the reaction; pressing another moves it; pressing it again clears it (`DELETE` with the body); offline presses draw at once and flush on reconnect (the spec toggles `context.setOffline`).
- [ ] Pass it on: only `can_receive` members listed; the counter reads `12 / 140` and blocks at 140; Send posts the letter with `recommend.send`; a fixture `409 recipient_unavailable` deselects that member with "Riya isn't taking recommendations any more." and keeps the note; no eligible recipient shows "Nobody is taking recommendations right now." with `Send` disabled; offline disables Send with "Sending needs a connection."
- [ ] Letters: a new letter unfolds (480 ms clip from the top) with its kicker typed; after 2 s at 50 % visibility it turns `read` and the dot fades; `Keep` keeps it in Tonight's `Sent to you`; `Dismiss` removes it; a failing `PATCH` restores the card with "Couldn't update the letter."; the Index row, the thumb-index badge and the sidebar count show the `new` count.
- [ ] Shared shelves: plates show `SHARED` and avatars; `SHARED WITH YOU` lists the shelves shared with the viewer with `CAN ADD` / `VIEW ONLY`; actions follow the permission table by role (hidden, not disabled); Leave shelf asks with the 1000 ms arm; smart shelves cannot be shared; sharing off hides Share with the explained overflow item.
- [ ] Settings → Circle & privacy: every row of G, the 18+ row only with the gate open, the master disabling the next four, `PATCH` bodies carrying only changed keys (captured with `page.on("request")`, never `show_presence` or `share_streak`), the hidden-series list, `Clear my shared activity` with the arm, and the typed preview line in its three forms.
- [ ] Member page: masthead, deck, rails, the recommend flow with the member preselected; `404 circle_member_not_sharing` shows "Riya isn't sharing right now."
- [ ] Series pages: the feature page's phone icon row reads `FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND` (390 × 844) and `SEND` opens Pass it on; the book page shows `IN THE CIRCLE` with Riya's avatar when Aarav views a book Riya follows, and no row when nobody else does.
- [ ] Tonight shows `Sent to you` (typed note), `From the Circle` (avatar stacks) and `Most read in the circle` (ranked) in the server's order with gapless folios; the Also `letter` card opens the LETTERS tab.
- [ ] 18+ and isolation: with Aarav's gate closed and a mature series in Riya's activity (Riya's `include_mature` on), Aarav sees no trace of it anywhere (feed, strip ring, reactions, letters, shelves, Tonight sections, counts); with the gate open it appears; Aarav never sees Riya's library, history or bookmarks beyond the shared items.
- [ ] Every Circle state of B8 renders with its exact copy (fixtures for the empty cases).
- [ ] Reduced motion: Unfold is a 150 ms fade, the ring swaps without a dissolve, Unseal and typing show end states.
- [ ] Keyboard: every control reachable with Tab in reading order, the double focus ring on keyboard focus only, the stamps usable as a radio group; the "Circle" key group in the `?` sheet.
- [ ] Hit targets: every `button, a, [role="button"], [role="radio"]` inside `main` is at least 44 × 44 px at 390 × 844 and 32 × 32 px at 1440 × 900.
- [ ] Per-skin boundary: `grep -rn "skins/" frontend/src/features/circle` is empty, so Glass (web/43) uses the same hooks and the one seven-kind enum: Cinematic offers five stamps and renders `HYPE` and `WRECKED` when present, Glass offers its six; Cinematic never sends `show_presence` or `share_streak`, which only Glass's Settings change.
- [ ] Lint, typecheck, Vitest and build green, `node design/build.mjs --check` and `node design/lint-utilities.mjs` pass, and Vitest totals are at least the start-of-step totals with 0 failed.

## Verification

Run from `/srv/manhwamaniacs/dev/ManhwaManiacs`, one command at a time, each after the RAM guard:

```
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # Vitest: passed >= start-of-step count, 0 failed
cd frontend && npm run build         # baseline: exit 0 (stop next dev first)
```

Read-only dependency check (cheap, no build): `cd backend && .venv/bin/python -m pytest -q --no-header tests/test_circle_core.py tests/test_circle_mature_gate.py` and the backend/09 Circle test files (`ls backend/tests | grep -i circle`) must pass before you trust the API; if they fail, stop and report. This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

Visual proof and behaviour against the dev stack (`docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md`; the seeded account `demo` has Riya with the gate open and Aarav with it closed, and Aarav follows three of Riya's series; credentials in `backend/scripts/README-dev-stack.md`, never committed):

1. `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` must print `200`, else `backend/scripts/dev_stack.sh start`. Web client: `cd frontend && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`.
2. `frontend/e2e/support/seed-circle.ts` (called from the spec's `beforeAll` through Playwright's `request` fixture, signed in as `demo`, switching profiles with `X-Profile-Id`): `PATCH /profiles/<Riya>/sharing {"activity": true, "reactions": true, "recommendations": true, "shelves": true, "show_presence": true}` and the same for Aarav (without `show_presence`); Riya completes chapter 1 of a series Aarav follows (`POST /reader/progress` with `is_completed: true`), starts another, reacts `loved` on chapter 1, sends Aarav a letter with the note "you'll love the tower arc.", and shares the "Weekend binge" shelf with Aarav in `can_add` mode. It records the ids it creates and the spec's `afterAll` removes them (`DELETE /circle/activity` for both, unshare, dismiss the letter, restore both sharing records to their defaults), so the dev database returns to its seeded state.
3. Run `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD=<from the README> npx playwright test e2e/cinematic/web-22-circle.spec.ts`. The spec views as Aarav (the profile picker, `mm-skin-debug=cinematic`), uses the live data from the seed, and `page.route("**/api/circle/**", …)` fixtures only for states the seed cannot make (the empty states, `409`, `404 circle_member_not_sharing`, the ring fading out, a mature item with the gate open and closed).
4. Screenshots at 1440 × 900 and 390 × 844 into `docs/redesign/proof/web-22/` (by the spec, or `MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-22 --skin cinematic --routes /circle --grid` from `frontend/` (`--skin cinematic` is required: without it `proof.mjs` sets no cookie and captures the legacy skin before the flip; `proof.mjs` names its own files, so every named shot below is saved by this step's spec with `page.screenshot`)), each at both sizes: `circle-all`, `circle-grid`, `circle-reading`, `circle-reactions`, `circle-letters`, `circle-shelves`, `circle-ring-tooltip`, `circle-quiet`, `circle-private-banner`, `circle-only-me`, `circle-loading`, `circle-offline`, `circle-error`, `letter-unfold` (mid-unfold), `member`, `member-not-sharing`, `stamps-credits-open`, `stamps-credits-guarded`, `reader-circle-panel-guarded`, `reader-circle-panel-unsealed`, `feature-circle-tab`, `schedule-row-reactions`, `pass-it-on`, `pass-it-on-nobody`, `collections-shared`, `shelf-share-sheet`, `shelf-member-view`, `settings-circle`, `tonight-circle-sections`, `reduced-motion-circle`. With `playwright-cli`, always pass `-s=web-22`.
5. Open the motion-timings overlay (`mod+shift+m`) and capture `motion-timings-1440x900.png` after a letter unfold and an unseal: no row may be `proof`.
6. Stop `next dev` and `backend/scripts/dev_stack.sh stop` when done.

## RAM guard

Production shares this box (7,746 MB total, with production containers and five Minecraft bots).

- Before every `npm run test`, `npm run build`, `next dev`, pytest run, Playwright run or dev-stack start: `free -m`, read the `available` column of `Mem:`; under 1024, do not start; stop and report "RAM guard: N MB available".
- `pgrep -af "next build|next dev|vitest|flutter_tester|pytest"` first; never two builds at once; wait for other sessions' builds and test runs to exit; stop your own `next dev` before `npm run build`.
- No `npm install`; every package comes from web/01. If `npm ls motion @base-ui/react sonner` reports one missing, stop and report that web/01 is not done.

## Git

- Branch `feat/vps-slim-source-native`; the eight commits above. Stage only your paths with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a`. Never commit secrets, the demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere**: no `Co-Authored-By` line, no "Generated with" line, no AI author, no mention of an assistant. This holds even if your harness asks for attribution: the owner's `~/.claude/CLAUDE.md` forbids it.
- Push after each working step with `git push origin feat/vps-slim-source-native`, only after `npm run build` passed for that step.

## Guardrails

- Never edit `backend/connectors/`. Never touch production: no `docker` commands, nothing under `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Do not modify `mobile/`, `backend/` or `design/`; if the API differs from `backend/docs/circle-api.md`, stop and report it rather than working around it in the client.
- The client never decides who may see what: eligibility, gating and isolation come from the server; the client only renders and applies the spoiler guard.
- Skin code imports nothing from `frontend/src/components/**` or `frontend/src/features/*/components/**`.

## Report back

Reply with:

1. **Done**: Scope items A1–A10, B1–B10, C1–C2, D1–D3, E1–E8, F, G, H1–H3, I with a one-line status each.
2. **Screenshots**: `docs/redesign/proof/web-22/` and the file list.
3. **Tests**: Vitest totals before and after; lint, typecheck and build results; the backend Circle tests you ran; the Playwright spec's passed and failed counts; the lowest `free -m` available figure seen.
4. **Motion**: the motion-timings rows for Unfold, Unseal, the ring dissolve and the stamp press (planned vs actual, dropped frames).
5. **Open issues**: note for the owner that `NOW` and the reading-now ring appear only for members whose `show_presence` is on, a switch only Glass's Settings exposes (glass §15.6), so a Cinematic-only household never sees them until Glass ships or a row is added; that the feature page `04 CIRCLE` tab is disabled for a non-sharing profile while the Circle screen follows the reciprocity rule (both as DESIGN.md says); anything else DESIGN.md left ambiguous and the choice made; any conflict between this prompt and DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/23-cinematic-ambient-reader-extras.md`.
