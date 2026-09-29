"use client";

import { useEffect, useState } from "react";
import { Toaster } from "sonner";
import { safeTop, useMedia } from "./overlay-utils";
import { useQueueFrame } from "./overlay-queue";

/** `html[data-…]` flags the Shell and the readers set; read live. */
function useRootFlag(name: string): boolean {
  const [on, setOn] = useState(false);
  useEffect(() => {
    const read = () => setOn(document.documentElement.hasAttribute(name));
    read();
    const mo = new MutationObserver(read);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: [name] });
    return () => mo.disconnect();
  }, [name]);
  return on;
}

/**
 * The one toast system: `sonner` through `toast.custom` only (glass 7.12). Mount once. Our components own the timer and the
 * motion, so sonner is unstyled, never expires a toast, and its swipe is off (our Motion drag owns dismissal).
 * Position by frame: phones top-centre at safe-top + 60; desktop bottom-left beside the sidebar (88 px up while a bottom bar
 * shows); inside the desktop readers top-centre at 60.
 */
export function GlassToaster() {
  useQueueFrame();
  // Alt+N moves focus to the newest toast (sonner's own hotkey only focuses its list)
  useEffect(() => {
    const on = (e: KeyboardEvent) => {
      if (e.altKey && e.code === "KeyN") setTimeout(() => document.querySelector<HTMLElement>('[data-sonner-toast][data-front="true"] [data-glass-toast]:not([data-hidden])')?.focus(), 0);
    };
    window.addEventListener("keydown", on);
    return () => window.removeEventListener("keydown", on);
  }, []);
  const desktop = useMedia("(min-width: 768px)");
  const reader = useRootFlag("data-reader");
  const bottomBar = useRootFlag("data-bottom-bar");
  const top = desktop ? (reader ? 60 : 0) : safeTop() + 60;
  const topCentre = !desktop || reader;
  const offset = topCentre
    ? { top, left: 16, right: 16 }
    : { bottom: bottomBar ? 88 : 24, left: "calc(var(--glass-sidebar-edge, 0px) + 24px)" };
  return (
    <Toaster
      position={topCentre ? "top-center" : "bottom-left"}
      visibleToasts={2}
      gap={8}
      hotkey={["altKey", "KeyN"]}
      containerAriaLabel="Notifications"
      swipeDirections={[]}
      offset={offset}
      mobileOffset={offset}
      toastOptions={{ unstyled: true, duration: Infinity }}
      className="g-toaster"
      style={{ "--width": "auto" } as React.CSSProperties}
    />
  );
}
