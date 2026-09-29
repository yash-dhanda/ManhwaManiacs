"use client";

import { downloadMarkLabel, type DownloadMarkState } from "@/features/offline/download-mark";
import s from "../feature.module.css";

const CLASS: Partial<Record<DownloadMarkState["kind"], string>> = {
  queued: s.markQueued,
  saved: s.markSaved,
  failed: s.markFailed,
  paused: s.markPaused,
  stale: s.markStale,
};

/** §7.18: the per-chapter download mark; one button, tooltip = accessible name. */
export function DownloadMark({
  state,
  onPress,
  disabled,
}: {
  state: DownloadMarkState;
  onPress?: () => void;
  disabled?: boolean;
}) {
  const label = downloadMarkLabel(state);
  const actionable = state.kind === "none" || state.kind === "failed" || state.kind === "stale";
  return (
    <button
      type="button"
      className={`${s.mark} ${CLASS[state.kind] ?? ""}`}
      aria-label={label}
      title={label}
      data-mark={state.kind}
      disabled={disabled || (!actionable && !onPress)}
      onClick={(e) => {
        e.preventDefault();
        e.stopPropagation();
        if (actionable) onPress?.();
      }}
    >
      <span className={s.markBox}>
        {state.kind === "downloading" ? (
          <span className={s.markFill} style={{ height: `${Math.round(state.progress * 100)}%` }} />
        ) : null}
      </span>
    </button>
  );
}
