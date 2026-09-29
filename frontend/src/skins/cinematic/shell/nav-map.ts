import { ROUTES, SETTINGS_SECTION_SPECS, type SettingsSection } from "../../contract.generated";

export type NavItemId = "tonight" | "library" | "updates" | "discover" | "downloads" | "collections" | "history" | "bookmarks" | "dialogue" | "numbers" | "circle" | "picks";
export type FooterItemId = "profiles" | "settings" | "status";
export type Lit = NavItemId | FooterItemId | null;

export type NavItem = { id: NavItemId; folio: string; label: string; href: string; g: string; group: "issue" | "back" };
/** §7.15 items, in order. */
export const NAV_ITEMS: readonly NavItem[] = [
  { id: "tonight", folio: "01", label: "Tonight", href: ROUTES.tonight(), g: "1", group: "issue" },
  { id: "library", folio: "02", label: "Library", href: ROUTES.library(), g: "2", group: "issue" },
  { id: "updates", folio: "03", label: "Updates", href: ROUTES.updates(), g: "3", group: "issue" },
  { id: "discover", folio: "04", label: "Discover", href: ROUTES.discover(), g: "4", group: "issue" },
  { id: "downloads", folio: "05", label: "Downloads", href: ROUTES.downloads(), g: "5", group: "issue" },
  { id: "collections", folio: "06", label: "Collections", href: ROUTES.collections(), g: "6", group: "back" },
  { id: "history", folio: "07", label: "History", href: ROUTES.history(), g: "7", group: "back" },
  { id: "bookmarks", folio: "08", label: "Bookmarks", href: ROUTES.bookmarks(), g: "8", group: "back" },
  { id: "dialogue", folio: "09", label: "Dialogue", href: ROUTES.dialogue(), g: "9", group: "back" },
  { id: "numbers", folio: "10", label: "The Numbers", href: ROUTES.numbers(), g: "10", group: "back" },
  { id: "circle", folio: "11", label: "Circle", href: ROUTES.circle(), g: "11", group: "back" },
  { id: "picks", folio: "12", label: "Picks", href: ROUTES.picks(), g: "12", group: "back" },
];
const BY_ID = new Map(NAV_ITEMS.map((i) => [i.id, i]));
export const navItem = (id: NavItemId) => BY_ID.get(id)!;

const seg = (p: string) => p.split("?")[0].split("/").filter(Boolean);
/** Static `/library/<x>` paths, matched before `/library/:followedId`. */
const LIBRARY_STATIC = new Set(["browse", "collections", "history", "bookmarks", "statistics", "recommendations"]);

/** Feature and book pages plus recaps: they keep the item lit before the navigation. */
export function isHeldRoute(pathname: string): boolean {
  const s = seg(pathname);
  if (s[0] === "recap") return true;
  if (s[0] === "sources" && s[2] === "series" && s.length >= 4) return true;
  if (s[0] === "library" && s.length === 2 && !LIBRARY_STATIC.has(s[1])) return true;
  return false;
}

const SECTION_TITLE: Partial<Record<SettingsSection, string>> = {
  "reading-manga": "READING: MANGA", "reading-novels": "READING: NOVELS", storage: "DOWNLOADS & STORAGE", circle: "CIRCLE & PRIVACY", profile: "PROFILE & ACCOUNT", server: "SERVER", about: "ABOUT",
};
export function settingsSectionTitle(section: string): string {
  if (section in SETTINGS_SECTION_SPECS) return SECTION_TITLE[section as SettingsSection] ?? section.toUpperCase();
  return section.toUpperCase();
}

export type Resolved = {
  /** The lit sidebar item (null: none, or a takeover without a sidebar). */
  lit: Lit;
  /** `No. 02 · LIBRARY`, `PROFILES`, `SETTINGS`, `INDEX`. */
  crumb: string;
  /** A static tail (`SOURCES`, a settings section), when the route names one itself. */
  tail?: string;
  /** True when the tail is the screen's own name (series, shelf, member, source): read from `useRunningHead().breadcrumbTail`. */
  dynamicTail: boolean;
};

