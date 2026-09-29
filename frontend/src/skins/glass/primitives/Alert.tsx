"use client";

import { AlertDialog } from "@base-ui/react/alert-dialog";
import { animate, motion, useMotionValue } from "motion/react";
import { useEffect, useLayoutEffect, useRef, useState, type ReactNode, type RefObject } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { announce } from "./announce";
import { Button } from "./Button";
import { settleConfirm, useConfirmRequest } from "./confirmAlert";
import { Icon } from "./Icon";
import { suppressLit } from "./lit";
import { useBlocker } from "./overlay-queue";
import { springTo, useGlassHost } from "./overlay-utils";
import { shake } from "./shake";

export interface AlertAction {
  label: string;
  onPress?: () => void | Promise<void>;
  /** `destructive` is the solid danger confirm; `cancel` is the least destructive; default a secondary twin */
  kind?: "default" | "cancel" | "destructive";
}

export interface AlertProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  body?: ReactNode;
  /** secondary lines: onGlass at footnote size, never alpha labels (an alert can open over a reader page) */
  secondary?: ReactNode;
  /** an optional warning or danger box: a surface2 slab with a 3 px leading bar in the semantic colour */
  box?: { tone: "warning" | "danger"; text: ReactNode };
  /** the least destructive action first */
  actions: AlertAction[];
  /** the control it blooms from; centre otherwise */
  source?: HTMLElement | RefObject<HTMLElement | null> | null;
  /** the confirm shows its loading state and the alert cannot be dismissed */
  pending?: boolean;
  /** an inline onGlass line above the buttons; the confirm shakes; announced through the assertive region */
  error?: string | null;
  "data-testid"?: string;
}

const elOf = (s: AlertProps["source"]) => (s && "current" in s ? s.current : s) ?? null;

/** Base UI AlertDialog owns roles, focus and dismissal; Motion owns the bloom. */
export function Alert(props: AlertProps) {
  const [mounted, setMounted] = useState(props.open);
  if (props.open && !mounted) setMounted(true);
  if (!mounted) return null;
  return <AlertBody {...props} onExited={() => setMounted(false)} />;
}

