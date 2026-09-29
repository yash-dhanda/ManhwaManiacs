import { GLYPHS } from "./icons/glyphs.generated";
import { ICON_ROLES, type IconRole } from "./icons/roles.generated";
import { PHOSPHOR } from "./icons/phosphor";

type Props = {
  name: IconRole;
  size?: 16 | 20 | 24 | 32;
  filled?: boolean;
  label?: string;
  className?: string;
};

/** Cinematic §2.7: Light at 24+, Regular at 20 and below, Fill for active. Never Bold or Duotone. */
export function cinematicWeight(size: number, filled: boolean) {
  return filled ? "fill" : size <= 20 ? "regular" : "light";
}

export function Icon({ name, size = 24, filled = false, label, className }: Props) {
  const role = ICON_ROLES[name];
  const weight = cinematicWeight(size, filled);
  const a11y = label
    ? ({ role: "img", "aria-label": label } as const)
    : ({ "aria-hidden": true, focusable: "false" } as const);
  if (role.kind === "glyph") {
    const Glyph = GLYPHS[role.name];
    return <Glyph weight={weight} size={size} className={className} {...a11y} />;
  }
  const P = PHOSPHOR[role.component];
  return <P weight={weight} size={size} color="currentColor" className={className} {...a11y} />;
}
