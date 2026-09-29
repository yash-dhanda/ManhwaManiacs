"use client";

import { useRef, useState } from "react";
import { Button } from "../../primitives/Button";
import { IconButton } from "../../primitives/IconButton";
import { ContextMenu, ContextMenuArea } from "../../primitives/ContextMenu";
import { Menu, type MenuEntry } from "../../primitives/Menu";
import { Poster } from "../../primitives/Poster";
import { SplitButton } from "../../primitives/SplitButton";
import { useContextPreview } from "../../primitives/useContextPreview";
import { Row } from "../Grounds";

const wait = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
const READ: MenuEntry[] = [
  { id: "start", label: "Read from the start", icon: "book-open" },
  { id: "all", label: "Read all", icon: "play" },
  { id: "pick", label: "Pick a chapter", icon: "caret-right" },
  { id: "dl", label: "Download next 10", icon: "download-simple", keys: ["D"] },
];

/** web/27 H: every row state, the pull-down bloom, the SplitButton menu, the poster lift and right-click. */
export function MenusSection() {
  const [hide, setHide] = useState(false);
  const [splitOpen, setSplitOpen] = useState(false);
  const [splitAnchor, setSplitAnchor] = useState<HTMLElement | null>(null);
  const [log, setLog] = useState("");
  const posterBox = useRef<HTMLDivElement>(null);
  const preview = useContextPreview(posterBox, "poster");
  const states: MenuEntry[] = [
    { id: "default", label: "Default", icon: "star" },
    { id: "hover", label: "Hover", icon: "star", forceState: "hover" },
    { id: "pressed", label: "Pressed", icon: "star", forceState: "pressed" },
    { id: "focus", label: "Focused", icon: "star", forceState: "focus" },
    { id: "disabled", label: "Disabled", icon: "star", disabled: true },
    { id: "loading", label: "Loading (2 s)", icon: "star", onSelect: () => wait(2000) },
    { id: "selected", label: "Selected", icon: "star", selected: true },
    { id: "error", label: "Error (fails)", icon: "star", error: "Couldn't do that", onSelect: () => { throw new Error("nope"); } },
    { kind: "gap" },
    { id: "delete", label: "Remove", icon: "trash", destructive: true },
    { kind: "check", id: "hide", label: "Hide from my Circle", icon: "eye-slash", checked: hide, onCheckedChange: setHide },
  ];
  const ctx: MenuEntry[] = [
    { id: "open", label: "Open", icon: "book-open", onSelect: () => setLog("open") },
    { id: "fav", label: "Favourite", icon: "heart", onSelect: () => setLog("favourite") },
    { id: "share", label: "Share", icon: "share", keys: ["S"] },
    { kind: "gap" },
    { id: "rm", label: "Remove from library", icon: "trash", destructive: true },
  ];
  return (
    <div>
      <Row label="Pull-down menu (blooms from its trigger; slide from the trigger to select)">
        <Menu label="Row states" items={states} trigger={<Button variant="secondary" size="M" label="Every row state" data-testid="menu-trigger" />} data-testid="menu" />
        <Menu label="More" items={READ} trigger={<IconButton icon="dots-three" label="More" data-testid="menu-more" />} />
      </Row>
      <Row label="SplitButton trailing segment">
        <Menu label="Read options" items={READ} open={splitOpen} onOpenChange={setSplitOpen} anchor={splitAnchor} trigger={<span />} data-testid="split-menu" />
        <SplitButton label="Continue Ch 12" icon="play" onPress={() => setLog("continue")} moreLabel="Read options" menuOpen={splitOpen} onMore={(el) => { setSplitAnchor(el); setSplitOpen(true); }} data-testid="split" />
      </Row>
      <Row label="Poster lift (long press 450 ms, or . / Shift+F10) and right-click">
        <div ref={posterBox} style={{ display: "inline-block" }}>
          <Poster title="Solo Leveling" src="/dev-covers/cover-01.svg" onContextPreview={preview.show} data-testid="ctx-poster" />
        </div>
        <ContextMenu label="Poster actions" items={ctx} preview={preview} data-testid="ctx-menu" />
        <ContextMenuArea label="Right-click actions" items={ctx} className="gal-rightclick" data-testid="rightclick-area"><span className="gal-note">Right-click here</span></ContextMenuArea>
        <span className="gal-readout" data-testid="menu-log">{log}</span>
      </Row>
    </div>
  );
}
