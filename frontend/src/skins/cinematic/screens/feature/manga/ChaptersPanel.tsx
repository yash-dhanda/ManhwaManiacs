"use client";

import { useWindowVirtualizer } from "@tanstack/react-virtual";
import { useEffect, useMemo, useState } from "react";
import { goToChapterMatches, goToChapterQuery } from "@/features/novels/book";
import { ListState } from "../FeatureStates";
import { RunSummary } from "../downloads/RunSummary";
import { SelectionBar } from "../downloads/SelectionBar";
import { SeriesDownloadCard } from "../downloads/SeriesDownloadCard";
import type { SeriesPage } from "../use-series-page";
import { ScheduleRow } from "./ScheduleRow";
import s from "../feature.module.css";
import t from "../type.module.css";

const VIRTUAL_ABOVE = 60;

/** §8.17 D3: toolbar, download card, schedule rows (windowed above 60), selection bar. */
export function ChaptersPanel({
  page,
  sourceName,
  goToRef,
}: {
  page: SeriesPage;
  sourceName: string;
  goToRef: React.RefObject<HTMLInputElement | null>;
}) {
  const { picker, rows } = page;
  const [goTo, setGoTo] = useState("");
  const [focusKey, setFocusKey] = useState<string | null>(null);
  const [listEl, setListEl] = useState<HTMLDivElement | null>(null);
  const virtual = rows.length > VIRTUAL_ABOVE;
  const currentKey = page.continueTo && page.continueTo.kind === "resume" ? page.continueTo.point.chapterKey : null;

  const v = useWindowVirtualizer({
    count: virtual ? rows.length : 0,
    estimateSize: () => 56,
    overscan: 8,
    scrollMargin: listEl?.offsetTop ?? 0,
  });

  const wanted = goToChapterQuery(goTo);
  const matches = useMemo(() => goToChapterMatches(page.chapters, goTo), [page.chapters, goTo]);
  const caption =
    goTo.trim() === "" ? "Type a chapter number." : wanted !== null && matches.length === 0 ? `No chapter ${wanted} in this series.` : null;

  useEffect(() => {
    if (!focusKey) return;
    const id = setTimeout(() => setFocusKey(null), 2400);
    return () => clearTimeout(id);
  }, [focusKey]);

  const jump = () => {
    const m = matches[0];
    if (!m) return;
    const idx = rows.findIndex((r) => r.id === m.chapterKey);
    if (idx < 0) return;
    setFocusKey(m.chapterKey);
    if (virtual) v.scrollToIndex(idx, { align: "center" });
    else document.querySelector(`[data-row="${idx}"]`)?.scrollIntoView({ block: "center" });
  };

  if (page.listState !== "content") {
    return (
      <ListState
        state={page.listState}
        reported={page.series?.chapter_count ?? 0}
        source={sourceName}
        sourceHref={`/sources/${encodeURIComponent(page.sourceId)}`}
        onRetry={() => void page.chaptersQuery.refetch()}
      />
    );
  }

  const hasProfile = picker.downloads.scope !== null;
  const render = (i: number) => (
    <ScheduleRow
      key={rows[i].id}
      page={page}
      row={rows[i]}
      index={i}
      current={rows[i].id === currentKey || rows[i].id === focusKey}
      focused={rows[i].id === focusKey}
    />
  );

  return (
    <div>
      <div className={s.toolbar}>
        <div className={`${s.seg} ${t.kicker}`} role="group" aria-label="Chapter order">
          <button type="button" aria-pressed={page.sort === "newest"} onClick={() => page.setSort("newest")}>NEWEST</button>
          <button type="button" aria-pressed={page.sort === "oldest"} onClick={() => page.setSort("oldest")}>OLDEST</button>
        </div>
        <input
          ref={goToRef}
          className={s.field}
          value={goTo}
          inputMode="decimal"
          placeholder="Chapter number"
          aria-label="Go to chapter"
          onChange={(e) => setGoTo(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") jump();
            if (e.key === "Escape") setGoTo("");
          }}
        />
        <button type="button" className={s.quiet} onClick={() => (picker.selecting ? picker.end() : picker.begin())}>
          {picker.selecting ? "Done" : "Select"}
        </button>
        <span className={s.spacer} />
        <span className={t.folio}>{picker.savedCount} OF {picker.total} SAVED</span>
        <button type="button" className={`${s.btn} ${s.secondary} ${s.sm}`} onClick={picker.begin}>Download</button>
      </div>
      {caption ? <p className={`${t.caption} ${s.note}`}>{caption}</p> : null}
      <SeriesDownloadCard picker={picker} />
      <RunSummary downloads={picker.downloads} />
      <div ref={setListEl} role="list" aria-label="Chapters" style={virtual ? { height: v.getTotalSize(), position: "relative" } : undefined}>
        {virtual
          ? v.getVirtualItems().map((it) => (
              <div
                key={it.key}
                className={s.vitem}
                style={{ position: "absolute", top: 0, left: 0, width: "100%", transform: `translateY(${it.start - v.options.scrollMargin}px)` }}
              >
                {render(it.index)}
              </div>
            ))
          : rows.map((_, i) => render(i))}
      </div>
      {picker.selecting ? (
        <SelectionBar picker={picker} novel={false} hasProfile={hasProfile} onDone={picker.end} />
      ) : null}
    </div>
  );
}
