"use client";

import { Menu as BaseMenu } from "@base-ui/react/menu";
import { motion, useMotionValue } from "motion/react";
import { useCallback, useEffect, useRef, useState, type ReactElement, type RefObject } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { announce } from "./announce";
import { Icon, type IconName } from "./Icon";
import { Keycap } from "./Keycap";
import { useBlocker } from "./overlay-queue";
import { springTo, useGlassHost } from "./overlay-utils";
import { Spinner } from "./Progress";
import { suppressLit } from "./lit";

export type MenuEntry =
  | { kind?: "item"; id: string; label: string; icon?: IconName; keys?: string[]; destructive?: boolean; disabled?: boolean; loading?: boolean; error?: string; selected?: boolean; onSelect?: () => void | Promise<void>; forceState?: "hover" | "pressed" | "focus" }
  | { kind: "check"; id: string; label: string; icon?: IconName; checked: boolean; onCheckedChange: (v: boolean) => void; disabled?: boolean }
  | { kind: "gap" };

/** Rows: 44 tall, radius 20, a 20 px icon leading, label `onGlass`; destructive rows keep the label and add a danger glyph on the backing disc. */
function Rows({ items }: { items: MenuEntry[] }) {
  const [busy, setBusy] = useState<string | null>(null);
  const [failed, setFailed] = useState<{ id: string; text: string } | null>(null);
  const run = async (e: Extract<MenuEntry, { kind?: "item" }>, close: () => void) => {
    haptic("select");
    try {
      setBusy(e.id);
      await e.onSelect?.();
      close();
    } catch (err) {
      const text = e.error ?? (err instanceof Error && err.message ? err.message : "Couldn't do that");
      setFailed({ id: e.id, text });
      announce(text);
      setTimeout(() => setFailed(null), 2000);
    } finally { setBusy(null); }
  };
  return (
    <>
      {items.map((e, i) => {
        if (e.kind === "gap") return <div key={`gap-${i}`} className="g-menu__gap" role="separator" />;
        const lead = e.icon ? (e.kind !== "check" && e.destructive ? <span className="g-disc" data-small=""><Icon name={e.icon} size={16} color="var(--mm-color-danger)" /></span> : <Icon name={e.icon} size={20} />) : <span className="g-menu__noicon" />;
        if (e.kind === "check") {
          return (
            <BaseMenu.CheckboxItem key={e.id} className="g-menu__row" label={e.label} checked={e.checked} disabled={e.disabled} onCheckedChange={(v) => { haptic("select"); e.onCheckedChange(v); }} closeOnClick={false} data-testid={`menu-${e.id}`}>
              {lead}<span className="g-menu__label">{e.label}</span>
              <BaseMenu.CheckboxItemIndicator className="g-menu__tick"><span className="g-disc" data-small=""><Icon name="check" size={16} color="var(--mm-color-iris400)" /></span></BaseMenu.CheckboxItemIndicator>
            </BaseMenu.CheckboxItem>
          );
        }
        const err = failed?.id === e.id;
        return (
          <BaseMenu.Item
            key={e.id}
            className="g-menu__row"
            label={e.label}
            disabled={e.disabled}
            closeOnClick={false}
            data-force={e.forceState}
            data-destructive={e.destructive ? "" : undefined}
            data-error={err ? "" : undefined}
            data-testid={`menu-${e.id}`}
            onClick={() => void run(e, () => document.dispatchEvent(new CustomEvent("mm:menu-close")))}
          >
            {err ? <span className="g-disc" data-small=""><Icon name="warning-circle" size={16} color="var(--mm-color-danger)" /></span> : lead}
            <span className="g-menu__label">{err ? failed.text : e.label}</span>
            {busy === e.id || e.loading ? <Spinner size={12} /> : e.selected ? <span className="g-disc" data-small=""><Icon name="check" size={16} color="var(--mm-color-iris400)" /></span> : e.keys ? <span className="g-menu__keys">{e.keys.map((k) => <Keycap key={k}>{k}</Keycap>)}</span> : null}
          </BaseMenu.Item>
        );
      })}
    </>
  );
}

