# web-04 critique record

## Legacy screens unchanged
library-before-1440x900.png (this tree with the step's only two non-skin edits, `globals.css` imports and `lib/keyboard/format.ts`, reverted to the pre-step commit) against library-after-1440x900.png (this branch): ImageMagick `compare -metric AE -fuzz 2%` reports no differing pixels. The route rendered without a session, so this proves the shell and global CSS, not an authenticated library. All new CSS is scoped to `[data-skin="cinematic"]` or to cine-only class names.

## impeccable pass (cinematic primitives gallery)
- Focus: one square double ring for every control; fields use the 2 px spot underline instead (documented in the states spec).
- Type: section headings are Bodoni italic at the ladder sizes, folios ink.45 turning spot when keyboard focus is inside the rail; empty sections dim the heading to ink.45.
- Colour: spot only on state (focus folio, selected, unread); the forced-colors block now targets the classes the components emit.
- Changed after review: poster states are component-owned (UNAVAILABLE caption, title-card loading plate, Retry cover on long-press); hover bloom composes with the focus halo.

## taste-skill pass
- Rejected: shimmer skeletons, rounded cards, drop shadows on posters. Kept: hairline plates, ragged galley bars, black-stock grounds.
- Changed after review: play glyph 28 px, slate clamps to the content columns, slate Library and Details actions are wired through Rail.
