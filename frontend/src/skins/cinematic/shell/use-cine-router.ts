"use client";
import { useRouter } from "next/navigation";
import { useMemo } from "react";

/** §8.0.4 navigation kinds. Browser back (popstate) carries none and gets no animation. */
export type NavKind = "forward" | "back" | "section" | "match";
const TYPE: Record<NavKind, string> = { forward: "nav-forward", back: "nav-back", section: "nav-section", match: "nav-match" };
export const transitionTypesFor = (nav: NavKind = "forward"): string[] => [TYPE[nav]];

/** `router.push` with the view-transition type of the navigation. */
export function useCineRouter() {
  const router = useRouter();
  return useMemo(() => ({
    push: (href: string, nav: NavKind = "forward") => router.push(href, { transitionTypes: transitionTypesFor(nav) }),
    replace: (href: string, nav: NavKind = "forward") => router.replace(href, { transitionTypes: transitionTypesFor(nav) }),
    back: () => router.back(),
    prefetch: (href: string) => router.prefetch(href),
  }), [router]);
}
