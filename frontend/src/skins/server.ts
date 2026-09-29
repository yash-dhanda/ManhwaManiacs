import { createElement } from "react";
import { cookies } from "next/headers";
import { notFound } from "next/navigation";
import type { ScreenId } from "./contract.generated";
import { skins } from "./index";
import { resolveSkin, SKIN_COOKIE, SKIN_DEBUG_COOKIE, type SkinId } from "./types";

export type RouteProps = {
  params: Promise<Record<string, string | string[]>>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/** The skin this request renders in (see `resolveSkin`). */
export async function getSkin(): Promise<SkinId> {
  const jar = await cookies();
  return resolveSkin(jar.get(SKIN_DEBUG_COOKIE)?.value, jar.get(SKIN_COOKIE)?.value);
}

/** Render `id` in the request's skin; a skin without that screen is a 404 (only legacy can lack one). */
export async function renderScreen(id: ScreenId, props: RouteProps, variant?: "browse") {
  const screen = skins[await getSkin()].screens[id];
  if (!screen) notFound();
  return createElement(screen, { screenId: id, variant, ...props });
}
