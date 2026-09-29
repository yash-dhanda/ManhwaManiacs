"use client";

/** Stable hash of a source id into 0..9 (the speaker palette, 2.1.5). */
export const hashIndex = (id: string) => { let h = 0; for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) >>> 0; return h % 10; };

/** Logo fallback: the name's first letter in `headline` 600 `label1` on `surface3`, radius 10, tinted by a hash of the id at 24 %. */
export function SourceMonogram({ id, name, size = 44 }: { id: string; name: string; size?: number }) {
  return <span className="g-mono" aria-hidden="true" style={{ width: size, height: size, ["--tint" as string]: `var(--mm-color-spk${hashIndex(id) + 1})` }}>{name.trim().slice(0, 1).toUpperCase()}</span>;
}
