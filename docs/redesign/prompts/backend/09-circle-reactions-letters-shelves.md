# Backend 09: reactions, letters and shared shelves (new feature 3, part 2)

**Goal.** Finish the server half of the Circle on top of `backend/08`'s sharing switches, activity record and shareable activity set S(member, viewer). Ship chapter reactions with the one shared enum of seven kinds and the server's half of the spoiler guard (a `sealed` flag that clears the moment the viewer completes the chapter); letters for Recommend to / Pass it on (create, inbox, sent box, `PATCH` state, `can_receive` on the member list, and `409 recipient_unavailable`); the `sent_to_you` section and the `letter` candidate of `also[]` on `GET /home`; and shared shelves (collections gain `shared` and `shared_with_me`, member-readable detail rows with their own `title`, `cover_url` and `ambient`, `can_add` series adds, `Leave shelf`, `added_by_profile_id` and the role-based series delete). Everything is profile-scoped, gates 18+ when serving and never when storing, reuses `backend/08`'s S and maturity methods instead of writing new ones, and is additive so today's clients keep working.

---

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §9.3.1 Model and privacy (S, gate on serve, counts after filtering)
   - §9.3.3 Reactions on chapters (the five stamps, one reaction per chapter per profile, moving and removing, the **spoiler guard** and the unseal)
   - §9.3.4 Recommend to ("Pass it on") and letters (who is listed for an 18+ series, the 140-character note, `Keep`, the failure toasts)
   - §9.3.5 Shared shelves (modes `CAN ADD │ VIEW ONLY`, `SHARED WITH YOU`, rows from the shelf's own `title`, `cover_url`, `ambient`, adder avatars, `Leave shelf`)
   - §9.3.8 Backend (reaction, letter and shelf endpoints and response shapes; **Adders**; **Race**)
   - §8.11 Collections and collection detail (the permission table "Who can do what on a shared shelf"; smart shelves cannot be shared; `Share` removed when the owner shares nothing)
   - §8.8 the `Sent to you` row and **Also in this issue** selection (candidate 3 `letter`: the newest unopened letter)
   - §9.1.7 the `sent_to_you` row of the section-items table (items are the `GET /circle/letters` shape)
   - §15.5 Backend additions (the Circle and shared-shelf rows, `PATCH /circle/letters/{id}`)
2. `docs/redesign/glass/DESIGN.md`
   - §9.3 the isolation and **Spoiler guard** paragraph
   - §9.3.1 Circle, the **Letters** bullet (`box=sent`, "Not opened yet" / "Opened", never whether it was added)
   - §9.3.2 Reactions on chapters (six named reactions and their stored kinds; `laughed` rendered as "Laughed"; one reaction per profile per chapter; states)
   - §9.3.3 Shared collections (who is listed; `View only` and `Can add` rights; "Remove {title}? Aarav added it."; `Leave shelf`; mature members served only to open gates)
   - §9.3.4 Recommend to a friend (`can_receive`, ineligible members omitted without explanation, `409 recipient_unavailable`)
   - §9.3.7 Backend used
   - §15.5 Backend additions (rows `can_receive`, `box=sent`, reaction kinds `hype` and `wrecked`, `PUT /library/collections/{id}/series/order`, `created_at`)
   - §15.6 Cross-skin contract alignment (rows **Reaction kinds**, **Recommendation recipients**, **Collection order and creation date**)
   - §8.0.10 the error table rows `recipient_unavailable` and `circle_member_not_sharing`
3. `docs/redesign/inventory/00-decisions.md` (new feature 3: reactions on chapters, shared collections, "recommend to", all respecting per-profile isolation and the 18+ gate)
4. `docs/redesign/stack-decision.md` §2.6 item 2 (social filtering runs on the backend; the 18+ gate applies when serving)
5. `docs/redesign/inventory/capabilities.md` §1 (error envelope, "the 18+ gate is absence, never a lock", `X-Total-Count` on bare lists), §11 Collections, §26 row "Social for 2-3 users"
6. `docs/redesign/00-baseline.md`
7. `docs/redesign/prompts-plan.json`, the entry whose `path` is this file
8. `docs/redesign/prompts/backend/08-circle-core-sharing-presence.md` (what the previous step built) and `backend/docs/circle-api.md` (its API note; you append to it)
9. The code you extend (read each fully first):
   - `backend/services/circle_service.py` (`CircleService`: the member definition, the S prefilter, `series_mature`, `record`, the feed, the member page, `CIRCLE_REQUIRES_VIEWER_SHARING`)
   - `backend/routes/circle.py`, `backend/routes/library.py` (collection routes), `backend/services/followed_series_service.py` (`_collection_scope`, `_visible_members`, `_member_counts`, `list_collections`, `get_collection`, `add_series_to_collection`, `remove_series_from_collection`, `_owned_collection`, `_serialize_collection`, and the `rules`, `preview_covers`, `preview_ambient_duo` fields `backend/02` added)
   - `backend/database/models.py` (`Collection`, `CollectionSeries`, `ChapterProgress`, `CircleEvent`, the `ReadingProfile` `share_*` columns)
   - the `GET /home` composer from `backend/04` (find it with `grep -rn '"circle_top"' backend/services backend/routes`) and its `also[]` selection
   - `backend/services/cover_colour.py` (`attach_cover_colours(db, items, key=…)`: sets `ambient` and `palette` from the `cover_palette` table, null on a miss, never fetches), `backend/scripts/README-dev-stack.md` (the dev stack and its `api` subcommand) and `docs/redesign/proof/backend-00/pytest-baseline.txt`
   - `backend/tests/test_audit_mature_collections.py`, `backend/tests/test_migrations_alembic.py`, `backend/tests/test_audit_isolation_profile_delete_cascade.py`, `backend/tests/conftest.py`

## Preconditions (check first; stop and report if one fails)

- On branch `feat/vps-slim-source-native`, no uncommitted changes under `backend/`. Record `BASE=$(git -C /srv/manhwamaniacs/dev/ManhwaManiacs rev-parse HEAD)` in your plan.
- `backend/08` has landed: `backend/services/circle_service.py` and `backend/routes/circle.py` exist, `grep -n 'circle_events' backend/database/models.py` matches, and `backend/.venv/bin/python -m pytest -q --no-header backend/tests/test_circle_core.py` passes.
- `backend/02` has landed: `grep -n 'preview_covers' backend/services/followed_series_service.py` matches and collections carry `rules`.
- `cd backend && .venv/bin/alembic heads` prints exactly one head (`backend/08`'s `NNNN_circle_core`).

## Skills to invoke

- `superpowers:writing-plans` first: the plan goes to `docs/redesign/proof/backend-09/plan.md`, one task per numbered scope item.
- `superpowers:test-driven-development` for every endpoint and permission rule.
- `superpowers:subagent-driven-development` to run the plan (sequential subagents, never two pytest runs at once); `superpowers:executing-plans` if subagents are unavailable.
- `superpowers:verification-before-completion` before claiming done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are **not** invoked: no UI in this step. The renderers are `web/22`, `mobile/22` (Cinematic) and `web/43`, `mobile/43` (Glass).

## Session rules

- **Scope lock.** Work only in `backend/` (never `backend/connectors/`) and `docs/redesign/proof/backend-09/` (plan and proof). Never edit `frontend/`, `mobile/`, `ops/`, `/srv/manhwamaniacs/{app,data}`, and never touch production containers.
- **RAM guard.** `free -m` before every full pytest run and before the dev stack; stop and report if `available` is under 1024 MB. One pytest run at a time.
- **Git.** Small commits on `feat/vps-slim-source-native` (migration + models; reactions; spoiler flag; letters; home letter sections; shelf roles and share calls; shelf rows and adds; shelf deletes and order; docs), `git push` after each. Stage explicit paths only. Conventional Commits (`feat(circle): …`). **No Claude or AI attribution anywhere** (no `Co-Authored-By`, no "Generated with", no AI author). Never commit secrets, cookie jars or `.claude/`.
- **Reuse, do not re-implement.** Every visibility decision about another profile's data calls `CircleService` (member definition, S prefilter, `series_mature`). If a method you need is private there, make it public in place; never copy its body.
- **Additive only.** No existing field changes type; `GET /library/collections` keeps returning a bare array unless the caller opts in with `include_shared=true` (§7).

---

## Scope (deliver every item)

### 1. Migration and models

One Alembic revision `backend/alembic/versions/MMMM_circle_social.py`, `MMMM` = the highest four-digit prefix in `backend/alembic/versions/` plus one, `revision = "MMMM_circle_social"` (at most 32 characters, the `alembic_version.version_num` width), `down_revision` = the single head (`NNNN_circle_core`), with a module docstring in the house style of `0017_world_catalog_cache.py`. `backend/database/models.py` declares the same schema, so autogenerate reports no diff. Every per-profile table uses the composite `(user_id, profile_id) → reading_profiles (user_id, id) ON DELETE CASCADE` foreign key of `ChapterProgress`, and every foreign key onto `reading_profiles` cascades (`test_every_profile_id_fk_cascades_in_the_orm_schema`).

- **`circle_reactions`**: `user_id` FK `users.id`; `profile_id` FK `reading_profiles.id` `ondelete="CASCADE"`; composite FK `fk_circle_reactions_scope`; `source_id` String(64); `series_key` String(512); `chapter_key` String(512); `chapter_number` Float NULL; `kind` String(16) NOT NULL; `shared` Integer (bool) NOT NULL `server_default="0"`; `created_at` DateTime NOT NULL. Primary key `(profile_id, source_id, series_key, chapter_key)` (one reaction per profile per chapter). Index `ix_circle_reactions_chapter (source_id, series_key, chapter_key)`.
- **`circle_letters`** (one row per recipient; a multi-recipient send shares a `sent_group`): `id` Integer PK; `from_user_id` FK `users.id`; `from_profile_id` FK `reading_profiles.id` CASCADE; `to_user_id` FK `users.id`; `to_profile_id` FK `reading_profiles.id` CASCADE; composite FKs `fk_circle_letters_from_scope` `(from_user_id, from_profile_id)` and `fk_circle_letters_to_scope` `(to_user_id, to_profile_id)`, both CASCADE; `sent_group` String(32) NOT NULL (`uuid4().hex`); `source_id` String(64); `series_key` String(512); `title` String(512) NOT NULL; `cover_url` String(1024) NULL; `note` String(140) NULL; `state` String(16) NOT NULL `server_default="new"` (`new`, `read`, `kept`, `dismissed`); `created_at`, `updated_at` DateTime NOT NULL. Indexes `ix_circle_letters_to (to_profile_id, created_at)`, `ix_circle_letters_from (from_profile_id, sent_group)`.
- **`collections.share_mode`** String(16) NULL (`can_add` | `view_only`; NULL = not shared), added with `op.add_column`.
- **`collection_shares`**: `collection_id` FK `collections.id` CASCADE; `user_id` FK `users.id`; `profile_id` FK `reading_profiles.id` CASCADE; composite FK `fk_collection_shares_scope`; `created_at` DateTime. Primary key `(collection_id, profile_id)`. Index `ix_collection_shares_profile (profile_id)`.
- **`collection_series` gains** `title` String(512) NULL, `cover_url` String(1024) NULL, `added_by_user_id` Integer NULL, `added_by_profile_id` Integer NULL, a composite `ForeignKeyConstraint(["added_by_user_id", "added_by_profile_id"], ["reading_profiles.user_id", "reading_profiles.id"], ondelete="CASCADE", name="fk_collection_series_added_by")` and `Index("ix_collection_series_added_by", "added_by_profile_id")` (the cascade's seek target). A table-level constraint cannot be added by `ALTER TABLE`, so use `op.batch_alter_table("collection_series", recreate="always")`. Consequence, documented in `backend/docs/circle-api.md`: deleting a profile removes the series it added to other profiles' shelves (a reused profile id can then never inherit another profile's add rights).
- **Backfill** in `upgrade()`, one `UPDATE collection_series` statement: `added_by_user_id` and `added_by_profile_id` = the owning collection's `user_id` and `profile_id`; `title` = `COALESCE(the owner's followed_series.title for the pair, source_series_cache.title when not '', series_key)`; `cover_url` = `COALESCE(the owner's followed_series.cover_url, source_series_cache.cover_url)`.
- `downgrade()` drops `collection_shares`, `circle_letters`, `circle_reactions`, `collections.share_mode`, and the four `collection_series` columns with their constraint and index (batch mode).
- Update `backend/tests/test_migrations_alembic.py`: `_HEAD`, `_REVISIONS`, `_EXPECTED_TABLES` (add `circle_reactions`, `circle_letters`, `collection_shares`), and add `test_circle_social_migration_backfills_collection_rows` modelled on `test_chapter_count_backfill_matches_the_parsed_array` (seed a collection row at the previous head, upgrade, assert `added_by_*` = owner and `title` = the follow's title, and the `series_key` fallback for an unfollowed, uncached row).

### 2. Reactions (`backend/routes/circle.py`, logic in `CircleService`)

**Kinds.** One enum of seven, the stored values shared by both skins (glass §15.6 row **Reaction kinds**): `loved`, `shook`, `laughed`, `tears`, `chefs_kiss`, `hype`, `wrecked`. Cinematic offers five stamps (`loved` ♥ Loved, `shook` !! Shook, `laughed` HA Laughed, `tears` … Tears, `chefs_kiss` ✦ Chef's kiss) and renders `hype` and `wrecked` as the stamps `HYPE` and `WRECKED`; Glass offers six (Love `loved`, Tears `tears`, Twist `shook`, Masterpiece `chefs_kiss`, Hype `hype`, Wrecked `wrecked`) and renders a stored `laughed` as "Laughed". The server stores and returns the value only; labels are the clients'.

- `POST /circle/reactions` body `{source_id (1–64), series_key (1–512), chapter_key (1–512), kind}` (`kind` a `Literal` of the seven; anything else `422`). One reaction per profile per chapter: no row → insert; the same kind → no change; another kind → update `kind` in place (cinematic §9.3.3 "pressing another moves it"). On insert and on move: `created_at = utcnow()`, `chapter_number` from the viewer's own `chapter_progress` row for that chapter (else NULL), `shared = share_activity AND share_reactions` of the viewer **at this moment** (so a reaction made while "Show my reactions" was off never surfaces later; glass §9.3.2 "Only you see this"). Then replace the Circle event: delete the viewer's `reacted` `circle_events` row for that chapter and, when `shared`, write a new one through `CircleService.record(kind="reacted", reaction=kind, …)`. Returns 200 with the `ChapterReactions` object for that chapter (below). The 18+ gate is not checked when storing.
- `DELETE /circle/reactions` with the body `{source_id, series_key, chapter_key}` (cinematic §9.3.8; one reaction per profile per chapter, so no id) → 204. Deletes the row and its `reacted` event; idempotent (204 when nothing existed).
- `GET /circle/reactions?source=&series=` (both required, `series` percent-decoded with `fully_unquote`) → `{"chapters": [ChapterReactions]}`, only chapters with at least one visible reaction, ordered by `chapter_number` descending (NULLs last), then `chapter_key`.

`ChapterReactions`:
```json
{"chapter_key": "…", "chapter_number": 142.0,
 "counts": {"loved": 1, "shook": 0, "laughed": 0, "tears": 1, "chefs_kiss": 0, "hype": 0, "wrecked": 0},
 "total": 2,
 "by": [{"profile_id": 7, "name": "Riya", "avatar_key": "…", "username": "riya", "kind": "loved", "created_at": "…"}],
 "mine": "tears",
 "sealed": true}
```

- **Visible reactions**: the viewer's own reaction always (whatever its `shared` flag or the viewer's switches); another profile's reaction only when that profile is a member (`backend/08` definition), `shared` is true, the member's `share_reactions` is on, `created_at` is at or after the member's `share_activity_since`, the series is not in the member's hidden list, and the both-sided 18+ rule passes (`series_mature(member, viewer, …)`, then the member's effective `include_mature` and the viewer's gate). `counts` (all seven keys, zeros included), `total` and `by` are computed from visible reactions only (cinematic §9.3.1 "counts are computed after filtering"). `mine` is the viewer's kind or `null`.
- The per-chapter counts on the feature page's schedule rows and the reader `CIRCLE` panel read this endpoint; the Glass strip's "who reacted" popover reads `by`.

### 3. The spoiler guard: the server's half

The guard is applied by the client from the viewer's own progress (cinematic §9.3.3; glass §9.3), so the server **still returns full reactions** (glyph, kind, counts) to anyone allowed to see them, and adds one flag so a client that holds no local progress for a chapter (a feed item for a series it never opened) can apply the guard correctly:

- `sealed: true` when the viewer has **not completed** that chapter: no `chapter_progress` row for the viewer with `is_completed = 1` and the same `source_id` and `series_key` and either the same `chapter_key` or the same non-null `chapter_number`. A half-read chapter (a row without `is_completed`) is sealed. `sealed: false` once completed.
- Unsealed by progress: the next read after `POST /reader/progress` (or `/reader/progress/batch`) completes the chapter returns `sealed: false`. No write happens on unseal; the flag is computed per request.
- The flag appears on `ChapterReactions`, on `GET /circle/feed` items of kind `reacted` (null on other kinds), and on the `reactions` items of `GET /circle/members/{profile_id}`. The viewer's own reaction is never guarded: clients show `mine` whatever `sealed` says.
- Clients render a sealed reaction as the avatar plus "reacted to Ch. 212" (Cinematic `type.caption` `ink.45`; Glass "reacted to Ch 212") and unseal with the glyphs fading in over 160 ms, 40 ms apart; those values are the clients' (`web/22`, `mobile/22`, `web/43`, `mobile/43`), not the server's.

### 4. Letters (Recommend to / Pass it on)

**Who can receive** (glass §15.5 row `can_receive`, cinematic §9.3.4): a recipient R can receive series X from viewer V when R is a member for V (`backend/08`: another profile, active account, `share_activity` on), R's `share_recommendations` is on, and, when X is mature by `series_mature(V, R, …)` (either side resolves mature), R's own gate is open **and** R's effective `include_mature` is on. No reason is ever returned (glass §9.3.4: the sheet must never reveal another profile's gate).

- **`GET /circle/members?source_id=&series_key=`**: with both parameters, each member object gains `"can_receive": bool` by the rule above; with neither, no field; with one of them, `422`.
- **`POST /circle/letters`** body `{to_profile_ids: [int] (1–10, unique), source_id, series_key, note?: str (stripped, ≤ 140 characters; empty becomes null)}`:
  - When X is mature by `series_mature(V, V, …)` and V's own gate is closed → `404 series_not_found` (a gated sender cannot probe a series' rating through who may receive it).
  - Any recipient that cannot receive (including V itself, an unknown id, a non-member) → `409 recipient_unavailable` with `details: {"profile_ids": [the failing ids]}`, and **nothing** is written (cinematic §9.3.8 **Race**: the client deselects them and resends).
  - Otherwise one `circle_letters` row per recipient sharing one `sent_group`, `state = "new"`, `title` and `cover_url` snapshotted from V's follow row, else `source_series_cache`, else `title = series_key`. The sender does not need `share_activity` on (reciprocity: a letter is a deliberate act that discloses only itself). → 201 with the `SentLetter` object below.
- **`GET /circle/letters`** (`box=inbox`, the default) → JSON array of `Letter`, the viewer's received letters in states `new`, `read`, `kept` (never `dismissed`), newest first:
  ```json
  {"id": 12, "from": {"profile_id", "name", "avatar_key", "username"},
   "source_id": "…", "series_key": "…", "title": "…", "cover_url": "…",
   "ambient": {…}, "palette": {…}, "content_kind": "manga",
   "note": "you'll love the tower arc.", "state": "new", "created_at": "…"}
  ```
  A letter whose series is mature by `series_mature(sender, viewer, …)` is **absent** while the viewer's gate is closed; a letter from an inactive account is absent. The Index tab badge, the Index `Circle` row folio (`2 NEW`), the sidebar count and Glass's bloom dot all count `state == "new"` rows of this list.
- **`GET /circle/letters?box=sent`** (Glass addition) → JSON array of `SentLetter`, one per `sent_group`, newest first:
  ```json
  {"id": "3f2a…", "to": [{"profile_id", "name", "avatar_key", "username", "state": "new"}],
   "source_id": "…", "series_key": "…", "title": "…", "cover_url": "…", "ambient": {…}, "palette": {…},
   "content_kind": "manga", "note": "…", "state": "new", "created_at": "…"}
  ```
  Each recipient's `state` is `new` when theirs is `new` and `read` for `read`, `kept` or `dismissed` (glass §9.3.1: "Not opened yet" or "Opened", never whether it was added or kept); the row's `state` is `new` when any recipient is `new`. Letters about a series mature by `series_mature(V, V, …)` are absent while V's gate is closed. `box` other than `inbox` or `sent` → `422`.
- **`PATCH /circle/letters/{id}`** body `{state: "read" | "kept" | "dismissed"}` (`new` or anything else `422`) → 200 with the updated `Letter`. Only the recipient's own row; another profile's letter, an unknown id, or a letter currently absent under the gate → `404 not_found`. Glass writes only `read` and `dismissed` and renders `kept` as an ordinary read letter; Cinematic's `Keep` writes `kept` (glass §15.6).

### 5. Letters on `GET /home`

Computed fresh on every request after the composed-cache read, never stored in the composed cache (so a dismissed letter or a gate change is reflected at once), following the request's `content_kind`:

- **`sent_to_you`** (cinematic §8.8 row, §9.1.7): inbox letters in state `new` or `kept`, newest first, at most 10; `items` are `Letter` objects; the section's `note` is the newest item's `note` (null when it has none); `title` `"Sent to you"`; `state` `"ready"` or `"empty"`; `generated_at` serve time. It sits at its fixed place in the §9.1.7 order (`… where_were_we, sent_to_you, picked …`). Glass's "From your Circle" rail reads `sent_to_you` plus `circle` (glass §9.1.1).
- **`also[]` candidate 3 `letter`** (cinematic §8.8 **Also in this issue**): the newest `new` inbox letter becomes `{"kind": "letter", "source_id", "series_key", "headline": "{from.name} recommends {title}", "deck": note or "", "ambient"}`. Re-run the `also[]` selection at serve time with this fresh candidate (priority order `new_chapters`, `because`, `letter`, `almost_there`; never repeating a series; never the cover story's series; three slots). If `backend/04` wrote the selection inline, first extract it into one pure function `select_also(candidates, cover_key) -> list` in the same module with no behaviour change (its existing tests prove that), then call it after the cache read.

### 6. Shared shelves: roles and sharing (`backend/services/followed_series_service.py`, `backend/routes/library.py`)

**Roles.** Replace the owner-only lookup on the collection read and write paths with one method `_shelf_access(collection_id) -> (Collection, role)`, `role` one of `owner`, `can_add`, `view_only`:
- `owner`: the collection's `(user_id, profile_id)` is the request's.
- `can_add` / `view_only` (the collection's `share_mode`): a `collection_shares` row for the viewer **and** the membership is effective: the owner profile's `share_activity` is on and its account active, and the viewer's `share_activity` and `share_shelves` are on (cinematic §8.11 "When the owner's profile shares nothing, `Share` is removed"; §9.3.1 "Nothing is visible to anyone until a profile turns sharing on").
- anything else: `404 not_found` (never disclose that a shelf exists).

**Permission table** (cinematic §8.11, glass §9.3.3), enforced by the server; a member that is not allowed gets `403 forbidden`:

| Call | owner | `can_add` | `view_only` |
|---|---|---|---|
| `GET /library/collections/{id}` | yes | yes | yes |
| `POST /library/collections/{id}/series` | yes | yes | 403 |
| `DELETE /library/collections/{id}/series` (existing body route) | any row | only rows whose `added_by_profile_id` is the viewer, else 403 | 403 |
| `PATCH /library/collections/{id}`, `DELETE /library/collections/{id}`, series order, `POST …/share` | yes | 403 | 403 |
| `DELETE /library/collections/{id}/share/me` | 403 | yes | yes |

- **`POST /library/collections/{id}/share`** body `{profile_ids: [int] (0–10, unique), mode: "can_add" | "view_only"}` → 200 with the owner's list row (§7). Refusals, checked in this order, each writing nothing: a smart shelf (`rules` not null) → `409 smart_shelf_not_shareable` (cinematic §8.11: "Smart shelves follow your own library, so they can't be shared."); the owner's `share_activity` off → `409 sharing_off`; any id that is the owner, unknown, on an inactive account, or whose `share_activity` or `share_shelves` is off → `409 member_unavailable` with `details: {"profile_ids": [...]}`. An empty `profile_ids` unshares (`share_mode = NULL`, all share rows deleted). Otherwise `share_mode = mode` and the member set is replaced by `profile_ids`. Series added by a removed member stay on the shelf.
- **`DELETE /library/collections/{id}/share/{profile_ref}`** → 204, `profile_ref` is `me` or an integer id (anything else `422`). The owner removes that member (idempotent 204 for a non-member id; `me` is 403 for the owner). A member may pass only `me` or their own id (another id → 403) and leaves the shelf (cinematic `Leave shelf`, glass "Leave shelf"): their share row is deleted, the series they added stay.
- **Series order.** If `PUT /library/collections/{id}/series/order` already exists (`grep -n 'series/order' backend/routes/library.py`), members get 403 through `_shelf_access` and nothing else changes. If it does not exist, add it (glass §15.5, §15.6 row **Collection order and creation date**): body `{items: [{source_id, series_key}]}`, owner only, 204; the listed rows take `sort_order` 0, 1, 2 … in body order, unlisted rows keep their relative order after them; an item that is not on the shelf → `422 order_mismatch`.
- If `GET /library/collections` rows do not yet carry `created_at` (the column exists on `collections`), add it (ISO 8601).

### 7. Shared shelves: payloads

- **`GET /library/collections`** (default, no parameter): the bare JSON array of the viewer's own shelves, as today, each row gaining `"role": "owner"` and `"shared": {"owner_profile_id", "mode", "member_profile_ids", "members": [ProfileRef]} | null` (`null` when `share_mode` is NULL; `member_profile_ids` and `members` list only effective members). `X-Total-Count` unchanged. Today's clients see only additive fields.
- **`GET /library/collections?include_shared=true`**: `{"collections": [the same owner rows], "shared_with_me": [SharedShelf]}`. The DESIGN shape "the response gains `shared_with_me`" cannot be added to a bare array without breaking today's clients, so the new skins opt in with this parameter; record this in `backend/docs/circle-api.md` as the one deliberate deviation. `X-Total-Count` is the length of `collections`.
- `SharedShelf`: the owner-row fields (`id`, `name`, `description`, `series_count`, `preview_covers`, `preview_ambient_duo`, `rules` (always null), `created_at`) computed over the rows **visible to the viewer**, plus `"owner": ProfileRef`, `"role": "can_add" | "view_only"` and `"shared"` as above. Ordered by owner name, then shelf name. Only effective memberships appear.
- **`GET /library/collections/{id}`** (owner and members): the existing payload plus `role`, `shared`, `owner` (ProfileRef), and on every `series` row `title`, `cover_url`, `ambient`, `palette` (set by `attach_cover_colours` from `backend/services/cover_colour.py`, keyed on the row's `(source_id, series_key)`), `added_by_profile_id` and `added_by` (ProfileRef, or `null` when the adder no longer exists). Rows render from the shelf's own `title`, `cover_url` and `ambient`, never from the viewer's library (cinematic §9.3.5).
- **18+ on shelves** (cinematic §9.3.5, glass §9.3.3 last bullet): on a shared shelf (`share_mode` not NULL), for owner and members alike, a row is visible when it is not mature by `series_mature(adder or owner, viewer, …)` or the viewer's gate is open; hidden rows are absent from `series`, `series_count`, `preview_covers` and `preview_ambient_duo`. The owner's include-18+ switch plays no part here (the owner shared the shelf deliberately; only the viewer's gate decides). An unshared shelf keeps the existing `_visible_members` path untouched, so `test_audit_mature_collections.py` stays green.
- **`POST /library/collections/{id}/series`** (owner or `can_add`): snapshots `title` and `cover_url` from the adder's follow row, else `source_series_cache`, else `title = series_key`, and sets `added_by_user_id`, `added_by_profile_id` to the viewer. This applies to the owner's unshared shelves too, so a later share needs no backfill.
- **Member page.** `GET /circle/members/{profile_id}` `shelves` (left `[]` by `backend/08`) becomes that member's shelves effectively shared with the viewer, as `SharedShelf` objects.

### 8. API note

Append to `backend/docs/circle-api.md`: every endpoint of this step with body, response and error codes (`recipient_unavailable`, `series_not_found`, `smart_shelf_not_shareable`, `sharing_off`, `member_unavailable`, `order_mismatch`, `forbidden`, `not_found`, `422` validation), the seven reaction kinds, the `sealed` flag, the `include_shared=true` deviation, and the profile-deletion consequence of `fk_collection_series_added_by`.

---

## File layout

| Path | Change |
|---|---|
| `backend/alembic/versions/MMMM_circle_social.py` | new migration (§1) |
| `backend/database/models.py` | `CircleReaction`, `CircleLetter`, `CollectionShare`; `Collection.share_mode`; `CollectionSeries` columns, constraint, index |
| `backend/services/circle_service.py` | reactions, `sealed`, `can_receive`, letters, `sent_to_you` and the `letter` `also[]` candidate, member-page `shelves` |
| `backend/routes/circle.py` | `POST`, `DELETE`, `GET /circle/reactions`; `POST`, `GET /circle/letters`; `PATCH /circle/letters/{id}`; `can_receive` query on `GET /circle/members` |
| `backend/services/followed_series_service.py` | `_shelf_access`, share and leave, role checks, row snapshots, shared payloads, `shared_with_me` |
| `backend/routes/library.py` | `include_shared` on the list, `POST …/share`, `DELETE …/share/{profile_ref}`, series order (only if absent) |
| the `/home` composer from `backend/04` | `sent_to_you` and the `letter` `also[]` candidate after the cache read (§5) |
| `backend/tests/test_circle_reactions.py` | new |
| `backend/tests/test_circle_letters.py` | new |
| `backend/tests/test_circle_shelves.py` | new |
| `backend/tests/test_migrations_alembic.py` | head, revisions, tables, backfill test |
| `backend/docs/circle-api.md` | appended (§8) |
| `docs/redesign/proof/backend-09/plan.md` | the plan |
| `docs/redesign/proof/backend-09/*.json`, `pytest-before.txt`, `pytest-after.txt` | proof captures |

## Tests (write each first; HTTP-level through `client` and `as_user(uid, pid)`)

World: account 1 with profiles A and B, account 2 with profile C; sharing on for all three unless a test turns it off; chapters read through `POST /reader/progress`.

`test_circle_reactions.py`:
1. `POST` inserts; the same kind is a no-op; another kind moves it (still one row); `DELETE` removes it; a second `DELETE` is 204.
2. All seven kinds are accepted; `"wow"` is 422.
3. `counts` (seven keys), `total`, `by` count only visible reactions; the viewer's own reaction is in `mine` and `by` with sharing off; others do not see it; turning `reactions` off hides C's reactions from A; a reaction C made while `reactions` was off stays hidden after C turns it back on.
4. Feed: `GET /circle/feed?kind=reaction` shows C's `reacted` item; moving the reaction replaces the item's `reaction`; deleting removes the item.
5. **Spoiler guard** (unread, half-read and finished chapters): for a chapter A has never opened `sealed` is true; for a chapter A has read halfway (`last_page` 5 of 20, not completed) `sealed` is true; for a chapter A finished `sealed` is false; after A completes the half-read chapter through `POST /reader/progress`, the next `GET /circle/reactions`, the next feed item and the next member-page reaction all say `sealed: false`; a completed row under another `chapter_key` spelling with the same `chapter_number` also unseals; glyph and kind are returned in every case.
6. 18+: C's reaction on a mature series reaches A only when C's effective `include_mature` is on and A's gate is open (all four cells), and the counts follow.
7. Isolation: B (same account, sharing off) and a non-member never appear in `by`; a profile on a third account sees C's reactions only under S.

`test_circle_letters.py`:
1. A sends to B and C with a note: each inbox has one `new` letter; A's `box=sent` has one row with both recipients `new`.
2. `409 recipient_unavailable` with the failing ids when a recipient has `recommendations` off, is not sharing, is A itself, or does not exist; nothing is written (both inboxes empty).
3. Mature series X: C's gate closed → 409; C's gate open and `include_mature` off → 409; both on → 201; `GET /circle/members?source_id&series_key` shows `can_receive` false, false, true for those cells and the objects contain no reason field; with one of the two parameters it is 422.
4. Never leak a mature title: after C (open gate, include on) receives X, C closes the gate: X's letter is absent from `GET /circle/letters`, from `/home` `sent_to_you` and from `also[]`, and the title string of X appears nowhere in any JSON C receives (assert on the response text); `PATCH` on it is 404. A gated A sending X gets `404 series_not_found`.
5. `PATCH` `read`, `kept`, `dismissed` work for the recipient; `new` is 422; B patching C's letter is 404; `dismissed` leaves the inbox; `kept` stays in `sent_to_you`; A's `box=sent` shows `kept` and `dismissed` as `read`.
6. A 141-character note, an empty `to_profile_ids` and eleven recipients are each 422.
7. `/home`: `sent_to_you` lists `new` and `kept` letters with `note` from the newest; `also[]` carries the `letter` candidate in its priority slot and never repeats the cover story's series.

`test_circle_shelves.py`:
1. A shares a shelf with B (`can_add`) and C (`view_only` via a second call replacing the set, then both back): A's row carries `shared` with `members`; B's default `GET /library/collections` is unchanged (no shared shelf in the array); B's `?include_shared=true` lists it under `shared_with_me` with `role: "can_add"` and `owner`.
2. B adds a series (row has `added_by_profile_id` B and a title snapshot), removes it, and gets 403 removing A's row; C gets 403 on add and on remove; a stranger profile gets 404 on read, add, remove, share and leave.
3. B and C get 403 on `PATCH`, `DELETE` and series order; A removes any row.
4. B leaves with `DELETE …/share/me`: the shelf leaves B's `shared_with_me`, B's added rows stay; A removes C with `DELETE …/share/{C}`; A's `DELETE …/share/me` is 403.
5. Refusals: a smart shelf → 409 `smart_shelf_not_shareable`; A with `activity` off → 409 `sharing_off`; C with `shelves` off → 409 `member_unavailable` naming C. A turning `activity` off removes the shelf from B's `shared_with_me` and makes B's detail read 404; B turning `shelves` off does the same.
6. 18+: a mature series on the shared shelf is absent for C with a closed gate (and out of `series_count` and `preview_covers`) and present for B with an open gate.
7. Detail rows carry `title`, `cover_url`, `ambient`, `added_by_profile_id`, `added_by`; `GET /circle/members/{A}` as B lists the shelf under `shelves`.
8. Deleting profile B removes B's share rows, the series B added to A's shelf, B's reactions and every letter to or from B.

## Acceptance criteria

- [ ] `MMMM_circle_social.py` upgrades, backfills and downgrades; `test_alembic_head_matches_models`, `test_autogenerate_against_head_reports_no_diff`, `test_every_profile_id_fk_cascades_in_the_orm_schema` and the new backfill test pass.
- [ ] Reactions: seven kinds, one per profile per chapter, move and remove, counts after filtering, own reaction always visible to its author, others' only under S with `shared` set at write time.
- [ ] Spoiler guard: `sealed` is true for unread and half-read chapters, false for finished ones, flips on the next read after completion, appears on reactions, feed `reacted` items and member-page reactions, and the server never withholds the glyph.
- [ ] Letters: `can_receive` by the §4 rule with no reason field; `409 recipient_unavailable` writes nothing; `box=sent` never reveals `kept` or `dismissed`; `PATCH` only by the recipient; a mature title never reaches a gated recipient in any payload.
- [ ] `/home` `sent_to_you` and the `also[]` `letter` candidate are computed per request, never cached.
- [ ] Shared shelves follow the permission table exactly (403 for members, 404 for strangers); `GET /library/collections` stays a bare array without `include_shared=true`; shared rows render from their own `title`, `cover_url`, `ambient`; mature rows are absent for gated viewers and counts follow; smart shelves and non-sharing owners cannot share.
- [ ] Every visibility decision about another profile's data calls `CircleService`; `grep -n 'mature' backend/services/circle_service.py backend/services/followed_series_service.py` shows no second copy of the Circle 18+ rule.
- [ ] Per-skin differences are served by one API: Cinematic reads five kinds plus `HYPE` and `WRECKED`, writes `kept`, uses `DELETE …/share/me`; Glass reads six kinds plus "Laughed", writes only `read` and `dismissed`, uses `box=sent` and `DELETE …/share/{profile_id}` with its own id; both read `can_receive` and `sealed`. No endpoint takes a skin parameter.
- [ ] Reduced motion, web keyboard access and 44 pt hit targets: not applicable to this backend step (no UI); the unseal timing (160 ms, 40 ms apart) and every hit target belong to `web/22`, `mobile/22`, `web/43`, `mobile/43`.
- [ ] `git diff --stat $BASE..HEAD -- frontend mobile backend/connectors ops` prints nothing.
- [ ] Every test that passed before your first change still passes; the new tests pass; 0 failed.
- [ ] `backend/docs/circle-api.md` covers every endpoint of this step; proof JSON exists under `docs/redesign/proof/backend-09/`.

## Verification (exact commands)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend
free -m                                   # stop if "available" < 1024
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-09/pytest-before.txt   # BEFORE any change; pre-existing failures named in docs/redesign/proof/backend-00/pytest-baseline.txt stay out of scope
# … work …
.venv/bin/alembic heads                   # exactly one head: MMMM_circle_social
.venv/bin/python -m pytest -q --no-header tests/test_circle_reactions.py tests/test_circle_letters.py tests/test_circle_shelves.py tests/test_circle_core.py tests/test_circle_mature_gate.py tests/test_migrations_alembic.py tests/test_audit_migrations_autogenerate_fts.py tests/test_audit_isolation_profile_delete_cascade.py tests/test_audit_mature_collections.py tests/test_profile_isolation.py
free -m
timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -25 > ../docs/redesign/proof/backend-09/pytest-after.txt   # before count + new tests, 0 new failures
```

No web or mobile file changes in this step, so the baseline's `npm run lint`, `npm run build` (in `frontend/`), `flutter analyze` and `flutter test` (in `mobile/`, Flutter at `/srv/manhwamaniacs/dev/flutter/bin`) are not re-run; `git diff --stat $BASE..HEAD -- frontend mobile` must print nothing.

**Proof** (captured JSON from the `backend/00` dev stack; this step has no screens and so no Playwright screenshots). The dev stack runs on `127.0.0.1:8010` against a dev SQLite file under `/srv/manhwamaniacs/dev/data/`, never production data; the seeded `demo` account has **Riya** (18+ open) and **Aarav** (18+ closed), Aarav follows three of Riya's series, and Riya owns the shelf "Weekend binge". `dev_stack.sh api METHOD PATH [JSON]` signs in and sends `X-Profile-Id` for `MM_DEV_PROFILE` (default `Riya`).

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
free -m                                                     # stop if "available" < 1024
backend/scripts/dev_stack.sh reset
P=docs/redesign/proof/backend-09
backend/scripts/dev_stack.sh api GET /profiles > $P/profiles.json                    # note both ids
backend/scripts/dev_stack.sh api PATCH /profiles/<Riya id>/sharing '{"activity": true}'
backend/scripts/dev_stack.sh api PATCH /profiles/<Aarav id>/sharing '{"activity": true}'
backend/scripts/dev_stack.sh api GET /library/series > $P/riya-library.json          # pick a series Aarav also follows, and one chapter key
backend/scripts/dev_stack.sh api POST /circle/reactions '{"source_id": "<id>", "series_key": "<key>", "chapter_key": "<chapter>", "kind": "loved"}'
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/circle/reactions?source=<id>&series=<url-encoded key>' > $P/reactions.json               # sealed: true
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api POST /reader/progress '{"source_id": "<id>", "series_key": "<key>", "chapter_key": "<chapter>", "last_page": 20, "page_count": 20, "is_completed": true}'
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/circle/reactions?source=<id>&series=<url-encoded key>' > $P/reactions-after-complete.json  # sealed: false
backend/scripts/dev_stack.sh api GET '/circle/members?source_id=<id>&series_key=<url-encoded key>' > $P/members-can-receive.json
backend/scripts/dev_stack.sh api POST /circle/letters '{"to_profile_ids": [<Aarav id>], "source_id": "<id>", "series_key": "<key>", "note": "The tower arc is worth it."}' > $P/letter-sent-response.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET /circle/letters > $P/letters-inbox.json
backend/scripts/dev_stack.sh api GET '/circle/letters?box=sent' > $P/letters-sent.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/home?content_kind=manga&tz_offset_minutes=330' | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"also": d["also"], "sent_to_you": [s for s in d["sections"] if s["type"] == "sent_to_you"]}, indent=2))' > $P/home-sent-to-you.json
backend/scripts/dev_stack.sh api GET /library/collections > $P/riya-collections.json  # note the shelf id
backend/scripts/dev_stack.sh api POST /library/collections/<shelf id>/share '{"profile_ids": [<Aarav id>], "mode": "can_add"}' > $P/share-response.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET '/library/collections?include_shared=true' > $P/collections-include-shared.json
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET /library/collections/<shelf id> > $P/shared-shelf-detail.json
backend/scripts/dev_stack.sh stop
```

Do not commit the dev stack's cookie file or database; only the files under `docs/redesign/proof/backend-09/`.

## Report back

Reply with:
1. Done items, numbered as Scope 1–8, each with its commit hash.
2. The migration file name and revision id, and whether `PUT /library/collections/{id}/series/order` and `created_at` already existed or were added here.
3. Test counts: full-suite passed before your first change, passed after, failed after (must be 0), and the number of new tests.
4. The proof path `docs/redesign/proof/backend-09/` and its file list.
5. Open issues, and the deviations the client steps must know: `GET /library/collections?include_shared=true` for `shared_with_me`; `sealed` beside the full reaction; `counts` has seven keys; `SentLetter.id` is the `sent_group` string while `Letter.id` is an integer.

**Next prompt file:** the backend track ends here; the Circle clients that consume this API are `docs/redesign/prompts/web/22-cinematic-circle.md` and `docs/redesign/prompts/mobile/22-cinematic-circle.md`. In the global plan order the next file is `docs/redesign/prompts/web/12-cinematic-manga-reader-strip.md`.
