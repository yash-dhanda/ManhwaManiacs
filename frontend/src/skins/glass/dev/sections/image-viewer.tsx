"use client";

import { useRef } from "react";
import { ImageViewer, openImage } from "../../primitives/ImageViewer";
import { Row } from "../Grounds";

/** web/27 J: the thumbnail opens `?sheet=image`; the viewer zooms out of its rect. */
export function ImageViewerSection() {
  const thumb = useRef<HTMLButtonElement>(null);
  return (
    <div>
      <Row label="Thumbnail (click, or Enter)">
        <button ref={thumb} type="button" className="gal-thumb" onClick={() => void openImage(thumb.current)} aria-label="Open image" data-testid="image-thumb" style={{ width: 120, height: 176, padding: 0, border: 0, borderRadius: 12, overflow: "hidden", background: "none" }}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/dev-covers/cover-05.svg" alt="" width={120} height={176} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
        </button>
      </Row>
      <p className="gal-note">Pinch 1x to 4x, double tap 1x / 2.5x, drag down to dismiss. Keys: + - 0, arrows, Esc.</p>
      <ImageViewer src="/dev-covers/cover-05.svg" alt="A dark cover with a violet sky" data-testid="image-viewer" />
    </div>
  );
}