/**
 * The bloom (item H): the menu grows out of its trigger on `morph` from the trigger's centre while the glass tier interpolates from
 * the trigger's tier to T4 (`tierValue`), the content fades in over the last 40 %; dismissal reverses over `dematerialise`.
 */
function useBloom(open: boolean, fromTier: number, origin: () => { x: number; y: number } | null, popup: RefObject<HTMLElement | null>) {
  const scale = useMotionValue(0.4);
  const opacity = useMotionValue(0);
  const content = useMotionValue(0);
  const tier = useMotionValue(fromTier);
  const [mounted, setMounted] = useState(open);
  if (open && !mounted) setMounted(true);
  useEffect(() => {
    if (open) {
      const o = origin();
      const el = popup.current;
      if (el && o) { const r = el.getBoundingClientRect(); el.style.setProperty("transform-origin", `${o.x - r.left}px ${o.y - r.top}px`); }
      scale.set(isGlassReduced() ? 1 : 0.4); opacity.set(0); content.set(0); tier.set(fromTier);
      const a = [play("bloom", scale, 1), play("materialise", opacity, 1), play("bloom", tier, 4)];
      const b = setTimeout(() => play("materialise", content, 1), isGlassReduced() ? 0 : 170);
      return () => { a.forEach((c) => c.stop()); clearTimeout(b); };
    }
    if (!mounted) return;
    const done = () => setMounted(false);
    const c = play("dematerialise", opacity, 0, { onComplete: done });
    play("dematerialise", content, 0);
    if (!isGlassReduced()) springTo(scale, 0.6, "dismiss");
    return () => c.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);
  return { scale, opacity, content, tier, mounted };
}

export interface MenuProps {
  items: MenuEntry[];
  label: string;
  /** the trigger element (a Button, an IconButton, the SplitButton's trailing segment) */
  trigger: ReactElement;
  /** controlled open state for triggers we do not own (SplitButton) */
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  anchor?: HTMLElement | null;
  /** tier of the trigger's glass, where the bloom starts (T2 for buttons) */
  fromTier?: number;
  "data-testid"?: string;
}

export function Menu({ items, label, trigger, open: openProp, onOpenChange, anchor, fromTier = 2, "data-testid": tid }: MenuProps) {
  const [inner, setInner] = useState(false);
  const open = openProp ?? inner;
  const setOpen = useCallback((o: boolean) => { setInner(o); onOpenChange?.(o); }, [onOpenChange]);
  const host = useGlassHost();
  const popup = useRef<HTMLElement | null>(null);
  const trig = useRef<HTMLElement | null>(null);
  useBlocker(open, "menu");
  useEffect(() => (open ? suppressLit() : undefined), [open]);
  useEffect(() => {
    const on = () => setOpen(false);
    document.addEventListener("mm:menu-close", on);
    return () => document.removeEventListener("mm:menu-close", on);
  }, [setOpen]);
  const originOf = () => { const r = (anchor ?? trig.current)?.getBoundingClientRect(); return r ? { x: r.left + r.width / 2, y: r.top + r.height / 2 } : null; };
  const { scale, opacity, content, tier, mounted } = useBloom(open, fromTier, originOf, popup);

  // slide to select: press the trigger and, without lifting, slide onto a row; release selects
  const slide = useRef({ down: false, x: 0, y: 0, moved: false, hot: null as HTMLElement | null });
  const onTriggerDown = (e: React.PointerEvent) => {
    slide.current = { down: true, x: e.clientX, y: e.clientY, moved: false, hot: null };
    const move = (ev: PointerEvent) => {
      const s = slide.current;
      if (!s.down) return;
      if (Math.hypot(ev.clientX - s.x, ev.clientY - s.y) > 8) s.moved = true;
      if (!s.moved) return;
      const row = (document.elementFromPoint(ev.clientX, ev.clientY) as HTMLElement | null)?.closest<HTMLElement>('[role^="menuitem"]') ?? null;
      if (row !== s.hot) { s.hot?.removeAttribute("data-slide-hot"); row?.setAttribute("data-slide-hot", ""); if (row) haptic("select"); s.hot = row; }
    };
    const up = () => {
      const s = slide.current;
      s.down = false;
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      if (s.moved && s.hot) { const row = s.hot; row.removeAttribute("data-slide-hot"); row.click(); }
    };
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
  };

  return (
    <BaseMenu.Root open={open} onOpenChange={setOpen} modal={false}>
      <BaseMenu.Trigger render={trigger} ref={(el: HTMLElement | null) => { trig.current = el; }} onPointerDown={onTriggerDown} />
      {mounted && host ? (
        <BaseMenu.Portal container={host}>
          <BaseMenu.Positioner anchor={anchor ?? undefined} sideOffset={8} align="start" collisionPadding={12} className="g-menu-pos">
            <BaseMenu.Popup
              className="g-menu"
              aria-label={label}
              render={(p) => <motion.div {...(p as object)} ref={(el: HTMLDivElement | null) => { popup.current = el; const r = (p as { ref?: React.Ref<HTMLDivElement> }).ref; if (typeof r === "function") r(el); else if (r) (r as { current: HTMLDivElement | null }).current = el; }} style={{ scale, opacity }} data-testid={tid ?? "menu"} />}
            >
              <GlassSurface tier="t4" tierValue={tier} radius={26} layer="overlays" materialize={false} className="g-menu__glass">
                <motion.div className="g-menu__inner" style={{ opacity: content }}><Rows items={items} /></motion.div>
              </GlassSurface>
            </BaseMenu.Popup>
          </BaseMenu.Positioner>
        </BaseMenu.Portal>
      ) : null}
    </BaseMenu.Root>
  );
}

/** The anchored form used by context menus: no trigger element, a virtual anchor (a point or an element). */
export function AnchoredMenu({ items, label, open, onOpenChange, anchor, "data-testid": tid }: { items: MenuEntry[]; label: string; open: boolean; onOpenChange: (o: boolean) => void; anchor: { x: number; y: number } | HTMLElement | null; "data-testid"?: string }) {
  const host = useGlassHost();
  const popup = useRef<HTMLElement | null>(null);
  useBlocker(open, "menu");
  useEffect(() => (open ? suppressLit() : undefined), [open]);
  useEffect(() => {
    const on = () => onOpenChange(false);
    document.addEventListener("mm:menu-close", on);
    return () => document.removeEventListener("mm:menu-close", on);
  }, [onOpenChange]);
  const virtual = anchor && !(anchor instanceof HTMLElement) ? { getBoundingClientRect: () => new DOMRect(anchor.x, anchor.y, 0, 0) } : anchor ?? undefined;
  const origin = () => {
    if (!anchor) return null;
    if (anchor instanceof HTMLElement) { const r = anchor.getBoundingClientRect(); return { x: r.left + r.width / 2, y: r.bottom }; }
    return anchor;
  };
  const { scale, opacity, content, tier, mounted } = useBloom(open, 3, origin, popup);
  if (!mounted || !host) return null;
  return (
    <BaseMenu.Root open={open} onOpenChange={onOpenChange} modal={false}>
      <BaseMenu.Portal container={host}>
        <BaseMenu.Positioner anchor={virtual} sideOffset={anchor instanceof HTMLElement ? 10 : 2} align="start" collisionPadding={12} className="g-menu-pos">
          <BaseMenu.Popup
            className="g-menu"
            aria-label={label}
            render={(p) => <motion.div {...(p as object)} ref={(el: HTMLDivElement | null) => { popup.current = el; const r = (p as { ref?: React.Ref<HTMLDivElement> }).ref; if (typeof r === "function") r(el); else if (r) (r as { current: HTMLDivElement | null }).current = el; }} style={{ scale, opacity }} data-testid={tid ?? "context-menu"} />}
          >
            <GlassSurface tier="t4" tierValue={tier} radius={26} layer="overlays" materialize={false} className="g-menu__glass">
              <motion.div className="g-menu__inner" style={{ opacity: content }}><Rows items={items} /></motion.div>
            </GlassSurface>
          </BaseMenu.Popup>
        </BaseMenu.Positioner>
      </BaseMenu.Portal>
    </BaseMenu.Root>
  );
}
