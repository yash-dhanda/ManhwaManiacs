/**
 * Cinematic §15.6 priority P3 (speculative work): at most two tasks in flight,
 * the rest queued behind them. A press is P1 and never goes through here.
 * ponytail: the "at least 20 of 50 slots free" gate is the server's count,
 * which the client cannot see; the in-flight cap is what this side can hold.
 */
const MAX_IN_FLIGHT = 2;
let inFlight = 0;
const queue: Array<() => void> = [];

function pump() {
  while (inFlight < MAX_IN_FLIGHT && queue.length) queue.shift()!();
}

export function runP3<T>(task: () => Promise<T>): Promise<T | undefined> {
  return new Promise((resolve) => {
    queue.push(() => {
      inFlight += 1;
      task()
        .then(resolve, () => resolve(undefined))
        .finally(() => {
          inFlight -= 1;
          pump();
        });
    });
    pump();
  });
}

export function p3State() {
  return { inFlight, queued: queue.length };
}
