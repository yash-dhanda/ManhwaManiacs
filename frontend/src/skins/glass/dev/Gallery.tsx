"use client";

import { useEffect, useState } from "react";
import { AmbientField, AmbientProvider } from "../glass/AmbientField";
import { GlassBudgetScope } from "../glass/budget";
import { LensDefs } from "../glass/GlassSurface";
import { useLightAngle } from "../glass/useLightAngle";
import { GlassMotionConfig } from "../motion";
import { GlassMotionTimings } from "../motion-timings";
import { SECTIONS } from "./sections";

const root = () => document.documentElement;
function useAttr(name: "solid" | "contrast" | "motion", on: string) {
  const [v, setV] = useState(false);
  const set = (next: boolean) => { setV(next); if (next) root().dataset[name] = on; else delete root().dataset[name]; };
  useEffect(() => () => { delete root().dataset[name]; }, [name]);
  return [v, set] as const;
}

/** Development primitives gallery (web/26 R): one section per family over black, the ambient field and white. */
export function Gallery({ section }: { section?: string }) {
  useLightAngle();
  const [solid, setSolid] = useAttr("solid", "on");
  const [contrast, setContrast] = useAttr("contrast", "more");
  const [motion, setMotion] = useAttr("motion", "reduced");
  const shown = section ? SECTIONS.filter((s) => s.id === section) : SECTIONS;
  return (
    <GlassMotionConfig>
      <AmbientProvider>
        <LensDefs />
        <AmbientField />
        <GlassBudgetScope exempt label="gallery">
          <main className="gal" data-testid="gallery">
            <h1>Glass primitives</h1>
            <div className="gal-toolbar" role="toolbar" aria-label="Gallery switches">
              <button type="button" aria-pressed={solid} onClick={() => setSolid(!solid)}>Solid glass</button>
              <button type="button" aria-pressed={contrast} onClick={() => setContrast(!contrast)}>Increase contrast</button>
              <button type="button" aria-pressed={motion} onClick={() => setMotion(!motion)}>Reduce motion</button>
            </div>
            <nav className="gal-nav" aria-label="Sections">{SECTIONS.map((s) => <a key={s.id} href={`?section=${s.id}`}>{s.title}</a>)}<a href="?">All</a></nav>
            {shown.map((s) => <section key={s.id} id={s.id} data-section={s.id} className="gal-section"><h2>{s.title}</h2>{s.el()}</section>)}
          </main>
          <GlassMotionTimings />
        </GlassBudgetScope>
      </AmbientProvider>
    </GlassMotionConfig>
  );
}
