# Web foundation 00: skin engine, route groups and the completeness contract

## Goal

Build the skeleton that lets the web client (`frontend/`, Next.js 16.2.9 + React 19.2.4 + Tailwind 4) run three skins side by side on one data layer: today's UI as the `legacy` skin, plus empty `cinematic` and `glass` skins whose every screen is a skin-neutral "not built yet" placeholder. You add the skin registry and `getSkin()` (which reads the `mm-skin-debug` and `mm-skin` cookies), move every route under a new `app/(app)/` root layout and add an `app/(preview)/` root layout stub, turn every route file into a thin file that renders `skins[await getSkin()].screens.<ScreenId>`, stamp `<html data-skin>` on the server, wire the generated design CSS into `app/globals.css`, add the lint boundary around `src/skins/**` and a Vitest completeness test over `SCREEN_IDS`. Nothing looks or behaves differently for a legacy user: same URLs, same status codes, same pixels. The new skins are reachable only by setting the `mm-skin-debug` cookie by hand (the debug row that sets it arrives in web/02).

## Read first

Read these before you plan. Section numbers are binding.

1. `docs/redesign/stack-decision.md` §2.2 (web folder layout, the lint boundary, completeness), §2.4 (where the skin choice is stored, boot resolution), §3 ("What happens to the existing feature layers", release model).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §8.0.3 (the route contract: every ScreenId and path; `setup` is a server redirect to `/login` on the web; the `/` → `/library` redirect with the two-cookie `missing` list),
   - §8.0.7 (the `glass_available` flag and the pre-flip debug row; a profile whose skin is `glass` renders Cinematic while the flag is false),
   - §8.30.3, the bullet list under "How the route is built" (two root layouts, pages move under `app/(app)/`, root files that stay at `app/`, the `[...missing]` catch-all 404, the preview layout),
   - §8.32 (404 inside the frame),
   - §15.2 (web file table, the paragraphs "Outside the skin folder", "View transitions" and "Home route"),
   - §15.10 rows S7 and S17.
3. `docs/redesign/glass/DESIGN.md` §15.2 (the Glass skin folder shape and its lint line), §15.6 first two bullets (routes and screen ids are shared), §15.10 row G7.
4. `docs/redesign/inventory/00-decisions.md` (binding owner decisions).
5. `docs/redesign/inventory/web.md` §0, §1 (route table R0–R27, E1–E4), §2.1 (frame selector and guards G1–G13).
6. `docs/redesign/00-baseline.md` (health baseline and RAM figures).
7. What the upstream steps left (read, do not rewrite): `frontend/src/skins/contract.generated.ts` (exports `SCREEN_IDS`, the `ScreenId` type, `ROUTES`, `FLAGS`, `HapticEvent`, `SoundEvent`), `frontend/src/skins/theme.generated.css`, `frontend/src/skins/cinematic/tokens.generated.{css,ts}`, `frontend/src/skins/glass/tokens.generated.{css,ts}` (present only if shared/01 has run), `design/contract.json`, `design/build.mjs`, `backend/scripts/README-dev-stack.md` (dev stack and demo credentials).
8. Today's code you move: `frontend/src/app/**` (every `page.tsx`, `layout.tsx`, `error.tsx`, `not-found.tsx`, `providers.tsx`, `globals.css`), `frontend/next.config.ts`, `frontend/eslint.config.mjs`, `frontend/vitest.config.ts`, `frontend/src/components/layout/app-shell.tsx`, `frontend/src/features/preferences/appearance-boot.tsx`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git status --short                  # clean, except files other sessions are editing outside frontend/
git branch --show-current           # feat/vps-slim-source-native
ls frontend/src/skins/contract.generated.ts frontend/src/skins/theme.generated.css frontend/src/skins/cinematic/tokens.generated.css
grep -n "SCREEN_IDS\|FLAGS" frontend/src/skins/contract.generated.ts | head
ls backend/scripts/dev_stack.sh backend/scripts/seed_demo.py backend/scripts/README-dev-stack.md
```

If `contract.generated.ts` or `theme.generated.css` is missing, shared/00 has not run. If the dev stack scripts are missing, backend/00 has not run. Report which and stop.

## Skills to invoke

- `superpowers:writing-plans` before touching code. Save the plan at `docs/redesign/proof/web-00/plan.md` and commit it with the first code commit.
- `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you work inline). Give each subagent this file's path and the exact section of it that its slice covers. Verify every subagent's work against `git status` and `git diff`, never against its report.
- `impeccable` and `taste-skill:taste-skill` only for the one visible element this step adds (the pending screen); keep it plain and skin-neutral.
- `frontend-design` is not needed beyond the pending screen.
- `superpowers:verification-before-completion` before you claim anything is done.

