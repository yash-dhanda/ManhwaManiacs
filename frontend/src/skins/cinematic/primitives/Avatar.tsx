"use client";
import { FilmSlateIcon, FireIcon, FlashlightIcon, GhostIcon, HeartIcon, MagicWandIcon, MoonStarsIcon, NewspaperIcon, PenNibIcon, StarIcon, SwordIcon, BookOpenTextIcon } from "@phosphor-icons/react/ssr";
import type { CSSProperties } from "react";
import { avatarPreset, type AvatarSize } from "./avatar-presets";
import { Badge } from "./Badge";

const GLYPH = { FilmSlate: FilmSlateIcon, Newspaper: NewspaperIcon, Heart: HeartIcon, Flashlight: FlashlightIcon, PenNib: PenNibIcon, Fire: FireIcon, Sword: SwordIcon, Ghost: GhostIcon, MagicWand: MagicWandIcon, MoonStars: MoonStarsIcon, Star: StarIcon, BookOpenText: BookOpenTextIcon } as const;

/** §7.25 circle avatar: field colour with a radial darkening to 60 % black at the rim, a Fill glyph at 45 % of the diameter in ink.100. */
export function Avatar({ presetKey, size = 44, selected = false, mature = false, reading, label }: {
  presetKey?: string | null; size?: AvatarSize; selected?: boolean; mature?: boolean; label?: string;
  /** Series ambient.duo while the profile is reading: draws the ReadingNowRing. */
  reading?: string | null;
}) {
  const p = avatarPreset(presetKey);
  const G = GLYPH[p.glyph];
  const ring: CSSProperties = selected ? { boxShadow: "0 0 0 3px #000, 0 0 0 5px var(--mm-color-spot)" } : reading ? { boxShadow: `0 0 0 3px #000, 0 0 0 5px ${reading}`, transition: "box-shadow 800ms var(--mm-ease-turn)" } : {};
  return (
    <span className="relative inline-flex shrink-0" style={{ width: size, height: size }} role="img" aria-label={label ?? p.name}>
      <span className="inline-flex items-center justify-center rounded-round text-ink-100" style={{ width: size, height: size, background: `radial-gradient(circle at 50% 50%, ${p.field} 55%, color-mix(in srgb, ${p.field} 40%, black) 100%)`, ...ring }}>
        <G aria-hidden size={Math.round(size * 0.45)} weight="fill" color="currentColor" />
      </span>
      {mature ? <span className="absolute right-0 bottom-0"><Badge variant="certificate" onArt /></span> : null}
    </span>
  );
}
