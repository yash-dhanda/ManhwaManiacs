"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { PHONE, useMedia } from "../use-media";
import s from "../feature.module.css";

/** web/19 appends 03 MORE LIKE THIS and web/22 appends 04 CIRCLE to this array. */
export interface FeatureTab {
  id: string;
  folio: string;
  label: string;
  count?: number;
  panel: ReactNode;
}

const SUP = "⁰¹²³⁴⁵⁶⁷⁸⁹";
const sup = (n: number) => String(n).replace(/\d/g, (d) => SUP[Number(d)]);

/** §7.12 contents tabs, sticky under the running head. */
export function FeatureTabs({
  tabs,
  active,
  onChange,
}: {
  tabs: FeatureTab[];
  active: string;
  onChange: (id: string) => void;
}) {
  const phone = useMedia(PHONE);
  const pager = useRef<HTMLDivElement>(null);
  const driving = useRef(false);
  const [frac, setFrac] = useState(0);
  const idx = Math.max(0, tabs.findIndex((x) => x.id === active));

  // A tab press (or a key) moves the pager; a swipe moves the tab, never the other way round mid-gesture.
  useEffect(() => {
    const el = pager.current;
    if (!phone || !el) return;
    if (driving.current) {
      driving.current = false;
      return;
    }
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    el.scrollTo({ left: idx * el.clientWidth, behavior: reduce ? "auto" : "smooth" });
  }, [idx, phone]);

  const onScroll = () => {
    const el = pager.current;
    if (!el || !el.clientWidth) return;
    const f = el.scrollLeft / el.clientWidth;
    setFrac(f);
    const at = Math.round(f);
    if (tabs[at] && tabs[at].id !== active) {
      driving.current = true;
      onChange(tabs[at].id);
    }
  };

  return (
    <>
      <div className={s.wrap}>
        <div className={s.tabs} role="tablist" aria-label="Contents" style={phone ? { display: "grid", gridTemplateColumns: `repeat(${tabs.length}, 1fr)` } : undefined}>
          {tabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              role="tab"
              id={`tab-${tab.id}`}
              aria-selected={tab.id === active}
              aria-controls={`panel-${tab.id}`}
              className={s.tab}
              onClick={() => onChange(tab.id)}
            >
              <span>{tab.folio}</span>
              <span>
                {tab.label}
                {tab.count != null ? <sup>{sup(tab.count)}</sup> : null}
              </span>
            </button>
          ))}
          {phone ? (
            <span aria-hidden="true" className={s.tabRule} data-testid="tab-rule" style={{ width: `${100 / tabs.length}%`, transform: `translateX(${frac * 100}%)` }} />
          ) : null}
        </div>
      </div>
      {phone ? (
        <div ref={pager} className={s.pager} data-testid="pager" onScroll={onScroll}>
          {tabs.map((tab) => (
            <div key={tab.id} role="tabpanel" id={`panel-${tab.id}`} aria-labelledby={`tab-${tab.id}`} className={`${s.pagerPanel} ${s.panel}`} data-active={tab.id === active || undefined}>
              {tab.panel}
            </div>
          ))}
        </div>
      ) : (
        <div className={s.wrap}>
          {tabs.map((tab) => (
            <div key={tab.id} role="tabpanel" id={`panel-${tab.id}`} aria-labelledby={`tab-${tab.id}`} hidden={tab.id !== active} className={s.panel}>
              {tab.id === active ? tab.panel : null}
            </div>
          ))}
        </div>
      )}
    </>
  );
}
