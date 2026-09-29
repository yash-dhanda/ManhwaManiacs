"use client";
import * as React from "react";
import { createContext, useContext, useEffect, useRef, useState } from "react";
import { sourcesLimiter, type Ticket } from "@/features/sources/request-limiter";
import { coverTransitionName } from "@/features/sources/cover-transition-name";
import { imagePixelRatio } from "@/lib/device-pixels";
import { withCoverWidth } from "@/lib/cover-url";
import { RackImage } from "../motion-components";
import { acquireCover, isLocalImage, needsGrant, refundIfCached, snapCoverWidth } from "./cover-gate";
import { Glyph } from "./glyphs";
import { GalleyPlate } from "./Skeleton";

const VT = (React as unknown as { ViewTransition?: React.ComponentType<{ name?: string; share?: string; children: React.ReactNode }> }).ViewTransition;

/** Proof screenshots and tests load every cover at once (no viewport wait). */
export const EagerImages = createContext(false);

export type MatchCut = { sourceId: string; seriesKey: string };

/**
 * §7.7 image: requests the cover at the nearest snapped width, waits for a P2 grant from the sources limiter (refunds cache hits),
 * runs Rack focus on first decode (Develop past the cap of 12) and shows the plate + title card when loading fails.
 */
export function CineImage({ src, alt, title, className = "", position = "50% 50%", matchCut, priority = false, onFail }: {
  src: string | null | undefined; alt: string; title?: string; className?: string; position?: string; matchCut?: MatchCut; priority?: boolean; onFail?: () => void;
}) {
  const box = useRef<HTMLDivElement>(null);
  const img = useRef<HTMLImageElement>(null);
  const [grant, setGrant] = useState<{ src: string; url: string } | null>(null);
  const final = grant && grant.src === src ? grant.url : null;
  const [ready, setReady] = useState(false);
  const [failed, setFailed] = useState(false);
  const [cached, setCached] = useState(false);
  const ticket = useRef<Ticket | null>(null);
  const eager = useContext(EagerImages);

  useEffect(() => {
    const el = box.current;
    if (!el || !src || !needsGrant(grant, src)) return; // one P2 ticket per src: a finished grant never re-arms the effect
    let ac: AbortController | null = null;
    const start = async () => {
      if (isLocalImage(src)) { setGrant({ src, url: src }); return; }
      const w = snapCoverWidth(el.clientWidth || 160, imagePixelRatio());
      const url = withCoverWidth(src, `${w / imagePixelRatio()}px`);
      ac = new AbortController();
      try { ticket.current = await acquireCover(sourcesLimiter, ac.signal); setGrant({ src, url }); } catch { /* left the viewport before the grant */ }
    };
    if (priority || eager || typeof IntersectionObserver === "undefined") { void start(); return () => ac?.abort(); }
    const io = new IntersectionObserver(([e]) => {
      if (e.isIntersecting) { if (!ac) void start(); }
      else if (ac) { ac.abort(); ac = null; }
    }, { rootMargin: "200px" });
    io.observe(el);
    return () => { io.disconnect(); ac?.abort(); };
  }, [src, priority, eager, grant]);

  useEffect(() => {
    const i = img.current;
    if (i && final && i.complete && i.naturalWidth > 0) { setCached(true); setReady(true); } // already decoded at mount: no rack
  }, [final]);

  const onLoad = () => {
    setReady(true);
    const shown = img.current?.currentSrc || final;
    if (shown && ticket.current) refundIfCached(sourcesLimiter, ticket.current, shown);
  };
  const body = (
    <div ref={box} className={`relative size-full overflow-hidden bg-paper-1 ${className}`}>
      {failed || !src ? (
        <>
          <GalleyPlate title={title} />
          <span role="img" aria-label="Cover didn't load" className="absolute right-2 bottom-2 text-ink-45"><Glyph name="image-broken" size={16} /></span>
        </>
      ) : (
        <>
          {!ready ? <GalleyPlate title={title} /> : null}
          {final ? (
            <RackImage ready={ready} alreadyDecoded={cached} className="absolute inset-0">
              {/* eslint-disable-next-line @next/next/no-img-element -- the cover proxy is cookie-gated; next/image cannot fetch it */}
              <img ref={img} src={final} alt={alt} decoding="async" draggable={false} onLoad={onLoad} onError={() => { setFailed(true); onFail?.(); }}
                className="cine-zoom size-full object-cover transition-transform duration-(--mm-dur-line) ease-settle" style={{ objectPosition: position }} />
            </RackImage>
          ) : null}
        </>
      )}
    </div>
  );
  return matchCut && VT ? <VT name={coverTransitionName(matchCut.sourceId, matchCut.seriesKey)} share="mm-match-cut">{body}</VT> : body;
}
