"use client";

import type { SourceSeriesSummary } from "@/features/sources/types";
import { sourceImageUrl } from "@/features/sources/api";
import { ROUTES } from "@/skins/contract.generated";
import { useGridNavHost } from "../kit/grid-host";
import { Poster } from "../kit/Kit";
import { transitionNameFor } from "../discover/ResultGroup";
import d from "./catalogue.module.css";

export function CatalogueWall({ items, sourceId, showMature }: { items: SourceSeriesSummary[]; sourceId: string; showMature: boolean }) {
  const grid = useGridNavHost(`catalogue.${sourceId}`, "Catalogue", items.length > 0);
  return (
    <div className={d.wall} {...grid}>
      {items.map((it) => (
        <Poster
          key={it.id}
          href={ROUTES.feature(sourceId, it.id)}
          title={it.title}
          coverUrl={it.cover_url ? sourceImageUrl(it.cover_url) : null}
          mature={showMature}
          transitionName={transitionNameFor(sourceId, it.id)}
        />
      ))}
    </div>
  );
}
