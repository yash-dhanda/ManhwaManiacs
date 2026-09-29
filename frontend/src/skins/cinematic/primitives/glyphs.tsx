import { ArrowLeftIcon, ArrowRightIcon, CheckIcon, DotsSixVerticalIcon, ImageBrokenIcon, StarIcon, WarningIcon, XIcon } from "@phosphor-icons/react/ssr";

// Phosphor glyphs the semantic roles of web/01 do not name (arrow-right, dots-six-vertical, image-broken, warning).
// TODO(web/01): fold into roles.generated.ts when shared/02 adds them.
const MAP = { "arrow-left": ArrowLeftIcon, "arrow-right": ArrowRightIcon, check: CheckIcon, "dots-six-vertical": DotsSixVerticalIcon, "image-broken": ImageBrokenIcon, star: StarIcon, warning: WarningIcon, x: XIcon } as const;
export type GlyphName = keyof typeof MAP;

/** §2.7 weights: Light at 24+, Regular at 20 and below, Fill when active. Never Bold or Duotone. */
export function Glyph({ name, size = 20, filled = false, className }: { name: GlyphName; size?: 12 | 16 | 20 | 24 | 28; filled?: boolean; className?: string }) {
  const P = MAP[name];
  return <P aria-hidden focusable="false" size={size} weight={filled ? "fill" : size <= 20 ? "regular" : "light"} color="currentColor" className={className} />;
}
