"use client";
import { CONTENT_MODES, type ContentMode } from "@/features/content-mode/mode";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { haptic } from "../haptics";

const LABEL: Record<ContentMode, string> = { manga: "MANGA", novel: "NOVELS" };

/** §7.29 typographic MANGA / NOVELS toggle: the active word ink.100 with a 2 px spot underline, the other ink.45. Renders nothing when novels are off. */
export function ContentModeToggle({ className = "" }: { className?: string }) {
  const { mode, setMode, novelsEnabled } = useContentMode();
  if (!novelsEnabled) return null;
  return (
    <div role="radiogroup" aria-label="Reading mode" className={`inline-flex items-center gap-2 ${className}`}>
      {CONTENT_MODES.map((m, i) => (
        <span key={m} className="inline-flex items-center gap-2">
          {i > 0 ? <span aria-hidden className="type-nav text-ink-30">/</span> : null}
          <button type="button" role="radio" aria-checked={mode === m} data-gallery={`mode-${m}`}
            onClick={() => { if (m !== mode) { haptic("select"); setMode(m); } }}
            onKeyDown={(e) => { if (e.key === "ArrowRight" || e.key === "ArrowLeft") { const o = CONTENT_MODES[(CONTENT_MODES.indexOf(m) + 1) % CONTENT_MODES.length]; e.preventDefault(); setMode(o); (e.currentTarget.parentElement?.parentElement?.querySelector(`[data-gallery="mode-${o}"]`) as HTMLElement | null)?.focus(); } }}
            className={`type-nav relative inline-flex min-h-(--mm-hit-min) items-center px-1 ${mode === m ? "text-ink-100" : "text-ink-45 hover:text-ink-100 "}`}>
            {LABEL[m]}
            {mode === m ? <span aria-hidden className="absolute inset-x-1 bottom-2 h-0.5 bg-spot" /> : null}
          </button>
        </span>
      ))}
    </div>
  );
}
