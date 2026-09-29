"use client";

import { useState } from "react";
import { Sheet, kit as s } from "../kit/Kit";
import d from "./discover.module.css";

export function GroupJump({ groups, onJump }: { groups: Array<{ key: string; name: string; count: number }>; onJump: (key: string) => void }) {
  const [open, setOpen] = useState(false);
  if (groups.length === 0) return null;
  return (
    <>
      <nav className={d.jumpBar} aria-label="Jump to source">
        <div className={s.slug}>
          {groups.map((g) => (
            <button key={g.key} type="button" className={s.slugItem} onClick={() => onJump(g.key)}>
              {g.name}
              <span className={s.raised}>{g.count}</span>
            </button>
          ))}
        </div>
      </nav>
      <button type="button" className={`${s.quiet} ${d.jumpBtn}`} onClick={() => setOpen(true)}>
        Jump to source
      </button>
      <Sheet open={open} onClose={() => setOpen(false)} title="Jump to source">
        {groups.map((g) => (
          <button
            key={g.key}
            type="button"
            className={s.menuItem}
            onClick={() => {
              setOpen(false);
              onJump(g.key);
            }}
          >
            {g.name} · {g.count}
          </button>
        ))}
      </Sheet>
    </>
  );
}
