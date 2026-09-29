import { describe, expect, it } from "vitest";
import { resolveBootSkin } from "./boot";

type In = Parameters<typeof resolveBootSkin>[0];
const base: In = { rendered: "legacy", debug: null, profileSkin: null, glassAvailable: false, defaultSkin: "legacy" };

describe("resolveBootSkin", () => {
  const cases: [string, Partial<In>, string | null][] = [
    ["debug differs: restart into it", { debug: "cinematic", profileSkin: "glass" }, "cinematic"],
    ["debug equals rendered", { debug: "legacy", rendered: "legacy" }, null],
    ["debug wins over profile", { debug: "cinematic", rendered: "cinematic", profileSkin: "glass" }, null],
    ["no profile payload keeps the mirror", { profileSkin: undefined, rendered: "cinematic" }, null],
    ["null profile uses the default", { rendered: "cinematic", profileSkin: null }, "legacy"],
    ["null profile, already default", { rendered: "legacy", profileSkin: null }, null],
    ["saved cinematic, rendered legacy", { profileSkin: "cinematic" }, "cinematic"],
    ["saved cinematic, rendered cinematic", { rendered: "cinematic", profileSkin: "cinematic" }, null],
    ["glass unavailable coerces to cinematic", { rendered: "cinematic", profileSkin: "glass" }, null],
    ["glass unavailable, rendered legacy", { rendered: "legacy", profileSkin: "glass" }, "cinematic"],
    ["glass available", { rendered: "cinematic", profileSkin: "glass", glassAvailable: true }, "glass"],
  ];
  it.each(cases)("%s", (_n, over, want) => {
    expect(resolveBootSkin({ ...base, ...over }).restartTo).toBe(want);
  });
});
