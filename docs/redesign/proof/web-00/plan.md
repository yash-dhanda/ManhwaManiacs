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

## Deviation found while verifying (final approach after fix pass 1)

Legacy's `AppShell` renders no children on the server (auth gate), so a page's `notFound()` never reached the
server render and `/setup`, `/welcome`, `/circle`, `/settings/profile` and unmatched URLs answered 200. Before the
skins these were Next's own not-found route: status 404, the root layout, and `not-found.tsx` rendered as a page.

Throwing `notFound()` anywhere the server render reaches does not recover that in Next 16.2: the not-found boundary
is a client component, so a thrown 404 during SSR always yields the bare `<html id="__next_error__">` document
(checked for cinematic too, whose Shell renders children). That document is client-rendered whole, so the appearance
boot script never runs ("Encountered a script tag"), the dev overlay shows an issue badge, and with the API
unreachable the shell's picker redirect crashed Next's router ("Rendered more hooks") into the global error screen.
The first fix (an SSR probe in the `(app)` layout throwing `notFound()`) hit exactly that and was reverted.

Final approach, two files outside the prompt's layout, both deleted with legacy at the flip:

- `src/proxy.ts`: for a legacy request (`resolveSkin` of the two cookies, now shared with `getSkin`) whose path has
  no legacy screen (route table built from `SCREENS` in the contract; `LEGACY_LACKS`; `/settings/:section`; anything
  else falls to `[...missing]`), rewrite to `/legacy-not-found` with status 404. Pages only: `_*`, `api`,
  `skin-preview` and any path with a dot are not matched.
- `app/(app)/legacy-not-found/page.tsx`: renders the `(app)/not-found.tsx` screen (and its metadata) as a page for
  legacy, `notFound()` for any other skin.

`[...missing]`, `renderScreen` and legacy's settings wrapper call `notFound()` exactly as the prompt specifies (legacy
never reaches them now; cinematic and glass keep Next's thrown 404). `src/proxy.test.ts` checks the proxy's route
table against every `(app)` route file and the legacy 404 set. Known ceiling: an unmatched legacy URL containing a
dot (`/foo.bar`) is not matched by the proxy and answers 200 (the not-found screen still shows).
