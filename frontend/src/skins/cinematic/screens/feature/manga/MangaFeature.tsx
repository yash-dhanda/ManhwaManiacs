"use client";

import { useRef, useState } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary } from "@/features/sources/types";
import { useSources } from "@/features/sources/hooks";
import { useReaderEntry } from "../reader-entry";
import { focusRow, useFeatureKeys } from "../use-feature-keys";
import type { SeriesPage } from "../use-series-page";
import { AddToShelfSheet, TagSheet } from "../standins";
import { Lightbox } from "../Lightbox";
import { AtAGlance } from "./AtAGlance";
import { ChaptersPanel } from "./ChaptersPanel";
import { DetailsPanel } from "./DetailsPanel";
import { FeatureSpread, type Ambient } from "./FeatureSpread";
import { FeatureTabs, type FeatureTab } from "./FeatureTabs";
import { RepointPanel } from "./RepointPanel";
import { useRouter } from "next/navigation";
import { healthOf } from "../health";
import s from "../feature.module.css";
import t from "../type.module.css";

/** The manga Feature page body (§8.17). */
export function MangaFeature({
  page,
  series,
  cover,
  setCover,
}: {
  page: SeriesPage;
  series: SourceSeriesSummary;
  cover: boolean;
  setCover: (open: boolean) => void;
}) {
  const router = useRouter();
  const enter = useReaderEntry();
  const sources = useSources().data;
  const source = sources?.find((x) => x.id === page.sourceId);
  const [tab, setTab] = useState("chapters");
  const [sheet, setSheet] = useState<null | "shelf" | "tags" | "move">(null);
  const goTo = useRef<HTMLInputElement>(null);
  const ambient = ((page.follow as unknown as { ambient?: Ambient | null } | undefined)?.ambient ??
    (series as unknown as { ambient?: Ambient | null }).ambient) as Ambient | null | undefined;
  const stale = Boolean((series as unknown as { cache?: { stale?: boolean } }).cache?.stale);
  const dead = healthOf(source) === "dead";
  const cp = page.continueTo;
  const currentNumber =
    cp && cp.kind !== "caught-up" ? (page.rows.find((r) => r.id === cp.point.chapterKey)?.number ?? null) : null;

  const tabs: FeatureTab[] = [
    {
      id: "chapters",
      folio: "01",
      label: "CHAPTERS",
      count: page.chapters.length,
      panel: (
        <div className={s.split}>
          <div className={s.chapters}>
            <ChaptersPanel page={page} sourceName={source?.name ?? page.sourceId} goToRef={goTo} />
          </div>
          <aside className={s.aside}>
            <AtAGlance page={page} onAddShelf={() => setSheet("shelf")} onTags={() => setSheet("tags")} />
          </aside>
        </div>
      ),
    },
    {
      id: "details",
      folio: "02",
      label: "DETAILS",
      panel: (
        <>
          <div className={s.asideInline}>
            <AtAGlance page={page} onAddShelf={() => setSheet("shelf")} onTags={() => setSheet("tags")} />
          </div>
          <DetailsPanel page={page} series={series} />
        </>
      ),
    },
  ];
  const at = (n: number) => tabs[n] && setTab(tabs[n].id);
  const idx = tabs.findIndex((x) => x.id === tab);
  const followed = page.followedId !== null;

  useFeatureKeys({
    Enter: () => page.primaryHref && enter(page.primaryHref),
    c: () => page.primaryHref && enter(page.primaryHref),
    a: () => page.readAll && enter(page.readAll),
    v: () => setCover(true),
    f: () => followed && page.patch({ is_favorite: !page.follow?.is_favorite }),
    n: () => followed && page.patch({ notify: !page.follow?.notify }),
    "+": () => void page.toggleFollow(),
    d: () => page.picker.begin(),
    x: () => (page.picker.selecting ? page.picker.end() : page.picker.begin()),
    "/": () => {
      setTab("chapters");
      setTimeout(() => goTo.current?.focus(), 0);
    },
    o: () => page.setSort(page.sort === "newest" ? "oldest" : "newest"),
    m: () => followed && page.online && setSheet("move"),
    j: () => focusRow(1),
    k: () => focusRow(-1),
    "[": () => at((idx - 1 + tabs.length) % tabs.length),
    "]": () => at((idx + 1) % tabs.length),
    ...Object.fromEntries(tabs.map((_, i) => [String(i + 1), () => at(i)])),
  });

  const coverSrc = page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url) : seriesCoverUrl(page.ref);

  return (
    <>
      <FeatureSpread
        page={page}
        series={series}
        source={source}
        ambient={ambient}
        stale={stale}
        onViewCover={() => setCover(true)}
        onAddToShelf={() => setSheet("shelf")}
        onTags={() => setSheet("tags")}
        onMove={() => setSheet("move")}
        onSelect={() => {
          setTab("chapters");
          page.picker.begin();
        }}
      />
      {dead && followed ? (
        <div className={s.wrap}>
          <div className={`${s.banner} ${t.caption}`}>
            <span className={`${t.kicker} ${s.noteTone}`}>NOTE </span>
            This source is down. Move the series to another source to keep reading.{" "}
            <button type="button" className={s.quiet} onClick={() => setSheet("move")}>Move</button>
          </div>
        </div>
      ) : null}
      <FeatureTabs tabs={tabs} active={tab} onChange={setTab} />
      {cover ? <Lightbox src={coverSrc} alt={`${series.title} cover`} onClose={() => setCover(false)} /> : null}
      {sheet === "shelf" ? <AddToShelfSheet page={page} onClose={() => setSheet(null)} /> : null}
      {sheet === "tags" ? <TagSheet page={page} onClose={() => setSheet(null)} /> : null}
      {sheet === "move" && page.followedId !== null ? (
        <RepointPanel
          followedId={page.followedId}
          sourceId={page.sourceId}
          title={series.title}
          currentNumber={currentNumber}
          currentSourceName={source?.name ?? page.sourceId}
          onClose={() => setSheet(null)}
          onMoved={(href, message) => {
            setSheet(null);
            page.toasts.push(message);
            router.push(href);
          }}
        />
      ) : null}
    </>
  );
}
