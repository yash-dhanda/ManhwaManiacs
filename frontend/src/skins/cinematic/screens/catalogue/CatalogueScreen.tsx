"use client";

import Link from "next/link";
import { use, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { RefreshCw } from "lucide-react";
import { describeBrowseFreshness } from "@/features/sources/browse-freshness";
import { browsePaging } from "@/features/sources/browse-paging";
import { useInfiniteSourceSeries, useRefreshSourceBrowse, useSourceBrowseModes, useSourceGenres, useSources } from "@/features/sources/hooks";
import { useDebouncedValue } from "@/lib/use-debounced-value";
import { useLoadMoreOnScroll } from "@/lib/use-load-more-on-scroll";
import type { ScreenProps } from "@/skins/types";
import { ROUTES } from "@/skins/contract.generated";
import { LeaderDial, Notice, SourceLogo, ToastHost, kit as s, RevealText } from "../kit/Kit";
import { useCountdown, useNow } from "../kit/motion";
import { errorCode, isStatus, retryAfterSeconds, useScreenChrome } from "../kit/use-screen";
import { CatalogueToolbar } from "./CatalogueToolbar";
import { CatalogueWall } from "./CatalogueWall";
import { CatalogueKeys } from "./keys";
import { OpeningDeck, OpeningPlates, SourceWash, useOpening } from "./OpeningState";
import { TopButton } from "./TopButton";
import d from "./catalogue.module.css";

export default function CatalogueScreen({ params }: ScreenProps) {
  const sourceId = String(use(params).sourceId ?? "");
  const router = useRouter();
  const pathname = usePathname();
  const sp = useSearchParams();
  const sources = useSources();
  const summary = sources.data?.find((x) => x.id === sourceId) ?? null;
  const modesQ = useSourceBrowseModes(sourceId);
  const genresQ = useSourceGenres(sourceId);
  const now = useNow(30_000);

  const [raw, setRaw] = useState(sp.get("q") ?? "");
  const [q] = useDebouncedValue(raw, 300);
  const genre = sp.get("genre") ?? "";
  const modeParam = sp.get("mode") ?? "";
  const mode = modeParam || modesQ.data?.[0]?.id || "";
  const searching = q.trim() !== "";
  const notBrowsable = summary?.browsable === false;
  const field = useRef<HTMLInputElement>(null);
  const focusSearch = useCallback(() => field.current?.focus(), []);
  const h1 = useScreenChrome(summary?.name ?? "Catalogue", focusSearch);

  const setParams = (patch: Record<string, string>) => {
    const next = new URLSearchParams(sp.toString());
    for (const [k, v] of Object.entries(patch)) {
      if (v) next.set(k, v);
      else next.delete(k);
    }
    const qs = next.toString();
    router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
  };
  useEffect(() => {
    if ((sp.get("q") ?? "") !== q.trim()) setParams({ q: q.trim() });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  const runQuery = !(notBrowsable && !searching);
  const facets = { mode: notBrowsable || searching ? undefined : mode, genre: notBrowsable ? undefined : genre };
  const query = useInfiniteSourceSeries(runQuery ? sourceId : "", q.trim(), facets.mode, facets.genre);
  const refresh = useRefreshSourceBrowse(sourceId, { query: q.trim(), sort: facets.mode, genre: facets.genre });
  const items = useMemo(() => query.data?.pages.flatMap((p) => p.items) ?? [], [query.data]);
  const total = query.data?.pages[0]?.total ?? items.length;
  const cache = query.data?.pages[0]?.cache;
  const fresh = describeBrowseFreshness(cache, now);

  const paging = browsePaging({
    itemCount: items.length,
    hasNextPage: query.hasNextPage,
    isFetchingNextPage: query.isFetchingNextPage,
    isFetchNextPageError: query.isFetchNextPageError,
    hasError: query.isError,
  });
  const sentinel = useLoadMoreOnScroll(paging.autoLoad, () => void query.fetchNextPage(), query.isFetchingNextPage);
  const opening = query.isLoading && runQuery;
  const clock = useOpening(opening);
  const err = query.error;
  const left = useCountdown(isStatus(err, 429) ? retryAfterSeconds(err) : null);
  const stepMode = (dir: 1 | -1) => {
    const ms = modesQ.data ?? [];
    if (!ms.length || searching) return;
    const i = ms.findIndex((m) => m.id === mode);
    setParams({ mode: ms[Math.min(ms.length - 1, Math.max(0, i + dir))].id });
  };

  if (isStatus(err, 404) || errorCode(err) === "source_not_found" || (sources.isSuccess && !summary)) {
    return (
      <main className={s.page}>
        <div className={s.frame}>
          <h1 ref={h1} tabIndex={-1} className={`${s.sr} ${s.h1focus}`}>Catalogue</h1>
          <Notice kicker="NOT IN THIS ISSUE" headline="This source isn't available here any more." deck="It may have been removed from its source.">
            <Link href={ROUTES.tonight()} className={s.btn}>Back to Tonight</Link>
            <Link href={ROUTES.discover()} className={s.btn}>Search for it</Link>
          </Notice>
        </div>
      </main>
    );
  }

  const offline = typeof navigator !== "undefined" && navigator.onLine === false;
  const name = summary?.name ?? sourceId;
  const deck = isStatus(err, 429) && left > 0 ? `Rate limited · retrying in ${left} s` : `Catalogue · ${total.toLocaleString("en-US")} series${searching ? ` · “${q.trim()}”` : ""}`;

  return (
    <main className={s.page} style={{ position: "relative" }}>
      <SourceWash sourceId={sourceId} on={clock.slow} />
      <div className={`${s.frame} ${s.rel}`}>
        <CatalogueKeys focusSearch={focusSearch} mode={stepMode} refresh={() => refresh.mutate()} />
        <p className={s.kicker}>No. 04 — DISCOVER / CATALOGUE</p>
        <div className={d.head}>
          <SourceLogo id={sourceId} name={name} iconUrl={summary?.icon_url ?? null} size={48} />
          <h1 ref={h1} tabIndex={-1} className={`${s.masthead} ${d.name} ${s.h1focus}`}>
            <RevealText text={name} />
          </h1>
        </div>
        {opening ? <OpeningDeck slow={clock.slow} tip={clock.tip} /> : <p className={s.deck}>{deck}</p>}
        <div className={d.credit}>
          {fresh ? (
            fresh.tone === "stale" ? (
              <span className={d.stale} title="The source is down; this is the last copy we saved.">
                SAVED COPY · {fresh.label.split("·")[1]?.trim().toUpperCase()}
              </span>
            ) : (
              <span className={s.folio}>{fresh.label.toUpperCase()}</span>
            )
          ) : null}
          <button type="button" className={s.quiet} disabled={refresh.isPending} onClick={() => refresh.mutate()}>
            {refresh.isPending ? <LeaderDial /> : <RefreshCw size={16} aria-hidden />} Refresh
          </button>
        </div>
        <div className={s.oxford} />
        <CatalogueToolbar
          ref={field}
          modes={modesQ.data ?? []}
          mode={mode}
          onMode={(m) => setParams({ mode: m })}
          genres={genresQ.data ?? []}
          genre={genre}
          onGenre={(g) => setParams({ genre: g })}
          q={raw}
          onQ={setRaw}
          browsable={!notBrowsable}
        />
        {notBrowsable && !searching ? (
          <Notice kicker="NOTE" headline="This source can only be searched, not browsed.">
            <button type="button" className={s.btn} onClick={focusSearch}>Search it</button>
          </Notice>
        ) : opening ? (
          <OpeningPlates />
        ) : paging.showFullError ? (
          offline ? (
            <Notice kicker="OFFLINE EDITION" headline="The catalogue needs a connection." />
          ) : isStatus(err, 429) ? (
            <Notice kicker="SLOW DOWN" headline={`Rate limited · retrying in ${left} s`} />
          ) : (
            <Notice kicker="CORRECTION" tone="proof" headline="Couldn't load the catalogue." deck={err instanceof Error ? err.message : undefined}>
              <button type="button" className={s.btn} onClick={() => void query.refetch()}>Try again</button>
            </Notice>
          )
        ) : items.length === 0 ? (
          <p className={s.deck}>{searching ? `No results for “${q.trim()}” on this source.` : "No series found."}</p>
        ) : (
          <>
            <CatalogueWall items={items} sourceId={sourceId} showMature={summary?.mature === true} />
            {query.isFetchingNextPage ? (
              <p className={`${s.folio} ${s.captionOn0}`} role="status">
                LOADING MORE <LeaderDial />
              </p>
            ) : null}
            {paging.showLoadMoreRetry ? (
              <p className={s.caption}>
                Couldn&apos;t load more.{" "}
                <button type="button" className={s.quiet} onClick={() => void query.fetchNextPage()}>Retry</button>
              </p>
            ) : null}
            <div ref={sentinel} aria-hidden style={{ height: 1 }} />
            {!query.hasNextPage && !query.isFetchNextPageError ? (
              <div className={d.end}>
                <hr className={s.rule1} />
                <p className={s.kicker}>END OF CATALOGUE</p>
              </div>
            ) : null}
          </>
        )}
      </div>
      <TopButton />
      <ToastHost />
    </main>
  );
}