function AlertBody({ open, onOpenChange, title, body, secondary, box, actions, source, pending, error, onExited, "data-testid": tid }: AlertProps & { onExited: () => void }) {
  const host = useGlassHost();
  useBlocker(open, "alert"); // the queue itself only lets an alert hold items on phones
  useEffect(() => suppressLit(), []);
  const first = useRef<HTMLButtonElement | null>(null);
  const confirmRef = useRef<HTMLButtonElement | null>(null);
  const popup = useRef<HTMLElement | null>(null);
  const opacity = useMotionValue(0);
  const scale = useMotionValue(1);
  const dim = useMotionValue(0);
  const src = elOf(source);
  const exited = useRef(false);

  // present: bloom from the source control (0.9 from its centre) or from the centre (0.94)
  useLayoutEffect(() => {
    const el = popup.current;
    if (el && src && src.isConnected) {
      const r = src.getBoundingClientRect();
      const pr = el.getBoundingClientRect();
      el.style.transformOrigin = `${r.left + r.width / 2 - pr.left}px ${r.top + r.height / 2 - pr.top}px`;
    }
    scale.set(src ? 0.9 : 0.94);
    opacity.set(0);
    const reduced = isGlassReduced();
    const a = play("bloom", scale, 1);
    const b = play("materialise", opacity, 1);
    const d = animate(dim, 1, { duration: 0.18, ease: "linear" });
    if (reduced) scale.set(1);
    return () => { a.stop(); b.stop(); d.stop(); };
    // mount only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // dismiss: shrink to 0.96 on `dismiss` while dematerialising over 350 ms
  useEffect(() => {
    if (open) return;
    const done = () => { if (!exited.current) { exited.current = true; onExited(); } };
    play("dematerialise", opacity, 0, { onComplete: done });
    animate(dim, 0, { duration: 0.35, ease: "linear" });
    if (!isGlassReduced()) springTo(scale, 0.96, "dismiss");
  }, [open, onExited, opacity, scale, dim]);

  useEffect(() => { if (error) { announce(error); shake(confirmRef.current, 8); } }, [error]);

  // buttons: stacked when there are three, or when two labels do not both fit side by side at M 44
  const row = useRef<HTMLDivElement | null>(null);
  const [stacked, setStacked] = useState(actions.length > 2);
  useLayoutEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- more than two actions always stack
    if (actions.length > 2) { setStacked(true); return; }
    const el = row.current;
    if (!el) return;
    const fits = () => {
      const kids = Array.from(el.children) as HTMLElement[];
      const need = kids.reduce((a, k) => a + k.scrollWidth, 0) + 8 * (kids.length - 1);
      setStacked(need > el.clientWidth);
    };
    fits();
    const ro = new ResizeObserver(fits);
    ro.observe(el);
    return () => ro.disconnect();
  }, [actions.length]);

  if (!host) return null;
  const destructive = actions.findIndex((a) => a.kind === "destructive");
  const ordered = actions; // least destructive first: on top of a stack, leading in a row so the confirm trails
  return (
    <AlertDialog.Root open onOpenChange={(o) => { if (!o && !pending) onOpenChange(false); }}>
      <AlertDialog.Portal container={host}>
        <div className="g-alert-layer" data-testid={tid ? `${tid}-layer` : undefined}>
          <AlertDialog.Backdrop className="g-alert__dim" render={<motion.div style={{ opacity: dim }} />} />
          <div className="g-alert__center">
            <AlertDialog.Popup
              className="g-alert"
              initialFocus={first}
              finalFocus={() => (src && src.isConnected ? src : true)}
              render={(p) => (
                <motion.div
                  {...(p as object)}
                  ref={(el: HTMLDivElement | null) => { popup.current = el; const r = (p as { ref?: React.Ref<HTMLDivElement> }).ref; if (typeof r === "function") r(el); else if (r) (r as { current: HTMLDivElement | null }).current = el; }}
                  style={{ opacity, scale }}
                  data-testid={tid ?? "alert"}
                  data-stacked={stacked ? "" : undefined}
                  data-pending={pending ? "" : undefined}
                />
              )}
            >
              <GlassSurface tier="t4" radius={26} layer="interruptions" className="g-alert__glass" materialize={false}>
                <div className="g-alert__inner">
                  <AlertDialog.Title className="g-alert__title type-title3">{title}</AlertDialog.Title>
                  {body ? <AlertDialog.Description className="g-alert__body type-callout">{body}</AlertDialog.Description> : null}
                  {secondary ? <p className="g-alert__secondary type-footnote">{secondary}</p> : null}
                  {box ? (
                    <div className="g-alert__box" data-tone={box.tone}>
                      <span className="g-alert__bar" aria-hidden="true" />
                      <span className="type-footnote">{box.text}</span>
                    </div>
                  ) : null}
                  {error ? (
                    <p className="g-alert__error type-footnote" data-testid="alert-error">
                      <span className="g-disc" data-small=""><Icon name="warning-circle" size={16} color="var(--mm-color-danger)" /></span>
                      <span>{error}</span>
                    </p>
                  ) : null}
                  <div ref={row} className="g-alert__actions" data-stacked={stacked ? "" : undefined}>
                    {ordered.map((a, i) => {
                      const isConfirm = i === destructive || (destructive < 0 && a.kind !== "cancel" && i === ordered.length - 1);
                      return (
                        <Button
                          key={a.label}
                          ref={(el) => { if (i === 0) first.current = el; if (isConfirm) confirmRef.current = el; }}
                          variant={a.kind === "destructive" ? "destructiveConfirm" : "secondary"}
                          size={stacked ? "L" : "M"}
                          twin={a.kind === "destructive" ? undefined : "onGlass"}
                          label={a.label}
                          loading={pending && isConfirm}
                          disabled={pending && !isConfirm}
                          onPress={() => { haptic(a.kind === "destructive" ? "delete.confirm" : "tap.secondary"); void a.onPress?.(); }}
                          data-testid={`alert-action-${i}`}
                        />
                      );
                    })}
                  </div>
                </div>
              </GlassSurface>
            </AlertDialog.Popup>
          </div>
        </div>
      </AlertDialog.Portal>
    </AlertDialog.Root>
  );
}

/** Renders whatever `confirmAlert()` has queued. Mount once (the Shell does; the gallery does). */
export function AlertHost() {
  const req = useConfirmRequest();
  const [last, setLast] = useState(req);
  if (req && req !== last) setLast(req); // keep the content on screen while the alert animates out
  const [ui, setUi] = useState<{ id: number; pending: boolean; error: string | null }>({ id: -1, pending: false, error: null });
  const shown = req ?? last;
  if (!shown) return null;
  const mine = ui.id === shown.id ? ui : { id: shown.id, pending: false, error: null };
  const cancel = () => settleConfirm(shown.id, false);
  const confirm = async () => {
    if (mine.pending) return;
    if (shown.onConfirm) {
      setUi({ id: shown.id, pending: true, error: null });
      try { await shown.onConfirm(); } catch (e) { setUi({ id: shown.id, pending: false, error: e instanceof Error && e.message ? e.message : "That didn't work. Try again." }); return; }
      setUi({ id: shown.id, pending: false, error: null });
    }
    settleConfirm(shown.id, true);
  };
  return (
    <Alert
      open={!!req}
      onOpenChange={(o) => { if (!o) cancel(); }}
      title={shown.title}
      body={shown.body}
      source={shown.source}
      pending={mine.pending}
      error={mine.error}
      actions={[
        { label: shown.cancelLabel ?? "Cancel", kind: "cancel", onPress: cancel },
        { label: shown.confirmLabel ?? "Confirm", kind: shown.destructive ? "destructive" : "default", onPress: confirm },
      ]}
    />
  );
}
