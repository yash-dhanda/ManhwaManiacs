"use client";

import { useEffect, useMemo, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { extendTocWindow, goToChapterMatches, goToChapterQuery, tocEntry, tocWindowAround } from "@/features/novels/book";
import { prefetchNovelChapterWindow, useCachedNovelWordCounts } from "@/features/novels/hooks";
import { ListState } from "../FeatureStates";
import { RunSummary } from "../downloads/RunSummary";
import { SelectionBar } from "../downloads/SelectionBar";
import { SeriesDownloadCard } from "../downloads/SeriesDownloadCard";
import type { SeriesPage } from "../use-series-page";
import { ContentsRow } from "./ContentsRow";
import s from "../feature.module.css";
import t from "../type.module.css";

const WINDOW = 400;

/** §8.18 E2: the toolbar and the windowed contents list. */
export function BookContents({
  page,
  narrated,
  focusKey,
  goToRef,
}: {
  page: SeriesPage;
  narrated: ReadonlySet<string>;
  focusKey: string | null;
  goToRef: React.RefObject<HTMLInputElement | null>;
}) {
  const qc = useQueryClient();
  const { picker, rows } = page;
  const words = useCachedNovelWordCounts(page.ref);
  const [goTo, setGoTo] = useState("");
  const [narratedOnly, setNarratedOnly] = useState(false);
  const [band, setBand] = useState<string | null>(focusKey);
  const shown = useMemo(() => (narratedOnly ? rows.filter((r) => narrated.has(r.id)) : rows), [rows, narratedOnly, narrated]);
  const focusIndex = Math.max(0, shown.findIndex((r) => r.id === band));
  const [win, setWin] = useState(() => tocWindowAround(shown.length, band ? focusIndex : 0, WINDOW));

  // Silent P3 warm of the first three chapters.
  useEffect(() => {
    const keys = page.ordered.slice(0, 3).map((c) => c.id);
    if (keys.length) void prefetchNovelChapterWindow(qc, page.ref, keys);
  }, [page.ordered, page.ref, qc]);

  useEffect(() => {
    if (!band) return;
    document.getElementById(`toc-${band}`)?.scrollIntoView({ block: "center" });
  }, [band, win]);

  const wanted = goToChapterQuery(goTo);
  const matches = useMemo(() => goToChapterMatches(page.chapters, goTo), [page.chapters, goTo]);
  const jumpTo = (key: string) => {
    const i = shown.findIndex((r) => r.id === key);
    if (i < 0) return;
    setWin(tocWindowAround(shown.length, i, WINDOW));
    setBand(key);
  };

  if (page.listState !== "content") {
    return (
      <ListState
        book
        state={page.listState}
        reported={page.series?.chapter_count ?? 0}
        source=""
        sourceHref={`/sources/${encodeURIComponent(page.sourceId)}`}
        onRetry={() => void page.chaptersQuery.refetch()}
      />
    );
  }
  const visible = shown.slice(win.start, win.end);

  return (
    <div>
      <div className={s.toolbar}>
        <div className={`${s.seg} ${t.kicker}`} role="group" aria-label="Contents order">
          <button type="button" aria-pressed={page.sort === "oldest"} onClick={() => page.setSort("oldest")}>FIRST → LAST</button>
          <button type="button" aria-pressed={page.sort === "newest"} onClick={() => page.setSort("newest")}>LAST → FIRST</button>
        </div>
        <input
          ref={goToRef}
          className={s.field}
          inputMode="decimal"
          placeholder="Chapter number"
          aria-label="Go to chapter"
          value={goTo}
          onChange={(e) => setGoTo(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && matches[0]) jumpTo(matches[0].chapterKey);
            if (e.key === "Escape") setGoTo("");
          }}
        />
        <button type="button" className={s.quiet} onClick={() => (picker.selecting ? picker.end() : picker.begin())}>
          {picker.selecting ? "Done" : "Pick chapters"}
        </button>
        {narrated.size > 0 ? (
          <button type="button" className={s.quiet} aria-pressed={narratedOnly} onClick={() => setNarratedOnly((v) => !v)}>
            Narrated only
          </button>
        ) : null}
      </div>
      {goTo.trim() === "" ? (
        <p className={`${t.caption} ${s.note}`}>Type a chapter number.</p>
      ) : matches.length === 0 && wanted !== null ? (
        <p className={`${t.caption} ${s.note}`}>No chapter {wanted} in this book.</p>
      ) : (
        <div className={s.matches}>
          {matches.slice(0, 12).map((m) => {
            const e = tocEntry({ number: m.number, title: m.title });
            return (
              <button key={m.chapterKey} type="button" className={s.chip} onClick={() => jumpTo(m.chapterKey)}>
                {e.title ?? `Chapter ${e.ordinal}`} <span className={t.folio}>row {shown.findIndex((r) => r.id === m.chapterKey) + 1}</span>
              </button>
            );
          })}
          {matches.length > 12 ? <span className={t.caption}>and {matches.length - 12} more</span> : null}
        </div>
      )}
      <SeriesDownloadCard picker={picker} />
      <RunSummary downloads={picker.downloads} />
      {win.start > 0 ? (
        <button type="button" className={s.quiet} onClick={() => setWin(extendTocWindow(win, shown.length, "earlier", WINDOW))}>
          Show earlier chapters ({win.start})
        </button>
      ) : null}
      <div className={s.toc} role="list" aria-label="Contents">
        {visible.map((r, i) => (
          <ContentsRow key={r.id} page={page} row={r} words={words.get(r.id)} narrated={narrated.has(r.id)} focused={r.id === band} index={win.start + i} />
        ))}
      </div>
      {win.end < shown.length ? (
        <button type="button" className={`${s.btn} ${s.secondary}`} onClick={() => setWin(extendTocWindow(win, shown.length, "later", WINDOW))}>
          Show more chapters ({shown.length - win.end})
        </button>
      ) : null}
      {picker.selecting ? <SelectionBar picker={picker} novel hasProfile={picker.downloads.scope !== null} onDone={picker.end} /> : null}
    </div>
  );
}
