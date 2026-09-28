# Cinematic DESIGN.md: capabilities and owner-decisions audit

Lens: every backend capability in `inventory/capabilities.md` has a UI surface with its states and error codes; every binding decision in `inventory/00-decisions.md` is honoured; the four new features are fully specified (screens, entry points, loading, empty, error and offline states, backend calls); the two signature animations match the decisions file. Every "missing" claim below was checked with a whole-file search of `cinematic/DESIGN.md`. Where the backend source was read to confirm a contract, the file and line are cited. Line numbers refer to `cinematic/DESIGN.md` as of this audit.

Result: 30 findings (5 high, 12 medium, 13 low).

---

## PRODUCT-1 · high · §9.1.5, §9.1.7, §8.8, §8.14.6, §8.17, §8.18

**Problem.** "Previously on" has no availability contract, and the default setting sends most manga through a dead-end slate. Buttons and the reader chip appear "when a recap is possible" or "is available", but no endpoint or payload field says so. `GET /ai/recap` is the only call, and it is a streamed generation. For manga, a recap needs OCR text, which exists only for chapters someone scanned. With the default `AFTER 14 DAYS AWAY`, the recap "opens first" on Continue whatever its availability. So a series with no indexed dialogue (most manga) shows the `NO RECAP FOR THIS ONE` slate before the reader. The recap range rule (which chapters, how many) is also undefined, so are the SSE framing and the `2 MIN` estimate, and whether a recap spends the daily ask budget.

**Evidence.**
- l.1768: "`secondary` `Previously on…` (only when a recap is possible)"
- l.2903: "`AFTER N DAYS AWAY` (default N = 14; the recap opens first when the gap is ≥ N days)"; "a slim chip on the first page, `PREVIOUSLY ON · 2 MIN` … and a recap is available"
- l.2912: "No recap (manga with no indexed dialogue in the range)"
- l.2934: `GET /ai/recap?source&series&to` → "Streamed text (SSE) + `{range, cast, sourced_from, available, reason}`"
- capabilities §26: "OCR `page_texts` for manga chapters (only for chapters someone scanned)"

**Fix.**
- Add `GET /ai/recap/availability?source&series&to` → `{available, reason: "ok"|"no_dialogue"|"first_chapter"|"not_configured"|"budget_exhausted", range: {from_key, to_key, from_number, to_number}, est_seconds, cached}`. Carry the same object as `recap` on the `GET /home` cover, on each `continue` item and on the series page load. Add it to §15.5.
- Range: the chapters this profile completed before `to`, newest first, at most 12, stopping at the first gap of more than 60 days in `last_read_at`.
- Manga is available when OCR coverage (`GET /ocr/coverage`) indexes at least 50 % of the range's chapters. Novels are always available except on the first chapter.
- Every `Previously on…` button, the now-showing strip action and the reader chip render only when `available`. `ALWAYS` and `AFTER N DAYS AWAY` auto-open only when `available`; otherwise `Continue` goes straight to the reader with no slate. The `NO RECAP FOR THIS ONE` slate is reachable only from an explicit tap on a stale button.
- The chip shows `ceil(est_seconds / 60)` as `2 MIN`.
- SSE framing: `event: meta` (data `{range, cast, sourced_from}`, sent first), `event: delta` (data `{text}`), `event: done`, `event: error` (data `{code, message}`). Flutter reads it with the installed HTTP client's streamed response and a line splitter, with no new package.
- Budget: a recap counts as one ask against the caller's daily ceiling (60 for the owner, 10 for other accounts) only on a cache miss.

---

## PRODUCT-2 · high · §8.7, §8.8 (new-profile state), §9.1.2 case 5, §8.20

**Problem.** Onboarding and the new-profile Tonight are built on data that a new profile does not have:
- Pins are per profile, and a new profile has none.
- World recommendations return an empty `for_you` when nothing is followed or read.
- There is no "world recommendations by genre" endpoint.
- "Each pick inserts 3 similar posters" has no call: `GET /ai/similar` takes `source&series`, but the onboarding wall is AniList items.

As written, step 3's genre paragraph, step 5's seed wall, the format mosaics and every new-profile Tonight section (`Popular on your sources`, `Sources`, `Genres`) come back empty. Separately, `onboarding_step` has no migration default, so the first launch either onboards every existing profile or none.

**Evidence.**
- l.1730: "the genre paragraph (the union of the pinned sources' genres and the world-recommendation genres…)"
- l.1740: "A poster wall seeded from steps 2–4 (world recommendations by genre). Each pick inserts 3 similar posters right after it"
- l.1820: "`Popular on your sources` (source browse "popular" of pinned sources)"
- l.2464: "No pinned sources: the section is not rendered."
- capabilities §26: "Design empty states for a brand-new profile with no reading history (world recs return empty `for_you` then)"
- backend `services/world_recs.py:451`: `return {"for_you": [], "sections": [], …}` when there are no seed titles
- l.1755: `GET /profiles` rows gain `onboarding_step`, with no default stated

**Fix.**
- Add `GET /onboarding/catalog?formats=&genres=&styles=` → `{formats: [{format, covers: [cover_url ×3]}], genres: [{name, weight}] (30–40 entries, the union of every browsable source's genre list, gated on serve), seeds: WorldItem[] (24, AniList trending filtered by the liked and loved genres, `available` items first, `is_adult` excluded unless the gate is open)}`. Cache it 24 h per (gate, formats, genres).
- Extend `GET /ai/similar` to accept `anilist_id` and return 3 WorldItems (budget-free, cached 7 days) for the per-pick insert.
- With 0 pins, the new-profile `popular` section and the §9.1.2 case 5 cover story use the `popular` browse mode of the 3 healthiest non-18+ sources of the current content kind (`health.status == "ok"`, fewest `consecutive_failures`), first 12 titles.
- Migration: set `onboarding_step = "done"` for every profile that exists when the column is added; new profiles default to `null`, which means step 1.
- Add all of the above to §15.5.

