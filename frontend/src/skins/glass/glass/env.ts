"use client";

import { useSyncExternalStore } from "react";
import { isGlassReduced } from "../motion";

const MQ = ["(prefers-contrast: more)", "(prefers-reduced-transparency: reduce)", "(prefers-reduced-motion: reduce)"] as const;

export interface GlassEnv {
  /** Increase Contrast (`html[data-contrast="more"]` or the media query) */
  hc: boolean;
  /** Solid glass (`html[data-solid="on"]`) or Reduce Transparency */
  solid: boolean;
  reduced: boolean;
  /** rendering tier stamped by the boot script (never a device tier) */
  renderer: "liquid" | "frosted";
}

const SERVER = "000frosted";

function read(): string {
  const d = document.documentElement.dataset;
  const hc = d.contrast === "more" || matchMedia(MQ[0]).matches;
  const solid = d.solid === "on" || matchMedia(MQ[1]).matches;
  return `${+hc}${+solid}${+isGlassReduced()}${d.glassRenderer === "liquid" ? "liquid" : "frosted"}`;
}

function subscribe(cb: () => void) {
  const mqs = MQ.map((q) => matchMedia(q));
  mqs.forEach((m) => m.addEventListener("change", cb));
  const mo = new MutationObserver(cb);
  mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-contrast", "data-solid", "data-motion", "data-glass-renderer"] });
  return () => { mqs.forEach((m) => m.removeEventListener("change", cb)); mo.disconnect(); };
}

/** The document-level material switches every surface reacts to. */
export function useGlassEnv(): GlassEnv {
  const s = useSyncExternalStore(subscribe, read, () => SERVER);
  return { hc: s[0] === "1", solid: s[1] === "1", reduced: s[2] === "1", renderer: s.slice(3) === "liquid" ? "liquid" : "frosted" };
}
