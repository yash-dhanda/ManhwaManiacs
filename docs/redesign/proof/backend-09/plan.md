# backend/09 plan: reactions, letters and shared shelves

BASE = feat/vps-slim-source-native at merge f5f020c2. Worktree branch redesign/backend.

1. Migration `0026_circle_social` and models (`CircleReaction`, `CircleLetter`, `CollectionShare`, `Collection.share_mode`, `CollectionSeries` snapshot and adder columns); head, revisions, tables and backfill tests.
2. Reactions in `CircleService` (`react`, `unreact`, `reactions`), routes on `/circle/reactions`.
3. `sealed` from the viewer's completed `chapter_progress`, on reactions, feed `reacted` items and member-page reactions.
4. Letters (`can_receive`, `send_letters`, inbox, sent box, `patch_letter`), routes on `/circle/letters`.
5. `/home`: `sent_to_you` live builder and the `letter` candidate; `select_also` extracted from `_also`, re-run at serve time from a cached candidate pool.
6. Shelf roles (`_shelf_access`), share and leave calls, member 403s.
7. Shelf payloads: `include_shared`, `SharedShelf`, snapshotted rows, adds with adder, shared-shelf 18+ rule, member page `shelves`.
8. Shelf deletes and order through `_shelf_access`.
9. API note appended to `backend/docs/circle-api.md`; proof JSON from the dev stack on :8012.
