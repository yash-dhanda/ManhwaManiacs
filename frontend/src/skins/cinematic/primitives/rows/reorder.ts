import type { MenuItemDef } from "../menu-types";

/** Immutable move of one item; out-of-range targets clamp. */
export function moveItem<T>(list: readonly T[], from: number, to: number): T[] {
  const next = list.slice();
  const [it] = next.splice(from, 1);
  next.splice(Math.max(0, Math.min(next.length, to)), 0, it);
  return next;
}

/** "Solo Leveling moved to position 3 of 12" (`to` is zero-based). */
export const announceMove = (title: string, to: number, total: number): string => `${title} moved to position ${to + 1} of ${total}`;

/** Which of Move up / down / to top / to bottom are disabled at this index. */
export const moveDisabled = (index: number, total: number) => ({
  up: index <= 0, top: index <= 0, down: index >= total - 1, bottom: index >= total - 1,
});

/** The four Move items every reorderable row menu gains; each calls `onMove(from, to)` (which writes sort_order). */
export function moveItems(index: number, total: number, onMove: (from: number, to: number) => void): MenuItemDef[] {
  const d = moveDisabled(index, total);
  const mk = (id: string, label: string, to: number, disabled: boolean, first = false): MenuItemDef => ({ id: `move-${id}`, label, separatorBefore: first, disabled, onSelect: () => onMove(index, to) });
  return [mk("up", "Move up", index - 1, d.up, true), mk("down", "Move down", index + 1, d.down), mk("top", "Move to top", 0, d.top), mk("bottom", "Move to bottom", total - 1, d.bottom)];
}
