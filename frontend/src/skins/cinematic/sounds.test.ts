import { existsSync } from "node:fs";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { setAudioActivity } from "@/features/audio/activity";
import { setStorageScope } from "@/lib/scoped-storage";
import { playSound, readSoundPrefs, writeSoundPrefs } from "./sounds";
import { SOUND_EVENTS } from "../contract.generated";
import { soundEvents, sounds } from "./tokens.generated";

const DIR = new URL("../../../public/sounds/cinematic/", import.meta.url);
const store: Record<string, string> = {};
const started = vi.fn();
const rates: number[] = [];

beforeEach(() => {
  setStorageScope({ userId: 1, profileId: 1 });
  for (const k of Object.keys(store)) delete store[k];
  started.mockClear();
  rates.length = 0;
  const localStorage = {
    getItem: (k: string) => store[k] ?? null,
    setItem: (k: string, v: string) => void (store[k] = v),
  };
  vi.stubGlobal("window", { addEventListener() {}, removeEventListener() {}, localStorage });
  vi.stubGlobal("localStorage", localStorage);
  vi.stubGlobal("navigator", {});
  vi.stubGlobal("Audio", class { canPlayType() { return "maybe"; } });
  vi.stubGlobal("fetch", async () => ({ ok: true, arrayBuffer: async () => new ArrayBuffer(1) }));
  vi.stubGlobal(
    "AudioContext",
    class {
      destination = {};
      createGain() { return { gain: { value: 1 }, connect() {} }; }
      resume() {}
      decodeAudioData() { return Promise.resolve({}); }
      createBufferSource() {
        const playbackRate = { value: 1 };
        return { buffer: null, playbackRate, connect() {}, start: () => { started(); rates.push(playbackRate.value); } };
      }
    },
  );
});

describe("cinematic sounds", () => {
  it("resolves every mapped event to a cue with both .ogg and .m4a", () => {
    for (const event of SOUND_EVENTS) {
      const mapped = (soundEvents as Record<string, unknown>)[event];
      const cues = mapped === null ? [] : Array.isArray(mapped) ? mapped : [mapped];
      for (const cue of cues) {
        const stem = (sounds as Record<string, string>)[cue as string];
        expect(stem, event).toBeTruthy();
        expect(existsSync(new URL(stem + ".ogg", DIR)), stem + ".ogg").toBe(true);
        expect(existsSync(new URL(stem + ".m4a", DIR)), stem + ".m4a").toBe(true);
      }
    }
  });

  it("defaults to off", () => {
    expect(readSoundPrefs().on).toBe(false);
  });

  it("is silent while off, plays when on, and stays silent while narration plays", async () => {
    playSound("tap.primary");
    expect(started).not.toHaveBeenCalled();
    writeSoundPrefs({ on: true });
    await new Promise((r) => setTimeout(r, 0));
    playSound("tap.primary");
    expect(started).toHaveBeenCalledTimes(1);
    setAudioActivity("narration", true);
    playSound("tap.primary");
    expect(started).toHaveBeenCalledTimes(1);
    setAudioActivity("narration", false);
    writeSoundPrefs({ on: false });
    playSound("tap.primary");
    expect(started).toHaveBeenCalledTimes(1);
  });
});

describe("cinematic prefs", () => {
  it("defaults to 60 percent and is per profile", () => {
    expect(readSoundPrefs()).toEqual({ on: false, volume: 60 });
    writeSoundPrefs({ volume: 30 });
    expect(readSoundPrefs().volume).toBe(30);
    setStorageScope({ userId: 1, profileId: 2 });
    expect(readSoundPrefs().volume).toBe(60);
  });
});
