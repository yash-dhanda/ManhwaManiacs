"use client";

import { Icon, type IconName } from "../Icon";

/** A 2-up grid cell: glyph 20 `iris400`, a `numeral` value, a label `footnote` `label2`, an optional 7-point sparkline 24 px tall in `iris500`. */
export function StatCard({ icon, value, label, series }: { icon: IconName; value: string; label: string; series?: readonly number[] }) {
  const pts = series?.slice(-7) ?? [];
  const max = Math.max(1, ...pts), min = Math.min(0, ...pts);
  const d = pts.length > 1 ? pts.map((v, i) => `${(i / (pts.length - 1)) * 96},${24 - ((v - min) / (max - min || 1)) * 22 - 1}`).join(" ") : "";
  return (
    <div className="g-card g-stat" data-slab="slab" role="group" aria-label={`${label}: ${value}`}>
      <div className="g-card__body">
        <span className="g-stat__icon"><Icon name={icon} size={20} color="var(--mm-color-iris400)" /></span>
        <p className="g-stat__value type-numeral">{value}</p>
        <p className="type-footnote g-stat__label">{label}</p>
        {d ? <svg className="g-stat__spark" viewBox="0 0 96 24" height={24} width={96} aria-hidden="true"><polyline points={d} fill="none" stroke="var(--mm-color-iris500)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" /></svg> : null}
      </div>
    </div>
  );
}
