# mobile/27 plan (fix pass 1)

Parts: A overlay queue, B sheets, C alerts, D toasts, E tabs, F sliders/scrub/dial, G toggles, H menus, I notices, J image viewer, K scroll edges, L pull to refresh, M content-mode switch, N gallery/tests/captures.

Fix pass 1 order:
1. Regression: `taste_service` added to `noClientCache` (no client provider reads the taste catalogue yet); revisit when the onboarding screens land.
2. Gallery: sections renamed to the prompt's names (`banners`, `scroll-edges`, `pull-to-refresh`, `content-mode`), new `image-viewer` section, `sheets` wrapped in `GlassRecede` with launch buttons for panel, window, detail window, popover, stacked, keyboard field and the 1,000-row list; alerts gained from-centre, pending and error; menus gained the context lift and a secondary-click region.
3. Defect found on the way: the alert, toast, status capsule, new-chapters/app-update capsule and the viewer error card wrapped their own `SkinGlass` in `GlassHost`, so the surface rendered its `onGlass` twin and never registered a live layer or the Solid slab. The host now wraps only the content.
4. Tests: `overlays_a11y`, `overlays_budget`, `overlays_solid`, `overlays_reduced`.
5. Captures: every name in the prompt, plus `<section>-contrast-phone.png`.
