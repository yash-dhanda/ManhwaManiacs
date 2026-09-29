"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useState, type ReactNode } from "react";
import { KeyboardProvider } from "@/lib/keyboard";
import { rankCommands, groupCommands } from "@/lib/command-palette";
import { ApiError } from "@/types/api";
import { MotionRoot } from "../motion";
import { Masthead } from "../primitives/Masthead";
import { GridOverlay } from "../primitives/layout/GridOverlay";
import { NotAvailableNotice } from "../primitives/NotAvailableNotice";
import { BannerStrip } from "../primitives/BannerStrip";
import { Button } from "../primitives/Button";
import { NotFound } from "./shell-exports";
import { RouteError } from "./shell-exports";
import { SplashView } from "../Splash";
import { CommandPaletteView } from "../shell/CommandPalette";
import { FirstRunNoteView } from "../shell/FirstRunNote";
import { groupForSheet, KeyboardSheetView } from "../shell/KeyboardSheet";
import { RunningHeadView } from "../shell/RunningHeadView";
import { SidebarView } from "../shell/SidebarView";
import { StopPressBannerView } from "../shell/StopPressBanner";
import { THUMB_TABS, ThumbIndexView } from "../shell/ThumbIndexView";
import { buildPaletteCommands } from "../shell/palette-commands";
import { ColumnWipe, Iris, bladeScaleAt } from "../shell/Overlays";
import { blades } from "../shell/wipe-geometry";
import { Section, Row } from "./parts";
import { Avatar } from "../primitives/Avatar";

const noop = () => undefined;
const F = ({ w, h, kind, label, children }: { w: number; h: number; kind: "phone" | "desktop"; label: string; children: ReactNode }) => (
  <div className="flex flex-col gap-2"><p className="type-folio text-ink-45">{label}</p><div data-shell-frame={kind} data-gallery={label.split(" ")[0]} style={{ width: w, height: h }}>{children}</div></div>
);
const counts = { updates: 3, downloads: 2 };
const none = new Set<never>();
const account = <span className="type-ui inline-flex items-center gap-2"><Avatar presetKey="film-slate" size={32} label="" />Aarav</span>;
const registry = [
  { id: "a", description: "Open or close the command palette", keys: "mod+k", group: "General" },
  { id: "b", description: "Go to notifications", keys: "alt+t", group: "General" },
  { id: "c", description: "Toggle the sidebar", keys: "mod+b", group: "General" },
  { id: "d", description: "Jump to a section: g then 1 to 12, 0 for Settings", keys: "g 1", group: "Navigation" },
  { id: "e", description: "Search the library", keys: "/", group: "Library" },
];
const palette = buildPaletteCommands({
  series: [{ id: 1, title: "Solo Leveling", chapterCount: 200, sourceId: "bato" }, { id: 2, title: "Tower of God", chapterCount: 590, sourceId: "bato" }],
  sources: [{ id: "bato", name: "Bato" }, { id: "asura", name: "Asura Scans" }], isAdmin: true, novelsEnabled: true, novelMode: false, glassAvailable: false,
  continue: { title: "Solo Leveling", href: "/library/1" },
});
const ranked = rankCommands(palette.commands, "so");
const rankedAll = rankCommands(palette.commands, "");

