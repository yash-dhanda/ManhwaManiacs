"use client";
import { create } from "zustand";
import type { NavItemId } from "./nav-map";

/** Shell-wide client state (§7.15 held item, Iris hand-over, layers). The shell survives client navigation; this is why. */
type ShellState = {
  held: NavItemId | null;
  setHeld: (id: NavItemId | null) => void;
  /** Where the Iris closed; the next route's content opens from here. */
  irisOut: { x: number; y: number } | null;
  requestIrisOut: (p: { x: number; y: number } | null) => void;
  sidebarOverlay: boolean;
  setSidebarOverlay: (open: boolean) => void;
  paletteOpen: boolean;
  setPaletteOpen: (open: boolean) => void;
  /** Where focus was when the palette opened; it returns there on close. */
  paletteReturn: HTMLElement | null;
  keyboardOpen: boolean;
  setKeyboardOpen: (open: boolean) => void;
  /** True once the splash hand-off began (or there is no splash): screens start their typed headline. */
  handoff: boolean;
  setHandoff: (v: boolean) => void;
  signOutOpen: boolean;
  setSignOutOpen: (open: boolean) => void;
  /** The session probe never reached the server (Gate): counts as offline in the running head. */
  unreachable: boolean;
  setUnreachable: (v: boolean) => void;
  /** Stop-press banner height in px, reported to the ToastHost. */
  bannerHeight: number;
  setBannerHeight: (h: number) => void;
};

export const useShellState = create<ShellState>((set) => ({
  held: null,
  setHeld: (held) => set({ held }),
  irisOut: null,
  requestIrisOut: (irisOut) => set({ irisOut }),
  sidebarOverlay: false,
  setSidebarOverlay: (sidebarOverlay) => set({ sidebarOverlay }),
  paletteOpen: false,
  paletteReturn: null,
  setPaletteOpen: (paletteOpen) => set((s) => ({ paletteOpen, paletteReturn: paletteOpen && !s.paletteOpen ? (document.activeElement as HTMLElement | null) : s.paletteReturn })),
  keyboardOpen: false,
  setKeyboardOpen: (keyboardOpen) => set({ keyboardOpen }),
  handoff: false,
  setHandoff: (handoff) => set({ handoff }),
  signOutOpen: false,
  setSignOutOpen: (signOutOpen) => set({ signOutOpen }),
  unreachable: false,
  setUnreachable: (unreachable) => set({ unreachable }),
  bannerHeight: 0,
  setBannerHeight: (bannerHeight) => set({ bannerHeight }),
}));

/** `useSplashDone()`: the first screen starts its typed headline when the hand-off begins (web/08 uses it for Tonight's cover). */
export const useSplashDone = () => useShellState((s) => s.handoff);
