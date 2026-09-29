/** Label/value pairs: labels type.credit-label ink.45, values type.credit; two columns on the desktop frame, one on the phone, a 1 px rule.1 column rule between. */
export function Credits({ rows }: { rows: { label: string; value: string }[] }) {
  return (
    <dl className="grid grid-cols-1 gap-x-8 gap-y-3 frame:grid-cols-2 frame:[column-rule:1px_solid_var(--mm-color-rule-1)]" style={{ columnGap: 32 }}>
      {rows.map((r) => (
        <div key={r.label} className="flex flex-col gap-0.5">
          <dt className="type-credit-label text-ink-45">{r.label}</dt>
          <dd className="type-credit text-ink-100">{r.value}</dd>
        </div>
      ))}
    </dl>
  );
}