## Scope, item by item

### A. Skin types, registry and `getSkin()`

1. `frontend/src/skins/types.ts`
   - `export const SKIN_IDS = ["cinematic", "glass", "legacy"] as const; export type SkinId = (typeof SKIN_IDS)[number];`
   - `export function isSkinId(value: unknown): value is SkinId`.
   - `export const DEFAULT_SKIN: SkinId = "legacy";` with the comment `// release/00 changes this to "cinematic" and deletes "legacy".`
   - `export const SKIN_COOKIE = "mm-skin"; export const SKIN_DEBUG_COOKIE = "mm-skin-debug";`
   - `export interface ScreenProps { screenId: ScreenId; params: Promise<Record<string, string | string[]>>; searchParams: Promise<Record<string, string | string[] | undefined>>; variant?: "browse"; }`
   - `export type Screen = (props: ScreenProps) => React.ReactNode | Promise<React.ReactNode>;`
   - `export interface Skin { id: SkinId; fontClassName: string; Shell: React.ComponentType<{ children: React.ReactNode }>; screens: Partial<Record<ScreenId, Screen>>; }` (the cinematic and glass objects narrow `screens` to the full record; see B).
2. `frontend/src/skins/index.ts`: `export const skins = { cinematic, glass, legacy } satisfies Record<SkinId, Skin>;`. Server-only by convention: client components never import `@/skins` or `@/skins/server`; they import `@/skins/types` or their own skin's modules. Write that rule as the file's header comment.
3. `frontend/src/skins/server.ts`:
   - `getSkin(): Promise<SkinId>` using `cookies()` from `next/headers`. Precedence, exactly: (1) `mm-skin-debug` when it holds a valid `SkinId` (any of the three, `glass` included, because the debug row is how Glass is previewed before it ships); (2) `mm-skin` when valid, except that `glass` resolves to `cinematic` while `FLAGS.glassAvailable` is false (cinematic §8.0.7); (3) `DEFAULT_SKIN`. Invalid values are ignored.
   - `renderScreen(id: ScreenId, props: RouteProps, variant?: "browse")`: resolves the skin, looks up `skins[skin].screens[id]`, calls `notFound()` from `next/navigation` when the skin has no such screen (only `legacy` can lack one), and returns `createElement(screen, { screenId: id, variant, ...props })`. Use `createElement`, so the file stays `.ts`.
   - `export type RouteProps = { params: Promise<Record<string, string | string[]>>; searchParams: Promise<Record<string, string | string[] | undefined>> };`

### B. The three skins

4. `frontend/src/skins/pending.tsx` (`"use client"`), one skin-neutral screen used for every unbuilt ScreenId of both new skins. It imports nothing from `@/components`, `@/features` or any skin folder. Layout: `min-height: 100dvh`, background `#000000`, text `#F5F5F5`, font `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`, padding 24 px, one column of max-width 560 px centred vertically and horizontally, 16 px gaps. Content, top to bottom:
   - kicker, 12 px / 16 px, weight 600, uppercase, letter-spacing 0.16em, `rgba(255,255,255,0.64)`: `{SKIN} · NOT BUILT YET`, where SKIN is `document.documentElement.dataset.skin` upper-cased (read in an effect; render `PREVIEW` on the server);
   - `h1`, 28 px / 34 px, weight 600: the `screenId` prop;
   - paragraph, 16 px / 24 px, `rgba(255,255,255,0.64)`: "This screen hasn't been built in this edition yet. It arrives in a later step of the redesign.";
   - the current path from `usePathname()` in `ui-monospace, "SF Mono", Menlo, monospace` 13 px;
   - a button "Leave the preview" that expires `mm-skin-debug` (`document.cookie = "mm-skin-debug=; Path=/; Max-Age=0; SameSite=Lax; Secure"`) and calls `location.reload()`. Minimum 44 px tall, padding 0 20 px, 1 px border `rgba(255,255,255,0.40)`, transparent fill, radius 0, text 15 px weight 600. Hover: border `rgba(255,255,255,0.80)`. Focus: `:focus-visible` outline 2 px solid `#FFFFFF`, offset 2 px. Put the three state rules in `frontend/src/skins/pending.module.css` using class selectors only (Turbopack rejects impure CSS-module selectors, and `tsc`/`eslint` do not catch that; only `next build` does).
   - No animation of any kind.
