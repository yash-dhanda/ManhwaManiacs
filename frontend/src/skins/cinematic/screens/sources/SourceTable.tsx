"use client";

import { Reorder, useDragControls } from "framer-motion";
import { useState } from "react";
import type { SourceSummary } from "@/features/sources/types";
import { SourceRow, type RowProps } from "./SourceRow";
import d from "./sources.module.css";

function PinnedItem({ id, onCommit, ...row }: RowProps & { id: string; onCommit: () => void }) {
  const controls = useDragControls();
  const [lifted, setLifted] = useState(false);
  return (
    <Reorder.Item
      value={id}
      as="li"
      dragListener={false}
      dragControls={controls}
      className={lifted ? d.lifted : undefined}
      onDragStart={() => setLifted(true)}
      onDragEnd={() => {
        setLifted(false);
        onCommit();
      }}
      transition={{ duration: 0.24, ease: [0.2, 0, 0, 1] }}
    >
      <SourceRow {...row} handle={{ onPointerDown: (e) => controls.start(e) }} />
    </Reorder.Item>
  );
}

export function PinnedTable({ ids, byId, common, onOrder, onCommit }: { ids: string[]; byId: Map<string, SourceSummary>; common: (s: SourceSummary) => Omit<RowProps, "handle">; onOrder: (ids: string[]) => void; onCommit: () => void }) {
  const key = ids.join("|");
  const [override, setOverride] = useState<{ key: string; value: string[] } | null>(null);
  const local = override && override.key === key ? override.value : ids;
  const setLocal = (value: string[]) => setOverride({ key, value });
  return (
    <Reorder.Group axis="y" values={local} onReorder={(v) => { setLocal(v); onOrder(v); }} as="ul" className={d.list} aria-label="Pinned sources">
      {local.map((id) => {
        const src = byId.get(id);
        return src ? <PinnedItem key={id} id={id} onCommit={onCommit} {...common(src)} /> : null;
      })}
    </Reorder.Group>
  );
}

export function AllTable({ rows, common }: { rows: SourceSummary[]; common: (s: SourceSummary) => Omit<RowProps, "handle"> }) {
  return (
    <ul className={d.list} aria-label="All sources">
      {rows.map((src) => (
        <li key={src.id}>
          <SourceRow {...common(src)} />
        </li>
      ))}
    </ul>
  );
}
