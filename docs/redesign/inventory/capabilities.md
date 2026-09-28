# ManhwaManiacs backend: capability inventory for the redesign

Source of truth read on 2026-09-29 (read-only):
`/srv/manhwamaniacs/dev/ManhwaManiacs/backend` (`api/router.py`, `main.py`, `routes/*.py`,
`services/*.py`, `core/*.py`, `connectors/registry.py`), plus `docs/ROADMAP.md`,
`docs/SOURCES.md`, `docs/OFFLINE_READING.md`, `docs/AUTH.md` and every file in
`docs/superpowers/specs/`. `docs/CONNECTOR_STATUS.md` does not exist any more:
`docs/CLAUDE_HANDOFF.md` §6 says it was deleted as untrustworthy. Its job is done
here by the live registry dump in §17.

Every endpoint below is something a redesigned screen can be built on. For each one
the file lists the inputs, the output shape (field names as the server sends them)
and the UI it implies. Section 26 lists roadmap items that have no endpoint yet but
need room in the design.

## 0. Counts at a glance

| What | Count |
|---|---|
| Route modules mounted | 13 (12 on `api_router`, plus `/novels` behind a flag) |
| Endpoints a client can call | **111** (64 GET, 47 POST/PUT/PATCH/DELETE) |
| Internal render-worker endpoints (`/novels/render/*`, token auth, no UI) | 5 |
| Capability groups (the `screen_names` list below) | 27 (26 built + 1 group of not-yet-built features) |
| Registered connectors (novels flag on) | 90, of which 89 browsable, 56 are 18+, 8 are novel sources, 86 have an icon, 22 expose genre filters |
| Profiles per account | max 5 |
| Follows per profile | max 1000 (`MM_MAX_FOLLOWS_PER_PROFILE`) |
| Pinned sources per profile | max 50 |
| Named TTS voices in the production pack | 31 (13 male, 18 female), read from disk on the VPS by `GET /novels/voices`; a checkout without the pack returns an empty list |

Capability groups, in report order: Auth and onboarding; Sessions and device security;
Account administration; Profiles; App settings and 18+ gate; Library; Home strips (continue
reading, recently updated); Recommendations and AI suggestions; Reading statistics and streaks;
Collections; Tags; Manga reader and progress; Reading history; Bookmarks; Sources directory,
health and pins; Source browse (popular, latest, genres); Series detail and chapter list; Image
proxy (covers and pages); Federated search; Novel text reader; Novel TTS (audio, voices, cast,
narration jobs); OCR dialogue search; Updates and notifications; Backup and restore; App
distribution, what's new and system status; Offline downloads (client-side); Not built yet but
designable.

Endpoints per module: auth 12, profiles 4, settings 2, system 3, app distribution 6,
library 26, reader 10, sources 14, ocr 4, updates 11, backup 4, novels 15
(+ novel_render 5 internal).

## 1. Cross-cutting contract every screen inherits

These are not screens, but every component the redesign draws has to deal with them.

- **Auth transport.** Web gets an httpOnly cookie `mm_session`; mobile reads `token` from
  the login/register body and sends `Authorization: Bearer <token>`. Session TTL 7 days,
  "remember me" 90 days (`services/auth_service.py`: `SESSION_TTL`, `REMEMBER_ME_TTL`).
  Every route except the public allowlist returns `401 not_authenticated` without a session.
  Public allowlist: `GET /`, `GET /health`, `GET /auth/bootstrap-status`, `POST /auth/login`,
  `POST /auth/register`, anything under `/app/*`, and CORS `OPTIONS`.
- **Active profile.** Clients send `X-Profile-Id: <id>` on every request. Reads resolve it
  leniently (missing or foreign id means the unscoped bucket, 18+ closed). Writes to
  profile-owned data require it: `400 profile_required` when absent, `404 profile_not_found`
  when it is not yours. So the profile picker is not optional chrome. It is the gate in front
  of the whole app for any account that has at least one profile.
- **Error envelope.** Every expected failure is `{code, message, details}` with an HTTP status.
  Codes a client should design copy for: `invalid_credentials`, `weak_password`,
  `username_taken`, `invalid_username`, `registration_disabled`, `invite_code_required`,
  `invite_code_invalid`, `bootstrap_window_expired`, `bootstrap_already_claimed`,
  `account_disabled`, `cannot_manage_self`, `forbidden`, `profile_required`,
  `profile_not_found`, `profile_limit_reached`, `invalid_profile_name`, `invalid_mood`,
  `follow_limit_reached`, `series_not_found`, `source_not_found`, `source_not_browsable`,
  `invalid_reading_status`, `bookmark_deleted` (409), `batch_too_large`, `db_busy` (503 + `Retry-After`),
  `check_already_running`, `narration_unavailable`, `audio_preparing`, `audio_convert_failed`,
  `suggest_shelf_empty`, `ai_no_matches`, `rate_limited` (429 + `Retry-After`), `not_found`.
- **Pagination.** Paged payloads carry `items, total, page, per_page, page_size, has_next,
  has_more, total_pages` (aliases are filled in by `utils/api_pagination.py`). Bare-list
  endpoints put the count in the `X-Total-Count` response header.
- **Rate limits** (slowapi, per client IP, `429` with `Retry-After`): login 10/min;
  register 5/min + 30/h; change-password 5/min + 20/h; bootstrap-status 30/min + 240/h;
  sources bucket 60/min (browse, search, series, chapters, covers, page images, novels);
  bulk bucket 6/min (`/reader/chapters/manifest`, `/novels/chapters`); OCR upload
  10/min + 200/h; AI suggest 3/min + 30/h; backup import 5/min. Design implication: the
  page-image proxy shares the 60/min sources bucket, so a reader must pace prefetch, and every
  surface needs a calm "slow down, retrying in N s" state.
- **The 18+ gate is absence, never a lock.** A mature source, series, notification, history row,
  bookmark or statistic simply is not returned when the active profile's
  `mature_content_enabled` is off. Counts (unread badge, source-health totals, statistics
  totals) are computed after the gate. The redesign must never draw a "hidden: 18+" placeholder,
  a blurred tile, or a count that implies hidden rows. Where content is shown, the UI should
  badge it: sources carry `mature: bool`, followed series carry `content_rating`, a resolved
  `rating` (`mature` / `safe` / `unknown`) and a user `mature_override` (null / true / false).
