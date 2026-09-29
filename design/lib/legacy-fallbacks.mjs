// Tailwind theme names the legacy UI (frontend/src/app/globals.css @theme, or Tailwind 4's default
// theme) already owns. Until the flip each is emitted as var(--mm-…, <what legacy renders today>),
// so a page with no --mm-* defined looks unchanged. The three colours fall back to legacy's runtime
// variables, which the [data-theme] blocks re-point. The flip release deletes this file.
export const LEGACY_FALLBACKS = {
  "--font-display": "var(--mm-font-display, var(--font-syne), Impact, sans-serif)",
  "--font-sans": "var(--mm-font-sans, var(--font-dm-sans), system-ui, sans-serif)",
  "--font-mono": "var(--mm-font-mono, var(--font-dm-sans), ui-monospace, monospace)",
  "--font-serif": 'var(--mm-font-serif, ui-serif, Georgia, Cambria, "Times New Roman", Times, serif)',
  "--color-danger": "var(--mm-color-danger, var(--mm-danger, #F85149))",
  "--color-success": "var(--mm-color-success, var(--mm-success, #3FB950))",
  "--color-warning": "var(--mm-color-warning, var(--mm-warning, #D29922))",
  "--radius-xs": "var(--mm-radius-xs, 0.125rem)",
  "--radius-sm": "var(--mm-radius-sm, 0.375rem)",
  "--radius-md": "var(--mm-radius-md, 0.5rem)",
  "--radius-lg": "var(--mm-radius-lg, 0.625rem)",
  "--radius-xl": "var(--mm-radius-xl, 1.5rem)",
};
