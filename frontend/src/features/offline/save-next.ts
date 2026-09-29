import { readScopedString, writeScopedString } from "@/lib/scoped-storage";

/**
 * "Save the next chapter while I read" (cinematic §8.14.11): per profile,
 * default on. The Settings row arrives with each skin's downloads step; the
 * engine's auto-queue reads it here.
 */
export const SAVE_NEXT_KEY = "mm.downloads.save-next";

export function readSaveNext(): boolean {
  return readScopedString(SAVE_NEXT_KEY) !== "0";
}

export function writeSaveNext(on: boolean): void {
  writeScopedString(SAVE_NEXT_KEY, on ? "1" : "0");
}
