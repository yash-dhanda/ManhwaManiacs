"use client";

import { Menu as BaseMenu } from "@base-ui/react/menu";
import { useState, useSyncExternalStore } from "react";
import type { ContentMode } from "@/features/content-mode/mode";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { haptic } from "../haptics";
import { Icon } from "./Icon";
import { Segmented } from "./Segmented";
import { useGlassHost } from "./overlay-utils";

/** Where the last Manga / Novels switch happened, so screens run their entrance wave from it. */
let origin: { x: number; y: number } | null = null;
const listeners = new Set<() => void>();
export const lastModeSwitchOrigin = () => origin;
export const subscribeModeSwitch = (cb: () => void) => { listeners.add(cb); return () => { listeners.delete(cb); }; };
export const useLastModeSwitchOrigin = () => useSyncExternalStore(subscribeModeSwitch, lastModeSwitchOrigin, () => null);
const record = (el: Element | null) => {
  const r = el?.getBoundingClientRect();
  origin = r ? { x: r.left + r.width / 2, y: r.top + r.height / 2 } : { x: 0, y: 0 };
  listeners.forEach((l) => l());
};

const OPTIONS = [{ value: "manga", label: "Manga" }, { value: "novel", label: "Novels" }] as const;
export type ContentModeVariant = "sidebar" | "navRow" | "menu";

/** The Manga | Novels switch (glass 7.36). Rendered only when the server enables novels. */
export function ContentModeSwitch({ variant = "sidebar", "data-testid": tid }: { variant?: ContentModeVariant; "data-testid"?: string }) {
  const { mode, setMode, novelsEnabled } = useContentMode();
  return <ContentModeSwitchView variant={variant} mode={mode} novelsEnabled={novelsEnabled} onMode={setMode} data-testid={tid} />;
}

/** Presentational half, so the gallery can show it without the bootstrap query. */
export function ContentModeSwitchView({ variant, mode, novelsEnabled, onMode, "data-testid": tid }: { variant: ContentModeVariant; mode: ContentMode; novelsEnabled: boolean; onMode: (m: ContentMode) => void; "data-testid"?: string }) {
  const [open, setOpen] = useState(false);
  const host = useGlassHost();
  if (!novelsEnabled) return null;
  const pick = (next: string, el?: Element | null) => {
    if (next === mode) return;
    haptic("select");
    record(el ?? document.activeElement);
    onMode(next as ContentMode);
  };
  if (variant === "sidebar") {
    return <div className="g-mode" data-variant="sidebar" data-testid={tid ?? "content-mode"}><Segmented label="Content mode" options={OPTIONS} value={mode} onChange={(v) => pick(v)} /></div>;
  }
  if (variant === "navRow") {
    return (
      <div className="g-mode" data-variant="navRow" data-open={open ? "" : undefined} data-testid={tid ?? "content-mode"}>
        {open ? (
          <div className="g-mode__expanded">
            <Segmented label="Content mode" options={OPTIONS} value={mode} onChange={(v) => { pick(v); setOpen(false); }} />
            <p className="g-mode__note">One setting for the whole app</p>
          </div>
        ) : (
          <button type="button" className="g-mode__pill" aria-expanded={false} aria-label={`Content mode: ${mode === "manga" ? "Manga" : "Novels"}`} onClick={() => setOpen(true)}>
            <span>{mode === "manga" ? "Manga" : "Novels"}</span><Icon name="caret-down" size={12} />
          </button>
        )}
      </div>
    );
  }
  // menu: a menuitemradio pair for the Library tab's long-press menu
  const inner = (
    <BaseMenu.RadioGroup value={mode} onValueChange={(v) => pick(String(v))} className="g-mode__radios" data-testid={tid ?? "content-mode"}>
      {OPTIONS.map((o) => (
        <BaseMenu.RadioItem key={o.value} value={o.value} className="g-menu__row" closeOnClick>
          <Icon name={o.value === "manga" ? "strip-scroll" : "book-open"} size={20} /><span className="g-menu__label">{o.label}</span>
          <BaseMenu.RadioItemIndicator className="g-menu__tick"><span className="g-disc" data-small=""><Icon name="check" size={16} color="var(--mm-color-iris400)" /></span></BaseMenu.RadioItemIndicator>
        </BaseMenu.RadioItem>
      ))}
    </BaseMenu.RadioGroup>
  );
  void host;
  return inner;
}
