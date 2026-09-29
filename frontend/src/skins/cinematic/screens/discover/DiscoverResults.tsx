"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";
import { useContentModeFilter } from "@/features/content-mode/use-content-mode";
import { useSearch } from "@/features/library/hooks";
import { useOcrSearch } from "@/features/ocr/hooks";
import { parseSnippet } from "@/features/ocr/snippet";
import { writeRecentSearch } from "@/features/library/recent-searches";
import { globalSearchScopeLabel } from "@/features/sources/global-search";
import { useFederatedSearch, useRetrySearchSource, useSourcePins, useSources } from "@/features/sources/hooks";
import type { GlobalSearchGroup } from "@/features/sources/types";
import { ROUTES } from "@/skins/contract.generated";
import { Keys } from "../kit/Keys";
import { Notice, Plate, kit as s } from "../kit/Kit";
import { prefersReducedMotion, useCountdown, useNow } from "../kit/motion";
import { errorCode, isStatus, retryAfterSeconds } from "../kit/use-screen";
import { GroupJump } from "./GroupJump";
import { ResultGroup, libraryItem, transitionNameFor, type GroupModel } from "./ResultGroup";
import d from "./discover.module.css";

type Filter = "all" | "with" | "pinned";

function sourceGroup(g: GlobalSearchGroup, byId: Map<string, import("@/features/sources/types").SourceSummary>): GroupModel {
  const id = g.source as string;
  return {
    key: id,
    name: g.source_name,
    iconUrl: g.icon_url,
    isLibrary: false,
    sourceId: id,
    source: byId.get(id) ?? null,
    count: g.items.length || g.total,
    status: g.status,
    error: g.error,
    items: g.items.map((it) => ({
      key: `${id}-${it.series_id}`,
      title: it.title,
      coverUrl: it.cover_url,
      href: ROUTES.feature(id, it.series_id),
      folio: it.chapter_count ? `CHAPTERS ${it.chapter_count}` : null,
      transitionName: transitionNameFor(id, it.series_id),
    })),
  };
}

