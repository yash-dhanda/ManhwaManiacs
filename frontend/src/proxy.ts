import { NextResponse, type NextRequest } from "next/server";
import { SCREENS, type ScreenId, type ScreenSpec } from "./skins/contract.generated";
import { resolveSkin, SKIN_COOKIE, SKIN_DEBUG_COOKIE } from "./skins/types";

/**
 * Legacy's 404. Next 16 answers a `notFound()` thrown during the server render
 * with its bare error document, and legacy's AppShell never renders the page on
 * the server anyway, so a thrown 404 reached legacy users as a 200 and a
 * client-side error. Instead, every legacy request for a URL legacy has no
 * screen for is rewritten, with the 404 status, to `/legacy-not-found`, which
 * renders the not-found screen as a page: what Next's own not-found route did
 * before the skins. Deleted with legacy at the flip (release/00).
 */

// The ScreenIds legacy has no screen for (see `screens` in ./skins/legacy/index.ts).
const LEGACY_LACKS = new Set<ScreenId>([
  "setup", "profileNew", "profileEdit", "onboarding", "tonight", "annual", "recap", "circle", "circleMember",
]);

// Route file paths from the contract; the readers' chapter keys are catch-alls (`[...chapterKey]`).
const ROUTES = Object.entries(SCREENS as Record<ScreenId, ScreenSpec>)
  .flatMap(([id, spec]) =>
    [spec.path, ...spec.aliases.filter((a) => a.platforms.includes("web")).map((a) => a.path)].map((path) => ({
      id: id as ScreenId,
      path,
      params: (path.match(/:/g) ?? []).length,
      re: new RegExp(`^${path.replace(/:chapterKey$/, ".+").replace(/:\w+/g, "[^/]+")}/?$`),
    })),
  )
  // Static segments win over dynamic ones, as in Next's router.
  .sort((a, b) => a.params - b.params);

/** The route a pathname lands on, or undefined for the `[...missing]` catch-all. */
export function matchRoute(pathname: string) {
  return ROUTES.find((r) => r.re.test(pathname));
}

export function legacyServes(pathname: string): boolean {
  const route = matchRoute(pathname);
  // `/settings/:section` stays a 404 for legacy (web/02 adds the diagnostics exception here too).
  return !!route && !LEGACY_LACKS.has(route.id) && route.path !== "/settings/:section";
}

export function proxy(req: NextRequest) {
  const skin = resolveSkin(req.cookies.get(SKIN_DEBUG_COOKIE)?.value, req.cookies.get(SKIN_COOKIE)?.value);
  if (skin === "legacy" && !legacyServes(req.nextUrl.pathname)) {
    return NextResponse.rewrite(new URL("/legacy-not-found", req.url), { status: 404 });
  }
}

export const config = {
  // Pages only: no API proxy, Next internals, preview layout or files (anything with a dot).
  matcher: ["/((?!_|api(?:/|$)|skin-preview(?:/|$)|dev(?:/|$)|.*\\.).*)"],
};
