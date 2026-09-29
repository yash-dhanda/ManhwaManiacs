"use client";

import type { ReactNode } from "react";
import { parseSnippet } from "@/features/ocr/snippet";
import d from "./dialogue.module.css";

/** Highlighted runs of a server snippet as real <mark> elements (never HTML injection). */
export function Highlighted({ snippet, sweep }: { snippet: string; sweep?: boolean }): ReactNode {
  let k = 0;
  return parseSnippet(snippet).map((seg, i) =>
    seg.highlight ? (
      <mark key={i} className={sweep ? d.hl : undefined} style={{ ["--k" as string]: k++, background: sweep ? undefined : "var(--mm-color-spot-wash)", color: "inherit" }}>
        {seg.text}
      </mark>
    ) : (
      <span key={i}>{seg.text}</span>
    ),
  );
}

export function creditLine(p: { title: string; chapterKey: string; page: number | null; words: number; engine: string }): string {
  return [p.title.toUpperCase(), `CH ${p.chapterKey}`, p.page !== null ? `PAGE ${p.page}` : null, `${p.words} WORDS`, p.engine].filter(Boolean).join(" · ");
}
