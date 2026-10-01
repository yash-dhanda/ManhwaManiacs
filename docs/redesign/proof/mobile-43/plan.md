# mobile/43 plan: Glass Circle

One task per scope item; each lands with its test. Lane M43 (worktree `redesign/M43`); surfaces owned by Glass steps not in this
worktree (mobile/32 Collections, mobile/33 series detail, mobile/35 and mobile/36 readers) get the parts built here and are
wired by those steps (lane override 13), listed in the report.

## A. Shared data layer (`features/circle`, `features/library/providers/lift_store.dart`)
- A1 `sentLettersProvider` (GET /circle/letters?box=sent, `SentLetter` with `to[]`), `memberFeedProvider(profileId)` (feed with
  `profile_id`; Cinematic's `circleFeedProvider(kind)` key is untouched), `newLetterCountProvider` reused, both in the profile and
  18+ invalidation lists. Test: fake Dio adapter for `box=sent` and `profile_id`.
- A2 `presence.dart`: `PresenceState`, `presenceState`, `arcOrder`, `ArcSlot`, `arcLayout`. Tests: 15-minute edge, local midnight,
  order, one member centred, four symmetric.
- A3 `collapse_feed.dart`: `FeedEntry`, `collapseReads`. Tests.
- A4 `finishedChaptersProvider` (local progress rows + this session). Tests: own, finished, half-read, unread, unfollowed.
- A5 outbox `mature` flag + `dropMature()`. Test.
- A6 `letters_deferred.dart`: `scheduleLetter`, `PendingLetter`, `pendingLettersProvider` (flush on paused/detached, `dropMature`).
  fakeAsync tests.
- A7 `recommend_targets.dart`. A8 `excluded_series.dart`. A9 `lift_store.dart` (`liftProvider`, `LiftState`, `LiftPhase`).

## B. Circle screen (`skins/glass/screens/circle/`)
Router: `circle` -> `CircleScreen`, out of PENDING. Presence arc (`arcLayout`, drift, breathing ring, streak badge, semantics
list, arrow traversal), Activity / Letters / Shelves tabs on `?tab=`, sticky day headers, collapsed reads, guarded reactions,
"Read it too", letters (read / Add to library / Not now / Sent chip), shelves, the wide right column, orb flight (one Heroine tag),
every state, keys group "Circle", badges verified.

## C. Reactions
`copy/reactions.dart` (the table), `parts/reactions/chapter_reactions.dart` binding the mobile/28 button and strip to
`chapterReactionsProvider` with the sending / failed / offline / sharing-off states; on activity rows and the friend sheet here.

## D. Shared shelves
`parts/collections/collection_share_sheet.dart`, `shared_shelf_menu.dart` (Save a copy, Leave shelf on `/share/me`),
`adder_orb.dart`.

## E. Recommend
Orb overlay moved from Home into the shell; drag path through the A6 deferred letter; `recommend_sheet.dart` (pick step, orbs,
note, 409), `letter_note_sheet.dart`, `orb_flight.dart` (pure Bezier, tested); `recommend` and `letter-note` registered.

## F. Friend sheet
`circleMember` -> `FriendScreen` as a `GlassSheetPage` (large / 560 px window / full page cold), header orb flight target,
Reading / Shelves / Recent / Their reactions, Recommend something, 404 state.

## G. Settings and series row
Verify mobile/39's Circle and privacy rows against 8.25.15; `parts/circle/series_circle_row.dart`; Hide from my Circle through
`toggleExcluded`.

## H. 18+ and isolation
Purge holder: invalidate Circle providers, drop mature outbox reactions and pending letters; gate-closed widget test.

## Verify
analyze, the Circle tests, the full suite, `build.mjs --check`, captures, report.
