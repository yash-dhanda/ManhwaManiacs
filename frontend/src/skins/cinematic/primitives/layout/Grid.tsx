import type { CSSProperties, ReactNode } from "react";

/** Horizontal margin (§2.2.2): max(grid margin, safe-area inset + 8 px). */
export const gridMargin = "max(var(--mm-grid-margin), calc(env(safe-area-inset-left) + 8px))";
export const gridMarginRight = "max(var(--mm-grid-margin), calc(env(safe-area-inset-right) + 8px))";

/** `grid-column` helpers: span(n) and col(i, n). */
export const span = (n: number): CSSProperties => ({ gridColumn: `span ${n} / span ${n}` });
export const col = (start: number, n = 1): CSSProperties => ({ gridColumn: `${start} / span ${n}` });

/** The layout grid: `--mm-grid-columns` columns, margin and gutter from the tokens, capped at `--mm-grid-max`. */
export function Grid({ children, className = "", as: Tag = "div" }: { children: ReactNode; className?: string; as?: "div" | "section" | "main" }) {
  return (
    <Tag className={`mx-auto w-full ${className}`} style={{ display: "grid", gridTemplateColumns: "var(--mm-grid-template)", columnGap: "var(--mm-grid-gutter)", maxWidth: "var(--mm-grid-max)", paddingLeft: gridMargin, paddingRight: gridMarginRight }}>
      {children}
    </Tag>
  );
}
