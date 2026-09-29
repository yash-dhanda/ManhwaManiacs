"use client";

export type Health = "ok" | "failing" | "dead" | "unknown";
const TEXT: Record<Health, string> = { ok: "working", failing: "having trouble", dead: "not working", unknown: "not checked yet" };
export const healthLabel = (h: Health, demoted?: boolean) => TEXT[h] + (demoted ? ", skipped by search" : "");

/** A 10 px health bead (a content twin): `success` ok, `warning` failing, `danger` dead, `g600` unknown; a 1 px `warning` ring when demoted. */
export function HealthBead({ health, demoted }: { health: Health; demoted?: boolean }) {
  return <span className="g-bead" data-health={health} data-demoted={demoted ? "" : undefined} role="img" aria-label={healthLabel(health, demoted)} />;
}
