"use client";

import { useState } from "react";
import type { ContentMode } from "@/features/content-mode/mode";
import { ContentModeSwitchView, useLastModeSwitchOrigin } from "../../primitives/ContentModeSwitch";
import { Row } from "../Grounds";

/** web/27 M: the three variants over local state. The real switch reads `novels_enabled`; here it is forced on and off. */
export function ContentModeSection() {
  const [mode, setMode] = useState<ContentMode>("manga");
  const origin = useLastModeSwitchOrigin();
  return (
    <div>
      <Row label="sidebar"><ContentModeSwitchView variant="sidebar" mode={mode} novelsEnabled onMode={setMode} data-testid="mode-sidebar" /></Row>
      <Row label="navRow (press to expand)"><ContentModeSwitchView variant="navRow" mode={mode} novelsEnabled onMode={setMode} data-testid="mode-navrow" /></Row>
      <Row label="disabled server-side: renders nothing"><ContentModeSwitchView variant="sidebar" mode="manga" novelsEnabled={false} onMode={setMode} data-testid="mode-off" /></Row>
      <span className="gal-readout" data-testid="mode-readout">mode: {mode}; wave origin: {origin ? `${Math.round(origin.x)},${Math.round(origin.y)}` : "none"}</span>
    </div>
  );
}
