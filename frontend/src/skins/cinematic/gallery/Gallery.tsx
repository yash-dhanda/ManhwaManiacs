"use client";
import { useState, type ReactNode } from "react";
import { KeyboardProvider } from "@/lib/keyboard";
import { useDuotone } from "../duotone";
import { Grain } from "../Grain";
import { MotionRoot } from "../motion";
import { Avatar } from "../primitives/Avatar";
import { AVATAR_PRESETS } from "../primitives/avatar-presets";
import { Badge, readingStatusLabel } from "../primitives/Badge";
import { Button } from "../primitives/Button";
import { CineImage } from "../primitives/CineImage";
import { IconButton } from "../primitives/IconButton";
import { Keycap } from "../primitives/Keycap";
import { Credits } from "../primitives/layout/Credits";
import { Grid } from "../primitives/layout/Grid";
import { GridOverlay } from "../primitives/layout/GridOverlay";
import { Measure } from "../primitives/layout/Measure";
import { Spread } from "../primitives/layout/Spread";
import { Masthead } from "../primitives/Masthead";
import { NumberField } from "../primitives/NumberField";
import { PasswordField } from "../primitives/PasswordField";
import { Poster } from "../primitives/Poster";
import { CountdownDial, DownloadMark, FolioCounter, IndeterminateRule, LeaderDial, PosterProgress, RuleProgress, StorageMeter, type DownloadState } from "../primitives/Progress";
import { Rail, type RailItem } from "../primitives/Rail";
import { SearchField } from "../primitives/SearchField";
import { SectionHeader } from "../primitives/SectionHeader";
import { SegmentedControl } from "../primitives/SegmentedControl";
import { SetHeading } from "../primitives/SetHeading";
import { GalleyHeadline, GalleyLine, GalleyNumeral, GalleyPlate } from "../primitives/Skeleton";
import { SlugLines, SlugToken } from "../primitives/SlugLines";
import { TextField } from "../primitives/TextField";
import { Textarea } from "../primitives/Textarea";
import { TriStateFilter, type TriState } from "../primitives/TriStateFilter";
import { TypedHeadline } from "../primitives/TypedHeadline";
import { CollectionPlate } from "../primitives/cards/CollectionPlate";
import { CuttingCard } from "../primitives/cards/CuttingCard";
import { FeatureCard } from "../primitives/cards/FeatureCard";
import { LetterCard } from "../primitives/cards/LetterCard";
import { StatBlock } from "../primitives/cards/StatBlock";
import { WorldCard } from "../primitives/cards/WorldCard";
import { COVER, CREDITS, DUOS, HEADLINE_40, LONG_LIST, SERIES } from "./fixtures";

function Section({ id, title, children }: { id: string; title: string; children: ReactNode }) {
  return (
    <section id={id} className="border-t border-rule-1 py-10">
      <p className="type-kicker mb-6 text-ink-45">{`#${id} — ${title}`}</p>
      <div className="flex flex-col gap-8">{children}</div>
    </section>
  );
}
const Row = ({ label, children }: { label: string; children: ReactNode }) => (
  <div className="flex flex-col gap-3"><p className="type-folio text-ink-45">{label}</p><div className="flex flex-wrap items-start gap-6">{children}</div></div>
);

const railItems = (n = 10): RailItem[] => SERIES.slice(0, n).map((s) => ({ id: s.id, title: s.title, src: COVER(s.n), kicker: s.kicker, deck: s.deck, why: "why" in s ? s.why : undefined, folio: s.folio, progress: s.progress, duo: DUOS[s.n % DUOS.length], href: "#rails" }));

