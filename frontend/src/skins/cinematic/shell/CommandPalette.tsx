"use client";
/* eslint-disable @next/next/no-img-element -- 40 px covers and 24 px logos already come through the cookie-gated proxy; next/image cannot fetch them */
import { Dialog } from "@base-ui/react/dialog";
import { useEffect, useId, useMemo, useRef, useState } from "react";
import { useCurrentUser } from "@/features/auth/hooks";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { useChapterHref } from "@/features/novels/use-chapter-href";
import { useContinueReading, useSearch } from "@/features/library/hooks";
import { sourceImageUrl } from "@/features/sources/api";
import { useSources } from "@/features/sources/hooks";
import { useManualCheck } from "@/features/updates/hooks";
import { libraryCoverUrl } from "@/features/library/api";
import { groupCommands, highlightSegments, rankCommands, type Command, type RankedCommand } from "@/lib/command-palette";
import { FLAGS } from "../../contract.generated";
import { Icon } from "../Icon";
import { Keycap } from "../primitives/Keycap";
import { SearchField } from "../primitives/SearchField";
import { buildPaletteCommands } from "./palette-commands";
import { useShellState } from "./shell-state";
import { useCineRouter } from "./use-cine-router";
import { useSignOut } from "./AccountMenu";

const DEBOUNCE_MS = 220;
const SERIES_LIMIT = 8;
const kicker = (g: string) => g.toUpperCase();

function Marked({ text, indices }: { text: string; indices: readonly number[] }) {
  return <>{highlightSegments(text, indices).map((s, i) => s.match ? <mark key={i} className="text-spot" style={{ background: "transparent" }}>{s.text}</mark> : <span key={i}>{s.text}</span>)}</>;
}

/** Fixture-friendly view (gallery): rows already ranked and grouped. */
export function CommandPaletteView({ query, onQuery, groups, folios, active, onActive, onRun, status, count, inputRef, listboxId }: {
  query: string; onQuery: (q: string) => void; groups: { group: string; commands: RankedCommand[] }[]; folios: Record<string, string>;
  active: number; onActive: (i: number) => void; onRun: (c: Command) => void; status: string; count: number; inputRef?: React.Ref<HTMLDivElement>; listboxId: string;
}) {
  let flat = -1;
  return (
    <div data-stock="raised" className="flex max-h-[70vh] w-full max-w-[720px] flex-col overflow-hidden border border-rule-2 bg-paper-2 text-ink-100">
      <div ref={inputRef} className="flex items-center gap-3 px-4 pt-2">
        <div className="min-w-0 flex-1" role="combobox" aria-expanded aria-controls={listboxId} aria-haspopup="listbox">
          <SearchField label="Search or jump" placeholder="Search or jump…" value={query} onChange={onQuery} />
        </div>
        <Keycap combo="escape" />
      </div>
      <div id={listboxId} role="listbox" aria-label="Results" className="min-h-0 flex-1 overflow-y-auto pb-2">
        {count === 0 ? <p className="type-body px-4 py-6 text-ink-60">{query.trim() ? `Nothing matches “${query.trim()}”.` : "Nothing to show yet."}</p> : null}
        {groups.map((g) => (
          <div key={g.group} role="group" aria-label={kicker(g.group)}>
            <p className="type-kicker px-4 pt-3 pb-1 text-ink-45">{kicker(g.group)}</p>
            {g.commands.map((c) => {
              const i = ++flat;
              const on = i === active;
              return (
                <div key={c.id} role="option" id={`pal-${i}`} aria-selected={on} data-active={on || undefined} onMouseMove={() => onActive(i)} onClick={() => onRun(c)}
                  className={`relative flex min-h-14 cursor-pointer items-center gap-3 px-4 py-2 ${on ? "bg-paper-4" : ""}`}>
                  {on ? <span aria-hidden className="absolute inset-y-0 left-0 w-0.5 bg-ink-100" /> : null}
                  <span className="flex w-10 shrink-0 items-center justify-center">
                    {c.kind === "series" && c.imageUrl ? <img alt="" src={c.imageUrl} width={40} height={60} className="h-[60px] w-10 object-cover" />
                      : c.kind === "source" && c.imageUrl ? <img alt="" src={c.imageUrl} width={24} height={24} className="size-6 object-contain" />
                      : folios[c.id] ? <span className="type-folio text-ink-45">{folios[c.id]}</span>
                      : <Icon name={c.kind === "action" ? "play" : "settings"} size={20} className="text-ink-60" />}
                  </span>
                  <span className="min-w-0 flex-1">
                    <span className="type-ui block truncate"><Marked text={c.title} indices={c.match.indices} /></span>
                    {c.subtitle ? <span className="type-caption block truncate text-ink-45">{c.subtitle}</span> : null}
                  </span>
                  {on ? <span aria-hidden className="type-ui text-ink-60">↵</span> : null}
                </div>
              );
            })}
          </div>
        ))}
      </div>
      <div className="flex items-center gap-4 border-t border-rule-1 px-4 py-2 text-ink-45">
        <span className="flex items-center gap-1"><Keycap combo="↑" /><Keycap combo="↓" /><span className="type-caption">navigate</span></span>
        <span className="flex items-center gap-1"><Keycap combo="enter" /><span className="type-caption">open</span></span>
        <span className="type-caption ml-auto">{count} {count === 1 ? "result" : "results"}</span>
      </div>
      <p role="status" aria-live="polite" className="sr-only">{status}</p>
    </div>
  );
}

