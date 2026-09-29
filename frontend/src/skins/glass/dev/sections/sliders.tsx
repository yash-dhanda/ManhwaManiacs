"use client";
/* eslint-disable @next/next/no-img-element -- plain img: Glass covers and viewer frames are dev assets and CDN URLs sized by their frame */

import { useRef, useState } from "react";
import { Button } from "../../primitives/Button";
import { FillSlider } from "../../primitives/FillSlider";
import { ScrubRail } from "../../primitives/ScrubRail";
import { Slider } from "../../primitives/Slider";
import { SpeedDial } from "../../primitives/SpeedDial";
import type { ForcedControlState } from "../../primitives/Switch";
import { Grounds, Row } from "../Grounds";

const STATES: (ForcedControlState | undefined)[] = [undefined, "hover", "pressed", "focus", "disabled", "loading", "error"];

/** web/27 F: the slider in every state, stepped, the fill slider, the scrub rail (segmented, bookmarks, lens) and the speed dial. */
export function SlidersSection() {
  const [v, setV] = useState(40);
  const [step, setStep] = useState(3);
  const [bright, setBright] = useState(0.6);
  const [vol, setVol] = useState(0.35);
  const [page, setPage] = useState(18);
  const [speed, setSpeed] = useState(1);
  const [open, setOpen] = useState(false);
  const anchor = useRef<HTMLButtonElement | null>(null);
  const [anchorEl, setAnchorEl] = useState<HTMLElement | null>(null);
  return (
    <div>
      <Grounds title="Slider" note="Continuous, stepped (magnet within 30 % of the step), and every state.">
        {() => (
          <>
            <Row label="continuous"><Slider value={v} onChange={setV} label="Text size" format={(n) => `${n}%`} data-testid="slider-main" /></Row>
            <Row label="stepped 0 to 10"><Slider value={step} min={0} max={10} step={1} onChange={setStep} label="Chapters ahead" data-testid="slider-stepped" /></Row>
            {STATES.slice(1).map((s) => <Row key={s} label={s}><Slider value={55} onChange={() => {}} label={`Slider ${s}`} forceState={s} /></Row>)}
          </>
        )}
      </Grounds>
      <Grounds title="Fill slider (on a glass host)" columns={1}>
        {() => (
          <Row>
            <FillSlider value={bright} onChange={setBright} label="Brightness" icon="sun" data-testid="fill-brightness" />
            <FillSlider value={vol} onChange={setVol} label="Volume" icon="speaker-high" data-testid="fill-volume" />
          </Row>
        )}
      </Grounds>
      <Grounds title="Scrub rail" note="Segmented by chapter, bookmarks as droplets. On touch the lens grows out of the thumb." columns={1}>
        {() => (
          <Row>
            <div style={{ display: "flex", gap: 24 }}>
              <ScrubRail pages={40} page={page} onCommit={setPage} height={280} bookmarks={[6, 27]} data-testid="scrub-plain"
                renderPreview={(p) => <img alt="" src={`/dev-covers/cover-${String((p % 24) + 1).padStart(2, "0")}.svg`} />} />
              <ScrubRail pages={60} page={page} onCommit={setPage} height={280} segments={[20, 25, 15]} data-testid="scrub-segmented" />
              <ScrubRail pages={1} page={1} onCommit={() => {}} data-testid="scrub-one" />
              <span className="gal-readout" data-testid="scrub-page">page {page}</span>
            </div>
          </Row>
        )}
      </Grounds>
      <Grounds title="Speed dial" note="Anchored picker: no URL state." columns={1}>
        {() => (
          <Row>
            <Button ref={(el) => { anchor.current = el; setAnchorEl(el); }} variant="secondary" size="M" label={`Speed ${speed}×`} onPress={() => setOpen(true)} data-testid="dial-open" />
            <SpeedDial open={open} onOpenChange={setOpen} anchor={anchorEl} value={speed} onChange={setSpeed} wpmAt={(s) => 190 * s} />
            <span className="gal-readout" data-testid="dial-value">speed {speed}</span>
          </Row>
        )}
      </Grounds>
    </div>
  );
}
