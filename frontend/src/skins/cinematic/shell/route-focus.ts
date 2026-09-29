"use client";
import { usePathname } from "next/navigation";
import { useEffect, useRef } from "react";
import { frameFor } from "./frames";

const SUFFIX = " · ManhwaManiacs";
const h1Text = (h: Element) => (h.getAttribute("aria-label") ?? h.querySelector(".sr-only")?.textContent ?? h.textContent ?? "").trim();

/** Focus `main h1` (masthead h1s carry tabIndex -1) and return it. */
export function focusMainHeading(): boolean {
  const h1 = document.querySelector<HTMLElement>("main h1");
  if (!h1) return false;
  if (!h1.hasAttribute("tabindex")) h1.setAttribute("tabindex", "-1"); // masthead h1s carry it; a bare screen's h1 gets it here
  h1.focus({ preventScroll: true });
  return true;
}

/**
 * Route focus (§14.4): after each pathname change (not a search-param change), once the new `main h1` exists, focus it and set
 * `document.title` to `{h1 text} · ManhwaManiacs`. The first load only sets the title, so the skip link stays the first Tab stop.
 * Reader and Page frames are left to web/12 and web/14, which focus the reading surface.
 */
export function useRouteFocus() {
  const pathname = usePathname() ?? "/";
  const prev = useRef<string | null>(null); // strict mode re-runs the effect with the same pathname: that is not a navigation
  useEffect(() => {
    const frame = frameFor(pathname);
    const isFirst = prev.current === null || prev.current === pathname;
    prev.current = pathname;
    if (frame === "reader" || frame === "page") return;
    let raf = 0, tries = 0, mo: MutationObserver | null = null;
    const apply = () => {
      const h1 = document.querySelector("main h1");
      if (!h1) return false;
      const t = h1Text(h1);
      if (t) document.title = t + SUFFIX;
      // Never pull focus out of an open dialog or a field the user has already reached (the h1 can render late).
      if (!isFirst && !document.activeElement?.closest("[role=dialog], input, textarea")) focusMainHeading();
      return true;
    };
    const poll = () => { if (apply()) return; if (tries++ < 120) raf = requestAnimationFrame(poll); };
    poll();
    // The masthead h1 may render its text later than it mounts.
    const h1 = document.querySelector("main h1");
    if (h1) { mo = new MutationObserver(() => { const t = h1Text(h1); if (t) document.title = t + SUFFIX; }); mo.observe(h1, { childList: true, subtree: true, characterData: true, attributes: true, attributeFilter: ["aria-label"] }); setTimeout(() => mo?.disconnect(), 3000); }
    // Next re-writes the metadata title after a hard load of a route with no title of its own (the 404); win that race.
    const head = new MutationObserver(() => { const h = document.querySelector("main h1"); const t = h ? h1Text(h) : ""; if (t && document.title !== t + SUFFIX) document.title = t + SUFFIX; });
    head.observe(document.head, { childList: true, subtree: true, characterData: true });
    const stopHead = setTimeout(() => head.disconnect(), 3000);
    return () => { cancelAnimationFrame(raf); mo?.disconnect(); head.disconnect(); clearTimeout(stopHead); };
  }, [pathname]);
}
