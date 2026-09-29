import { color } from "../tokens.generated";

/** §7.25: twelve presets, each a field colour and a Phosphor Fill glyph at 45 % of the diameter. */
export const AVATAR_PRESETS = {
  violet: { name: "Matinee", field: color.avatarViolet, glyph: "FilmSlate" },
  cyan: { name: "Newsreel", field: color.avatarCyan, glyph: "Newspaper" },
  rose: { name: "Romance", field: color.avatarRose, glyph: "Heart" },
  amber: { name: "Usher", field: color.avatarAmber, glyph: "Flashlight" },
  emerald: { name: "Critic", field: color.avatarEmerald, glyph: "PenNib" },
  ember: { name: "Premiere", field: color.avatarEmber, glyph: "Fire" },
  blade: { name: "Swordplay", field: color.avatarBlade, glyph: "Sword" },
  phantom: { name: "Phantom", field: color.avatarPhantom, glyph: "Ghost" },
  arcane: { name: "Illusionist", field: color.avatarArcane, glyph: "MagicWand" },
  lunar: { name: "Late show", field: color.avatarLunar, glyph: "MoonStars" },
  star: { name: "Marquee", field: color.avatarStar, glyph: "Star" },
  reader: { name: "Bookworm", field: color.avatarReader, glyph: "BookOpenText" },
} as const;

export type AvatarKey = keyof typeof AVATAR_PRESETS;
export const AVATAR_SIZES = [20, 24, 28, 32, 44, 56, 96, 112, 144] as const;
export type AvatarSize = (typeof AVATAR_SIZES)[number];
/** Unknown keys fall back to Matinee (violet). */
export const avatarPreset = (key: string | null | undefined) => AVATAR_PRESETS[(key as AvatarKey) in AVATAR_PRESETS ? (key as AvatarKey) : "violet"];