---

## PRODUCT-3 · high · §9.3.2, §9.3.6, §9.3.7, §9.3.8, §8.14.12, §8.17 (tab 04 CIRCLE)

**Problem.** The Circle backend list does not cover the Circle screens it has to feed. An implementation session would have to invent the missing calls:
- Member page (`/circle/:profileId`): `GET /circle/feed?cursor` has no member filter, and there is no member endpoint for "Now reading / Recently finished / Their reactions / shared shelves".
- `Clear my shared activity`: no endpoint.
- Feature page `CIRCLE` tab ("who follows or read it") and the reader `CIRCLE` panel ("Riya is on Ch. 150"): nothing returns other members' follow or progress state for one series.
- `DELETE` for reactions: no path or body.
- Shared shelves: no call lists `SHARED WITH YOU`, lets a `CAN ADD` member add, or lets a member leave.
- Polling cadence for `GET /circle/members`: none, although the reading-now ring "dissolves … when they switch series" and fades "15 minutes after their last page".
- Circle-specific error codes: none.

**Evidence.**
- l.3142: "rails `Now reading`, `Recently finished`, `Their reactions`; shared shelves"
- l.3138: "`Clear my shared activity` (destructive, dialog)"
- l.2392: "**CIRCLE** (§9.3): who follows or read it"
- l.2178: "Members who read further than the viewer are listed as "Riya is on Ch. 150""
- l.3132–3134: `SHARED WITH YOU`, `Leave shelf`
- l.3146: the complete endpoint list, which has none of the above; the only reaction write is "`POST /circle/reactions {…}` / `DELETE`"

**Fix.** Add to §9.3.8 and §15.5:
- `GET /circle/members/{profile_id}` → `{profile, sharing: {activity, reactions}, now, reading: [series], finished: [series], reactions: [...], shelves: [...]}`; `404 circle_member_not_sharing` renders "Riya isn't sharing right now."
- `GET /circle/feed?cursor&profile_id=&kind=reading|reaction|letter`.
- `DELETE /circle/activity` → 204.
- `GET /circle/series?source&series` → `{followers: [profile], readers: [{profile, chapter_key, chapter_number, last_read_at}]}`, gated on serve.
- `DELETE /circle/reactions` with the same body as POST `{source_id, series_key, chapter_key}`.
- `GET /library/collections` gains `shared: {owner_profile_id, mode, member_profile_ids} | null` per row, plus a `shared_with_me` array.
- `POST /library/collections/{id}/series` is allowed for `can_add` members (`403 forbidden` otherwise).
- `DELETE /library/collections/{id}/share/me` implements Leave shelf.
- Poll `GET /circle/members` every 60 s while Circle, Tonight or a reader `CIRCLE` panel is visible; pause in the background. The ring colour updates on each poll.
- `409 recipient_unavailable` when a recipient turned `Receive recommendations` off between opening the sheet and sending; toast "Riya isn't taking recommendations any more."

---

## PRODUCT-4 · high · §9.4.3, §2.1.5, §15.5, §15.6, §15.10 S1

**Problem.** Guided view contradicts the contract's own rule against analysing pages on the VPS, and its states are incomplete. Panels are "computed server-side from the page proxy with … Pillow" in the background for every page. Yet the contract moved page tint to the client because "the shared VPS image proxy must not decode and analyse every page" (S1, awaiting owner sign-off), and §15.6 repeats that the proxy does no image work. Server-side detection also re-fetches every page upstream through the shared 60/min sources bucket. States are missing too:
- no loading state while panels are fetched;
- no offline state: downloaded chapters store no panels and an offline manifest has no `panels_ready`;
- no error state for the panels call.

**Evidence.**
- l.3175: "computed server-side from the page proxy with a whitespace/blackspace gutter projection in Pillow; cached per page ETag"
- l.147: "the shared VPS image proxy must not decode and analyse every page"
- l.3867: "so the shared VPS image proxy does no colour work"
- l.3181: states cover only not ready, failed page and reduced motion
- capabilities §26: "Panel detection has no backend support."

**Fix.**
- Detect panels on the client, in the same place as page tint: a Web Worker on the decoded `ImageBitmap` scaled to 360 px width, and a Flutter `compute()` isolate on a 360 px `ResizeImage` decode.
- Rule: row and column projections of luminance; a gutter is a run of at least 12 px (at 360 px width) where at least 98 % of pixels have L > 0.92 or L < 0.06; panels are the rects between gutters, each at least 8 % of the page area; reading order follows the layout direction. Pin the rule with shared vectors, `design/panel-vectors.json` (24 pages with expected rects, run by both suites).
- `panels_ready` becomes client state (the current page has been analysed). The `panel-focus` button appears once the first page is done.
- Downloaded chapters store panels in their local manifest copy, so guided view works offline. Optionally `POST /reader/panels` caches client results the way page tints are cached.
- States: loading "Finding panels…" with a 16 px leader dial in the folio slot (at most 400 ms per page); analysis failed on a page → `PAGE 18 · WHOLE PAGE`.
- Drop `GET /reader/panels` from §15.5, or list it under S1 as a sign-off item.

