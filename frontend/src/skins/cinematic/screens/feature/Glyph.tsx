import type { ReactNode } from "react";

// TODO(web/01): stand-in line glyphs (24 grid, square caps) until the Phosphor
// icon roles land; replace with the role components.
const D: Record<string, ReactNode> = {
  plus: <path d="M12 4v16M4 12h16" />,
  check: <path d="M4 12.5l5 5L20 6.5" />,
  star: <path d="M12 3.5l2.6 5.6 6 .7-4.5 4.1 1.3 6-5.4-3.1-5.4 3.1 1.3-6L3.4 9.8l6-.7z" />,
  bell: <path d="M6 17V11a6 6 0 0112 0v6l1.5 2h-15zM10 21h4" />,
  download: <path d="M12 4v11M7 11l5 5 5-5M5 20h14" />,
  dots: <path d="M5 12h.01M12 12h.01M19 12h.01" strokeWidth="3" />,
  scroll: <path d="M6 3h12v18H6zM9 8h6M9 12h6M9 16h4" />,
  back: <path d="M20 12H5M11 5l-7 7 7 7" />,
  x: <path d="M5 5l14 14M19 5L5 19" />,
  headphones: <path d="M4 15v-3a8 8 0 0116 0v3M4 15h4v5H4zM16 15h4v5h-4z" />,
  search: <path d="M10.5 4a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM16 16l5 5" />,
};

export function Glyph({ name, fill }: { name: keyof typeof D | string; fill?: boolean }) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" style={fill ? { fill: "currentColor" } : undefined}>
      {D[name]}
    </svg>
  );
}
