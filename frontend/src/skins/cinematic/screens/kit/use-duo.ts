"use client";

import { useEffect, useState } from "react";

/**
 * TODO(web/23): stand-in for the series' `ambient.duo`. Samples the cover's mean
 * colour on an 8x8 canvas; null (the caller keeps `ambient.fallback.duo`) when
 * the pixels can't be read.
 */
export function useDuo(src: string | null): string | null {
  const [duo, setDuo] = useState<{ src: string; color: string | null } | null>(null);
  useEffect(() => {
    if (!src) return;
    let live = true;
    const img = new Image();
    img.onload = () => {
      let color: string | null = null;
      try {
        const c = document.createElement("canvas");
        c.width = c.height = 8;
        const g = c.getContext("2d");
        if (g) {
          g.drawImage(img, 0, 0, 8, 8);
          const px = g.getImageData(0, 0, 8, 8).data;
          let r = 0, gg = 0, b = 0;
          for (let i = 0; i < px.length; i += 4) { r += px[i]; gg += px[i + 1]; b += px[i + 2]; }
          const n = px.length / 4;
          color = `rgb(${Math.round(r / n)}, ${Math.round(gg / n)}, ${Math.round(b / n)})`;
        }
      } catch { /* tainted canvas: keep the fallback */ }
      if (live) setDuo({ src, color });
    };
    img.src = src;
    return () => { live = false; };
  }, [src]);
  return duo && duo.src === src ? duo.color : null;
}