- **Identity.** A series is `(source_id, series_key)`, a chapter is
  `(source_id, series_key, chapter_key)`. Keys are opaque strings that may contain `/` and
  `%`; path segments must be percent-encoded per segment. `chapter_number` (float or null) is
  the only thing that means the same across sources, so it is what the UI prints. Decimal
  chapters and null numbers (prologues) are real and must render.
  `series_identity` is what to compare to decide "is the series on this page followed?"
  (Asura rotates slugs, so the key alone lies).
- **Cover and page URLs are relative.** `cover_url` on browse results is
  `/sources/{id}/series/{key}/cover`; page `url` is `/sources/{id}/pages/{key}/image`.
  Clients prefix the API base and append `?w=` (see §16).
- **Staleness.** Browse pages and novel chapters carry a `cache` block
  `{status: "fresh"|"live"|"stale", stale: bool, fetched_at}`. A stale grid is served when the
  upstream site is down, so the design needs a quiet "offline copy from <time>" badge rather
  than an error page.

---

## 2. Auth and onboarding

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /auth/bootstrap-status` (public) | none | `{needs_bootstrap, bootstrap_open, registration_enabled, invite_code_required, registration_open, novels_enabled}` | The very first screen after splash decides between three forms: **Claim this instance** (create the owner, only while `bootstrap_open`), **Sign up** (only when `registration_open`; show an invite-code field only when `invite_code_required`), **Sign in**. `novels_enabled` is also read here and decides whether any novel UI exists at all (tab, source filter, reader, TTS). |
| `POST /auth/register` (public) | `{username, password, email?, display_name?, invite_code?, remember}` | `201 {user: UserOut, token}` | Sign-up form with "remember me". The first account becomes admin/owner. Registration is open on this deployment by owner choice. |
| `POST /auth/login` (public) | `{username, password, remember}` | `{user: UserOut, token}` | Sign-in form. Errors: `invalid_credentials`, `account_disabled` (403), `rate_limited`. |
| `POST /auth/logout` | none | 204 | Sign out (this device). |
| `GET /auth/me` | none | `UserOut {id, username, email, display_name, is_admin, created_at, last_login_at}` | Account header in Settings, admin-only sections toggled by `is_admin`. |
| `POST /auth/change-password` | `{current_password, new_password}` | 204; revokes every other session | Change-password sheet with a "signed out everywhere else" confirmation. |

## 3. Sessions and device security

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /auth/sessions` | none | `[{id, created_at, last_used_at, expires_at, user_agent, ip_address, current}]` | "Where you're signed in" list: device (parse `user_agent`), last active, expiry, a "This device" badge for `current`. |
| `DELETE /auth/sessions/{id}` | path id | 204 | Swipe or button to revoke one device. |
| `POST /auth/logout-all` | none | 204 | "Sign out everywhere" destructive action. |

## 4. Account administration (owner only)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /auth/users` | none | `[{id, username, is_admin, is_active, created_at, last_login_at, session_count}]` | **Members** screen: every account, active/disabled state, last sign-in, signed-in device count. |
| `PATCH /auth/users/{id}` | `{is_active}` | `AccountOut` | Enable/disable toggle. Disabling kills that account's sessions immediately. The owner's own row refuses (`cannot_manage_self`). |
| `DELETE /auth/users/{id}` | path id | 204 | Irreversible delete of the account and everything it owns (profiles, library, progress, bookmarks, collections, tags, notifications, stats, sessions). Needs a heavy confirmation. |

## 5. Profiles (Netflix-style "who's reading")

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /profiles` | none | `[{id, name, avatar_key, mood, sort_order, mature_content_enabled, created_at}]` | Profile picker after sign-in and a switcher in the shell. |
| `POST /profiles` | `{name (1-255), avatar_key? (≤64), mood?, sort_order?, mature_content_enabled?}` | profile (201) | "Add profile" editor. Limit 5, `profile_limit_reached` after that. |
| `PATCH /profiles/{id}` | any subset of the create fields | profile | Edit profile: name, avatar, mood, 18+ toggle, reorder. |
| `DELETE /profiles/{id}` | path id | 204 | Delete profile (its follows, progress, bookmarks, collections go with it). |

Design hooks:
- `avatar_key` is a free string (≤64 chars). The avatar catalog lives in the clients (today
  12 keys such as `violet`, `cyan`, `rose`, `amber`, `emerald`, `ember`, `blade`, `phantom`,
  `arcane`), so the redesign can replace the whole avatar set for each skin without a backend
  change. Old keys must still map to something.
- `mood` is one of `default, romantic, action, comedy, horror, slice_of_life, fantasy`. The
  clients use it for an ambient tint on the shell and reader margins. It is a per-profile
  atmosphere signal, not a free accent colour. The decisions file forbids an accent picker, so
  each skin needs its own interpretation of these 7 moods (Cinematic: a colour-graded backdrop
  bloom; Glass: a tinted refraction on the material).
- `mature_content_enabled` is the per-profile 18+ switch (see §6). It is the only thing that
  opens the gate.

## 6. App settings and the 18+ gate

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /settings` | none | `{version, project_name, mature_content_enabled, updates: {enabled, check_interval_minutes, notify_enabled, check_on_startup, last_run_at}, source_cache_ttl_minutes, capabilities: {online_sources, client_downloads, ocr, collections, bookmarks, continue_reading, reading_progress}}` | Settings root. `capabilities` flags let a screen hide a section the server does not offer. |
| `PUT /settings` | any of `updates_enabled, updates_check_interval_minutes (≥5), updates_notify_enabled, updates_check_on_startup, source_cache_ttl_minutes (≥5), mature_content_enabled` | same as GET | Profile users may only flip `mature_content_enabled` for their own active profile. The update-scheduler fields and cache TTL are instance-wide and admin-only (403 otherwise). |

Nothing on the server stores UI preferences. The skin choice (Cinematic / Glass), reader
preferences (mode, fit, direction, zoom, page gap, cinema auto-hide), haptics and sound toggles
are all client-local today (per profile via scoped storage on web, per install or per profile
on mobile). If the skin must follow a profile across devices, a backend field is needed (§26).

