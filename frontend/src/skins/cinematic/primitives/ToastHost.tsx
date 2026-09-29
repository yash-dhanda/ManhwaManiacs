"use client";
import { useEffect } from "react";
import { Toaster } from "sonner";
import { DB_BUSY_EVENT } from "@/lib/busy-retry";
import { useDesktopFrame } from "./overlay-hooks";
import { setSubtitleFrame, subtitle } from "./subtitles";

/**
 * Mount once. Phone frame bottom-centre above the thumb index (`anchorBottom`), desktop bottom-left 24 px; max 2 visible
 * (1 while the stop-press banner shows, offset by `bannerHeight`). `Alt+T` moves focus into the region; sonner pauses
 * every hold while the region is hovered or focused.
 */
export function ToastHost({ anchorBottom = 24, anchorBottomPhone = 16, bannerHeight = 0, frame = "page" }: {
  anchorBottom?: number; anchorBottomPhone?: number; bannerHeight?: number; frame?: "reader" | "page";
}) {
  const desktop = useDesktopFrame();
  useEffect(() => { setSubtitleFrame(frame); }, [frame]);
  useEffect(() => {
    const on = () => subtitle.info("The server is busy. Your progress is saved on this device and will sync.", { id: "db-busy" });
    window.addEventListener(DB_BUSY_EVENT, on);
    return () => window.removeEventListener(DB_BUSY_EVENT, on);
  }, []);
  const extra = bannerHeight > 0 ? bannerHeight + 8 : 0;
  return (
    <Toaster
      position={desktop ? "bottom-left" : "bottom-center"}
      visibleToasts={bannerHeight > 0 ? 1 : 2}
      hotkey={["altKey", "KeyT"]}
      offset={{ bottom: anchorBottom + extra, left: 24 }}
      mobileOffset={{ bottom: anchorBottomPhone + extra, left: 16, right: 16 }}
      gap={8}
      toastOptions={{ unstyled: true }}
      style={{ ["--width" as string]: "min(560px, calc(100vw - 32px))", zIndex: "var(--mm-z-toast)" }}
    />
  );
}