---

## PRODUCT-5 · high · §8.3 (States), §8.30.4

**Problem.** A mistyped current password in Change password signs the user out. The backend answers a wrong current password with **401** `invalid_credentials`, and the contract's global rule treats any 401 as a session loss. The Change password sheet also has no copy for `weak_password` (422) or for its own rate limit (5/min + 20/h).

**Evidence.**
- l.1648: "Signed out mid-session (any 401): the app dips to this screen with the toast "You've been signed out.""
- l.2711: validation lines "(empty, too short, too long, mismatch, same as current)", and no server errors
- backend `services/auth_service.py:471-474`: `"Current password is incorrect."`, `code="invalid_credentials"`, `status_code=401`
- capabilities §1: "change-password 5/min + 20/h"

**Fix.**
- The global handler signs out only when `status == 401` **and** `code` is `not_authenticated` or `auth_required`.
- Change password maps:
  - `invalid_credentials` → field error under Current, "That isn't your current password." (`proof`), with focus returned to the field;
  - `weak_password` → under New, "Pick a stronger password: at least 8 characters.";
  - `rate_limited` → a `SLOW DOWN` line with the `Retry-After` countdown, and `Change password` disabled until it reaches 0.

---

## PRODUCT-6 · medium · §9.3.4, §7.25, §9.3.2

**Problem.** Circle leaks other profiles' 18+ settings, against the per-profile isolation and 18+ decision. First, the Pass it on sheet lists only recipients whose gate is open and says so, which tells the sender which profiles on other accounts have 18+ switched on. Second, the reading-now ring and `NOW` badge check only the viewer's gate and the exclusion list, not the member's `Include 18+ titles in my activity` switch (off by default). So a member reading an 18+ series shows its colour and title to any gate-open viewer, although they never chose to share 18+ activity.

**Evidence.**
- l.3125: "for an 18+ series, only recipients whose gate is open are listed, with the caption "Only readers who can see 18+ titles are listed.""
- l.1383: "The ring appears only when … the member shares activity, the series is not excluded, and for an 18+ series the viewer's own gate is open"
- l.3078: "`Include 18+ titles in my activity` (off by default; even when on, 18+ items are only served to viewer profiles whose own gate is open)"

**Fix.**
- Eligible recipients for an 18+ series: `Receive recommendations` on **and** gate open **and** the recipient's own `Include 18+ titles in my activity` on, so only profiles that chose to disclose 18+ are listed. Caption: "Only readers who share 18+ titles are listed."
- `now` on `GET /circle/members` is `null` for an 18+ series unless the member's Include-18+ switch is on **and** the viewer's gate is open. Enforce this server-side and restate it in §7.25 and §9.3.8.

---

## PRODUCT-7 · medium · §8.17 (Gestures, Platform deltas), §8.18 (Gestures), §11 swipe row

**Problem.** Chapter-level `Mark read`, `Mark unread up to here`, swipe-left `Mark read` and the desktop hover "mark read" have no backend call. `Mark unread` cannot work on today's API at all, because progress merges furthest-wins and never rewinds. Posting completed progress rows would also record reading sessions, inflating The Numbers and extending streaks with no reading.

**Evidence.**
- l.2409: "long-press a chapter → Mark read / Mark unread up to here / Download / Bookmark start; swipe a chapter row left → Mark read"
- l.2403: "hover reveals row actions (download, mark read)"
- l.2433: "long-press a contents row → Mark read"
- capabilities §13: "The merge is furthest-wins and never rewinds."
- backend `services/progress_service.py` `record_session` writes a `ReadingSession` for progress saves
- §15.5 has no progress addition

**Fix.**
- Mark read: `POST /reader/progress/batch`, one row per chapter from the chapter list up to the tapped one, `{last_page: max(page_count, 1), page_count, is_completed: true, time_spent_seconds: 0, manual: true}`, in chunks of 200.
- Mark unread: add `DELETE /reader/progress {source_id, series_key, chapter_keys[] (≤ 200)}` (profile-scoped).
- Add both to §15.5, with `manual: true` rows excluded from sessions, statistics and streaks.
- Until the DELETE exists, `Mark unread up to here` is not rendered.
- Result toast: "Marked 42 chapters read." with `Undo`, which calls the DELETE for the same keys.

---

## PRODUCT-8 · medium · §8.16.5, §8.16.8

**Problem.** Re-narration is unreachable. After re-casting a voice, the row shows `RE-VOICING` "until the next render", but nothing triggers that render. The Audiobook sheet offers only `NEXT 10`, `ALL UN-NARRATED` and `NONE`, and labels narrated chapters `ALREADY NARRATED`. It never says they can be selected or that `force: true` is sent. The `priority` input is also unused.

**Evidence.**
- l.2340: "Chapters already rendered keep the voice they were made with until they're rendered again."
- l.2341: "the row shows `RE-VOICING` until the next render"
- l.2354: quick picks `NEXT 10 · ALL UN-NARRATED ⁽³⁸⁾ · NONE`
- capabilities §19.3: `POST /novels/audio/render {…, priority 0-9, force}`

**Fix.**
- In the NARRATE segment, narrated chapters are selectable with the caption `ALREADY NARRATED · WILL BE RE-VOICED`.
- Add the quick pick `RE-VOICE ⁽ⁿ⁾`: chapters whose `rendered_at` is older than the book's `cast_changed_at`. Add both fields to `GET /novels/audio/series` in §15.5.
- Submitting sends `force: true` for already-narrated keys and `priority: 5`. The opener's `Narrate this chapter` sends `priority: 2`.
- After any cast or narrator change, the cast sheet footer shows the owner a quiet `Re-narrate 38 chapters`, which opens the sheet with that pick selected.

