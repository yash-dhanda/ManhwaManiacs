import type { ReactNode } from "react";
import { cn } from "@/lib/cn";

export type BadgeVariant =
  | "new" | "status" | "reading" | "certificate" | "saved" | "text" | "stale" | "picked" | "pickedAgo" | "smart" | "shared"
  | "now" | "count" | "admin" | "you" | "deactivated";

/** The one reading-status vocabulary (§7.19). `COMPLETED` is reserved for publication status. */
export function readingStatusLabel(status: "unread" | "reading" | "on_hold" | "plan_to_read" | "completed" | "dropped", short = false): string {
  switch (status) {
    case "unread": return "NOT STARTED";
    case "reading": return "READING";
    case "on_hold": return "ON HOLD";
    case "plan_to_read": return short ? "PLAN" : "PLAN TO READ";
    case "completed": return "DONE";
    case "dropped": return "DROPPED";
  }
}

const OUTLINE: Record<BadgeVariant, string> = {
  new: "bg-spot text-paper-0",
  status: "border border-ink-45 text-ink-60",
  reading: "border border-ink-100 text-ink-100",
  certificate: "border border-proof text-proof",
  saved: "border border-set text-set",
  text: "border border-ink-45 text-ink-45",
  stale: "border border-spot text-spot",
  picked: "border border-ink-100 text-ink-100",
  pickedAgo: "border border-ink-45 text-ink-45",
  smart: "border border-ink-45 text-ink-45",
  shared: "border border-ink-45 text-ink-45",
  now: "bg-ink-100 text-paper-0",
  count: "bg-spot text-paper-0",
  admin: "border border-ink-100 text-ink-100",
  you: "bg-ink-100 text-paper-0",
  deactivated: "border border-proof text-proof",
};

/** §7.19: square boxes, min height 16, horizontal padding 4, type.micro. `onArt` puts a #000000 fill inside the outline. */
export function Badge({ variant, children, onArt = false, large = false, count, className }: { variant: BadgeVariant; children?: ReactNode; onArt?: boolean; large?: boolean; count?: number; className?: string }) {
  if (variant === "certificate") {
    const s = large ? "size-5" : "size-4";
    return (
      <span role="img" aria-label="Mature, 18 plus" className={cn("inline-flex items-center justify-center", s, OUTLINE.certificate, onArt && "bg-paper-0", className)}>
        <span aria-hidden className="font-grotesk" style={{ fontSize: large ? 12 : 10, fontVariationSettings: '"wdth" 62, "wght" 800', lineHeight: 1 }}>18</span>
      </span>
    );
  }
  if (variant === "count") {
    const n = count ?? 0;
    return <span aria-label={`${n}`} className={cn("type-folio inline-flex min-h-4 min-w-4 items-center justify-center px-1", OUTLINE.count, className)} style={{ fontSize: 10 }}><span aria-hidden>{n > 99 ? "99+" : n}</span></span>;
  }
  const label = variant === "new" && count !== undefined ? `${count > 99 ? "99+" : count} NEW` : children;
  return <span className={cn("type-micro inline-flex min-h-4 items-center px-1 py-0.5", OUTLINE[variant], onArt && "bg-paper-0", variant === "new" && onArt && "bg-spot", className)}>{label}</span>;
}

/** Badges stack 4 px apart. */
export function BadgeStack({ children, className }: { children: ReactNode; className?: string }) {
  return <div className={cn("flex flex-col items-start gap-1", className)}>{children}</div>;
}
