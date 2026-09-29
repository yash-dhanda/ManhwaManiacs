import { readScopedString } from "@/lib/scoped-storage";

/** Per-profile "Single-key shortcuts" preference (§8.14.9): `"on"` unless stored `"off"`. */
export const SINGLE_KEY_STORAGE_KEY = "mm.shortcuts.single";

export function singleKeyShortcutsEnabled(read: (k: string) => string | null = readScopedString): boolean {
  try {
    return read(SINGLE_KEY_STORAGE_KEY) !== "off";
  } catch {
    return true;
  }
}

/** True when a combo needs no mod/ctrl/meta/alt; `escape` and the help keys stay live so a layer can always be closed. */
export function isSingleKeyCombo(combo: string): boolean {
  const c = combo.trim().toLowerCase();
  if (c === "escape" || c === "?" || c === "shift+?" || c === "shift+/") return false;
  return !c.split(/\s+/).some((seg) => seg.split("+").some((p) => ["mod", "ctrl", "control", "cmd", "meta", "alt"].includes(p.trim())));
}

/** Whether a shortcut with these combos may fire now. */
export function comboAllowed(keys: string | string[], singleOn: boolean): boolean {
  if (singleOn) return true;
  return (Array.isArray(keys) ? keys : [keys]).some((k) => !isSingleKeyCombo(k));
}
