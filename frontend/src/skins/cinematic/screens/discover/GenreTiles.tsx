"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { sourceImageUrl } from "@/features/sources/api";
import type { GenreEntry } from "@/features/sources/genre-index";
import { ROUTES } from "@/skins/contract.generated";
import { useLimitedSrc, kit as s, cx } from "../kit/Kit";
import { useGenreCover } from "./use-discover-data";
import d from "./discover.module.css";

function Tile({ entry, onOpen }: { entry: GenreEntry; onOpen: (e: GenreEntry) => void }) {
  const cover = useGenreCover(entry.sourceIds[0], entry.label);
  const url = cover.data?.cover_url ? sourceImageUrl(cover.data.cover_url) : null;
  const src = useLimitedSrc(url, "P3");
  return (
    <button type="button" className={d.tile} onClick={() => onOpen(entry)} data-genre={entry.label}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img className={d.tileImg} src={src} alt="" />
      ) : null}
      {src ? <span className={d.tileDuo} aria-hidden /> : null}
      <span className={d.tileFoot} aria-hidden />
      <span className={d.tileName}>{entry.label}</span>
    </button>
  );
}

export function GenreTiles({ genres, onPanel }: { genres: GenreEntry[]; onPanel: (e: GenreEntry) => void }) {
  const router = useRouter();
  const [all, setAll] = useState(false);
  const shown = all ? genres : genres.slice(0, 12);
  const open = (e: GenreEntry) => {
    if (e.sourceIds.length === 1) router.push(ROUTES.source(e.sourceIds[0], { genre: e.label }));
    else onPanel(e);
  };
  return (
    <>
      <div className={d.tiles}>
        {shown.map((g) => (
          <Tile key={g.genre} entry={g} onOpen={open} />
        ))}
      </div>
      {genres.length > 12 ? (
        <button type="button" className={cx(s.quiet)} onClick={() => setAll((v) => !v)} aria-expanded={all}>
          {all ? "Fewer genres" : `All ${genres.length} genres`}
        </button>
      ) : null}
    </>
  );
}
