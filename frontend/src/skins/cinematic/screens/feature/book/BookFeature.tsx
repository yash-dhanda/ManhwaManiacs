"use client";

import { useRouter } from "next/navigation";
import { useRef, useState } from "react";
import { libraryCoverUrl, seriesCoverUrl } from "@/features/library/api";
import { useSeriesAudio } from "@/features/novels/hooks";
import { useSources } from "@/features/sources/hooks";
import type { SourceSeriesSummary } from "@/features/sources/types";
import { healthOf } from "../health";
import { Lightbox } from "../Lightbox";
import type { Ambient } from "../manga/FeatureSpread";
import { RepointPanel } from "../manga/RepointPanel";
import { useReaderEntry } from "../reader-entry";
import { AddToShelfSheet, TagSheet } from "../standins";
import { FeatureKeys } from "../use-feature-keys";
import type { SeriesPage } from "../use-series-page";
import { BookContents } from "./BookContents";
import { BookFrontMatter } from "./BookFrontMatter";
import s from "../feature.module.css";
import t from "../type.module.css";

/** The novel Book page body (§8.18). */
export function BookFeature({
  page,
  series,
  cover,
  setCover,
  focusKey,
}: {
  page: SeriesPage;
  series: SourceSeriesSummary;
  cover: boolean;
  setCover: (open: boolean) => void;
  focusKey: string | null;
}) {
  const router = useRouter();
  const enter = useReaderEntry();
  const source = useSources().data?.find((x) => x.id === page.sourceId);
  const audio = useSeriesAudio(page.ref).data;
  const [sheet, setSheet] = useState<null | "shelf" | "tags" | "move">(null);
  const goTo = useRef<HTMLInputElement>(null);
  const narrated = new Set(audio?.chapters.map((c) => c.chapter_key) ?? []);
  const ambient = (page.follow as unknown as { ambient?: Ambient | null } | undefined)?.ambient;
  const cp = page.continueTo;
  const point = cp && cp.kind !== "caught-up" ? cp.point : null;
  const listenKey = point?.chapterKey ?? [...narrated][0] ?? null;
  const listenHref =
    narrated.size > 0 && listenKey ? `${page.chapterHref(listenKey, point?.page)}${page.chapterHref(listenKey).includes("?") ? "&" : "?"}listen=1` : null;
  const followed = page.followedId !== null;
  const dead = healthOf(source) === "dead";
  const currentNumber = point ? (page.rows.find((r) => r.id === point.chapterKey)?.number ?? null) : null;

  const keys = [
    { id: "continue", keys: ["c", "Enter"], label: "Start or continue reading", run: () => page.primaryHref && enter(page.primaryHref) },
    { id: "listen", keys: "l", label: "Listen", run: () => listenHref && enter(listenHref) },
    { id: "cover", keys: "v", label: "View cover", run: () => setCover(true) },
    { id: "library", keys: "+", label: "Add to or remove from library", run: () => void page.toggleFollow() },
    { id: "download", keys: "d", label: "Download book", run: () => page.picker.startKeys(page.picker.unsaved) },
    { id: "goto", keys: "/", label: "Go to chapter", run: () => goTo.current?.focus() },
    { id: "order", keys: "o", label: "Change the order", run: () => page.setSort(page.sort === "oldest" ? "newest" : "oldest") },
    { id: "move", keys: "m", label: "Move to another source", run: () => followed && page.online && setSheet("move") },
  ];


  const coverSrc = page.follow?.cover_url ? libraryCoverUrl(page.follow.cover_url) : seriesCoverUrl(page.ref);
  return (
    <>
      <FeatureKeys keys={keys} />
      <BookFrontMatter
        page={page}
        series={series}
        source={source}
        ambient={ambient}
        listenHref={listenHref}
        narrationUnavailable={audio != null && narrated.size === 0 && !audio.can_render}
        onViewCover={() => setCover(true)}
        onAddToShelf={() => setSheet("shelf")}
        onTags={() => setSheet("tags")}
        onMove={() => setSheet("move")}
        onPick={() => page.picker.begin()}
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
      <div className={s.wrap}>
        <div className={s.contents}>
          <BookContents page={page} narrated={narrated} focusKey={focusKey} goToRef={goTo} />
        </div>
      </div>
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