5. `frontend/src/skins/setup-redirect.ts`: `export default function SetupRedirect(): never { redirect("/login"); }` (cinematic §8.0.3 `setup`, §15.10 S7).
6. `frontend/src/skins/pending-shell.tsx`: `export function PendingShell({ children }) { return <>{children}</>; }`. Cinematic's real Shell replaces it in web/06, Glass's in web/29.
7. `frontend/src/skins/cinematic/index.ts` and `frontend/src/skins/glass/index.ts`, identical in shape:
   - `export const PENDING = new Set<ScreenId>([...])` listing every ScreenId except `setup`.
   - `export const screens = { setup: SetupRedirect, login: Pending, register: Pending, … } satisfies Record<ScreenId, Screen>;` as one object literal with one line per ScreenId, so a missing ScreenId is a type error. Every id in `PENDING` maps to `Pending` (the default export of `../pending`), and nothing else does. Finishing a screen in a later step means two edits in this file: map the id to the real screen, and delete it from `PENDING`.
   - `export const cinematic: Skin = { id: "cinematic", fontClassName: "", Shell: PendingShell, screens };` (and `glass` likewise). `fontClassName` stays `""` until web/01 fills it.
8. `frontend/src/skins/legacy/index.ts` maps each ScreenId that exists today to today's page body. Build it this way:
   - `git mv` every existing `frontend/src/app/**/page.tsx` to `frontend/src/skins/legacy/pages/<slug>.tsx` (slugs in the route table below). Keep each body verbatim, except for three things: relative imports become `@/` imports; dynamic parameter names change where the folder was renamed (table); and a static `export const metadata` moves back to the thin route file (see C).
   - `legacy/index.ts` imports those files and exports `legacy: Skin` with `screens: Partial<Record<ScreenId, Screen>>`, `Shell: AppShell` (from `@/components/layout/app-shell`) and `fontClassName` from `legacy/fonts.ts`.
   - `library` is a wrapper: when `variant === "browse"` it renders the moved `library-browse.tsx` body, otherwise `library.tsx`. Write it with `createElement` so the file stays `.ts`.
   - `settings` is a wrapper that calls `notFound()` when a `section` param is present, so `/settings/anything` stays a 404 for legacy users exactly as today (web/02 adds the one diagnostics exception).
   - Screens that do not exist today are absent from the legacy map: `setup`, `onboarding`, `tonight`, `profileNew`, `profileEdit`, `annual`, `recap`, `circle`, `circleMember`.
   - `frontend/src/skins/legacy/fonts.ts` holds today's `Syne` and `DM_Sans` `next/font/google` calls, moved verbatim from `app/layout.tsx`, and exports `legacyFontClassName = \`${syne.variable} ${dmSans.variable}\``.

### C. Routes

9. Create the two route groups. There is no top-level `app/layout.tsx` any more (cinematic §8.30.3, §15.10 S17).
   - `app/(app)/layout.tsx` is today's root layout, made skin-aware:

     ```tsx
     export default async function AppLayout({ children }: { children: React.ReactNode }) {
       const id = await getSkin();
       const skin = skins[id];
       return (
         <html lang="en" data-skin={id} className={`${skin.fontClassName} antialiased`} suppressHydrationWarning>
           <head><AppearanceBootScript /></head>
           <body>
             <Providers>
               <ServiceWorkerBoundary />
               <skin.Shell>{children}</skin.Shell>
             </Providers>
           </body>
         </html>
       );
     }
     ```

     Keep today's `metadata` object verbatim. Replace the static `viewport` with `export async function generateViewport(): Promise<Viewport>`: for `legacy` it returns today's object exactly (the light/dark `themeColor` pair and `viewportFit: "cover"`); for `cinematic` and `glass` it returns `{ themeColor: "#000000", colorScheme: "dark", viewportFit: "cover" }`. Import `../globals.css`. Keep the comments that explain `suppressHydrationWarning` and the boot script.
   - `app/(app)/error.tsx` and `app/(app)/not-found.tsx` are today's files moved with `git mv`, unchanged. Until a skin's status-screen step replaces them, every skin shows the legacy 404 and error screens. That is expected; it is not a regression.
   - `app/(app)/[...missing]/page.tsx`: `import { notFound } from "next/navigation"; export default function Missing() { notFound(); }`. Unmatched URLs then render `(app)/not-found.tsx` inside the `(app)` layout and Shell. `experimental.globalNotFound` is not used.
   - `app/(preview)/skin-preview/[skin]/layout.tsx`, the second root layout (a stub): `const { skin } = await params;` then `notFound()` unless `skin` is `cinematic` or `glass`; render `<html lang="en" data-skin={skin} className={skins[skin].fontClassName}><body>{children}</body></html>` with no Providers and no Shell; `import "../../../globals.css";`.
   - `app/(preview)/skin-preview/[skin]/page.tsx`: renders the skin-neutral `Pending` screen with `screenId="tonight"` and empty param promises. Comment: `// web/18 replaces this with the skin's real Tonight over the demo-feed fixture (cinematic §8.30.3).`
   - These stay at `app/`: `global-error.tsx`, `manifest.ts`, `favicon.ico`, `globals.css`, `presets.css`, `themes.generated.css`, `providers.tsx`, `motion.test.ts`, `proxy-timeout.test.ts`. Check that both tests still find their files (`motion.test.ts` reads `src/app/globals.css`).
