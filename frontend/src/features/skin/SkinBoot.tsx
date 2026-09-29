"use client";

import { useEffect } from "react";
import { useProfiles } from "@/features/profiles/hooks";
import { useActiveProfileStore } from "@/features/profiles/store";
import { applyBootA11y, readBootA11y } from "@/features/preferences/boot-a11y";
import { SKIN_MESSAGE } from "@/features/offline/protocol";
import { subscribeStorageScope } from "@/lib/scoped-storage";
import { logSkinRestart } from "@/lib/motion-timings";
import { armSounds as armCinematicSounds } from "@/skins/cinematic/sounds";
import { armSounds as armGlassSounds } from "@/skins/glass/sounds";
import { FLAGS } from "@/skins/contract.generated";
import { DEFAULT_SKIN, isSkinId, type SkinId } from "@/skins/types";
import { resolveBootSkin } from "./boot";
import {
  BOOT_RESTART_KEY,
  postToWorker,
  readCookie,
  restartInto,
  RETURN_KEY,
} from "./skin-storage";

const LOOP_GUARD_MS = 10_000;

function renderedSkin(): SkinId {
  const v = document.documentElement.dataset.skin;
  return isSkinId(v) ? v : DEFAULT_SKIN;
}

/** Skin-neutral boot work: tell the worker, time a restart, reconcile the profile's skin, stamp a11y. */
export function SkinBoot() {
  const activeId = useActiveProfileStore((s) => s.activeProfile?.id ?? null);
  const { data: profiles } = useProfiles();

  useEffect(() => {
    const rendered = renderedSkin();
    const tell = () => postToWorker({ type: SKIN_MESSAGE.boot, skin: rendered });
    tell();
    navigator.serviceWorker?.addEventListener("controllerchange", tell);
    try {
      sessionStorage.removeItem(RETURN_KEY);
    } catch {
      // ignore
    }
    // Fallback until each skin's Splash logs on its own first frame; whichever runs first clears t0.
    const raf = requestAnimationFrame(() => logSkinRestart(rendered));
    return () => {
      cancelAnimationFrame(raf);
      navigator.serviceWorker?.removeEventListener("controllerchange", tell);
    };
  }, []);

  useEffect(() => {
    const apply = () => applyBootA11y(document.documentElement, readBootA11y());
    apply();
    return subscribeStorageScope(apply);
  }, []);

  // Sounds already on for this profile: listen for the first gesture so the first cue is not dropped.
  useEffect(() => {
    if (activeId === null) return;
    armCinematicSounds();
    armGlassSounds();
  }, [activeId]);

  useEffect(() => {
    if (activeId === null || !profiles) return;
    const row = profiles.find((p) => p.id === activeId);
    if (!row) return;
    const rendered = renderedSkin();
    const debug = readCookie("mm-skin-debug");
    const { restartTo } = resolveBootSkin({
      rendered,
      debug: isSkinId(debug) ? debug : null,
      profileSkin: row.skin ?? null,
      glassAvailable: FLAGS.glassAvailable,
      defaultSkin: DEFAULT_SKIN,
    });
    if (!restartTo) return;
    try {
      const [skin, at] = (sessionStorage.getItem(BOOT_RESTART_KEY) ?? "").split(":");
      if (skin === restartTo && Date.now() - Number(at) < LOOP_GUARD_MS) {
        console.warn(`Skin boot: ${restartTo} did not take; staying in ${rendered}`);
        return;
      }
      sessionStorage.setItem(BOOT_RESTART_KEY, `${restartTo}:${Date.now()}`);
    } catch {
      // Storage blocked: restart once; the cookie write below is the only guard left.
    }
    restartInto({
      cookie: "mm-skin",
      skin: restartTo,
      from: rendered,
      returnPath: location.pathname + location.search,
    });
  }, [activeId, profiles]);

  return null;
}