function DuoDemo() {
  const f = useDuotone(DUOS[1]);
  return (
    <div className="flex flex-wrap gap-6">
      <div className="relative h-48 w-32 overflow-hidden"><CineImage src={COVER(1)} alt="Salt and Iron, full colour" /></div>
      <div className="relative h-48 w-32 overflow-hidden" style={{ filter: f }}><CineImage src={COVER(1)} alt="Salt and Iron, duotone" /></div>
      <div className="relative h-48 w-32 overflow-hidden"><CineImage src={COVER(2)} alt="Ember Ledger with grain" /><Grain /></div>
    </div>
  );
}

export function Gallery() {
  const [n, setN] = useState(0);
  const [q, setQ] = useState("");
  const [slug, setSlug] = useState("all");
  const [multi, setMulti] = useState(["romance"]);
  const [seg, setSeg] = useState("strip");
  const [tri, setTri] = useState<TriState>("neutral");
  const [sel, setSel] = useState(false);
  const [dl, setDl] = useState<DownloadState>("downloading");
  return (
    <KeyboardProvider>
      <MotionRoot>
        <GridOverlay />
        <main data-testid="gallery" className="mx-auto max-w-[1760px] px-4 pb-32 frame:px-8 desktop:px-12">
          <Masthead folio="No. 04" section="PRIMITIVES" title="Programme" deck="Every Cinematic primitive, every state." />

          <Section id="buttons" title="Button">
            <Row label="primary sm / md / lg"><Button size="sm" data-gallery="button-primary-sm">Continue</Button><Button data-gallery="button-primary">Continue</Button><Button size="lg" data-gallery="button-primary-lg">Continue</Button></Row>
            <Row label="split (folio button)"><Button variant="split" folio="CH 143 · p.12" data-gallery="button-split">Continue</Button><Button variant="split" folio="CH 143 · p.12" size="lg" data-gallery="button-split-lg">Continue</Button></Row>
            <Row label="secondary / quiet / destructive / on-art / link"><Button variant="secondary" data-gallery="button-secondary">Add to library</Button><Button variant="quiet" data-gallery="button-quiet">Not now</Button><Button variant="destructive" data-gallery="button-destructive">Delete profile</Button><span className="relative inline-block h-20 w-40 overflow-hidden"><CineImage src={COVER(3)} alt="" /><span className="absolute right-2 bottom-2"><Button variant="on-art" size="sm" data-gallery="button-on-art">Save</Button></span></span><Button variant="link" data-gallery="button-link">Read the terms</Button></Row>
            <Row label="play 64 / 56 / 36"><Button variant="play" size="lg" ariaLabel="Play" data-gallery="button-play-lg" /><Button variant="play" size="md" playing ariaLabel="Pause" data-gallery="button-play-md" /><Button variant="play" size="sm" ariaLabel="Play" data-gallery="button-play-sm" /></Row>
            <Row label="disabled / loading / selected / error"><Button disabled disabledReason="Pick a chapter first" data-gallery="button-disabled">Continue</Button><Button variant="secondary" disabled data-gallery="button-secondary-disabled">Add</Button><Button loading loadingLabel="Signing in…" data-gallery="button-loading">Sign in</Button><Button variant="secondary" selected data-gallery="button-selected">Following</Button><Button error="That password is not right." onClick={() => undefined} data-gallery="button-error">Sign in</Button></Row>
          </Section>

          <Section id="icon-buttons" title="IconButton and Tooltip">
            <Row label="bare / on-art / ruled / badged">
              <IconButton icon="bookmark" label="Bookmark" shortcut="b" data-gallery="icon-button-bare" />
              <span className="relative inline-block bg-paper-3 p-2"><IconButton icon="favourite" label="Favourite" variant="on-art" data-gallery="icon-button-on-art" /></span>
              <IconButton icon="zoom-in" label="Zoom in" variant="ruled" data-gallery="icon-button-ruled" />
              <IconButton icon="updates" label="Updates" variant="badged" badge={3} data-gallery="icon-button-badged" />
            </Row>
            <Row label="disabled / loading / selected / error"><IconButton icon="share" label="Share" disabled data-gallery="icon-button-disabled" /><IconButton icon="refresh" label="Refreshing" loading data-gallery="icon-button-loading" /><IconButton icon="favourite" label="Favourite" selected data-gallery="icon-button-selected" /><IconButton icon="download" label="Download" error="No connection" data-gallery="icon-button-error" /></Row>
          </Section>

          <Section id="fields" title="Fields">
            <div className="grid max-w-3xl gap-8 frame:grid-cols-2">
              <TextField label="Username" autoComplete="username" placeholder="yourname" data-gallery="field-text" />
              <TextField label="Email" type="email" inputMode="email" autoComplete="email" defaultValue="reader@example.test" success data-gallery="field-text-success" />
              <TextField label="Username" defaultValue="taken" error="That name is taken." data-gallery="field-text-error" />
              <TextField label="Display name" disabled defaultValue="Locked" data-gallery="field-text-disabled" />
              <TextField label="Checking" defaultValue="ilse" loading data-gallery="field-text-loading" />
              <PasswordField label="Password" defaultValue="hunter22" data-gallery="field-password" />
              <NumberField label="Sleep timer" defaultValue={30} unit="min" data-gallery="field-number" />
              <Textarea label="Note" helper="Shown on the letter." defaultValue="Line one" data-gallery="field-textarea" />
            </div>
          </Section>

          <Section id="search" title="SearchField">
            <div className="max-w-3xl"><SearchField label="Search every source" placeholder="Search every source" value={q} onChange={setQ} data-gallery="search-index" /></div>
            <div className="max-w-md"><SearchField variant="compact" label="Search or jump" placeholder="Search or jump" value="" onChange={() => undefined} data-gallery="search-compact" /></div>
          </Section>

          <Section id="slug-lines" title="Slug lines, segmented control, tri-state">
            <SlugLines label="Sort" value={slug} onChange={setSlug} items={[{ id: "all", label: "All", count: 12 }, { id: "reading", label: "Reading", count: 4 }, { id: "plan", label: "Plan", count: 8 }, { id: "done", label: "Done", count: null }]} />
            <SlugLines label="Genres" mode="multi" value={multi} onChange={(id) => setMulti((m) => (m.includes(id) ? m.filter((x) => x !== id) : [...m, id]))} items={[{ id: "romance", label: "Romance" }, { id: "action", label: "Action" }, { id: "fantasy", label: "Fantasy" }]} />
            <Row label="removable tokens"><SlugToken label="Romance" onRemove={() => undefined} /><SlugToken label="Completed" onRemove={() => undefined} /></Row>
            <SegmentedControl label="Layout" value={seg} onChange={setSeg} items={[{ id: "strip", label: "Strip" }, { id: "single", label: "Single" }, { id: "double", label: "Double", disabled: true, disabledReason: "Height fit needs a paged layout" }]} />
            <Row label="tri-state genre filter"><TriStateFilter label="Romance" state={tri} onChange={setTri} data-gallery="tri-state" /><TriStateFilter label="Horror" state="exclude" onChange={() => undefined} /><TriStateFilter label="Action" state="include" onChange={() => undefined} /></Row>
          </Section>

          <Section id="cards" title="Cards">
            <div className="grid gap-8 frame:grid-cols-3">
              <FeatureCard src={COVER(1)} kicker="EDITOR'S NOTE" headline="The harbour that taxed the dead" deck="A slow, salt-stained mystery about who owes whom." href="#cards" data-gallery="card-feature" />
              <CuttingCard src={COVER(2)} title="Ember Ledger" folio="CH 142 · 63%" progress={63} nudge={{ kind: "new", count: 3 }} href="#cards" data-gallery="card-cutting" />
              <CuttingCard src={COVER(3)} title="The Ninth Regression" folio="NEXT · CH 143" progress={20} nudge={{ kind: "paused", days: 21 }} href="#cards" data-gallery="card-cutting-paused" />
              <WorldCard variant="available" title="Dune Courier" src={COVER(5)} kicker="MANHWA · ONGOING · ★ 8.4" why="Because you liked quiet road stories." credit="ON MANGADEX, ASURA +1" href="#cards" onDismiss={() => undefined} data-gallery="card-world-available" />
              <WorldCard variant="info" title="Copper Saints" src={COVER(6)} kicker="MANHWA · ONGOING" credit="NOT ON YOUR SOURCES" siteName="MangaDex" duo={DUOS[1]} data-gallery="card-world-info" />
              <WorldCard variant="shelf" title="Glass Tide" src={COVER(8)} kicker="ASURA · 19 CHAPTERS" byline="Ilse Marrow" why="New on this source." href="#cards" data-gallery="card-world-shelf" />
              <StatBlock kicker="CHAPTERS THIS WEEK" value={48} caption="Up 12 on last week." />
              <StatBlock kicker="LOADING" value="" loading />
              <LetterCard from="Riya" title="Frost Archive" note="Slow, cold, and exactly your speed." src={COVER(9)} duo={DUOS[2]} isNew onRead={() => undefined} onAdd={() => undefined} onKeep={() => undefined} onDismiss={() => undefined} />
              <CollectionPlate name="Rainy evenings" covers={[COVER(7), COVER(8), COVER(9), COVER(10)]} duo={DUOS[2]} credit="24 SERIES · SMART · SHARED" sharedWith={["rose", "cyan"]} href="#cards" data-gallery="card-collection" />
              <CollectionPlate name="Reorder mode" covers={[COVER(1), COVER(2), COVER(3), COVER(4)]} duo={DUOS[1]} credit="8 SERIES" selected />
              <FeatureCard kicker="LOADING" headline="" loading />
            </div>
          </Section>

          <Section id="posters" title="Poster and CineImage">
            <div data-poster-group className="grid grid-cols-3 gap-4 frame:grid-cols-6">
              <Poster title="Salt and Iron" src={COVER(1)} folio="CH 142 · 3 NEW" href="#posters" data-gallery="poster-default" badges={<Badge variant="new" onArt count={3} />} progress={63} favourite />
              <Poster title="Ember Ledger" src={COVER(2)} folio="NOT STARTED" href="#posters" data-gallery="poster-below" hoverIcons={{ favourite: false, notify: false, onFavourite: () => undefined, onNotify: () => undefined }} />
              <Poster title="Red Lantern Pact" src={COVER(4)} caption="ranked" rank={3} href="#posters" data-gallery="poster-ranked" />
              <Poster title="Dune Courier" src={COVER(5)} caption="wall" href="#posters" data-gallery="poster-wall" />
              <Poster title="Copper Saints" src={COVER(6)} folio="UNAVAILABLE" disabled data-gallery="poster-disabled" />
              <Poster title="Moonlit Bakery" src={COVER(7)} folio="CH 12 OF 40" selectMode selected={sel} onSelect={() => setSel((s) => !s)} data-gallery="poster-select" />
              <Poster title="Loading title" loading src={null} folio="" data-gallery="poster-loading" />
              <Poster title="Broken cover" src="/gallery/covers/missing.webp" folio="CH 1" data-gallery="poster-error" />
              <Poster title="Manual order" src={COVER(8)} manualOrder folio="CH 3" data-gallery="poster-manual" />
              <Poster title="Rack focus 1" src={COVER(9)} folio="CH 9" />
            </div>
          </Section>

          <Section id="rails" title="Rail and slate">
            <Rail index="01" title="Continue" items={railItems(10)} onSeeAll={() => undefined} data-gallery="rail-ready" />
            <Rail index="02" title="New this week" items={railItems(8)} onSeeAll={() => undefined} data-gallery="rail-second" />
            <Rail index="03" title="Loading row" items={railItems(6)} state="loading" />
            <Rail index="04" title="Nothing in progress" items={[]} state="empty" core emptyLine="Nothing in progress. Start something below." />
            <Rail index="05" title="Error row" items={[]} state="error" onRetry={() => undefined} />
            <Rail index="06" title="Riya's picks" items={railItems(6)} state="ai-unavailable" aiNote="Riya is resting." />
            <Rail index="07" title="Saved copy" items={railItems(6)} staleLabel="SAVED COPY · 3 H" pickedLabel="PICKED 3 DAYS AGO" />
            <Rail index="08" title="Virtualised" items={LONG_LIST.map((s, i) => ({ id: s.id, title: s.title, src: COVER(i + 1), kicker: s.kicker, deck: s.deck, folio: s.folio }))} />
          </Section>

          <Section id="skeletons" title="Galley proofs">
            <div className="grid max-w-3xl gap-6 frame:grid-cols-2">
              <div className="flex flex-col"><GalleyLine index={0} /><GalleyLine index={1} /><GalleyLine index={2} /><GalleyLine index={3} /></div>
              <GalleyHeadline />
              <div className="h-48 w-32"><GalleyPlate title="Salt and Iron" /></div>
              <GalleyNumeral />
            </div>
          </Section>

          <Section id="progress" title="Progress">
            <div className="grid max-w-3xl gap-6">
              <RuleProgress value={63} label="Chapter progress" />
              <IndeterminateRule />
              <div className="relative h-24 w-16 bg-paper-1"><PosterProgress value={40} /></div>
              <Row label="leader dial 32 / 24 / 16 / 12, countdown, folio counter">
                <LeaderDial immediate size={32} /><LeaderDial immediate size={24} /><LeaderDial immediate size={16} /><LeaderDial immediate size={12} /><CountdownDial /><FolioCounter index={7} total={40} />
              </Row>
              <Row label="download mark">
                {(["not", "queued", "downloading", "saved", "failed", "paused", "stale"] as DownloadState[]).map((s) => <DownloadMark key={s} state={s} progress={30} onClick={() => setDl(s === dl ? "saved" : s)} />)}
              </Row>
              <StorageMeter other={30} app={4.1} capGb={10} totalGb={64} freeGb={20} />
              <StorageMeter other={30} app={10} capGb={10} totalGb={64} freeGb={1} />
            </div>
            <MicroProgressDemo />
          </Section>

          <Section id="badges" title="Badges">
            <Row label="new / status / reading / certificate / saved / text / stale / picked">
              <Badge variant="new" count={3} /><Badge variant="new" count={120} /><Badge variant="status">ONGOING</Badge><Badge variant="status">COMPLETED</Badge><Badge variant="reading">{readingStatusLabel("reading")}</Badge><Badge variant="reading">{readingStatusLabel("plan_to_read", true)}</Badge><Badge variant="certificate" /><Badge variant="certificate" large /><Badge variant="saved">SAVED</Badge><Badge variant="text">EDITED</Badge><Badge variant="stale">SAVED COPY · 3 H</Badge><Badge variant="picked">PICKED</Badge><Badge variant="pickedAgo">PICKED 3 DAYS AGO</Badge>
            </Row>
            <Row label="smart / shared / now / count / admin / you / deactivated"><Badge variant="smart">SMART</Badge><Badge variant="shared">SHARED</Badge><Badge variant="now">NOW</Badge><Badge variant="count" count={7} /><Badge variant="count" count={140} /><Badge variant="admin">ADMIN</Badge><Badge variant="you">YOU</Badge><Badge variant="deactivated">DEACTIVATED</Badge></Row>
          </Section>

          <Section id="avatars" title="Avatars">
            <Row label="twelve presets">{Object.keys(AVATAR_PRESETS).map((k) => <Avatar key={k} presetKey={k} size={56} />)}</Row>
            <Row label="sizes / selected / 18+ / reading now">{([20, 24, 28, 32, 44, 96] as const).map((s) => <Avatar key={s} presetKey="rose" size={s} />)}<Avatar presetKey="cyan" size={56} selected /><Avatar presetKey="ember" size={56} mature /><Avatar presetKey="lunar" size={56} reading={DUOS[2]} label="Reading Omniscient Reader · CH 212" /></Row>
          </Section>

          <Section id="keycaps" title="Keycaps">
            <Row label="combos"><Keycap combo="mod+k" /><Keycap combo="shift+g" /><Keycap combo="delete" /><Keycap combo="b" secondary /></Row>
          </Section>

          <Section id="masthead" title="Masthead and mood grades">
            <Masthead folio="No. 02" section="YOUR SHELF" title="Library" deck="142 chapters unread across 12 series." mood="romantic" id="gallery-masthead-library" />
            <SectionHeader folio="04" title="Recently added" action="See all" onAction={() => undefined} />
            <SectionHeader title="Nothing here" empty />
          </Section>

          <Section id="layout" title="Grid, measure, spread, credits">
            <Grid className="[&>div]:bg-paper-2 [&>div]:p-3">{Array.from({ length: 4 }).map((_, i) => <div key={i} className="type-folio col-span-2 text-ink-60">{`span 2 · ${i + 1}`}</div>)}</Grid>
            <Measure kind="deck"><p className="type-deck text-ink-80">A deck is capped at sixty-two characters to the line so the eye never has to travel far to find the next one, and a recap is a little narrower still.</p></Measure>
            <Spread art={<CineImage src={COVER(11)} alt="Harbour of Echoes" />}><h3 className="type-headline text-ink-100">Harbour of Echoes</h3><Measure kind="synopsis"><p className="type-body mt-3 text-ink-80">Every ship returns carrying somebody else&apos;s name.</p></Measure><div className="mt-6"><Credits rows={CREDITS} /></div></Spread>
          </Section>

          <Section id="grain-duotone" title="Grain and duotone">
            <DuoDemo />
          </Section>

          <Section id="reveals" title="The two signature reveals">
            <Row label="controls"><Button variant="secondary" size="sm" onClick={() => setN((v) => v + 1)} data-gallery="reveals-replay">Replay</Button></Row>
            <div data-testid="reveal-library" key={`lib-${n}`}><SetHeading as="h2" trigger="mount" id={`gallery-library-${n}`} text="Library" className="type-masthead text-ink-100" /></div>
            <div data-testid="reveal-linked" className="set-heading-link" key={`lnk-${n}`}><SetHeading as="h3" trigger="mount" id={`gallery-linked-${n}`} text="Continue reading" className="type-section text-ink-100" /></div>
            <div data-testid="reveal-p" key={`p-${n}`}><SetHeading as="p" trigger="mount" id={`gallery-p-${n}`} text="Welcome back" className="type-headline text-ink-100" /></div>
            <div data-testid="narrow-358" className="overflow-hidden" style={{ width: 358 }} key={`n358-${n}`}><SetHeading as="h2" trigger="mount" id={`gallery-narrow-${n}`} text="Transmigration" className="type-cover text-ink-100" /></div>
            <div data-testid="narrow-160" className="overflow-hidden" style={{ width: 160 }} key={`n160-${n}`}><SetHeading as="h2" trigger="mount" id={`gallery-narrower-${n}`} text="Transmigration" className="type-cover text-ink-100" /></div>
            <div data-testid="typed" key={`typed-${n}`}><TypedHeadline as="h2" text={HEADLINE_40} className="type-headline text-ink-100" /></div>
          </Section>
        </main>
      </MotionRoot>
    </KeyboardProvider>
  );
}

function MicroProgressDemo() {
  return <div className="relative h-10 w-full max-w-3xl bg-paper-1"><div className="absolute inset-x-0 bottom-0 h-0.5"><div className="h-full w-1/2 bg-spot" /></div><span className="type-folio absolute top-2 left-2 text-ink-45">MicroProgress (reader foot)</span></div>;
}
