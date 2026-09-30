# mobile-10 plan

1. Shared data layer (`features/`, no skin imports, tests first): collection model and calls (rules, previews, createdAt, member order PUT), the smart-shelf evaluator, collection order and the recently created sort, the history next-chapter resolver moved out of the legacy screen in its own no-pixel commit, paged history, notification grouping, Updates extras (run, sources, seen ids), bookmark note upsert with the removed-elsewhere error and restore, `notify_enabled` on the profile update.
2. Hub kit: notices, error states (offline, rate limit, correction), greeked galley, hardware-key entries.
3. Updates: the check (live run for admins, unread polling for members), NEW by day and series with typed folios, FOLLOWING, schedule deck, the admin aside from 900 px, states, keys.
4. Collections: plates as strip mosaics (`CineCollectionMosaic`, the match cut's Hero), sorts, Custom order, the New shelf form with rule chips, states, keys.
5. Shelf page: match-cut header, Add series, Edit, Reorder, Select, Delete with the arm, member wall, smart shelves, states, keys.
6. History (the log, time margin, Continue and Next by Dip, Load earlier) and Bookmarks (marginal notes, in-place notes through the outbox, Undo).
7. Wiring: five ids out of `PENDING`; the stop-press banner gets an Overlay so its Dismiss tooltip cannot throw.
8. Tap-target, reduced-motion and text-scale tests; the estimate gate; proof shots and report.
