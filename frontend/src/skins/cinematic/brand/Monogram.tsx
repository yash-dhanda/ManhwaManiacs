import { MM_MARK } from "../mark.generated";

/**
 * The monogram (§12.2) as inline SVG: two Didone M's in bone; their intersection is a mask of one path over the other, so its fill can
 * animate `#000` -> `spot`. Paths come from `mark.generated.ts`, regenerated from the brand masters; never copy them by hand.
 */
export function Monogram({ size = 160, intersection = "#000000", bloom = 0, className = "", ...rest }: { size?: number; intersection?: string; bloom?: number; className?: string; "data-monogram"?: string }) {
  const m = MM_MARK as unknown as { viewBox: string; upright: string; italic: string; bone: string; spot: string };
  const id = "mm-mono-x";
  return (
    <svg role="img" aria-label="ManhwaManiacs" viewBox={m.viewBox} width={size} height={size} className={className} data-monogram={rest["data-monogram"]} style={{ overflow: "visible" }}>
      <defs>
        <clipPath id={`${id}-a`}><path d={m.upright} /></clipPath>
        <radialGradient id={`${id}-glow`}><stop offset="0" stopColor={m.spot} stopOpacity="1" /><stop offset="1" stopColor={m.spot} stopOpacity="0" /></radialGradient>
      </defs>
      <circle data-bloom cx="512" cy="512" r="420" fill={`url(#${id}-glow)`} opacity={bloom} />
      <path d={m.upright} fill={m.bone} />
      <path d={m.italic} fill={m.bone} />
      <g clipPath={`url(#${id}-a)`}><path data-intersection d={m.italic} fill={intersection} /></g>
    </svg>
  );
}
