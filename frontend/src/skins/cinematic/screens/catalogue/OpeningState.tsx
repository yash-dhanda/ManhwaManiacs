"use client";

import { useEffect, useState } from "react";
import { sourceWashHue } from "@/features/sources/source-wash";
import { LeaderDial, Plate } from "../kit/Kit";
import { useTyped } from "../kit/motion";
import d from "./catalogue.module.css";
import { kit as s } from "../kit/Kit";

const TIPS = [
  "Press / to search this source.",
  "Pick a browse mode to change the order.",
  "Tap a genre on any series to browse it here.",
  "Your progress syncs across devices.",
];

/** The wash behind the masthead band: fades in after 3 s of opening. */
export function SourceWash({ sourceId, on }: { sourceId: string; on: boolean }) {
  return <div className={`${d.wash} ${on ? d.washOn : ""}`} style={{ ["--wash" as string]: `hsl(${sourceWashHue(sourceId)} 35% 6%)` }} aria-hidden />;
}

/** Opening-state clock: `slow` flips after 3 s, `tip` rotates every 3.5 s once slow. */
export function useOpening(active: boolean) {
  const [slow, setSlow] = useState(false);
  const [tip, setTip] = useState(0);
  useEffect(() => {
    if (!active) return;
    const t = setTimeout(() => setSlow(true), 3000);
    return () => {
      clearTimeout(t);
      setSlow(false);
    };
  }, [active]);
  useEffect(() => {
    if (!slow) return;
    const t = setInterval(() => setTip((v) => (v + 1) % TIPS.length), 3500);
    return () => clearInterval(t);
  }, [slow]);
  return { slow, tip: TIPS[tip] };
}

export function OpeningDeck({ slow, tip }: { slow: boolean; tip: string }) {
  const typed = useTyped(tip, slow);
  return (
    <>
      <p className={s.deck}>
        {slow ? "This source can take about 10 s." : "Opening the catalogue"} <LeaderDial big />
      </p>
      {slow ? <p className={`${s.caption} ${d.tips}`} aria-live="off">{typed}</p> : null}
    </>
  );
}

export function OpeningPlates() {
  return (
    <div className={d.wall} aria-busy="true">
      {Array.from({ length: 12 }, (_, i) => (
        <Plate key={i} style={{ aspectRatio: "2/3" }} />
      ))}
    </div>
  );
}