10. Thin route files. Each `page.tsx` under `app/(app)/` is at most about 8 lines: `export default function Page(props: RouteProps) { return renderScreen("<id>", props); }`, plus the static `metadata` export when today's page had one (`downloads` has one; move it back verbatim). If `next build` rejects `RouteProps` against a route's generated `PageProps`, type that file with Next 16's global `PageProps<"/that/route">` instead. Every row of this table is one route file:

| URL | Route file under `app/(app)/` | ScreenId | Legacy body (`skins/legacy/pages/`) |
|---|---|---|---|
| `/` | `page.tsx` | `tonight` | none |
| `/setup` | `setup/page.tsx` | `setup` | none |
| `/login` | `login/page.tsx` | `login` | `login.tsx` |
| `/register` | `register/page.tsx` | `register` | `register.tsx` |
| `/profiles` | `profiles/page.tsx` | `profiles` | `profiles.tsx` |
| `/profiles/new` | `profiles/new/page.tsx` | `profileNew` | none |
| `/profiles/:id/edit` | `profiles/[id]/edit/page.tsx` | `profileEdit` | none |
| `/profiles/manage` | `profiles/manage/page.tsx` | `profilesManage` | `profiles-manage.tsx` |
| `/welcome` | `welcome/page.tsx` | `onboarding` | none |
| `/library` | `library/page.tsx` | `library` | `library.tsx` |
| `/library/browse` | `library/browse/page.tsx` (passes `variant: "browse"`) | `library` | `library-browse.tsx` |
| `/library/:followedId` | `library/[followedId]/page.tsx` (folder renamed from `[seriesId]`) | `featureByFollow` | `library-followed.tsx` (reads `followedId`) |
| `/library/collections` | `library/collections/page.tsx` | `collections` | `collections.tsx` |
| `/library/collections/:id` | `library/collections/[id]/page.tsx` (renamed from `[collectionId]`) | `collection` | `collection.tsx` (reads `id`) |
| `/library/history` | `library/history/page.tsx` | `history` | `history.tsx` |
| `/library/bookmarks` | `library/bookmarks/page.tsx` | `bookmarks` | `bookmarks.tsx` |
| `/library/recommendations` | `library/recommendations/page.tsx` | `picks` | `picks.tsx` |
| `/library/statistics` | `library/statistics/page.tsx` | `numbers` | `numbers.tsx` |
| `/library/statistics/annual/:year` | `library/statistics/annual/[year]/page.tsx` | `annual` | none |
| `/recap/:sourceId/:seriesKey` | `recap/[sourceId]/[seriesKey]/page.tsx` | `recap` | none |
| `/circle` | `circle/page.tsx` | `circle` | none |
| `/circle/:profileId` | `circle/[profileId]/page.tsx` | `circleMember` | none |
| `/search` | `search/page.tsx` | `discover` | `discover.tsx` |
| `/sources` | `sources/page.tsx` | `sources` | `sources.tsx` |
| `/sources/:sourceId` | `sources/[sourceId]/page.tsx` | `source` | `source.tsx` |
| `/sources/:sourceId/series/:seriesKey` | `sources/[sourceId]/series/[seriesKey]/page.tsx` (renamed from `[seriesId]`) | `feature` | `feature.tsx` (reads `seriesKey`) |
| `/reader` | `reader/page.tsx` | `readerLanding` | `reader-landing.tsx` |
| `/reader/:sourceId/:seriesKey/:chapterKey` | `reader/[sourceId]/[seriesKey]/[...chapterKey]/page.tsx` (catch-all kept: chapter keys can hold `/`) | `reader` | `reader.tsx` |
| `/read-all/:sourceId/:seriesKey` | `read-all/[sourceId]/[seriesKey]/page.tsx` | `readAll` | `read-all.tsx` |
| `/novels/:sourceId/:seriesKey/:chapterKey` | `novels/[sourceId]/[seriesKey]/[...chapterKey]/page.tsx` | `novel` | `novel.tsx` |
| `/updates` | `updates/page.tsx` | `updates` | `updates.tsx` |
| `/downloads` | `downloads/page.tsx` | `downloads` | `downloads.tsx` |
| `/ocr` | `ocr/page.tsx` | `dialogue` | `dialogue.tsx` |
| `/more` | `more/page.tsx` | `index` | `index-hub.tsx` |
| `/settings` | `settings/page.tsx` | `settings` | `settings.tsx` |
| `/settings/:section` | `settings/[section]/page.tsx` | `settings` | the same wrapper (404 for legacy) |
| `/admin/status` | `admin/status/page.tsx` | `status` | `admin-status.tsx` |

   - The co-located modules in `app/admin/status/` (`StatusView.tsx`, `api.ts`, `hooks.ts`, `status.ts`, `status.test.ts`) move with the folder to `app/(app)/admin/status/`; `admin-status.tsx` imports `@/app/(app)/admin/status/StatusView`.
   - If `contract.generated.ts` lists a ScreenId or path that differs from this table, the generated file wins: add or adjust the route file and note it in the report.
   - `ROUTES` builders from `contract.generated.ts` are the only way new code builds paths. This step builds none.
