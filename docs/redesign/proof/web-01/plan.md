# web/01 plan
1. motion 13.4.4 swap + pinned packages (package.json, lock, 2 import files; the other two framer-motion hits are comments).
2. optimizePackageImports for Phosphor.
3. Spring parity tests per skin (Vitest, against installed motion).
4. Fonts per skin + next/font/google Vitest stub, wired into fontClassName.
5. Per-skin PHOSPHOR import maps + Icon components + icon tests.
6. Dev-only specimen page; font network proof.

## Legacy motion before/after (fix pass 1)
legacy-{library,settings,palette}-{before,after}-{1440,390}[-reduced].png: legacy skin, signed in as a local test user, palette opened with Ctrl+K.
"before" = AnimatedText.tsx and StickyStack.tsx temporarily importing framer-motion, "after" = motion/react (committed). Layout, palette
and reduced-motion states match; the only pixel differences at 1440 are remote source icons that finish loading at different moments.
preload-check.txt: curl proof that Cinematic and Glass pages preload no Bodoni Moda / Google Sans Flex / Syne / DM Sans (preload:false fallback taken;
skins/legacy/fonts.ts was also edited, not in the spec's file list). The 12 remaining font preloads are the pre-existing Archivo / Newsreader / IBM Plex Mono.
