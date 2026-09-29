"use client";

import { forwardRef } from "react";
import type { SourceBrowseMode, SourceGenre } from "@/features/sources/types";
import { IndexField } from "../kit/IndexField";
import { kit as s } from "../kit/Kit";
import d from "./catalogue.module.css";

export const CatalogueToolbar = forwardRef<HTMLInputElement, { modes: SourceBrowseMode[]; mode: string; onMode: (m: string) => void; genres: SourceGenre[]; genre: string; onGenre: (g: string) => void; q: string; onQ: (q: string) => void; browsable: boolean }>(
  function CatalogueToolbar({ modes, mode, onMode, genres, genre, onGenre, q, onQ, browsable }, ref) {
    const searching = q.trim() !== "";
    return (
      <div className={d.toolbar}>
        {browsable && !searching && modes.length > 0 ? (
          <div className={s.tabs} role="tablist" aria-label="Browse mode">
            {modes.map((m) => (
              <button key={m.id} type="button" role="tab" aria-selected={m.id === mode} className={s.tab} onClick={() => onMode(m.id)}>
                {m.label}
              </button>
            ))}
          </div>
        ) : null}
        <div className={d.bar}>
          {browsable && genres.length > 0 ? (
            <select className={d.select} aria-label="Genre" value={genre} onChange={(e) => onGenre(e.target.value)}>
              <option value="">All genres</option>
              {genres.map((g) => (
                <option key={g.id} value={g.id}>
                  {g.label}
                </option>
              ))}
            </select>
          ) : null}
          <div style={{ flex: 1, minWidth: 220 }}>
            <IndexField ref={ref} value={q} onChange={onQ} placeholder="Search this source" label="Search this source" variant="compact" />
          </div>
        </div>
      </div>
    );
  },
);
