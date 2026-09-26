"use client";

import Link from "next/link";
import { useState } from "react";
import { ExternalLink, Globe, ImageOff, Search } from "lucide-react";
import { CoverImage } from "@/components/ui/cover-image";
import type { WorldItem } from "@/features/library/types";
import {
  worldAvailabilityLabel,
  worldBadgeLine,
  worldChaptersLabel,
  worldPlatformLink,
  worldRatingLabel,
  worldSearchHref,
  worldSeriesHref,
} from "@/features/library/world-card";

const COVER_SIZES = "80px";

const ACTION_CLASS =
  "inline-flex items-center gap-1 rounded-full border border-border/50 bg-white/[0.03] px-2.5 py-1 text-xs text-muted transition-colors hover:border-primary/40 hover:bg-primary/10 hover:text-primary";

/**
 * An AniList CDN cover: external, so it goes without a referrer, and a
 * missing or broken one falls back to the same placeholder as no cover.
 */
function WorldCover({ item }: { item: WorldItem }) {
  const [failed, setFailed] = useState(false);
  return (
    <div className="relative h-[120px] w-[80px] shrink-0 overflow-hidden rounded-lg bg-surface-2">
      {item.cover_url && !failed ? (
        <CoverImage
          src={item.cover_url}
          alt={item.title}
          fill
          sizes={COVER_SIZES}
          unoptimized
          loading="lazy"
          referrerPolicy="no-referrer"
          onError={() => setFailed(true)}
          className="object-cover transition-transform duration-300 group-hover:scale-105"
        />
      ) : (
        <div className="flex h-full w-full items-center justify-center text-muted/40">
          <ImageOff className="size-6" aria-hidden />
        </div>
      )}
    </div>
  );
}

/**
 * One title from the worldwide catalogue. A title one of the reader's sources
 * carries is a link to that series; one none carries is not a link at all,
 * and offers a search and the official platform instead.
 */
export function WorldTitleCard({ item }: { item: WorldItem }) {
  const href = worldSeriesHref(item);
  const platform = href ? null : worldPlatformLink(item);
  const numbers = [worldChaptersLabel(item.chapters), worldRatingLabel(item.rating)].filter(
    Boolean,
  );
  const badge = worldBadgeLine(item);

  const card = (
    // `glass-flat`: a row on the flat page background, where a blur shows
    // nothing and still costs a backdrop pass per card per scrolled frame.
    <article
      className={
        href
          ? "glass-card glass-flat group flex gap-4 rounded-2xl p-3 transition-all hover:border-primary/30 hover:shadow-glow"
          : "glass-card glass-flat flex gap-4 rounded-2xl p-3"
      }
    >
      <WorldCover item={item} />

      <div className="flex min-w-0 flex-1 flex-col">
        <h3 className="line-clamp-2 text-base font-semibold text-fg group-hover:text-primary">
          {item.title}
        </h3>
        {badge ? <p className="mt-0.5 truncate text-xs text-muted">{badge}</p> : null}
        {numbers.length > 0 ? (
          <p className="mt-0.5 text-xs tabular-nums text-muted">{numbers.join(" · ")}</p>
        ) : null}
        {item.genres.length > 0 ? (
          <div className="mt-1.5 flex flex-wrap gap-1">
            {item.genres.slice(0, 3).map((genre) => (
              <span
                key={genre}
                className="rounded-full bg-surface-2 px-1.5 py-0.5 text-[10px] text-muted"
              >
                {genre}
              </span>
            ))}
          </div>
        ) : null}

        <div className="mt-auto flex flex-wrap items-center gap-2 pt-3">
          {href ? (
            <span className="inline-flex items-center gap-1 rounded-md border border-primary/30 bg-primary/10 px-2 py-0.5 text-[11px] font-semibold text-primary">
              <Globe className="size-3" aria-hidden />
              {worldAvailabilityLabel(item)}
            </span>
          ) : (
            <>
              <span className="text-[11px] text-muted">{worldAvailabilityLabel(item)}</span>
              <Link href={worldSearchHref(item.title)} className={ACTION_CLASS}>
                <Search className="size-3" aria-hidden />
                Search
              </Link>
              {platform ? (
                <a
                  href={platform.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={ACTION_CLASS}
                >
                  <ExternalLink className="size-3" aria-hidden />
                  {platform.label}
                </a>
              ) : null}
            </>
          )}
        </div>
      </div>
    </article>
  );

  return (
    <div>
      {href ? (
        <Link href={href} className="block">
          {card}
        </Link>
      ) : (
        card
      )}
      {item.why ? <p className="mt-1.5 pl-1 text-sm text-muted">{item.why}</p> : null}
    </div>
  );
}
