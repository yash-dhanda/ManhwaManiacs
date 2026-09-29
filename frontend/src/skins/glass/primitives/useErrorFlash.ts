"use client";

import { useEffect, useState } from "react";
import { announce } from "./announce";
import { shake } from "./shake";

/**
 * The error state of a control (Button, IconButton, chips): when `error` becomes a non-empty string the control shakes
 * with the `error` haptic, the text goes to the assertive region for 6 s, and `flashing` is true for 2 s (the caller swaps
 * its label or glyph for a `warning-circle` while it is).
 */
export function useErrorFlash(error: string | null | undefined, getEl: () => HTMLElement | null, amp = 8): { flashing: boolean; text: string } {
  const [flash, setFlash] = useState<{ on: boolean; text: string }>({ on: false, text: "" });
  useEffect(() => {
    if (!error) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the error prop is the trigger; the flash is its 2 s echo
    setFlash({ on: true, text: error });
    shake(getEl(), amp);
    announce(error, 6000);
    const t = setTimeout(() => setFlash((f) => ({ ...f, on: false })), 2000);
    return () => clearTimeout(t);
  }, [error, getEl, amp]);
  return { flashing: flash.on, text: flash.text };
}