---

## PRODUCT-9 · medium · §9.1.3, §7.6 (World card)

**Problem.** The Picks ask box misses three backend answers and mis-renders one result type:
- `suggest_shelf_empty` (409, listed in capabilities) has no state.
- The backend answers a spent budget on `POST /library/suggest` with **429** `ai_budget_exhausted`, the same status as `rate_limited`. The contract maps 429 to the `SLOW DOWN` countdown.
- `ai_not_configured` (503) and `ai_failed` are unmapped.
- `FROM YOUR SOURCES` results (`/library/suggest`) are `{kind:"source", source, series_id, title, cover_url, author, chapter_count, extra, why}`, not WorldItems, yet they are drawn as World cards whose kicker (`MANHWA · ONGOING · ★ 8.4`) and credit (`ON MANGADEX, ASURA +1`) need fields those items do not have.

**Evidence.**
- l.2855: "result cards as **mini reviews** in two columns: World cards (§7.6)"
- l.2873: "Rate limited | `SLOW DOWN` line with the `Retry-After` countdown"
- capabilities §1 code list includes `suggest_shelf_empty`; capabilities §9 gives the suggest item shape
- backend `services/suggestion_service.py:553-557` (`suggest_shelf_empty`, 409), `:652-656` (`ai_budget_exhausted`, 429), `ai_not_configured` (503), `ai_failed`

**Fix.**
- Branch on `code`, never on status alone:
  - `suggest_shelf_empty` → notice `NOTHING TO PICK FROM YET`: "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again." + `Browse sources`, and a quiet `Ask everywhere instead` that switches to `FROM EVERYWHERE`;
  - `ai_budget_exhausted` → the Budget exhausted state (field disabled, quota folio `0 ASKS LEFT TODAY`);
  - `ai_not_configured` → the not-configured state;
  - `ai_failed` → "The editors couldn't answer that one. Try describing it differently." + `Try again`, with the text kept.
- Add a **Shelf** variant of the World card for `kind: "source"` items: full-colour poster from `cover_url` (relative, proxied at the snapped width), kicker `{SOURCE NAME} · {chapter_count} CHAPTERS`, byline "by {author}", the `why` pull quote. The whole card opens `/sources/{source}/series/{series_id}`. No rating, no status, no information-only state.

---

## PRODUCT-10 · medium · §9.1.2, §9.1.7, §8.8 (Streak at risk), §9.2.7

**Problem.** `GET /home` and `GET /library/annual` take no timezone, but they are asked to produce local-time output: the headline's time word ("This morning" 05–11, "This afternoon" 12–17, "Tonight"), the 20:00 at-risk rule, the `streak {current, at_risk}` block and "this week". Statistics needs `tz_offset_minutes` for exactly this reason. The home feed is also cached 10 minutes per profile, so a cached payload can straddle 20:00 or 12:00.

**Evidence.**
- l.2932: `GET /home?content_kind=manga|novel` → `{…, streak: {current, at_risk}, …}`, "cached 10 min per profile"
- l.2835: "the time word follows the local hour"
- capabilities §10: `GET /library/statistics` takes `tz_offset_minutes (-720..840)`

**Fix.**
- `GET /home?content_kind=&tz_offset_minutes=` and `GET /library/annual?year=&tz_offset_minutes=`, both with the parameter required and range −720..840.
- Web sends `-new Date().getTimezoneOffset()`; Flutter sends `DateTime.now().timeZoneOffset.inMinutes`.
- The home cache key is (profile, content_kind, tz_offset_minutes, local hour).
- The client recomputes `at_risk` locally on every Tonight visit from `streak.current`, `streak.last_active_date` and the device clock, overriding the cached flag.

---

## PRODUCT-11 · medium · §9.4.2, §8.34, §15.5

**Problem.** The soundscape delivery path does not exist, and neither does the static folder the install page's fonts come from. `/app/media/{name}` takes one path segment, strips directories, accepts only image suffixes and reads from `mobile/docs/screenshots`. The backend has no static mount. So `/app/media/soundscapes/{id}.ogg` returns 404, and "files under /app/media/soundscapes/" in §15.5 is not an implementable addition.

**Evidence.**
- l.3167: "fetched on first use from the backend's static folder (`/app/media/soundscapes/{id}.{ogg|m4a}`)"
- l.3857: "Soundscape files under `/app/media/soundscapes/`"
- l.2803: "fonts self-hosted from the backend's static folder"
- backend `routes/app_distribution.py:1985-1992`: `safe = Path(name).name`, `_ALLOWED_MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}`; no `StaticFiles` mount anywhere in `backend/`

**Fix.**
- New public route `GET /app/soundscapes/{id}.{ext}`, with `id` in `projector-room, rain-on-glass, night-city, cafe, night-wind, low-drone, afternoon-park, temple-bells` and `ext` in `ogg`, `m4a`. It reads from `backend/media/soundscapes/` (env `MM_SOUNDSCAPES_DIR`) through `FileResponse` (Range support), with `Cache-Control: public, max-age=31536000, immutable`, and returns 404 otherwise.
- `GET /app/fonts/{file}.woff2` from `backend/media/fonts/` for the install page.
- List both routes in §15.5, replacing the "static folder" wording.

---

## PRODUCT-12 · medium · §10.1.1, §10.1.4–§10.1.6, §15.6

