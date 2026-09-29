import { cache } from "react";
import { notFound } from "next/navigation";

/**
 * Per request: does the route's screen exist? Settled by `renderScreen` (or by
 * `markScreenMissing` in the `[...missing]` catch-all, or by a self-settling screen), read by the layout's
 * `NotFoundStatus`. Every page under `app/(app)` must settle it, or the
 * document render waits forever (completeness.test.ts checks that they do).
 *
 * Why: a `notFound()` thrown by the page only sets the 404 status when the
 * server HTML render reaches it, and legacy's AppShell renders no children on
 * the server (its auth gate), so the status stayed 200. The probe sits outside
 * the Shell, where the server render always reaches.
 */
export const screenMissing = cache(() => Promise.withResolvers<boolean>());

export function markScreenMissing(): never {
  screenMissing().resolve(true);
  notFound();
}

export function markScreenFound(): void {
  screenMissing().resolve(false);
}

const selfSettling = new WeakSet<object>();

/**
 * For a screen that can still 404 once it runs (legacy's settings wrapper):
 * `renderScreen` then leaves settling to the screen, which must call
 * `markScreenFound` or `markScreenMissing` itself.
 */
export function settlesItself<T extends object>(screen: T): T {
  selfSettling.add(screen);
  return screen;
}

export function isSelfSettling(screen: object): boolean {
  return selfSettling.has(screen);
}
