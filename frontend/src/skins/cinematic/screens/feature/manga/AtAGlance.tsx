"use client";

import Link from "next/link";
import { rejectSuggestedTag } from "@/features/ai/tags";
import type { SeriesPage } from "../use-series-page";
import s from "../feature.module.css";
import t from "../type.module.css";

const STATUS: [string, string][] = [
  ["reading", "READING"],
  ["plan_to_read", "PLAN TO READ"],
  ["on_hold", "ON HOLD"],
  ["completed", "DONE"],
  ["dropped", "DROPPED"],
  ["not_started", "NOT STARTED"],
];

/** §8.17 D3: the At a glance aside (also the top of DETAILS below 1024 px). */
export function AtAGlance({
  page,
  onAddShelf,
  onTags,
}: {
  page: SeriesPage;
  onAddShelf: () => void;
  onTags: () => void;
}) {
  const followed = page.followedId !== null;
  const total = page.chapters.length;
  const own = page.allTags.filter((x) => page.tagIds.has(x.id));
  const suggested = page.suggested?.available ? page.suggested.tags.slice(0, 5) : [];
  const shelves = ((page.follow as unknown as { collections?: { id: number; name: string }[] } | undefined)?.collections) ?? [];
  const cov = page.coverage?.chapters.length ?? 0;
  const acceptSuggested = async (name: string) => {
    const existing = page.allTags.find((x) => x.name.toLowerCase() === name.toLowerCase());
    if (existing) page.tagSeries.mutate({ ref: page.ref, tagId: existing.id });
  };
  return (
    <div className={s.aag} aria-label="At a glance">
      <div className={s.heavy}>
        <div className={`${t.kicker}`} style={{ color: "var(--mm-color-ink-60)" }}>CHAPTERS READ</div>
        <div className={s.stat}>{page.readCount} / {total}</div>
      </div>
      {followed ? (
        <div className={`${s.slug} ${t.kicker}`} role="group" aria-label="Reading status">
          {STATUS.map(([id, label]) => (
            <button
              key={id}
              type="button"
              aria-pressed={page.follow?.reading_status === id}
              disabled={!page.online}
              onClick={() => page.patch({ reading_status: id })}
            >
              {label}
            </button>
          ))}
        </div>
      ) : null}
      <div className={`${t.folio}`} style={{ color: "var(--mm-color-ink-60)" }}>YOUR TIME HERE {page.timeSpent}</div>
      <div>
        <div className={`${t.kicker}`} style={{ color: "var(--mm-color-ink-60)" }}>TAGS</div>
        <div className={s.tokens}>
          {own.map((x) => (
            <span key={x.id} className={s.chip}>
              {x.name}
              <button
                type="button"
                className={s.quiet}
                style={{ minHeight: 24, padding: 0 }}
                aria-label={`Remove tag ${x.name}`}
                onClick={() => page.untagSeries.mutate({ ref: page.ref, tagId: x.id })}
              >
                ×
              </button>
            </span>
          ))}
          <button type="button" className={s.quiet} onClick={onTags}>Add tag</button>
        </div>
        {suggested.length > 0 ? (
          <div style={{ marginTop: 12 }}>
            <div className={t.kicker} style={{ color: "var(--mm-color-ink-60)" }}>SUGGESTED</div>
            <div className={s.tokens}>
              {suggested.map((name) => (
                <span key={name} className={`${s.chip} ${s.dashed} ${t.micro}`}>
                  {name}
                  <button type="button" className={s.quiet} style={{ minHeight: 24, padding: 0 }} aria-label={`Add suggested tag ${name}`} onClick={() => void acceptSuggested(name)}>+</button>
                  <button type="button" className={s.quiet} style={{ minHeight: 24, padding: 0 }} aria-label={`Reject suggested tag ${name}`} onClick={() => void rejectSuggestedTag(page.ref, name)}>×</button>
                </span>
              ))}
            </div>
          </div>
        ) : null}
      </div>
      <div>
        <div className={t.kicker} style={{ color: "var(--mm-color-ink-60)" }}>SHELVES</div>
        <div className={s.tokens}>
          {shelves.map((c) => (
            <Link key={c.id} className={s.chip} href={`/library/collections/${c.id}`}>{c.name}</Link>
          ))}
          <button type="button" className={s.quiet} onClick={onAddShelf}>Add to shelf</button>
        </div>
      </div>
      {page.coverage ? (
        <div>
          <div className={t.caption}>Dialogue indexed for {cov} of {total} chapters</div>
          <div className={s.rule2}><i style={{ width: `${total ? Math.min(100, (cov / total) * 100) : 0}%` }} /></div>
        </div>
      ) : null}
    </div>
  );
}
