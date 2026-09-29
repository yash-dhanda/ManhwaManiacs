"use client";

import { useRef, useState } from "react";
import { Button } from "../../primitives/Button";
import { PullToRefresh, type PullToRefreshHandle } from "../../primitives/PullToRefresh";
import { Row } from "../Grounds";

const wait = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

/** web/27 L: touch-drag the list down 100 px; the droplet grows over 60, the neck thins and snaps at 100. */
export function PullSection() {
  const h = useRef<PullToRefreshHandle>(null);
  const [n, setN] = useState(0);
  const [changed, setChanged] = useState(true);
  return (
    <div>
      <Row label="Alternatives (Refresh in the menu, r on desktop)">
        <Button variant="secondary" size="M" label="Refresh()" onPress={() => h.current?.refresh()} data-testid="pull-refresh-btn" />
        <Button variant="secondary" size="M" label={changed ? "Result: changed" : "Result: unchanged"} onPress={() => setChanged(!changed)} />
        <span className="gal-readout" data-testid="pull-count">refreshed: {n}</span>
      </Row>
      <div className="gal-pullbox">
        <PullToRefresh handle={h} onRefresh={async () => { await wait(1200); setN((v) => v + 1); return { changed }; }} data-testid="pull">
          {Array.from({ length: 30 }, (_, i) => <div key={i} className="gal-scrollrow">Row {i + 1}</div>)}
        </PullToRefresh>
      </div>
    </div>
  );
}
