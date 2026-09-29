# web-11 plan (lane L19)

Built on a tree where web/01-web/10 are not integrated. Stand-ins (all marked TODO(step-id)) live in
`frontend/src/skins/cinematic/screens/feature/`: Glyph (web/01), SetHeading (web/03), toasts (web/07),
reader-entry (web/06), standins.tsx (AddToShelfSheet, TagSheet: web/09), tags-standin.ts (web/09),
features/ai/feedback.ts (web/08), library/mark-read.ts (web/09).

Structure: `use-series-page.ts` holds all data and actions for both pages; `FeatureView` picks
`manga/MangaFeature` or `book/BookFeature`; tabs are an array (`FeatureTab[]`) for web/19 and web/22.
Not done: Playwright spec and proof screenshots, phone scroll-snap pager, real Column wipe and match cut,
per-row swipe spring, prefetch through the sources limiter.
