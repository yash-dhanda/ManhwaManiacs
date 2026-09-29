"use client";
import { Button } from "./Button";
import { Glyph } from "./glyphs";
import { SetHeading } from "./SetHeading";

/** The rail header row, reused outside rails: folio, linked heading, right-aligned quiet action. */
export function SectionHeader({ folio, title, action, onAction, empty = false }: { folio?: string; title: string; action?: string; onAction?: () => void; empty?: boolean }) {
  return (
    <div className="set-heading-link flex items-baseline gap-3 py-3">
      {folio ? <span className="type-folio text-ink-45">{folio}</span> : null}
      <SetHeading as="h3" trigger="inView" id={`section-${title}`} text={title} className={`type-section min-w-0 ${empty ? "text-ink-45" : "text-ink-100"}`} />
      {action ? <span className="ml-auto"><Button variant="quiet" size="sm" onClick={onAction}>{action} <Glyph name="arrow-right" size={16} /></Button></span> : null}
    </div>
  );
}