/** web/06 gallery: every shell state from fixture props. Development only. */
export function ShellGallery({ freezeAt }: { freezeAt?: never }) {
  const [qc] = useState(() => new QueryClient());
  const ta = { updates: 12 };
  void freezeAt; void ta;
  const wipe = (vw: number, cols: number, margin: number, gutter: number, t: number) => { const b = blades(vw, { columns: cols, margin, gutter, max: 1760 }); return <ColumnWipe blades={b} scaleAt={(i) => bladeScaleAt(i, b.length, t)} />; };
  return (
    <QueryClientProvider client={qc}>
      <KeyboardProvider>
        <MotionRoot>
          <GridOverlay />
          <main data-testid="shell-gallery" className="mx-auto max-w-[1760px] px-4 pb-32 frame:px-8 desktop:px-12">
            <Masthead folio="No. 06" section="SHELL" title="Frame" deck="The Cinematic shell, state by state." />

            <Section id="sidebar" title="Contents sidebar">
              <Row label="expanded 248">
                <F w={248} h={720} kind="desktop" label="sidebar-expanded"><SidebarView spine={false} lit="collections" counts={counts} isAdmin novelsEnabled hidden={none} onToggle={noop} /></F>
                <F w={72} h={720} kind="desktop" label="sidebar-spine 72"><SidebarView spine lit="library" counts={counts} isAdmin novelsEnabled hidden={none} onToggle={noop} /></F>
                <F w={300} h={720} kind="desktop" label="sidebar-overlay"><div style={{ position: "absolute", inset: 0, background: "var(--mm-scrim-modal)" }} /><SidebarView spine={false} overlay lit="updates" counts={counts} isAdmin={false} novelsEnabled={false} hidden={new Set(["dialogue"] as const)} onToggle={noop} /></F>
                <F w={72} h={480} kind="desktop" label="sidebar-short 480 tall"><SidebarView spine lit="tonight" counts={{}} isAdmin novelsEnabled={false} hidden={none} onToggle={noop} /></F>
              </Row>
            </Section>

            <Section id="running-head" title="Running head">
              <F w={1200} h={140} kind="desktop" label="head-desktop"><RunningHeadView crumb={{ folio: "02", section: "LIBRARY", sectionHref: "/library", tail: "SOLO LEVELING" }} solid titleVisible unread={7} offline="none" account={account} onSearch={noop} /></F>
              <F w={1200} h={200} kind="desktop" label="head-over-art scrim"><div style={{ position: "absolute", inset: 0, background: "linear-gradient(120deg, #6b2d2d, #1b2a4a 60%, #c9a24a)" }} /><RunningHeadView crumb={{ folio: "04", section: "DISCOVER", sectionHref: "/search", tail: "SOLO LEVELING" }} overArt solid={false} titleVisible unread={0} offline="edition" account={account} onSearch={noop} /></F>
              <Row label="phone">
                <F w={390} h={120} kind="phone" label="head-phone back+title"><RunningHeadView crumb={{ section: "LIBRARY" }} title="LIBRARY · UPDATES" back={{ href: "/library" }} trailing={[{ icon: "search", label: "Search" }, { icon: "filter", label: "Filter" }]} solid titleVisible unread={0} offline="none" account={null} onSearch={noop} /></F>
                <F w={390} h={120} kind="phone" label="head-phone offline"><RunningHeadView crumb={{ section: "LIBRARY" }} title="LIBRARY" solid titleVisible unread={0} offline="edition" account={null} onSearch={noop} /></F>
                <F w={390} h={120} kind="phone" label="head-phone glyph"><RunningHeadView crumb={{ section: "LIBRARY" }} title="LIBRARY" solid titleVisible unread={0} offline="glyph" account={null} onSearch={noop} /></F>
                <F w={390} h={120} kind="phone" label="head-phone back-online"><RunningHeadView crumb={{ section: "LIBRARY" }} title="LIBRARY" solid titleVisible unread={0} offline="back-online" account={null} onSearch={noop} /></F>
              </Row>
            </Section>

            <Section id="thumb" title="Thumb index">
              <Row label="each tab active, with badges">
                {THUMB_TABS.map((t) => <F key={t.id} w={390} h={100} kind="phone" label={`thumb-${t.id}`}><ThumbIndexView active={t.id} badges={{ library: 12, downloads: 120, index: 2 }} /></F>)}
              </Row>
            </Section>

            <Section id="banners" title="Stop press, first run, keyboard, palette">
              <Row label="stop press">
                <F w={640} h={120} kind="desktop" label="stop-press"><StopPressBannerView count={14} seriesCount={5} onRead={noop} onDismiss={noop} /></F>
                <F w={640} h={120} kind="desktop" label="stop-press singular"><StopPressBannerView count={1} seriesCount={1} onRead={noop} onDismiss={noop} /></F>
              </Row>
              <div data-gallery="first-run"><FirstRunNoteView onDiscover={noop} /></div>
              <div data-gallery="keyboard" className="max-w-[720px] border border-ink-30 bg-paper-3 p-6"><KeyboardSheetView groups={groupForSheet(registry)} /></div>
              <Row label="palette">
                <div className="w-[720px] max-w-full" data-gallery="palette"><CommandPaletteView query="so" onQuery={noop} groups={groupCommands(ranked)} folios={palette.folios} active={0} onActive={noop} onRun={noop} status={`${ranked.length} results`} count={ranked.length} listboxId="g1" /></div>
                <div className="w-[720px] max-w-full" data-gallery="palette-empty"><CommandPaletteView query="zzzz" onQuery={noop} groups={[]} folios={{}} active={0} onActive={noop} onRun={noop} status="0 results" count={0} listboxId="g2" /></div>
                <div className="w-[720px] max-w-full" data-gallery="palette-open"><CommandPaletteView query="" onQuery={noop} groups={groupCommands(rankedAll)} folios={palette.folios} active={2} onActive={noop} onRun={noop} status={`${rankedAll.length} results`} count={rankedAll.length} listboxId="g3" /></div>
              </Row>
            </Section>

            <Section id="status" title="Status screens and notices">
              <div data-gallery="not-found"><NotFound /></div>
              <div data-gallery="route-error"><RouteError error={new Error("boom")} reset={noop} /></div>
              <div data-gallery="route-error-offline"><RouteError error={new ApiError(0, { message: "offline" })} reset={noop} /></div>
              <Row label="not available">
                <div className="w-[560px] max-w-full" data-gallery="na-series"><NotAvailableNotice kind="series" title="Solo Leveling" /></div>
                <div className="w-[560px] max-w-full" data-gallery="na-source"><NotAvailableNotice kind="source" /></div>
                <div className="w-[560px] max-w-full" data-gallery="na-browsable"><NotAvailableNotice kind="not-browsable" sourceId="bato" /></div>
              </Row>
              <BannerStrip kicker="NOTE" tone="note" actions={<Button variant="quiet" size="sm" onClick={noop}>OK</Button>}>Fixture strip for spacing checks.</BannerStrip>
            </Section>

            <Section id="motion" title="Splash, Column wipe, Iris (frozen)">
              <Row label="splash at 0, 300, 560, 900, 1180, 1400 ms">
                {[0, 300, 560, 900, 1180, 1400].map((t) => <F key={t} w={320} h={480} kind="phone" label={`splash-${t}`}><SplashView t={t} frozen /></F>)}
              </Row>
              <Row label="column wipe: 12 blades closed / mid-open">
                <F w={1200} h={300} kind="desktop" label="wipe-close-end">{wipe(1200, 12, 48, 24, 376)}</F>
                <F w={1200} h={300} kind="desktop" label="wipe-mid-open">{wipe(1200, 12, 48, 24, 376 + 40 + 200)}</F>
                <F w={390} h={300} kind="phone" label="wipe-phone-close-end">{wipe(390, 4, 16, 12, 248)}</F>
              </Row>
              <Row label="iris mid-close">
                <F w={390} h={300} kind="phone" label="iris-mid"><Iris x={195} y={150} radius={120}><div style={{ width: 390, height: 300, background: "#1b2a4a" }} /></Iris></F>
              </Row>
            </Section>
          </main>
        </MotionRoot>
      </KeyboardProvider>
    </QueryClientProvider>
  );
}