11. `frontend/next.config.ts`:
   - `redirects()` keeps the `/` → `/library` redirect (`permanent: false`) only for legacy: `missing: [{ type: "cookie", key: "mm-skin", value: "(cinematic|glass)" }, { type: "cookie", key: "mm-skin-debug", value: "(cinematic|glass)" }]`. Next skips the redirect when either cookie matches. Replace the long comment above it with one that names the two-cookie rule and says release/00 deletes `redirects()`.
   - `experimental: { proxyTimeout: 120_000, viewTransition: true }` (cinematic §15.2 "View transitions"; off by default in 16.2.9).
   - `rewrites()` stays the array form (`afterFiles`), so the `[...missing]` catch-all never swallows `/api/*`. Do not change it.

### D. CSS wiring and the legacy bridge

12. `frontend/src/app/globals.css`: add, among the `@import` lines at the top and before the legacy `@theme {` block, in this order:
    `@import "../skins/theme.generated.css";`, `@import "../skins/cinematic/tokens.generated.css";`, `@import "../skins/glass/tokens.generated.css";` (only if that file exists now; otherwise web/02 adds the line), `@import "../skins/legacy-bridge.css";`.
    The generated theme's `@theme inline` block must come **before** legacy's `@theme` block, because Tailwind keeps the last definition of a key and legacy must keep its own values for the keys both define.
13. The key collision. These keys are defined by legacy `@theme` and by `theme.generated.css`: `--font-display` (Cinematic), and for Glass `--color-success`, `--color-warning`, `--color-danger`, `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-xl`, plus whatever else the generated file adds (compute the list; do not trust this one). Legacy wins in Tailwind (item 12), so `font-display` compiles to `font-family: var(--font-display)`. Each new skin then points the shared variable at its own token in `frontend/src/skins/legacy-bridge.css`, which is unlayered and so beats Tailwind's `@layer theme`:

    ```css
    /* Deleted at the flip together with legacy's @theme (release/00). */
    html[data-skin="cinematic"] { --font-display: var(--mm-font-display); }
    html[data-skin="glass"] { --color-success: var(--mm-color-success); /* … one line per overlapping key … */ }
    ```

    The `html[data-skin]` selector (specificity 0,1,1) also beats legacy's `[data-theme]` and `[data-preset]` rules (0,1,0) in `themes.generated.css` and `presets.css`.
