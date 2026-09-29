"use client";
import { Dialog as BaseDialog } from "@base-ui/react/dialog";
import { useEffect, useRef, type ReactNode, type RefObject } from "react";

export type DialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: ReactNode;
  children?: ReactNode;
  /** DOM order is desktop order (Cancel first); the phone frame stacks them reversed so the committing action is on top. */
  actions?: ReactNode;
  /** Error line above the actions, in proof. */
  error?: string;
  /** False while a destructive request runs: Esc and the barrier do nothing. */
  dismissible?: boolean;
  initialFocus?: RefObject<HTMLElement | null>;
  className?: string;
  "data-gallery"?: string;
};

/** §7.10 dialog: paper.3 raised, 1 px ink.30 border, radius 0, max 560, Insert in / 160 ms fade out, no blur behind. */
export function Dialog({ open, onOpenChange, title, description, children, actions, error, dismissible = true, initialFocus, className = "", ...rest }: DialogProps) {
  const openedAt = useRef(0);
  useEffect(() => { if (open) openedAt.current = performance.now(); }, [open]);
  return (
    // An outside press in the first 400 ms is the second tap of the double tap that opened the dialog: ignore it.
    <BaseDialog.Root open={open} onOpenChange={(o, d) => { if (!o && (!dismissible || (d.reason === "outside-press" && performance.now() - openedAt.current < 400))) return; onOpenChange(o); }} disablePointerDismissal={!dismissible}>
      <BaseDialog.Portal>
        <BaseDialog.Backdrop className="cine-barrier cine-barrier--insert" style={{ zIndex: "var(--mm-z-dialog)" }} />
        <div className="pointer-events-none fixed inset-0 flex items-center justify-center" style={{ zIndex: "var(--mm-z-dialog)" }}>
          <BaseDialog.Popup data-stock="raised" data-gallery={rest["data-gallery"]} initialFocus={initialFocus}
            className={`cine-insert pointer-events-auto flex max-h-[90dvh] w-[88%] max-w-[560px] flex-col gap-4 overflow-y-auto border border-ink-30 bg-paper-3 p-6 text-ink-100 outline-none frame:w-full ${className}`}>
            <BaseDialog.Title className="type-subhead text-ink-100">{title}</BaseDialog.Title>
            {description ? <BaseDialog.Description className="type-body max-w-[48ch] text-ink-60">{description}</BaseDialog.Description> : null}
            {children}
            {error ? <p role="alert" className="type-caption text-proof">{error}</p> : null}
            {actions ? <div className="mt-2 flex flex-col-reverse gap-2 frame:flex-row frame:items-center frame:justify-end [&>*]:justify-center">{actions}</div> : null}
          </BaseDialog.Popup>
        </div>
      </BaseDialog.Portal>
    </BaseDialog.Root>
  );
}
