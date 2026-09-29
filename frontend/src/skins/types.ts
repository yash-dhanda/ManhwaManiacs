import type { ComponentType, ReactNode } from "react";
import { FLAGS, type ScreenId } from "./contract.generated";

export const SKIN_IDS = ["cinematic", "glass", "legacy"] as const;
export type SkinId = (typeof SKIN_IDS)[number];

export function isSkinId(value: unknown): value is SkinId {
  return typeof value === "string" && (SKIN_IDS as readonly string[]).includes(value);
}

// release/00 changes this to "cinematic" and deletes "legacy".
export const DEFAULT_SKIN: SkinId = "legacy";

export const SKIN_COOKIE = "mm-skin";
export const SKIN_DEBUG_COOKIE = "mm-skin-debug";

/**
 * The skin a request renders in, from its two cookies. Precedence: the
 * `mm-skin-debug` preview cookie (any skin, Glass included), then the `mm-skin`
 * device mirror (Glass falls back to Cinematic while `FLAGS.glassAvailable` is
 * false, cinematic §8.0.7), then `DEFAULT_SKIN`. Invalid values are ignored.
 */
export function resolveSkin(debug: string | undefined, mirror: string | undefined): SkinId {
  if (isSkinId(debug)) return debug;
  if (isSkinId(mirror)) return mirror === "glass" && !FLAGS.glassAvailable ? "cinematic" : mirror;
  return DEFAULT_SKIN;
}

export interface ScreenProps {
  screenId: ScreenId;
  params: Promise<Record<string, string | string[]>>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
  variant?: "browse";
}

export type Screen = (props: ScreenProps) => ReactNode | Promise<ReactNode>;

export interface Skin {
  id: SkinId;
  fontClassName: string;
  Shell: ComponentType<{ children: ReactNode }>;
  screens: Partial<Record<ScreenId, Screen>>;
}
