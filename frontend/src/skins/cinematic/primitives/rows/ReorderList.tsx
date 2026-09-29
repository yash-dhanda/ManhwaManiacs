"use client";
import { Reorder, useDragControls } from "motion/react";
import { useEffect, useState, type ReactNode } from "react";
import { haptic } from "../../haptics";
import { ease } from "../../tokens.generated";
import { Glyph } from "../glyphs";
import { useAnnouncer } from "../overlay-hooks";
import type { MenuItemDef } from "../menu-types";
import { announceMove, moveItems } from "./reorder";

export type ReorderItem = { id: string; title: string };
const shift = { duration: 0.24, ease: ease.set as unknown as [number, number, number, number] };

/**
 * §7.16 reorder: a dots-six-vertical handle at the trailing edge; drag, Alt+Up / Alt+Down, or the four Move items in the row menu
 * (`menuFor(item)` returns the row's own items, the Move items are appended). `onMove(from, to)` writes sort_order.
 */
export function ReorderList<T extends ReorderItem>({ items, onMove, renderRow, label }: {
  items: T[]; onMove: (from: number, to: number) => void; label: string;
  renderRow: (item: T, o: { index: number; handle: ReactNode; moveMenu: MenuItemDef[] }) => ReactNode;
}) {
  const [live, say] = useAnnouncer();
  const [order, setOrder] = useState(items);
  useEffect(() => setOrder(items), [items]); // eslint-disable-line react-hooks/set-state-in-effect -- follow the caller's order
  const commit = (from: number, to: number) => {
    if (to < 0 || to >= items.length || from === to) return;
    onMove(from, to); say(announceMove(items[from].title, to, items.length));
  };
  return (
    <>
      <Reorder.Group axis="y" values={order} onReorder={setOrder} aria-label={label} as="ul">
        {order.map((it) => { const i = items.findIndex((x) => x.id === it.id); return <ReorderRow key={it.id} item={it} index={i} items={items} order={order} commit={commit} renderRow={renderRow} />; })}
      </Reorder.Group>
      <div role="status" aria-live="polite" className="sr-only">{live}</div>
    </>
  );
}

function ReorderRow<T extends ReorderItem>({ item, index, items, order, commit, renderRow }: {
  item: T; index: number; items: T[]; order: T[]; commit: (from: number, to: number) => void;
  renderRow: (item: T, o: { index: number; handle: ReactNode; moveMenu: MenuItemDef[] }) => ReactNode;
}) {
  const controls = useDragControls();
  const [lifted, setLifted] = useState(false);
  const handle = (
    <button type="button" aria-label={`Reorder ${item.title}`} onPointerDown={(e) => { controls.start(e); }} style={{ touchAction: "none" }}
      className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) cursor-grab items-center justify-center text-ink-45 hover:text-ink-100 active:cursor-grabbing"><Glyph name="dots-six-vertical" size={20} /></button>
  );
  return (
    <Reorder.Item as="li" value={item} dragListener={false} dragControls={controls} layout="position" transition={shift}
      onDragStart={() => setLifted(true)}
      onDragEnd={() => { setLifted(false); haptic("select"); commit(index, order.findIndex((x) => x.id === item.id)); }}
      onKeyDown={(e) => { if (e.altKey && (e.key === "ArrowUp" || e.key === "ArrowDown")) { e.preventDefault(); commit(index, index + (e.key === "ArrowUp" ? -1 : 1)); } }}
      style={{ position: "relative", top: lifted ? -1 : 0, outline: lifted ? "1px solid var(--mm-color-ink-100)" : "none", zIndex: lifted ? 1 : 0 }}>
      {renderRow(item, { index, handle, moveMenu: moveItems(index, items.length, commit) })}
    </Reorder.Item>
  );
}
