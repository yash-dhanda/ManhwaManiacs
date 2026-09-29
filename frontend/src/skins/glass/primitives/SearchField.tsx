"use client";

import { useEffect, useRef, useState } from "react";
import { useDebouncedValue } from "@/lib/use-debounced-value";
import { GlassSurface } from "../glass/GlassSurface";
import { Icon } from "./Icon";
import { IconButton } from "./IconButton";
import { KeyCombos } from "./Keycap";
import { Spinner } from "./Progress";
import { Button } from "./Button";
import { project } from "../physics/project";
import { createTracker } from "../physics/tracker";
import { usePress } from "./usePress";
import type { FieldForce } from "./TextField";

export type SearchVariant = "bottom" | "page" | "filter" | "sidebar";
export type SearchStatus = "idle" | "searching" | "results" | "none" | "error" | "offline";

export interface SearchFieldProps {
  variant?: SearchVariant;
  value?: string;
  /** debounced 300 ms; Enter fires at once */
  onQuery?: (q: string) => void;
  status?: SearchStatus;
  placeholder?: string;
  /** bottom: the trailing plain Cancel */
  onCancel?: () => void;
  /** bottom: a downward drag past 80 px projected dismisses the keyboard, then calls this */
  onCollapse?: () => void;
  /** sidebar: opens the command palette (web/29) */
  onOpenPalette?: () => void;
  /** gallery: draw in place instead of fixed above the keyboard */
  inline?: boolean;
  forceState?: FieldForce;
  "data-testid"?: string;
}

const isIOS = () => typeof navigator !== "undefined" && (/iP(hone|ad|od)/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1));
export const DEFAULT_PLACEHOLDER = "Search series, sources and dialogue";

/** iOS Safari: --vv-h and --vv-top from visualViewport, at most one write per frame, only while focused. Chrome on Android relies on interactive-widget=resizes-content. */
function useVisualViewport(active: boolean) {
  useEffect(() => {
    const vv = typeof window !== "undefined" ? window.visualViewport : null;
    if (!active || !vv || !isIOS()) return;
    let raf = 0;
    const write = () => { raf = 0; const s = document.documentElement.style; s.setProperty("--vv-h", `${vv.height}px`); s.setProperty("--vv-top", `${vv.offsetTop}px`); };
    const on = () => { if (!raf) raf = requestAnimationFrame(write); };
    write();
    vv.addEventListener("resize", on); vv.addEventListener("scroll", on);
    return () => { vv.removeEventListener("resize", on); vv.removeEventListener("scroll", on); cancelAnimationFrame(raf); const s = document.documentElement.style; s.removeProperty("--vv-h"); s.removeProperty("--vv-top"); };
  }, [active]);
}

export function SearchField({ variant = "page", value, onQuery, status = "idle", placeholder = DEFAULT_PLACEHOLDER, onCancel, onCollapse, onOpenPalette, inline, forceState, "data-testid": tid }: SearchFieldProps) {
  const [q, setQ] = useState(value ?? "");
  const [focused, setFocused] = useState(false);
  const input = useRef<HTMLInputElement>(null);
  const [dq] = useDebouncedValue(q, 300);
  const last = useRef(value ?? "");
  useEffect(() => { if (dq !== last.current) { last.current = dq; onQuery?.(dq); } }, [dq]); // eslint-disable-line react-hooks/exhaustive-deps
  // eslint-disable-next-line react-hooks/set-state-in-effect -- a controlled value from the parent replaces the draft
  useEffect(() => { if (value !== undefined) setQ(value); }, [value]);
  useVisualViewport(focused && variant === "bottom");
  const tracker = useRef(createTracker("y"));

  const side = useRef<HTMLButtonElement>(null);
  const press = usePress<HTMLButtonElement>({ material: "content", sink: 0.98, forceState: undefined, onPress: () => onOpenPalette?.(), haptic: "select" });
  void side;
  if (variant === "sidebar") {
    return (
      <button {...press.props} type="button" className="g-search g-search--sidebar" onClick={press.props.onClick} data-testid={tid} aria-label="Search" aria-keyshortcuts="Meta+K Control+K">
        <Icon name="magnifying-glass" size={16} /><span className="g-search__ph">Search</span><KeyCombos combo="mod+k" />
      </button>
    );
  }
  const fire = () => { last.current = q; onQuery?.(q); };
  const offline = status === "offline";
  const lead = status === "searching" ? <Spinner size={16} /> : offline ? <span className="g-disc" data-small=""><Icon name="wifi-slash" size={16} color="var(--mm-color-warning)" /></span> : <Icon name="magnifying-glass" size={20} />;
  const field = (
    <>
      <span className="g-search__lead">{lead}</span>
      <input ref={input} type="search" enterKeyHint="search" value={q} placeholder={placeholder} aria-label="Search" autoComplete="off" autoCapitalize="none" spellCheck={false} data-testid={tid}
        onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => { if (e.key === "Enter") fire(); }}
        onFocus={() => setFocused(true)} onBlur={() => setFocused(false)} />
      {variant === "filter" && q ? <IconButton variant="plain" icon="x" label="Clear search" onPress={() => { setQ(""); input.current?.focus(); }} /> : null}
    </>
  );
  const helper = offline ? <p className="g-field__msg g-search__helper">Offline: searching this device only</p> : null;
  if (variant === "filter") return <div className="g-search-wrap"><div className="g-search g-search--filter" data-status={status} data-force={forceState}>{field}</div>{helper}</div>;

  const onDown = (e: React.PointerEvent) => { if (variant === "bottom" && e.pointerType !== "mouse" && e.target !== input.current) tracker.current.start(e); };
  const onMove = (e: React.PointerEvent) => { tracker.current.move(e); };
  const onUp = () => {
    if (variant !== "bottom") return;
    const { offset, velocity } = tracker.current.end();
    if (project(offset, velocity) > 80) { input.current?.blur(); onCollapse?.(); }
  };
  return (
    <div className={`g-search-wrap${variant === "bottom" && !inline ? " g-search-wrap--fixed" : ""}`} data-variant={variant}>
      <GlassSurface tier="t3" capsule finish="regular" layer="controls" className={`g-search g-search--${variant}`} data-status={status} data-force={forceState} onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp}>
        {field}
      </GlassSurface>
      {variant === "bottom" ? <Button variant="plain" size="M" label="Cancel" onPress={() => { setQ(""); input.current?.blur(); onCancel?.(); }} /> : null}
      {helper}
    </div>
  );
}
