"use client";
import { toast } from "sonner";

export type SubtitleTone = "info" | "success" | "error";
const EDGE: Record<SubtitleTone, string> = { info: "bg-spot", success: "bg-set", error: "bg-proof" };

/** §7.11 surface: paper.2 raised, 1 px rule.2, 2 px tone edge, type-ui text that grows (never truncated), one quiet underlined action. */
export function SubtitleView({ id, text, tone, action, reader = false }: {
  id: string | number; text: string; tone: SubtitleTone; action?: { label: string; onAction: () => void }; reader?: boolean;
}) {
  return (
    <div
      role={tone === "error" ? "alert" : "status"} tabIndex={-1}
      data-stock={reader ? undefined : "raised"} data-gallery="subtitle" data-tone={tone}
      onKeyDown={(e) => { if (e.key === "Escape") toast.dismiss(id); }}
      style={reader ? { background: "var(--stock-page)", color: "var(--stock-ink)" } : undefined}
      className={`cine-toast relative flex w-full max-w-[560px] items-center gap-4 border border-rule-2 py-3 pr-4 pl-4 outline-none ${reader ? "" : "bg-paper-2 text-ink-100 "}`}
    >
      <span aria-hidden className={`absolute inset-y-0 left-0 w-0.5 ${EDGE[tone]}`} />
      <p className="type-ui min-w-0 flex-1">{text}</p>
      {action ? (
        <button type="button" onClick={() => { action.onAction(); toast.dismiss(id); }}
          className="type-label inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) shrink-0 items-center justify-center px-2 underline underline-offset-4">{action.label}</button>
      ) : null}
    </div>
  );
}
