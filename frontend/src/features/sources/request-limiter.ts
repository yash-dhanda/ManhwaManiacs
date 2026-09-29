import { ApiError } from "@/types/api";

/**
 * The one request limiter for the sources bucket (cinematic §15.6): a sliding
 * window of request STARTS (not a refilling bucket, which would admit 99 in one
 * window), four priorities, and `Retry-After` pauses.
 *
 * P0 visible reader page + next, P1 user-initiated lists: never wait.
 * P2 covers in view: wait for one free slot. P3 prefetch: wait for 20 free
 * slots and fewer than 2 P3 in flight. P2 and P3 also wait out a pause.
 */
export type Priority = "P0" | "P1" | "P2" | "P3";

export interface Ticket {
  readonly id: number;
  readonly priority: Priority;
}

export interface RequestLimiter {
  /** Resolves when the request may start. */
  acquire(p: Priority, signal?: AbortSignal): Promise<Ticket>;
  run<T>(
    p: Priority,
    task: (signal?: AbortSignal) => Promise<T>,
    signal?: AbortSignal,
  ): Promise<T>;
  /** A response served from a local cache costs nothing. */
  refund(t: Ticket): void;
  /** Free the P3 in-flight count for a ticket taken with `acquire` directly. */
  release(t: Ticket): void;
  /** After a 429: P2 and P3 wait until now + ms. */
  pause(ms: number): void;
  /** capacity - starts in the last windowMs, floor 0. */
  free(): number;
}

export const HOVER_DWELL_MS = 150;
const DEFAULT_RETRY_MS = 12_000;

interface Waiter {
  priority: "P2" | "P3";
  signal?: AbortSignal;
  resolve: (t: Ticket) => void;
  reject: (e: unknown) => void;
  onAbort?: () => void;
}

function abortError(): Error {
  return new DOMException("Aborted", "AbortError");
}

export function createRequestLimiter(opts: {
  capacity?: number;
  windowMs?: number;
  p3MinFree?: number;
  p3MaxInFlight?: number;
  now?: () => number;
  setTimer?: (fn: () => void, ms: number) => unknown;
} = {}): RequestLimiter {
  const capacity = opts.capacity ?? 50;
  const windowMs = opts.windowMs ?? 60_000;
  const p3MinFree = opts.p3MinFree ?? 20;
  const p3MaxInFlight = opts.p3MaxInFlight ?? 2;
  const now = opts.now ?? (() => Date.now());
  const setTimer = opts.setTimer ?? ((fn, ms) => setTimeout(fn, ms));

  let nextId = 1;
  let log: { id: number; t: number }[] = []; // start times, ascending
  let pausedUntil = 0;
  let p3InFlight = 0;
  const p3Live = new Set<number>();
  const waiters: Waiter[] = [];
  let pendingAt: number | null = null;

  const prune = () => {
    const cutoff = now() - windowMs;
    while (log.length && log[0].t <= cutoff) log.shift();
  };
  const free = () => {
    prune();
    return Math.max(0, capacity - log.length);
  };
  const start = (priority: Priority): Ticket => {
    const id = nextId++;
    log.push({ id, t: now() });
    if (priority === "P3") {
      p3InFlight++;
      p3Live.add(id);
    }
    return { id, priority };
  };

  const pump = () => {
    // P2 before P3, first come first served within a priority.
    for (const pr of ["P2", "P3"] as const) {
      for (let i = 0; i < waiters.length; ) {
        const w = waiters[i];
        if (w.priority !== pr) {
          i++;
          continue;
        }
        const paused = now() < pausedUntil;
        const ok =
          !paused &&
          (pr === "P2"
            ? free() >= 1
            : free() >= p3MinFree && p3InFlight < p3MaxInFlight);
        if (!ok) break; // FIFO: the head of this priority blocks the rest of it
        waiters.splice(i, 1);
        w.signal?.removeEventListener("abort", w.onAbort!);
        w.resolve(start(pr));
      }
    }
    if (!waiters.length) return;
    // Wake at the next moment a slot frees or the pause ends.
    prune();
    const t = now();
    let wake = Infinity;
    if (t < pausedUntil) wake = pausedUntil;
    else if (log.length) wake = log[0].t + windowMs;
    if (wake === Infinity) return; // only P3 in-flight blocks: release() pumps
    if (pendingAt === null || wake < pendingAt) {
      pendingAt = wake;
      setTimer(() => {
        pendingAt = null;
        pump();
      }, Math.max(1, wake - t));
    }
  };

  const acquire = (p: Priority, signal?: AbortSignal): Promise<Ticket> => {
    if (signal?.aborted) return Promise.reject(abortError());
    if (p === "P0" || p === "P1") return Promise.resolve(start(p));
    return new Promise<Ticket>((resolve, reject) => {
      const w: Waiter = { priority: p, signal, resolve, reject };
      w.onAbort = () => {
        const i = waiters.indexOf(w);
        if (i >= 0) waiters.splice(i, 1);
        reject(abortError());
      };
      signal?.addEventListener("abort", w.onAbort, { once: true });
      waiters.push(w);
      pump();
    });
  };

  const release = (t: Ticket) => {
    if (p3Live.delete(t.id)) {
      p3InFlight--;
      pump();
    }
  };

  const pause = (ms: number) => {
    pausedUntil = Math.max(pausedUntil, now() + ms);
  };

  const run = async <T>(
    p: Priority,
    task: (signal?: AbortSignal) => Promise<T>,
    signal?: AbortSignal,
  ): Promise<T> => {
    for (let attempt = 0; ; attempt++) {
      const ticket = await acquire(p, signal);
      try {
        return await task(signal);
      } catch (e) {
        if (!(e instanceof ApiError) || e.status !== 429) throw e;
        const ms = e.retryAfterMs ?? DEFAULT_RETRY_MS;
        pause(ms);
        if (p !== "P0" || attempt > 0) throw e;
        await new Promise<void>((r) => setTimer(r, ms)); // P0 retries once
      } finally {
        release(ticket);
      }
    }
  };

  return {
    acquire,
    run,
    release,
    pause,
    free,
    refund(t) {
      log = log.filter((e) => e.id !== t.id);
      release(t);
      pump();
    },
  };
}

export const sourcesLimiter = createRequestLimiter();
