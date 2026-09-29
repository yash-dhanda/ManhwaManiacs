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
    if (d > 0 && d < frameInterval - 0.5 && d > 4) frameInterval = d;
    if (d > frameInterval * 1.5) r.dropped++;
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
