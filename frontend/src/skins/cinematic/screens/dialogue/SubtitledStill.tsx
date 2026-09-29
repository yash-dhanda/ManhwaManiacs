"use client";

import { useEffect, useRef, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { ImageOff } from "lucide-react";
import { fetchStillManifest, pageAspect, stillPageUrl } from "@/features/ocr/still-source";
import { stillCrop } from "@/features/ocr/still-crop";
import type { OcrSearchResultItem } from "@/features/ocr/types";
import { readerManifestQueryKey } from "@/features/reader/hooks";
import { useLimitedSrc } from "../kit/Kit";
import { Highlighted } from "./TranscriptBlock";
import d from "./dialogue.module.css";

function useNear<T extends Element>(margin = 400) {
  const ref = useRef<T>(null);
  const [near, setNear] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el || near) return;
    const io = new IntersectionObserver((e) => e[0]?.isIntersecting && setNear(true), { rootMargin: `${margin}px` });
    io.observe(el);
    return () => io.disconnect();
  }, [margin, near]);
  return [ref, near] as const;
}

/** 16:9 still cropped around the matched bubble with the matched line set as a subtitle. */
export function SubtitledStill({ item, index }: { item: OcrSearchResultItem; index: number }) {
  const [ref, near] = useNear<HTMLDivElement>();
  const chapter = { sourceId: item.source_id, seriesKey: item.series_key, chapterKey: item.chapter_key };
  const manifest = useQuery({
    queryKey: readerManifestQueryKey(chapter),
    queryFn: ({ signal }) => fetchStillManifest(chapter, signal),
    enabled: near && item.page !== null,
    staleTime: 5 * 60_000,
    retry: false,
  });
  const url = stillPageUrl(manifest.data, item.page);
  const src = useLimitedSrc(url, "P3");
  const [failed, setFailed] = useState(false);
  const crop = stillCrop(item.box, pageAspect(manifest.data, item.page));
  const hasStill = item.page !== null;
  const broken = failed || manifest.isError || (manifest.isSuccess && url === null);
  return (
    <div ref={ref} className={d.still}>
      {hasStill && src && !broken ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          className={`${d.stillImg} ${index < 12 ? d.rack : d.develop}`}
          src={src}
          alt=""
          onError={() => setFailed(true)}
          style={{ objectPosition: crop.objectPosition, transform: `scale(${crop.scale})`, transformOrigin: crop.objectPosition }}
        />
      ) : null}
      <p className={d.subtitle}>
        <Highlighted snippet={item.snippet} sweep />
      </p>
      {broken ? (
        <span className={d.broken} title="Page didn't load">
          <ImageOff size={16} aria-label="Page didn't load" />
        </span>
      ) : null}
    </div>
  );
}
