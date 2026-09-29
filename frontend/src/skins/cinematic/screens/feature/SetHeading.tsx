"use client";

import { useEffect, useState, type ElementType } from "react";
import s from "./feature.module.css";
import t from "./type.module.css";

/** Grapheme count, so a long title steps down one role past 24 and two past 40 (§3.1). */
function graphemes(text: string): number {
  try {
    return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text)].length;
  } catch {
    return [...text].length;
  }
}

// TODO(web/03): stand-in for the SetHeading primitive: letters fade in by the
// signal delay (480 ms after a match cut, else 160 ms), no seen-set access.
export function SetHeading({
  text,
  as: Tag = "h1",
  masthead,
  delayMs = 160,
}: {
  text: string;
  as?: ElementType;
  masthead?: boolean;
  delayMs?: number;
}) {
  const [on, setOn] = useState(false);
  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const id = setTimeout(() => setOn(true), reduce ? 0 : delayMs);
    return () => clearTimeout(id);
  }, [delayMs, text]);
  const n = graphemes(text);
  const step = n > 40 ? s.headlineDown2 : n > 24 ? s.headlineDown : "";
  const role = masthead ? `${t.masthead} ${s.masthead}` : `${t.headline} ${s.headline}`;
  return (
    <Tag className={`${role} ${step}`} aria-label={text}>
      <span aria-hidden="true" style={{ opacity: on ? 1 : 0, transition: `opacity 640ms var(--mm-ease-settle)`, filter: on ? "none" : "blur(8px)" }}>
        {text}
      </span>
    </Tag>
  );
}