## 7. Library (the profile's followed series)

A series is in the library if and only if a `followed_series` row exists for the active profile.

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/series` | `page, per_page (≤200, default 40), sort (title, -title, sort_order, updated_at/recently_updated, created_at/recently_added), search, reading_status, is_favorite` | paged `items: FollowedSeries[]` | The library grid/shelf with filters (status chips, favourites), sort menu, search-in-library, manual reordering. |
| `GET /library/series/{followed_id}` | path id | FollowedSeries + `known_chapters`, `description`, `author`, `genres`, `chapters`, `progress: {chapter_key: {last_page, is_completed}}` | Series detail from the library side, with per-chapter read state. |
| `PATCH /library/series/{followed_id}` | any of `is_favorite, reading_status, notify, mature_override, sort_order` | FollowedSeries with `read_state` | Favourite heart, status picker (`unread, reading, completed, on_hold, dropped, plan_to_read`), per-series "notify me" bell, "treat as 18+ / not 18+" override, drag to reorder. |
| `POST /library/follow` | `{source_id, series_key}` | FollowedSeries (with `known_chapters`) | The follow/"add to library" button on every series surface. `follow_limit_reached` at 1000. |
| `DELETE /library/follow/{followed_id}` | path id | 204 | Unfollow. Reading progress survives, so re-following restores position. |
| `GET /library/search` | `q, page, per_page` | paged FollowedSeries | Search box scoped to "My library". |

`FollowedSeries` fields: `id, source_id, series_key, series_identity, title, cover_url,
is_favorite, reading_status, notify, sort_order, content_rating, rating, mature_override,
chapter_count, last_checked_at, created_at, updated_at`, plus `known_chapters:
[{key, number, title, published_at}]` on detail/follow/patch, and on list rows
`read_state: {started, chapter_key, chapter_number, position, total, latest_number, new_count}`.

`read_state` is the richest card signal in the API: "Ch 41 of 120", "3 new", "Not started",
"Caught up" (when `new_count == 0`), a progress ring from `position/total`. Every library card
in both skins should be designed around it.

## 8. Home strips

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/continue-reading` | `limit (≤50, default 10)` | `[{source_id, series_key, chapter_key, chapter_number, last_page, page_count, last_read_at, title, cover_url}]` | The **Continue** hero and rail. One item per series; it resolves to the furthest chapter, and when that chapter is finished it moves forward to the next one (`last_page: 1, page_count: 0`). Tapping opens the reader at that exact page. |
| `GET /library/recently-updated` | `limit (≤50)` | FollowedSeries[] (no chapter arrays) | "New episodes" rail, ordered by the last update check. |

