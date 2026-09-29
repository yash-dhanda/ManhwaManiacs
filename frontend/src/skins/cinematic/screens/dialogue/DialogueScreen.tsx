"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { useAllFollowedSeries } from "@/features/library/hooks";
import { libraryCoverUrl } from "@/features/library/api";
import { engineLabel } from "@/features/ocr/engine-label";
import { writeDialogueJump } from "@/features/ocr/dialogue-jump";
import { useInfiniteOcrSearch, useOcrCapability } from "@/features/ocr/hooks";
import type { OcrSearchResultItem } from "@/features/ocr/types";
import { useDebouncedValue } from "@/lib/use-debounced-value";
import { ROUTES } from "@/skins/contract.generated";
import { IndexField } from "../kit/IndexField";
import { Notice, Plate, ToastHost, kit as s, RevealText } from "../kit/Kit";
import { useScreenChrome } from "../kit/use-screen";
import { DialogueKeys } from "./keys";
import { SubtitledStill } from "./SubtitledStill";
import { Highlighted, creditLine } from "./TranscriptBlock";
import d from "./dialogue.module.css";

export default function DialogueScreen() {
  const router = useRouter();
  const pathname = usePathname();
  const sp = useSearchParams();
  const { mode } = useContentMode();
  const ocrOn = useOcrCapability();
  const [raw, setRaw] = useState(sp.get("q") ?? "");
  const [q] = useDebouncedValue(raw, 300);
  const field = useRef<HTMLInputElement>(null);
  const focusField = useCallback(() => field.current?.focus(), []);
  const h1 = useScreenChrome("Dialogue search", focusField);
  const trimmed = q.trim();
  const query = useInfiniteOcrSearch(mode === "manga" ? trimmed : "");
  const followed = useAllFollowedSeries();
  const byKey = useMemo(() => new Map((followed.data ?? []).map((r) => [`${r.source_id}:${r.series_key}`, r])), [followed.data]);
  const items = useMemo(() => query.data?.pages.flatMap((p) => p.items) ?? [], [query.data]);
  const total = query.data?.pages[0]?.total ?? 0;

  useEffect(() => {
    if ((sp.get("q") ?? "") !== trimmed) router.replace(trimmed ? `${pathname}?q=${encodeURIComponent(trimmed)}` : pathname, { scroll: false });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [trimmed]);

  const open = (it: OcrSearchResultItem) => {
    writeDialogueJump({ sourceId: it.source_id, seriesKey: it.series_key, chapterKey: it.chapter_key, q: trimmed, page: it.page, box: it.box });
    router.push(ROUTES.reader(it.source_id, it.series_key, it.chapter_key, it.page !== null ? { page: it.page } : undefined));
  };

  const offline = typeof navigator !== "undefined" && navigator.onLine === false;
  let body;
  if (mode !== "manga") {
    body = (
      <Notice kicker="NOTE" headline="Dialogue search is for manga. Switch to Manga, or search the novels' text.">
        <Link href={ROUTES.discover()} className={s.btn}>Search novels</Link>
      </Notice>
    );
  } else if (ocrOn === false) {
    body = (
      <Notice kicker="NOTE" headline="Dialogue search isn't available on this server." />
    );
  } else if (trimmed === "") {
    body = <p className={s.deck} style={{ marginTop: 32 }}>Type a line you remember.</p>;
  } else if (query.isLoading) {
    body = (
      <ul className={d.list} aria-busy="true">
        {[0, 1, 2].map((i) => (
          <li key={i} className={d.block} style={{ cursor: "default" }}>
            <Plate style={{ aspectRatio: "16/9" }} />
            <div className={d.ghostLines}>
              <Plate className={d.ghostLine} />
              <Plate className={d.ghostLine} />
            </div>
          </li>
        ))}
      </ul>
    );
  } else if (query.isError) {
    body = offline ? (
      <Notice kicker="OFFLINE EDITION" headline="Dialogue search needs a connection." />
    ) : (
      <Notice kicker="CORRECTION" tone="proof" headline="Dialogue search didn't finish.">
        <button type="button" className={s.btn} onClick={() => void query.refetch()}>Try again</button>
      </Notice>
    );
  } else if (items.length === 0) {
    body = <Notice kicker="NOTHING FOUND" headline={`Nothing found for “${trimmed}”. Only chapters whose dialogue was scanned, in series you follow, can be searched.`} />;
  } else {
    body = (
      <>
        <ul className={d.list} aria-label="Dialogue matches">
          {items.map((it, i) => {
            const f = byKey.get(`${it.source_id}:${it.series_key}`);
            const title = f?.title ?? it.series_key;
            return (
              <li key={`${it.source_id}/${it.series_key}/${it.chapter_key}/${i}`}>
                <button type="button" className={d.block} data-block="" onClick={() => open(it)} aria-label={`${title}, chapter ${it.chapter_key}`}>
                  <SubtitledStill item={it} index={i} />
                  <div>
                    <p className={d.text}>
                      <Highlighted snippet={it.snippet} sweep />
                    </p>
                    <div className={d.credit}>
                      {f?.cover_url ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img className={d.cover} src={libraryCoverUrl(f.cover_url)} alt="" loading="lazy" />
                      ) : null}
                      <span className={d.creditText}>{creditLine({ title, chapterKey: it.chapter_key, page: it.page, words: it.word_count, engine: engineLabel(it.engine) })}</span>
                    </div>
                  </div>
                </button>
              </li>
            );
          })}
        </ul>
        <div className={d.more}>
          {total > items.length ? (
            <p className={s.caption}>{`Showing the first ${items.length} of ${total} matches. Narrow the search.`}</p>
          ) : null}
          {query.hasNextPage ? (
            <button type="button" className={s.btn} disabled={query.isFetchingNextPage} onClick={() => void query.fetchNextPage()}>
              Show more
            </button>
          ) : null}
        </div>
      </>
    );
  }

  return (
    <main className={s.page} style={{ position: "relative" }}>
      <div className={s.grade} aria-hidden />
      <div className={`${s.frame} ${s.rel}`}>
        <DialogueKeys focusField={focusField} />
        <p className={s.kicker}>
          <RevealText text="No. 09 — DIALOGUE" />
        </p>
        <h1 ref={h1} tabIndex={-1} className={`${s.sr} ${s.h1focus}`}>Dialogue search</h1>
        <div style={{ maxWidth: "calc(8 / 12 * 100%)", minWidth: "min(100%, 320px)" }}>
          <IndexField ref={field} value={raw} onChange={setRaw} placeholder="Search what a character said" label="Search what a character said" />
        </div>
        <p className={s.deck}>Across chapters whose dialogue has been read, in series you follow.</p>
        {body}
      </div>
      <ToastHost />
    </main>
  );
}
