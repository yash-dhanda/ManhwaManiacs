import { describe, expect, it } from "vitest";
import { AUTO_QUEUE_MIN_FREE_BYTES, shouldAutoQueueNext, type AutoQueueInput } from "./auto-queue";

const ok: AutoQueueInput = {
  medium: "manga",
  hasProfileScope: true,
  serviceWorkerSupported: true,
  capabilityOn: true,
  hasNextChapter: true,
  nextSaved: false,
  alreadyQueued: false,
  switchOn: true,
  freeBytes: AUTO_QUEUE_MIN_FREE_BYTES,
};

describe("shouldAutoQueueNext", () => {
  it("queues when every condition holds, with exactly the floor free", () => {
    expect(shouldAutoQueueNext(ok)).toBe(true);
  });
  it("treats unknown storage as enough", () => {
    expect(shouldAutoQueueNext({ ...ok, freeBytes: null })).toBe(true);
  });

  const falseCases: [string, Partial<AutoQueueInput>][] = [
    ["a novel", { medium: "novel" }],
    ["no profile scope", { hasProfileScope: false }],
    ["no service worker", { serviceWorkerSupported: false }],
    ["client_downloads off", { capabilityOn: false }],
    ["no next chapter", { hasNextChapter: false }],
    ["next already saved", { nextSaved: true }],
    ["already queued this open", { alreadyQueued: true }],
    ["switch off", { switchOn: false }],
    ["one byte under the floor", { freeBytes: AUTO_QUEUE_MIN_FREE_BYTES - 1 }],
    ["no free storage", { freeBytes: 0 }],
  ];
  it.each(falseCases)("does not queue: %s", (_name, patch) => {
    expect(shouldAutoQueueNext({ ...ok, ...patch })).toBe(false);
  });
});
