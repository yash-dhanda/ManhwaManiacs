"use client";
import { useMemo } from "react";
import { shortcutCombos, useRegisteredShortcuts, type Shortcut } from "@/lib/keyboard";
import { Dialog } from "../primitives/Dialog";
import { DotLeader } from "../primitives/rows/DotLeader";
import { Keycap } from "../primitives/Keycap";
import { useShellState } from "./shell-state";

/** §8.33.2 group order, defined in the skin (the legacy `SHORTCUT_GROUP_ORDER` is untouched). */
export const CINEMATIC_GROUP_ORDER = [
  "General", "Navigation", "Tonight", "Library", "Updates", "Discover", "Sources", "Catalogue", "Downloads", "Collections", "History", "Bookmarks",
  "Dialogue", "The Numbers", "Circle", "Picks", "Profiles", "Settings", "System status", "Series page", "Reader", "Novel reader", "Listen", "Recap", "The Annual",
] as const;

export type SheetGroup = { name: string; shortcuts: Pick<Shortcut, "id" | "description" | "keys">[] };

/** Pure: bucket the registry in CINEMATIC_GROUP_ORDER, unknown groups after, sorted by description. The developer group is left out. */
export function groupForSheet(shortcuts: readonly Pick<Shortcut, "id" | "description" | "keys" | "group">[]): SheetGroup[] {
  const buckets = new Map<string, SheetGroup["shortcuts"]>();
  for (const s of shortcuts) {
    const name = s.group ?? "General";
    if (name === "Developer") continue;
    (buckets.get(name) ?? buckets.set(name, []).get(name)!).push(s);
  }
  for (const list of buckets.values()) list.sort((a, b) => a.description.localeCompare(b.description));
  const out: SheetGroup[] = [];
  for (const name of CINEMATIC_GROUP_ORDER) { const l = buckets.get(name); if (l?.length) { out.push({ name, shortcuts: l }); buckets.delete(name); } }
  for (const name of [...buckets.keys()].sort()) out.push({ name, shortcuts: buckets.get(name)! });
  return out;
}

/** Fixture-friendly body: two-column credits lists (description, dot leaders, keycaps). */
export function KeyboardSheetView({ groups }: { groups: SheetGroup[] }) {
  return (
    <div className="flex flex-col gap-6">
      <p className="type-body text-ink-60">Only what works on this screen is listed. Shortcuts pause while you type in a field.</p>
      {groups.length === 0 ? <p className="type-body text-ink-45">No shortcuts on this screen.</p> : null}
      {groups.map((g) => (
        <section key={g.name} aria-label={g.name}>
          <h3 className="type-kicker mb-2 text-ink-45">{g.name.toUpperCase()}</h3>
          <ul className="grid gap-x-8 gap-y-2 frame:grid-cols-2">
            {g.shortcuts.map((s) => (
              <li key={s.id} className="flex items-center gap-2">
                <span className="type-ui">{s.description}</span>
                <DotLeader />
                <span className="flex shrink-0 items-center gap-1">{shortcutCombos(s as Shortcut).slice(0, 2).map((c, i) => <Keycap key={c} combo={c} secondary={i > 0} />)}</span>
              </li>
            ))}
          </ul>
        </section>
      ))}
    </div>
  );
}

/** §8.33.2 the keyboard sheet: the live registry. The General group always lists `Alt+T`. */
export function KeyboardSheet() {
  const open = useShellState((s) => s.keyboardOpen);
  const setOpen = useShellState((s) => s.setKeyboardOpen);
  const registry = useRegisteredShortcuts();
  const groups = useMemo(() => groupForSheet(registry), [registry]);
  return (
    <Dialog open={open} onOpenChange={setOpen} title="Keyboard" className="!max-w-[720px]" data-gallery="keyboard-sheet">
      <KeyboardSheetView groups={groups} />
    </Dialog>
  );
}
