import { ApiError } from "@/types/api";

export const DB_BUSY_EVENT = "mm:db-busy";
const BUSY_RETRIES = 3;
const BUSY_DEFAULT_MS = 2000;

const isDbBusy = (e: unknown): e is ApiError => e instanceof ApiError && e.status === 503 && e.code === "db_busy";

/** React Query `retry`: `503 db_busy` retries three times, then tells the app (`mm:db-busy`); anything else keeps the old one retry. */
export function busyRetry(failureCount: number, error: unknown): boolean {
  if (!isDbBusy(error)) return failureCount < 1;
  if (failureCount < BUSY_RETRIES) return true;
  if (typeof window !== "undefined") window.dispatchEvent(new CustomEvent(DB_BUSY_EVENT));
  return false;
}

/** React Query `retryDelay`: the error's Retry-After when it has one, else 2000 ms (other errors keep the library default). */
export function busyRetryDelay(failureCount: number, error: unknown): number {
  if (isDbBusy(error)) return error.retryAfterMs ?? BUSY_DEFAULT_MS;
  return Math.min(1000 * 2 ** failureCount, 30_000);
}
