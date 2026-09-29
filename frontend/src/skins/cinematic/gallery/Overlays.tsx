"use client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { Badge } from "../primitives/Badge";
import { BannerStrip } from "../primitives/BannerStrip";
import { Button } from "../primitives/Button";
import { Certificate } from "../primitives/Certificate";
import { CertificateDialog } from "../primitives/CertificateDialog";
import { Checkbox } from "../primitives/Checkbox";
import { ConfirmDialog } from "../primitives/ConfirmDialog";
import { ContentModeChip } from "../primitives/ContentModeChip";
import { ContentModeToggle } from "../primitives/ContentModeToggle";
import { ContentsTabs } from "../primitives/ContentsTabs";
import { ContextMenu } from "../primitives/ContextMenu";
import { Dialog } from "../primitives/Dialog";
import { FolioFlip } from "../primitives/FolioFlip";
import { IconButton } from "../primitives/IconButton";
import { InlineConfirm } from "../primitives/InlineConfirm";
import { Lightbox } from "../primitives/Lightbox";
import { Menu } from "../primitives/Menu";
import { Notice } from "../primitives/Notice";
import { PullToReprint } from "../primitives/PullToReprint";
import { Radios } from "../primitives/Radio";
import { QuickLookTarget } from "../primitives/QuickLook";
import { Scrubber } from "../primitives/Scrubber";
import { Select } from "../primitives/Select";
import { SelectModeBar } from "../primitives/SelectModeBar";
import { Sheet } from "../primitives/Sheet";
import { Slider } from "../primitives/Slider";
import { Stepper } from "../primitives/Stepper";
import { Switch } from "../primitives/Switch";
import { ToastHost } from "../primitives/ToastHost";
import { actionItems } from "../primitives/actions";
import { commitWithUndo } from "../primitives/commitWithUndo";
import { subtitle } from "../primitives/subtitles";
import { ContentsRow } from "../primitives/rows/ContentsRow";
import { CreditsRow } from "../primitives/rows/CreditsRow";
import { ReorderList } from "../primitives/rows/ReorderList";
import { Row as ListRow } from "../primitives/rows/Row";
import { ScheduleRow } from "../primitives/rows/ScheduleRow";
import { SettingsRow } from "../primitives/rows/SettingsRow";
import { SwipeRow } from "../primitives/rows/SwipeRow";
import { moveItem } from "../primitives/rows/reorder";
import { CineImage } from "../primitives/CineImage";
import { COVER, SERIES } from "./fixtures";
import { Row, Section } from "./parts";

const NOW = Date.now();
const wait = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
const T = (id: string) => ({ "data-gallery": `w5-trigger-${id}` });

