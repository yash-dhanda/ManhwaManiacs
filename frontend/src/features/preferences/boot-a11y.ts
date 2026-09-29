import { readScopedString, writeScopedString } from "@/lib/scoped-storage";

export const BOOT_A11Y_BASE = "mm.boot.a11y";

/** `motion: true` means "Reduce motion in this app" is forced on. Cinematic reads legible + motion; Glass all five. */
export type BootA11y = {
  legible: boolean;
  motion: boolean;
  solid: boolean;
  contrast: boolean;
  sr: boolean;
};

const OFF: BootA11y = { legible: false, motion: false, solid: false, contrast: false, sr: false };

export function readBootA11y(): BootA11y | null {
  const raw = readScopedString(BOOT_A11Y_BASE);
  if (raw === null) return null;
  try {
    const parsed = JSON.parse(raw) as Partial<BootA11y> | null;
    if (!parsed || typeof parsed !== "object") return null;
    return {
      legible: parsed.legible === true,
      motion: parsed.motion === true,
      solid: parsed.solid === true,
      contrast: parsed.contrast === true,
      sr: parsed.sr === true,
    };
  } catch {
    return null;
  }
}

/** Set or remove the five first-paint attributes on <html>. */
export function applyBootA11y(root: HTMLElement, value: BootA11y | null): void {
  const v = value ?? OFF;
  const os =
    typeof matchMedia === "function" && matchMedia("(prefers-reduced-motion: reduce)").matches;
  const set = (name: string, on: boolean, val: string) =>
    on ? root.setAttribute(name, val) : root.removeAttribute(name);
  set("data-motion", v.motion || os, "reduced");
  set("data-legible", v.legible, "on");
  set("data-solid", v.solid, "on");
  set("data-contrast", v.contrast, "more");
  set("data-sr", v.sr, "on");
}

export function writeBootA11y(patch: Partial<BootA11y>): void {
  const next = { ...(readBootA11y() ?? OFF), ...patch };
  writeScopedString(BOOT_A11Y_BASE, JSON.stringify(next));
  if (typeof document !== "undefined") applyBootA11y(document.documentElement, next);
}
