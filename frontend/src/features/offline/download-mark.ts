import type { SavedChapterEntry } from "./types";

export type DownloadMarkState =
  | { kind: "none" }
  | { kind: "queued" }
  | { kind: "downloading"; progress: number }
  | { kind: "saved" }
  | { kind: "failed" }
  | { kind: "paused" }
  | { kind: "stale" };

/** `queued` is page-side (a picked chapter the run has not reached); pass it in. */
export function downloadMarkState(
  entry: SavedChapterEntry | null | undefined,
  queued = false,
): DownloadMarkState {
  if (!entry) return queued ? { kind: "queued" } : { kind: "none" };
  if (entry.status === "saving") {
    const p = entry.pageCount > 0 ? entry.savedPages / entry.pageCount : 0;
    return { kind: "downloading", progress: Math.min(1, Math.max(0, p)) };
  }
  if (entry.status === "paused") return { kind: "paused" };
  if (entry.stale) return { kind: "stale" };
  if (entry.status === "partial" || entry.failed > 0 || entry.savedPages < entry.pageCount) {
    return { kind: "failed" };
  }
  return { kind: "saved" };
}

/** DP7 wording, which is also the control's accessible name and tooltip. */
export function downloadMarkLabel(state: DownloadMarkState): string {
  switch (state.kind) {
    case "none":
      return "Download";
    case "queued":
      return "Queued to download";
    case "downloading":
      return `Downloading, ${Math.round(state.progress * 100)} percent`;
    case "saved":
      return "Downloaded — opens with no connection";
    case "failed":
      return "Failed, tap to retry";
    case "paused":
      return "Paused — this browser is out of room";
    case "stale":
      return "The source changed these pages — download it again";
  }
}
