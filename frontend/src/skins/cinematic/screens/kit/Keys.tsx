"use client";

import { useShortcut } from "@/lib/keyboard";

export interface KeyDef {
  id: string;
  keys: string | string[];
  description: string;
  handler: (e: KeyboardEvent) => void;
  enabled?: boolean;
  allowInInput?: boolean;
}

function Key({ def, group }: { def: KeyDef; group: string }) {
  useShortcut({ ...def, group, preventDefault: true });
  return null;
}

/** Registers a screen's keys under the group named by its masthead title. */
export function Keys({ group, defs }: { group: string; defs: KeyDef[] }) {
  return (
    <>
      {defs.map((d) => (
        <Key key={d.id} def={d} group={group} />
      ))}
    </>
  );
}
