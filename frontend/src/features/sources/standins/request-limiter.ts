// TODO(web/03): stand-in for features/sources/request-limiter.ts. Same surface
// (`sourcesLimiter.run/acquire`, P0..P3); replace with the real one when web/03 lands.
export type Priority = "P0" | "P1" | "P2" | "P3";

const ORDER: Priority[] = ["P0", "P1", "P2", "P3"];

export interface LimiterOptions {
  capacity?: number;
  refillPerSecond?: number;
  now?: () => number;
  /** P3 runs only while at least this many tokens remain. */
  p3Floor?: number;
  p3MaxInFlight?: number;
}

export function createLimiter(options: LimiterOptions = {}) {
  const capacity = options.capacity ?? 40;
  const refill = options.refillPerSecond ?? 8;
  const now = options.now ?? (() => Date.now());
  const p3Floor = options.p3Floor ?? 20;
  const p3Max = options.p3MaxInFlight ?? 2;
  let tokens = capacity;
  let last = now();
  let pausedUntil = 0;
  let p3InFlight = 0;
  const queues: Record<Priority, Array<() => boolean>> = { P0: [], P1: [], P2: [], P3: [] };
  let timer: ReturnType<typeof setTimeout> | null = null;

  const top = () => {
    const t = now();
    tokens = Math.min(capacity, tokens + ((t - last) / 1000) * refill);
    last = t;
  };

  const canStart = (p: Priority) => {
    if (tokens < 1) return false;
    if ((p === "P2" || p === "P3") && now() < pausedUntil) return false;
    if (p === "P3" && (tokens < p3Floor || p3InFlight >= p3Max)) return false;
    return true;
  };

  const pump = () => {
    top();
    for (const p of ORDER) {
      const q = queues[p];
      while (q.length > 0 && canStart(p)) {
        const start = q.shift()!;
        if (start()) tokens -= 1;
      }
    }
    const waiting = ORDER.some((p) => queues[p].length > 0);
    if (waiting && timer === null) {
      timer = setTimeout(() => {
        timer = null;
        pump();
      }, 125);
    }
  };

  function acquire(priority: Priority, signal?: AbortSignal): Promise<() => void> {
    return new Promise((resolve, reject) => {
      if (signal?.aborted) return reject(new DOMException("aborted", "AbortError"));
      let done = false;
      const start = () => {
        if (done) return false;
        done = true;
        if (priority === "P3") p3InFlight += 1;
        resolve(() => {
          if (priority === "P3") {
            p3InFlight -= 1;
            pump();
          }
        });
        return true;
      };
      signal?.addEventListener("abort", () => {
        if (done) return;
        done = true;
        reject(new DOMException("aborted", "AbortError"));
      });
      queues[priority].push(start);
      pump();
    });
  }

  async function run<T>(priority: Priority, task: () => Promise<T>, signal?: AbortSignal): Promise<T> {
    const release = await acquire(priority, signal);
    try {
      return await task();
    } catch (error) {
      const status = (error as { status?: number } | null)?.status;
      if (status === 429) {
        const retry = Number((error as { retryAfter?: number }).retryAfter ?? 5);
        pausedUntil = now() + retry * 1000;
      }
      throw error;
    } finally {
      release();
    }
  }

  return { run, acquire, tokens: () => (top(), tokens) };
}

export const sourcesLimiter = createLimiter();
