"use client";
import { useRouter } from "next/navigation";
import { useMemo } from "react";
import { haptic } from "../haptics";
import { playSound } from "../sounds";

/** §8.0.4 navigation kinds. Browser back (popstate) carries none and gets no animation. */
export type NavKind = "forward" | "back" | "section" | "match";
const TYPE: Record<NavKind, string> = { forward: "nav-forward", back: "nav-back", section: "nav-section", match: "nav-match" };
export const transitionTypesFor = (nav: NavKind = "forward"): string[] => [TYPE[nav]];

/** The cue every section change carries: haptic plus the `tick` sound. */
export const navCue = () => { haptic("nav.change"); playSound("nav.change"); };

/** `router.push` with the view-transition type of the navigation. */
export function useCineRouter() {
  const router = useRouter();
  return useMemo(() => ({
    push: (href: string, nav: NavKind = "forward") => { if (nav === "section") navCue(); return router.push(href, { transitionTypes: transitionTypesFor(nav) }); },
    replace: (href: string, nav: NavKind = "forward") => { if (nav === "section") navCue(); return router.replace(href, { transitionTypes: transitionTypesFor(nav) }); },
    back: () => router.back(),
    prefetch: (href: string) => router.prefetch(href),
  }), [router]);
}