14. `frontend/src/skins/legacy-bridge.test.ts` (Vitest, node): read `src/app/globals.css`, collect every key declared in its plain `@theme {…}` blocks, read `src/skins/theme.generated.css`, collect the keys of its `@theme inline {…}` block with their `var(--mm-…)` targets, and take the overlap. For each overlapping key, find which skin's `tokens.generated.css` declares the target `--mm-…` property, then assert that `legacy-bridge.css` has an `html[data-skin="<that skin>"]` rule declaring the key as `var(<target>)`. Also assert that the generated import line comes before the legacy `@theme {` line in `globals.css`.

### E. Lint boundary

15. `frontend/eslint.config.mjs`: add `no-restricted-imports` blocks (stack-decision §2.2; glass §15.2 "Lint"):
    - `files: ["src/skins/cinematic/**"]`: `patterns` banning `@/components`, `@/components/**`, `@/features/*/components`, `@/features/*/components/**`, `@/features/*` (bare feature barrels, which re-export legacy components; import the data module by its path instead, for example `@/features/library/hooks`), `@/app/**`, `@/skins`, `@/skins/server`, `@/skins/glass`, `@/skins/glass/**`, `@/skins/legacy`, `@/skins/legacy/**`, `../glass/**`, `../legacy/**`, `../../glass/**`, `../../legacy/**`, `../../../glass/**`, `../../../legacy/**`. Give each pattern group a `message` saying what to import instead.
    - `files: ["src/skins/glass/**"]`: the same with `cinematic` in place of `glass`.
    - `files: ["src/skins/pending.tsx", "src/skins/pending-shell.tsx", "src/skins/setup-redirect.ts"]`: ban `@/components/**`, `@/features/**`, `@/app/**` and all three skin folders.
    - `src/skins/legacy/**`, `src/skins/index.ts`, `src/skins/server.ts` and `src/skins/types.ts` get no block.

### F. Completeness test

16. `frontend/src/skins/completeness.test.ts` (Vitest, node). Import `SCREEN_IDS` from `./contract.generated`, `screens as cine, PENDING as cinePending` from `./cinematic/index`, and the same from `./glass/index`. Never import `./index` or `./legacy/*`; that would pull the whole legacy tree into node. Assert:
    - each skin's `screens` has exactly the keys in `SCREEN_IDS` (no extra, none missing), and every value is a function;
    - `PENDING` is a subset of `SCREEN_IDS`, and it equals exactly the set of ids whose screen `=== Pending` (so the set and the map cannot drift);
    - `screens.setup` is `SetupRedirect` in both skins;
    - a `MUST_BE_COMPLETE = { cinematic: false, glass: false }` constant at the top of the file with the comment `// web/24 sets cinematic to true, web/45 sets glass to true (release gates).` When a flag is true, that skin's `PENDING.size` must be 0.
    - The test prints `cinematic pending: N / total` and `glass pending: N / total` with `console.info`.

## File layout (create or change; nothing else)

```
frontend/next.config.ts                                        change (redirect cookies, viewTransition)
frontend/eslint.config.mjs                                     change (skin boundary blocks)
frontend/src/app/globals.css                                   change (four @import lines)
frontend/src/app/layout.tsx                                    git mv → src/app/(app)/layout.tsx, then edit
frontend/src/app/error.tsx, not-found.tsx                      git mv → src/app/(app)/
frontend/src/app/<every route folder>                          git mv → src/app/(app)/<folder> (renames per the table)
frontend/src/app/(app)/[...missing]/page.tsx                   new
frontend/src/app/(app)/<new routes from the table>/page.tsx    new, thin
frontend/src/app/(preview)/skin-preview/[skin]/layout.tsx      new (stub root layout)
frontend/src/app/(preview)/skin-preview/[skin]/page.tsx        new (stub)
frontend/src/skins/types.ts, index.ts, server.ts               new
frontend/src/skins/pending.tsx, pending.module.css             new
frontend/src/skins/pending-shell.tsx, setup-redirect.ts        new
frontend/src/skins/legacy-bridge.css, legacy-bridge.test.ts    new
frontend/src/skins/completeness.test.ts                        new
frontend/src/skins/cinematic/index.ts                          new
frontend/src/skins/glass/index.ts                              new
frontend/src/skins/legacy/index.ts, fonts.ts                   new
frontend/src/skins/legacy/pages/*.tsx                          git mv from app/**/page.tsx
docs/redesign/proof/web-00/plan.md                                  new (the plan)
docs/redesign/proof/web-00/*.png                               new (screenshots)
```

