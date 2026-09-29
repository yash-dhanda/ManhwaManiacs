"use client";

import { ViewTransition, useCallback, useEffect, useRef, useState } from "react";
import { useIsNovelSource } from "@/features/novels/hooks";
import { ApiError } from "@/types/api";
import { BookFeature } from "./book/BookFeature";
import { BookError, BookOffline } from "./book/BookStates";
import { Galley, NotAvailable, Notice } from "./FeatureStates";
import { MangaFeature } from "./manga/MangaFeature";
import { MotionTimings } from "./MotionTimings";
import { sampleTransitions } from "./motion-log";
import { ToastStack } from "./toasts";
import { useSeriesPage } from "./use-series-page";
import "./view-transitions.css";
import s from "./feature.module.css";

export interface FeatureViewProps {
  sourceId: string;
  seriesKey: string;
  followedId: number | null;
  /** A chapter key to centre the book contents on (`?chapter=`). */
  focusChapterKey?: string | null;
}

const GONE = new Set(["series_not_found", "source_not_found"]);

/**
 * The one series page: the manga Feature or the novel Book by the source's
 * content kind, for `/sources/:s/series/:k` and `/library/:followedId` alike.
 */
export function FeatureView({ sourceId, seriesKey, followedId, focusChapterKey = null }: FeatureViewProps) {
  const kind = useIsNovelSource(sourceId);
  const isNovel = kind === true;
  const page = useSeriesPage({ sourceId, seriesKey, followedId, isNovel });
  const [cover, setCoverState] = useState(false);

  // The Lightbox is a history entry (`?view=cover`), so browser back closes it.
  const setCover = useCallback((open: boolean) => {
    setCoverState(open);
    const url = new URL(window.location.href);
    if (open && url.searchParams.get("view") !== "cover") {
      url.searchParams.set("view", "cover");
      window.history.pushState({}, "", url);
    } else if (!open && url.searchParams.get("view") === "cover") {
      window.history.back();
    }
  }, []);
  useEffect(() => {
    const pop = () => setCoverState(new URL(window.location.href).searchParams.get("view") === "cover");
    window.addEventListener("popstate", pop);
    return () => window.removeEventListener("popstate", pop);
  }, []);

  const { series, seriesQuery } = page;
  const title = series?.title ?? page.follow?.title ?? "";
  useEffect(() => {
    if (title) document.title = `${title} · ManhwaManiacs`;
  }, [title]);

  // Next does not animate a history traversal, so back is a view transition of our own: the browser snapshots
  // this page (its cover is named), we wait for the route to commit, and the shared cover plays the 336 ms
  // reverse match cut into whatever wears the same name (`html[data-mm-nav=back]` sets the duration).
  const root = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const html = document.documentElement;
    if (html.dataset.mmNav !== "back") sampleTransitions("in");
    let t: ReturnType<typeof setTimeout> | undefined;
    const back = () => {
      html.dataset.mmNav = "back";
      clearTimeout(t);
      t = setTimeout(() => delete html.dataset.mmNav, 1200);
      const me = root.current;
      // React names view-transition elements only inside its own transitions, so name the cover by hand
      // (`data-mm-cover` marks it, here and on any poster elsewhere that wants the reverse cut).
      const mine = me?.querySelector<HTMLElement>("[data-mm-cover]");
      const name = mine?.dataset.mmCover;
      if (mine && name) {
        mine.style.viewTransitionName = name;
        mine.style.setProperty("view-transition-class", "mm-match-cut");
      }
      let target: HTMLElement | null = null;
      const vt = document.startViewTransition?.(
        () =>
          new Promise<void>((done) => {
            const t0 = performance.now();
            // timers, not rAF: the browser pauses rendering while a transition waits for its DOM update
            const tick = () => {
              const gone = !me?.isConnected;
              target = gone && name ? document.querySelector<HTMLElement>(`[data-mm-cover="${name}"]`) : null;
              if ((gone && (target || !name)) || performance.now() - t0 > 800) {
                if (target) {
                  target.style.viewTransitionName = name!;
                  target.style.setProperty("view-transition-class", "mm-match-cut");
                }
                setTimeout(done, 30);
              } else setTimeout(tick, 16);
            };
            tick();
          }),
      );
      void vt?.finished.finally(() => {
        if (target) {
          (target as HTMLElement).style.viewTransitionName = "";
          (target as HTMLElement).style.removeProperty("view-transition-class");
        }
      });
    };
    // The app router commits a traversal before `popstate` fires, so where the Navigation API exists the
    // `navigate` event (before the commit) is the moment to start the transition.
    const nav = (window as unknown as { navigation?: EventTarget }).navigation;
    const onNavigate = (e: Event) => {
      if ((e as Event & { navigationType?: string }).navigationType === "traverse") back();
    };
    if (nav) nav.addEventListener("navigate", onNavigate);
    else window.addEventListener("popstate", back);
    return () => {
      if (nav) nav.removeEventListener("navigate", onNavigate);
      else window.removeEventListener("popstate", back); // the timer stays: it clears the flag after the transition
      sampleTransitions("out");
    };
  }, []);

  const err = seriesQuery.error;
  const gone = err instanceof ApiError && (GONE.has(err.code) || err.status === 404);
  let body;
  if (gone) body = <NotAvailable title={page.follow?.title} />;
  else if (seriesQuery.isLoading && !series) body = <Galley book={isNovel} />;
  else if (!series) {
    const offline = !page.online;
    body = isNovel ? (
      offline ? <BookOffline /> : <BookError sourceHref={`/sources/${encodeURIComponent(sourceId)}`} onRetry={() => void seriesQuery.refetch()} />
    ) : (
      <Notice
        kicker={offline ? "OFFLINE" : "CORRECTION"}
        headline={offline ? "This series page needs a connection to load." : "Couldn't load this series."}
        deck={offline ? undefined : "The source did not answer."}
        primary={{ label: "Try again", onClick: () => void seriesQuery.refetch() }}
        secondary={{ label: "Back to the source", href: `/sources/${encodeURIComponent(sourceId)}` }}
      />
    );
  } else if (isNovel) {
    body = <BookFeature page={page} series={series} cover={cover} setCover={setCover} focusKey={focusChapterKey} />;
  } else {
    body = <MangaFeature page={page} series={series} cover={cover} setCover={setCover} />;
  }

  return (
    <ViewTransition enter="mm-page-in" exit="mm-page-out" default="none">
      <div ref={root} className={s.page} data-screen="feature" data-kind={isNovel ? "book" : "feature"}>
        {body}
        <ToastStack toasts={page.toasts.toasts} dismiss={page.toasts.dismiss} />
        <MotionTimings />
      </div>
    </ViewTransition>
  );
}