## 9. Recommendations and AI suggestions (partly built)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/recommendations` | `limit` | `[{genre, weight}]` | Genre affinity. Today only a histogram, so it suits a "Your genres" chip row that deep-links into browse, or a genre radar on the stats screen. |
| `GET /library/world/recommendations` | `seeds (1-8, default 5), per_seed (3-15, default 10)` | `{for_you: WorldItem[], sections: [{because: {title, source_id, series_key}, items: WorldItem[]}], unavailable_reason}` | **"For you" rail + "Because you read X" rails.** Candidates come from AniList, chapter counts from MangaUpdates. |
| `GET /library/suggest/availability` | none | `{available, reason: "ok"\|"not_configured"\|"budget_exhausted", remaining_today, daily_ceiling}` | Whether to show the AI prompt box at all, plus a "N asks left today" meter. The ceiling is 60/day for the owner and 10/day for other accounts. |
| `POST /library/suggest` | `{prompt (3-600 chars), limit (1-8, default 6)}` | `{items: [{kind:"source", source, series_id, title, cover_url, author, chapter_count, extra, why}], dropped, model, remaining_today}` | **"Describe what you feel like reading"** box. Every item opens (it comes from the server's cached catalog); `why` is a one-line reason (≤160 chars) to show on the card. |
| `POST /library/world/suggest` | `{prompt (3-600), limit (1-15, default 12)}` | `{items: WorldItem[], dropped, model, remaining_today}` | Same box answered from the whole medium, AniList-verified. |

`WorldItem`: `anilist_id, title, alt_titles[≤4], format (Manhwa|Manhua|Manga|Novel|One-shot|Comic),
country, status (Ongoing|Completed|Hiatus|Cancelled|Upcoming), chapters, rating (0-10, one
decimal), genres[≤5], cover_url (AniList CDN, absolute), is_adult, platforms[{site,url}] (≤3
official links), anilist_url, available[{source_id, source_name, series_key}], why`.

The key design distinction is **`available`**. A non-empty `available` is a card that opens a
series on one of the reader's own sources, with a source picker if there are several. An empty
one is an information card (cover, rating, status, chapter count, official platforms) whose
action is "search my sources for this". Both skins need two visibly different card states for
this. States to design: loading (a cold page makes dozens of public-API calls), `unavailable_reason`
(worldwide catalog unreachable, showing cache), AI not configured, daily budget exhausted,
`ai_no_matches`, `rate_limited`.

## 10. Reading statistics and streaks

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/statistics` | `days (1-365, default 30)`, `tz_offset_minutes (-720..840)` | see below | The stats screen, streak flame, and most of a Wrapped-style recap. |

Output: `followed_total, favorites, by_reading_status {status: n}, chapters_completed`, plus
`range {days, since, until, timezone_offset_minutes, session_cap_seconds}`,
`totals {sessions, pages_read, chapters_read, series_read, seconds_read, first_session_at, last_session_at}`,
`window {sessions, pages_read, chapters_read, series_read, seconds_read}` (for the chosen days),
`streak {current_days, longest_days, last_active_date}`,
`daily [{date, sessions, pages_read, chapters_read, series_read, seconds_read}]` (one per day),
`by_hour [{hour 0-23, sessions, pages_read, seconds_read}]` (24 rows),
`by_source [{source_id, name, sessions, pages_read, chapters_read, series_read, seconds_read}]` (top sources),
`by_series [{source_id, series_key, title, cover_url, last_read_at, sessions, pages_read, chapters_read, seconds_read}]`,
`recent_sessions [{source_id, series_key, chapter_key, chapter_number, title, day, pages_read, seconds_read, sessions, started_at, ended_at}]`.

That covers: a contribution-style daily heatmap, time-read totals, an hour-of-day clock chart
("you read at night"), top sources, top series with covers, a streak flame with current and
longest, and a recent-activity list. A yearly recap is `days=365`. Genre radar data comes from
`/library/recommendations`. Everything is per profile and 18+-gated.

## 11. Collections (manual shelves)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/collections` | none | `[{id, name, description, sort_order, series_count}]` | Collections index (shelves as big cards). |
| `POST /library/collections` | `{name, description?}` | collection | "New collection" sheet. |
| `GET /library/collections/{id}` | path id | collection + `series: [{source_id, series_key, sort_order}]` | Collection detail. Members carry no title or cover, so the client joins them to the library rows. |
| `PATCH /library/collections/{id}` | `name?, description?, sort_order?` | collection | Rename, describe, reorder shelves. |
| `DELETE /library/collections/{id}` | path id | 204 | Delete shelf. |
| `POST /library/collections/{id}/series` | `{source_id, series_key}` | membership | "Add to collection" from any series surface (multi-select sheet). |
| `DELETE /library/collections/{id}/series` | same body | 204 | Remove from shelf. |

Design note: the collection list has no preview covers, so a poster-mosaic shelf card needs one
detail call per collection plus a library join, or a small backend addition (first 4 member covers
on the list payload). Worth deciding before the redesign commits to mosaic shelves.

## 12. Tags

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /library/tags` | `category?` | `[{id, name, category, color}]` | Tag manager and filter chips. `color` is a client-chosen string ≤16 chars. |
| `POST /library/tags` | `{name, category="custom", color?}` | tag | Create tag. |
| `DELETE /library/tags/{id}` | path id | 204 | Delete tag. |
| `POST /library/series-tags` | `{source_id, series_key, tag_id}` | `{source_id, series_key, tag_id}` | Tag a series. |
| `DELETE /library/series-tags` | same body | 204 | Untag. |

Note: there is no "list series by tag" endpoint and no tags on the `FollowedSeries` payload, so
a tag filter needs either a backend addition or client-side joins. Worth deciding before the
redesign puts tags on cards.

## 13. Manga reader: manifest and progress

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /reader/chapter/manifest` | `source, series, chapter` | `{source_id, series_key, chapter_key, chapter_number, page_count, pages: [{number, url, width, height}], prev, next}` | The reader's plan. `width/height` (may be null) let the reader reserve the exact strip height before images land, so there is no layout jump. `prev/next` drive the next-chapter card and the seamless boundary. |
| `POST /reader/chapters/manifest` | `{source_id, series_key, chapter_keys[] (≤20)}` | `{source_id, series_key, max_chapters, requested, ok_count, failed_count, items: [{chapter_key, status: "ok"\|"error", manifest, error}]}` | **Read-all** continuous mode (a whole series as one scroll, windowed 20 at a time) and **bulk download** ("next 10", "all unread"). Partial failure per chapter is normal and needs a per-chapter retry affordance. |
| `GET /sources/{id}/series/{series}/chapters/{chapter}/reader` | path keys | `{mode:"remote", source_id, series_id, id, title, number, page_count, pages: [{id, chapter_id, number, width, height, image_url}], previous_chapter_id, next_chapter_id, series_title}` | Older online-reader payload. Same data as the manifest plus titles. |
| `POST /reader/progress` | `{source_id, series_key, chapter_key, chapter_number?, last_page ≥1, page_count, scroll_offset_px, is_completed, last_read_at?, time_spent_seconds}` | progress row + `advanced` | Silent keep-alive from the reader. The merge is furthest-wins and never rewinds. `advanced: false` means another device is further ahead, which is the hook for a "you're further on another device, jump there?" toast. `503 db_busy` with `Retry-After` should back off quietly. |
| `POST /reader/progress/batch` | array (≤200) of the above | `{saved, advanced, items, rejected: [{index, errors}]}` | Offline outbox flush. Invisible, but a "Synced N reads" confirmation is possible. |
| `GET /reader/progress/series` | `source, series` | `[progress rows]` | Per-chapter read state on a series page (dim finished chapters, "14/27" on in-progress ones, "Continue Ch 41 p.12" CTA). |

Progress row: `id, source_id, series_key, chapter_key, chapter_number, last_page, page_count,
scroll_offset_px, is_completed, started_at, last_read_at, completed_at, time_spent_seconds`.

Novel progress uses the same rows: `last_page/page_count` are paragraph-bucket indices.

## 14. Reading history

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /reader/history` | `limit (≤200, default 50), offset, collapse=none\|series` | progress rows + `series_title, cover_url` | **History** screen. `collapse=series` gives one row per book ("what have I been reading"); `none` gives a chapter-by-chapter timeline. Group by day client-side. |

## 15. Bookmarks (exact position, both media, offline-synced)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `POST /reader/bookmark` | `{client_id?, source_id, series_key, chapter_key, chapter_number?, media_type: "manga"\|"novel", anchor_index ≥1, anchor_fraction 0-1, anchor_total, note?}` | bookmark (with server-minted `client_id`) | One-tap bookmark in both readers, no dialog. The note is optional and added afterwards. `409 bookmark_deleted` if that id was already deleted. |
| `POST /reader/bookmarks/batch` | array (≤200) of `{op: upsert\|delete, client_id, ..., updated_at?}` | per item `{client_id, op, status: created\|updated\|tombstoned\|already_deleted\|stale\|rejected_deleted, bookmark}` | Offline outbox flush. |
| `GET /reader/bookmarks` | `source?, series?, since?, include_deleted?, limit (≤500), offset` | `[{id, client_id, source_id, series_key, series_title, chapter_key, chapter_number, media_type, anchor_index, anchor_fraction, anchor_total, page, position_fraction, snippet, anchor_stale, note, deleted, created_at, updated_at, deleted_at}]` | **Bookmarks** screen: series, "62% of chapter 14" (`position_fraction`), and for novels a text `snippet` at that exact point. `anchor_stale: true` means the text changed, so show a quiet "position approximate" note. Filter by series. |
| `DELETE /reader/bookmarks/{id}` | path id | 204 | Delete (a tombstone, so it syncs across devices). |

## 16. Sources: directory, health, pins, browse, series, images

### 16.1 Directory, health and pins

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /sources` | none | `[{id, source_id, name, description, browsable, supports_import, mature, icon_url, content_kind: "manga"\|"novel", language, health}]` | The **Sources** directory: icon, name, 18+ badge, manga vs novel split, language, health dot. |
| `GET /sources/health` | none | the same rows ordered worst-first | "What's broken" status view (dead, then failing, then unknown, then ok). |
| `GET /system/source-health` | none | `{total, ok, failing, dead, unknown, demoted}` | A one-line status banner or ring ("84 of 89 sources healthy"). Gated counts. |
| `GET /sources/pins` | none | `[{source_id, sort_order, name, icon_url, mature, available}]` | Pinned sources at the top of Sources and as the first search tier. |
| `PUT /sources/pins` | `{source_ids: [...]}` (ordered, ≤50) | the new list | Pin/unpin and drag-reorder. |

`health`: `{status: "ok"|"failing"|"dead"|"unknown", consecutive_failures, demoted, last_ok_at,
last_error_at, last_error, last_checked_at}`. Four status colours plus a "demoted" (skipped by
search) marker, in both skins.

### 16.2 Browse (popular, latest, genres)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /sources/{id}/browse-modes` | path id | `[{id, label}]` | Segmented control or tabs on a source page. Observed across 89 sources: `popular` "Popular" (64), `rating` "Top Rated" (52), `default` "Latest" (47), `latest` "New"/"Latest"/"Latest Updates" (68), `completed` (7), `new`/"Newly Added" (9), `top_rated` (5), `english` "English Only" (4), `alphabetical`/`title` "A-Z" (6), `updated` "Recently Updated" (3), `trending`/"Trending This Week" (5), `ongoing` (3), "Most Downloaded" (2). Labels are server-provided, so the tab bar must accept arbitrary strings. |
| `GET /sources/{id}/genres` | path id | `[{id, label}]` (22 sources have any) | Genre filter sheet, only when non-empty. |
| `GET /sources/{id}/series` | `page, query?, sort? (mode id), genre?, refresh?` | paged `items: SourceSeries[]` + `cache` block | The browse grid with infinite scroll, per-source search, pull-to-refresh (`refresh=true`), and a stale badge from `cache`. |

`SourceSeries`: `id, source_id, series_identity, title, chapter_count, description, author,
artist, status, genres[], content_rating, latest_chapter, cover_url`.

### 16.3 Series detail and chapters

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /sources/{id}/series/{series_key}` | path keys | `SourceSeries` | The **series page**: cover backdrop, title, author/artist, status, genres, synopsis, rating badge, follow button (compare `series_identity` with the library), Read / Continue / Read all CTAs. |
| `GET /sources/{id}/series/{series_key}/chapters` | path keys | `[{id, source_id, series_id, title, number, page_count, release_date}]` (+ `X-Total-Count`) | Chapter list with sort (newest/oldest), release dates, per-chapter read state (joined from `/reader/progress/series`), download buttons, multi-select. |
| `GET /sources/{id}/chapters/{chapter_key}/pages` | path keys | `[{id, chapter_id, number, width, height, image_url}]` | Raw page list, same data as the manifest. |

### 16.4 Image proxy

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /sources/{id}/series/{key}/cover` | `w?` snapped to **96, 160, 240, 360, 480, 720** px; `Accept` picks WebP or JPEG | image bytes; `ETag`, `Cache-Control: public, max-age=2592000` (30 days), `Vary: Accept`, `X-Cover-Width` when resized | Every poster. Design the poster sizes around these widths (at DPR 3, a 120 pt poster asks for `w=360`). Covers are 30-day cacheable, so hero backdrops can reuse them. A 720 px maximum means a full-bleed hero on a 1440 px desktop is upscaled, so blur, scale or vignette it by design rather than showing it sharp. |
| `GET /sources/{id}/pages/{page_key}/image` | `w?` snapped to **480, 720, 800, 1080, 1200, 1440, 1600** px | image bytes; `ETag`, `max-age=86400`, `X-Page-Width` only when actually resized | Reader pages. Webtoon strips are usually 720-800 px wide at source and pass through unresized. |

Upstream bytes are capped at 25 MB per image, and nothing is stored server-side for pages. The
reader needs a per-page failed state with a tap-to-retry, since any single upstream image can
fail.

## 17. Connectors (by name)

90 registered with the novels flag on; 89 are browsable (`local_filesystem` is registered but
not browsable, a leftover). The list drifts, so clients must render whatever `GET /sources`
returns and never hard-code it.

- **General manga/manhwa/manhua (25):** asurascans (AsuraScans), aurorascans (Aurora Scans),
  baozimh (BaoZiMH), demonicscans (DemonicScans), elftoon (Elf Toon), flamescans (Flame Scans),
  guazimanhua (GuaziManhua), fanfox (Manga Fox), mangabuddy (MangaBuddy), mangadex (MangaDex),
  mangafreak (MangaFreak), mangahub (MangaHub), mangakatana (MangaKatana), mangapill (MangaPill),
  mangaread (MangaRead), mangasushi (MangaSushi), mangatop (MangaTop), mangatown (MangaTown),
  manhuaplus (ManhuaPlus), novelcool (Novel Cool, a manga source despite the name),
  rawinu (RawINU), rawkuma (Rawkuma), s2manga (S2Manga), tapas (Tapas), webtoons (WEBTOON).
  (firstkissmanga has code in the tree but is on the exclusion list and not registered.)
- **Novel sources (8, content_kind "novel", English):** archiveorg (Internet Archive),
  freewebnovel (FreeWebNovel), gutenberg (Project Gutenberg), novelarchive (Novel Archive, the
  flagship), novelbuddy (NovelBuddy), novelfull (NovelFull), royalroad (Royal Road),
  standardebooks (Standard Ebooks).
- **18+ (56):** 18porncomic, 3hentai, 8muses, akuma, allporncomic, allporncomicsco, apcomics,
  asmhentai, beehentai, cocomic, comicasura, comicland, comicsvalley, comicsvalleycom,
  cucumbermanga, doujindistrict, doujinhq, doujins, ehentai, freeadultcomix, galaxymanga,
  gedecomix, hentai20, hentaiera, hentaifox, hentaihand, hentaisyaoi, hentaixcomic,
  hentaixdickgirl, hentaixyuri, kokomangas, manga18free, manga18x, mangadistrict,
  mangaforfree, mangafree, mangahe, mangamaniacs, mangaowl, manhuahot, manhuanext, manhwa18,
  manhwa18net, manhwaclub, manhwacomics, manhwaden, manhwanex, manhwareads, manhwatop,
  milftoon, nhentai, omegascans, orchisasia, paritehaber, petrotechsociety, yaoihub.

Design implications: 86 of 89 have an `icon_url` (a favicon-grade image), so source chips need a
monogram fallback. On a gated profile the directory shrinks from 89 to about 33 entries, and
the layout must look complete at both sizes. Novel sources exist only when `novels_enabled`.

## 18. Federated search

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /sources/search` | `q, page, per_page (≤200, default 40), tier? (1 or 2)` | `{items (flat, interleaved), groups: [{source, source_name, icon_url, status: ok\|empty\|error, error, total, has_more, items, health}], sources_queried, sources_failed, sources_demoted, sources_deferred, tier, next_tier, page, has_more}` | **Global search** with results grouped per source. It is two-phase: call `tier=1` (pinned and followed sources, answers in under 2 s), render it, then call `tier=2` when `next_tier == 2` (everything else, up to about 12 s). The design needs a "searching N more sources…" progress state, per-source error rows, and a way to jump between source groups. Hit items: `{kind: "source", source, series_id, title, cover_url, author, chapter_count, extra}`. |
| `GET /library/search` | see §7 | | The "In your library" section at the top of global search. |
| `GET /ocr/search` | see §20 | | The "In dialogue" section: search for what a character said. |

A unified search screen can therefore have three result families: library, sources, dialogue.

## 19. Novels, text reader and TTS (behind `novels_enabled`)

All `/novels/*` routes 404 unless `MM_NOVELS_ENABLED` is on. Clients read the flag from
`GET /auth/bootstrap-status`. Browse, search and series detail for novels reuse `/sources/*`
(filter by `content_kind == "novel"`).

### 19.1 Text

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /novels/chapter` | `source, series, chapter` | `{source_id, series_key, chapter_key, title, chapter_number, paragraphs: [str], prev, next, word_count, cache}` | The **novel reader** (Apple Books / Kindle style): sanitized plain paragraphs, no HTML. `word_count` gives "12 min left". `prev/next` feed seamless continuation. |
| `POST /novels/chapters` | `{source_id, series_key, chapter_keys[] (≤20)}` | `{max_chapters, requested, ok_count, failed_count, items: [{chapter_key, status, chapter, error}]}` | Whole-novel download (paged by 20) and prefetch. |

### 19.2 Dialogue attribution (who speaks each line)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /novels/attribution` | `source, series, chapter` | `{attributed, text_fingerprint, narrator, spans: [{p, s, e, head, speaker}], cast: [{name, gender, voice_id}], narrator_voice_id}` | Tint each quoted line by speaker (`p` = paragraph index, `s`/`e` = character offsets). `cast` is ordered by line count; the clients assign colours in that order so the two busiest speakers get the most distinct colours. That means each skin needs an ordered speaker palette of around 8 or more colours that stay distinct on AMOLED black. Tint only when `text_fingerprint` matches the text on screen. `attributed: false` is the normal state for most chapters. |

### 19.3 Audio (TTS narration)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /novels/audio` | `source, series, chapter` | `{available, bytes, total_ms, highlight_safe, segments: [{i, start_ms, end_ms, p, s, e, voice, speaker, speech}]}` | **Listen mode**: play button, scrubber, and sentence-level follow-along highlight (segments carry measured timings and text offsets). Follow the text only when `highlight_safe`. Each segment names its `speaker` and `voice`, so a "now speaking" chip is possible. |
| `GET /novels/audio/series` | `source, series` | `{chapters: [{chapter_key, bytes, has_timing}], narratable: [chapter_key], can_render}` | Headphone badges on the chapter list (which chapters have audio), and whether to offer "Narrate" at all (`can_render`). |
| `GET /novels/audio/file` | `source, series, chapter, format=ogg\|m4a` | audio file, Range/206 supported | The player source. iOS must use `m4a`. The first m4a request can return `503 audio_preparing`, so the player needs a "preparing audio" state and a retry. |
| `POST /novels/audio/render` (owner) | `{source_id, series_key, chapter_keys[] (≤200), priority 0-9, force}` | `{queued: [...], skipped: [...]}` | "Narrate these chapters" (multi-select or whole book). Partial results are normal. `503 narration_unavailable` when no render box is configured. |
| `GET /novels/audio/jobs` | `source, series` | `{jobs: [{job_id, chapter_key, chapter_number, status, progress 0-1, attempts, error_code, error_detail}]}` | Per-book narration queue with progress bars. |
| `GET /novels/audio/jobs/active` | none | same, across all books | A global "Narrating 3 chapters…" indicator (mini-player area or activity centre). |
| `DELETE /novels/audio/jobs/{job_id}` (owner) | path id | 204 | Cancel. It stops "shortly", so the copy should say so. |

Job `status`: `queued`, `planning`, `rendering` (active); `done`, `failed`, `cancelled` (terminal).

### 19.4 Voices and casting

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /novels/voices` | none | `{voices: [{voice_id, name, character, gender, pitch_hz, expressiveness, seconds, license, attribution, transcript}]}` | **Voice gallery** (31 named voices in production, 13 male and 18 female, named A to Z by pitch and served deepest first within each gender). Cards can show name, character, a pitch scale ("deeper ↔ brighter" from `pitch_hz`), an expressiveness meter, and license/credit. An empty list is valid: no pack installed. |
| `GET /novels/voices/sample` | `voice, format=ogg\|m4a` | audio clip (each voice introducing itself) | Tap to preview a voice, with a waveform or pulse while playing. |
| `POST /novels/narrator` (owner) | `{source_id, series_key, voice_id\|null}` | narrator setting | "Narrator voice for this book" picker. |
| `POST /novels/cast` (owner) | `{source_id, series_key, name, gender? (male\|female\|unknown), voice_id?}` | `{name, gender, voice_id, locked}` | **Cast sheet**: every character, gender, assigned voice, and a lock icon once corrected by hand. |
| `POST /novels/cast/alias` (owner) | `{source_id, series_key, alias, canonical}` | `{alias, resolves_to}` | "X is the same character as Y" merge action. It retroactively fixes every attributed chapter. |

## 20. OCR dialogue search (client runs OCR, server stores and searches)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `POST /ocr/chapter` | `{source_id, series_key, chapter_key, chapter_number?, language?, engine, pages: [{page, text, boxes?: [{text, x, y, width, height, left, top, right, bottom, confidence}]}]}` (≤500 pages, ≤2 M chars) | `{source_id, series_key, chapter_key, language, engine, word_count, updated_at}` | "Scan this chapter's dialogue" action on a downloaded chapter (mobile runs Apple Vision or ML Kit on-device, then uploads). Needs a per-page progress UI during the scan. |
| `GET /ocr/chapter` | `source, series, chapter` | the above + `page_texts: [{page, text, boxes}]` (404 when none) | In-reader "show dialogue" overlay: tap a page to see its recognised text, with boxes positioned over speech bubbles. |
| `GET /ocr/coverage` | `source, series` | `{chapters: [{chapter_key, word_count}]}` | "Searchable" badges on a series' chapter list and a coverage bar ("dialogue indexed for 34 of 120 chapters"). |
| `GET /ocr/search` | `q, limit (≤100), offset` | `{items: [{source_id, series_key, chapter_key, word_count, engine, snippet, highlighted_terms}], total, offset, limit, has_more}` | **Dialogue search** ("who said 'I'll surpass you'?"): snippet with highlighted terms, then open the reader at that chapter. Results carry no title or cover, so the client joins them to library or series data. |

OCR text is global (shared across accounts) but reads are gated by the 18+ rules.

## 21. Updates and notifications

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /updates/notifications` | `unread_only, limit (≤500)` | `[{id, followed_series_id, source_id, series_key, chapter_key, chapter_title, chapter_number, is_read, created_at}]` + `X-Total-Count` | **Updates inbox**: "New Ch 142 of X". Items carry no series title or cover, so group by `followed_series_id` and join to the library (one card per series with "3 new chapters"). Deep link into the reader. |
| `GET /updates/notifications/unread-count` | none | `{count}` | Badge on the Updates tab or bell. Gated. |
| `PATCH /updates/notifications/{id}/read` | path id | notification | Mark one read (swipe). |
| `POST /updates/notifications/read-all` | `{content_kind?: "manga"\|"novel"}` | `{updated: n}` | "Mark all read", scoped to the manga or novel tab. |
| `POST /updates/check` | `{followed_ids?: [int]}` | a run `{id, trigger, status, series_checked, new_chapters_found, error, started_at, finished_at}` or `{queued: true}`; `409 check_already_running` | "Check for new chapters now" (pull-to-refresh on Updates). |
| `POST /updates/followed/{id}/check` | path id | run | "Check this series" on a series page. |
| `GET /updates/settings` | none | `{enabled, check_interval_minutes, notify_enabled, check_on_startup, last_run_at}` | "Last checked 12 min ago" line. |
| `PUT /updates/settings` (admin) | same fields | settings | Scheduler settings in the admin area. |
| `GET /updates/sources` | none | `[{id, name}]` | Source filter on the Updates screen. |
| `GET /updates/runs` (admin) | `limit (≤100)` | runs | Update-run log in the admin area. |
| `GET /updates/runs/{id}` (admin) | path id | run | Run detail. |

Per-series notifications are switched on the library row (`notify`). There are no push
notifications: updates are pulled when the app opens, so the badge is the main signal.

## 22. Backup and restore (admin)

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /backup/status` | none | `{restore_pending, nightly: {ok, finished_at, phase, bytes} \| null}` | A backup health card: last nightly result and size. `null` means unknown, which is never "healthy". A "restore pending, restart to apply" banner. |
| `GET /backup/export` (admin) | `include_cache?` | SQLite snapshot download | "Download backup" (optionally a warm clone with caches). |
| `POST /backup/import` (admin) | multipart `file` | `{status: "staged", message}` | Upload-and-stage restore flow with a strong warning; it applies on the next server start, and the previous DB is kept. |
| `DELETE /backup/pending` (admin) | none | status | "Cancel staged restore". |

## 23. App distribution, what's new, system status

| Endpoint | Inputs | Output | UI it implies |
|---|---|---|---|
| `GET /app/version` (public) | none | `{version, build, apk}` | In-app "update available" prompt on Android (compare with the running build). |
| `GET /app/changelog` (public) | none | `{entries: [{version, build, date, highlights: [str]}]}` | **What's new** sheet after an update, and a release-notes page. Current top entry: 3.4.3 build 56. |
| `GET /app/download` (public) | none | APK | Android install and update. |
| `GET /app/source.json`, `GET /app/ios/download` (public) | none | SideStore manifest, IPA | iOS sideload path. Not an in-app UI, but the install landing page at `/` is a branded surface the redesign should cover too (new wordmark, screenshots via `GET /app/media/{name}`). |
| `GET /` (public) | none | HTML install landing page | Public front door: install instructions, screenshots, changelog. |
| `GET /health` (public) | none | `{status: "online", name, version}` | Connection check on the mobile "server URL" escape-hatch screen and the offline or unreachable state. |

## 24. Offline downloads (client-side capability built on the manifest and image proxy)

No server endpoint stores chapter bytes, but this is a first-class product surface. The phone
keeps a sqflite index plus a content-addressed blob store; the web keeps Cache Storage behind a
service worker. What the UI has to express (from `OFFLINE_READING.md`, the mobile spec §3/§3b,
and the reading-flow spec):
- Per-chapter and per-series download buttons, a multi-select chapter list with "next 10" and
  "all unread" helpers, and whole-novel download.
- A **Downloads** tab: saved series and chapters with real on-device sizes, a pin toggle
  (pinned series are never evicted), queue state (fetching pages at concurrency 2,
  paused at the storage floor, per-item retry). On iOS, downloads run in the foreground only,
  so a "keep the app open" notice is needed.
- **Settings → Storage**: cap 2 / 5 / 10 / 20 GB / Unlimited, live usage against the cap, a
  per-series size breakdown, "Free up space", the non-negotiable ~1.5 GB free-space floor, the
  48-hour read-then-expire rule (configurable), and "Manage in Files" on iOS or a folder picker
  on Android.
- Offline-first reading: a downloaded chapter paints from disk without waiting on the network.
  Progress and bookmarks queue in outboxes and flush on reconnect.

## 25. Reader-flow capabilities the design must stage (built or specified)

- **Seamless chapter boundary**: the last page of chapter N and the first of N+1 in one scroll,
  a quiet divider, scrollable in both directions, with the next manifest prefetched
  (`manifest.next`).
- **Read all**: an entire series as one windowed scroll, entered from a small control next to
  "Read" on the series page, streaming chapter 1 immediately while the rest fills in.
- **Cinema mode**: all chrome hidden after about 3 s idle, returning on tap or pointer move.
- **Continue hero**: large cover plus "Ch N · page P", one tap resumes the exact page.
- **Chapter list read-state**: finished chapters dimmed, in-progress ones showing `14/27`,
  unread normal; newest/oldest sort; decimal chapters sorted numerically.

---

## 26. Not built yet but designable

Roadmap Phase 5 (`ROADMAP.md`, ratified 2026-07-11) says AI features use external AI APIs
only. Below, each item names what the backend already gives and what is missing, so the
redesign can leave the right hole.

| Feature | Status today | What the redesign should reserve |
|---|---|---|
| **AI recommendations** | Partly built: `/library/world/recommendations` ("For you" plus "Because you read X"), `/library/suggest` and `/library/world/suggest` (the prompt box), and a genre histogram. | Rails, prompt box, `why` reasons and available-vs-info card states are designable now. Missing: "similar series" for a given series (no endpoint takes a seed series), "not interested" feedback, and ratings that feed back into ranking. Reserve a "More like this" rail on the series page and a dismiss or hide gesture on recommendation cards. |
| **Personalized home feed** | Not an endpoint. The pieces exist: continue-reading, recently-updated, world recs, pins, statistics. | The home can be composed client-side from those pieces today. Reserve a hero spotlight slot and an ordering that a future `GET /home` could drive (section type, title, items). Design empty states for a brand-new profile with no reading history (world recs return empty `for_you` then). |
| **Summaries and "Previously on" recap** | Nothing built. `ROADMAP.md` lists reading, chapter, character and series summaries "built on existing OCR text"; the decisions file asks for a "previously on" recap before continuing. Raw material exists: OCR `page_texts` for manga chapters (only for chapters someone scanned) and full paragraphs for novels. | A recap card or sheet between "Continue" and the reader, with loading, "no recap available (dialogue not indexed)" and "AI unavailable" states, plus a character list or glossary panel for novels (the attribution cast already lists characters per book). |
| **Smart collections** | Collections are manual only; tags exist but cannot be queried as a filter, and there is no rule engine. | Design collections with a "smart" variant (rule chips such as "status is reading and 3+ new chapters", "favourite manhwa", "unfinished novels") and an auto-generated badge. Client-side rules over `/library/series` fields (`reading_status`, `is_favorite`, `read_state.new_count`, `content_rating`) are possible now; server-side rules are not. |
| **Continue-reading suggestions** | Continue-reading itself is built (furthest chapter, auto-advances past finished ones). What is not built is suggestion logic: "you stopped this 3 weeks ago, pick it up?", "3 new chapters since you caught up", "finish this, only 2 chapters left". | The data is mostly there: `read_state.new_count`, `last_read_at`, `recently-updated`. Reserve badge and nudge variants on continue cards ("3 new", "Almost done", "Paused 21 d") and a "Up next" slot after finishing a series. |
| **Offline reading** | Built client-side (mobile M3 store, web service-worker Downloads). No backend work is needed. | Fully designable now (§24). |
| **Reading stats Wrapped** (decisions file) | The stats payload covers it for up to 365 days (daily, by-hour, streak, top series, top sources, totals). Missing: genre-over-time, per-year boundaries (it is a rolling window), and server-side image export. | Wrapped story cards and shareable images can be rendered client-side from `/library/statistics?days=365`. Reserve a genre radar (from `/library/recommendations`) and a streak flame. |
| **Social for 2-3 users** (decisions file) | Nothing built, and it cuts against the current model: every read is scoped to one `(user_id, profile_id)`, with no cross-account visibility at all. | Needs new backend endpoints (activity feed, reactions, shared collections, "recommend to") and an explicit opt-in sharing model that still hides 18+ items from profiles whose gate is closed. Design it as opt-in per profile, and design the "nothing shared yet" state as the default. |
| **Ambient reader extras** (decisions file) | Client-only: auto-scroll, soundscape, panel-by-panel view, dynamic colour from the current page. The only backend help is page `width/height` in the manifest. Panel detection has no backend support. | Pure client design space. |
| **Skin setting that follows the profile** | Not stored server-side; the settings endpoint has no UI-preference fields. | If Cinematic/Glass should follow a profile across devices, a `ui_skin` field on the profile is needed. Otherwise the setting is per device. Decide before designing the Settings copy. |
| **Source repoint** ("this source died, follow it on another") | Deferred (`backend-source-native-design.md` §10.1). The columns `migrated_from_source`, `migrated_from_series_key`, `migrated_at` exist; there is no endpoint. | A "Source is down, move to another source" flow on a followed series whose source health is `dead`, with a progress-mapping confirmation by chapter number. |
| **Search improvements, tag generation, metadata enrichment** | Listed in Phase 5, not built. World recs already enrich with AniList data (format, status, rating, official platforms). | Reserve space on the series page for enriched metadata (rating, format, official links, alt titles) and AI-suggested tags with accept/reject. |
| **Push notifications** | Not built (pull on open only). | Reserve the notification-permission prompt and a per-series notify bell (the `notify` field already exists). |

Superseded spec, for the record: `2026-09-05-design-presets-design.md` specified five
live-switching presets (Eclipse, Flat, Compact, Editorial, Cinema) that control shape but no
colour. The 2026-09-28 owner decisions (`inventory/00-decisions.md`) replace it with two full
skins, a restart on switch, dark AMOLED only, and no accent picker. The redesign should follow
the decisions file. The one idea worth keeping from the old spec is that the novel reader's
paper palettes are a separate axis from the app skin.
