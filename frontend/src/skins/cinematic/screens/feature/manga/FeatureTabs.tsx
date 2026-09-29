"use client";

import type { ReactNode } from "react";
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
  return (
    <>
      <div className={s.wrap}>
        <div className={s.tabs} role="tablist" aria-label="Contents">
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
        </div>
      </div>
      <div className={s.wrap}>
        {tabs.map((tab) => (
          <div
            key={tab.id}
            role="tabpanel"
            id={`panel-${tab.id}`}
            aria-labelledby={`tab-${tab.id}`}
            hidden={tab.id !== active}
            className={s.panel}
          >
            {tab.id === active ? tab.panel : null}
          </div>
        ))}
      </div>
    </>
  );
}
