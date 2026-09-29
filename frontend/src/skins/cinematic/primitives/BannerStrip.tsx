import type { ReactNode } from "react";

const EDGE = { info: "bg-spot", success: "bg-set", error: "bg-proof", note: "bg-ink-60" } as const;
/** §7.29 banner strip: paper.0 with a 2 px left rule in the tone colour, kicker + one line + actions. Callers place it under the running head. */
export function BannerStrip({ kicker, children, actions, tone = "info", ...rest }: { kicker?: string; children: ReactNode; actions?: ReactNode; tone?: keyof typeof EDGE; "data-gallery"?: string }) {
  return (
    <div role={tone === "error" ? "alert" : "status"} data-gallery={rest["data-gallery"]} className="relative flex flex-wrap items-center gap-x-4 gap-y-1 border-b border-rule-1 bg-paper-0 py-2 pr-4 pl-5 text-ink-100">
      <span aria-hidden className={`absolute inset-y-0 left-0 w-0.5 ${EDGE[tone]}`} />
      {kicker ? <span className="type-kicker text-ink-45">{kicker}</span> : null}
      <p className="type-ui min-w-0 flex-1">{children}</p>
      {actions ? <div className="flex items-center gap-2">{actions}</div> : null}
    </div>
  );
}