/** §8.33.1 the command palette "Index". Lazy: this module loads on first open. */
export default function CommandPalette() {
  const open = useShellState((s) => s.paletteOpen);
  const setOpen = useShellState((s) => s.setPaletteOpen);
  const router = useCineRouter();
  const was = useRef(false);
  // Focus returns to where it was when the palette opened, however it closed.
  useEffect(() => {
    if (was.current && !open) requestAnimationFrame(() => useShellState.getState().paletteReturn?.focus());
    was.current = open;
  }, [open]);
  if (!open) return null;
  return (
    <Dialog.Root open onOpenChange={(o) => { if (!o) { setOpen(false); requestAnimationFrame(() => useShellState.getState().paletteReturn?.focus()); } }}>
      <Dialog.Portal>
        <Dialog.Backdrop className="cine-barrier cine-barrier--insert" style={{ zIndex: "var(--mm-z-dialog)" }} />
        <div className="pointer-events-none fixed inset-0 flex justify-center px-4" style={{ zIndex: "var(--mm-z-dialog)", paddingTop: "12vh" }}>
          <Dialog.Popup aria-label="Search or jump" className="cine-insert pointer-events-auto w-full max-w-[720px] outline-none" initialFocus={undefined}>
            <PaletteBody onDone={() => setOpen(false)} push={(h) => router.push(h, "section")} />
          </Dialog.Popup>
        </div>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

function PaletteBody({ onDone, push }: { onDone: () => void; push: (href: string) => void }) {
  const [query, setQuery] = useState("");
  const [debounced, setDebounced] = useState("");
  const [active, setActive] = useState(0);
  const boxRef = useRef<HTMLDivElement>(null);
  const listboxId = `${useId()}-listbox`;
  const { data: user } = useCurrentUser();
  const { mode, setMode, novelsEnabled } = useContentMode();
  const search = useSearch({ q: debounced, per_page: SERIES_LIMIT });
  const sources = useSources();
  const cont = useContinueReading(1);
  const chapterHref = useChapterHref();
  const check = useManualCheck();
  const signOut = useSignOut();
  useEffect(() => {
    const q = query.trim();
    const t = setTimeout(() => setDebounced(q), q ? DEBOUNCE_MS : 0);
    return () => clearTimeout(t);
  }, [query]);
  useEffect(() => { boxRef.current?.querySelector("input")?.focus(); }, []);
  const { commands, folios } = useMemo(() => {
    const c = cont.data?.[0];
    return buildPaletteCommands({
      series: (search.data?.items ?? []).map((s) => ({ id: s.id, title: s.title, chapterCount: s.chapter_count, sourceId: s.source_id, coverUrl: libraryCoverUrl(s.cover_url, "40px") })),
      sources: (sources.data ?? []).map((s) => ({ id: s.id, name: s.name, description: s.description, iconUrl: s.icon_url ? sourceImageUrl(s.icon_url) : null })),
      isAdmin: Boolean(user?.is_admin), novelsEnabled, novelMode: mode === "novel", glassAvailable: FLAGS.glassAvailable,
      continue: c ? { title: c.series_key, href: chapterHref({ sourceId: c.source_id, seriesKey: c.series_key, chapterKey: c.chapter_key }) } : null,
    });
  }, [search.data, sources.data, user, novelsEnabled, mode, cont.data, chapterHref]);
  const ranked = useMemo(() => rankCommands(commands, query, 40), [commands, query]);
  const groups = useMemo(() => groupCommands(ranked), [ranked]);
  const cur = Math.min(active, Math.max(0, ranked.length - 1));
  const searching = query.trim() !== debounced && query.trim().length > 0;
  const status = searching ? "Searching…" : `${ranked.length} results`;
  useEffect(() => { document.getElementById(`pal-${cur}`)?.scrollIntoView({ block: "nearest" }); }, [cur]);
  const run = (c: Command) => {
    onDone();
    if (c.kind === "action") {
      switch (c.id) {
        case "action:continue": if (c.href) push(c.href); break;
        case "action:check": check.mutate(undefined); break;
        case "action:settings": push("/settings"); break;
        case "action:mode": setMode(mode === "novel" ? "manga" : "novel"); break;
        case "action:sign-out": signOut.open(); break;
      }
      return;
    }
    if (c.href) push(c.href);
  };
  const onKey = (e: React.KeyboardEvent) => {
    const n = ranked.length;
    if (e.key === "ArrowDown") { e.preventDefault(); setActive((cur + 1) % Math.max(1, n)); }
    else if (e.key === "ArrowUp") { e.preventDefault(); setActive((cur - 1 + n) % Math.max(1, n)); }
    else if (e.key === "Home") { e.preventDefault(); setActive(0); }
    else if (e.key === "End") { e.preventDefault(); setActive(Math.max(0, n - 1)); }
    else if (e.key === "Enter") { e.preventDefault(); if (ranked[cur]) run(ranked[cur]); }
    else if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); onDone(); }
  };
  return (
    <div onKeyDown={onKey} onKeyDownCapture={(e) => { if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); onDone(); } }}>
      <CommandPaletteView query={query} onQuery={(q) => { setQuery(q); setActive(0); }} groups={groups} folios={folios} active={cur} onActive={setActive} onRun={run} status={status} count={ranked.length} inputRef={boxRef} listboxId={listboxId} />
    </div>
  );
}
