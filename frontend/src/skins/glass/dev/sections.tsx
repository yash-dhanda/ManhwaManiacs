"use client";

import { useEffect, useRef, useState, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { useGlassCount } from "../glass/budget";
import { Badge, badgeLabel, type StatusKey } from "../primitives/Badge";
import { Button, type ButtonVariant } from "../primitives/Button";
import { Chip } from "../primitives/Chip";
import { ChipRow } from "../primitives/ChipRow";
import { CollectionCard } from "../primitives/cards/CollectionCard";
import { ContinueStack } from "../primitives/cards/ContinueStack";
import { HealthBead } from "../primitives/cards/HealthBead";
import { HistoryTile } from "../primitives/cards/HistoryTile";
import { NotificationCard } from "../primitives/cards/NotificationCard";
import { ResultCard } from "../primitives/cards/ResultCard";
import { SeriesCard } from "../primitives/cards/SeriesCard";
import { SourceMonogram } from "../primitives/cards/SourceMonogram";
import { SourceRowCard } from "../primitives/cards/SourceRowCard";
import { StatCard } from "../primitives/cards/StatCard";
import { WorldCard } from "../primitives/cards/WorldCard";
import { GlassGroup } from "../primitives/GlassGroup";
import { GoalRing } from "../primitives/GoalRing";
import { HoldToConfirm } from "../primitives/HoldToConfirm";
import { Icon } from "../primitives/Icon";
import { IconButton } from "../primitives/IconButton";
import { KeyCombos, Keycap } from "../primitives/Keycap";
import { LetterReveal } from "../primitives/LetterReveal";
import { LiquidProgress } from "../primitives/LiquidProgress";
import { Poster } from "../primitives/Poster";
import { PosterGrid } from "../primitives/PosterGrid";
import { Progress, Dots, Spinner } from "../primitives/Progress";
import { ORB_SIZES, ProfileOrb, AVATAR_PRESETS, type AvatarPreset } from "../primitives/ProfileOrb";
import { Rail } from "../primitives/Rail";
import { RailGroup } from "../primitives/RailGroup";
import { SearchField } from "../primitives/SearchField";
import { Segmented } from "../primitives/Segmented";
import { Skeleton } from "../primitives/Skeleton";
import { SplitButton } from "../primitives/SplitButton";
import { TextArea } from "../primitives/TextArea";
import { TextField } from "../primitives/TextField";
import { Tooltip } from "../primitives/Tooltip";
import { TypedHeadline } from "../primitives/TypedHeadline";
import { useWave } from "../primitives/wave";
import { Grounds, Row } from "./Grounds";
import { SheetsSection } from "./sections/sheets";
import { AlertsSection } from "./sections/alerts";
import { ToastsSection } from "./sections/toasts";
import { TabsSection } from "./sections/tabs";
import { SlidersSection } from "./sections/sliders";
import { TogglesSection } from "./sections/toggles";
import { MenusSection } from "./sections/menus";
import { BannersSection } from "./sections/banners";
import { ImageViewerSection } from "./sections/image-viewer";
import { ScrollEdgesSection } from "./sections/scroll-edges";
import { PullSection } from "./sections/pull-to-refresh";
import { ContentModeSection } from "./sections/content-mode";

const COVERS = Array.from({ length: 24 }, (_, i) => `/dev-covers/cover-${String(i + 1).padStart(2, "0")}.svg`);
const cover = (i: number) => COVERS[i % COVERS.length];
const TITLES = ["Solo Leveling", "Tower of God", "The Beginning After The End", "Omniscient Reader", "Lookism", "Eleceed", "Nano Machine", "Return of the Mount Hua"];
const STATES = ["hover", "pressed", "focus", "disabled", "loading", "selected", "error"] as const;

function Live() {
  const c = useGlassCount();
  return <p className="gal-readout" data-testid="live-count">live glass: {c.glass + c.exempt} ({c.exempt} exempt in this gallery; screens are limited to 6)</p>;
}

export function ButtonsSection() {
  const [fav, setFav] = useState(false);
  const [dl, setDl] = useState<"idle" | "queued" | "saving" | "done" | "failed">("idle");
  const [done, setDone] = useState(3);
  const [err, setErr] = useState<string | null>(null);
  useEffect(() => { if (dl === "queued") { const t = setTimeout(() => setDl("saving"), 800); return () => clearTimeout(t); } if (dl === "saving") { const t = setInterval(() => setDone((d) => { if (d >= 12) { setDl("done"); return d; } return d + 1; }), 350); return () => clearInterval(t); } }, [dl]);
  const variants: ButtonVariant[] = ["primary", "secondary", "plain", "destructive", "destructiveConfirm"];
  return (
    <>
      <Live />
      {(["L", "M", "S"] as const).map((size) => (
        <Grounds key={size} title={`Size ${size}: every variant, every state`} note="Two live page-level controls at most per scrolling page (2.4.1 rule 2); a button repeated per item takes twin=content. Only one tinted primary per screen: the gallery shows several, so it turns lit-object warnings off by design.">
          {variants.map((v) => (
            <Row key={v} label={v}>
              <Button variant={v} size={size} label={v === "destructiveConfirm" ? "Delete" : v === "destructive" ? "Delete" : "Continue"} icon={v === "plain" || v === "destructiveConfirm" ? undefined : "play"} />
              {STATES.map((s) => (
                <Button key={s} variant={v} size={size} label={s} forceState={s === "disabled" || s === "loading" || s === "selected" || s === "error" ? undefined : s} disabled={s === "disabled"} disabledReason="Sign in to continue" loading={s === "loading"} selected={s === "selected" ? true : undefined} error={s === "error" ? "Couldn't save" : undefined} />
              ))}
            </Row>
          ))}
        </Grounds>
      ))}
      <Grounds title="Toggle, twin and over media">
        <Row label="toggle (label follows state, no aria-pressed)"><Button label={fav ? "Favourited" : "Favourite"} icon="star" selected={fav} onPress={() => setFav((f) => !f)} data-testid="toggle-fav" /></Row>
        <Row label="twin=content (per item)"><Button label="Read" twin="content" size="S" /><Button variant="primary" label="Start" twin="content" size="S" /></Row>
        <Row label="secondary overMedia"><Button label="Preview" overMedia icon="play" /></Row>
      </Grounds>
      <Grounds title="Progress button (download)" note="Download, Queued, saving 12/40 style count, Saved, Retry with the shake.">
        <Row label={dl}>
          <Button variant="progress" label="Download" download={dl === "idle" ? { status: "idle" } : dl === "queued" ? { status: "queued" } : dl === "saving" ? { status: "saving", done, total: 12 } : dl === "done" ? { status: "done" } : { status: "failed" }} onPress={() => { setDone(0); setDl("queued"); }} onRetry={() => { setDone(0); setDl("queued"); }} data-testid="progress-button" />
          <Button size="S" label="Fail" onPress={() => setDl("failed")} />
          <Button size="S" label="Reset" onPress={() => setDl("idle")} />
        </Row>
      </Grounds>
      <Grounds title="Split button">
        <Row label="continue + more"><SplitButton label="Continue, chapter 143" moreLabel="More ways to read" onPress={() => {}} onMore={() => {}} data-testid="split" /></Row>
        <Row label="error text (assertive region)"><Button label="Save" error={err} onPress={() => setErr("Couldn't save")} data-testid="error-button" /></Row>
      </Grounds>
    </>
  );
}

export function HoldSection() {
  const [clicks, setClicks] = useState(0);
  const [confirms, setConfirms] = useState(0);
  const [mode, setMode] = useState(0);
  return (
    <Grounds title="HoldToConfirm" note="200 ms before anything starts, the fill rises to 1,200 ms; Enter and Space are always a click. standalone opens the confirm alert (web/27), inAlert shows its explicit button under the hold button.">
      <Row label="standalone"><HoldToConfirm mode="standalone" label="Hold to delete" icon="trash" onConfirm={() => setConfirms((c) => c + 1)} onRequestConfirm={() => setClicks((c) => c + 1)} data-testid="hold-standalone" /></Row>
      <Row label="inAlert (fallback always visible)"><HoldToConfirm mode="inAlert" label="Hold to turn on 18+" icon="age-gate" fallbackLabel="Turn on 18+" onConfirm={() => setMode((c) => c + 1)} data-testid="hold-inalert" /></Row>
      <Row label="disabled"><HoldToConfirm mode="standalone" label="Hold to delete" onConfirm={() => {}} onRequestConfirm={() => {}} disabled /></Row>
      <Row label="preview 60 %"><HoldToConfirm mode="standalone" label="Hold to delete" onConfirm={() => {}} onRequestConfirm={() => {}} previewLevel={0.6} /></Row>
      <p className="gal-readout" data-testid="hold-readout">requestConfirm {clicks} · confirmed {confirms} · inAlert confirmed {mode}</p>
    </Grounds>
  );
}

export function IconButtonsSection() {
  const [on, setOn] = useState<Record<string, boolean>>({ fav: false, pin: true, dl: false });
  const t = (k: string) => () => setOn((o) => ({ ...o, [k]: !o[k] }));
  return (
    <>
      <Grounds title="nav, plain, row">
        {(["nav", "plain", "row"] as const).map((v) => (
          <Row key={v} label={v}>
            <IconButton variant={v} icon="caret-left" label="Back" />
            {STATES.map((s) => <IconButton key={s} variant={v} icon="share" label={`Share ${s}`.replace(/^Share (\w+)$/, "Share") } tooltipLevel="bar" forceState={s === "hover" || s === "pressed" || s === "focus" ? s : undefined} disabled={s === "disabled"} disabledReason="Not available offline" loading={s === "loading"} pressed={s === "selected" ? true : undefined} error={s === "error" ? "Couldn't share" : undefined} />)}
          </Row>
        ))}
      </Grounds>
      <Grounds title="Constant-label toggles (aria-pressed, fixed names)">
        <Row label="favourite / pin / downloaded"><IconButton variant="plain" icon="star" label="Favourite" pressed={on.fav} tone="streak" onPress={t("fav")} data-testid="ib-fav" /><IconButton variant="plain" icon="push-pin" label="Pin source" pressed={on.pin} onPress={t("pin")} /><IconButton variant="plain" icon="droplet" label="Downloaded" pressed={on.dl} tone="success" onPress={t("dl")} /></Row>
        <Row label="nav toggles on glass"><IconButton icon="bookmark-simple" label="Bookmark" pressed={on.fav} tone="iris" onPress={t("fav")} /><IconButton icon="bell-ringing" label="Notify me" pressed={on.pin} onPress={t("pin")} /></Row>
        <Row label="badged"><IconButton icon="bell" label="Updates" badge={4} /><IconButton variant="plain" icon="bell" label="Updates, plain" badge={12} /></Row>
        <Row label="back with a long press (450 ms, 500 ms on touch)"><IconButton icon="caret-left" label="Back" onLongPress={() => {}} /></Row>
      </Grounds>
      <Grounds title="GlassGroup (one live surface)">
        <Row label="2, 3, 4 icons"><GlassGroup label="Reader actions"><IconButton variant="group" icon="bookmark-simple" label="Bookmark" /><IconButton variant="group" icon="share" label="Share" /></GlassGroup><GlassGroup label="Three"><IconButton variant="group" icon="star" label="Favourite" pressed tone="streak" /><IconButton variant="group" icon="push-pin" label="Pin" /><IconButton variant="group" icon="dots-three" label="More" /></GlassGroup></Row>
      </Grounds>
    </>
  );
}

export function InputsSection() {
  const [shake, setShake] = useState(0);
  return (
    <Grounds title="Wells: never glass" columns={3}>
      <Row label="text"><TextField label="Username" placeholder="yash" name="username" helper="Lowercase letters and numbers" data-testid="tf-text" /></Row>
      <Row label="states"><TextField label="Hover" forceState="hover" placeholder="hover" /><TextField label="Focus" forceState="focus" placeholder="focus" /><TextField label="Disabled" disabled placeholder="disabled" /><TextField label="Loading" loading placeholder="loading" /></Row>
      <Row label="error (aria-invalid, aria-describedby, shake)"><TextField label="Email" error="Enter a valid email" shakeKey={shake} data-testid="tf-error" /><Button size="S" label="Submit" onPress={() => setShake((s) => s + 1)} /></Row>
      <Row label="password"><TextField type="password" label="Password" defaultValue="hunter2" data-testid="tf-password" /></Row>
      <Row label="url"><TextField type="url" label="Source URL" placeholder="https://" status="validating" /><TextField type="url" label="Reachable" defaultValue="https://example.org" status="reachable" /></Row>
      <Row label="number / go-to"><TextField type="number" placeholder="142" onGo={() => {}} /></Row>
      <Row label="text area (3 to 8 rows, counter, Enter submits)"><TextArea label="Prompt" placeholder="Ask about a series" maxLength={200} submitOnEnter data-testid="ta" /><TextArea label="Notes" defaultValue={"line\n".repeat(4)} helper="Grows to 8 rows, then scrolls" /></Row>
      <Row label="on glass (wellOnGlass)"><GlassSurface tier="t4" style={{ padding: 16, borderRadius: 24, width: "100%" }}><TextField label="Rename" defaultValue="Weekend reads" /></GlassSurface></Row>
    </Grounds>
  );
}

export function SearchSection() {
  const [q, setQ] = useState("");
  return (
    <Grounds title="Search fields" note="The bottom field is fixed above the keyboard in screens; shown inline here.">
      <Row label="page"><SearchField variant="page" onQuery={setQ} data-testid="sf-page" /></Row>
      <Row label="bottom (inline)"><SearchField variant="bottom" inline /></Row>
      <Row label="filter"><SearchField variant="filter" placeholder="Filter" /></Row>
      <Row label="sidebar"><SearchField variant="sidebar" onOpenPalette={() => {}} /></Row>
      <Row label="searching / offline"><SearchField variant="page" status="searching" /><SearchField variant="page" status="offline" /></Row>
      <p className="gal-readout">query: {q}</p>
    </Grounds>
  );
}

export function ChipsSection() {
  const [sel, setSel] = useState<Record<string, boolean>>({ a: true });
  const [choice, setChoice] = useState("all");
  const [tags, setTags] = useState(["Action", "Fantasy", "Romance"]);
  return (
    <Grounds title="Chips">
      <Row label="filter"><ChipRow label="Filters">{["a", "b", "c", "d", "e", "f", "g", "h"].map((k) => <Chip key={k} label={`Filter ${k.toUpperCase()}`} glyph="star" selected={!!sel[k]} onPress={() => setSel((s) => ({ ...s, [k]: !s[k] }))} />)}</ChipRow></Row>
      <Row label="choice (shared droplet)"><ChipRow label="Status" choice={{ options: [{ value: "all", label: "All" }, { value: "reading", label: "Reading" }, { value: "done", label: "Completed" }], value: choice, onChange: setChoice }} /></Row>
      <Row label="count"><Chip kind="count" label="Pinned" count={4} /><Chip kind="count" label="With results" count={12} selected /><Chip kind="count" label="Loading" count={0} loading /></Row>
      <Row label="input (removable)"><ChipRow label="Genres">{tags.map((t) => <Chip key={t} kind="input" label={t} onRemove={() => setTags((x) => x.filter((y) => y !== t))} />)}</ChipRow></Row>
      <Row label="assist"><Chip kind="assist" label="Next 10" glyph="plus" /><Chip kind="assist" label="All unread" /></Row>
      <Row label="tag"><Chip kind="tag" label="Action" /><Chip kind="tag" label="Ongoing" href="#tags" /></Row>
      <Row label="states"><Chip label="hover" forceState="hover" /><Chip label="pressed" forceState="pressed" /><Chip label="focus" forceState="focus" /><Chip label="disabled" disabled /><Chip label="error" error="This filter is unavailable" /></Row>
    </Grounds>
  );
}

function SegmentedError() {
  const [v, setV] = useState("a");
  const [err, setErr] = useState(false);
  return (
    <Segmented label="Failing save" error={err} options={[{ value: "a", label: "Public" }, { value: "b", label: "Private" }]} value={v} data-testid="seg-error"
      onChange={(n) => { setV(n); setErr(true); setTimeout(() => { setV("a"); setErr(false); }, 1200); }} />
  );
}

export function SegmentedSection() {
  const [v, setV] = useState("a");
  const [s, setS] = useState("all");
  return (
    <Grounds title="Segmented control" note="Drag the thumb: it becomes transient glass (one live T1 surface) while dragged.">
      <Row label="2 segments"><Segmented label="Sort" options={[{ value: "a", label: "Recent" }, { value: "b", label: "A to Z" }]} value={v} onChange={setV} data-testid="seg-2" /></Row>
      <Row label="4 segments (radiogroup)"><Segmented label="Density" options={[{ value: "a", label: "Cozy" }, { value: "b", label: "Compact" }, { value: "c", label: "List" }, { value: "d", label: "Tiny" }]} value={v} onChange={setV} data-testid="seg-4" /></Row>
      <Row label="tabs, compact"><Segmented label="Panels" as="tabs" compact options={[{ value: "a", label: "Chapters" }, { value: "b", label: "About" }, { value: "c", label: "Notes" }]} value={v} onChange={setV} /></Row>
      <Row label="states"><Segmented label="Loading" loading options={[{ value: "a", label: "One" }, { value: "b", label: "Two" }]} value="a" onChange={() => {}} /><Segmented label="Disabled" disabled options={[{ value: "a", label: "One" }, { value: "b", label: "Two" }]} value="a" onChange={() => {}} /></Row>
      <Row label="error (thumb springs back on tick)"><SegmentedError /></Row>
      <Row label="dragging (glass shown)"><Segmented label="Dragging" forceDragging options={[{ value: "a", label: "One" }, { value: "b", label: "Two" }, { value: "c", label: "Three" }]} value="b" onChange={() => {}} /></Row>
      <Row label="vertical scopes (220 px column)"><Segmented label="Scope" orientation="vertical" options={[{ value: "all", label: "Everything" }, { value: "series", label: "Series" }, { value: "sources", label: "Sources" }, { value: "dialogue", label: "Dialogue" }]} value={s} onChange={setS} data-testid="seg-vertical" /></Row>
    </Grounds>
  );
}

export function CardsSection() {
  return (
    <>
      <Grounds title="Series, result, history">
        <Row label="series card"><div style={{ width: 124 }}><SeriesCard title="Solo Leveling" src={cover(0)} meta="Ch 143 · Reading" newCount={3} /></div><div style={{ width: 124 }}><SeriesCard title="Tower of God" src={cover(1)} meta="Ch 12" loading /></div></Row>
        <Row label="result card"><ResultCard title="Lookism" src={cover(4)} source="MangaSource" /><ResultCard title="Eleceed" src={cover(5)} source="MangaSource" hideSource /></Row>
        <Row label="history tile"><HistoryTile title="Nano Machine" src={cover(6)} progress={0.42} orbText="42 %" meta="Ch 12 · 3 h ago" onOpen={() => {}} /></Row>
      </Grounds>
      <Grounds title="Continue stack, world card">
        <Row label="continue"><ContinueStack title="Solo Leveling" cover={cover(0)} nextThumb={cover(1)} chapter={142} page={18} pageCount={40} onContinue={() => {}} onMore={() => {}} onPreviouslyOn={() => {}} /></Row>
        <Row label="unopened next chapter"><ContinueStack title="Solo Leveling" cover={cover(0)} nextThumb={cover(1)} chapter={143} page={0} pageCount={0} onContinue={() => {}} /></Row>
        <Row label="world: available"><WorldCard variant="available" title="The Beginning After The End" cover={cover(2)} kind="Manhwa" status="Ongoing" chapters={120} rating={8.4} tags={["Action", "Fantasy", "Isekai"]} why="Because you read Solo Leveling" source="MangaSource" moreSources={2} /></Row>
        <Row label="world: info-only"><WorldCard variant="info" title="Berserk" cover={cover(3)} kind="Manga" status="Ongoing" chapters={380} rating={9.4} tags={["Dark"]} site="Wikipedia" /></Row>
      </Grounds>
      <Grounds title="Stat, collection, notification, source row">
        <Row label="stat cards"><div style={{ width: 160 }}><StatCard icon="flame" value="12" label="Day streak" series={[2, 4, 3, 6, 5, 8, 7]} /></div><div style={{ width: 160 }}><StatCard icon="book-open" value="1,204" label="Pages read" /></div></Row>
        <Row label="collection"><CollectionCard name="Weekend reads" count={12} covers={[cover(0), cover(1), cover(2), cover(3)]} onOpen={() => {}} /><CollectionCard name="Opened fan" count={4} covers={[cover(4), cover(5), cover(6)]} onOpen={() => {}} fanOpen /></Row>
        <Row label="notification"><NotificationCard title="Solo Leveling" cover={cover(0)} chapters={[141, 142, 143]} time="2 h ago" onOpen={() => {}} onChapter={() => {}} /></Row>
        <Row label="source rows"><SourceRowCard id="ms" name="MangaSource" description="Large catalogue, fast updates" language="en" health="ok" pinned onPin={() => {}} onOpen={() => {}} /><SourceRowCard id="zz" name="Zeta Scans" description="Fan translations" health="failing" demoted mature pinned={false} onPin={() => {}} onOpen={() => {}} /><SourceRowCard id="qq" name="Quiet" description="Hidden" health="dead" pinned={false} onPin={() => {}} onOpen={() => {}} disabled disabledReason="Not on this device" /></Row>
        <Row label="beads and monograms">{(["ok", "failing", "dead", "unknown"] as const).map((h) => <HealthBead key={h} health={h} />)}<HealthBead health="ok" demoted /><SourceMonogram id="alpha" name="Alpha" /><SourceMonogram id="beta" name="Beta" /></Row>
      </Grounds>
      <Grounds title="Card states">
        <Row label="selected / disabled / error"><div style={{ width: 124 }}><SeriesCard title="Selected" src={cover(7)} selectMode selected /></div><div style={{ width: 124 }}><SeriesCard title="Disabled" src={cover(8)} disabled disabledReason="Source unavailable" /></div><div style={{ width: 124 }}><SeriesCard title="Cover failed" error /></div></Row>
      </Grounds>
    </>
  );
}

export function PostersSection() {
  const [log, setLog] = useState("");
  return (
    <>
      <Grounds title="Poster overlays and states" note="Hover (desktop): tilt, specular, star and bell replace the tag and badge; rest 600 ms for the peek. Touch: press 150 ms to lift, 450 ms preview, throw up to open.">
        <Row label="default, new, downloaded, favourite, progress"><Poster title="Solo Leveling" src={cover(0)} status="reading" newCount={3} downloaded progress={0.4} onOpen={() => setLog("open")} onContextPreview={() => setLog("context preview")} onThrowOpen={() => setLog("throw open")} allowAway onThrowAway={() => setLog("not interested")} peek="Continue Ch 12" data-testid="poster-main" /><Poster title="Tower of God" src={cover(1)} status="completed" favourite mature /></Row>
        <Row label="18+ gate, select mode, disabled"><Poster title="Locked" src={cover(2)} mature gateLocked /><Poster title="Selected" src={cover(3)} selectMode selected /><Poster title="Disabled" src={cover(4)} disabled disabledReason="Source unavailable" /></Row>
        <Row label="loading, cover failed, pale cover"><Poster title="Loading" loading /><Poster title="Failed" error /><Poster title="Pale" src={cover(5)} lMax={0.95} /></Row>
        <Row label="peek forced"><Poster title="Peek" src={cover(6)} peek="Open" forceState="peek" /></Row>
        <p className="gal-readout" data-testid="poster-log">{log}</p>
      </Grounds>
      <Grounds title="PosterGrid" columns={1}><PosterGrid label="Grid">{COVERS.slice(0, 12).map((c, i) => <Poster key={c} title={TITLES[i % TITLES.length]} src={c} newCount={i % 4 === 0 ? 2 : undefined} />)}</PosterGrid></Grounds>
    </>
  );
}

export function RailsSection() {
  return (
    <Grounds title="Rails and RailGroup" columns={1} note="One tab stop per rail. Left and right move inside; up and down move between rails keeping the column.">
      <RailGroup label="Home rails">
        <Rail index={0} title="Continue reading" subtitle="Because you read Solo Leveling" onSeeAll={() => {}} revealKey="gallery:rails:continue">{COVERS.slice(0, 10).map((c, i) => <Poster key={c} title={TITLES[i % 8]} src={c} width={124} />)}</Rail>
        <Rail index={1} title="New this week" onSeeAll={() => {}} revealKey="gallery:rails:new">{COVERS.slice(6, 14).map((c, i) => <Poster key={c} title={TITLES[(i + 2) % 8]} src={c} width={124} newCount={i + 1} />)}</Rail>
        <Rail index={2} title="Loading row" state="loading" />
        <Rail index={3} title="Partial row" state="partial">{COVERS.slice(0, 3).map((c, i) => <Poster key={c} title={TITLES[i]} src={c} width={124} />)}</Rail>
        <Rail index={4} title="Failed row" state="error" onRetry={() => {}} />
      </RailGroup>
    </Grounds>
  );
}

export function SkeletonsSection() {
  const ref = useRef<HTMLDivElement>(null);
  const [n, setN] = useState(0);
  useWave(ref, "top-left", n);
  return (
    <Grounds title="Wet glass skeletons and the entrance wave">
      <Row label="shapes"><Skeleton shape="poster" width={100} /><Skeleton shape="line" width={160} /><Skeleton shape="circle" width={44} /><Skeleton shape="card" width={180} height={96} /><Skeleton shape="line" width={160} ai row={2} /></Row>
      <Row label="list, phase offset 60 ms per row"><div style={{ display: "grid", gap: 8, width: "100%" }}>{[0, 1, 2, 3].map((i) => <Skeleton key={i} shape="line" height={44} row={i} radius={12} />)}</div></Row>
      <Row label="wave from the top-left">
        <div ref={ref} style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>{COVERS.slice(0, 8).map((c) => <div key={c} data-wave-item style={{ width: 60 }}><Poster title="x" src={c} width={60} /></div>)}</div>
        <Button size="S" label="Replay wave" onPress={() => setN((x) => x + 1)} />
      </Row>
    </Grounds>
  );
}

export function ProgressSection() {
  const [v, setV] = useState(0.4);
  return (
    <Grounds title="Progress" note="Values jump under reduced motion; LiquidProgress sloshes once on lens.">
      <Row label="linear"><Progress kind="linear" value={v} valueText={`${Math.round(v * 40)} of 40 pages saved`} label="Downloading" /></Row>
      <Row label="linear states"><Progress value={undefined} label="Loading" status="loading" /><Progress value={1} status="complete" label="Done" /><Progress value={0.5} status="paused" label="Paused" /><Progress value={0.5} status="error" label="Failed" onRetry={() => {}} /><Progress value={0.5} status="disabled" label="Off" /></Row>
      <Row label="hairline, ring 24 / 32"><Progress kind="hairline" value={v} label="Reading" /><Progress kind="ring" size={24} value={v} label="Chapter" /><Progress kind="ring" size={32} value={v} label="Chapter" /></Row>
      <Row label="LiquidProgress"><Progress kind="liquid" value={v} label="Storage" valueText={`${Math.round(v * 100)} percent used`} /><Progress kind="liquid" value={0.7} status="paused" label="Paused" /></Row>
      <Row label="spinner 10 / 12 / 16 / 24, dots"><Spinner size={10} /><Spinner size={12} /><Spinner size={16} /><Spinner size={24} /><Dots /></Row>
      <Row label="segmented"><Progress kind="segmented" label="Storage breakdown" segments={[{ value: 0.4, color: "var(--mm-color-iris500)", label: "Chapters" }, { value: 0.2, color: "var(--mm-color-success)", label: "Covers" }, { value: 0.1, color: "var(--mm-color-warning)", label: "Other" }]} /></Row>
      <Row label="drive"><Button size="S" label="Jump 15 %" onPress={() => setV(0.15)} /><Button size="S" label="Jump 90 %" onPress={() => setV(0.9)} /></Row>
      <div className="gal-readout" style={{ position: "relative", height: 44, width: 240, borderRadius: 9999, background: "var(--mm-color-fill1)" }}><LiquidProgress value={v} /></div>
    </Grounds>
  );
}

const STATUSES: StatusKey[] = ["reading", "completed", "on-hold", "plan", "dropped", "unread"];
export function BadgesSection() {
  const [n, setN] = useState(3);
  return (
    <Grounds title="Badges and markers">
      <Row label="count (pops on change)"><Badge kind="count" count={n} /><Badge kind="count" count={12} /><Badge kind="count" count={120} max={99} /><Badge kind="count" count={0} loading /><Badge kind="count" count={0} error /><Button size="S" label="+1" onPress={() => setN((x) => x + 1)} /></Row>
      <Row label="dot, new"><Badge kind="dot" /><Badge kind="new" count={3} /><Badge kind="new" count={120} /></Row>
      <Row label="status on black">{STATUSES.map((s) => <Badge key={s} kind="status" status={s} />)}</Row>
      <Row label="status on a cover"><span style={{ background: "#fff", padding: 8, display: "inline-flex", gap: 4, flexWrap: "wrap" }}>{STATUSES.map((s) => <Badge key={s} kind="status" status={s} onCover />)}</span></Row>
      <Row label="mature, source, downloaded"><Badge kind="mature" /><Badge kind="mature" glyph /><Badge kind="source" name="MangaSource" /><Badge kind="downloaded" /><Badge kind="downloaded" onCover /></Row>
      <Row label="offline, role, friend"><Badge kind="offline" text="Saved copy · 2 h" /><Badge kind="role" text="Admin" /><Badge kind="role" text="You" /><Badge kind="friend" name="Ari" /></Row>
      <p className="gal-readout">{["Solo Leveling", badgeLabel({ kind: "new", count: 3 }), badgeLabel({ kind: "downloaded" })].join(", ")}</p>
    </Grounds>
  );
}

export function AvatarsSection() {
  const presets = Object.keys(AVATAR_PRESETS) as AvatarPreset[];
  return (
    <Grounds title="Profile orbs, friend orbs and the goal ring">
      <Row label="presets at 56">{presets.map((p) => <ProfileOrb key={p} preset={p} size={56} name={p} mood="#8B5CF6" />)}</Row>
      <Row label="sizes">{ORB_SIZES.map((s) => <ProfileOrb key={s} preset="violet-spark" size={s} name={`orb ${s}`} />)}</Row>
      <Row label="friend orbs 18 / 32 / 56"><ProfileOrb preset="rose-heart" size={18} friend name="Ari" /><ProfileOrb preset="rose-heart" size={32} friend name="Ari" /><ProfileOrb preset="rose-heart" size={56} friend name="Ari" /></Row>
      <Row label="goal ring"><ProfileOrb preset="cyan-rocket" size={56} name="Yash" mood="#06B6D4"><GoalRing orbSize={56} minutes={8} goal={10} /></ProfileOrb><ProfileOrb preset="amber-coffee" size={56} name="Closed" mood="#F59E0B"><GoalRing orbSize={56} minutes={12} goal={10} /></ProfileOrb><ProfileOrb preset="emerald-cat" size={56} name="On disc" onGlass><GoalRing orbSize={56} minutes={4} goal={10} onDisc /></ProfileOrb></Row>
      <Row label="states"><ProfileOrb preset="phantom" size={56} name="press" onPress={() => {}} /><ProfileOrb preset="phantom" size={56} name="selected" selected /><ProfileOrb preset="phantom" size={56} name="loading" loading /><ProfileOrb preset="phantom" size={56} name="error" error /><ProfileOrb preset="phantom" size={56} name="disabled" disabled /><ProfileOrb preset="starlight" size={96} name="drift" drift onPress={() => {}} /></Row>
    </Grounds>
  );
}

export function TooltipsSection() {
  return (
    <Grounds title="Tooltips and keycaps" note="600 ms on hover, 150 ms for bars, none on keyboard focus; Esc closes it; it stays while the pointer rests on it.">
      <Row label="icon buttons"><IconButton icon="share" label="Share" data-testid="tip-target" /><IconButton icon="star" label="Favourite" tooltipLevel="bar" /></Row>
      <Row label="keycaps"><Keycap>Esc</Keycap><Keycap>⌘</Keycap><KeyCombos combo="mod+k" /><KeyCombos combo="shift+p" /></Row>
      <Row label="tooltip on a plain element"><Tooltip label={<span>Reorder <KeyCombos combo="alt+ArrowUp" /></span>}><button type="button" className="gal-plain" style={{ minHeight: 44, minWidth: 44, borderRadius: 12, background: "var(--mm-color-fill3)", color: "inherit", border: 0 }}><Icon name="dots-three" /></button></Tooltip></Row>
    </Grounds>
  );
}

export function RevealsSection() {
  const heads = [
    { title: "Continue reading", key: "gallery:rev:a" },
    { title: "Because you read Solo Leveling", key: "gallery:rev:b" },
    { title: "New chapters this week", key: "gallery:rev:c" },
  ];
  return (
    <div data-testid="reveals">
      <div className="gal-block"><TypedHeadline text="Good evening, Yash" typedKey="gallery:greeting" as="h1" className="type-large-title" data-testid="typed-greeting" /></div>
      <div style={{ height: 1400 }} aria-hidden="true" className="gal-note">scroll: three rail headers enter together below</div>
      <div data-testid="three-rails" style={{ display: "grid", gap: 8, minHeight: 320 }}>
        {heads.map((h) => <LetterReveal key={h.key} text={h.title} revealKey={h.key} as="h3" typeClass="type-title2" data-testid={`rail-head-${h.key.slice(-1)}`} />)}
      </div>
      <div style={{ height: 900 }} aria-hidden="true" />
      <LetterReveal text="This heading has more than sixty graphemes so it reveals one word at a time instead" as="h2" typeClass="type-title2" data-testid="long-head" />
      <div style={{ height: 200 }} aria-hidden="true" />
      <LetterReveal text="Live spotlight title" as="h2" mode="live" typeClass="type-title2" data-testid="live-head" />
    </div>
  );
}

export function CursorsSection() {
  const items: [string, string][] = [["pointer", "button"], ["not-allowed", "disabled"], ["text", "field"], ["grab", "grab"], ["ns-resize", "ns-resize"], ["zoom-in", "zoom-in"], ["zoom-out", "zoom-out"], ["none", "none"], ["all-scroll", "all-scroll"]];
  return (
    <Grounds title="Cursors (7.40)" columns={1}>
      <Row>
        {items.map(([cursor, kind]) => (
          <div key={cursor} style={{ display: "grid", justifyItems: "center", gap: 4 }}>
            {kind === "button" ? <button type="button" data-testid="cur-button" className="gal-cur">button</button>
              : kind === "disabled" ? <button type="button" disabled data-testid="cur-disabled" className="gal-cur">disabled</button>
              : kind === "field" ? <input data-testid="cur-field" className="gal-cur" defaultValue="text" aria-label="text field" />
              : <div data-testid={`cur-${kind}`} data-cursor={kind} className="gal-cur">{kind}</div>}
            <span className="gal-label">{cursor}</span>
          </div>
        ))}
      </Row>
    </Grounds>
  );
}

export const SECTIONS: { id: string; title: string; el: () => ReactNode }[] = [
  { id: "buttons", title: "Buttons", el: () => <ButtonsSection /> },
  { id: "hold", title: "Hold to confirm", el: () => <HoldSection /> },
  { id: "icon-buttons", title: "Icon buttons", el: () => <IconButtonsSection /> },
  { id: "inputs", title: "Inputs", el: () => <InputsSection /> },
  { id: "search", title: "Search fields", el: () => <SearchSection /> },
  { id: "chips", title: "Chips", el: () => <ChipsSection /> },
  { id: "segmented", title: "Segmented", el: () => <SegmentedSection /> },
  { id: "cards", title: "Cards", el: () => <CardsSection /> },
  { id: "posters", title: "Posters", el: () => <PostersSection /> },
  { id: "rails", title: "Rails", el: () => <RailsSection /> },
  { id: "skeletons", title: "Skeletons and wave", el: () => <SkeletonsSection /> },
  { id: "progress", title: "Progress", el: () => <ProgressSection /> },
  { id: "badges", title: "Badges", el: () => <BadgesSection /> },
  { id: "avatars", title: "Avatars", el: () => <AvatarsSection /> },
  { id: "tooltips", title: "Tooltips", el: () => <TooltipsSection /> },
  { id: "reveals", title: "Reveals", el: () => <RevealsSection /> },
  { id: "cursors", title: "Cursors", el: () => <CursorsSection /> },
  { id: "sheets", title: "Sheets", el: () => <SheetsSection /> },
  { id: "alerts", title: "Alerts", el: () => <AlertsSection /> },
  { id: "toasts", title: "Toasts", el: () => <ToastsSection /> },
  { id: "tabs", title: "Tabs and pager", el: () => <TabsSection /> },
  { id: "sliders", title: "Sliders", el: () => <SlidersSection /> },
  { id: "toggles", title: "Toggles and selection", el: () => <TogglesSection /> },
  { id: "menus", title: "Menus", el: () => <MenusSection /> },
  { id: "banners", title: "Banners and capsules", el: () => <BannersSection /> },
  { id: "image-viewer", title: "Image viewer", el: () => <ImageViewerSection /> },
  { id: "scroll-edges", title: "Scroll edges", el: () => <ScrollEdgesSection /> },
  { id: "pull-to-refresh", title: "Pull to refresh", el: () => <PullSection /> },
  { id: "content-mode", title: "Content mode", el: () => <ContentModeSection /> },
];
