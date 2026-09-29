"use client";
import { useState } from "react";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { ContentModeToggle } from "./ContentModeToggle";
import { Glyph } from "./glyphs";
import { Sheet } from "./Sheet";

/** §7.29 phone-frame chip `MANGA ▾` that opens a small Sheet with the toggle. Renders nothing when novels are off. */
export function ContentModeChip({ className = "" }: { className?: string }) {
  const { mode, novelsEnabled } = useContentMode();
  const [open, setOpen] = useState(false);
  if (!novelsEnabled) return null;
  return (
    <>
      <button type="button" aria-haspopup="dialog" data-gallery="mode-chip" onClick={() => setOpen(true)}
        className={`type-nav inline-flex min-h-(--mm-hit-min) items-center gap-1 px-2 text-ink-100 ${className}`}>
        {mode === "novel" ? "NOVELS" : "MANGA"}<Glyph name="caret-down" size={12} />
      </button>
      <Sheet open={open} onOpenChange={setOpen} title="Manga or novels" kicker="READING MODE">
        <ContentModeToggle />
        <p className="type-caption mt-4 text-ink-45">One setting for the whole app: library, sources, search, downloads and updates all follow it.</p>
      </Sheet>
    </>
  );
}
