import type { ReactNode } from "react";

export function Section({ id, title, children }: { id: string; title: string; children: ReactNode }) {
  return (
    <section id={id} className="border-t border-rule-1 py-10">
      <p className="type-kicker mb-6 text-ink-45">{`#${id} — ${title}`}</p>
      <div className="flex flex-col gap-8">{children}</div>
    </section>
  );
}
export const Row = ({ label, children }: { label: string; children: ReactNode }) => (
  <div className="flex flex-col gap-3"><p className="type-folio text-ink-45">{label}</p><div className="flex flex-wrap items-start gap-6">{children}</div></div>
);