**Problem.** The heading reveal disagrees with itself and with the decisions file:
- §15.6 caps letter reveals at 60 graphemes and falls back to a word-level reveal. The decision says "each letter fades in, slides up, and un-blurs", and §10.1.1 specifies per-letter timing for any length ("a 40-grapheme title at 1200 ms"), with the stagger formula already capping total stagger at 560 ms.
- The trigger table requires "every mount, starting after the match cut lands (or 160 ms after first paint)" for cover and feature titles, and first mount for mastheads. Both code samples implement only in-view with a seen-set.
- The Flutter hover wipe is specified as "an `AnimatedDefaultTextStyle` per letter with a delay", but that widget has no delay parameter, and the Flutter `SetHeading` has no `MouseRegion`.
- The web passes `custom={graphemes(text).length}` (spaces included), while Flutter counts graphemes without spaces, so the step differs for headings over 24 letters.

**Evidence.**
- l.3864: "letter reveals cap at 60 graphemes per heading (longer titles fall back to a word-level reveal with the same timings)"
- l.3216, l.3218 (trigger rules), l.3238, l.3268–3273, l.3310
- 00-decisions: "Heading reveal: each letter fades in, slides up, and un-blurs, staggered"

**Fix.**
- Delete the §15.6 cap. The reveal is per letter at every length (blur layers are already dropped below 0.05 σ).
- Add a `trigger` prop: `"inView"` (H3s; seen-set), `"mount"` (mastheads; seen-set per session), `"signal"` (cover and feature titles; no seen-set; starts when `play` turns true).
  - Web: `animate={play ? "show" : "hidden"}`, where `play` is set by the match cut's `ViewTransition` `finished` promise, or 160 ms after first paint.
  - Flutter: `SetHeading(trigger: SetTrigger.signal, play: ValueListenable<bool>)`.
- Flutter hover: one `AnimationController` of `200 + 10 × (n − 1)` ms driven by `MouseRegion.onEnter` / `onExit`. Letter `i` lerps `ink.100` → `spot` over `Interval(10i / total, (10i + 200) / total)`. Exit animates all letters back together in 160 ms.
- Both clients use n = graphemes excluding spaces.

---

## PRODUCT-13 · medium · §9.4.1, §8.15.5

**Problem.** Novel auto-scroll speed is defined against "the profile's measured reading pace", which nothing defines: no measurement, sample window, bounds, storage or conversion from words per minute to scroll pixels. The ruler's WPM equivalent depends on it too.

**Evidence.**
- l.3157: "Novels: 1.00× = the profile's measured reading pace in words per minute (default 250 wpm)"
- l.2244: "1.00× = the profile's measured reading pace (default 250 wpm, §9.4.1); the WPM equivalent under the value"

**Fix.**
- Pace: the median over the profile's last 10 completed novel chapters of `word_count / (time_spent_seconds / 60)`, using only chapters with 60 ≤ `time_spent_seconds` ≤ 7200 and a pace within 80–900 wpm. It stays at 250 wpm until 3 samples exist.
- Store it per profile client-side (`mm.novel-pace.u{user}p{profile}`) and recompute on each chapter completion.
- Scroll speed: `px/s = (pace_wpm × speed / 60) × lineHeightPx / avgWordsPerLine`, where `avgWordsPerLine` = the laid-out chapter's word count / rendered line count, recomputed after any Type sheet change.

---

## PRODUCT-14 · medium · §8.14.2, §8.17, §8.18, §8.24, §7.8 (preview slate)

**Problem.** Prefetching is not paced against the shared sources rate limit (60/min per IP, covering browse, search, series, chapters, covers, page images and novels). The contract adds several prefetch triggers on top of normal page loads:
- the manifest and first two pages on hover, focus or press of entry controls;
- manifests on chapter-row hover plus "the first five on load";
- 3 pages of paged preload;
- silent prefetch of the first three novel chapters;
- a manifest plus a 480 px page image per dialogue-search result, 20 results per page.

Nothing orders or limits these, so ordinary browsing can hit `429` and stall the reader, which is the case capabilities warns about.

**Evidence.**
- l.1978, l.2387 ("Rows prefetch the manifest on hover or focus (and the first five on load)"), l.2437, l.2064, l.2577
- capabilities §1: "the page-image proxy shares the 60/min sources bucket, so a reader must pace prefetch"

**Fix.** One client-side limiter per client for that bucket:
- token bucket: 50 tokens/min (refill 1 per 1.2 s), burst 8;
- priority P0: the visible reader page and the next page;
- priority P1: user-initiated lists (browse, search, series, chapters);
- priority P2: covers in view;
- priority P3: prefetch (hover or focus manifests, first rows, next-chapter manifest, novel chapters, dialogue crops, preview slates);
- P3 runs only while at least 20 tokens remain, with at most 2 in flight;
- hover prefetch starts after a 150 ms dwell; "first five on load" becomes the first 2;
- responses served from the local cache (Cache Storage, image cache, sqflite) cost no token;
- on any 429, P2 and P3 pause for `Retry-After` and P0 retries after it.

---

## PRODUCT-15 · medium · §8.0.3, §8.0.4, §8.17 (follow button)

**Problem.** The contract ignores two identity rules in capabilities §1:
- **Opaque keys in routes.** Keys may contain `/` and `%` and must be percent-encoded per path segment, but the route contract (`/reader/:sourceId/:seriesKey/:chapterKey`, `/recap/…`, `/read-all/…`, `/novels/…`, `/sources/:sourceId/series/:seriesKey`) never says so. The match-cut `view-transition-name: cover-<sourceId>-<seriesKey>` builds a CSS identifier from raw keys, which is invalid for keys with `/`, `%` or spaces and would silently drop the transition.
- **Follow state.** "Is this series followed?" must compare `series_identity`, because Asura rotates slugs. The file never mentions `series_identity` (0 hits).

