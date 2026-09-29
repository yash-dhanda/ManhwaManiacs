// TODO(web/02): replace this local stand-in with the shared motion-timings recorder core from web/02 (not integrated in this lane).
export interface MoveRecord {
  id: number;
  name: string;
  label: string;
  plannedMs: number;
  start: number;
  end: number | null;
  frames: number;
  dropped: number;
}

const MAX = 200;
let records: MoveRecord[] = [];
let seq = 0;
const listeners = new Set<() => void>();
const emit = () => { records = [...records]; listeners.forEach((l) => l()); };

export const subscribeRecords = (l: () => void) => (listeners.add(l), () => void listeners.delete(l));
export const getRecords = () => records;
export const clearRecords = () => { records = []; emit(); };

export function beginRecord(name: string, label: string, plannedMs: number): MoveRecord {
  const r: MoveRecord = { id: ++seq, name, label, plannedMs, start: performance.now(), end: null, frames: 0, dropped: 0 };
  records = [...records, r].slice(-MAX);
  emit();
  return r;
}

let frameInterval = 1000 / 60;
const recent: number[] = [];

/** The display's frame interval: the median of the last 30 rAF deltas (robust to a stray short or long one), 6.9 to 33.4 ms. */
function noteDelta(d: number) {
  recent.push(d);
  if (recent.length > 30) recent.shift();
  if (recent.length >= 8) frameInterval = Math.min(33.4, Math.max(6.9, [...recent].sort((a, b) => a - b)[recent.length >> 1]));
}

/** Counts rendered frames and dropped frames (rAF deltas over 1.5 x the display's frame interval) until `finish()`. */
export function trackFrames(r: MoveRecord) {
  let last = performance.now();
  let raf = 0;
  let done = false;
  const tick = (now: number) => {
    if (done) return;
    const d = now - last;
    last = now;
    r.frames++;
    if (d > frameInterval * 1.5) r.dropped++;
    if (d > 0) noteDelta(d);
    raf = requestAnimationFrame(tick);
  };
  raf = requestAnimationFrame(tick);
  return () => {
    if (done) return;
    done = true;
    cancelAnimationFrame(raf);
    r.end = performance.now();
    emit();
  };
}
