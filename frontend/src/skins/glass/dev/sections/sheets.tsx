"use client";

import { useRef, useState } from "react";
import { Button } from "../../primitives/Button";
import { Sheet, type SheetState } from "../../primitives/Sheet";
import { TextField } from "../../primitives/TextField";
import { openSheet } from "../../primitives/useSheetParam";

const ROWS = ["Sort by", "Status", "Genre", "Language", "Content rating", "Source"];

function Rows({ many }: { many?: boolean }) {
  return (
    <ul className="gal-sheet-rows">
      {(many ? [...ROWS, ...ROWS, ...ROWS] : ROWS).map((r, i) => <li key={i}>{r}</li>)}
    </ul>
  );
}

/** Every sheet form with a launch button; the page wrapper is the recedeTarget (web/27 B6). */
export function SheetsSection() {
  const page = useRef<HTMLDivElement>(null);
  const [state, setState] = useState<SheetState>("ready");
  const launch = (id: string, extra?: Record<string, string>) => (el: HTMLElement | null) => () => openSheet(id, extra, el);
  const btn = (id: string, label: string, extra?: Record<string, string>) => (
    <Button key={id} variant="secondary" size="M" label={label} onPress={() => openSheet(id, extra)} data-testid={`open-${id}`} />
  );
  void launch;
  return (
    <div ref={page} className="gal-page" data-testid="sheets-page">
      <p className="gal-note">Phone (below 768 px): detents, grabber, recession. Desktop: panel, window, detail window, popover. Every form is URL state: ?sheet=id.</p>
      <div className="gal-specimens">
        {btn("filters", "Filters (medium, large)")}
        {btn("large-only", "Large only")}
        {btn("picker", "Picker (centred title)")}
        {btn("peek", "Peek, medium, large")}
        {btn("keyboard", "Sheet with a field")}
        {btn("panel-demo", "Panel (desktop)")}
        {btn("window-demo", "Window (desktop)")}
        {btn("detail-demo", "Detail window (desktop)")}
        {btn("offer-demo", "Offer popover (desktop)")}
        {btn("loading-demo", "Loading")}
        {btn("error-demo", "Error")}
        {btn("empty-demo", "Empty")}
        {btn("monolith-demo", "Monolith (T5)")}
      </div>
      <div className="gal-page__filler" aria-hidden="true" />
      <div className="gal-specimens">
        <Button variant="secondary" size="M" label="State: ready" onPress={() => setState("ready")} />
        <Button variant="secondary" size="M" label="State: loading" onPress={() => setState("loading")} />
      </div>

      <Sheet id="filters" title="Filters" detents={["medium", "large"]} desktop="panel" recedeTarget={page}>
        <Rows many />
        <div className="gal-specimens"><Button variant="secondary" size="M" label="Stack another sheet" twin="onGlass" onPress={() => openSheet("recommend", { series: "solo-leveling" })} data-testid="open-recommend" /></div>
      </Sheet>
      <Sheet id="recommend" title="Recommend" detents={["medium", "large"]} desktop="window" recedeTarget={page}><Rows /></Sheet>
      <Sheet id="large-only" title="Chapters" detents={["large"]} desktop="panel" recedeTarget={page}><Rows many /></Sheet>
      <Sheet id="picker" title="Pick a chapter" centerTitle detents={["medium", "large"]} desktop="window" recedeTarget={page}><Rows /></Sheet>
      <Sheet id="peek" title="Now playing" detents={["peek", "medium", "large"]} initialDetent="peek" desktop="panel" recedeTarget={page}><Rows many /></Sheet>
      <Sheet id="keyboard" title="Add a note" detents={["medium", "large"]} desktop="window" recedeTarget={page}>
        <TextField label="Title" placeholder="Something to remember" sheet />
        <TextField label="Details" placeholder="More" sheet />
      </Sheet>
      <Sheet id="panel-demo" title="Panel" desktop="panel" recedeTarget={page}><Rows many /></Sheet>
      <Sheet id="window-demo" title="Window" desktop="window" recedeTarget={page}><Rows /></Sheet>
      <Sheet id="detail-demo" title="Series detail" desktop="detailWindow" recedeTarget={page}><Rows many /></Sheet>
      <Sheet id="offer-demo" title="Recap offer" desktop="popover" recedeTarget={page}><Rows /></Sheet>
      <Sheet id="loading-demo" title="Loading" state="loading" desktop="panel" recedeTarget={page} />
      <Sheet id="error-demo" title="Couldn't load" state="error" errorText="Sources are busy." onRetry={() => setState("ready")} desktop="panel" recedeTarget={page} />
      <Sheet id="empty-demo" title="Nothing yet" state="empty" emptyCopy="No bookmarks yet." desktop="panel" recedeTarget={page} />
      <Sheet id="monolith-demo" title="Listen" material="monolith" desktop="window" recedeTarget={page}><Rows many /></Sheet>
      <p className="gal-readout" data-testid="sheets-state">{state}</p>
    </div>
  );
}
