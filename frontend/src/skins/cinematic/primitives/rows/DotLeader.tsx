/** §7.16: `·` at 0.5 em intervals in ink.30 and folio type, a repeating radial-gradient on the baseline; decorative. */
export function DotLeader({ className = "" }: { className?: string }) {
  return (
    <span aria-hidden className={`type-folio mx-2 h-[1em] min-w-4 flex-1 self-end text-ink-30 ${className}`}
      style={{ backgroundImage: "radial-gradient(circle at center, currentColor 0.5px, transparent 1px)", backgroundSize: "0.5em 1em", backgroundRepeat: "repeat-x", backgroundPosition: "0 100%", height: "0.5em", marginBottom: "0.35em" }} />
  );
}
