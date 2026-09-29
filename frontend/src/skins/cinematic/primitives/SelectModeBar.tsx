"use client";
import { useShortcut } from "@/lib/keyboard";
import { Icon } from "../Icon";
import type { IconRole } from "../icons/roles.generated";
import { RuleProgress } from "./Progress";
import { useDesktopFrame } from "./overlay-hooks";

export type BulkAction = { id: string; label: string; icon: IconRole; destructive?: boolean; onPress: () => void };

/**
 * §7.29 select-mode bar. Phone: fixed above the safe area over the thumb index; desktop: sticky under the running head.
 * States: selecting (count, Select all, actions, Done), running (`4 OF 12 · 1 FAILED` + determinate rule + Stop), result (line + Dismiss / Undo).
 * Bulk Unfollow: the caller opens a ConfirmDialog (destructive, so the arm applies) from that action.
 */
export function SelectModeBar({ selected, total, actions, onSelectAll, onDone, running, result, ...rest }: {
  selected: number; total: number; actions: BulkAction[]; onSelectAll: () => void; onDone: () => void;
  running?: { done: number; total: number; failed: number; onStop: () => void };
  result?: { text: string; onDismiss: () => void; onUndo?: () => void };
  "data-gallery"?: string;
}) {
  const desktop = useDesktopFrame();
  useShortcut({ id: "select-mode.done", keys: "escape", description: "Leave select mode", group: "Selection", allowInInput: false, handler: onDone });
  const pos = desktop ? "sticky z-(--mm-z-sticky)" : "fixed inset-x-0 z-(--mm-z-chrome)";
  const style = desktop ? { top: "var(--mm-running-head-h, 56px)" } : { bottom: "calc(var(--mm-thumb-index-h, 0px) + env(safe-area-inset-bottom, 0px))" };
  const quiet = "type-label inline-flex min-h-(--mm-hit-min) items-center gap-2 px-3 hover:underline hover:underline-offset-4";
  return (
    <div role="toolbar" aria-label="Selection" data-stock="raised" data-gallery={rest["data-gallery"]} className={`${pos} border-t border-rule-2 bg-paper-2 px-4 text-ink-100`} style={style}>
      {result ? (
        <div className="flex min-h-14 items-center gap-3"><p role="status" className="type-ui flex-1">{result.text}</p>
          {result.onUndo ? <button type="button" className={`${quiet} text-ink-100`} onClick={result.onUndo}>Undo</button> : null}
          <button type="button" className={`${quiet} text-ink-60`} onClick={result.onDismiss}>Dismiss</button></div>
      ) : running ? (
        <div className="flex min-h-14 flex-col justify-center gap-2 py-2">
          <div className="flex items-center gap-3"><p role="status" className="type-folio flex-1">{`${running.done} OF ${running.total}${running.failed ? ` · ${running.failed} FAILED` : ""}`}</p>
            <button type="button" className={`${quiet} text-ink-100`} onClick={running.onStop}>Stop</button></div>
          <RuleProgress value={running.total ? (running.done / running.total) * 100 : 0} label="Bulk action progress" />
        </div>
      ) : (
        <div className="flex min-h-14 flex-wrap items-center gap-x-2">
          <p aria-live="polite" className="type-folio mr-2">{`${selected} SELECTED`}</p>
          <button type="button" className={`${quiet} text-ink-60`} onClick={onSelectAll}>{`Select all ${total}`}</button>
          <span className="flex-1" />
          {actions.map((a) => (
            <button key={a.id} type="button" aria-disabled={selected === 0 || undefined} onClick={() => { if (selected) a.onPress(); }}
              className={`${quiet} ${selected === 0 ? "text-ink-30" : a.destructive ? "text-proof" : "text-ink-100"}`}><Icon name={a.icon} size={20} />{a.label}</button>
          ))}
          <button type="button" className={`${quiet} text-ink-100`} onClick={onDone}>Done</button>
        </div>
      )}
    </div>
  );
}
