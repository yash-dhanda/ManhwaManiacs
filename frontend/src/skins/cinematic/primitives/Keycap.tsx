import { formatKeyCombo } from "@/lib/keyboard";

/** §7.26: type.folio 12 in a 1 px ink.30 square box, min 20 x 20, platform glyphs through formatKeyCombo(). */
export function Keycap({ combo, secondary = false }: { combo: string; secondary?: boolean }) {
  const parts = formatKeyCombo(combo);
  return (
    <kbd className={`type-folio inline-flex min-h-5 min-w-5 items-center justify-center gap-1 border border-ink-30 px-1 font-folio text-ink-60 ${secondary ? "opacity-60" : ""}`}>
      {parts.join(" ")}
    </kbd>
  );
}
