"use client";

import { useEffect, useRef, type CSSProperties } from "react";
import { Icon } from "./Icon";
import { ProfileOrb } from "./ProfileOrb";
import { Spinner } from "./Progress";
import { pop } from "./shake";

export type StatusKey = "reading" | "completed" | "on-hold" | "plan" | "dropped" | "unread";
export const STATUS: Record<StatusKey, { text: string; color: string }> = {
  reading: { text: "Reading", color: "var(--mm-color-iris400)" },
  completed: { text: "Completed", color: "var(--mm-color-success)" },
  "on-hold": { text: "On hold", color: "var(--mm-color-warning)" },
  plan: { text: "Plan to read", color: "var(--mm-color-info, #6CB8FF)" },
  dropped: { text: "Dropped", color: "var(--mm-color-g700)" },
  unread: { text: "Unread", color: "var(--mm-color-g800)" },
};

export type BadgeProps =
  | { kind: "count"; count: number; max?: 9 | 99; loading?: boolean; error?: boolean; disabled?: boolean }
  | { kind: "dot"; label?: string }
  | { kind: "new"; count: number }
  | { kind: "status"; status: StatusKey; onCover?: boolean }
  | { kind: "mature"; onCover?: boolean; glyph?: boolean }
  | { kind: "source"; name: string; iconUrl?: string }
  | { kind: "downloaded"; onCover?: boolean }
  | { kind: "offline"; text: string }
  | { kind: "role"; text: string }
  | { kind: "friend"; name?: string };

const cap = (n: number, max: number) => (n > max ? `${max}+` : String(n));

/** The text a badge contributes to its host's accessible name: "Solo Leveling, 3 new chapters, downloaded". Badges are never the only signal. */
export function badgeLabel(b: BadgeProps): string {
  switch (b.kind) {
    case "count": return `${b.count} new`;
    case "new": return `${b.count} new chapter${b.count === 1 ? "" : "s"}`;
    case "dot": return b.label ?? "new";
    case "status": return STATUS[b.status].text.toLowerCase();
    case "mature": return "18+";
    case "source": return b.name;
    case "downloaded": return "downloaded";
    case "offline": return b.text;
    case "role": return b.text;
    case "friend": return "friend";
  }
}

export function Badge(b: BadgeProps) {
  const ref = useRef<HTMLSpanElement>(null);
  const count = b.kind === "count" || b.kind === "new" ? b.count : undefined;
  const first = useRef(true);
  useEffect(() => { if (first.current) { first.current = false; return; } if (b.kind === "count") pop(ref.current, 1.25); }, [count, b.kind]);
  switch (b.kind) {
    case "count":
      return (
        <span ref={ref} className="g-badge" data-kind="count" data-disabled={b.disabled ? "" : undefined}>
          {b.loading ? <Spinner size={10} /> : b.error ? <i className="g-badge__warn" /> : cap(b.count, b.max ?? 9)}
        </span>
      );
    case "dot": return <span className="g-badge" data-kind="dot" role="img" aria-label={b.label ?? "new"} />;
    case "new": return <span className="g-badge" data-kind="new">{cap(b.count, 99)} NEW</span>;
    case "status": {
      const s = STATUS[b.status];
      return <span className="g-badge" data-kind="status" data-on-cover={b.onCover ? "" : undefined} style={{ "--b-c": s.color } as CSSProperties}>{s.text}</span>;
    }
    case "mature":
      return b.glyph ? <span className="g-badge" data-kind="mature-glyph"><Icon name="age-gate" size={14} color="var(--mm-color-mature)" /></span> : <span className="g-badge" data-kind="mature" data-on-cover={b.onCover ? "" : undefined}>18+</span>;
    case "source":
      return <span className="g-badge" data-kind="source">{b.iconUrl ? <img src={b.iconUrl} alt="" width={12} height={12} /> : <span className="g-badge__mono">{b.name.slice(0, 1).toUpperCase()}</span>}{b.name}</span>;
    case "downloaded": return <span className="g-badge" data-kind="downloaded" data-on-cover={b.onCover ? "" : undefined}><Icon name="droplet" size={14} color="var(--mm-color-success)" weight="fill" /></span>;
    case "offline": return <span className="g-badge" data-kind="offline">{b.text}</span>;
    case "role": return <span className="g-badge" data-kind="role">{b.text}</span>;
    case "friend": return <span className="g-badge" data-kind="friend"><ProfileOrb preset="rose-heart" size={18} name={b.name ?? "Friend"} friend /></span>;
  }
}