Do not touch `frontend/src/components/**` or `frontend/src/features/**` in this step, apart from the import-path fixes that moved files force.

## Acceptance criteria

- [ ] `npm run typecheck`, `npm run lint`, `npm run test` and `npm run build` pass in `frontend/`. The Vitest file and case counts are at least the counts you recorded before your first change, and no test that passed before fails.
- [ ] No top-level `app/layout.tsx` exists. `app/(app)/layout.tsx` and `app/(preview)/skin-preview/[skin]/layout.tsx` both import `globals.css`.
- [ ] With no skin cookie (legacy): `curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n"` against the dev server returns `307 …/library` for `/`, `404` for `/setup`, `/welcome`, `/circle`, `/settings/profile` and `/no-such-page`, and `200` for `/login`. The 404 page renders inside the legacy shell, as today.
- [ ] Legacy pixel parity: the before and after screenshots of every route in the proof list are identical apart from live data (times, counts). You compare each pair by viewing both images.
- [ ] With `mm-skin-debug=cinematic`: `/` returns 200 and renders the pending screen for `tonight`; `/setup` redirects to `/login`; `/library` renders the pending screen for `library`; `<html>` carries `data-skin="cinematic"`; an unmatched URL renders the 404 inside the `(app)` layout.
- [ ] With `mm-skin=glass` and no debug cookie, the page renders `data-skin="cinematic"` (`FLAGS.glassAvailable` is false). With `mm-skin-debug=glass`, it renders `data-skin="glass"` and the pending screen.
- [ ] `/skin-preview/cinematic` and `/skin-preview/glass` render the pending `tonight` screen inside their own root layout (`<html data-skin>` set from the URL, no Shell). `/skin-preview/legacy` and `/skin-preview/x` return 404.
- [ ] The built CSS keeps legacy's variables: `find frontend/.next/static -name '*.css' | xargs grep -ho '\.font-display{[^}]*}\|\.rounded-lg{[^}]*}'` shows `var(--font-display)` and `var(--radius-lg)`, and `legacy-bridge.test.ts` passes.
- [ ] The lint boundary bites. A throwaway `frontend/src/skins/cinematic/__probe.tsx` importing `@/components/ui/kbd`, `@/features/library` and `@/skins/glass` gives three `no-restricted-imports` errors under `npx eslint src/skins/cinematic/__probe.tsx`. Delete the probe and do not commit it.
- [ ] `completeness.test.ts` passes. Both skins list every ScreenId except `setup` in `PENDING`.
- [ ] Keyboard (web): on the pending screen, Tab reaches "Leave the preview", the focus ring (2 px `#FFFFFF`, 2 px offset) is visible, and Enter or Space expires the debug cookie and reloads into legacy.
- [ ] Hit target: "Leave the preview" is at least 44 px tall at 390 × 844.
- [ ] Reduced motion: this step adds no animation. The pending screen is identical with `prefers-reduced-motion: reduce`.
- [ ] Per-skin differences: legacy renders `AppShell` and today's fonts; cinematic and glass render `PendingShell`, `data-skin` set to their id, `themeColor` `#000000`, and no legacy font classes on `<html>`.
- [ ] `git grep -n "framer-motion" frontend/src/skins` is empty (this step adds no motion code).

## Verification

