import { formatRelativeAge } from "./browse-freshness";
import type { SourceHealth } from "./types";
import { parseUtcTimestamp } from "@/lib/utc-time";

export type HealthState = "ok" | "failing" | "dead" | "unknown" | "demoted";

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export function describeHealth(health: SourceHealth | null | undefined, now: number): { state: HealthState; label: string } {
  if (!health) return { state: "unknown", label: "UNKNOWN" };
  if (health.demoted) return { state: "demoted", label: "DEMOTED" };
  const status = health.status.toLowerCase();
  if (status === "dead") {
    const since = parseUtcTimestamp(health.last_ok_at ?? health.last_error_at);
    if (since === null) return { state: "dead", label: "DEAD" };
    const d = new Date(since);
    return { state: "dead", label: `DEAD since ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}` };
  }
  if (status === "failing" || health.consecutive_failures > 0) {
    const n = health.consecutive_failures;
    return { state: "failing", label: `FAILING · ${n} ${n === 1 ? "error" : "errors"}` };
  }
  const checked = parseUtcTimestamp(health.last_checked_at);
  if (status === "ok" && checked !== null) {
    return { state: "ok", label: `OK · last checked ${formatRelativeAge(now - checked)}` };
  }
  return { state: "unknown", label: "UNKNOWN" };
}

const RANK: Record<HealthState, number> = { dead: 0, failing: 1, demoted: 2, unknown: 3, ok: 4 };

export function sortWorstFirst<T extends { name: string; health?: SourceHealth | null }>(rows: readonly T[], now = Date.now()): T[] {
  return [...rows].sort(
    (a, b) =>
      RANK[describeHealth(a.health, now).state] - RANK[describeHealth(b.health, now).state] ||
      a.name.localeCompare(b.name),
  );
}
