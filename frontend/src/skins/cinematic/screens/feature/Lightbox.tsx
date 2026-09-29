"use client";

import { useEffect, useRef } from "react";
import { Glyph } from "./Glyph";
import s from "./feature.module.css";

/** §7.30: the whole cover on near-black. Esc and the x close; a drag down past 120 px closes. */
export function Lightbox({ src, alt, onClose }: { src: string; alt: string; onClose: () => void }) {
  useEffect(() => {
    const key = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", key);
    return () => window.removeEventListener("keydown", key);
  }, [onClose]);
  const startY = useRef(0);
  return (
    <div
      className={s.lightbox}
      role="dialog"
      aria-modal="true"
      aria-label="Cover"
      onPointerDown={(e) => (startY.current = e.clientY)}
      onPointerUp={(e) => e.clientY - startY.current > 120 && onClose()}
    >
      {/* eslint-disable-next-line @next/next/no-img-element */}
      <img src={src} alt={alt} draggable={false} />
      <button type="button" className={s.icon} aria-label="Close" onClick={onClose} autoFocus>
        <Glyph name="x" />
      </button>
    </div>
  );
}
