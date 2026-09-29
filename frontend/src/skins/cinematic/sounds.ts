import { readScopedString, writeScopedString } from "@/lib/scoped-storage";
import { createUiSoundEngine } from "@/features/audio/ui-sound-engine";
import type { SoundEvent } from "../contract.generated";
import { soundEvents, sounds, type SoundCue } from "./tokens.generated";

/** Per profile (cinematic §6): `mm.sounds`, off by default, volume in percent. */
export type SoundPrefs = { on: boolean; volume: number };
export const SOUNDS_BASE = "mm.sounds";
const DEFAULT: SoundPrefs = { on: false, volume: 60 };

export function readSoundPrefs(): SoundPrefs {
  try {
    const raw = readScopedString(SOUNDS_BASE);
    if (raw === null) return { ...DEFAULT };
    const p = JSON.parse(raw) as Partial<SoundPrefs>;
    const v = typeof p.volume === "number" ? Math.min(100, Math.max(0, p.volume)) : DEFAULT.volume;
    return { on: p.on === true, volume: v };
  } catch {
    return { ...DEFAULT };
  }
}

const engine = createUiSoundEngine({
  dir: "/sounds/cinematic",
  stems: Object.values(sounds),
  isOn: () => readSoundPrefs().on,
  gain: () => readSoundPrefs().volume / 100,
});

/** Call from a click handler when turning sounds on so the context primes inside the gesture. */
export function writeSoundPrefs(patch: Partial<SoundPrefs>): void {
  const next = { ...readSoundPrefs(), ...patch };
  writeScopedString(SOUNDS_BASE, JSON.stringify(next));
  engine.refreshGain();
  if (next.on && patch.on === true) engine.prime();
}

/** Listen for the first gesture once sounds are on. */
export const armSounds = engine.arm;

export function playSound(event: SoundEvent): void {
  const cue = (soundEvents as Record<SoundEvent, SoundCue | null>)[event];
  if (!cue) return;
  engine.play(sounds[cue]);
}
