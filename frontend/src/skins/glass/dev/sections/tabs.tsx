"use client";

import { useState } from "react";
import { TabPager, type TabDef } from "../../primitives/TabPager";

const Panel = ({ name }: { name: string }) => (
  <ul className="gal-sheet-rows" style={{ minHeight: 160 }}>{[1, 2, 3].map((i) => <li key={i}>{name} {i}</li>)}</ul>
);

/** web/27 E: the tab strip over a scroll-snap pager, with disabled, loading and error tabs. */
export function TabsSection() {
  const [v, setV] = useState("chapters");
  const tabs: TabDef[] = [
    { id: "chapters", label: "Chapters", panel: <Panel name="Chapter" /> },
    { id: "details", label: "Details", panel: <Panel name="Detail" /> },
    { id: "loading", label: "Related", state: "loading", panel: null },
    { id: "off", label: "Comments", disabled: true, panel: <Panel name="Comment" /> },
    { id: "error", label: "Sources", state: "error", errorText: "Couldn't load sources.", onRetry: () => setV("chapters"), panel: null },
  ];
  return (
    <div style={{ maxWidth: 480 }}>
      <TabPager tabs={tabs} value={v} onChange={setV} label="Series sections" data-testid="tabs-main" />
      <p className="gal-readout" data-testid="tabs-value">selected: {v}</p>
    </div>
  );
}
