"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import s from "./feature.module.css";
import t from "./type.module.css";

function useTyped(text: string) {
  const [n, setN] = useState(0);
  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce) {
      const id = setTimeout(() => setN(text.length), 0);
      return () => clearTimeout(id);
    }
    const id = setInterval(() => setN((v) => (v >= text.length ? v : v + 1)), 50);
    return () => clearInterval(id);
  }, [text]);
  return text.slice(0, n);
}

/** A notice: kicker, typed headline at 50 ms per character, deck, actions. */
export function Notice({
  kicker,
  headline,
  deck,
  primary,
  secondary,
}: {
  kicker: string;
  headline: string;
  deck?: string;
  primary?: { label: string; href?: string; onClick?: () => void };
  secondary?: { label: string; href?: string; onClick?: () => void };
}) {
  const typed = useTyped(headline);
  const act = (a: NonNullable<typeof primary>, cls: string) =>
    a.href ? (
      <Link className={cls} href={a.href}>{a.label}</Link>
    ) : (
      <button type="button" className={cls} onClick={a.onClick}>{a.label}</button>
    );
  return (
    <main className={s.notice}>
      <div className={`${t.kicker}`} style={{ color: "var(--mm-color-spot)" }}>{kicker}</div>
      <h1 className={`${t.headline}`} aria-label={headline}>
        <span aria-hidden="true">{typed}</span>
      </h1>
      {deck ? <p className={t.deck}>{deck}</p> : <div style={{ height: 24 }} />}
      <div className={s.actions}>
        {primary ? act(primary, `${s.btn} ${s.secondary}`) : null}
        {secondary ? act(secondary, s.quiet) : null}
      </div>
    </main>
  );
}

/** The §8.0.10 notice. Never reveals 18+. */
export function NotAvailable({ title }: { title?: string | null }) {
  return (
    <Notice
      kicker="NOT IN THIS ISSUE"
      headline="This series isn't available here any more."
      deck="It may have been removed from its source."
      primary={{ label: "Back to Tonight", href: "/" }}
      secondary={{
        label: "Search for it",
        href: title ? `/discover?q=${encodeURIComponent(title)}` : "/discover",
      }}
    />
  );
}

/** The galley: title bars, credit lines, a flickering plate, greeked rows. */
export function Galley({ book }: { book?: boolean }) {
  return (
    <div className={s.page} aria-busy="true" aria-label="Loading">
      <div className={`${s.wrap} ${s.grid}`} style={{ paddingTop: 96 }}>
        <div className={book ? s.bookText : s.spreadText} style={{ gridColumn: book ? undefined : "1 / span 5" }}>
          <div className={s.greek} style={{ height: 56, width: "80%" }} />
          <div className={s.greek} style={{ height: 56, width: "50%", marginTop: 8 }} />
          {[70, 55, 60].map((w) => (
            <div key={w} className={s.greek} style={{ width: `${w}%`, marginTop: 12 }} />
          ))}
        </div>
        <div className={s.bookArt} style={{ gridColumn: "8 / -1", background: "var(--mm-color-galley)" }} />
      </div>
      <div className={s.wrap} style={{ marginTop: 48 }}>
        {Array.from({ length: book ? 10 : 8 }, (_, i) => (
          <div key={i} className={s.row} style={{ cursor: "default" }}>
            <span />
            <span className={s.greek} style={{ width: `${40 + ((i * 13) % 40)}%` }} />
            <span />
            <span />
          </div>
        ))}
      </div>
    </div>
  );
}

/** The chapter-list / contents states of D11 and E7. */
export function ListState({
  state,
  reported,
  source,
  sourceHref,
  onRetry,
  book,
}: {
  state: "loading" | "offline" | "error" | "unavailable" | "empty";
  reported: number;
  source: string;
  sourceHref: string;
  onRetry: () => void;
  book?: boolean;
}) {
  if (state === "loading") {
    return (
      <div aria-busy="true">
        {Array.from({ length: book ? 10 : 8 }, (_, i) => (
          <div key={i} className={s.row} style={{ cursor: "default" }}>
            <span />
            <span className={s.greek} style={{ width: `${40 + ((i * 13) % 40)}%` }} />
            <span />
            <span />
          </div>
        ))}
      </div>
    );
  }
  const text: Record<string, [string, boolean]> = {
    offline: [book ? "The contents need a connection to load." : "The chapter list needs a connection.", true],
    error: [book ? "Couldn't load the contents" : "Couldn't load the chapters.", true],
    unavailable: [
      book
        ? "Contents didn't come through."
        : `${source} lists ${reported} chapters but returned none just now — usually the source, not you.`,
      true,
    ],
    empty: [book ? "No chapters yet." : "No chapters yet. The source hasn't published any.", false],
  };
  const [msg, retry] = text[state];
  return (
    <div style={{ padding: "32px 0" }} role="status">
      <p className={t.body} style={{ color: "var(--mm-color-ink-80)", margin: 0 }}>{msg}</p>
      <div className={s.actions}>
        {retry ? <button type="button" className={`${s.btn} ${s.secondary}`} onClick={onRetry}>Try again</button> : null}
        {!retry && !book ? <Link className={s.quiet} href={sourceHref}>Back to the source</Link> : null}
      </div>
    </div>
  );
}
