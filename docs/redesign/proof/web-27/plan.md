# web/27 plan

1. Foundation (sequential): overlay queue (A, tested), development `mm:haptic` event, `.glass-recede*` rules, per-family style files and gallery section stubs, icon additions.
2. Fan-out by family on disjoint files: B sheets; C alerts and D toasts; H menus and I banners; F sliders; G toggles and E tabs; J viewer, K edges, L pull, M content mode.
3. Pure pieces first, vitest: sheet-physics, pull-physics, slider-math, overlay-queue.
4. Gallery sections per family, then `glass-overlays.spec.ts`, then proof screenshots and report.
Stand-ins: `primitives/Icon.tsx` (TODO web/01) gains sun, speaker-high, minus, download-simple, info, caret-up.

Restart pass: the interrupted session had landed A to G and the H to K files uncommitted. Committed those; built L (PullToRefresh), M (ContentModeSwitch) and the six remaining gallery sections; fixed lint (react-hooks) to 0 errors and 0 warnings; found and fixed three defects the browser spec exposed (Menu never opened because Base UI's Trigger cannot drive our Button, so the trigger is now a `display: contents` wrapper; sheets, alerts and the viewer leaked Tab to the page, so `trapTab` wraps focus; `data-scrolling` was never set, now `useScrollingFlag`). The web/01 Icon stand-in was reviewed: the shared Icon is role-keyed and lacks check, warning-circle and droplet, so the primitives keep their own name-keyed wrapper (TODO removed, reason in the file).
