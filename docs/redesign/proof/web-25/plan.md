# web-25 plan: Glass foundation (lane L03)

Order (each step is one commit, pure parts test-first):
1. deps (motion 13.4.6 because 13.4.4 does not resolve; fast-average-color 9.6.0), document defaults, renderer stamp, glass tokens import, /dev root layout, proxy exemption.
2. material.ts, physics/, liquid-map.ts, budget.ts, palette.ts, rain.ts (pure, vitest first).
3. GlassSurface + LensDefs + glass.css (tiers, finishes, tiers A/B/C, contrast, forced colours, twins, focus ring).
4. useLightAngle, Caustic, useLb, AmbientField.
5. motion.ts (MOTION_TABLE from DESIGN 4.10) + local recorder stand-in + overlay.
6. /dev/glass-calibration + Playwright spec + proof.

Stand-ins (web/02 not integrated in this lane): motion-timings recorder lives in skins/glass/motion-recorder.ts (TODO web/02); Glass tokens import added to globals.css; `data-solid`/`data-contrast`/`data-motion` are stamped by the calibration page on <html>.
