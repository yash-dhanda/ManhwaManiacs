import { ApiError } from "@/types/api";

export type NotAvailableKind = "series" | "source" | "not-browsable";

/** §8.0.10: which "no longer available" wording an error earns. Gated 18+ content answers the same codes, so the wording never reveals it. */
export function notAvailableKind(error: unknown): NotAvailableKind | null {
  if (!(error instanceof ApiError)) return null;
  if (error.code === "series_not_found") return "series";
  if (error.code === "source_not_found") return "source";
  if (error.code === "source_not_browsable") return "not-browsable";
  return null;
}
