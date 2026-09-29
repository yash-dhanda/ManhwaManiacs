"use client";

import { useEffect, useRef, type CSSProperties } from "react";
import { animate } from "motion/react";
import { useGlassReduced } from "../motion";
import { Icon, type IconName } from "./Icon";
import { Spinner } from "./Progress";
import { usePress, type PressState } from "./usePress";

export const ORB_SIZES = [18, 20, 24, 32, 44, 56, 72, 96, 112, 128, 132] as const;
export type OrbSize = (typeof ORB_SIZES)[number];

/** token slug (color.avatar.<slug>) -> glyph. The two gradient stops and the glyph colour come from the generated tokens. */
export const AVATAR_PRESETS = {
  "violet-spark": "sparkle", "cyan-rocket": "rocket-launch", "rose-heart": "heart", "amber-coffee": "coffee", "emerald-cat": "cat",
  "ember-flame": "flame", "steel-blade": "sword", phantom: "ghost", "arcane-wand": "magic-wand", "lunar-moon": "moon", starlight: "star", bookworm: "book-open",
} as const satisfies Record<string, IconName>;
export type AvatarPreset = keyof typeof AVATAR_PRESETS;

export interface ProfileOrbProps {
  preset: AvatarPreset;
  size?: OrbSize;
  name: string;
  /** the profile's mood colour: a 2 px ring at 60 % */
  mood?: string;
  /** the bloom ring of a friend (`#FF9ED8`) */
  friend?: boolean;
  /** on glass surfaces: 0.5 px rim + specular */
  onGlass?: boolean;
  /** the picker's idle drift: +-3 px on a sine, 5 to 7 s, random phase; frozen under reduced motion */
  drift?: boolean;
  selected?: boolean;
  loading?: boolean;
  error?: boolean;
  disabled?: boolean;
  onPress?: () => void;
  forceState?: PressState;
  /** children render outside the orb, inside the ring host (GoalRing) */
  children?: React.ReactNode;
}

export function ProfileOrb({ preset, size = 44, name, mood, friend, onGlass, drift, selected, loading, error, disabled, onPress, forceState, children }: ProfileOrbProps) {
  const reduced = useGlassReduced();
  const interactive = !!onPress;
  const p = usePress<HTMLElement>({ material: "glass", growth: "medium", disabled, loading, selected, error, forceState, onPress: () => onPress?.(), haptic: "select", stretch: false });
  const drifting = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const el = drifting.current;
    if (!drift || reduced || !el) return;
    const period = 5000 + Math.random() * 2000, phase = Math.random() * Math.PI * 2;
    const c = animate(0, 1, { duration: period / 1000, repeat: Infinity, ease: "linear", onUpdate: (t) => { el.style.translate = `0 ${(3 * Math.sin(phase + t * Math.PI * 2)).toFixed(2)}px`; } });
    return () => { c.stop(); el.style.translate = ""; };
  }, [drift, reduced]);
  const v = (k: string) => `var(--mm-color-avatar-${preset}-${k})`;
  const style = { width: size, height: size, "--orb-from": v("from"), "--orb-to": v("to"), "--orb-glyph": v("glyph"), "--orb-ring": friend ? "#FF9ED8" : mood ? `color-mix(in srgb, ${mood} 60%, transparent)` : "transparent", "--orb-ring-w": selected ? "3px" : "2px" } as CSSProperties;
  const inner = (
    <>
      <span className="g-orb__face">
        {loading ? <Spinner size={size >= 44 ? 24 : 12} /> : <Icon name={AVATAR_PRESETS[preset]} size={Math.round(size * 0.5)} weight="light" color="var(--orb-glyph)" />}
      </span>
      {error ? <span className="g-orb__warn"><Icon name="warning-circle" size={Math.max(12, size * 0.4)} weight="fill" color="var(--mm-color-danger)" /></span> : null}
      {children}
    </>
  );
  const common = { className: "g-orb", style, "data-size": size, "data-friend": friend ? "" : undefined, "data-on-glass": onGlass ? "" : undefined, "data-selected-ring": selected ? "" : undefined, "data-big": size >= 96 ? "" : undefined, "aria-label": name };
  return (
    <span ref={drifting} className="g-orb-host" style={{ width: size, height: size }}>
      {interactive ? (
        <button {...common} {...p.props} type="button">{inner}</button>
      ) : (
        <span {...common} role="img" data-disabled={disabled ? "" : undefined}>{inner}</span>
      )}
    </span>
  );
}
