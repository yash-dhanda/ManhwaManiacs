# Glass DESIGN.md: judgement of the product-lens findings

Input: `glass/verify/find-product.md` (28 findings). Each finding was checked against `glass/DESIGN.md` (grepped across the whole file, not only the cited section), `cinematic/DESIGN.md` (§8.7, §8.11, §8.17, §9.2.7, §9.3, §9.4.3, §15.5, §15.10), `inventory/00-decisions.md`, `inventory/capabilities.md`, `stack-decision.md` §2.4 and §2.6, and the backend and client code the finding cites (read only). A finding is confirmed only when the defect exists and the fix below is correct against those documents; where the finder's fix was wrong, vague or offered two options, the fix below replaces it.

Result: **27 confirmed** (several with rewritten or trimmed fixes), **1 refuted** (PRODUCT-24). Two sub-items inside confirmed findings were refuted and removed from their fixes (PRODUCT-25 item 3, PRODUCT-28 item 2).

## Verdicts

| ID | Verdict | Severity | Reason in one line |
|---|---|---|---|
| PRODUCT-1 | confirmed | medium | The endpoints exist (Cinematic §15.5, reused by Glass's §15.5 blanket rule), but no Glass control is bound to them; an implementer reaching for `POST /reader/progress` would fire streaks. Severity lowered from high because the shared calls are already defined |
| PRODUCT-2 | confirmed | high | Glass §9.4.3 and §15.5 call a server-computed `GET /reader/panels` "Cinematic's"; Cinematic defines client detection with `POST /reader/panels` and `pages[].panels` (S11). One backend cannot serve both. Fix rewritten: the finder's 256 px width, invented file paths and 300 ms figure contradict Cinematic's shared rule (360 px) |
| PRODUCT-3 | confirmed | high | `PATCH /profiles/{id}/sharing` field names differ (`share_activity` vs `activity` etc.) and reaction removal differs (`DELETE /circle/reactions/{id}` vs a body). Fix trimmed: Glass's own two fields keep the names already bound in §15.5 and §15.6 |
| PRODUCT-4 | confirmed | medium | Most sources exist in Cinematic §9.3.8, but §8.18 really joins shared-shelf members to the viewer's library (every friend's poster would read "No longer in your library"), the "Sent" filter has no source anywhere, and `recipient_unavailable` has no copy. Fix rewritten: the finder invented a member-page response shape and mapped "Add to library" onto Cinematic's `kept`, which means something else |
| PRODUCT-5 | confirmed | medium | Neither skin's `GET /circle/members` carries anything that tells the sender who may receive a mature series; the rule cannot be built. Fix rewritten to one server rule for both skins, and the Glass-only "18+ collections" filter is dropped in favour of the serve-time gating both skins already specify |
| PRODUCT-6 | confirmed | medium | `backend/routes/app_distribution.py:1985-1992` serves one path segment with image suffixes only; Cinematic §15.5 defines the allowlisted `GET /app/soundscapes/{id}.{ext}`. Fix cleaned of its self-contradicting cache-key sentence |
| PRODUCT-7 | confirmed | medium | Glass invents `POST /library/taste/seed` beside Cinematic's `GET /onboarding/catalog`, sends `onboarding_step` where the shared PUT takes `step`, and its trigger re-opens onboarding after a Skip with no follows. Fix rewritten: the similar-title call and the seed item type follow Cinematic (`anilist_id`, WorldItems), not the finder's `source&series&fallback=genres` |
| PRODUCT-8 | confirmed | low | `suggestion_service.py:595/655/661` raise `ai_failed` 502, `ai_budget_exhausted` 429 (no `Retry-After`), `ai_not_configured` 503; §8.0.10 has no row, so they fall to the generic toast |
| PRODUCT-9 | confirmed | medium | `SuggestRequest` has only `prompt` and `limit ≤ 8`; `use_taste` and a novel filter exist nowhere; Glass calls `GET /home` without `content_kind` and without Cinematic's required `tz_offset_minutes`. Fix rewritten so the shared default leaves Cinematic's asks unchanged |
| PRODUCT-10 | confirmed | low | Cards say "all time" and show a delta "against the previous window"; `/library/statistics` has `totals` (all time) and `window` only. The finder offered two fixes; one is chosen (drop the delta, as Cinematic does) |
| PRODUCT-11 | confirmed | medium | Cinematic's annual payload (§9.2.7) has no `pages_read` and `longest_streak {days, month}` only; `tz_offset_minutes` is required and Glass omits it |
| PRODUCT-12 | confirmed | medium | The rows Glass would draw from carry no rating; the shared `shareable` block exists for exactly this and Glass never reads it. Mature covers could reach exported images |
| PRODUCT-13 | confirmed | medium | `grep -ci smart` = 0. Cinematic stores smart shelves as `rules` with device-computed membership; Glass would show them as empty and offer Add series on them. Fix aligned to Cinematic's rule vocabulary and its "smart shelves can't be shared" rule |
| PRODUCT-14 | confirmed | low | `grep -ci repoint` = 0; Glass offers only "Remove from library" on a dead source, and the owner removes dead connectors by policy, so this path loses reading position for real. Cinematic's endpoint exists |
| PRODUCT-15 | confirmed | low | `GET /sources` carries `health`; `GET /system/source-health` is authenticated, not admin-only (`backend/routes/system.py:76`); Glass shows health only on the admin screen |
| PRODUCT-16 | confirmed | low | §8.4 gives copy for `username_taken` only. Fix corrected: `bootstrap_window_expired` cannot be fixed by restarting (the server says it must be claimed by its operator, `auth_service.py:238-239`) |
| PRODUCT-17 | confirmed | low | `auth_service.py:470-475` returns `401 invalid_credentials` for a wrong current password; §8.0.10 routes that code to Login's copy. The rate-limit half is already covered by the §8.0.10 `rate_limited` row ("the button countdown on auth forms") and is only restated |
| PRODUCT-18 | confirmed | low | `routes/library.py` has only add and remove for members; `_serialize_collection` returns no `created_at`. Cinematic has the same hole, so the fix is registered as shared. One of the finder's two options is chosen |
| PRODUCT-19 | confirmed | medium | The binding "smooth colour transition on hover/state" is in the §10.1 table but in neither sample; the Flutter sample wraps per character (mid-word breaks) and indexes controllers sized for the first string (a `RangeError` when placement 3 changes to a longer title). Fix simplified: a keyed `AnimatedSwitcher` instead of `didUpdateWidget` bookkeeping |
| PRODUCT-20 | confirmed | low | The SSR'd grapheme animations start at first paint and the caret's interval at hydration, so the caret trails. Fix corrected: §10.2 has no CSS fail-safe for the finder to rely on, and the caret's blink and exit animations must be gated too |
| PRODUCT-21 | confirmed | low | capabilities §8: an auto-advanced continue item has `last_page: 1, page_count: 0`; §7.7 prints "p. x of y" and a ring from their ratio |
| PRODUCT-22 | confirmed | low | Cast rows show no gender and give the owner no way to correct it, although `POST /novels/cast` takes `gender`; skip reasons `chapter_unreadable` and `already_queued` (`novel_render_queue.py:125,153`) and `lease_expired` (`:406`) have no copy |
| PRODUCT-23 | confirmed | low | §8.0.8 and §8.25.1 refer to a skin row on the profile form that §8.6 does not have; Cinematic's form has one (its §8.6 `Edition`) |
| PRODUCT-24 | **refuted** | — | Glass's 12 preset names are exactly the existing labels in both clients (`frontend/src/features/profiles/avatars.ts:32-43`, `mobile/lib/features/profiles/models/profile_avatar.dart:31-98`), so the key mapping is one-to-one by label, and the shared `resolveAvatar` already falls back to the default preset for an unknown key. Nothing for Glass to specify |
| PRODUCT-25 | confirmed (items 1, 2, 4) | low | Novel chapters carry `cache.stale` (`novel_service.py:605-609`) with no Glass badge; §8.0.10 would show the `db_busy` capsule for silent keep-alives; `include_cache` exists (`routes/backup.py:64`) with no control. Item 3 refuted: the shared outbox already collects `rejected` indexes (`mobile/lib/features/downloads/providers/progress_outbox_provider.dart:259`) and the "Synced N reads" toast is optional in capabilities |
| PRODUCT-26 | confirmed | low | No slot for `GET /series/enrichment` or `GET /ai/tags`, which the shared backend serves and capabilities §26 asks both skins to reserve. Fix adds the rejection call the finder left out (`tag_rejected`) |
| PRODUCT-27 | confirmed | low | Glass names `tag_ids` as a row field; Cinematic's row field is `tags` and `tag_ids=` is the query parameter; the Manage tags count has no source. One of the finder's two options is chosen |
| PRODUCT-28 | confirmed (items 1, 3, 4) | low | The recommend sheet lacks loading and offline states; the genre chip is drawn even when `GET /sources/{id}/genres` is empty; `?genre=` takes a genre id, not the free string on `SourceSeries`. Item 2 refuted: More like this offline is covered by §9.1.5's offline row. The finder's fallback (a title search for the genre word) returns titles, not a genre filter, and is replaced |

