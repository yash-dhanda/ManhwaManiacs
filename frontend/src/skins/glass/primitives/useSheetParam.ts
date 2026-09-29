"use client";

import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useCallback, useEffect, useSyncExternalStore } from "react";

/**
 * Sheet URL state (glass 7.10): a sheet, panel or window is open when `?sheet={id}` names it. Opening pushes a history
 * entry with window.history.pushState, which Next 16 syncs into useSearchParams without re-rendering the route tree, so
 * browser back closes the sheet. A page hard-loaded with the parameter closes by replacing the URL. Anchored pickers
 * (menus, the speed dial, popovers) never use this. At most two sheets stack: the URL names the top one.
 */
const PARAM = "sheet";

interface Store { stack: string[]; pushed: Set<string>; triggers: Map<string, HTMLElement | null> }
const store: Store = { stack: [], pushed: new Set(), triggers: new Map() };
let snapshot = "";
const subs = new Set<() => void>();
const emit = () => { snapshot = store.stack.join(","); subs.forEach((s) => s()); };
const subscribe = (cb: () => void) => (subs.add(cb), () => void subs.delete(cb));
const getSnapshot = () => snapshot;

/** Pure: the next stack given the URL's top id (used when the URL changes under us: back, forward, hard load). */
export function reconcileStack(stack: readonly string[], top: string | null): string[] {
  if (!top) return [];
  if (stack[stack.length - 1] === top) return [...stack];
  if (stack.length >= 2 && stack[stack.length - 2] === top) return stack.slice(0, -1);
  return [top];
}

/** Pure: pushing an id onto a stack keeps at most two, a third replaces the top one. */
export function pushStack(stack: readonly string[], id: string): string[] {
  const rest = stack.filter((x) => x !== id);
  return rest.length >= 2 ? [rest[0], id] : [...rest, id];
}

const urlWith = (id: string | null, extra?: Record<string, string>) => {
  const u = new URL(window.location.href);
  if (id) {
    u.searchParams.set(PARAM, id);
    for (const [k, v] of Object.entries(extra ?? {})) u.searchParams.set(k, v);
  } else u.searchParams.delete(PARAM);
  return u;
};

/** Open a sheet: `?sheet={id}` (kebab-case) plus any parameter beside it. Remembers the focused trigger. */
export function openSheet(id: string, extra?: Record<string, string>, trigger?: HTMLElement | null): void {
  store.triggers.set(id, trigger ?? (document.activeElement instanceof HTMLElement ? document.activeElement : null));
  window.history.pushState({ sheet: id }, "", urlWith(id, extra));
  store.pushed.add(id);
  store.stack = pushStack(store.stack, id);
  emit();
}

export const sheetTrigger = (id: string) => store.triggers.get(id) ?? null;

export interface SheetParam {
  open: boolean;
  /** true while another sheet is above this one */
  covered: boolean;
  /** true when two sheets are stacked (only the lowest one recedes the page) */
  stacked: boolean;
  close: () => void;
  openSheet: typeof openSheet;
}

export function useSheetParam(id: string): SheetParam {
  const sp = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const top = sp.get(PARAM);
  const signature = useSyncExternalStore(subscribe, getSnapshot, () => "");
  useEffect(() => {
    const next = reconcileStack(store.stack, top);
    if (next.join(",") !== store.stack.join(",")) {
      for (const gone of store.stack) if (!next.includes(gone)) store.pushed.delete(gone);
      store.stack = next;
      emit();
    }
  }, [top]);
  const stack = signature ? signature.split(",") : [];
  const isTop = top === id;
  const covered = !isTop && stack[stack.length - 1] === top && stack[stack.length - 2] === id;
  const open = isTop || covered;
  const close = useCallback(() => {
    if (store.pushed.has(id)) { window.history.back(); return; }
    // hard-loaded with the parameter: replace the URL without it
    const u = urlWith(null);
    router.replace(`${pathname}${u.search}${u.hash}`, { scroll: false });
    store.stack = store.stack.filter((x) => x !== id);
    emit();
  }, [id, pathname, router]);
  return { open, covered, stacked: stack.length > 1, close, openSheet };
}

/** test hook */
export const _resetSheets = () => { store.stack = []; store.pushed.clear(); store.triggers.clear(); emit(); };
