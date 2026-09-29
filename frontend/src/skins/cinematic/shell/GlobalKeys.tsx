"use client";
import { usePathname } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { HELP_SHORTCUT_KEYS, useShortcut } from "@/lib/keyboard";
import { frameFor } from "./frames";
import { useGSequence } from "./g-sequence";
import { useShellState } from "./shell-state";
import { useCineRouter } from "./use-cine-router";

/** §8.0.6 global web keys plus the `g` sequence and its `G 1_` chip. Everything registered in the `General` and `Navigation` groups. */
export function GlobalKeys({ onToggleSidebar }: { onToggleSidebar: () => void }) {
  const pathname = usePathname() ?? "/";
  const router = useCineRouter();
  const { mode, novelsEnabled } = useContentMode();
  const frame = frameFor(pathname);
  const togglePalette = useCallback(() => { const s = useShellState.getState(); s.setPaletteOpen(!s.paletteOpen); }, []);
  useShortcut({ id: "shell.palette", keys: "mod+k", description: "Open or close the command palette", group: "General", allowInInput: true, handler: togglePalette });
  useShortcut({ id: "shell.sidebar", keys: "mod+b", description: "Toggle the sidebar", group: "General", allowInInput: true, handler: onToggleSidebar });
  useShortcut({ id: "shell.keyboard", keys: HELP_SHORTCUT_KEYS, description: "Show keyboard shortcuts", group: "General", handler: () => { const s = useShellState.getState(); s.setKeyboardOpen(!s.keyboardOpen); } });
  useShortcut({ id: "shell.focus-search", keys: "/", description: "Focus search", group: "Navigation", handler: () => { window.dispatchEvent(new CustomEvent("mm:focus-search")); } });
  // Listing only: the web/05 sonner hotkey moves focus into the toast region.
  useShortcut({ id: "shell.notifications", keys: "alt+t", description: "Go to notifications", group: "General", allowInInput: true, preventDefault: false, handler: () => undefined });
  // Listing only: a chord never matches a single keydown; the real handler is the capture-phase listener below.
  useShortcut({ id: "shell.g", keys: "g 1", description: "Jump to a section: g then 1 to 12, 0 for Settings", group: "Navigation", preventDefault: false, handler: () => undefined });
  const inChrome = frame === "app" || frame === "takeover" || frame === "bare";
  const { chip } = useGSequence({ enabled: inChrome, novels: novelsEnabled && mode === "novel", onJump: (href) => router.push(href, "section") });
  // Hold the last text and fade it out over 160 ms after the sequence ends, then unmount.
  const [held, setHeld] = useState<string | null>(null);
  const [shown, setShown] = useState(false);
  useEffect(() => {
    if (chip) { setHeld(chip); setShown(true); return; } // eslint-disable-line react-hooks/set-state-in-effect -- mirrors the chip for the exit fade
    setShown(false);
    const t = setTimeout(() => setHeld(null), 160);
    return () => clearTimeout(t);
  }, [chip]);
  return held ? (
    <div role="status" aria-label={`Go to section, ${held}`} data-g-chip data-shown={shown} className="pointer-events-none fixed left-6 flex items-center" style={{ bottom: "calc(var(--mm-thumb-index-h, 0px) + 24px)", zIndex: "var(--mm-z-toast)", opacity: shown ? 1 : 0, transition: "opacity 160ms var(--mm-ease-set)" }}>
      <kbd className="type-folio border border-ink-30 bg-paper-0 px-2 py-1 text-ink-100">{held}</kbd>
    </div>
  ) : null;
}
