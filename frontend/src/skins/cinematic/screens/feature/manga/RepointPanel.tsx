"use client";

import { useMemo, useState } from "react";
import { mappingSentence, useRepoint } from "@/features/library/repoint";
import { sourcesApi } from "@/features/sources/api";
import { useFederatedSearch, useSources } from "@/features/sources/hooks";
import type { GlobalSearchItem } from "@/features/sources/types";
import { seriesPageHref } from "@/features/reader/reader-link";
import { healthOf, HealthMark } from "../health";
import { Glyph } from "../Glyph";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §8.17 D6: candidates, mapping, moving. A column panel on desktop, a sheet on phones. */
export function RepointPanel({
  followedId,
  sourceId,
  title,
  currentNumber,
  currentSourceName,
  onClose,
  onMoved,
}: {
  followedId: number;
  sourceId: string;
  title: string;
  currentNumber: number | null;
  currentSourceName: string;
  onClose: () => void;
  onMoved: (href: string, message: string) => void;
}) {
  const search = useFederatedSearch({ q: title });
  const sources = useSources().data ?? [];
  const repoint = useRepoint(followedId);
  const [picked, setPicked] = useState<{ item: GlobalSearchItem; range: [number, number] | null; name: string } | null>(null);
  const [keepOld, setKeepOld] = useState(false);

  const candidates = useMemo(
    () =>
      (search.data?.groups ?? [])
        .filter((g) => g.source && g.source !== sourceId && g.status === "ok")
        .map((g) => ({ group: g, item: g.items[0] }))
        .filter((c) => c.item),
    [search.data, sourceId],
  );
  const failed = (search.data?.groups ?? []).filter((g) => g.source && g.source !== sourceId && g.status === "error");

  async function pick(item: GlobalSearchItem, name: string) {
    let range: [number, number] | null = null;
    try {
      const chapters = await sourcesApi.getChapters(item.source!, item.series_id);
      const nums = chapters.map((c) => c.number).filter((n): n is number => n != null);
      if (nums.length) range = [Math.min(...nums), Math.max(...nums)];
    } catch {
      /* the sentence falls back to "start at chapter 1" */
    }
    setPicked({ item, range, name });
  }

  async function move() {
    if (!picked) return;
    try {
      const r = await repoint.mutateAsync({
        source_id: picked.item.source!,
        series_key: picked.item.series_id,
        keep_old: keepOld,
      });
      const n = r.mapped_chapter_number;
      onMoved(
        seriesPageHref({ sourceId: picked.item.source!, seriesKey: picked.item.series_id }),
        n != null ? `Moved to ${picked.name}. You're on chapter ${n}.` : `Moved to ${picked.name}.`,
      );
    } catch {
      /* the error line below reads repoint.isError */
    }
  }

  return (
    <>
      <div className={s.scrim} onClick={onClose} />
      <aside
        className={s.side}
        role="dialog"
        aria-label="Move to another source"
        onKeyDown={(e) => e.key === "Escape" && onClose()}
      >
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span className={t.kicker} style={{ color: "var(--mm-color-spot)" }}>MOVE TO ANOTHER SOURCE</span>
          <button type="button" className={s.icon} aria-label="Close" onClick={onClose}><Glyph name="x" /></button>
        </div>

        {!picked ? (
          <div style={{ marginTop: 16 }}>
            {search.isLoading ? (
              [0, 1, 2].map((i) => <div key={i} className={s.greek} style={{ height: 60, marginTop: 12 }} />)
            ) : candidates.length === 0 && failed.length === 0 ? (
              <p className={t.body}>No other source has this series.</p>
            ) : (
              candidates.map(({ group, item }) => (
                <button key={group.source} type="button" className={s.cand} onClick={() => void pick(item, group.source_name)}>
                  {group.icon_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={group.icon_url} alt="" width={24} height={24} />
                  ) : (
                    <span aria-hidden="true" />
                  )}
                  <span>
                    <span className={t.title} style={{ display: "block" }}>{item.title}</span>
                    <span className={`${t.folio} ${s.rowCap}`}>
                      {group.source_name.toUpperCase()}
                      {item.chapter_count ? ` · CHAPTERS ${item.chapter_count}` : ""} ·{" "}
                      <HealthMark health={healthOf(sources.find((x) => x.id === group.source))} />
                    </span>
                  </span>
                  {item.cover_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={item.cover_url} alt="" />
                  ) : (
                    <span />
                  )}
                </button>
              ))
            )}
            {failed.map((g) => (
              <p key={g.source} className={`${t.caption} ${s.err}`}>
                <span className={t.kicker}>CORRECTION </span>{g.source_name} didn&apos;t answer.{" "}
                <button type="button" className={s.quiet} onClick={() => void search.refetch()}>Retry</button>
              </p>
            ))}
          </div>
        ) : (
          <div style={{ marginTop: 16 }}>
            <p className={t.body}>
              {mappingSentence({ currentNumber, candidateRange: picked.range, sourceName: picked.name })}
            </p>
            <label className={t.body} style={{ display: "flex", gap: 8, alignItems: "center", minHeight: 44 }}>
              <input type="checkbox" checked={keepOld} onChange={(e) => setKeepOld(e.target.checked)} />
              Keep following it on {currentSourceName} too
            </label>
            {repoint.isError ? (
              <p className={`${t.caption} ${s.err}`}>
                Couldn&apos;t move this series.{" "}
                <button type="button" className={s.quiet} onClick={() => void move()}>Try again</button>
              </p>
            ) : null}
            <div className={s.actions}>
              <button type="button" className={`${s.btn} ${s.primary}`} disabled={repoint.isPending} onClick={() => void move()}>
                <span>{repoint.isPending ? "Moving…" : "Move"}</span>
              </button>
              <button type="button" className={s.quiet} onClick={() => setPicked(null)}>Back</button>
            </div>
          </div>
        )}
      </aside>
    </>
  );
}
