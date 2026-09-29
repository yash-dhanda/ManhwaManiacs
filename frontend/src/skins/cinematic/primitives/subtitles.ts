import { createElement } from "react";
import { toast } from "sonner";
import { durMs } from "../tokens.generated";
import { haptic } from "../haptics";
import { playSound } from "../sounds";
import { SubtitleView, type SubtitleTone } from "./SubtitleView";

type Opts = { id?: string | number; duration?: number };
let readerFrame = false;
/** ToastHost tells the API which frame it is in (novel reader stock colours). */
export const setSubtitleFrame = (frame: "reader" | "page") => { readerFrame = frame === "reader"; };

function show(text: string, tone: SubtitleTone, duration: number, opts: Opts = {}, action?: { label: string; onAction: () => void }) {
  return toast.custom((id) => createElement(SubtitleView, { id, text, tone, action, reader: readerFrame }), {
    id: opts.id, duration: opts.duration ?? duration, unstyled: true,
  });
}

/** §7.11 "subtitles". Holds: 3600 ms, 6000 errors, 8000 with an action, 10000 skin undo; the host pauses them while hovered or focused. */
export const subtitle = {
  info: (text: string, opts?: Opts) => show(text, "info", durMs.holdToast, opts),
  success: (text: string, opts?: Opts) => show(text, "success", durMs.holdToast, opts),
  error: (text: string, opts?: Opts) => show(text, "error", durMs.holdToastError, opts),
  action: (text: string, a: { label: string; onAction: () => void }, opts?: Opts) => show(text, "info", durMs.holdToastAction, opts, a),
  /** Undo toast; `holdMs` 10000 is the skin-switch undo, default 8000. */
  undo: (text: string, onUndo: () => void, opts?: Opts & { holdMs?: number }) =>
    show(text, "info", opts?.holdMs ?? durMs.holdToastAction, opts, { label: "Undo", onAction: () => { haptic("undo"); playSound("undo"); onUndo(); } }),
};
export const dismissSubtitles = () => toast.dismiss();
