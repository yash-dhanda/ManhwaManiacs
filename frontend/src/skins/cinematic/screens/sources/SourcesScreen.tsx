"use client";

import Link from "next/link";
import { useCallback, useMemo, useRef, useState } from "react";
import { useContentModeFilter } from "@/features/content-mode/use-content-mode";
import { availablePosition, movePin, reorderAvailable, type PinMove } from "@/features/sources/pin-order";
import { PullMark, usePullToReprint } from "../kit/use-pull";
import { useReplaceSourcePins, useSourceHealthSummary, useSourcePins, useSources } from "@/features/sources/hooks";
import { isSourcePinned, toggleSourcePin } from "@/features/sources/pins";
import type { SourceSummary } from "@/features/sources/types";
import { ROUTES } from "@/skins/contract.generated";
import { IndexField } from "../kit/IndexField";
import { LeaderDial, Masthead, Notice, Plate, Sheet, ToastHost, kit as s, toast } from "../kit/Kit";
import { useNow } from "../kit/motion";
import { useScreenChrome } from "../kit/use-screen";
import { HealthDetailsSheet } from "./HealthDetailsSheet";
import { SourcesKeys } from "./keys";
import { AllTable, PinnedTable } from "./SourceTable";
import d from "./sources.module.css";

type Filter = "all" | "pinned" | "mature";

