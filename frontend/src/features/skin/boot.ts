import type { SkinId } from "@/skins/types";

/** Boot resolution, stack §2.4 steps 1-5. Pure. */
export function resolveBootSkin(i: {
  rendered: SkinId;
  debug: SkinId | null;
  profileSkin: "cinematic" | "glass" | null | undefined;
  glassAvailable: boolean;
  defaultSkin: SkinId;
}): { restartTo: SkinId | null } {
  if (i.debug) return { restartTo: i.debug !== i.rendered ? i.debug : null };
  if (i.profileSkin === undefined) return { restartTo: null };
  let desired: SkinId = i.profileSkin ?? i.defaultSkin;
  if (desired === "glass" && !i.glassAvailable) desired = "cinematic";
  return { restartTo: desired === i.rendered ? null : desired };
}
