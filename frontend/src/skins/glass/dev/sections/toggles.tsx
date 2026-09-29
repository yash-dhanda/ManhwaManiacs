"use client";

import { useState } from "react";
import { GlassSurface } from "../../glass/GlassSurface";
import { Checkbox } from "../../primitives/Checkbox";
import { Radio, RadioList } from "../../primitives/RadioList";
import { SelectionCheck } from "../../primitives/SelectionCheck";
import { Stepper } from "../../primitives/Stepper";
import { Switch, type ForcedControlState } from "../../primitives/Switch";
import { showToast } from "../../primitives/Toast";
import { Grounds, Row } from "../Grounds";

const STATES: ForcedControlState[] = ["hover", "pressed", "focus", "disabled", "loading", "error"];

/** web/27 G: switch, checkbox, radio list, selection check and stepper, every state. */
export function TogglesSection() {
  const [on, setOn] = useState(true);
  const [flaky, setFlaky] = useState(false);
  const [c, setC] = useState<boolean | "mixed">(true);
  const [r, setR] = useState("all");
  const [sel, setSel] = useState(true);
  const [n, setN] = useState(3);
  return (
    <div>
      <Grounds title="Switch" note="Tap, drag the knob, or press Space. The flaky one rejects and springs back with the shake.">
        {() => (
          <>
            <Row label="on / off">
              <Switch checked={on} onChange={setOn} label="Notifications" data-testid="switch-main" />
              <Switch checked={!on} onChange={(v) => setOn(!v)} label="Inverse" />
            </Row>
            <Row label="flaky (error: springs back)">
              <Switch checked={flaky} label="Flaky setting" data-testid="switch-flaky" onChange={async (v) => { await new Promise((res) => setTimeout(res, 300)); if (v) { showToast({ kind: "error", text: "Couldn't change that setting" }); throw new Error("no"); } setFlaky(v); }} />
            </Row>
            {STATES.map((s) => <Row key={s} label={s}><Switch checked={s !== "disabled"} onChange={() => {}} label={`Switch ${s}`} forceState={s} /></Row>)}
          </>
        )}
      </Grounds>
      <Grounds title="Checkbox, radio, selection check">
        {() => (
          <>
            <Row label="checkbox: off, on, mixed">
              <Checkbox checked={c} onChange={setC} label="Select all" data-testid="check-main" />
              <Checkbox checked={false} onChange={() => {}} label="Off" />
              <Checkbox checked="mixed" onChange={() => {}} label="Some" />
              <Checkbox checked onChange={() => {}} label="Disabled" disabled />
              <Checkbox checked={false} onChange={() => {}} label="Focus" forceState="focus" />
            </Row>
            <Row label="radio visual">
              <Radio checked={false} /><Radio checked />
            </Row>
            <Row label="radio list (only in lists)">
              <div style={{ width: 300 }}>
                <RadioList label="Show" value={r} onChange={setR} data-testid="radios" options={[{ value: "all", label: "All series" }, { value: "unread", label: "Unread only", description: "Hides finished series" }, { value: "downloaded", label: "Downloaded" }, { value: "locked", label: "Unavailable", disabled: true }]} />
              </div>
            </Row>
            <Row label="selection check (lists, select mode)">
              <button type="button" className="gal-cur" onClick={() => setSel(!sel)} aria-pressed={sel}><SelectionCheck selected={sel} /></button>
              <SelectionCheck selected />
              <SelectionCheck selected={false} />
            </Row>
          </>
        )}
      </Grounds>
      <Grounds title="Stepper" note="Past a limit the value stretches 4 px and springs back." columns={1}>
        {() => (
          <>
            <Row label="on content"><Stepper value={n} onChange={setN} min={0} max={5} label="Chapters" data-testid="stepper-main" /></Row>
            <Row label="on glass (wellOnGlass)">
              <GlassSurface tier="t4" radius={26} layer="overlays" className="gal-glass-pad" materialize={false}><Stepper value={n} onChange={setN} min={0} max={5} label="Chapters on glass" /></GlassSurface>
            </Row>
          </>
        )}
      </Grounds>
    </div>
  );
}
