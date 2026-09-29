import { createUiSoundEngine } from "@/features/audio/ui-sound-engine";
import type { SoundEvent } from "../contract.generated";
import { soundEvents, sounds, type SoundCue } from "./tokens.generated";

/** Per device (glass §6, §8.25.5): `mm.glass.sounds`, off by default, volume in dB (-24..0). */
export type SoundPrefs = { on: boolean; volumeDb: number };
export const SOUNDS_KEY = "mm.glass.sounds";
const DEFAULT: SoundPrefs = { on: false, volumeDb: -6 };

export function readSoundPrefs(): SoundPrefs {
  try {
    const raw = localStorage.getItem(SOUNDS_KEY);
    if (raw === null) return { ...DEFAULT };
    const p = JSON.parse(raw) as Partial<SoundPrefs>;
    const db = typeof p.volumeDb === "number" ? Math.min(0, Math.max(-24, p.volumeDb)) : DEFAULT.volumeDb;
    return { on: p.on === true, volumeDb: db };
  } catch {
    return { ...DEFAULT };
  }
}

const engine = createUiSoundEngine({
  dir: "/sounds/glass",
  stems: Object.values(sounds),
  isOn: () => readSoundPrefs().on,
  gain: () => 10 ** (readSoundPrefs().volumeDb / 20),
});

/** Call from a click handler when turning sounds on so the context primes inside the gesture. */
export function writeSoundPrefs(patch: Partial<SoundPrefs>): void {
  const next = { ...readSoundPrefs(), ...patch };
  try {
    localStorage.setItem(SOUNDS_KEY, JSON.stringify(next));
  } catch {
    // ignore
  }
  engine.refreshGain();
  if (next.on && patch.on === true) engine.prime();
}

export const armSounds = engine.arm;

/** The throw whoosh's centre frequency over its 1200 Hz base. */
export const throwRate = (v: number): number => (1200 + Math.min(Math.abs(v), 3000) * 0.6) / 1200;
/** Scrub ticks rise up to +3 semitones. */
export const semitoneRate = (n: number): number => 2 ** (n / 12);

/** The stem an event plays; `nav.push` picks by depth (default 1). */
export function cueFor(event: SoundEvent, depth: 1 | 2 | 3 | 4 = 1): SoundCue | null {
  const cue = (soundEvents as Record<SoundEvent, SoundCue | readonly SoundCue[] | null>)[event];
  if (Array.isArray(cue)) return (cue as readonly SoundCue[])[depth - 1] ?? null;
  return (cue as SoundCue | null) ?? null;
}

export function playSound(event: SoundEvent, opts?: { rate?: number; depth?: 1 | 2 | 3 | 4 }): void {
  const cue = cueFor(event, opts?.depth);
  if (!cue) return;
  engine.play(sounds[cue], opts?.rate);
}
