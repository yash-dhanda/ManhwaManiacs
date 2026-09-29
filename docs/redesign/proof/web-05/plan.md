# web/05 plan and record

Lane L02, branch redesign/L02. Scope items 1-14 of `docs/redesign/prompts/web/05-cinematic-primitives-overlays-controls-states.md`.

## Sheet path

Path taken: Base UI `Dialog` plus `useSheetDrag` (`@use-gesture/react` 10.3.1 `useDrag` and Motion `animate`), not `Drawer`.
Read `node_modules/@base-ui/react/drawer/**/*.d.ts`: the Drawer exposes snap points and a swipe direction, but no prop for a 30 % / 800 px/s
dismissal rule, the `d * (1 - 1 / (x * 0.35 / d + 1))` rubber band, or a `spring.sheet` release. The behaviour in the prompt is fixed, so the
drag is ours; this is the same decision cinematic/DESIGN.md 7.9 records for Flutter's `CineSheetRoute`. Pure maths in `sheet-physics.ts` (tested).

## Decisions

- Dialog ignores an outside press in its first 400 ms (the second tap of the double tap that opened it), on top of the 1000 ms arm.
- Pull to reprint: the 96 px trigger is measured on the finger's raw pull; only the shown stretch is rubber-banded (c = 0.35). With a banded trigger the
  rule never reached 96 px inside a sensible stretch.
- Lightbox `=` and `-` step 1.25x per press; double click / double tap goes 1x to 2.5x and shows the `250%` chip.
- Notice and CertificateDialog headlines use `zoom: 0.6` on `type-headline` for the "0.6 scale" desktop size.
- `ContentModeToggle` / `ContentModeChip` import `@/features/content-mode/{mode,use-content-mode}` by path (the barrel re-exports legacy components and is lint-restricted).
- Gallery wraps only the content-mode row in a local `QueryClientProvider` (the preview route has none); it renders nothing there, as specified for novels off.
- Menus and ContextMenu share one item renderer (`Menu.tsx` `MenuItems`); the Select popup reuses the menu surface.
- Row menus: trailing `dots-three`, right-click through `ContextMenu` on the desktop frame, 450 ms long-press on coarse pointers.

## Verification record

See the report in the lane summary. Proof files: `overlays/*.png` (sheet, panel, dialogs, menu, toasts, quick look, notices, certificate on both frames,
lightbox), `states/*` (hover, focus, pressed of every `w5-` control), and the full-page grid / reduced captures.

## Critiques (impeccable / taste-skill pass against cinematic/DESIGN.md)

1. Notices and the certificate dialog headline rendered at about 10 px: `[font-size:0.6em]` overrode the role size. Changed to `zoom: 0.6` on the role, so
   it is 0.6 of the headline size. The rate-limit countdown wrapped mid-phrase inside the deck; it is now its own folio line under the deck.
2. Radius, shadow, blur and bounce sweep over every new file (grep for `shadow`, `rounded`, `blur`, `backdrop`, non-zero `bounce`): only the radio circle and the
   leader dial use `rounded-round`, both allowed. Focus uses the existing square double ring. Checkbox / switch hit areas were 20-32 px wide when the label was
   hidden; the label now carries a 44 px minimum width so the touch target meets the rule.
