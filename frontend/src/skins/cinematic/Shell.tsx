"use client";
import dynamic from "next/dynamic";
import { usePathname } from "next/navigation";
import { lazy, Suspense, useEffect, useRef, useState, type ReactNode } from "react";
import { useActiveProfileStore } from "@/features/profiles/store";
import { DuotoneDefs } from "./duotone";
import { MotionRoot } from "./motion";
import { GridOverlay } from "./primitives/layout/GridOverlay";
import { ToastHost } from "./primitives/ToastHost";
import { Splash } from "./Splash";
import { SignOutDialog } from "./shell/AccountMenu";
import { FirstRunNote } from "./shell/FirstRunNote";
import { frameFor } from "./shell/frames";
import { useGate, StaleProfileCheck } from "./shell/Gate";
import { GlobalKeys } from "./shell/GlobalKeys";
import { KeyboardSheet } from "./shell/KeyboardSheet";
import { Overlays, useIrisReveal } from "./shell/Overlays";
import { PageTransition } from "./shell/PageTransition";
import { RatingCardHost } from "./shell/RatingCardHost";
import { RunningHead } from "./shell/RunningHead";
import { focusMainHeading, useRouteFocus } from "./shell/route-focus";
import { Sidebar, useSidebar } from "./shell/Sidebar";
import { useShellState } from "./shell/shell-state";
import { StopPressBanner } from "./shell/StopPressBanner";
import { ThumbIndex } from "./shell/ThumbIndex";

const CommandPalette = lazy(() => import("./shell/CommandPalette"));
// Development builds only: the dynamic import sits behind the NODE_ENV check so production bundles never contain the overlay.
const MotionTimings = process.env.NODE_ENV !== "production" ? dynamic(() => import("./motion-timings"), { ssr: false }) : null;

/** The active profile's mood for the mastheads that grade behind them (Tonight, Library, Discover, Index). */
export function useShellMood() {
  return useActiveProfileStore((s) => s.activeProfile?.mood ?? null);
}

function PaletteHost() {
  const [opened, setOpened] = useState(false);
  const open = useShellState((s) => s.paletteOpen);
  if (open && !opened) setOpened(true);
  return opened ? <Suspense fallback={null}><CommandPalette /></Suspense> : null;
}

/** Long-press on mobile web: `contextmenu` on `.cine-press` elements is prevented in the phone frame (§8.0.5). */
function useLongPressGuard() {
  useEffect(() => {
    const on = (e: Event) => {
      if (!window.matchMedia("(max-width: 767px)").matches) return;
      if ((e.target as Element | null)?.closest?.(".cine-press")) e.preventDefault();
    };
    document.addEventListener("contextmenu", on);
    return () => document.removeEventListener("contextmenu", on);
  }, []);
}

/**
 * The Cinematic frame (§8.0.1): Bare, Takeover, Desktop, Phone, Reader, Page. Desktop and phone are one server-rendered tree that
 * media queries pick between; frames chrome-less screens (auth, picker, readers) render bare.
 */
export default function Shell({ children }: { children: ReactNode }) {
  const pathname = usePathname() ?? "/";
  const frame = frameFor(pathname);
  const { unresolved, gate } = useGate();
  const sidebar = useSidebar();
  const banner = useShellState((s) => s.bannerHeight);
  const mainRef = useRef<HTMLElement | null>(null);
  const probeSettled = gate === "public" || gate !== "pending";
  useRouteFocus();
  useLongPressGuard();
  useIrisReveal(mainRef, pathname);
  useEffect(() => { document.documentElement.style.setProperty("color-scheme", "dark"); }, []);
  const app = frame === "app";
  return (
    <MotionRoot>
      <DuotoneDefs />
      <div data-cine-shell data-frame={frame} data-sidebar={sidebar.stored} className="min-h-dvh bg-paper-0 text-ink-100">
        <a href="#main-content" className="cine-skip type-ui" onClick={(e) => { e.preventDefault(); if (!focusMainHeading()) document.getElementById("main-content")?.focus(); }}>Skip to content</a>
        {app ? <Sidebar sidebar={sidebar} /> : null}
        {app ? <RunningHead /> : null}
        <div className="cine-content" data-frame={frame}>
          {app ? <FirstRunNote /> : null}
          <main id="main-content" ref={mainRef} tabIndex={-1} className="outline-none">
            {unresolved ? null : <PageTransition>{children}</PageTransition>}
          </main>
        </div>
        {app ? <ThumbIndex /> : null}
        {app || frame === "takeover" || frame === "bare" ? <StopPressBanner /> : null}
        <RatingCardHost />
        <ToastHost anchorBottom={24} anchorBottomPhone={app ? 72 : 16} bannerHeight={banner} frame={frame === "reader" ? "reader" : "page"} />
        <GridOverlay />
        {MotionTimings ? <MotionTimings /> : null}
        <GlobalKeys onToggleSidebar={sidebar.toggle} />
        <PaletteHost />
        <KeyboardSheet />
        <SignOutDialog />
        <StaleProfileCheck />
        <Overlays />
        <Splash probeSettled={probeSettled} />
      </div>
    </MotionRoot>
  );
}