export function DiscoverResults({ q, scope, dialogueAvailable, aiAvailable, onAsk }: { q: string; scope: "all" | "library" | "sources" | "dialogue"; dialogueAvailable: boolean; aiAvailable: boolean; onAsk: () => void }) {
  const [filter, setFilter] = useState<Filter>("all");
  const [showEmpty, setShowEmpty] = useState(false);
  const now = useNow(30_000);
  const wantLibrary = scope === "all" || scope === "library";
  const wantSources = scope === "all" || scope === "sources";
  const wantDialogue = (scope === "all" || scope === "dialogue") && dialogueAvailable;

  const lib = useSearch({ q: wantLibrary ? q : "" });
  const fed = useFederatedSearch({ q: wantSources ? q : "" });
  const ocr = useOcrSearch(wantDialogue ? q : "");
  const retry = useRetrySearchSource({ q });
  const sources = useSources();
  const pins = useSourcePins();
  const { keepSource } = useContentModeFilter();
  const byId = useMemo(() => new Map((sources.data ?? []).map((x) => [x.id, x])), [sources.data]);
  const pinnedIds = useMemo(() => new Set((pins.data ?? []).map((p) => p.source_id)), [pins.data]);
  const heads = useRef(new Map<string, HTMLHeadingElement | null>());

  useEffect(() => {
    if (q.trim().length >= 2) writeRecentSearch(q);
  }, [q]);

  const groups: GroupModel[] = useMemo(() => {
    const out: GroupModel[] = [];
    if (wantLibrary) {
      const rows = lib.data?.items ?? [];
      out.push({ key: "@library", name: "IN YOUR LIBRARY", iconUrl: null, isLibrary: true, sourceId: null, source: null, count: rows.length, status: rows.length ? "ok" : "empty", error: null, items: rows.map(libraryItem) });
    }
    if (wantSources) {
      for (const g of fed.data?.groups ?? []) {
        if (g.source === null || !keepSource(g.source)) continue;
        out.push(sourceGroup(g, byId));
      }
    }
    return out;
  }, [wantLibrary, wantSources, lib.data, fed.data, keepSource, byId]);

  const visible = groups.filter((g) => (filter === "with" ? g.count > 0 && g.status !== "error" : filter === "pinned" ? g.isLibrary || (g.sourceId !== null && pinnedIds.has(g.sourceId)) : true));
  const shown = visible.filter((g) => g.isLibrary || g.status === "error" || g.count > 0);
  const collapsed = visible.filter((g) => !g.isLibrary && g.status !== "error" && g.count === 0);
  const totalHits = shown.reduce((n, g) => n + g.count, 0);
  const failed = groups.filter((g) => g.status === "error").length;

  const loading = (wantSources ? fed.isLoading : false) || (wantLibrary && !wantSources && lib.isLoading);
  const restLoading = wantSources && Boolean((fed as { isLoadingRest?: boolean }).isLoadingRest);
  const error = (wantSources ? fed.error : null) ?? (wantLibrary && !wantSources ? lib.error : null);
  const offline = typeof navigator !== "undefined" && navigator.onLine === false;
  const rateLeft = useCountdown(isStatus(error, 429) ? retryAfterSeconds(error) : null);

  const jump = (key: string) => {
    const el = heads.current.get(key);
    el?.closest("section")?.scrollIntoView({ behavior: prefersReducedMotion() ? "auto" : "smooth", block: "start" });
    el?.focus({ preventScroll: true });
  };
  const order = shown.map((g) => g.key);
  const step = (dir: number) => {
    const active = document.activeElement?.closest("[data-group]")?.getAttribute("data-group");
    const i = active ? order.indexOf(active) : -1;
    const next = order[Math.min(order.length - 1, Math.max(0, i + dir))];
    if (next) jump(next);
  };

  if (offline) {
    return (
      <Notice kicker="OFFLINE EDITION" headline="Search needs a connection to reach your library and sources." deck="Saved chapters still open.">
        <Link href={ROUTES.downloads()} className={`${s.btn} ${s.focusable}`}>Go to Downloads</Link>
      </Notice>
    );
  }
  if (isStatus(error, 429)) {
    return (
      <Notice kicker="SLOW DOWN" headline="Too many searches at once.">
        <span className={s.folio}>{rateLeft > 0 ? `Retrying in ${rateLeft} s` : "Try again"}</span>
        <button type="button" className={s.quiet} onClick={() => void fed.refetch()}>Try again</button>
      </Notice>
    );
  }
  if (error && !fed.data && !lib.data) {
    return (
      <Notice kicker="CORRECTION" tone="proof" headline={errorCode(error) === "network_error" ? "Couldn't reach the server." : "Search didn't finish."}>
        <button type="button" className={s.btn} onClick={() => void fed.refetch()}>Try again</button>
      </Notice>
    );
  }
  if (loading && shown.length <= 1 && totalHits === 0) {
    return (
      <div role="status" aria-live="polite">
        <p className={`${s.caption} ${d.status}`}>Searching your library and pinned sources…</p>
        {[0, 1, 2].map((g) => (
          <div key={g} className={d.plateRow} style={{ marginTop: 24 }}>
            {[0, 1, 2, 3].map((i) => (
              <Plate key={i} style={{ aspectRatio: "2/3" }} />
            ))}
          </div>
        ))}
      </div>
    );
  }
  if (!loading && !restLoading && totalHits === 0 && collapsed.length + shown.length > 0 && failed === 0 && !(wantDialogue && (ocr.data?.items.length ?? 0) > 0)) {
    return (
      <Notice kicker="NOTHING FOUND" headline={`No series match “${q}” in your library or sources.`}>
        {aiAvailable ? (
          <button type="button" className={s.btn} onClick={onAsk}>Ask the editors</button>
        ) : null}
      </Notice>
    );
  }

  const status = restLoading
    ? `${totalHits} results so far · searching ${fed.data?.sources_deferred ?? "more"} more sources…`
    : `${totalHits} results · ${shown.filter((g) => !g.isLibrary && g.count > 0).length} sources`;
  const scopeLine = fed.data ? globalSearchScopeLabel(fed.data.sources_queried, fed.data.sources_failed) : null;

  return (
    <div>
      <Keys
        group="Discover"
        defs={[
          { id: "discover.group.prev", keys: "[", description: "Previous result group", handler: () => step(-1) },
          { id: "discover.group.next", keys: "]", description: "Next result group", handler: () => step(1) },
        ]}
      />
      <p className={`${s.caption} ${d.status}`} role="status" aria-live="polite">
        {status}
        {scopeLine ? <span className={s.captionOn0}> · {scopeLine}</span> : null}
      </p>
      {restLoading ? <div className={s.indeterminate} aria-hidden /> : null}
      {failed > 0 ? (
        <p className={d.note}>NOTE · {failed} {failed === 1 ? "source" : "sources"} didn&apos;t answer.</p>
      ) : null}
      {wantSources ? (
        <div className={s.slug} role="group" aria-label="Filter results">
          {(["all", "with", "pinned"] as const).map((f) => (
            <button key={f} type="button" className={s.slugItem} aria-pressed={filter === f} onClick={() => setFilter(f)}>
              {f === "all" ? "ALL" : f === "with" ? "WITH RESULTS" : "PINNED"}
            </button>
          ))}
        </div>
      ) : null}
      <GroupJump groups={shown.map((g) => ({ key: g.key, name: g.isLibrary ? "LIBRARY" : g.name, count: g.count }))} onJump={jump} />
      {shown.map((g) => (
        <ResultGroup
          key={g.key}
          group={g}
          now={now}
          retrying={retry.isPending && retry.variables === g.sourceId}
          onRetry={(id) => retry.mutate(id)}
          ref={(el) => {
            heads.current.set(g.key, el);
          }}
        />
      ))}
      {collapsed.length > 0 ? (
        <>
          <button type="button" className={s.quiet} aria-expanded={showEmpty} onClick={() => setShowEmpty((v) => !v)}>
            {showEmpty ? `Hide ${collapsed.length} sources with no matches` : `Show ${collapsed.length} sources with no matches`}
          </button>
          {showEmpty ? (
            <div className={s.slug}>
              {collapsed.map((g) => (
                <span key={g.key} className={s.captionOn0} style={{ minHeight: 24 }}>
                  {g.name}
                </span>
              ))}
            </div>
          ) : null}
        </>
      ) : null}
      {wantDialogue && (ocr.data?.items.length ?? 0) > 0 ? (
        <section className={`${d.group} ${s.set}`} data-group="@dialogue" aria-labelledby="grp-dialogue">
          <div className={d.groupHead}>
            <h2 id="grp-dialogue" ref={(el) => void heads.current.set("@dialogue", el)} tabIndex={-1} className={d.groupName}>
              IN DIALOGUE
            </h2>
            <Link href={ROUTES.dialogue({ q })} className={`${s.quiet} ${s.focusable}`}>See all</Link>
          </div>
          {ocr.data!.items.slice(0, 3).map((it) => (
            <Link key={`${it.source_id}/${it.series_key}/${it.chapter_key}`} href={ROUTES.dialogue({ q })} className={`${d.transcript} ${s.focusable}`}>
              {parseSnippet(it.snippet).map((seg, i) => (seg.highlight ? <mark key={i} className={d.hi}>{seg.text}</mark> : <span key={i}>{seg.text}</span>))}
            </Link>
          ))}
        </section>
      ) : null}
    </div>
  );
}
