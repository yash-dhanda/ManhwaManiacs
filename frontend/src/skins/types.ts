import type { ComponentType, ReactNode } from "react";
import type { ScreenId } from "./contract.generated";

export const SKIN_IDS = ["cinematic", "glass", "legacy"] as const;
export type SkinId = (typeof SKIN_IDS)[number];

export function isSkinId(value: unknown): value is SkinId {
  return typeof value === "string" && (SKIN_IDS as readonly string[]).includes(value);
}

// release/00 changes this to "cinematic" and deletes "legacy".
export const DEFAULT_SKIN: SkinId = "legacy";

export const SKIN_COOKIE = "mm-skin";
export const SKIN_DEBUG_COOKIE = "mm-skin-debug";

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
