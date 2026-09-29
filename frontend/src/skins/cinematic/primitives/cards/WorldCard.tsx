"use client";
import { Badge } from "../Badge";
import { Button } from "../Button";
import { CineImage } from "../CineImage";
import { IconButton } from "../IconButton";
import { useDuotone } from "../../duotone";
import { CardRoot } from "./shared";

export type WorldCardProps = {
  variant: "available" | "info" | "shelf";
  title: string;
  src?: string | null;
  kicker: string;
  why?: string;
  credit?: string;
  byline?: string;
  /** `available[]` source is mature, or the shelf item's source is mature; only shown when the gate is open. */
  mature?: boolean;
  gateOpen?: boolean;
  duo?: string;
  siteName?: string;
  href?: string;
  onOpen?: () => void;
  onSearchMySources?: () => void;
  onReadOnSite?: () => void;
  onDismiss?: () => void;
  "data-gallery"?: string;
};

/** §7.6 world card: available (full colour), information only (duotone, quiet actions), shelf (a source's own item). */
export function WorldCard(p: WorldCardProps) {
  const filter = useDuotone(p.duo ?? "#B8B2A4");
  const info = p.variant === "info";
  const open = info ? undefined : p.onOpen;
  return (
    <div className="group/world relative flex flex-col gap-2">
      <CardRoot href={info ? undefined : p.href} onOpen={open} label={`${p.title}. ${p.kicker}`} data-gallery={p["data-gallery"]}>
        <div className="relative aspect-[2/3] w-full overflow-hidden bg-paper-1" style={info ? { filter } : undefined} data-duotone={info || undefined}>
          <CineImage src={p.src} alt="" title={p.title} />
        </div>
        {p.gateOpen && p.mature ? <span className="absolute top-1 left-1"><Badge variant="certificate" onArt /></span> : null}
        <p className="type-title mt-2 text-ink-100">{p.title}</p>
        <p className="type-kicker mt-1 text-ink-45">{p.kicker}{p.variant === "shelf" && p.byline ? ` · by ${p.byline}` : ""}</p>
        {p.why ? <p className="type-pull mt-2 border-l-2 border-spot pl-3 text-ink-80" style={{ fontSize: "1rem", lineHeight: "1.4rem" }}>{p.why}</p> : null}
        {p.credit ? <p className="type-kicker mt-2 text-ink-45">{p.credit}</p> : null}
      </CardRoot>
      {info ? (
        <div className="flex flex-wrap gap-1">
          <Button variant="quiet" size="sm" onClick={p.onSearchMySources}>Search my sources</Button>
          <Button variant="quiet" size="sm" onClick={p.onReadOnSite}>{`Read on ${p.siteName ?? "the site"} ↗`}</Button>
        </div>
      ) : null}
      {p.onDismiss ? <span className="absolute top-1 right-1 opacity-0 group-hover/world:opacity-100 focus-within:opacity-100"><IconButton variant="on-art" icon="close" label="Not for me" onClick={p.onDismiss} /></span> : null}
    </div>
  );
}
