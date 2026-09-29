/** `11 H 20 M`, `45 M` under an hour, `—` for none. */
export function timeHere(rows: readonly { time_spent_seconds?: number | null }[]): string {
  const total = rows.reduce((sum, r) => sum + Math.max(0, r.time_spent_seconds ?? 0), 0);
  const minutes = Math.floor(total / 60);
  if (minutes <= 0) return "—";
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h > 0 ? `${h} H ${m} M` : `${m} M`;
}
