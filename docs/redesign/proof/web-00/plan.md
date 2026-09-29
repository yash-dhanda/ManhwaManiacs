# web/00 plan: skin engine, route groups, completeness contract

Source: `docs/redesign/prompts/web/00-foundation-skin-engine-and-routes.md`. Worked inline, lane web1
(API 8013, web 3013, data `/srv/manhwamaniacs/dev/data-web1/`).

Baseline (before any change): Vitest 159 files / 2810 tests pass. Legacy curls: `/` 307 → `/library`,
`/setup` `/welcome` `/circle` `/settings/profile` `/no-such-page` 404, `/login` 200. Before screenshots in
`before/`.

## Steps (one commit each)

1. **Route move (pure `git mv`).** Every `app/**/page.tsx` → `skins/legacy/pages/<slug>.tsx` (slugs from the
   prompt's route table); `layout.tsx`, `error.tsx`, `not-found.tsx` and the `admin/status` co-located modules →
   `app/(app)/`. No content changes in this commit.
2. **Skin types, pending screen, new skins.** `skins/types.ts`, `pending.tsx` + `pending.module.css`
   (class selectors only), `pending-shell.tsx`, `setup-redirect.ts`, `cinematic/index.ts`, `glass/index.ts`
   (`PENDING` = every ScreenId but `setup`; `screens satisfies Record<ScreenId, Screen>`), `completeness.test.ts`.
3. **Legacy skin, registry, resolver, routes.** Legacy page edits (param renames `seriesId`→`followedId`,
   `collectionId`→`id`, `seriesId`→`seriesKey`; `./StatusView` → `@/app/(app)/admin/status/StatusView`; downloads
   `metadata` back to its route file), `legacy/fonts.ts`, `legacy/index.ts` (`library` browse wrapper, `settings`
   404-on-section wrapper), `skins/index.ts`, `skins/server.ts` (`getSkin` precedence debug → mirror with glass
   gate → default; `renderScreen`), `(app)/layout.tsx` skin-aware with `generateViewport`, `[...missing]`,
   `(preview)/skin-preview/[skin]` stub, one thin `page.tsx` per table row.
4. **next.config.** `/` redirect only when neither cookie holds `cinematic|glass`; `viewTransition: true`.
5. **CSS wiring and bridge.** Generated imports ahead of legacy `@theme`; `legacy-bridge.css`; `legacy-bridge.test.ts`.
   Overlap computed from the files, owner = the skin whose `tokens.generated.css` declares or references the
   target; keys no existing tokens file mentions belong to Glass while `glass/tokens.generated.css` is absent.
6. **Lint boundary.** `no-restricted-imports` blocks for cinematic, glass and the neutral pending files; probe check.
7. **Proof.** After screenshots (legacy, cinematic, glass), curls, build CSS grep, keyboard + hit-target check.

## Verification

`npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` under the web lock, one at a time, RAM guard
first. Dev server `next dev -p 3013` against the lane backend on 8013, browsed via `localhost` (Next 16 blocks
dev resources to `127.0.0.1` without `allowedDevOrigins`).

## Deviation found while verifying

Legacy's `AppShell` renders no children on the server (auth gate), so a page's `notFound()` never reached the
HTML shell and `/setup`, `/circle`, `/settings/profile` and unmatched URLs answered 200. Fix: two files outside the
prompt's layout, `skins/screen-status.ts` (a per-request `cache()`d promise settled by `renderScreen`, by
`markScreenMissing` in `[...missing]`, and by legacy's self-settling settings wrapper) and
`skins/not-found-status.tsx` (an SSR-only probe in the `(app)` layout, outside the Shell, that throws `notFound()`
when the screen is missing). `completeness.test.ts` checks every `(app)` route file settles the status.
