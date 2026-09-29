"use client";
import { useEffect, useState, useSyncExternalStore } from "react";

const subscribe = (q: string) => (cb: () => void) => { const m = window.matchMedia(q); m.addEventListener("change", cb); return () => m.removeEventListener("change", cb); };
function useMedia(q: string, server = false): boolean {
  return useSyncExternalStore(subscribe(q), () => window.matchMedia(q).matches, () => server);
}
/** The desktop frame (768 px and up): sheets become column panels, menus 40 px items. */
export const useDesktopFrame = () => useMedia("(min-width: 768px)");
/** Touch-first pointer: drag, swipe and long-press paths are live only here. */
export const useCoarsePointer = () => useMedia("(pointer: coarse)");

/** Polite live-region text that re-announces even when the same string repeats. */
export function useAnnouncer(): [string, (msg: string) => void] {
  const [msg, setMsg] = useState("");
  const [flip, setFlip] = useState(false);
  return [msg + (flip ? "​" : ""), (m: string) => { setMsg(m); setFlip((f) => !f); }];
}

/** True once mounted (portals and window reads). */
export function useMounted(): boolean {
  const [m, setM] = useState(false);
  useEffect(() => setM(true), []); // eslint-disable-line react-hooks/set-state-in-effect -- mount flag
  return m;
}
