import type { Command } from "@/lib/command-palette";
import { NAV_ITEMS } from "./nav-map";

/** The settings sections the palette names (web/18 extends it to every row). */
export const PALETTE_SETTINGS: { id: string; label: string; admin?: boolean; novels?: boolean }[] = [
  { id: "profile", label: "Profile & account" },
  { id: "appearance", label: "Appearance" },
  { id: "reading-manga", label: "Reading: manga" },
  { id: "reading-novels", label: "Reading: novels", novels: true },
  { id: "listen", label: "Listen" },
  { id: "ambient", label: "Ambient" },
  { id: "storage", label: "Downloads & storage" },
  { id: "content", label: "Content" },
  { id: "circle", label: "Circle & privacy" },
  { id: "feedback", label: "Feedback" },
  { id: "notifications", label: "Notifications" },
  { id: "keyboard", label: "Keyboard" },
  { id: "admin", label: "Admin", admin: true },
  { id: "about", label: "About" },
];

/** Series title for the Continue action: the row's own title, else the followed-index join, else the key. */
export const continueTitle = (c: { title?: string | null; source_id: string; series_key: string }, titles: ReadonlyMap<string, string>) =>
  c.title ?? titles.get(`${c.source_id}:${c.series_key}`) ?? c.series_key;

export type PaletteInput = {
  series: { id: number; title: string; chapterCount: number; sourceId: string; coverUrl?: string | null }[];
  sources: { id: string; name: string; description?: string; iconUrl?: string | null }[];
  isAdmin: boolean;
  novelsEnabled: boolean;
  novelMode: boolean;
  glassAvailable: boolean;
  continue?: { title: string; href: string } | null;
};
export type PaletteData = { commands: Command[]; folios: Record<string, string> };

/** Pure: every palette row (§8.33.1). Groups rank Library, Sources, Go to, Actions, Edition, Settings; `rankCommands` caps at 40. */
export function buildPaletteCommands(i: PaletteInput): PaletteData {
  const folios: Record<string, string> = {};
  const commands: Command[] = [];
  for (const s of i.series) commands.push({ id: `series:${s.id}`, title: s.title, subtitle: `${s.chapterCount} chapters`, group: "Library", kind: "series", href: `/library/${s.id}`, keywords: [s.sourceId], imageUrl: s.coverUrl });
  for (const s of i.sources) commands.push({ id: `source:${s.id}`, title: s.name, subtitle: s.description || "Browse this source", group: "Sources", kind: "source", href: `/sources/${encodeURIComponent(s.id)}`, keywords: [s.id], imageUrl: s.iconUrl });
  for (const n of NAV_ITEMS) {
    if (n.id === "dialogue" && i.novelMode) continue;
    const id = `route:${n.href}`;
    folios[id] = n.folio;
    commands.push({ id, title: n.label, subtitle: n.href, group: "Go to", kind: "route", href: n.href, keywords: [n.folio, n.label] });
  }
  for (const r of [{ t: "Index", h: "/more" }, { t: "Profiles", h: "/profiles/manage" }, { t: "Settings", h: "/settings" }, ...(i.isAdmin ? [{ t: "Status", h: "/admin/status" }] : [])]) {
    commands.push({ id: `route:${r.h}`, title: r.t, subtitle: r.h, group: "Go to", kind: "route", href: r.h, keywords: [r.t] });
  }
  if (i.continue) commands.push({ id: "action:continue", title: `Continue ${i.continue.title}`, subtitle: "Pick up where you stopped", group: "Actions", kind: "action", href: i.continue.href, keywords: ["resume", "read"] });
  commands.push({ id: "action:check", title: "Check for updates", subtitle: "Look for new chapters now", group: "Actions", kind: "action", keywords: ["refresh", "new chapters"] });
  commands.push({ id: "action:settings", title: "Open settings", subtitle: "Appearance, notifications, downloads, shortcuts", group: "Actions", kind: "action", keywords: ["preferences", "options"] });
  if (i.novelsEnabled) commands.push({ id: "action:mode", title: i.novelMode ? "Switch to manga" : "Switch to novels", subtitle: "Toggle reading mode", group: "Actions", kind: "action", keywords: ["reading mode", "manga", "novels"] });
  commands.push({ id: "action:sign-out", title: "Sign out", subtitle: "End this session", group: "Actions", kind: "action", keywords: ["logout", "log out"] });
  // EDITION arrives with web/18 while Glass is not available.
  for (const s of PALETTE_SETTINGS) {
    if (s.admin && !i.isAdmin) continue;
    if (s.novels && !i.novelsEnabled) continue;
    commands.push({ id: `route:/settings/${s.id}`, title: s.label, subtitle: "Settings", group: "Settings", kind: "route", href: `/settings/${s.id}`, keywords: ["settings", s.id] });
  }
  return { commands, folios };
}
