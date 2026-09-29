# Owner to-do (redesign)

Items only the owner can do, by step.

- **mobile/00** (reader engine extraction): run the device checklist in
  `docs/redesign/proof/mobile-00/device-check.md` on the iPhone (SideStore build)
  and the Android flagship (next signed APK), including the 120-page, 2,880 px
  scroll-performance check (stack risk 6).
- **shared/02** (icon sets and custom glyphs): decide the Cinematic `mm-mark` weights
  (cinematic §12.2/§2.7). The upright and italic M intersect only ~119 px² at 1024, so
  Light, Regular and Fill trace to one identical outline. Either accept one outline for
  all three weights, or change the overlap rule to act on the letterforms instead of
  their bounding boxes. The mark also does not read at 16 px (a ~9x4 px smudge).
  Geometry is unchanged until you decide; see the comment above `case 'mm-mark'` in
  `brand/make-glyph-masters.mjs`.

- shared/04: owner to check the new launcher icon, `Maniacs` label and black native frame on a real iPhone and Android device after the next build; hairlines of the Bodoni monogram are ~1 unit, judge the icon at 60 px.
