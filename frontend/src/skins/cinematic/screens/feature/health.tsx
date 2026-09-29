import type { SourceSummary } from "@/features/sources/types";
import s from "./feature.module.css";

export type Health = "live" | "slow" | "dead";

export function healthOf(source: SourceSummary | undefined): Health {
  const status = source?.health?.status;
  if (status === "dead") return "dead";
  if (status && status !== "ok" && status !== "healthy") return "slow";
  return "live";
}

const LABEL: Record<Health, string> = { live: "LIVE", slow: "SLOW", dead: "DOWN" };

/** §2.1.3: 6 x 6 square + label. */
export function HealthMark({ health }: { health: Health }) {
  const cls = health === "dead" ? s.healthDead : health === "slow" ? s.healthSlow : "";
  return (
    <>
      <span className={`${s.health} ${cls}`} aria-hidden="true" />
      <span>{LABEL[health]}</span>
    </>
  );
}
