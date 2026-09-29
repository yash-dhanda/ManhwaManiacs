"use client";

import type { ReactNode } from "react";
import { Icon, type IconName } from "./Icon";

export type NoticeTone = "info" | "warning" | "danger" | "success";
const TONE: Record<NoticeTone, { icon: IconName; color: string }> = {
  info: { icon: "info", color: "var(--mm-color-info)" },
  warning: { icon: "warning", color: "var(--mm-color-warning)" },
  danger: { icon: "warning-circle", color: "var(--mm-color-danger)" },
  success: { icon: "check-circle", color: "var(--mm-color-success)" },
};

/** A `surface1` slab, radius 20, padding 12 16, a leading 20 px glyph in the semantic colour, callout text, an optional plain action, and a 3 px leading bar. */
export function InlineNotice({ tone = "info", children, action, "data-testid": tid }: { tone?: NoticeTone; children: ReactNode; action?: { label: string; onPress: () => void }; "data-testid"?: string }) {
  const t = TONE[tone];
  return (
    <div className="g-notice" data-tone={tone} role={tone === "danger" ? "alert" : "status"} data-testid={tid}>
      <span className="g-notice__bar" aria-hidden="true" />
      <span className="g-notice__glyph" style={{ color: t.color }}><Icon name={t.icon} size={20} /></span>
      <span className="g-notice__text">{children}</span>
      {action ? <button type="button" className="g-notice__action" onClick={action.onPress}>{action.label}</button> : null}
    </div>
  );
}
