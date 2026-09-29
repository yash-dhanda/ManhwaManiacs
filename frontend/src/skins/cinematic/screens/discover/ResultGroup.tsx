"use client";

import { forwardRef } from "react";
import { libraryCoverUrl } from "@/features/library/api";
import type { SourceSummary } from "@/features/sources/types";
import { ROUTES } from "@/skins/contract.generated";
import { MmMark } from "../../icons/glyphs.generated";
import { HealthMark, Plate, Poster, SourceLogo, kit as s, cx } from "../kit/Kit";
import { useGridNavHost } from "../kit/grid-host";
import d from "./discover.module.css";

export interface GroupItem {
  key: string;
  title: string;
  coverUrl: string | null;
  href: string;
  folio: string | null;
  mature?: boolean;
  transitionName?: string;
}

export interface GroupModel {
  key: string;
  name: string;
  iconUrl: string | null;
  isLibrary: boolean;
  sourceId: string | null;
  source: SourceSummary | null;
  count: number;
  items: GroupItem[];
  status: "ok" | "empty" | "error";
  error: string | null;
}

export function transitionNameFor(sourceId: string, key: string) {
  return `cover-${sourceId}-${key}`.replace(/[^a-zA-Z0-9_-]/g, "_");
}

export function libraryItem(row: { id: number; title: string; cover_url: string; chapter_count: number }): GroupItem {
  return {
    key: `lib-${row.id}`,
    title: row.title,
    coverUrl: row.cover_url ? libraryCoverUrl(row.cover_url) : null,
    href: ROUTES.featureByFollow(row.id),
    folio: `CHAPTERS ${row.chapter_count}`,
  };
}

export const ResultGroup = forwardRef<HTMLHeadingElement, { group: GroupModel; now: number; retrying: boolean; onRetry: (id: string) => void }>(function ResultGroup(
  { group, now, retrying, onRetry },
  headRef,
) {
  const grid = useGridNavHost(group.key);
  return (
    <section className={cx(d.group, s.set)} data-group={group.key} aria-labelledby={`grp-${group.key}`}>
      <div className={d.groupHead}>
        {group.isLibrary ? <MmMark size={24} weight="regular" /> : <SourceLogo id={group.sourceId ?? ""} name={group.name} iconUrl={group.iconUrl} size={24} />}
        <h2 id={`grp-${group.key}`} ref={headRef} tabIndex={-1} className={d.groupName}>
          {group.isLibrary ? "IN YOUR LIBRARY" : group.name}
        </h2>
        <span className={s.badge}>{group.count}</span>
        {group.source ? <HealthMark health={group.source.health} now={now} showLabel={false} /> : null}
      </div>
      {group.status === "error" ? (
        <div>
          <p className={s.noticeKicker} style={{ color: "var(--mm-color-proof)" }}>CORRECTION</p>
          <p className={s.caption}>This source didn&apos;t answer.</p>
          {retrying ? (
            <div className={d.plateRow}>
              <Plate style={{ aspectRatio: "2/3" }} />
              <Plate style={{ aspectRatio: "2/3" }} />
            </div>
          ) : (
            <button type="button" className={s.quiet} onClick={() => group.sourceId && onRetry(group.sourceId)}>
              Retry
            </button>
          )}
        </div>
      ) : (
        <div className={d.rail} {...grid}>
          {group.items.map((it) => (
            <Poster key={it.key} href={it.href} title={it.title} coverUrl={it.coverUrl} folio={it.folio} mature={it.mature} transitionName={it.transitionName} />
          ))}
        </div>
      )}
    </section>
  );
});
