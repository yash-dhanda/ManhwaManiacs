"use client";

import { useRef } from "react";
import { FastScroll } from "../../primitives/FastScroll";
import { HardEdge, ScrollEdge, useScrollingFlag } from "../../primitives/ScrollEdge";
import { Row } from "../Grounds";

const rows = Array.from({ length: 260 }, (_, i) => i + 1);

/** web/27 K: soft edges over a scrolling list, a hard edge under a pinned header, scrollbars, and the fast-scroll strip (260 rows). */
export function ScrollEdgesSection() {
  const scroller = useRef<HTMLDivElement | null>(null);
  const plain = useRef<HTMLDivElement | null>(null);
  useScrollingFlag(plain);
  return (
    <div>
      <Row label="Soft edges + FastScroll (over 200 rows)">
        <div className="gal-scrollbox">
          <div ref={scroller} id="gal-chapters" className="glass-scroll gal-scroll" data-testid="scroll-list" tabIndex={0} aria-label="Chapters">
            {rows.map((n) => <div key={n} className="gal-scrollrow">Chapter {n}</div>)}
          </div>
          <ScrollEdge edge="top" plateau={16} scroller={scroller} data-testid="edge-top" />
          <ScrollEdge edge="bottom" plateau={16} scroller={scroller} data-testid="edge-bottom" />
          <FastScroll count={rows.length} scroller={scroller} labelAt={(i) => String(i + 1)} controls="gal-chapters" data-testid="fast-scroll" />
        </div>
      </Row>
      <Row label="Hard edge under a pinned header, thin scrollbar">
        <div className="gal-scrollbox">
          <div ref={plain} className="glass-scroll gal-scroll" tabIndex={0} aria-label="Short list">
            {rows.slice(0, 40).map((n) => <div key={n} className="gal-scrollrow">Row {n}</div>)}
          </div>
          <HardEdge edge="top" height={44} />
        </div>
      </Row>
    </div>
  );
}
