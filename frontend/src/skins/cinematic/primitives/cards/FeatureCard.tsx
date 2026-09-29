"use client";
import { cn } from "@/lib/cn";
import { CineImage } from "../CineImage";
import { GalleyLine, GalleyPlate } from "../Skeleton";
import { CardRoot, Frame } from "./shared";

/** §7.6 feature: image 3:2 (4:5 on the phone frame), kicker, subhead headline (2 lines), italic deck (2 lines). No frame. */
export function FeatureCard({ src, kicker, headline, deck, href, onOpen, loading, error, ambientInk, "data-gallery": g }: {
  src?: string | null; kicker: string; headline: string; deck?: string; href?: string; onOpen?: () => void; loading?: boolean; error?: boolean; ambientInk?: string; "data-gallery"?: string;
}) {
  if (loading) return <div aria-busy className="flex flex-col gap-3"><Frame ratio="3 / 2"><GalleyPlate /></Frame><GalleyLine index={0} lineHeight={16} width={30} /><GalleyLine index={1} lineHeight={28} /><GalleyLine index={2} lineHeight={24} /></div>;
  return (
    <CardRoot href={href} onOpen={onOpen} label={`${headline}. ${kicker}`} data-gallery={g}>
      <Frame ratio="4 / 5" className="frame:hidden"><CineImage src={error ? null : src} alt="" title={headline} /></Frame>
      <Frame ratio="3 / 2" className="hidden frame:block"><CineImage src={error ? null : src} alt="" title={headline} /></Frame>
      <p className="type-kicker mt-3" style={{ color: ambientInk ?? "var(--mm-color-ink-45)" }}>{kicker}</p>
      <p className={cn("type-subhead mt-1 line-clamp-2 text-ink-100 group-hover:underline group-hover:underline-offset-4")}>{headline}</p>
      {deck ? <p className="type-body-italic mt-1 line-clamp-2 text-ink-60">{deck}</p> : null}
    </CardRoot>
  );
}