**Evidence.**
- l.1466–1476 (routes)
- l.1499: "`view-transition-name: cover-<sourceId>-<seriesKey>`"
- capabilities §1: "path segments must be percent-encoded per segment … `series_identity` is what to compare … (Asura rotates slugs, so the key alone lies)"

**Fix.**
- Every key in a route is `encodeURIComponent` (web) or `Uri.encodeComponent` (Flutter) per segment, and decoded exactly once by the router.
- `view-transition-name` = `cover-` + the first 12 hex characters of SHA-1(`sourceId + "\u0000" + seriesKey`), computed once per card.
- Follow state on feature and book pages, posters, Quick look, World cards and Circle's `Read it too` compares `series_identity` against the library's `series_identity` set, never `series_key`.

---

## PRODUCT-16 · medium · §9.3.2, §9.3.4, §9.3.5, §9.3.7

**Problem.** Circle's write paths have no failure or offline states, although each new feature must specify error and offline behaviour. Missing:
- Pass it on: send failure, offline;
- the shelf share sheet: save failure;
- letter `Keep`, `Dismiss` and `Add to library`: failures;
- `Clear my shared activity`: dialog copy and failure;
- the member page: offline;
- the Circle screen: offline, where "Offline / error | Notices" names no copy and does not say whether cached activity shows.

**Evidence.**
- l.3108: "Offline / error | Notices"
- l.3125: the sheet has only the success toast "Sent to Riya."
- l.3142: member page states "not sharing any more …, loading, error"
- l.3138: "`Clear my shared activity` (destructive, dialog)", with no dialog text

**Fix.**
- Circle offline: the last cached feed read-only with the `OFFLINE EDITION` badge; letters' actions disabled with "Needs a connection."; reactions keep their queued behaviour.
- Circle error: `CORRECTION` "The circle didn't load." + `Try again`.
- Pass it on offline: `Send` disabled, caption "Sending needs a connection."
- Pass it on failure: toast "Couldn't send to Riya. Try again."; the sheet stays open with the note kept.
- Share sheet failure: inline `CORRECTION` "Couldn't update who can see this shelf." + `Try again`.
- Letter action failure: toast "Couldn't update the letter.", and the card restores.
- Clear dialog: "Clear everything you've shared? Others stop seeing your past activity. Your library isn't touched." with `Clear` (destructive, 1000 ms arm); failure toast "Couldn't clear your activity."
- Member page offline: notice `OFFLINE EDITION` "The circle needs a connection."

---

## PRODUCT-17 · medium · §9.2.5

**Problem.** "Save image" does not work on Android. It relies on "the share sheet's own Save option". iOS has one (Save Image); Android's system share sheet has no save-to-gallery target, so an Android user has no way to save a stat card, which the decision's "shareable stat cards (image export)" requires.

**Evidence.**
- l.3056: ""Save image" writes to the photo library through the share sheet's own Save option (no photos permission plugin)"

**Fix.**
- iOS: unchanged.
- Android: write the PNG through `MediaStore.Images.Media.EXTERNAL_CONTENT_URI` with `RELATIVE_PATH = "Pictures/ManhwaManiacs"` (API 29+, no permission), via a ~30-line `MethodChannel("mm/save_image")`. Toast "Card saved to Pictures/ManhwaManiacs."
- Below API 29, fall back to the share sheet with the toast "Pick an app to save the card."

---

## PRODUCT-18 · low · §9.2.4 page 10, §9.2.7

**Problem.** The Annual colophon's `NARRATED BY` line needs "the top 3 narration voices by listening time", but nothing records listening. The audio endpoints are reads only, and statistics have no listening fields, so the new annual endpoint has no data for it.

**Evidence.**
- l.3039: "`NARRATED BY` the voices used most in Listen, up to 3"
- l.3067: "the top 3 narration voices by listening time"
- capabilities §10 statistics output and §19.3: no listening telemetry

**Fix.**
- Add `POST /novels/listen-sessions` with an array (≤ 200) of `{source_id, series_key, chapter_key, seconds, voice_ids[≤3], started_at}`. Clients batch it on pause, chapter end and app background when `seconds ≥ 10`, and queue it offline in the progress outbox.
- The annual endpoint returns `top_voices: [{voice_id, name, seconds}]`.
- Add both to §15.5.

---

## PRODUCT-19 · low · §8.14.6 (End states), §8.15.2 (End matter)

**Problem.** Finishing a series has no end state, and capabilities §26 reserves an "Up next" slot for it. The manga `CAUGHT UP` copy promises a next chapter even for a completed series. The novel end matter only says the source has published nothing more, and offers no next series.

**Evidence.**
- l.2051: "deck "MangaDex has published 142 chapters. You'll get a notice when 143 lands.""
- l.2205: "or "You've reached the last chapter this source has published.""
- capabilities §26: "a "Up next" slot after finishing a series"

**Fix.** When the series `status` is Completed (case-insensitive) and its last chapter completes:
- kicker `THE END`, headline "You finished {title}.", deck "{n} chapters, {h} hours.";
- an `Up next` rail (Similar §9.1.4, else Because you read, else From your shelf);
- quiet `Mark as completed` (`PATCH /library/series/{id} {reading_status: "completed"}`), hidden when already completed.

