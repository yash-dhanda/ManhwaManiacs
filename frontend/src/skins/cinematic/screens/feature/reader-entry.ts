"use client";

import { useCallback } from "react";
import { enterReader } from "../../shell/reader-entry";

/** Opening a chapter from a feature or book page is the Column wipe (§8.0.4); the shell owns it. */
export function useReaderEntry() {
  return useCallback((href: string) => { void enterReader(href, { entry: "wipe" }); }, []);
}