/** web/05 sections: fixture data only, triggers that open every overlay in every state, one ToastHost. */
export function OverlaySections() {
  const [sheet, setSheet] = useState<null | "plain" | "live" | "loading" | "error" | "history">(null);
  const [dlg, setDlg] = useState<null | "plain" | "confirm" | "destructive" | "pending" | "error" | "phrase" | "ack">(null);
  const [tab, setTab] = useState("chapters");
  const [sub, setSub] = useState("new");
  const [sw, setSw] = useState({ a: false, b: true, c: false, d: false });
  const [swErr, setSwErr] = useState<string | undefined>();
  const [cb, setCb] = useState<boolean | "indeterminate">(false);
  const [radio, setRadio] = useState("strip");
  const [step, setStep] = useState(3);
  const [size, setSize] = useState(19);
  const [page, setPage] = useState(18);
  const [sel, setSel] = useState<Record<string, boolean>>({});
  const [selMode, setSelMode] = useState(false);
  const [order, setOrder] = useState(SERIES.slice(0, 5).map((s) => ({ id: s.id, title: s.title })));
  const [pick, setPick] = useState("b");
  const [flag, setFlag] = useState(false);
  const [cert, setCert] = useState(false);
  const [stamp, setStamp] = useState(false);
  const [box, setBox] = useState<null | "cover" | "page" | "failed">(null);
  const [from, setFrom] = useState<DOMRect | null>(null);
  const [running, setRunning] = useState(false);
  const [reprints, setReprints] = useState(0);
  const [qc] = useState(() => new QueryClient());
  useEffect(() => { if (!swErr) return; const t = setTimeout(() => setSwErr(undefined), 2500); return () => clearTimeout(t); }, [swErr]);
  const menuItems = [
    { id: "open", label: "Open", icon: "external" as const, shortcut: "o", onSelect: () => subtitle.info("Opened.") },
    { id: "fav", label: "Favourite", icon: "favourite" as const, checked: flag, onSelect: () => setFlag((f) => !f) },
    { id: "more", label: "More", submenu: [{ id: "a", label: "Alpha" }, { id: "b", label: "Beta" }] },
    { id: "dis", label: "Unavailable", disabled: true, disabledReason: "Needs a source" },
    { id: "rm", label: "Remove", destructive: true, separatorBefore: true },
  ];
  const openBox = (kind: "cover" | "page" | "failed") => (e: React.MouseEvent<HTMLElement>) => { setFrom(e.currentTarget.getBoundingClientRect()); setBox(kind); };

  return (
    <>
      <ToastHost />

      <Section id="sheets" title="Sheets, column panels, Quick look">
        <Row label="phone frame: bottom sheet · desktop frame: column panel">
          <Button variant="secondary" onClick={() => setSheet("plain")} {...T("sheet")}>Open sheet</Button>
          <Button variant="secondary" onClick={() => setSheet("live")} {...T("sheet-live")}>Live preview</Button>
          <Button variant="secondary" onClick={() => setSheet("loading")} {...T("sheet-loading")}>Loading</Button>
          <Button variant="secondary" onClick={() => setSheet("error")} {...T("sheet-error")}>Error</Button>
          <Button variant="secondary" onClick={() => setSheet("history")} {...T("sheet-history")}>With history entry</Button>
        </Row>
        <Row label="quick look: long-press (touch) or right-click (desktop)">
          <QuickLookTarget info={{ title: SERIES[0].title, kicker: "MANHWA · ONGOING", credits: "WRITTEN BY ILSE MARROW", src: COVER(1) }}
            items={actionItems({ open: () => undefined, continue: () => undefined, "previously-on": () => undefined, favourite: () => undefined, "mark-read": () => undefined, unfollow: () => undefined })}>
            <div data-gallery="w5-quicklook-target" className="relative h-36 w-24"><CineImage src={COVER(1)} alt={SERIES[0].title} /></div>
          </QuickLookTarget>
        </Row>
        <Sheet open={sheet === "plain" || sheet === "history"} onOpenChange={(o) => !o && setSheet(null)} title="Sort chapters" kicker="CHAPTERS" historyKey={sheet === "history" ? "type" : undefined} data-gallery="w5-sheet">
          <div className="flex flex-col gap-3"><Button variant="secondary">First control</Button><p className="type-body text-ink-60">Sheet body. Tab stays inside; Escape closes and returns focus to the trigger.</p><Button variant="quiet">Another</Button></div>
        </Sheet>
        <Sheet open={sheet === "live"} onOpenChange={(o) => !o && setSheet(null)} title="Type" kicker="READER" livePreview data-gallery="w5-sheet-live">
          <Slider label="Text size" min={12} max={28} value={size} onValueChange={setSize} format={(v) => `${v} px`} />
        </Sheet>
        <Sheet open={sheet === "loading"} onOpenChange={(o) => !o && setSheet(null)} title="Voices" kicker="LISTEN" loading data-gallery="w5-sheet-loading" />
        <Sheet open={sheet === "error"} onOpenChange={(o) => !o && setSheet(null)} title="Voices" kicker="LISTEN" error={<Notice tone="error" headline="Voices did not load." deck="Check your connection and try again." primary={{ label: "Retry", onPress: () => undefined }} />} data-gallery="w5-sheet-error" />
      </Section>

      <Section id="dialogs" title="Dialogs and the destructive arm">
        <Row label="dialog · confirm · destructive (arm 1000 ms) · pending · error · heavy phrase · heavy acknowledge">
          <Button variant="secondary" onClick={() => setDlg("plain")} {...T("dialog")}>Dialog</Button>
          <Button variant="secondary" onClick={() => setDlg("confirm")} {...T("confirm")}>Confirm</Button>
          <Button variant="destructive" onClick={() => setDlg("destructive")} {...T("destructive")}>Remove series</Button>
          <Button variant="destructive" onClick={() => setDlg("pending")} {...T("pending")}>Pending</Button>
          <Button variant="destructive" onClick={() => setDlg("error")} {...T("error")}>Fails</Button>
          <Button variant="destructive" onClick={() => setDlg("phrase")} {...T("phrase")}>Restore backup</Button>
          <Button variant="destructive" onClick={() => setDlg("ack")} {...T("ack")}>Sign out everywhere</Button>
        </Row>
        <Row label="inline confirm (4 s revert) · undo commit">
          <InlineConfirm verb="Delete" onConfirm={() => subtitle.info("Deleted.")} data-gallery="w5-inline-confirm" />
          <Button variant="secondary" {...T("undo")} onClick={() => commitWithUndo({ run: () => undefined, undo: () => undefined, message: `Removed ${SERIES[2].title}.` })}>Unfollow with undo</Button>
        </Row>
        <Dialog open={dlg === "plain"} onOpenChange={(o) => !o && setDlg(null)} title="Sign in again?" description="Your session ended. Sign in to keep reading." data-gallery="w5-dialog"
          actions={<><Button variant="quiet" onClick={() => setDlg(null)}>Cancel</Button><Button onClick={() => setDlg(null)}>Sign in</Button></>} />
        <ConfirmDialog open={dlg === "confirm"} onOpenChange={(o) => !o && setDlg(null)} title="Mark all read?" description="Every chapter in this series will be marked read." confirmLabel="Mark all read" onConfirm={() => wait(300)} data-gallery="w5-confirm" />
        <ConfirmDialog open={dlg === "destructive"} onOpenChange={(o) => !o && setDlg(null)} destructive title="Remove Salt and Iron?" description="It leaves your library and its reading progress is deleted." confirmLabel="Remove" onConfirm={() => wait(300)} data-gallery="w5-confirm-destructive" />
        <ConfirmDialog open={dlg === "pending"} onOpenChange={(o) => !o && setDlg(null)} destructive pending title="Remove everything?" description="Working…" confirmLabel="Remove" onConfirm={() => wait(60_000)} data-gallery="w5-confirm-pending" />
        <ConfirmDialog open={dlg === "error"} onOpenChange={(o) => !o && setDlg(null)} destructive error="The server did not accept that. Nothing was removed." title="Remove Ember Ledger?" confirmLabel="Remove" onConfirm={() => wait(100)} data-gallery="w5-confirm-error" />
        <ConfirmDialog open={dlg === "phrase"} onOpenChange={(o) => !o && setDlg(null)} destructive typedPhrase="RESTORE" title="Restore this backup?" description="Type RESTORE to confirm. Your current library is replaced." confirmLabel="Restore" onConfirm={() => wait(300)} data-gallery="w5-confirm-phrase" />
        <ConfirmDialog open={dlg === "ack"} onOpenChange={(o) => !o && setDlg(null)} destructive acknowledge="I understand this signs me out on this device too" title="Sign out everywhere?" confirmLabel="Sign out" onConfirm={() => wait(300)} data-gallery="w5-confirm-ack" />
      </Section>

      <Section id="toasts" title="Subtitles">
        <Row label="info · success · error · action · undo">
          <Button variant="secondary" {...T("toast-info")} onClick={() => subtitle.info("Library updated.")}>Info</Button>
          <Button variant="secondary" {...T("toast-success")} onClick={() => subtitle.success("Saved 5 chapters.")}>Success</Button>
          <Button variant="secondary" {...T("toast-error")} onClick={() => subtitle.error("Could not reach the source. Try again in a moment.")}>Error</Button>
          <Button variant="secondary" {...T("toast-action")} onClick={() => subtitle.action("Chapter 143 is ready.", { label: "View", onAction: () => undefined })}>Action</Button>
          <Button variant="secondary" {...T("toast-undo")} onClick={() => subtitle.undo("Skin changed.", () => undefined, { holdMs: 10_000 })}>Undo</Button>
          <Button variant="secondary" {...T("toast-three")} onClick={() => { subtitle.info("First."); subtitle.info("Second."); subtitle.info("Third."); }}>Three at once</Button>
        </Row>
      </Section>

      <Section id="tabs" title="Contents tabs">
        <ContentsTabs value={tab} onValueChange={setTab} label="Series sections" data-gallery="w5-tabs"
          tabs={[
            { id: "chapters", folio: "01", label: "Chapters", count: 201, panel: <p className="type-body p-4 text-ink-60">Chapter list panel.</p> },
            { id: "details", folio: "02", label: "Details", panel: <p className="type-body p-4 text-ink-60">Details panel.</p> },
            { id: "more", folio: "03", label: "More like this", count: "loading", panel: <p className="type-body p-4 text-ink-60">Recommendations panel.</p> },
            { id: "circle", folio: "04", label: "Circle", disabled: true, disabledReason: "Sharing is off", count: "error" },
          ]} />
        <ContentsTabs pager={false} value={sub} onValueChange={setSub} label="Updates" shortcutGroup="Updates" data-gallery="w5-tabs-nested"
          tabs={[{ id: "new", folio: "01", label: "New", panel: <p className="type-body p-4 text-ink-60">New.</p> }, { id: "following", folio: "02", label: "Following", panel: <p className="type-body p-4 text-ink-60">Following.</p> }]} />
      </Section>

      <Section id="rows" title="Lists and rows">
        <div className="max-w-3xl">
          <ListRow leadingIcon="settings" title="Reading" caption="Layout, direction and pace" chevron menu={actionItems({ open: () => undefined, favourite: () => undefined })} data-gallery="w5-row-standard" />
          <ListRow leading={<div className="relative h-[60px] w-10 shrink-0"><CineImage src={COVER(2)} alt="" /></div>} title="Ember Ledger" caption="88 CHAPTERS" trailing="CH 12" data-gallery="w5-row-cover" onClick={() => undefined} />
          <ListRow title="Selected row" selected data-gallery="w5-row-selected" />
          <ListRow title="Disabled row" disabled caption="Needs a source" />
          <ListRow title="Loading row" loading />
          <ListRow title="Error row" error="Could not load this series." onRetry={() => undefined} />
          <ListRow title="Current chapter" current caption="You are here" />
          <SettingsRow label="Notifications" description="New chapters of series you follow" control={<Switch label="Notifications" hideLabel checked={sw.c} onCheckedChange={(v) => setSw((s) => ({ ...s, c: v }))} />} data-gallery="w5-row-settings" />
          <SettingsRow label="Download quality" value="HIGH" chevron onClick={() => undefined} />
          <ScheduleRow number={143} title="Chapter 143: The tide table" released={new Date(NOW)} pages={27} page={14} data-gallery="w5-row-schedule" />
          <ScheduleRow number={142} title="The last ferry" released={new Date(NOW - 86_400_000)} pages={31} complete />
          <ScheduleRow number={null} title="Extra: character sheet" released={new Date(NOW - 3 * 86_400_000)} />
          <ContentsRow ordinal={12} title="The Salt Road" minutes={12} progress={42} narrated data-gallery="w5-row-contents" />
          <ContentsRow ordinal={11} title="A Harbour at Night" minutes={9} read />
          <CreditsRow label="Written by" value="Ilse Marrow" />
        </div>
        <Row label="swipe (touch) · reorder (handle, Alt+Up/Down, row menu) · select mode">
          <div className="w-full max-w-xl"><SwipeRow action="remove" onCommit={() => subtitle.info("Removed.")}><ListRow title="Swipe me" caption="Touch only" /></SwipeRow></div>
          <div className="w-full max-w-xl" data-gallery="w5-reorder">
            <ReorderList label="Collection order" items={order} onMove={(f, t) => setOrder((o) => moveItem(o, f, t))}
              renderRow={(it, { handle, moveMenu }) => <ListRow title={it.title} menu={moveMenu} end={handle} />} />
          </div>
          <div className="w-full max-w-xl">
            <Button variant="secondary" {...T("select-mode")} onClick={() => setSelMode((m) => !m)}>{selMode ? "Leave select mode" : "Select mode"}</Button>
            {SERIES.slice(0, 4).map((s) => <ListRow key={s.id} title={s.title} selectMode={selMode} selected={!!sel[s.id]} onSelectedChange={(v) => setSel((x) => ({ ...x, [s.id]: v }))} onClick={() => undefined} />)}
          </div>
        </Row>
        {selMode ? <SelectModeBar selected={Object.values(sel).filter(Boolean).length} total={4} onSelectAll={() => setSel(Object.fromEntries(SERIES.slice(0, 4).map((s) => [s.id, true])))} onDone={() => { setSelMode(false); setSel({}); }}
          running={running ? { done: 4, total: 12, failed: 1, onStop: () => setRunning(false) } : undefined}
          actions={[{ id: "fav", label: "Favourite", icon: "favourite", onPress: () => setRunning(true) }, { id: "dl", label: "Download", icon: "download", onPress: () => undefined }, { id: "unf", label: "Unfollow", icon: "following", destructive: true, onPress: () => setDlg("destructive") }]} data-gallery="w5-select-bar" /> : null}
      </Section>

      <Section id="sliders" title="Sliders and the scrubber">
        <div className="grid max-w-xl gap-8">
          <Slider label="Text size" min={12} max={28} value={size} onValueChange={setSize} format={(v) => `${v} px`} minCaption="12" maxCaption="28" data-gallery="w5-slider" />
          <Scrubber label="Page" min={1} max={40} value={page} onValueChange={setPage} valueText={(v) => `Page ${v} of 40`} format={(v) => `p.${v}`} chapterOf={(p) => Math.floor((p - 1) / 10)} data-gallery="w5-scrubber" />
          <Slider label="Disabled" min={0} max={10} value={4} onValueChange={() => undefined} disabled data-gallery="w5-slider-disabled" />
        </div>
      </Section>

      <Section id="toggles" title="Switches, checkboxes, radios, steppers">
        <Row label="switch: off · on · loading · disabled · error">
          <Switch label="Off" checked={sw.a} onCheckedChange={(v) => setSw((s) => ({ ...s, a: v }))} data-gallery="w5-switch" />
          <Switch label="On" checked={sw.b} onCheckedChange={(v) => setSw((s) => ({ ...s, b: v }))} />
          <Switch label="Saving" checked loading onCheckedChange={() => undefined} data-gallery="w5-switch-loading" />
          <Switch label="Locked" checked={false} disabled onCheckedChange={() => undefined} />
          <Switch label="Server fails" checked={sw.d} error={swErr} onCheckedChange={() => setSwErr("Could not save. Try again.")} data-gallery="w5-switch-error" />
        </Row>
        <Row label="checkbox: off · on · indeterminate · disabled">
          <Checkbox label="Remember me" checked={cb === true} onCheckedChange={setCb} data-gallery="w5-checkbox" />
          <Checkbox label="Some" checked="indeterminate" onCheckedChange={() => undefined} />
          <Checkbox label="Disabled" checked={false} disabled onCheckedChange={() => undefined} />
        </Row>
        <Row label="radios"><Radios label="Layout" value={radio} onValueChange={setRadio} options={[{ value: "strip", label: "Strip" }, { value: "single", label: "Single page" }, { value: "double", label: "Double page", disabled: true }]} data-gallery="w5-radios" /></Row>
        <Row label="stepper (Folio flip)"><Stepper label="Chapters ahead" value={step} onChange={setStep} min={0} max={12} data-gallery="w5-stepper" /><FolioFlip value={step * 11} /></Row>
      </Section>

      <Section id="menus" title="Menus, context menus, select">
        <Row label="menu · context menu (right-click) · select">
          <Menu trigger={<IconButton label="More actions" icon="overflow" data-gallery="w5-menu-trigger" />} items={menuItems} data-gallery="w5-menu" />
          <ContextMenu items={menuItems} data-gallery="w5-context-target"><div className="type-ui border border-rule-2 px-8 py-6 text-ink-60">Right-click here</div></ContextMenu>
          <div className="w-64"><Select label="Sort by" value={pick} onValueChange={setPick} options={[{ value: "a", label: "Alphabetical" }, { value: "b", label: "Last read" }, { value: "c", label: "Unread first" }]} data-gallery="w5-select" /></div>
        </Row>
      </Section>

      <Section id="notices" title="Notices">
        <div className="grid gap-12 frame:grid-cols-2">
          <Notice tone="empty" headline="Nothing on this shelf yet." deck="Follow a series and it appears here." primary={{ label: "Browse", onPress: () => undefined }} data-gallery="w5-notice-empty" />
          <Notice tone="error" headline="That did not load." deck="The source did not answer." primary={{ label: "Retry", onPress: () => undefined }} quiet={{ label: "Report", onPress: () => undefined }} data-gallery="w5-notice-error" />
          <Notice tone="offline" headline="You are offline." offlinePreset data-gallery="w5-notice-offline" />
          <Notice tone="caution" headline="This source is slow today." deck="Chapters may take longer to open." data-gallery="w5-notice-caution" />
          <Notice tone="rateLimit" headline="Too many requests." deck="The server asked us to wait." retryAfterMs={12000} data-gallery="w5-notice-rate" />
          <Button variant="secondary" {...T("busy")} onClick={() => window.dispatchEvent(new CustomEvent("mm:db-busy"))}>Simulate db_busy</Button>
        </div>
      </Section>

      <Section id="certificate" title="The certificate">
        <Row label="mark · stamp · dialog"><Certificate stamped={stamp} /><Badge variant="certificate" large />
          <Button variant="secondary" {...T("stamp")} onClick={() => { setStamp(true); setTimeout(() => setStamp(false), 400); }}>Stamp</Button>
          <Button variant="secondary" {...T("certificate")} onClick={() => setCert(true)}>Open certificate dialog</Button></Row>
        <CertificateDialog open={cert} onOpenChange={setCert} profileName="Riya" onConfirm={() => wait(500)} onCancel={() => undefined} data-gallery="w5-certificate-dialog" />
      </Section>

      <Section id="other" title="Content mode, pull to reprint, banners">
        <QueryClientProvider client={qc}><Row label="content mode (renders nothing when novels are off)"><ContentModeToggle /><ContentModeChip /></Row></QueryClientProvider>
        <Row label="pull to reprint (touch)"><PullToReprint onRefresh={async () => { await wait(1200); setReprints((n) => n + 1); }} className="w-full max-w-md border border-rule-1"><p className="type-body p-6 text-ink-60">{`Pull down here on a touch device. Reprints: ${reprints}`}</p></PullToReprint></Row>
        <div className="flex max-w-3xl flex-col gap-2">
          <BannerStrip kicker="FIRST RUN" actions={<Button variant="quiet" size="sm">Browse</Button>} data-gallery="w5-banner">Nothing followed yet.</BannerStrip>
          <BannerStrip tone="error" kicker="OVERDUE">The checker has not run since Monday.</BannerStrip>
          <BannerStrip tone="success" kicker="RESTORED">Your backup is staged.</BannerStrip>
        </div>
      </Section>

      <Section id="lightbox" title="Lightbox">
        <Row label="double-click (desktop) or long-press (touch) the cover · page · failed image">
          <button type="button" onDoubleClick={openBox("cover")} onClick={openBox("cover")} data-gallery="w5-lightbox-cover" className="relative h-48 w-32 cursor-zoom-in"><CineImage src={COVER(1)} alt="Salt and Iron cover" /></button>
          <Button variant="secondary" {...T("lightbox-page")} onClick={openBox("page")}>Open page image</Button>
          <Button variant="secondary" {...T("lightbox-failed")} onClick={openBox("failed")}>Failed full image</Button>
        </Row>
        <Lightbox open={box !== null} onOpenChange={(o) => !o && setBox(null)} from={from} title="Salt and Iron" kind={box === "page" ? "page" : "cover"} page={18}
          src={box === "failed" ? "/gallery/covers/missing.webp" : COVER(1)} thumbSrc={COVER(1)} naturalW={box === "page" ? 800 : 720} naturalH={box === "page" ? 1200 : 1080} data-gallery="w5-lightbox" />
      </Section>
    </>
  );
}
