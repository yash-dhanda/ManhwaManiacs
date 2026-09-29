import { OxfordRule } from "../primitives/OxfordRule";

const wm = (italic: boolean): React.CSSProperties => ({ fontFamily: "var(--mm-font-display)", fontStyle: italic ? "italic" : "normal", fontVariationSettings: '"opsz" 96, "wght" 800', fontWeight: 800, letterSpacing: "-0.035em" });

/**
 * Wordmark (§12.2). `inline`: "Manhwa" Roman + "Maniacs" Italic on one line (the sidebar head, 20 px). `stacked`: the lockup as live text,
 * Roman over Italic, leading 0.86, flush left, in `type-masthead`, with the Oxford rule under both (first 12 % in spot).
 */
export function Wordmark({ variant = "inline", size = 20, rule = false, className = "" }: { variant?: "inline" | "stacked"; size?: number; rule?: boolean; className?: string }) {
  if (variant === "inline") {
    return (
      <span aria-label="ManhwaManiacs" role="img" className={`inline-flex items-baseline whitespace-nowrap text-ink-100 ${className}`} style={{ fontSize: size, lineHeight: 1 }}>
        <span aria-hidden style={wm(false)}>Manhwa</span><span aria-hidden style={wm(true)}>Maniacs</span>
      </span>
    );
  }
  return (
    <span className={`inline-flex flex-col text-ink-100 ${className}`} role="img" aria-label="ManhwaManiacs">
      <span aria-hidden className="type-masthead" style={{ ...wm(false), lineHeight: 0.86 }}>Manhwa</span>
      <span aria-hidden className="type-masthead" style={{ ...wm(true), lineHeight: 0.86 }}>Maniacs</span>
      {rule ? <span className="mt-3 block"><OxfordRule spotLead /></span> : null}
    </span>
  );
}
