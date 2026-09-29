"use client";

import Link from "next/link";
import type { GenreEntry } from "@/features/sources/genre-index";
import type { SourceSummary } from "@/features/sources/types";
import { ROUTES } from "@/skins/contract.generated";
import { HealthMark, Sheet, SourceLogo, kit as s } from "../kit/Kit";
import d from "./discover.module.css";

export function GenrePanel({ entry, sources, onClose, now }: { entry: GenreEntry | null; sources: Map<string, SourceSummary>; onClose: () => void; now: number }) {
  return (
    <Sheet open={entry !== null} onClose={onClose} kicker="GENRE" title={entry?.label ?? ""}>
      {entry?.sourceIds.map((id) => {
        const src = sources.get(id);
        if (!src) return null;
        return (
          <Link key={id} href={ROUTES.source(id, { genre: entry.label })} className={`${d.credit} ${s.link} ${s.focusable}`}>
            <SourceLogo id={id} name={src.name} iconUrl={src.icon_url} size={24} />
            <span className={d.creditName}>{src.name}</span>
            <HealthMark health={src.health} now={now} showLabel={false} />
          </Link>
        );
      })}
    </Sheet>
  );
}
