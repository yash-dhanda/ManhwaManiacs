import { Icon } from "../../Icon";
import type { IconRole } from "../../icons/roles.generated";

const ROLE: Record<string, IconRole> = {
  plus: "follow",
  check: "following",
  star: "favourite",
  bell: "notify",
  download: "download",
  dots: "overflow",
  scroll: "strip-mode",
  back: "back",
  x: "close",
  headphones: "listen",
  search: "search",
  certificate: "age-gate",
};

/** Local names for the shared Cinematic icon roles (web/01). */
export function Glyph({ name, fill, size = 24 }: { name: string; fill?: boolean; size?: 16 | 20 | 24 }) {
  return <Icon name={ROLE[name] ?? "follow"} size={size} filled={fill} />;
}
