"use client";
import { usePathname } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import { computeNewChaptersBanner, useUpdateNotifications } from "@/features/updates/hooks";
import { Icon } from "../Icon";
import { Button } from "../primitives/Button";
import { frameFor } from "./frames";
import { useShellState } from "./shell-state";
import { useCineRouter } from "./use-cine-router";

const KEY = "mm.updates.banner.dismissedMaxId"; // K49, shared with the legacy banner
const readDismissed = (): number | null => { try { const v = sessionStorage.getItem(KEY); const n = v === null ? NaN : Number.parseInt(v, 10); return Number.isFinite(n) ? n : null; } catch { return null; } };

/** "{n} new chapters across {m} series." / "1 new chapter in 1 series." / "{n} new chapters in 1 series." */
export function stopPressLine(count: number, seriesCount: number): string {
  const c = `${count} new chapter${count === 1 ? "" : "s"}`;
  return seriesCount > 1 ? `${c} across ${seriesCount} series.` : `${c} in 1 series.`;
}

/** Pure view: a subtitle-style strip in raised stock with a 2 px spot left rule. `placement="top"` is for the Page frame (novel reader, web/14). */
export function StopPressBannerView({ count, seriesCount, onRead, onDismiss, placement = "bottom", boxRef }: { count: number; seriesCount: number; onRead: () => void; onDismiss: () => void; placement?: "bottom" | "top"; boxRef?: React.Ref<HTMLDivElement> }) {
  const top = placement === "top";
  return (
    <div ref={boxRef} role="status" data-stock="raised" data-stop-press className="fixed z-(--mm-z-toast) flex max-w-[560px] items-center gap-3 border border-rule-2 bg-paper-2 py-2 pr-2 pl-4 text-ink-100"
      style={top ? { top: 0, left: 0, right: 0, maxWidth: "none" } : { left: "max(var(--mm-grid-margin), 16px)", right: "max(var(--mm-grid-margin), 16px)", bottom: "calc(var(--mm-thumb-index-h, 0px) + 16px)", marginLeft: "var(--mm-sidebar-w, 0px)" }}>
      <span aria-hidden className="absolute inset-y-0 left-0 w-0.5 bg-spot" />
      <div className="min-w-0 flex-1">
        <p className="type-kicker text-ink-45">STOP PRESS</p>
        <p className="type-ui">{stopPressLine(count, seriesCount)}</p>
      </div>
      <Button variant="quiet" size="sm" onClick={onRead}>Read updates</Button>
      <button type="button" aria-label="Dismiss" onClick={onDismiss} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60 hover:text-ink-100"><Icon name="close" size={20} /></button>
    </div>
  );
}

/** Unread notifications polled every 60 s; hidden on /updates and in the Reader frame; dismissal by watermark. Reports its height to the ToastHost. */
export function StopPressBanner({ placement = "bottom" }: { placement?: "bottom" | "top" }) {
  const pathname = usePathname() ?? "/";
  const router = useCineRouter();
  const { data } = useUpdateNotifications(true);
  const [dismissed, setDismissed] = useState<number | null>(null);
  useEffect(() => { setDismissed(readDismissed()); }, []); // eslint-disable-line react-hooks/set-state-in-effect -- session value read after hydration
  const state = computeNewChaptersBanner(data, dismissed);
  const hidden = !state.show || pathname === "/updates" || frameFor(pathname) === "reader";
  const setH = useShellState((s) => s.setBannerHeight);
  const ref = useRef<HTMLDivElement | null>(null);
  const bind = useCallback((el: HTMLDivElement | null) => { ref.current = el; }, []);
  useEffect(() => {
    const el = ref.current;
    if (hidden || !el || placement === "top") { setH(0); return; }
    const ro = new ResizeObserver(() => setH(Math.round(el.getBoundingClientRect().height)));
    ro.observe(el);
    setH(Math.round(el.getBoundingClientRect().height));
    return () => { ro.disconnect(); setH(0); };
  }, [hidden, placement, setH]);
  if (hidden) return null;
  return (
    <StopPressBannerView count={state.count} seriesCount={state.seriesCount} placement={placement} boxRef={bind}
      onRead={() => router.push("/updates", "section")}
      onDismiss={() => { if (state.latestId === null) return; try { sessionStorage.setItem(KEY, String(state.latestId)); } catch { /* private mode */ } setDismissed(state.latestId); }} />
  );
}