Novels get the same block in stock colours. Tonight's `continue` never lists a finished completed series.

---

## PRODUCT-20 · low · §7.8, §9.1.3, §9.1.6, §9.1.8

**Problem.** AI state copy contradicts itself. §9.1.8 says it is "the only place these states are designed", but:
- Picks draws rate-limited as a `SLOW DOWN` countdown, while §9.1.8 says "Too many asks at once. Try again in a minute.";
- §7.8 and §9.1.6 hard-code "The picks desk is closed tonight." for every unavailable reason, while §9.1.8 gives per-reason copy;
- budget exhaustion reads "Today's asks are used up. They reset at midnight UTC." in §9.1.3 and "The picks desk is closed tonight." in §9.1.8.

**Evidence.** l.2873, l.2871, l.2948, l.2924, the §7.8 rail state "AI unavailable".

**Fix.** One table keyed by `code` or `reason`, referenced from §7.8, §9.1.3 and §9.1.6:
- `budget_exhausted` / `ai_budget_exhausted`: "The picks desk is closed tonight. Asks reset at midnight UTC.";
- `not_configured` / `ai_not_configured`: "The editors' desk isn't set up on this server.";
- `rate_limited`: `SLOW DOWN` "Too many asks at once. Try again in {n} s.", with the live `Retry-After` countdown.

---

## PRODUCT-21 · low · §10.2.4

**Problem.** The Flutter caret blink formula does not produce the specified 530 ms halves. The controller runs 3340 ms, and `(v * 6).floor()` splits the whole 3340 ms into sixths of 556.7 ms, so the blink drifts from the web keyframe (six 530 ms halves, then a 160 ms fade).

**Evidence.**
- l.3475: "one `AnimationController(duration: 3340.ms)` driving `Opacity((v * 6).floor().isEven ? 1 : 0)` for the first 3180 ms"
- l.3397: "530 ms on / 530 ms off three times (3180 ms) and fades out over 160 ms"

**Fix.** `final ms = v * 3340; final o = ms < 3180 ? ((ms ~/ 530).isEven ? 1.0 : 0.0) : 1 - (ms - 3180) / 160;`

---

## PRODUCT-22 · low · §8.8 (Streak at risk), §9.1.2, §10.2.1

**Problem.** The at-risk headline breaks the 60-grapheme headline limit. The count is always spelled out ("One hundred and four"), which pushes long streaks past the ≤ 60-grapheme (≤ 3 s) limit set for typed headlines: "One hundred and twenty-three days and counting. One chapter keeps it alive." is 75 graphemes.

**Evidence.**
- l.1822: "always spelled out whatever its size: "Two", "Twelve", "Thirty-one", "One hundred and four""
- l.2835: "Headline composition (≤ 60 graphemes …)"
- l.3399: "Headlines only, ≤ 60 graphemes (≤ 3 s)"

**Fix.** When the spelled line exceeds 60 graphemes, use "Your {n}-day streak ends at midnight." The count no longer opens the sentence, so it is a numeral under §12.5 (e.g. "Your 123-day streak ends at midnight.", 37 graphemes).

---

## PRODUCT-23 · low · §9.2.2, §8.8

**Problem.** The streak's "read today" rule does not match the backend. The design ties it to finishing a chapter: "first completed chapter of the day", "One chapter keeps it alive", "Read any chapter before midnight". The backend's streak counts any day with a reading session, including a few pages, and keeps it alive through today while yesterday was active. The flame can show "Alive, read today" before any chapter is finished, and the ignite moment would fire on an event the streak does not use.

**Evidence.**
- l.3004: "Just extended (first completed chapter of the day …)"
- backend `services/reading_stats_service.py:690-711` (active days come from `ReadingSession`; "The current streak survives a day with no reading today")

**Fix.**
- "Read today" := `streak.last_active_date == local today`, from statistics called with `tz_offset_minutes`.
- Ignite when a refetch after leaving a reader shows `last_active_date` flipping to today.
- Copy: at-risk deck "Open any chapter before midnight to keep your streak."; the not-yet-today caption "Read a little today to keep your 12-day streak."

---

## PRODUCT-24 · low · §9.2.1, §9.2.4, §9.2.7

**Problem.** The Annual contradicts itself on its time window and labels:
- `GET /library/annual?year=` is a per-year endpoint, yet §9.2.4 says the Annual is a rolling 365-day window reading "Your last twelve months" "until a calendar-year aggregate exists";
- the banner calls the same early issue "Your year so far";
- the banner threshold is ≥ 30 days of data, while `available_years` and the not-enough state use 7 days.

**Evidence.** l.2963 ("any time with ≥ 30 days of data as "Your year so far""), l.3042 ("Rolling windows … "Your last twelve months""), l.3044 ("< 7 days recorded"), l.3067 ("years with ≥ 7 days recorded").

**Fix.**
- The Annual is the calendar year (1 Jan–31 Dec, local via `tz_offset_minutes`). Delete the rolling-window paragraph.
- The current year's cover reads "Your year so far" until 31 December.
- The banner shows from 1 December when the current year is in `available_years`, and before December only with ≥ 30 recorded days.
- `THE ANNUAL 2026 IS OUT` is used only from 1 December.

---

## PRODUCT-25 · low · §8.15.9

**Problem.** The novel reader lacks two capability surfaces the manga reader has:
- the "further on another device" prompt from `advanced: false` (novel progress uses the same rows);
- the stale-copy badge for novel chapters served from cache (`cache.stale`).

