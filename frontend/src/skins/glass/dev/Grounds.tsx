"use client";

import type { ReactNode } from "react";

/** Each specimen is shown over three grounds side by side: black, the ambient field and a white panel (shows the legibility dim and the backing discs). */
export const GROUNDS = ["black", "ambient", "white"] as const;
export type Ground = (typeof GROUNDS)[number];

export function Grounds({ title, note, children, columns = 3 }: { title?: string; note?: string; children: ReactNode | ((g: Ground) => ReactNode); columns?: 1 | 3 }) {
  return (
    <div className="gal-block">
      {title ? <h3 className="gal-h3">{title}</h3> : null}
      {note ? <p className="gal-note">{note}</p> : null}
      <div className="gal-grounds" data-columns={columns}>
        {GROUNDS.map((g) => (
          <div key={g} className="gal-ground" data-ground={g}>
            <span className="gal-tag">{g}</span>
            {typeof children === "function" ? children(g) : children}
          </div>
        ))}
      </div>
    </div>
  );
}

/** A labelled row of specimens inside a ground. */
export function Row({ label, children }: { label?: string; children: ReactNode }) {
  return (
    <div className="gal-row">
      {label ? <span className="gal-label">{label}</span> : null}
      <div className="gal-specimens">{children}</div>
    </div>
  );
}