---

## Confirmed

Each entry gives the final fix to apply to `glass/DESIGN.md`. Where a fix adds a backend field, it goes in §15.5, and where it changes a value both skins share, it also gets a row in the §15.6 register.

### PRODUCT-1 (medium): bind Mark read, Mark unread and Mark finished to the shared calls

Add a paragraph **"Mark read and Mark unread"** to §8.12 and point §7.29, §7.34 (chapter-row swipe), §7.35, §8.17 (bulk toolbar and context menu) and §8.19 (Mark finished) at it:

- **Mark read** (one chapter, or in bulk every selected chapter, or every `known_chapters` key of each selected series that is not completed yet) sends `POST /reader/progress/batch` rows `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}` in chunks of 200 (Cinematic's §8.17 and §15.5 call, reused as is).
- **Mark unread** sends `DELETE /reader/progress {source_id, series_key, chapter_keys[] ≤ 200}` → 204.
- **Mark finished** (History) is Mark read of that chapter.
- These controls never use `POST /reader/progress`. A `manual: true` row creates no `ReadingSession`, so it never produces `extended_today: true`, never moves `today_seconds`, the goal ring, Statistics or Wrapped, and never fires `streak.extend` (§9.2.2).
- Toasts: "Marked 42 chapters read · Undo" (Undo deletes only the keys that were not completed before) and "Marked chapter 142 unread · Undo" (Undo re-posts the deleted rows, kept by the client until the toast closes).
- Offline: the controls are disabled with "Needs a connection".

No §15.5 row is needed (Glass adds nothing to these endpoints).

### PRODUCT-2 (high): guided view uses the shared client-side panel detection (S11)

- **§9.4.3 Data**, replaced: "Panels are detected on the client by the shared reader engine exactly as `cinematic/DESIGN.md` §9.4.3 specifies (its Detection, Rule, Parity and Cache paragraphs are the contract for both skins): the page-tint Web Worker, or the `compute()` isolate on Flutter, analyses the page scaled to 360 px wide, one page ahead of the reading position, with the gutter rule and the `design/panel-vectors.json` parity cases run by `panels.test.ts` and `panels_test.dart`. A manifest's `pages[].panels` is used first when present; on chapter exit the engine posts `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}` (fire and forget, skipped offline). Downloaded chapters keep their panels in the local manifest copy and analyse local blobs when none were stored. The engine exposes the current page's result as `panelBoxes` (§15.4)."
- **Entry:** the `panel-focus` button shows once `panelBoxes` is non-null for the current page (not on a `panels_ready` flag).
- **States:** "Finding panels…" means the current page is being analysed (the page is framed whole meanwhile); replace "not ready" with the page-level state "No panels found on this page" (framed whole, the counter reads "Page 7 · whole page", next moves to the next page); replace the offline state with "works from the saved copy". Drop "the button appears when the backend finishes".
- **§9 intro:** remove "and panel boxes" from the list of things the backend computes, and add "panel boxes are detected on the client (§9.4.3, G14)".
- **§15.5:** delete the row "`GET /reader/panels` + `panels_ready` (Cinematic's)". Glass adds nothing to Cinematic's `pages[].panels` / `POST /reader/panels` row.
- **§15.7:** add "panel detection shares the page-sample worker or isolate at 360 px wide, one page ahead".
- **§15.10:** add row **G14**: "§2.6 item 2 (panel boxes on the backend) | Panel detection runs on the client, Cinematic's S11; its sign-off covers both skins | **sign-off** before the reader cluster".

### PRODUCT-3 (high): one sharing payload and one reaction-removal shape

- §9.3 switch table and §9.3.7: use Cinematic's field names for its five switches and keep the two Glass additions under the names already bound in §15.5 and §15.6: `PATCH /profiles/{id}/sharing {activity, reactions, recommendations, shelves, include_mature, show_presence, share_streak, excluded_series}`. Mapping in the table: Share what I'm reading = `activity`, Show my reactions = `reactions`, Accept recommendations = `recommendations`, Let others add me to shared shelves = `shelves`, Include 18+ titles = `include_mature`, Show me in presence = `show_presence`, Share my streak = `share_streak`, Hidden from my Circle = `excluded_series` (`[{source_id, series_key, title}]`).
- §8.25.15 loads its rows from `GET /profiles/{id}/sharing` (Cinematic's; Glass adds the two fields to its response) and writes partial bodies with the PATCH.
- §9.3.7: reaction removal is `DELETE /circle/reactions` with the body `{source_id, series_key, chapter_key}` (one reaction per profile per chapter, so no id is needed).
- §15.6 "Sharing switches" row: add "field names are Cinematic's (`activity`, `reactions`, `shelves`, `recommendations`, `include_mature`); `GET /profiles/{id}/sharing` returns the two Glass fields too".

### PRODUCT-4 (medium): name the Circle data sources and fix the shared-shelf join

1. §9.3.7 lists the calls Glass already inherits from Cinematic §9.3.8: `GET /circle/members/{profile_id}` (the friend sheet: `reading` feeds Reading, `shelves` feeds Shelves, `reactions` feeds Their reactions), `GET /circle/feed?profile_id={id}&cursor` (Recent), `shared_with_me` on `GET /library/collections` (Collections → From your Circle and the Circle Shelves tab), and `added_by_profile_id` on shelf detail rows (the 20 px adder orb). The Reading posters draw their progress line from `chapter_number` over `chapter_count` on each `reading` item; add those two fields to that item in §15.5 as a Glass addition (Cinematic ignores them).
2. §8.18 collection detail: a collection from `shared_with_me`, or one with `shared != null`, renders its member rows from the rows' own `title` and `cover_url` (Cinematic's member-readable rows), never from the viewer's library payload; "No longer in your library" applies only to the viewer's own unshared collections.
3. Letters: opening a card sends `PATCH /circle/letters/{id} {state: "read"}`; "Add to library" follows the series (`POST /library/follow`) and marks the letter `read` if it was `new`; "Not now" sends `{state: "dismissed"}` and the card leaves. `kept` is not used by Glass (it is Cinematic's "Keep" and renders in Glass as an ordinary read letter).
4. "Sent" filter: add to §15.5 as a Glass addition `GET /circle/letters?box=sent` → the same rows with `to: [{profile_id, name, avatar_key}]` in place of `from`. A sent card says "Not opened yet" (`new`) or "Opened" (any other state). Drop "and whether it was added": no field says so, and saying it would expose the recipient's library.
5. §8.0.10 gains two rows: `recipient_unavailable` (409, toast "{name} isn't taking recommendations any more.", that orb is deselected, `warning`) and `circle_member_not_sharing` (404 on the friend sheet, its "Aarav isn't sharing right now." state, no haptic).

### PRODUCT-5 (medium): one server rule decides who may receive a series

- §15.5 (shared, register in §15.6): `GET /circle/members?source_id=&series_key=` adds `can_receive: bool` per member, computed by the server: the member's `recommendations` switch is on, and, when the series is mature (source mature, or resolved rating mature after `mature_override`), the member's 18+ gate is open **and** their `include_mature` is on. No reason field. `POST /circle/letters` refuses any recipient with `can_receive: false` with `409 recipient_unavailable` (copy in PRODUCT-4).
- §9.3.4 menu path: the sheet calls the parameterised form when it opens (3 orb skeletons while loading). Members with `shares.recommendations` off keep the disabled "{name} isn't taking recommendations" row; members who take recommendations but have `can_receive: false` are **omitted** without explanation (as Cinematic does), so the sheet never reveals another profile's gate. Delete "Not available to {name}" and the §9.3.4 18+ line "the sender never learns another profile's gate beyond the disabled row", replacing it with "ineligible recipients are simply not listed".
- The drag-to-orb gesture shows only orbs with `can_receive: true`.
- §9.3.3: delete "18+ collections list only members whose gate is open" and the state "an 18+ collection with no eligible member". A shared shelf's mature members are already served only to viewers whose gate is open (the last bullet of §9.3.3, and Cinematic §9.3.5), so the share sheet needs no gate knowledge.

### PRODUCT-6 (medium): serve Glass's soundscape layers through the shared allowlisted route

- §9.4.2 and §15.5: the 18 layers are served by Cinematic's `GET /app/soundscapes/{id}.{ext}` with the ids `glass-{scene}-{layer}` added to its allowlist, where `scene` ∈ `rain, wind, ocean, hearth, stream, deep` and `layer` ∈ `bed, detail, tone`; `ext` `ogg` or `m4a`; files in `backend/media/soundscapes/` (listed in its `SOURCES.md`), `Cache-Control: public, max-age=31536000, immutable`, anything else 404.
- Replace every `/app/media/soundscapes/glass/…` path. The Cache Storage name `mm-soundscapes-v1` is unchanged.

### PRODUCT-7 (medium): onboarding on the shared taste contract

1. Step 6 reads `GET /onboarding/catalog?formats=&genres=&styles=` (Cinematic's): its `seeds` are 24 WorldItems, 18+ filtered by the profile's gate. Tapping a seed follows its first `available[]` source (`POST /library/follow`); a seed with no available source is kept in `taste.seeds` as `{anilist_id}` and its poster says "Not on your sources yet". Delete `POST /library/taste/seed` from §8.7, §9.1.6, §15.5 and Appendix A.
2. "Each pick pulls up to three similar titles" uses `GET /ai/similar?anilist_id={id}` (Cinematic's onboarding form: 3 WorldItems, budget-free, cached 7 days); with AI unavailable, a pick inserts nothing.
3. The PUT sends `step` (not `onboarding_step`): `PUT /profiles/{id}/taste {step: 1…7 | "done", formats, genres, styles, seeds}`. §15.5 and the §15.6 Taste row: the server accepts `step` 1 to 7 (Cinematic uses 1 to 5); a skin resuming a step beyond its own count resumes at its last step.
4. Trigger (replaces "a profile with no reading history and no follows"): onboarding shows when the active profile's `GET /profiles` row has `onboarding_step` `NULL` or 1 to 7, never when it is `"done"`; Skip on every step (skip-all) and Finish both write `step: "done"`. Resume opens `/welcome?step={onboarding_step}`.
5. §15.6 Taste row becomes: "One `PUT /profiles/{id}/taste` payload with Cinematic's `step`; Glass's `styles` values are its nine crops; the step range is 1 to 7".

### PRODUCT-8 (low): map the AI error codes

Add three §8.0.10 rows, surface "inline in For you" with the §9.1.5 long lines, no haptic:
- `ai_budget_exhausted` (429, no `Retry-After`): the `budget_exhausted` line with the countdown to 00:00 UTC; no automatic retry; re-read `GET /library/suggest/availability`, which hides the Ask box.
- `ai_not_configured` (503): the `not_configured` line.
- `ai_failed` (502): the "upstream error" line and Try again.

And one sentence under the table: "Only `code == "rate_limited"` starts the automatic `Retry-After` retry; an HTTP 429 with another code never does."

### PRODUCT-9 (medium): list the request fields Glass sends

§15.5 gains (Glass additions; register "Suggest requests" in §15.6):
- `use_taste: bool = false` on `POST /library/suggest` and `POST /library/world/suggest`; when true the server adds the profile's taste to the prompt. Glass sends `true` unless the "Use my taste" switch is off. The default is false so Cinematic's asks do not change.
- `content_kind: "manga" | "novel" | null` on `POST /library/suggest`, filtering the local catalogue to sources of that kind. Glass sends `"novel"` in Novels mode (§8.0.8; the worldwide ask is already replaced by a note there).
- The Ask sends `limit: 8` with "Only my sources" on (the server caps local suggest at 8) and `limit: 12` with it off (world cap 15). §9.1.2 States: "results (up to 8 from your sources, 12 worldwide)".
- §8.8 and §15.5: Home calls `GET /home?content_kind={manga|novel}&tz_offset_minutes={local}` (Cinematic's; the offset is required); `content_kind` is sent whenever novels are enabled.

### PRODUCT-10 (low): stat cards show the range, with all time underneath, and no delta

§9.2.1 Totals: each of the four cards shows `window.*` for the selected range, captioned with the range ("Last 30 days", "Last 365 days"), with the all-time figure from `totals.*` as a second line in `caption1` `label3` ("412 h all time"); Series uses `window.series_read` / `totals.series_read`. The 7-point sparkline comes from the last 7 entries of `daily`. Delete "the delta against the previous window" (the endpoint has no previous window, and Cinematic shows none either).

### PRODUCT-11 (medium): Wrapped reads a complete annual payload

- §9.2.3 Data: `GET /library/annual?year={y}&tz_offset_minutes={local}` (the offset is required, −720 to 840).
- §15.5 Wrapped row, extended: `pages_read` (int) and `longest_streak {days, month, start, end}` (`start` and `end` ISO dates), beside `busiest_day` and `firsts_lasts`; add them to the §15.6 "Statistics and Wrapped fields" row.
- Name each card's source: 2 `seconds_read`; 3 `chapters_read`, `pages_read`, `chapters_by_month`; 4 `top_series`; 5 `genres`; 6 `by_hour`; 7 `longest_streak` (the footnote from `start` and `end`); 8 `busiest_day`; 9 `firsts_lasts`; 10 `top_sources`; 11 `circle`; 12 `seconds_read`, `chapters_read`, `pages_read`, `longest_streak.days`, `genres`.
- The year menu on Statistics reads `available_years`; "5 days recorded so far" reads `recorded_days`; "Your {year} so far" follows `partial`.

### PRODUCT-12 (medium): share sides draw only from `shareable`

- §9.2.4: every cover, title and genre word on a share side comes from a `shareable` block (Cinematic's, computed server-side from series that are not mature after `mature_override`): Wrapped from `annual.shareable` (`top_series`, `art_series`, `genre_weights`), Statistics, streak, milestone and single-stat shares from `shareable` on `GET /library/statistics` (Cinematic's "range payload behind Share"; name it in §15.5 as reused). When `shareable.top_series` is empty the card uses card 2's numeral layout with no cover box.
- One check (Playwright, and the Flutter widget-test equivalent): export the Summary card for a seeded profile whose top series is mature and assert its cover URL is not drawn.

### PRODUCT-13 (medium): smart shelves (Cinematic's `rules`) work in Glass

- §8.18: a collection with `rules != null` is **Auto**. Its members are computed on the device over the library rows by the conjunction `rules.all`, with one evaluator in the shared data layer (`frontend/src/features/library/`, `mobile/lib/features/library/`) used by both skins. Its card carries an "Auto" capsule (`caption1`, `lightning` glyph in `iris400`), and its fanned stack uses the first four computed members (the server's `preview_covers` is empty for rules-based shelves).
- Detail shows the rules as read-only chips under the name and hides Add series, Remove and reorder; Share is disabled with "Smart shelves can't be shared" (their members come from the owner's library).
- New collection and Edit gain a "Smart" switch revealing Cinematic's rule chips, combined with AND: Status is ▸ (`reading_status eq`), Favourite (`is_favorite eq true`), New chapters ≥ n (`new_count gte`), Format ▸ (`format in`), Unfinished novels (`content_kind eq "novel"` and `reading_status ne "completed"`). Saved with `POST` / `PATCH /library/collections` (`rules`).
- States: "No series match these rules yet." + "Edit rules"; offline evaluates over the cached library (rules read-only).

### PRODUCT-14 (low): move a followed series to another source

- Add "Move to another source…" to the series ⋯ menu (followed only), and make it the primary action of the §8.0.8 lens when the source is `dead` or `source_not_found`.
- The `?sheet=move-source` `large` sheet runs `GET /sources/search?q={title}&tier=1`, then `tier=2` when `next_tier == 2`, listing candidates as rows (logo, title, "412 chapters" from `chapter_count`, the source's health bead of PRODUCT-15).
- Choosing one shows "You're on chapter 142 here. It becomes chapter 142 on {source}." (or "Your place couldn't be matched; you'll start from chapter 1" when `mapped_chapter_number` is null), a "Keep the old one too" switch (`keep_old`, default off), and the tinted "Move" that sends Cinematic's `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old}`.
- States: searching (the tier capsule of §8.9), no match ("No other source has this series"), failed (toast "Couldn't move it. Try again"), offline ("Moving needs a connection"), success (toast "Moved to {source}" and the sheet zooms into the new series detail).

### PRODUCT-15 (low): source health for every reader

1. §7.7 Source row card: a 10 px health bead after the name (the §8.26 bead as a content twin) from the row's `health.status`: `success` ok, `warning` failing, `danger` dead, `g600` unknown, with a 1 px `warning` ring when `health.demoted`. Accessible text "working", "having trouble", "not working", "not checked yet", plus ", skipped by search" when demoted. Add the source's `language` as a `caption1` tag ("EN").
2. §8.10 header line in `footnote` `label2`: "84 of 89 sources working" from `GET /system/source-health` (authenticated, gated counts), with a chip "Having trouble (5)" that filters the list to `GET /sources/health` rows worst-first; the chip is hidden when `failing + dead == 0`.
3. §8.11 catalogue header: when `health.status` is `failing` or `dead`, an inline notice (`warning` / `danger`): "This source is having trouble; pages may not load." / "This source isn't working right now."

### PRODUCT-16 (low): Register error copy and fields

Add to §8.4:

| Code | Field shaken | Copy | Recovery |
|---|---|---|---|
| `invalid_username` | Username | "Use 3 to 64 letters, numbers, dots, dashes or underscores, starting with a letter or number." (the server rule `^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$`, `backend/services/auth_service.py:49`) | none |
| `weak_password` | Password | the server's `message` ("Password must be at least 8 characters." / "Password is too long.") | none |
| `invite_code_required` | Invite code | "This server needs an invite code." | reveal the Invite code field if it was hidden |
| `invite_code_invalid` | Invite code | "That invite code didn't work. Check it with whoever invited you." | none |
| `registration_disabled` | form | "This server isn't accepting new accounts." | switch to the Closed variant |
| `bootstrap_window_expired` | form | "The time to claim this server from the app has run out. Its operator has to create the first account on the server." | none |
| `bootstrap_already_claimed` | form | "Someone already claimed this server. Sign in instead." | the primary becomes "Sign in" |

### PRODUCT-17 (low): Change password errors

- §8.25.7 errors gain: `invalid_credentials` from `POST /auth/change-password` → inline on Current, "That isn't your current password.", `error` + shake; `weak_password` → the server's message under New.
- §8.0.10 first row: `invalid_credentials` copy is per form (§8.3 at login, §8.25.7 on Change password). Add a note that this 401 never starts the §8.0.9 signed-out flow, which keys only on `not_authenticated`.
- The existing `rate_limited` row (button countdown on auth forms) applies to this form: the button reads "Try again in 42 s" in `mono`.

### PRODUCT-18 (low): member order and creation date for collections

- §15.5 (shared; register in §15.6, since Cinematic's Reorder and "Recently created" need the same): `PUT /library/collections/{id}/series/order {items: [{source_id, series_key}]}` → 204, the full ordered list, owner only (`403 forbidden` for shared-shelf members); `created_at` on `GET /library/collections` rows (the column exists on `collections`).
- §8.18 reorder by drag writes that call after the drop (optimistic, reverting with the toast "Couldn't save the order" on failure); "Recently created" sorts by `created_at`.

### PRODUCT-19 (medium): the heading reveal's colour transition, word wrapping and changing text

- **Web:** add `.letter-reveal { transition: color var(--mm-dur-color-shift) var(--mm-ease-color-shift); }` so a hover or state colour change on the heading (the letters inherit `color`) eases over 240 ms.
- **Flutter:** split the primitive into `LetterReveal` (public, stateless) and `_LetterRun` (the stateful per-string part). `LetterReveal` builds `AnimatedDefaultTextStyle(style: widget.style, duration: const Duration(milliseconds: 240), curve: const Cubic(0.2, 0, 0, 1), child: AnimatedSwitcher(duration: const Duration(milliseconds: 120), switchOutCurve: const Cubic(0.4, 0, 1, 1), child: _LetterRun(key: ValueKey(text), …)))`, so a new string (placement 3) gets a fresh state with correctly sized controllers while the old letters leave together over `fadeOut`, with no `didUpdateWidget` bookkeeping. Each letter is `Text(ch)` with no explicit style, inheriting the animated `DefaultTextStyle` (the translate offset still reads `widget.style.fontSize`).
- **Word wrapping:** `_LetterRun` builds `Wrap(children: [for (final word in words) Row(mainAxisSize: MainAxisSize.min, children: [...letters(word), const Text(' ')])])`, with the letter index continuing across words for the 24 ms stagger, so lines break only at spaces.
- **Check:** a widget test pumps a 40-grapheme title of several words at 200 px width and asserts that no word's letters sit on two lines, and pumps a text change to a longer title without a `RangeError`.

### PRODUCT-20 (low): the typing reveal starts letters and caret together

In §10.2's CSS and component:
- Nothing animates until the effect sets `data-typing="run"` on the heading, in the same tick that starts the interval: gate the grapheme, tail, `caret-blink` and `caret-out` animations on `.typed[data-typing="run"]` (for example `.typed[data-typing="run"] > [data-g] { animation: ty-land …; animation-delay: calc(var(--i) * 50ms); }`).
- Before that, graphemes and the tail are transparent and the caret hidden, with a fail-safe like §10.1's: `.typed:not([data-typing]):not(.is-done) > :is([data-g], .tail) { opacity: 0; animation: ty-failsafe 0s 1500ms forwards; } @keyframes ty-failsafe { to { opacity: 1; } }`, so text still appears if hydration never happens.
- The already-typed and reduced-motion branches keep setting `is-done` (all visible at once, no caret).
- The existing Playwright check (10th grapheme below 0.1 opacity at 200 ms) stays valid, and gains one assertion that the caret's `translate` is past grapheme 0 whenever grapheme 6 is visible.

### PRODUCT-21 (low): continue items for an unopened next chapter

§7.7 Continue stack and §8.8: when `page_count == 0` (the auto-advanced next chapter), the line reads "Up next · Ch 143", the ring shows its track only, the button reads "Start" instead of "Continue", and the spotlight's primary reads "Start Ch 143". No ratio is computed.

### PRODUCT-22 (low): cast gender, skip and failure copy

- §8.16.4 cast rows: a gender capsule (Male · Female · Unknown) from the row's `gender`. For the owner, tapping it opens a three-item menu that writes `POST /novels/cast {source_id, series_key, name, gender}` and shows the lock glyph; the orbit filter then follows the corrected gender. Non-owners see it read-only.
- §8.16.5 render toast skip wording, by reason: `already_rendered` "{n} already narrated", `chapter_not_cached` "{n} not on the server yet", `chapter_unreadable` "{n} couldn't be read", `already_queued` "{n} already waiting".
- Job failure lines by `error_code`: `lease_expired` "The narration PC stopped responding"; `audio_convert_failed` as written; any other code "Rendering failed ({code})".

### PRODUCT-23 (low): the skin row on the profile form

Add to §8.6 Content, after Mood, a **Skin** segmented control Glass · Cinematic (32 px mini previews), hidden until `flags.glass_available`, matching Cinematic's `Edition` row:
- It writes `reading_profiles.skin` through `PATCH /profiles/{id}` (for a new profile, right after `POST /profiles` succeeds).
- A new profile's control is preselected to the skin this device is showing, and that value is written explicitly, so a profile created in Glass does not boot as `NULL` → Cinematic (`stack-decision.md` §2.4).
- For another or a new profile the change applies the next time it is picked. For the active profile, Save saves the other fields first, then runs the §8.25.2 alert and restart; "Stay in Glass" keeps the other saved fields and leaves the skin unchanged.

### PRODUCT-25 (low): stale novel chapters, silent `db_busy`, backup caches

1. §8.15.7: when the chapter's `cache.stale` is true, a `warning` capsule "Saved copy · 2 h" (age from `cache.fetched_at`) sits in the top-left chrome group, as the catalogue's freshness capsule does.
2. §8.0.10 `db_busy` row: on background writes (progress keep-alive, outbox flushes, bookmark sync) the client retries after `Retry-After` with no UI; the capsule is for user-initiated actions only.
3. §8.25.10 Export: a switch "Include caches (larger, restores faster)", default off, which sends `GET /backup/export?include_cache=true`.

### PRODUCT-26 (low): enriched metadata and suggested tags on the series page

- §8.12 facts line gains "★ 8.4 · Manhwa" from `GET /series/enrichment?source&series` (`score`, `format`) when non-null, and a "Read officially" row of up to 3 site chips from `official`, each opening externally (the §8.0.10 "Couldn't open {site}" toast on failure).
- The Tags sheet gains a "Suggested" group from `GET /ai/tags?source&series` (up to 5): machine-sparkle chips, each with ✓ (accept: `POST /library/tags` when no tag of that name exists, then `POST /library/series-tags`) and × (dismiss: `POST /ai/feedback {signal: "tag_rejected", source_id, series_key, tag}`).
- States: enrichment null → the row is omitted; AI unavailable (`available: false`) → the Suggested group is omitted.

### PRODUCT-27 (low): tag field names and the tag count

- §15.5 and §8.0.3: the row field is `tags` (`[{id, name, color}]`, Cinematic's); `tag_ids=` is the `GET /library/series` query parameter (any-of).
- §8.17 Manage tags: rename sends `PATCH /library/tags/{id} {name}` (Cinematic's, reused).
- The per-row "12 series": add `series_count` to `GET /library/tags` rows in §15.5 as a Glass addition (a server-side count, since the library list pages at 200 rows).

### PRODUCT-28 (low): recommend-sheet states and genre links

1. §9.3.4 States: loading (3 orb skeletons while `GET /circle/members` answers); offline ("Recommending needs a connection", orbs and Send disabled; the drag-to-orb gesture shows no orbs).
2. §8.11: draw the genre chip only when `GET /sources/{id}/genres` returned a non-empty list.
3. §8.12 (and §8.13's genre tags): a genre links to the catalogue with `?genre={id}` only when a `label` in that source's genre list matches the genre case-insensitively; otherwise it renders as a plain tag, not a link.

---

## Refuted

- **PRODUCT-24** (avatar keys): the 12 Glass preset names are the existing labels verbatim in both clients (`violet` Violet Spark … `lunar` Lunar Moon, `star` Starlight, `reader` Bookworm), so the key for each Glass preset is unambiguous, and the shared `resolveAvatar` / Flutter preset lookup already falls back to the default preset for an unknown key. Nothing is missing.
- **PRODUCT-25 item 3** (batch `rejected` rows): the shared mobile outbox already collects `rejected` indexes (`progress_outbox_provider.dart:259`); this is data-layer behaviour, not skin design, and the "Synced N reads" toast is marked optional in capabilities §13.
- **PRODUCT-28 item 2** (More like this offline): §9.1.5 already gives every AI surface, More like this included, the offline line ("You're offline. AI picks come back when you reconnect.").

## Noted outside this lens (not judged)

- §9.4.2 pins `flutter_soloud` 5.1.4 and §9.2.4 `share_plus` 13.3.0, while `cinematic/DESIGN.md` §15.11 records that 5.x needs `meta ^1.19.0` (Flutter 3.44.6 pins 1.18.0) and 13.x needs `win32 ^6`. Worth a check by the stack lens.
