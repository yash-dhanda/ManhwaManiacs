import { beforeEach, describe, expect, it, vi } from "vitest";
import type { StripFetchResult, StripSource } from "./strip-source";
import type { StripChapter } from "./strip";
import { useChapterStrip, type ChapterStripInput } from "./use-chapter-strip";

/**
 * A just-enough hook runner. The test environment is node with no DOM and no
 * renderer package, so `react` is replaced by a tiny emulation of the four
 * hooks the strip uses — the strip's own code is what runs, unmodified.
 */
interface EffectSlot {
  deps: readonly unknown[] | undefined;
  cleanup: void | (() => void);
}
const runtime = vi.hoisted(() => ({
  slots: [] as unknown[],
  index: 0,
  rendering: false,
  dirty: false,
  pending: [] as Array<() => void>,
}));

vi.mock("react", () => {
  const sameDeps = (a: readonly unknown[] | undefined, b: readonly unknown[] | undefined) =>
    !!a && !!b && a.length === b.length && a.every((value, i) => Object.is(value, b[i]));
  return {
    useState<T>(initial: T) {
      const at = runtime.index++;
      if (!(at in runtime.slots)) runtime.slots[at] = initial;
      const set = (update: T | ((previous: T) => T)) => {
        const previous = runtime.slots[at] as T;
        const next = typeof update === "function" ? (update as (p: T) => T)(previous) : update;
        if (Object.is(next, previous)) return;
        runtime.slots[at] = next;
        runtime.dirty = true;
      };
      return [runtime.slots[at] as T, set] as const;
    },
    useRef<T>(initial: T) {
      const at = runtime.index++;
      if (!(at in runtime.slots)) runtime.slots[at] = { current: initial };
      return runtime.slots[at] as { current: T };
    },
    useCallback<T>(fn: T) {
      runtime.index++;
      return fn;
    },
    useEffect(effect: () => void | (() => void), deps?: readonly unknown[]) {
      const at = runtime.index++;
      const previous = runtime.slots[at] as EffectSlot | undefined;
      if (previous && sameDeps(previous.deps, deps)) return;
      runtime.pending.push(() => {
        if (previous && typeof previous.cleanup === "function") previous.cleanup();
        runtime.slots[at] = { deps, cleanup: effect() } satisfies EffectSlot;
      });
      runtime.slots[at] = previous ?? { deps: undefined, cleanup: undefined };
    },
  };
});

// Not named like a hook: this runner is the "component" the hook renders in.
const renderStrip = useChapterStrip;

function mount(initial: ChapterStripInput) {
  runtime.slots = [];
  runtime.pending = [];
  let input = initial;
  let result!: ReturnType<typeof useChapterStrip>;
  const settle = async () => {
    for (let pass = 0; pass < 20; pass += 1) {
      await Promise.resolve();
      do {
        runtime.dirty = false;
        runtime.index = 0;
        result = renderStrip(input);
        const effects = runtime.pending.splice(0);
        for (const run of effects) run();
      } while (runtime.dirty || runtime.pending.length > 0);
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
  };
  return {
    get current() {
      return result;
    },
    async rerender(next: Partial<ChapterStripInput>) {
      input = { ...input, ...next };
      await settle();
    },
    settle,
  };
}

function chapter(key: string, next: string | null): StripChapter {
  return {
    sourceId: "s",
    seriesKey: "series",
    chapterKey: key,
    chapterNumber: null,
    title: `Chapter ${key}`,
    pageCount: 0,
    pages: [],
    previousChapterKey: null,
    nextChapterKey: next,
  };
}

const CHAIN: Record<string, StripChapter> = {
  A: chapter("A", "B"),
  B: chapter("B", "C"),
  C: chapter("C", null),
};

function controllableSource() {
  const waiting: Array<{ keys: string[]; resolve: (r: StripFetchResult) => void }> = [];
  const fetch = vi.fn((keys: readonly string[]) => {
    return new Promise<StripFetchResult>((resolve) => {
      waiting.push({ keys: [...keys], resolve });
    });
  });
  const source: StripSource = {
    entryKeys: () => ["A", "B"],
    keysAfter: (loaded) => {
      const next = loaded[loaded.length - 1]?.nextChapterKey;
      return next ? [next] : [];
    },
    keyBefore: () => null,
    keysBefore: () => [],
    edgeLabel: () => null,
    fetch,
  };
  return { source, fetch, waiting };
}

describe("useChapterStrip extension", () => {
  beforeEach(() => {
    runtime.slots = [];
  });

  it("keeps the in-flight next chapter when the active chapter flips away and back", async () => {
    const { source, fetch, waiting } = controllableSource();
    const strip = mount({
      entryChapterKey: "A",
      activeChapterKey: "A",
      source,
      window: { behind: 1, ahead: 1 },
    });
    await strip.settle();
    waiting[0].resolve({ chapters: [CHAIN.A, CHAIN.B], error: null });
    await strip.settle();
    expect(strip.current.chapters.map((c) => c.chapterKey)).toEqual(["A", "B"]);

    await strip.rerender({ activeChapterKey: "B" });
    expect(fetch).toHaveBeenCalledTimes(2);
    expect(waiting[1].keys).toEqual(["C"]);

    await strip.rerender({ activeChapterKey: "A" });
    await strip.rerender({ activeChapterKey: "B" });
    waiting[1].resolve({ chapters: [CHAIN.C], error: null });
    await strip.settle();

    expect(strip.current.chapters.map((c) => c.chapterKey)).toEqual(["A", "B", "C"]);
    expect(fetch).toHaveBeenCalledTimes(2);
  });

  it("still drops a result that belongs to a replaced strip", async () => {
    const { source, waiting } = controllableSource();
    const strip = mount({
      entryChapterKey: "A",
      activeChapterKey: "A",
      source,
      window: { behind: 1, ahead: 1 },
    });
    await strip.settle();
    waiting[0].resolve({ chapters: [CHAIN.A, CHAIN.B], error: null });
    await strip.settle();
    await strip.rerender({ activeChapterKey: "B" });
    expect(waiting[1].keys).toEqual(["C"]);

    await strip.rerender({ entryChapterKey: "Z", activeChapterKey: "Z" });
    waiting[1].resolve({ chapters: [CHAIN.C], error: null });
    await strip.settle();

    expect(strip.current.chapters.map((c) => c.chapterKey)).not.toContain("C");
  });
});
