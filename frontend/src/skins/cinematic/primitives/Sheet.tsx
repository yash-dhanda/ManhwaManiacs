"use client";
import { Dialog } from "@base-ui/react/dialog";
import { useEffect, useRef, type ReactNode, type RefObject } from "react";
import { playSound } from "../sounds";
import { useDelayedFlag } from "../motion";
import { LeaderDial } from "./Progress";
import { useCoarsePointer, useDesktopFrame } from "./overlay-hooks";
import { useSheetDrag } from "./useSheetDrag";

export type SheetProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  kicker?: string;
  /** Right-hand quiet button; never an x in a sheet. */
  doneLabel?: string;
  /** Detents [0.5, 0.92] so the page stays visible above (else content height, capped at 0.92). */
  livePreview?: boolean;
  /** Pushes `?sheet=<key>` on open and closes on popstate. */
  historyKey?: string;
  loading?: boolean;
  /** A `Notice` (or any node) shown inside the body. */
  error?: ReactNode;
  initialFocus?: RefObject<HTMLElement | null>;
  /** Extra header content between title and Done (e.g. Quick look's 96 px cover). */
  headerLead?: ReactNode;
  children?: ReactNode;
  className?: string;
  "data-gallery"?: string;
};

/**
 * §7.9 sheet (phone frame) / column panel (desktop frame). Built on Base UI Dialog + `useSheetDrag`: the installed Drawer
 * exposes snap points and swipe direction but not the 30 % / 800 px/s dismissal, the 0.35 rubber band or the `spring.sheet`
 * release, so the drag is ours (same decision as Flutter's CineSheetRoute).
 */
export function Sheet({ open, onOpenChange, title, kicker, doneLabel = "Done", livePreview = false, historyKey, loading = false, error, initialFocus, headerLead, children, className = "", ...rest }: SheetProps) {
  const desktop = useDesktopFrame();
  const coarse = useCoarsePointer();
  const popupRef = useRef<HTMLDivElement>(null);
  const bodyRef = useRef<HTMLDivElement>(null);
  const detents = livePreview ? [0.5, 0.92] : [0.92];
  const showDial = useDelayedFlag(400, open && loading);
  const pushed = useRef(false);
  const close = () => onOpenChange(false);
  const { bind, reset } = useSheetDrag({ popupRef, bodyRef, detents, enabled: open && coarse && !desktop, onDismiss: close });

  // Browser back closes a historyKey sheet; closing another way pops the entry we pushed, once.
  useEffect(() => {
    if (!historyKey || !open) return;
    const url = new URL(window.location.href);
    url.searchParams.set("sheet", historyKey);
    window.history.pushState({ sheet: historyKey }, "", url);
    pushed.current = true;
    const onPop = () => { pushed.current = false; onOpenChange(false); };
    window.addEventListener("popstate", onPop);
    return () => {
      window.removeEventListener("popstate", onPop);
      if (pushed.current) { pushed.current = false; window.history.back(); }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- push once per open
  }, [historyKey, open]);
  useEffect(() => { if (open) { playSound("sheet.open"); reset(); } }, [open]); // eslint-disable-line react-hooks/exhaustive-deps -- once per open

  const rail = desktop
    ? "cine-panel border-l border-rule-2 right-0 bottom-0 w-1/3 min-w-[400px]"
    : `cine-rise border-t border-rule-2 inset-x-0 bottom-0 mx-auto w-full max-w-[720px] ${livePreview ? "h-[92dvh]" : "max-h-[92dvh]"}`;
  return (
    <Dialog.Root open={open} onOpenChange={(o) => onOpenChange(o)}>
      <Dialog.Portal>
        <Dialog.Backdrop className="cine-barrier" style={{ zIndex: "var(--mm-z-sheet)", top: desktop ? "var(--mm-running-head-h, 56px)" : 0 }} />
        <Dialog.Popup
          ref={popupRef} data-stock="raised" data-gallery={rest["data-gallery"]} initialFocus={initialFocus}
          className={`fixed flex flex-col overflow-hidden bg-paper-2 text-ink-100 outline-none ${rail} ${className}`}
          style={{ zIndex: "var(--mm-z-sheet)", ...(desktop ? { top: "var(--mm-running-head-h, 56px)" } : {}) }}
        >
          <div {...bind()} className="shrink-0 touch-none">
            {desktop ? null : <div aria-hidden className="mx-auto mt-2 h-[3px] w-8 bg-ink-30" />}
            <header className="flex min-h-14 items-center gap-4 px-5 py-2">
              {headerLead}
              <div className="min-w-0 flex-1">
                {kicker ? <p className="type-kicker text-ink-45">{kicker}</p> : null}
                <Dialog.Title className="type-subhead text-ink-100">{title}</Dialog.Title>
              </div>
              <Dialog.Close className="type-label inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center px-2 text-ink-60 hover:text-ink-100 hover:underline hover:underline-offset-4">{doneLabel}</Dialog.Close>
            </header>
          </div>
          <div ref={bodyRef} aria-busy={loading || undefined} className="min-h-0 flex-1 overflow-y-auto overscroll-contain border-t border-rule-1 px-5 py-4">
            {loading ? (
              <div className="flex flex-col items-center gap-2 py-8">
                {showDial ? <><LeaderDial size={24} /><p className="type-kicker text-ink-45">LOADING</p></> : null}
              </div>
            ) : error ?? children}
          </div>
        </Dialog.Popup>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
