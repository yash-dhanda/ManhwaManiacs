"use client";

import Link from "next/link";
import { useMemo, useState, useSyncExternalStore } from "react";
import { ArrowRight, Sparkle } from "lucide-react";
import {
  clearRecentSearches,
  getRecentSearchesServerSnapshot,
  getRecentSearchesSnapshot,
  subscribeRecentSearches,
} from "@/features/library/recent-searches";
import type { GenreEntry } from "@/features/sources/genre-index";
import { useSources } from "@/features/sources/hooks";
import { ROUTES } from "@/skins/contract.generated";
import { BubbleSearch, Certificate18 } from "../../icons/glyphs.generated";
import { HealthMark, RevealText, SourceLogo, kit as s } from "../kit/Kit";
import { useTyped, useNow } from "../kit/motion";
import { GenrePanel } from "./GenrePanel";
import { GenreTiles } from "./GenreTiles";
import { usePinnedSources, useGenreIndex, useTrending } from "./use-discover-data";
import d from "./discover.module.css";

const ASK_EXAMPLE = "A murim regressor who comes back stronger";

export function DiscoverIdle({ aiAvailable, dialogueAvailable, onSearch, openGenre }: { aiAvailable: boolean; dialogueAvailable: boolean; onSearch: (q: string) => void; openGenre?: string | null }) {
  const recent = useSyncExternalStore(subscribeRecentSearches, getRecentSearchesSnapshot, getRecentSearchesServerSnapshot);
  const pinned = usePinnedSources();
  const genres = useGenreIndex(pinned.ids);
  const trending = useTrending(pinned.ids);
  const sources = useSources();
  const now = useNow(30_000);
  const typed = useTyped(ASK_EXAMPLE, aiAvailable);
  const [panel, setPanel] = useState<GenreEntry | null>(null);
  const byId = useMemo(() => new Map((sources.data ?? []).map((x) => [x.id, x])), [sources.data]);
  const fromHash = openGenre ? genres.find((g) => g.label.toLowerCase() === openGenre.toLowerCase()) ?? null : null;
  const [dismissedHash, setDismissedHash] = useState(false);
  const activePanel = panel ?? (!dismissedHash ? fromHash : null);

  let n = 0;
  const num = () => String(++n).padStart(2, "0");

  return (
    <div className={d.idle}>
      {recent.length > 0 ? (
        <section className={d.idleSection} aria-label="Recent searches">
          <div className={d.rowSlug}>
            <span className={s.kicker} style={{ margin: 0 }}>RECENT</span>
            {recent.slice(0, 4).map((r) => (
              <button key={r} type="button" className={s.quiet} onClick={() => onSearch(r)}>
                {r}
              </button>
            ))}
            <button type="button" className={s.quiet} onClick={() => clearRecentSearches()}>
              Clear
            </button>
          </div>
        </section>
      ) : null}

      {aiAvailable ? (
        <section className={d.askBlock} aria-label="Ask the editors">
          <div className={s.kicker}>ASK THE EDITORS</div>
          <p className={d.askPull} aria-label={ASK_EXAMPLE}>
            <span aria-hidden>{typed}</span>
          </p>
          <p className={s.deck}>Describe it in your own words; the editors pick from everywhere.</p>
          <p style={{ marginTop: 16 }}>
            <Link href={`${ROUTES.picks()}#ask`} className={`${s.btn} ${s.focusable}`}>
              <Sparkle size={20} aria-hidden /> Ask
            </Link>
          </p>
        </section>
      ) : null}

      {genres.length > 0 ? (
        <section className={d.idleSection} aria-labelledby="idle-genres">
          <hr className={s.rule1} />
          <h2 id="idle-genres" className={s.sectionHead}>
            <RevealText text={`${num()} Browse by genre`} />
          </h2>
          <GenreTiles genres={genres} onPanel={setPanel} />
        </section>
      ) : null}

      {pinned.rows.length > 0 ? (
        <section className={d.idleSection} aria-labelledby="idle-sources">
          <hr className={s.rule1} />
          <h2 id="idle-sources" className={s.sectionHead}>
            {num()} Sources
          </h2>
          {pinned.rows.map(({ pin, source }) => (
            <Link key={pin.source_id} href={ROUTES.source(pin.source_id)} className={`${d.credit} ${s.link} ${s.focusable}`}>
              <SourceLogo id={pin.source_id} name={source.name} iconUrl={source.icon_url} size={24} />
              <span className={d.creditName}>{source.name}</span>
              <HealthMark health={source.health} now={now} />
              {source.mature ? <Certificate18 size={16} weight="regular" title="18+" /> : null}
            </Link>
          ))}
          <Link href={ROUTES.sources()} className={`${s.quiet} ${s.focusable}`}>
            All {sources.data?.length ?? pinned.rows.length} sources <ArrowRight size={16} aria-hidden />
          </Link>
        </section>
      ) : null}

      {dialogueAvailable ? (
        <section className={d.idleSection} aria-labelledby="idle-dialogue">
          <hr className={s.rule1} />
          <h2 id="idle-dialogue" className={s.sectionHead}>
            {num()} Search what they said
          </h2>
          <div className={d.dialogueEntry}>
            <BubbleSearch size={32} weight="light" />
            <div>
              <div className={s.kicker} style={{ margin: 0 }}>DIALOGUE</div>
              <Link href={ROUTES.dialogue()} className={`${d.dialogueLine} ${s.focusable}`}>
                Find the chapter by a line someone said.
              </Link>
            </div>
          </div>
        </section>
      ) : null}

      {trending.length > 0 ? (
        <section className={d.idleSection} aria-labelledby="idle-trending">
          <hr className={s.rule1} />
          <h2 id="idle-trending" className={s.sectionHead}>
            {num()} Trending on your sources
          </h2>
          <div className={d.rowSlug}>
            {trending.map((t) => (
              <Link key={`${t.sourceId}:${t.seriesKey}`} href={ROUTES.feature(t.sourceId, t.seriesKey)} className={`${s.quiet} ${s.focusable}`}>
                {t.title}
              </Link>
            ))}
          </div>
        </section>
      ) : null}

      <GenrePanel
        entry={activePanel}
        sources={byId}
        now={now}
        onClose={() => {
          setPanel(null);
          setDismissedHash(true);
        }}
      />
    </div>
  );
}
