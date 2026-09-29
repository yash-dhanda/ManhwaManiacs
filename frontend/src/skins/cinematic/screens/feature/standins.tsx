"use client";

import { useState, type ReactNode } from "react";
import { useAddSeriesToCollection, useCollections, useCreateCollection } from "@/features/library/hooks";
import { useCreateTag } from "./tags-standin";
import type { SeriesPage } from "./use-series-page";
import { Glyph } from "./Glyph";
import s from "./feature.module.css";
import t from "./type.module.css";

function Sheet({ kicker, onClose, children }: { kicker: string; onClose: () => void; children: ReactNode }) {
  return (
    <>
      <div className={s.scrim} onClick={onClose} />
      <aside className={s.side} role="dialog" aria-label={kicker} onKeyDown={(e) => e.key === "Escape" && onClose()}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span className={t.kicker} style={{ color: "var(--mm-color-spot)" }}>{kicker}</span>
          <button type="button" className={s.icon} aria-label="Close" onClick={onClose}><Glyph name="x" /></button>
        </div>
        {children}
      </aside>
    </>
  );
}

// TODO(web/09): stand-in for parts/AddToShelfSheet.tsx.
export function AddToShelfSheet({ page, onClose }: { page: SeriesPage; onClose: () => void }) {
  const shelves = useCollections().data ?? [];
  const add = useAddSeriesToCollection();
  const create = useCreateCollection();
  const [name, setName] = useState("");
  return (
    <Sheet kicker="ADD TO SHELF" onClose={onClose}>
      <ul className={s.rows} style={{ marginTop: 16 }}>
        {shelves.map((c) => (
          <li key={c.id}>
            <button
              type="button"
              className={s.cand}
              style={{ gridTemplateColumns: "1fr" }}
              onClick={() => {
                add.mutate({ collectionId: c.id, ref: page.ref });
                page.toasts.push(`Added to ${c.name}.`);
                onClose();
              }}
            >
              <span className={t.title}>{c.name}</span>
            </button>
          </li>
        ))}
      </ul>
      <form
        style={{ marginTop: 16, display: "flex", gap: 8 }}
        onSubmit={(e) => {
          e.preventDefault();
          if (!name.trim()) return;
          create.mutate({ name: name.trim() }, {
            onSuccess: (c) => {
              add.mutate({ collectionId: c.id, ref: page.ref });
              page.toasts.push(`Added to ${c.name}.`);
              onClose();
            },
          });
        }}
      >
        <input className={s.field} value={name} placeholder="New shelf…" aria-label="New shelf name" onChange={(e) => setName(e.target.value)} />
        <button type="submit" className={s.quiet}>Create</button>
      </form>
    </Sheet>
  );
}

// TODO(web/09): stand-in for parts/TagSheet.tsx.
export function TagSheet({ page, onClose }: { page: SeriesPage; onClose: () => void }) {
  const create = useCreateTag();
  const [name, setName] = useState("");
  return (
    <Sheet kicker="TAGS" onClose={onClose}>
      <div className={s.tokens}>
        {page.allTags.map((tag) => {
          const on = page.tagIds.has(tag.id);
          return (
            <button
              key={tag.id}
              type="button"
              className={s.chip}
              aria-pressed={on}
              onClick={() =>
                (on ? page.untagSeries : page.tagSeries).mutate({ ref: page.ref, tagId: tag.id })
              }
            >
              {on ? "✓ " : ""}{tag.name}
            </button>
          );
        })}
      </div>
      <form
        style={{ marginTop: 16, display: "flex", gap: 8 }}
        onSubmit={(e) => {
          e.preventDefault();
          if (!name.trim()) return;
          create.mutate(name.trim(), {
            onSuccess: (tag) => page.tagSeries.mutate({ ref: page.ref, tagId: tag.id }),
          });
          setName("");
        }}
      >
        <input className={s.field} value={name} placeholder="New tag…" aria-label="New tag name" onChange={(e) => setName(e.target.value)} />
        <button type="submit" className={s.quiet}>Create</button>
      </form>
    </Sheet>
  );
}