**Evidence.**
- l.2288: the state list has neither
- capabilities §13: "`advanced: false` … the hook for a "you're further on another device, jump there?" toast"; "Novel progress uses the same rows"
- capabilities §19.1 and §1: novel chapters carry `cache {status, stale, fetched_at}`

**Fix.**
- Toast in stock colours: "You're further ahead on another device (CH 214, 38%). Jump there?" + `Jump`.
- A `SAVED COPY · 3 H` micro badge in the running head (stock muted) when `cache.stale`, with the tooltip "The source is down; this is the last copy we saved."

---

## PRODUCT-26 · low · §8.30.6

**Problem.** Two backup gaps:
- The mobile `Export backup` opens `GET /backup/export` in the external browser. Mobile authenticates with `Authorization: Bearer`, which the browser does not have, so the download fails unless that browser also holds a web session.
- The nightly card shows only OK or `UNKNOWN`. The backend reports `ok: false` with the failing `phase`, and that state has no presentation.

**Evidence.**
- l.2727: "mobile opens the download in the browser"
- l.2726: "`LAST NIGHTLY · OK · …` (or `UNKNOWN`, never shown as healthy)"
- capabilities §1 (Bearer transport) and §22
- backend `routes/backup.py` (`Depends(require_admin_user)`; `NightlyBackup.ok`, `phase`)

**Fix.**
- Mobile downloads with the app's HTTP client (Bearer) to a temp file `manhwamaniacs-backup-{yyyyMMdd-HHmm}.db`, showing a determinate rule with bytes, then opens the share sheet (`share_plus`) so iOS can Save to Files.
- Error toast: "Couldn't download the backup."
- Nightly `ok: false` → `LAST NIGHTLY · FAILED AT {PHASE} · 28 SEP 03:00` in `proof`.

---

## PRODUCT-27 · low · §5 (event table), §12.4

**Problem.** The splash reveal fires a haptic that is not in the event vocabulary. The logo reveal plays "haptic `impress`", which is an AHAP pattern name, not an event, and no splash event exists in §5 (§6 declares `splash.reveal` as sound-only). The decisions ask for a full haptic vocabulary table, and `design/contract.json` is generated from §5.

**Evidence.** l.3570: "haptic `impress`; sound `reel` lands its hit if on"; §5 table l.829–868; §6 l.891 `splash.reveal` (sound only).

**Fix.** Add the event `splash.reveal` to the §5 table (iOS `impress`, Android `impress`, web —, fired at t = 1180 ms of the reveal, cold start only), and drop "sound-only" from its §6 row.

---

## PRODUCT-28 · low · §8.23 (STORAGE tab, Save to Files)

**Problem.** Capabilities lists a folder picker on Android as the counterpart of "Manage in Files" on iOS. The contract has no Android surface for it: exports go to an unnamed directory, and the platform note only says files are private.

**Evidence.**
- l.2548: Android "Files live in the app's private storage."
- l.2549: "the directory on Android"
- capabilities §24: ""Manage in Files" on iOS or a folder picker on Android"

**Fix.**
- Android STORAGE row `Export folder`: value "Not set — exports stay in the app's folder." and `Choose folder`, which opens the SAF tree picker via the installed `file_picker` 8.1 `getDirectoryPath()`, stored per device.
- Save to Files writes there, and its result dialog shows the folder's display path.

---

## PRODUCT-29 · low · §8.30.1 (Capabilities)

**Problem.** Only four of the seven `GET /settings` capability flags have rules. `online_sources`, `continue_reading` and `reading_progress` have none, so an implementation cannot know what to hide when the server turns one off.

**Evidence.**
- l.2656: rules for `client_downloads`, `ocr`, `collections`, `bookmarks` only
- capabilities §6: `capabilities: {online_sources, client_downloads, ocr, collections, bookmarks, continue_reading, reading_progress}`

**Fix.**
- `online_sources` false: hide Sources, source catalogues, Discover's `SOURCES` scope, Tonight's `sources` and `popular`, `Find it on another source` and `Move to another source`.
- `continue_reading` false: hide Tonight's `continue` section, Library's Continue cuttings, and cover-story cases 1–2.
- `reading_progress` false: hide progress rules and folios (`CH 12 OF 40`, `63%`), the History tab, and the "further on another device" toasts.

---

## PRODUCT-30 · low · §9.2.2, §15.5

**Problem.** The milestone rule contradicts itself on repeat milestones. It says "Each milestone shows once per profile", and the store is a flat `milestones_seen: [7, 30]`. But the card's deck alternative "Your longest is 41." can only appear when a milestone is reached again after a broken streak: the first time a profile reaches 30, it cannot already have a 41-day longest. An implementation cannot tell whether a rebuilt streak's 7 and 30 show a card, and the flat array cannot record a per-run "seen".

**Evidence.**
- l.3008: deck "Your longest yet." (or "Your longest is 41.")
- l.3010: "Each milestone shows once per profile (stored server-side with the streak so it does not repeat on another device)"
- l.3842: "`milestones_seen: [7, 30]` on the statistics streak object, set by `POST /library/statistics/milestones/{days}/seen`"

**Fix.**
- Key milestones by run: `milestones_seen: [{days, run_started}]`, where `run_started` is the first date of the current streak run, set by `POST /library/statistics/milestones/{days}/seen {run_started}`.
- A card shows when `current_days ≥ days` and no entry matches (days, the current `run_started`).
- 365 shows once per run like the others. The deck "Your longest yet." applies only when `current_days > longest_days` before this run.