Run every heavy command on its own, never two at once, and check memory first. Production shares this box.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
free -m     # stop if the "available" column is under 1024 MB; wait and re-check
npm run test 2>&1 | tail -5         # BEFORE any change: record files/cases passed
# … implement …
free -m && npm run typecheck
free -m && npm run lint             # baseline: exit 0, 0 errors, 0 warnings
free -m && npm run test
free -m && npm run build            # baseline: exit 0; never while another next build or next dev runs
```

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff (mobile, backend and shared sessions commit on the same branch): `git show --stat --format= <hash>` for each of your commits must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** `frontend/scripts/proof.mjs` does not exist until web/03, so use this one-off script. Save it as `/tmp/mm-shoot.mjs` and do not commit it.

```js
// node /tmp/mm-shoot.mjs <outDir> <skin|none> <route> [<route> …]
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
const require = createRequire("/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/package.json");
const { chromium } = require("playwright");
const [outDir, skin, ...routes] = process.argv.slice(2);
const BASE = process.env.MM_BASE ?? "http://127.0.0.1:3010";
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch();
for (const [w, h] of [[1440, 900], [390, 844]]) {
  const ctx = await browser.newContext({ viewport: { width: w, height: h } });
  if (skin !== "none") await ctx.addCookies([{ name: "mm-skin-debug", value: skin, url: BASE }]);
  const page = await ctx.newPage();
  const login = await page.request.post(`${BASE}/api/auth/login`, {
    data: { username: process.env.MM_USER, password: process.env.MM_PASS },
  });
  if (!login.ok()) throw new Error(`login ${login.status()}`);
  const me = await (await page.request.get(`${BASE}/api/auth/me`)).json();
  const [p] = await (await page.request.get(`${BASE}/api/profiles`)).json();
  await page.goto(`${BASE}/login`);
  await page.evaluate(([p, uid]) => localStorage.setItem("mm.active-profile", JSON.stringify({
    state: { activeProfile: { id: p.id, name: p.name, avatar_key: p.avatar_key, mood: p.mood }, ownerUserId: uid },
    version: 0,
  })), [p, me.id ?? me.user?.id]);
  for (const route of routes) {
    await page.goto(`${BASE}${route}`, { waitUntil: "networkidle" });
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(1500);
    const slug = route === "/" ? "home" : route.slice(1).replace(/[/?=&]/g, "-");
    await page.screenshot({ path: `${outDir}/${skin}-${slug}-${w}x${h}.png` });
  }
  await ctx.close();
}
await browser.close();
```

Check the persisted shape against `frontend/src/features/profiles/store.ts` (`partialize` keeps `activeProfile` and `ownerUserId`; use its `version`, 0 when none is set). If Chromium is missing (`ls ~/.cache/ms-playwright`), run `npx playwright install chromium` in `frontend/`.

1. Start the dev stack as `backend/scripts/README-dev-stack.md` says (uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data). Set `MM_USER` and `MM_PASS` to the demo credentials that README documents.
2. **Before** your first change: `free -m`, then `cd frontend && BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010` in the background. Then run `node /tmp/mm-shoot.mjs docs/redesign/proof/web-00/before none /library /library/browse /library/history /settings /profiles /search /sources /downloads /more /reader /no-such-page`. Stop `next dev` before any `npm run build`.
3. **After**: the same command into `docs/redesign/proof/web-00/after`, then `node /tmp/mm-shoot.mjs docs/redesign/proof/web-00/after cinematic / /library /setup /no-such-page` and the same for `glass`.
4. Compare every before/after legacy pair.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one working step per commit, for example: skin types and registry; pending screen; route move with `git mv` (a pure move commit, so history follows the files); thin routes; next.config; CSS wiring and bridge; lint boundary; completeness test; proof. Push after each working step: `git push origin feat/vps-slim-source-native`.
- Stage only your own paths explicitly (`git add frontend/src/skins frontend/src/app frontend/next.config.ts frontend/eslint.config.mjs docs/redesign/proof/web-00/plan.md docs/redesign/proof/web-00`). Never `git add -A` or `git add .`: mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By`, no "Generated with" line, no AI author. Never commit secrets, `.env*` files or `.claude/`.
- `npm run build` must pass before every push.

## Guardrails

- Work in `frontend/` only (and `docs/redesign/proof/`). Never edit `backend/connectors/`, `mobile/`, `design/` sources, or generated files by hand (regenerate with `node design/build.mjs` if you need to).
- Never touch production: no Docker commands, nothing under `/srv/manhwamaniacs/{app,data}`.
- RAM guard: `free -m` before every build, test run and dev server start. Stop if available memory is under 1024 MB. Never run two builds, or a build and `next dev`, at the same time.

## Report back

Reply with:
1. Done items, by the letters A–F above, each with its commit hash.
2. The route move: the list of `git mv` pairs, and any ScreenId or path where `contract.generated.ts` differed from the table.
3. The overlapping theme keys the bridge covers, per skin.
4. Screenshot folder `docs/redesign/proof/web-00/` (before, after, cinematic, glass) and the result of the before/after comparison.
5. Test counts before and after (Vitest files and cases), lint and build results, and the lowest `free -m` available figure you saw.
6. Open issues, including anything you deferred and why.

Next prompt in the web track: `docs/redesign/prompts/web/01-foundation-motion-deps-fonts-icons.md` (it also needs `docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md` done). Next in the global order: `docs/redesign/prompts/mobile/00-foundation-reader-engine-extraction.md`.
