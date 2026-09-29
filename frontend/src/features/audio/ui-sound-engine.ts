import { isOtherAudioActive } from "./activity";

/**
 * Web Audio playback for a skin's UI cues, shared by both skins. Nothing is
 * fetched until sounds are on and a user gesture has primed the context.
 */
export type UiSoundEngine = ReturnType<typeof createUiSoundEngine>;

export function createUiSoundEngine(o: {
  dir: string; // e.g. "/sounds/cinematic"
  stems: readonly string[];
  isOn: () => boolean;
  gain: () => number;
}) {
  let ctx: AudioContext | null = null;
  let master: GainNode | null = null;
  const buffers = new Map<string, AudioBuffer>();
  let armed = false;

  const ext = () => {
    try {
      return new Audio().canPlayType('audio/ogg; codecs="opus"') !== "" ? "ogg" : "m4a";
    } catch {
      return "m4a";
    }
  };

  async function load(stem: string): Promise<void> {
    try {
      const res = await fetch(`${o.dir}/${stem}.${ext()}`);
      if (!res.ok || !ctx) return;
      buffers.set(stem, await ctx.decodeAudioData(await res.arrayBuffer()));
    } catch {
      // A cue that will not decode is a silent cue.
    }
  }

  /** Create the context and load every cue. Call inside a gesture. */
  function prime(): void {
    if (ctx || !o.isOn() || typeof AudioContext === "undefined") return;
    ctx = new AudioContext();
    master = ctx.createGain();
    master.gain.value = o.gain();
    master.connect(ctx.destination);
    // iOS Safari: "ambient" lets the silent switch mute cues (State A).
    const session = (navigator as Navigator & { audioSession?: { type: string } }).audioSession;
    if (session) session.type = "ambient";
    void ctx.resume?.();
    for (const stem of o.stems) void load(stem);
  }

  /** After sounds are on, the first pointerdown or keydown primes. */
  function arm(): void {
    if (armed || ctx || !o.isOn() || typeof window === "undefined") return;
    armed = true;
    const go = () => {
      window.removeEventListener("pointerdown", go, true);
      window.removeEventListener("keydown", go, true);
      armed = false;
      prime();
    };
    window.addEventListener("pointerdown", go, true);
    window.addEventListener("keydown", go, true);
  }

  function refreshGain(): void {
    if (master) master.gain.value = o.gain();
  }

  function play(stem: string, rate = 1): void {
    if (!o.isOn() || isOtherAudioActive() || !ctx || !master) {
      if (o.isOn()) arm();
      return;
    }
    const buffer = buffers.get(stem);
    if (!buffer) return;
    const src = ctx.createBufferSource();
    src.buffer = buffer;
    src.playbackRate.value = rate;
    src.connect(master);
    src.start();
  }

  return { prime, arm, refreshGain, play };
}
