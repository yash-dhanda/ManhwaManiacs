import { createElement } from "react";
import { cookies } from "next/headers";
import { notFound } from "next/navigation";
import { FLAGS, type ScreenId } from "./contract.generated";
import { skins } from "./index";
import { DEFAULT_SKIN, isSkinId, SKIN_COOKIE, SKIN_DEBUG_COOKIE, type SkinId } from "./types";

export type RouteProps = {
  params: Promise<Record<string, string | string[]>>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/**
 * The skin this request renders in. Precedence: the `mm-skin-debug` preview
 * cookie (any skin, Glass included), then the `mm-skin` device mirror (Glass
 * falls back to Cinematic while `FLAGS.glassAvailable` is false, cinematic
 * §8.0.7), then `DEFAULT_SKIN`. Invalid values are ignored.
 */
export async function getSkin(): Promise<SkinId> {
  const jar = await cookies();
  const debug = jar.get(SKIN_DEBUG_COOKIE)?.value;
  if (isSkinId(debug)) return debug;
  const mirror = jar.get(SKIN_COOKIE)?.value;
  if (isSkinId(mirror)) {
    return mirror === "glass" && !FLAGS.glassAvailable ? "cinematic" : mirror;
  }
  return DEFAULT_SKIN;
}

/** Render `id` in the request's skin; a skin without that screen is a 404 (only legacy can lack one). */
export async function renderScreen(id: ScreenId, props: RouteProps, variant?: "browse") {
  const screen = skins[await getSkin()].screens[id];
  if (!screen) notFound();
  return createElement(screen, { screenId: id, variant, ...props });
}
