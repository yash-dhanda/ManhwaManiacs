/**
 * Motion-timings recorder core (cinematic §15.9), shared by both skins. The
 * overlay UI and `play()` come later (web/04, web/25); this is the counting.
 */
export type MotionEntry = {
  name: string;
  kind: "move" | "gesture" | "restart";
  plannedMs: number;
  startMs: number;
  endMs: number;
  startFrame: number;
  endFrame: number;
  frames: number;
  plannedFrames: number;
  dropped: number;
};

const RING = 200;
export const T0_KEY = "mm.skin.t0";
const RESTART_BUDGET_MS = 1500;

let ring: MotionEntry[] = [];
let recording = false;
const listeners = new Set<() => void>();

type Open = { name: string; kind: "move" | "gesture"; plannedMs: number; startMs: number; startFrame: number; dropped: number };
const open = new Set<Open>();
let frame = 0;
let last = 0;
let raf: number | null = null;
let deltas: number[] = [];
let interval = 1000 / 60;

const NOOP = { end() {} };

function emit(): void {
  for (const l of listeners) l();
}

function push(entry: MotionEntry): void {
  ring.push(entry);
  if (ring.length > RING) ring = ring.slice(-RING);
  if (recording) console.table([{ ...entry, line: formatEntry(entry) }]);
  emit();
}

function tick(now: number): void {
  raf = null;
  if (open.size === 0) return;
  frame += 1;
  if (last > 0) {
    const delta = now - last;
    if (delta < 100) {
      deltas.push(delta);
      if (deltas.length > 60) deltas.shift();
      const sorted = [...deltas].sort((a, b) => a - b);
      interval = sorted[Math.floor(sorted.length / 2)];
    }
    if (delta > 1.5 * interval) {
      const missed = Math.round(delta / interval) - 1;
      for (const o of open) o.dropped += missed;
    }
  }
  last = now;
  raf = requestAnimationFrame(tick);
}

function begin(name: string, kind: "move" | "gesture", plannedMs: number) {
  if (!recording) return NOOP;
  const o: Open = { name, kind, plannedMs, startMs: performance.now(), startFrame: frame, dropped: 0 };
  if (open.size === 0) {
    last = 0;
    deltas = [];
    interval = 1000 / 60;
  }
  open.add(o);
  if (raf === null) raf = requestAnimationFrame(tick);
  return {
    end() {
      if (!open.delete(o)) return;
      const endMs = performance.now();
      push({
        name: o.name,
        kind: o.kind,
        plannedMs: o.plannedMs,
        startMs: o.startMs,
        endMs,
        startFrame: o.startFrame,
        endFrame: frame,
        frames: frame - o.startFrame,
        plannedFrames: Math.round(o.plannedMs / interval),
        dropped: o.dropped,
      });
      if (open.size === 0 && raf !== null) {
        cancelAnimationFrame(raf);
        raf = null;
      }
    },
  };
}

export const startMove = (name: string, plannedMs: number) => begin(name, "move", plannedMs);
export const startGesture = (name: string) => begin(name, "gesture", 0);

export const entries = (): readonly MotionEntry[] => ring;
export function clearEntries(): void {
  ring = [];
  emit();
}
export function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}
export function setRecording(on: boolean): void {
  recording = on;
}
export const isRecording = () => recording;

export function isLate(e: MotionEntry): boolean {
  if (e.kind === "restart") return e.endMs - e.startMs > RESTART_BUDGET_MS;
  return e.endMs - e.startMs > e.plannedMs + interval || e.dropped > 0;
}

const n = (v: number) => Math.round(v).toLocaleString("en-US");

export function formatEntry(e: MotionEntry): string {
  if (e.kind === "restart") {
    return `${e.name.toUpperCase()}  confirm → first splash frame  ${n(e.endMs - e.startMs)} MS`;
  }
  const name = e.name.toUpperCase();
  return `${name.padEnd(Math.max(14, name.length + 1))}${n(e.plannedMs)} → ${n(e.endMs - e.startMs)} MS   ${e.frames}/${e.plannedFrames} F   ${e.dropped} DROP`;
}

export function markSkinRestartStart(): void {
  try {
    sessionStorage.setItem(T0_KEY, String(Date.now()));
  } catch {
    // Storage blocked: the restart just goes unmeasured.
  }
}

/** Log the restart's duration on the arriving skin's first frame. Null without a t0. */
export function logSkinRestart(skin: string): MotionEntry | null {
  let raw: string | null = null;
  try {
    raw = sessionStorage.getItem(T0_KEY);
    sessionStorage.removeItem(T0_KEY);
  } catch {
    return null;
  }
  const t0 = Number(raw);
  if (!raw || !Number.isFinite(t0)) return null;
  const ms = Math.max(0, Date.now() - t0);
  const now = performance.now();
  const entry: MotionEntry = {
    name: "SKIN RESTART",
    kind: "restart",
    plannedMs: 0,
    startMs: now - ms,
    endMs: now,
    startFrame: frame,
    endFrame: frame,
    frames: 0,
    plannedFrames: 0,
    dropped: 0,
  };
  push(entry); // recorded whether or not recording is on (§15.9)
  console.info(`${formatEntry(entry)}  (${skin})`);
  if (ms > RESTART_BUDGET_MS) console.warn(`SKIN RESTART ${ms} ms > ${RESTART_BUDGET_MS} ms`);
  return entry;
}
