import { existsSync } from "node:fs";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { setAudioActivity } from "@/features/audio/activity";
import { cueFor, playSound, readSoundPrefs, semitoneRate, throwRate, writeSoundPrefs } from "./sounds";
import { SOUND_EVENTS } from "../contract.generated";
import { soundEvents, sounds } from "./tokens.generated";

const DIR = new URL("../../../public/sounds/glass/", import.meta.url);
const store: Record<string, string> = {};
const started = vi.fn();
const rates: number[] = [];

beforeEach(() => {
  
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

describe("glass sounds", () => {
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

describe("glass mapping and prefs", () => {
  it("defaults to -6 dB, device-wide", () => {
    expect(readSoundPrefs()).toEqual({ on: false, volumeDb: -6 });
  });

  it("maps nav.push by depth and nav.pop to back", () => {
    expect(cueFor("nav.push", 1)).toBe("push-1");
    expect(cueFor("nav.push", 4)).toBe("push-4");
    expect(cueFor("nav.pop")).toBe("back");
  });

  it("rate helpers", () => {
    expect(throwRate(0)).toBe(1);
    expect(throwRate(99999)).toBe((1200 + 1800) / 1200);
    expect(semitoneRate(12)).toBe(2);
  });

  it("passes rate through as playbackRate", async () => {
    writeSoundPrefs({ on: true });
    await new Promise((r) => setTimeout(r, 0));
    playSound("select", { rate: 1.5 });
    expect(rates).toEqual([1.5]);
  });
});
