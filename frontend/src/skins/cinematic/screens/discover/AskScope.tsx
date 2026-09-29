"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { canSubmitPrompt } from "@/features/library/suggestions";
import { useWorldSuggest } from "@/features/library/hooks";
import type { WorldItem } from "@/features/library/types";
import { ROUTES } from "@/skins/contract.generated";
import { aiCopy } from "../../ai-copy";
import { LeaderDial, Notice, Poster, kit as s } from "../kit/Kit";
import { useCountdown, useTyped } from "../kit/motion";
import { errorCode, isStatus, retryAfterSeconds } from "../kit/use-screen";
import d from "./discover.module.css";

function WorldCard({ item }: { item: WorldItem }) {
  const avail = item.available?.[0];
  const href = avail ? ROUTES.feature(avail.source_id, avail.series_key) : ROUTES.discover({ q: item.title });
  return <Poster href={href} title={item.title} coverUrl={item.cover_url ?? null} folio={[item.format, item.status].filter(Boolean).join(" · ").toUpperCase() || null} />;
}

export function AskScope({ prompt, submitted, onSearchInstead }: { prompt: string; submitted: number; onSearchInstead: () => void }) {
  const suggest = useWorldSuggest();
  const [dial, setDial] = useState(false);
  const typed = useTyped("Reading your shelf…", suggest.isPending);
  const { mutate } = suggest;
  useEffect(() => {
    if (submitted > 0 && canSubmitPrompt(prompt, false)) mutate({ prompt: prompt.trim() });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [submitted]);
  useEffect(() => {
    if (!suggest.isPending) return;
    const t = setTimeout(() => setDial(true), 1000);
    return () => {
      clearTimeout(t);
      setDial(false);
    };
  }, [suggest.isPending]);
  const err = suggest.error;
  const left = useCountdown(isStatus(err, 429) && errorCode(err) === "rate_limited" ? retryAfterSeconds(err) : null);

  return (
    <div className={d.field2}>
      {suggest.isPending ? (
        <p className={s.deck} role="status">
          {typed} {dial ? <LeaderDial /> : null}
        </p>
      ) : null}
      {err ? (
        errorCode(err) === "rate_limited" ? (
          <Notice kicker="SLOW DOWN" headline={aiCopy.rate_limited(left)} />
        ) : (
          <Notice kicker="NOTE" headline={aiCopy.forCode(errorCode(err))} />
        )
      ) : null}
      {suggest.data ? (
        <div className={d.threeWide}>
          {suggest.data.items.map((it) => (
            <WorldCard key={it.anilist_id} item={it} />
          ))}
        </div>
      ) : null}
      {suggest.data || err ? (
        <p>
          <button type="button" className={s.quiet} onClick={onSearchInstead}>
            {`Search sources for "${prompt}" instead`}
          </button>
        </p>
      ) : null}
      {!suggest.isPending && !suggest.data && !err ? <p className={s.caption}>Press Enter to ask.</p> : null}
      <Link href={ROUTES.picks()} className={`${s.quiet} ${s.focusable}`}>Open the picks desk</Link>
    </div>
  );
}
