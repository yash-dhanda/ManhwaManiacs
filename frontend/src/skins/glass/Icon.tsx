import { GLYPHS } from "./icons/glyphs.generated";
import { ICON_ROLES, ICON_RULES, type IconRole } from "./icons/roles.generated";
import { PHOSPHOR } from "./icons/phosphor";

type State = "rest" | "active" | "pressed";
type Tier = "default" | "ornamental" | "dense";
type Props = {
  name: IconRole;
  size?: number;
  state?: State;
  tier?: Tier;
  /** Depth level for the back-depth (Strata) glyph. */
  level?: 1 | 2 | 3 | 4;
  label?: string;
  className?: string;
};

/** Glass §2.7: pressed Fill, active Duotone, ornamental Light, dense Bold, otherwise Regular. */
export function glassWeight(state: State, tier: Tier) {
  if (state === "pressed") return "fill";
  if (state === "active") return "duotone";
  if (tier === "ornamental") return "light";
  if (tier === "dense") return "bold";
  return "regular";
}

export function Icon({ name, size = 22, state = "rest", tier = "default", level, label, className }: Props) {
  const role = ICON_ROLES[name];
  const weight = glassWeight(state, tier);
  const a11y = label
    ? ({ role: "img", "aria-label": label } as const)
    : ({ "aria-hidden": true, focusable: "false" } as const);
  if (role.kind === "glyph") {
    // Glyphs only have regular / duotone / fill masters.
    const gw = weight === "light" || weight === "bold" ? ICON_RULES.glyphFallback[weight] : weight;
    const Glyph = GLYPHS[role.name] as (p: Record<string, unknown>) => React.JSX.Element;
    return <Glyph weight={gw} size={size} {...(role.name === "strata" ? { level: level ?? 1 } : {})} className={className} {...a11y} />;
  }
  const P = PHOSPHOR[role.component];
  return <P weight={weight} size={size} color="currentColor" className={className} {...a11y} />;
}
