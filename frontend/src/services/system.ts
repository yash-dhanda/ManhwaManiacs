import { http } from "./http";

/** Health/status payload returned by the backend root route. */
export interface SystemStatus {
  status: string;
  name: string;
  version: string;
}

export const systemService = {
  getStatus: (signal?: AbortSignal) => http.get<SystemStatus>("/", { signal }),
};

/** `GET /system/source-health`: counts per health state, already gated per profile. */
export interface SourceHealthSummary {
  total: number;
  ok: number;
  failing: number;
  dead: number;
  unknown: number;
  demoted: number;
}

export const sourceHealthService = {
  summary: () => http.get<SourceHealthSummary>("/system/source-health"),
};
