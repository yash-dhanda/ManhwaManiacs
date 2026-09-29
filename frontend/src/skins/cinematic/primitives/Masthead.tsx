"use client";
import type { ReactNode } from "react";
import { MoodGrade, gradeStock, type Mood } from "./MoodGrade";
import { OxfordRule } from "./OxfordRule";
import { SetHeading } from "./SetHeading";

/** §7.27 masthead block: kicker (`No. 02 — YOUR SHELF`), SetHeading h1 (mount trigger, tabIndex -1 for route focus), deck, Oxford rule drawn after the letters. Bottom margin 48 desktop / 32 phone. */
export function Masthead({ folio, section, title, deck, mood, children, id }: { folio: string; section: string; title: string; deck?: ReactNode; mood?: Mood | null; children?: ReactNode; id?: string }) {
  const n = title.replaceAll(" ", "").length;
  return (
    <header data-stock={gradeStock(mood)} className="relative mb-8 frame:mb-12">
      <MoodGrade mood={mood} />
      <div className="relative">
        <p className="type-kicker text-ink-45">{`${folio} — ${section}`}</p>
        <SetHeading as="h1" trigger="mount" id={id ?? `masthead-${title}`} text={title} tabIndex={-1} className="type-masthead mt-2 text-ink-100" />
        {deck ? <p className="type-deck mt-3 text-ink-60">{deck}</p> : null}
        <div className="mt-4"><OxfordRule delayMs={120 + Math.min(24, 560 / Math.max(1, n - 1)) * n + 640 - 200} /></div>
        {children}
      </div>
    </header>
  );
}