const no = (id: NavItemId) => `No. ${navItem(id).folio} · ${navItem(id).label.toUpperCase()}`;
const item = (id: NavItemId, tail?: string, dynamicTail = false): Resolved => ({ lit: id, crumb: no(id), tail, dynamicTail });

/**
 * Pure: the §7.15 route table. `held` is the item lit before the navigation (feature pages and recaps keep it);
 * `followed` decides the cold-load fallback (Library when the series is followed, else Discover).
 */
export function resolveNav(pathname: string, ctx: { held?: NavItemId | null; followed?: boolean } = {}): Resolved {
  const s = seg(pathname);
  const [a, b] = s;
  if (s.length === 0) return item("tonight");
  if (isHeldRoute(pathname)) {
    const id = ctx.held ?? (ctx.followed ? "library" : "discover");
    return item(id, undefined, true);
  }
  switch (a) {
    case "library":
      if (s.length === 1 || b === "browse") return item("library");
      if (b === "collections") return item("collections", undefined, s.length > 2);
      if (b === "history") return item("history");
      if (b === "bookmarks") return item("bookmarks");
      if (b === "statistics") return item("numbers");
      if (b === "recommendations") return item("picks");
      break;
    case "updates": return item("updates");
    case "search": return item("discover");
    case "sources": return s.length === 1 ? item("discover", "SOURCES") : item("discover", undefined, true);
    case "downloads": return item("downloads");
    case "ocr": return item("dialogue");
    case "circle": return item("circle", undefined, s.length > 1);
    case "profiles": return { lit: "profiles", crumb: "PROFILES", dynamicTail: false };
    case "settings": return { lit: "settings", crumb: "SETTINGS", tail: b ? settingsSectionTitle(b) : undefined, dynamicTail: false };
    case "admin": return { lit: "status", crumb: "STATUS", dynamicTail: false };
    case "more": return { lit: null, crumb: "INDEX", dynamicTail: false };
  }
  return { lit: null, crumb: "", dynamicTail: false };
}

/** The item a pathname lights when it is a plain section (fills the shell's held state). */
export function litItemFor(pathname: string): NavItemId | null {
  if (isHeldRoute(pathname)) return null;
  const l = resolveNav(pathname).lit;
  return l && BY_ID.has(l as NavItemId) ? (l as NavItemId) : null;
}

/** Thumb-index branches (§8.0.3). */
export type Branch = "tonight" | "library" | "discover" | "downloads" | "index";
export const BRANCH_ROOTS: Record<Branch, string> = { tonight: "/", library: "/library", discover: "/search", downloads: "/downloads", index: "/more" };
export type ThumbState = { visible: boolean; active: Branch | null };

/** Pure: whether the thumb index shows and which branch is active. Feature pages, readers, auth and takeovers hide it; unknown routes show it with no tab lit. */
export function thumbFor(pathname: string): ThumbState {
  const s = seg(pathname);
  const [a, b] = s;
  const on = (active: Branch | null): ThumbState => ({ visible: true, active });
  const off: ThumbState = { visible: false, active: null };
  if (s.length === 0) return on("tonight");
  if (isHeldRoute(pathname)) return off;
  switch (a) {
    case "login": case "register": case "welcome": case "recap": case "read-all": case "novels": case "setup": return off;
    case "reader": return s.length === 1 ? on(null) : off;
    case "profiles": return s.length === 1 ? off : on("index");
    case "library":
      if (b === "statistics") return s[2] === "annual" ? off : on("index");
      if (b === "recommendations") return on("discover");
      return on("library");
    case "updates": return on("library");
    case "search": case "ocr": case "sources": return on("discover");
    case "downloads": return on("downloads");
    case "more": case "settings": case "admin": case "circle": return on("index");
  }
  return on(null);
}