export default function SourcesScreen() {
  const sources = useSources();
  const pinsQ = useSourcePins();
  const replace = useReplaceSourcePins();
  const summary = useSourceHealthSummary();
  const { filterSources, mode } = useContentModeFilter();
  const now = useNow(30_000);
  const reprint = usePullToReprint(() => Promise.all([sources.refetch(), pinsQ.refetch()]));
  const [q, setQ] = useState("");
  const [filter, setFilter] = useState<Filter>("all");
  const [menu, setMenu] = useState<SourceSummary | null>(null);
  const [details, setDetails] = useState<SourceSummary | null>(null);
  const [live, setLive] = useState("");
  const field = useRef<HTMLInputElement>(null);
  const focusField = useCallback(() => field.current?.focus(), []);
  const h1 = useScreenChrome("Sources", focusField);

  const pins = useMemo(() => pinsQ.data ?? [], [pinsQ.data]);
  const list = useMemo(() => filterSources(sources.data), [filterSources, sources.data]);
  const byId = useMemo(() => new Map(list.map((x) => [x.id, x])), [list]);
  const matureVisible = list.some((x) => x.mature);
  const pinnedIds = useMemo(() => pins.filter((p) => p.available && byId.has(p.source_id)).map((p) => p.source_id), [pins, byId]);
  const [order, setOrder] = useState<string[] | null>(null);
  const matches = (x: SourceSummary) => {
    const t = q.trim().toLowerCase();
    return !t || x.name.toLowerCase().includes(t) || x.id.toLowerCase().includes(t);
  };
  const pinnedRows = pinnedIds.filter((id) => matches(byId.get(id)!));
  const allRows = list.filter((x) => matches(x) && (filter === "mature" ? x.mature : true) && (filter === "pinned" ? isSourcePinned(pins, x.id) : true));

  const write = (next: typeof pins) =>
    replace.mutate(next, { onError: () => toast("Couldn't update your pinned sources.", "error") });
  const togglePin = (src: SourceSummary) => {
    const was = isSourcePinned(pins, src.id);
    write(toggleSourcePin(pins, src));
    toast(`${src.name} ${was ? "unpinned" : "pinned"}`);
  };
  const doMove = (id: string, m: PinMove) => {
    const next = movePin(pins, id, m);
    if (!next) return;
    write(next);
    const pos = availablePosition(next, id);
    const name = byId.get(id)?.name ?? id;
    if (pos) setLive(`${name} moved to position ${pos.position} of ${pos.total}`);
  };
  const commitOrder = () => {
    if (!order || order.join() === pinnedIds.join()) return;
    write(reorderAvailable(pins, order));
    const id = order.find((x, i) => x !== pinnedIds[i]);
    const pos = id ? order.indexOf(id) + 1 : 0;
    if (id) setLive(`${byId.get(id)?.name ?? id} moved to position ${pos} of ${order.length}`);
  };

  const pinsBroken = pinsQ.isError;
  const common = (src: SourceSummary) => ({
    source: src,
    pinned: isSourcePinned(pins, src.id),
    now,
    pinDisabledReason: pinsBroken ? "Pinned sources couldn't be loaded, so pinning is off until they are." : null,
    onTogglePin: () => togglePin(src),
    onMenu: () => setMenu(src),
  });

  const total = summary.data?.total ?? list.length;
  const healthy = summary.data?.ok ?? list.filter((x) => x.health?.status === "ok").length;
  const deck = `${total} sources · ${healthy} healthy · ${pinnedIds.length} pinned`;
  const offline = typeof navigator !== "undefined" && navigator.onLine === false;
  const menuPos = menu ? availablePosition(pins, menu.id) : null;

  let body;
  if (sources.isLoading) {
    body = (
      <div aria-busy="true" style={{ marginTop: 24 }}>
        {Array.from({ length: 10 }, (_, i) => (
          <Plate key={i} style={{ height: 64, marginBottom: 1 }} />
        ))}
      </div>
    );
  } else if (sources.isError && !sources.data) {
    body = offline ? (
      <Notice kicker="OFFLINE EDITION" headline="The source list needs a connection." />
    ) : (
      <Notice kicker="CORRECTION" tone="proof" headline="Couldn't load the sources.">
        <button type="button" className={s.btn} onClick={() => void sources.refetch()}>Try again</button>
      </Notice>
    );
  } else if (list.length === 0) {
    body = <p className={d.err}>No sources installed on this server.</p>;
  } else {
    body = (
      <>
        {pinsBroken ? (
          <Notice kicker="NOTE" headline="Pinned sources couldn't be loaded, so pinning is off until they are.">
            <button type="button" className={s.quiet} onClick={() => void pinsQ.refetch()}>Try again</button>
          </Notice>
        ) : null}
        <h2 className={d.sectionTitle}>Pinned</h2>
        {pinnedIds.length === 0 ? (
          <p className={s.caption}>No pinned sources. Tap the pin on any source to keep it at the top.</p>
        ) : pinnedRows.length === 0 ? (
          <p className={s.caption}>{`No sources match “${q}”.`}</p>
        ) : (
          <PinnedTable ids={pinnedRows} byId={byId} common={common} onOrder={setOrder} onCommit={commitOrder} />
        )}
        <h2 className={d.sectionTitle}>All sources</h2>
        {allRows.length === 0 ? <p className={s.caption}>{`No sources match “${q}”.`}</p> : <AllTable rows={allRows} common={common} />}
      </>
    );
  }

  return (
    <main className={s.page} style={{ position: "relative" }}>
      <PullMark {...reprint} />
      <div className={s.grade} aria-hidden />
      <div className={`${s.frame} ${s.rel}`}>
        <SourcesKeys
          focusFilter={focusField}
          togglePin={(id) => {
            const src = byId.get(id);
            if (src && !pinsBroken) togglePin(src);
          }}
          move={(id, dir) => doMove(id, dir)}
        />
        <Masthead kicker="No. 04 — DISCOVER / SOURCES" title="Sources" deck={deck} focusRef={h1} />
        <div className={d.toolbar}>
          <IndexField ref={field} value={q} onChange={setQ} placeholder="Filter sources" label="Filter sources" variant="compact" />
          <div className={d.toolbarRow}>
            <div className={s.slug} role="group" aria-label="Filter">
              <button type="button" className={s.slugItem} aria-pressed={filter === "all"} onClick={() => setFilter("all")}>ALL</button>
              <button type="button" className={s.slugItem} aria-pressed={filter === "pinned"} onClick={() => setFilter("pinned")}>
                PINNED<span className={s.raised}>{pinnedIds.length}</span>
              </button>
              {matureVisible ? (
                <button type="button" className={s.slugItem} aria-pressed={filter === "mature"} onClick={() => setFilter("mature")}>18+</button>
              ) : null}
            </div>
            <span className={s.folio}>{mode === "novel" ? "NOVELS" : "MANGA"}</span>
          </div>
        </div>
        {body}
        <div className={s.sr} role="status" aria-live="polite">{live}</div>
      </div>
      <Sheet open={menu !== null} onClose={() => setMenu(null)} kicker="SOURCE" title={menu?.name ?? ""}>
        {menu ? (
          <>
            <button type="button" className={s.menuItem} disabled={pinsBroken} onClick={() => { togglePin(menu); setMenu(null); }}>
              {isSourcePinned(pins, menu.id) ? "Unpin" : "Pin"}
            </button>
            <Link href={ROUTES.source(menu.id)} className={s.menuItem}>Open</Link>
            <button type="button" className={s.menuItem} onClick={() => { setDetails(menu); setMenu(null); }}>Health details</button>
            {menuPos
              ? ([["up", "Move up", menuPos.position === 1], ["down", "Move down", menuPos.position === menuPos.total], ["top", "Move to top", menuPos.position === 1], ["bottom", "Move to bottom", menuPos.position === menuPos.total]] as const).map(([m, label, off]) => (
                  <button key={m} type="button" className={s.menuItem} disabled={off} onClick={() => { doMove(menu.id, m); setMenu(null); }}>
                    {label}
                  </button>
                ))
              : null}
          </>
        ) : null}
      </Sheet>
      <HealthDetailsSheet source={details} onClose={() => setDetails(null)} now={now} />
      <ToastHost />
      {sources.isFetching && !sources.isLoading ? <span className={s.sr}><LeaderDial /></span> : null}
    </main>
  );
}
