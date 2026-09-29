"use client";

import { useRef, useState } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import type { SourceSeriesSummary } from "@/features/sources/types";
import { useSources } from "@/features/sources/hooks";
import { useReaderEntry } from "../reader-entry";
import { FeatureKeys, focusRow } from "../use-feature-keys";
import type { SeriesPage } from "../use-series-page";
import { AddToShelfSheet, TagSheet } from "../standins";
import { Lightbox } from "../Lightbox";
import { AtAGlance } from "./AtAGlance";
import { ChaptersPanel } from "./ChaptersPanel";
import { DetailsPanel } from "./DetailsPanel";
import { FeaturePhoneHero } from "./FeaturePhoneHero";
import { FeatureSpread, type Ambient } from "./FeatureSpread";
import { PHONE, useMedia } from "../use-media";
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
  const phone = useMedia(PHONE);
  const Hero = phone ? FeaturePhoneHero : FeatureSpread;
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

  const tabKeys = tabs.map((tb, i) => ({ id: `tab${i + 1}`, keys: String(i + 1), label: `Tab ${i + 1}: ${tb.label.toLowerCase()}`, run: () => at(i) }));
  const keys = [
    { id: "continue", keys: ["c", "Enter"], label: "Continue reading", run: () => page.primaryHref && enter(page.primaryHref) },
    { id: "all", keys: "a", label: "Read all", run: () => page.readAll && enter(page.readAll) },
    { id: "cover", keys: "v", label: "View cover", run: () => setCover(true) },
    { id: "fav", keys: "f", label: "Favourite", run: () => followed && page.patch({ is_favorite: !page.follow?.is_favorite }) },
    { id: "notify", keys: "n", label: "Notify", run: () => followed && page.patch({ notify: !page.follow?.notify }) },
    { id: "follow", keys: "+", label: "Follow or unfollow", run: () => void page.toggleFollow() },
    { id: "download", keys: "d", label: "Download (select chapters)", run: () => page.picker.begin() },
    { id: "select", keys: "x", label: "Select mode", run: () => (page.picker.selecting ? page.picker.end() : page.picker.begin()) },
    { id: "goto", keys: "/", label: "Go to chapter", run: () => { setTab("chapters"); setTimeout(() => goTo.current?.focus(), 0); } },
    { id: "order", keys: "o", label: "Newest or oldest first", run: () => page.setSort(page.sort === "newest" ? "oldest" : "newest") },
    { id: "move", keys: "m", label: "Move to another source", run: () => followed && page.online && setSheet("move") },
    { id: "next", keys: "j", label: "Next chapter", run: () => focusRow(1) },
    { id: "prev", keys: "k", label: "Previous chapter", run: () => focusRow(-1) },
    { id: "tabprev", keys: "[", label: "Previous tab", run: () => at((idx - 1 + tabs.length) % tabs.length) },
    { id: "tabnext", keys: "]", label: "Next tab", run: () => at((idx + 1) % tabs.length) },
    ...tabKeys,
  ];


  const coverSrc = page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url) : seriesCoverUrl(page.ref);

  return (
    <>
      <FeatureKeys keys={keys} />
      <Hero
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
