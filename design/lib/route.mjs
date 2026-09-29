// Route builders shared by both clients (cinematic/DESIGN.md §8.0.3 "Encoded route builders").
// buildRoute's body is copied verbatim into contract.generated.ts by emit-ts.mjs, so keep it
// plain JavaScript that also type-checks as TypeScript.

export function buildRoute(pattern, params, query) {
  let i = 0;
  const path = pattern.replace(/:[A-Za-z]+/g, () => encodeURIComponent(String(params[i++])));
  const entries = [];
  for (const [k, v] of Object.entries(query ?? {})) if (v !== undefined && v !== null) entries.push([k, String(v)]);
  const qs = new URLSearchParams(entries).toString();
  return qs ? path + "?" + qs : path;
}

// A screen whose only extra shape is one trailing `/:param` alias (settings) takes that
// param as an optional argument: go_router has no optional segments, so the contract
// lists the second shape as an alias.
export function optionalSegment(screen) {
  const a = screen.aliases.find((x) => x.path.startsWith(screen.path + "/:") && x.platforms.length === 2);
  return a && !a.path.slice(screen.path.length + 2).includes("/") ? { name: a.path.slice(screen.path.length + 2), pattern: a.path } : null;
}

export function makeRoutes(screens) {
  const routes = {};
  for (const s of screens) {
    const opt = optionalSegment(s);
    routes[s.id] = opt
      ? (value, query) => (value === undefined ? buildRoute(s.path, [], query) : buildRoute(opt.pattern, [value], query))
      : (...args) => buildRoute(s.path, args.slice(0, s.params.length), args[s.params.length]);
  }
  return routes;
}
