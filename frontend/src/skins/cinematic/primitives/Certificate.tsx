/**
 * §7.24 the 160 px certificate: a square with a 2 px proof border and "18" in Bodoni Moda Roman wght 900 at 88 px.
 * `stamped` is the confirm moment: the square fills proof for 160 ms while the 18 knocks out to #000, then settles back
 * (the caller fires haptic gate.confirm and cue impress at the fill; reduced motion shows the fill for 160 ms with no transition).
 */
export function Certificate({ stamped = false, className = "" }: { stamped?: boolean; className?: string }) {
  return (
    <div role="img" aria-label="Mature, 18 plus" data-stamped={stamped || undefined}
      className={`cine-certificate flex size-40 shrink-0 items-center justify-center border-2 border-proof text-proof ${className}`}>
      <span aria-hidden className="font-display" style={{ fontSize: 88, lineHeight: 1, fontVariationSettings: '"wght" 900, "opsz" 96', fontStyle: "normal" }}>18</span>
    </div>
  );
}
