"use client";

import { animate } from "motion/react";
import { useEffect, useRef, useState, type CSSProperties, type ElementType } from "react";
import { isGlassReduced, useGlassReduced } from "../motion";
import { MOTION_LABELS } from "../motion.generated";
import { beginRecord, trackFrames } from "../motion-recorder";
import { spring } from "../tokens.generated";

const seg = typeof Intl !== "undefined" && "Segmenter" in Intl ? new Intl.Segmenter(undefined, { granularity: "grapheme" }) : null;
const graphemes = (s: string): string[] => (seg ? Array.from(seg.segment(s), (x) => x.segment) : Array.from(s));
export const REVEALED_KEY = "mm.glass.revealed";
export const MAX_GRAPHEMES = 60;
export const STAGGER_MS = 24;
export const WORD_STAGGER_MS = 40;
export const MAX_CONCURRENT = 2;
const LETTER_MS = 345, GLINT_GAP = 120, GLINT_MS = 500;

const CJK = /^[\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}\p{sc=Hangul}]/u;
const UNITS = /[\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}\p{sc=Hangul}]+|[^\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}\p{sc=Hangul}\s]+\s*|\s+/gu;

/** How long a reveal of `n` staggered units keeps its slot: n x stagger + 345 + 120 + 500 ms. */
export const revealDuration = (n: number, stagger = STAGGER_MS) => n * stagger + LETTER_MS + GLINT_GAP + GLINT_MS;

/* ---- at most two reveals at once (15.7): a module-level slot counter and a queue ---- */
interface Slot { start: () => void; complete: () => void; visible: boolean }
let running = 0;
const queue: Slot[] = [];
export const _slots = () => ({ running, queued: queue.length });
export const _resetSlots = () => { running = 0; queue.length = 0; };
function pump() {
  while (running < MAX_CONCURRENT && queue.length) {
    const s = queue.shift()!;
    if (s.visible) { running++; s.start(); } else s.complete();
  }
}
const request = (s: Slot) => { queue.push(s); pump(); };
const release = (s: Slot, held: boolean) => { const i = queue.indexOf(s); if (i >= 0) queue.splice(i, 1); if (held) { running = Math.max(0, running - 1); pump(); } };

const readSeen = (): string[] => { try { return JSON.parse(sessionStorage.getItem(REVEALED_KEY) ?? "[]"); } catch { return []; } };
const record = (key: string) => { try { sessionStorage.setItem(REVEALED_KEY, JSON.stringify([...new Set([...readSeen(), key])])); } catch { /* private mode */ } };

export interface LetterRevealProps {
  text: string;
  /** "{profileId}:{screenId}:{headingKey}": plays once per session. Omit for the hero title and chapter seams (they play whenever their text changes or they enter the viewport). */
  revealKey?: string;
  as?: ElementType;
  /** a `type-*` utility, e.g. "type-title2" */
  typeClass?: string;
  /** "live": per-letter Motion springs so new text retargets mid-flight (the Home spotlight title, web/31) */
  mode?: "css" | "live";
  className?: string;
  "data-testid"?: string;
}

