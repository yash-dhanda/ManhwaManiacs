# web/06 plan

Slices, in commit order: (1) lib moves, single-key guard, not-available, capabilities; (2) pure modules with tests
(frames, nav-map, g-sequence, wipe-geometry, splash-timeline); (3) shell state + Gate + Shell frames; (4) Sidebar + running head;
(5) thumb index, focus, skip link, mood; (6) view transitions + overlays (dip, column wipe, iris); (7) global keys, palette, keyboard sheet;
(8) status screens + NotAvailableNotice; (9) stop-press, first-run, rating-card host; (10) splash, timings overlay, smooth wheel;
(11) gallery + e2e + proof.
Interfaces first: `shell-state.ts` (zustand), `running-head-context.tsx`, `use-cine-router.ts`, `CineLink.tsx`. Pure logic is test-first.
