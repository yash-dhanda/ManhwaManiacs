"use client";

import { useCallback, useEffect, useRef, type ReactNode } from "react";
import { haptic } from "../haptics";
import { GlassSurface, type GlassTwin } from "../glass/GlassSurface";
import { threshold } from "../tokens.generated";
import { useGroup } from "./GlassGroup";
import { Icon, type IconName } from "./Icon";
import { Badge } from "./Badge";
import { Spinner } from "./Progress";
import { Tooltip } from "./Tooltip";
import { pop } from "./shake";
import { useErrorFlash } from "./useErrorFlash";
import { usePress, type PressState } from "./usePress";

export type IconButtonVariant = "nav" | "group" | "plain" | "row";
export type IconTone = "iris" | "streak" | "success";
const TONE: Record<IconTone, string> = { iris: "var(--mm-color-iris400)", streak: "var(--mm-color-streak-core)", success: "var(--mm-color-success)" };

export interface IconButtonProps {
  variant?: IconButtonVariant;
  icon: IconName;
  /** required: the accessible name AND the tooltip. For a toggle it is constant ("Favourite", "Pin source"). */
  label: string;
  onPress?: () => void;
  /** nav only: 450 ms (500 ms on web touch), fires `stack.open` */
  onLongPress?: () => void;
  /** constant-label toggle: sets aria-pressed; on = Fill glyph in `tone` */
  pressed?: boolean;
  tone?: IconTone;
  /** count badge (item M) at the top-right */
  badge?: number;
  disabled?: boolean;
  disabledReason?: string;
  loading?: boolean;
  /** error text, e.g. "Couldn't save": shake, warning-circle for 2 s, assertive announcement */
  error?: string | null;
  /** on a glass host the coloured glyph sits on the 28 px backing disc */
  onGlass?: boolean;
  twin?: GlassTwin;
  forceState?: PressState;
  tooltipLevel?: "default" | "bar";
  className?: string;
}

const disc = (on: boolean, node: ReactNode) => (on ? <span className="g-disc">{node}</span> : node);

export function IconButton({ variant = "nav", icon, label, onPress, onLongPress, pressed, tone = "iris", badge, disabled, disabledReason, loading, error, onGlass, twin, forceState, tooltipLevel, className }: IconButtonProps) {
  const group = useGroup();
  const own = useRef<HTMLButtonElement | null>(null);
  const setOwn = useCallback((el: HTMLButtonElement | null) => { own.current = el; }, []);
  const isGlass = variant === "nav" || variant === "group";
  const long = useRef({ timer: undefined as ReturnType<typeof setTimeout> | undefined, fired: false });
  const p = usePress<HTMLButtonElement>({
    material: variant === "group" ? "glass" : isGlass ? "glass" : "content",
    growth: "feather",
    sink: 0.92,
    disabled, loading, selected: pressed, error: !!error, forceState,
    haptic: pressed === undefined ? "tap.primary" : pressed ? "toggle.off" : "toggle.on",
    onPress: () => { if (long.current.fired) { long.current.fired = false; return; } onPress?.(); },
    onPressStart: (e) => {
      long.current.fired = false;
      if (group) group.light(e.clientX, e.clientY, true);
      if (onLongPress) long.current.timer = setTimeout(() => { long.current.fired = true; haptic("stack.open"); onLongPress(); }, e.pointerType === "touch" ? threshold.stackLongPressWebTouch : threshold.stackLongPress);
    },
    onCancel: () => { clearTimeout(long.current.timer); group?.light(0, 0, false); },
    stretch: false,
    forwardRef: setOwn,
  });
  const getEl = useCallback(() => own.current, []);
  const { flashing } = useErrorFlash(error, getEl, 8);
  const icon2 = useRef<HTMLSpanElement>(null);
  const first = useRef(true);
  useEffect(() => { if (first.current) { first.current = false; return; } if (pressed) pop(icon2.current); }, [pressed]);
  useEffect(() => () => clearTimeout(long.current.timer), []);

  const props = {
    ...p.props,
    onPointerUp: (e: React.PointerEvent<HTMLButtonElement>) => { clearTimeout(long.current.timer); group?.light(0, 0, false); p.props.onPointerUp(e); },
    type: "button" as const,
    "aria-label": label,
    "aria-pressed": pressed === undefined ? undefined : pressed,
    "data-variant": variant,
    className: `g-ib${className ? ` ${className}` : ""}`,
  };
  const on = !!pressed;
  const glyph = flashing ? (
    disc(!!onGlass || isGlass, <Icon name="warning-circle" size={22} color="var(--mm-color-danger)" />)
  ) : loading ? (
    <Spinner size={16} />
  ) : (
    <span ref={icon2} className="g-icon" style={{ color: on ? TONE[tone] : undefined, display: "inline-flex" }}>
      {disc(on && (!!onGlass || isGlass), <Icon name={icon} size={variant === "row" ? 18 : 22} weight={on ? "fill" : "regular"} />)}
    </span>
  );
  const body = (
    <>
      <span className="g-ib__visual">{glyph}</span>
      {badge !== undefined ? <span className="g-ib__badge"><Badge kind="count" count={badge} /></span> : null}
    </>
  );
  const tip = disabled && disabledReason ? disabledReason : label;
  if (variant === "nav") {
    return (
      <Tooltip label={tip} level={tooltipLevel}>
        <GlassSurface {...props} as="button" tier="t2" capsule twin={twin} pressedGlow={p.glow} overContent={false} layer="controls">{body}</GlassSurface>
      </Tooltip>
    );
  }
  return (
    <Tooltip label={tip} level={tooltipLevel}>
      <button {...props}>{body}</button>
    </Tooltip>
  );
}