/** Every grapheme is a droplet settling (10.1). Starts at first visibility (25 %), never on mount; at most two run at once. */
export function LetterReveal({ text, revealKey, as: Tag = "h3", typeClass = "type-title2", mode = "css", className, "data-testid": tid }: LetterRevealProps) {
  const ref = useRef<HTMLElement>(null);
  const reduced = useGlassReduced();
  const [state, setState] = useState<"wait" | "run" | "done">("wait");
  const n = graphemes(text).length;
  const perWord = n > MAX_GRAPHEMES;
  const units = (text.match(UNITS) ?? []).length;
  const steps = perWord ? text.split(/\s+/).filter(Boolean).length : n;

  useEffect(() => {
    if (mode === "live") return;
    const el = ref.current;
    if (!el) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- syncing with sessionStorage and the reduced-motion setting, which only exist on the client
    if (reduced || (revealKey && readSeen().includes(revealKey))) { setState("done"); return; }
    setState("wait");
    let held = false, endRec: (() => void) | null = null, timer: ReturnType<typeof setTimeout> | undefined, finished = false;
    const slot: Slot = {
      visible: false,
      start: () => {
        held = true;
        endRec = trackFrames(beginRecord("letterReveal", MOTION_LABELS.letterReveal, steps * (perWord ? WORD_STAGGER_MS : STAGGER_MS) + LETTER_MS));
        setState("run");
        if (revealKey) record(revealKey);
        timer = setTimeout(() => { finish(); }, revealDuration(steps, perWord ? WORD_STAGGER_MS : STAGGER_MS));
      },
      complete: () => { finish(); },
    };
    function finish() { if (finished) return; finished = true; clearTimeout(timer); endRec?.(); endRec = null; const was = held; held = false; release(slot, was); setState("done"); }
    const io = new IntersectionObserver((es) => {
      const e = es[es.length - 1];
      slot.visible = e.isIntersecting && e.intersectionRatio >= 0.25;
      if (slot.visible && !held && !finished && !queue.includes(slot)) request(slot);
      if (e.intersectionRatio === 0 && (held || queue.includes(slot))) finish(); // scrolled fully off-screen: completes at once
    }, { threshold: [0, 0.25] });
    io.observe(el);
    const tap = () => finish();
    el.addEventListener("pointerdown", tap);
    return () => { io.disconnect(); el.removeEventListener("pointerdown", tap); clearTimeout(timer); if (!finished) release(slot, held); };
  }, [text, revealKey, reduced, mode, steps, perWord]);

  if (mode === "live") return <LiveReveal text={text} as={Tag} typeClass={typeClass} className={className} tid={tid} />;

  let i = 0;
  const g = (s: string) => <span key={i} className="g" style={{ "--i": i++ } as CSSProperties}>{s}</span>;
  void units;
  return (
    <Tag ref={ref} className={`letter-reveal ${typeClass}${className ? ` ${className}` : ""}`} data-reveal={state} data-testid={tid} tabIndex={-1} style={{ "--stagger": perWord ? `${WORD_STAGGER_MS}ms` : `${STAGGER_MS}ms` } as CSSProperties}>
      <span className="sr-only">{text}</span>
      <span aria-hidden>
        {(text.match(UNITS) ?? []).map((t, w) => CJK.test(t)
          ? graphemes(t).map((s) => g(s))
          : (
            <span key={`w${w}`} className="word" style={perWord ? ({ "--i": i++ } as CSSProperties) : undefined}>
              {perWord ? t : graphemes(t.trimEnd()).map((s) => g(s))}
              {perWord ? null : t.slice(t.trimEnd().length)}
            </span>
          ))}
        <span className="glint" style={{ "--n": i } as CSSProperties}>{text}</span>
      </span>
    </Tag>
  );
}

/** Live variant: each letter is its own Motion spring (`spring.letter`), the old letters leave together over `fadeOut` with blur 4 px while the new wave starts. */
function LiveReveal({ text, as: Tag, typeClass, className, tid }: { text: string; as: ElementType; typeClass: string; className?: string; tid?: string }) {
  const host = useRef<HTMLElement>(null);
  const [shown, setShown] = useState(text);
  const ctl = useRef<{ stop: () => void }[]>([]);
  const first = useRef(true);
  useEffect(() => {
    const el = host.current;
    if (!el) return;
    ctl.current.forEach((c) => c.stop());
    ctl.current = [];
    /* eslint-disable react-hooks/set-state-in-effect -- the live text follows the prop after the leaving letters fade out */
    if (isGlassReduced()) { setShown(text); return; }
    if (first.current) { first.current = false; setShown(text); return; }
    /* eslint-enable react-hooks/set-state-in-effect */
    const old = Array.from(el.querySelectorAll<HTMLElement>(".g"));
    if (!old.length || text === shown) { setShown(text); return; }
    const out = old.map((l) => animate(l, { opacity: 0, filter: "blur(4px)" }, { duration: 0.12, ease: [0.4, 0, 1, 1] }));
    ctl.current = out;
    const t = setTimeout(() => setShown(text), 120);
    return () => { clearTimeout(t); out.forEach((c) => c.stop()); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [text]);
  useEffect(() => {
    const el = host.current;
    if (!el || isGlassReduced()) return;
    const letters = Array.from(el.querySelectorAll<HTMLElement>(".g"));
    ctl.current = letters.map((l, i) => animate(l, { opacity: [0, 1], y: ["0.4em", "0em"], scale: [0.96, 1], filter: ["blur(12px)", "blur(0px)"] }, { ...spring.letter, opacity: { duration: 0.18, ease: [0.2, 0, 0, 1] }, delay: i * 0.024 } as never));
    return () => ctl.current.forEach((c) => c.stop());
  }, [shown]);
  let i = 0;
  return (
    <Tag ref={host} className={`letter-reveal letter-reveal--live ${typeClass}${className ? ` ${className}` : ""}`} data-reveal="run" data-testid={tid} tabIndex={-1}>
      <span className="sr-only">{shown}</span>
      <span aria-hidden>{(shown.match(UNITS) ?? []).map((t, w) => CJK.test(t) ? graphemes(t).map((s) => <span key={i++} className="g">{s}</span>) : <span key={`w${w}`} className="word">{graphemes(t.trimEnd()).map((s) => <span key={i++} className="g">{s}</span>)}{t.slice(t.trimEnd().length)}</span>)}</span>
    </Tag>
  );
}
