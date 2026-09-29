# web/26 plan

1. Foundation of the step: `usePress` (states by data attribute, swell and sink on `press`, cancel at 1.5 x hit, keyboard as click), `lit.ts`, `GlassBudgetScope`, `announce`, `shake`, `useErrorFlash`, shared `press.css` with the cursor contract.
2. Pure pieces first, tested: `hold.ts`, `poster-throw.ts`, `wave.ts`, `segmented-math.ts`, `rail-columns.ts`, press math.
3. Components by family, one commit each: progress and badges and orbs, icon buttons and tooltip, buttons and hold, fields and search, chips and segmented, reveals, posters, rails, cards.
4. Gallery (`/dev/glass-primitives`), then `glass-reveals.spec.ts` and `glass-primitives.spec.ts`, then proof.
Stand-ins (web/01 not integrated): `primitives/Icon.tsx` (TODO web/01), `@base-ui/react` and `@phosphor-icons/react` pinned in package.json.
