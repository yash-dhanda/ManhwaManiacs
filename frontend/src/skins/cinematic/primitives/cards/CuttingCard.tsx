"use client";
import { folioLabel } from "../../a11y/folio";
import { useLongPress } from "../hooks";
import { Badge, BadgeStack } from "../Badge";
import { CineImage } from "../CineImage";
import { PosterProgress } from "../Progress";
import { GalleyLine, GalleyPlate } from "../Skeleton";
import { CardRoot, Frame } from "./shared";

export type Nudge = { kind: "new"; count: number } | { kind: "almost" } | { kind: "paused"; days: number };

/** §7.6 cutting: 3:2 crop at object-position 50% 22%, a 2 px spot progress rule on the image's bottom edge, title, folio caption. */
export function CuttingCard({ src, title, folio, progress, nudge, href, onOpen, onQuickLook, loading, "data-gallery": g }: {
  src?: string | null; title: string; folio: string; progress?: number; nudge?: Nudge; href?: string; onOpen?: () => void; onQuickLook?: () => void; loading?: boolean; "data-gallery"?: string;
}) {
  const press = useLongPress(onQuickLook);
  if (loading) return <div aria-busy className="flex flex-col gap-2"><Frame ratio="3 / 2"><GalleyPlate /></Frame><GalleyLine lineHeight={20} width={70} /><GalleyLine index={1} lineHeight={16} width={40} /></div>;
  return (
    <div {...press} className="relative">
      <CardRoot href={href} onOpen={onOpen} label={`${title}. ${folioLabel(folio)}`} data-gallery={g}>
        <Frame ratio="3 / 2">
          <CineImage src={src} alt="" title={title} position="50% 22%" />
          {nudge ? (
            <BadgeStack className="absolute top-1 left-1">
              {nudge.kind === "new" ? <Badge variant="new" onArt count={nudge.count} /> : nudge.kind === "almost" ? <Badge variant="text" onArt>ALMOST DONE</Badge> : <Badge variant="text" onArt>{`PAUSED ${nudge.days} D`}</Badge>}
            </BadgeStack>
          ) : null}
          {progress != null ? <PosterProgress value={progress} /> : null}
        </Frame>
        <p className="type-title mt-2 truncate text-ink-100">{title}</p>
        <p className="type-folio mt-1 text-ink-45" aria-hidden>{folio}</p>
      </CardRoot>
    </div>
  );
}
