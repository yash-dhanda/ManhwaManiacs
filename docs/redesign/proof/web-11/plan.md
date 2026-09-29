# web-11 plan (lane L19)

Built on a tree where web/03-web/10 are not integrated (the lane's waitFor list holds web/01 and web/02 only).
web/01 is integrated: the series pages use the real Cinematic `Icon` roles (Glyph.tsx is a name map onto them).
The remaining stand-ins are marked `TODO(step-id)` in `frontend/src/skins/cinematic/screens/feature/`:
SetHeading (web/03), the single-key setting (web/03, use-feature-keys.tsx), toasts (web/07), reader-entry (web/06,
it is the real Column wipe; only the `motion.ts` re-export is missing), standins.tsx AddToShelfSheet and TagSheet
(web/09), tags-standin.ts (web/09), features/ai/feedback.ts (web/08), library/mark-read.ts (web/09).

Structure: `use-series-page.ts` holds all data and actions for both pages; `FeatureView` picks
`manga/MangaFeature` or `book/BookFeature`; tabs are an array (`FeatureTab[]`) for web/19 and web/22.
The manga hero is `FeatureSpread` (desktop, tablet) or `FeaturePhoneHero` (phone), both around `FeatureBody`.

Fix pass 1 added: Column wipe (`wipe.ts`), match cut / Page in / Page out (`view-transitions.css` + React
`ViewTransition` around the cover and the page), the motion-timings overlay (`MotionTimings.tsx`, mod+shift+m),
the P3 prefetch limiter (`features/sources/p3-limiter.ts`: two in flight, hover/focus dwell 150 ms, the first two
rows on load, P1 on press), the phone tab pager (scroll-snap), the swipe slab (`swipe-row.ts`), keys through the app
keyboard registry (group "Series"), the download-marks gallery under `/skin-preview/cinematic/download-marks`, and
`frontend/e2e/cinematic/web-11-series.spec.ts` with fixtures in `frontend/e2e/fixtures/series/`.
