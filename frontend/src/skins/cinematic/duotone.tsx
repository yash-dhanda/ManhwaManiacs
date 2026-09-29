"use client";
import { useEffect } from "react";
import { create } from "zustand";

type DuoStore = { colors: string[]; add: (hex: string) => void };
const useStore = create<DuoStore>((set, get) => ({
  colors: [],
  add: (hex) => { if (!get().colors.includes(hex)) set((s) => ({ colors: [...s.colors, hex] })); },
}));

const norm = (hex: string) => hex.replace("#", "").toLowerCase().padStart(6, "0").slice(0, 6);

/** Black -> duo luminance map: R, G, B rows are [d*0.2126, d*0.7152, d*0.0722, 0, 0] (§2.1.5). */
export function duotoneMatrix(hex: string): string {
  const h = norm(hex);
  const d = [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
  const row = (v: number) => `${(v * 0.2126).toFixed(4)} ${(v * 0.7152).toFixed(4)} ${(v * 0.0722).toFixed(4)} 0 0`;
  return `${row(d[0])} ${row(d[1])} ${row(d[2])} 0 0 0 1 0`;
}

/** Hidden SVG holding one filter per registered duo colour. Mounted by the Shell, the preview layout and the gallery. */
export function DuotoneDefs() {
  const colors = useStore((s) => s.colors);
  return (
    <svg width="0" height="0" aria-hidden="true" style={{ position: "absolute" }}>
      {colors.map((c) => (
        <filter key={c} id={`duo-${norm(c)}`} colorInterpolationFilters="sRGB">
          <feColorMatrix type="matrix" values={duotoneMatrix(c)} />
        </filter>
      ))}
    </svg>
  );
}

/** Registers the colour and returns the `filter:` value. */
export function useDuotone(hex: string): string {
  const add = useStore((s) => s.add);
  const n = `#${norm(hex)}`;
  useEffect(() => add(n), [add, n]); // the filter resolves as soon as DuotoneDefs re-renders
  return `url(#duo-${norm(hex)})`;
}
