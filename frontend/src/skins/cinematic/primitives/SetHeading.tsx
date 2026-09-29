"use client";
import { Fragment, useEffect, useLayoutEffect, useRef, useState } from "react";
import { motion, stagger, useInView, type Variants } from "motion/react";
import { startMove } from "@/lib/motion-timings";
import { graphemeCount, graphemes } from "../text";
import { letterStep, useCineReduced } from "../motion";

const settle = [0.16, 1, 0.3, 1] as const;
const seen = new Set<string>();
/** §10.1.1: "inView" H3s, "mount" mastheads, "signal" cover, feature, book and takeover titles. */
export type SetTrigger = "inView" | "mount" | "signal";

const parent: Variants = {
  hidden: {},
  show: ({ n, startDelay }: { n: number; startDelay: number }) => ({ transition: { delayChildren: stagger(Math.min(0.024, 0.56 / Math.max(1, n - 1)), { startDelay }) } }),
};
const letter: Variants = {
  hidden: { opacity: 0, y: "0.42em", filter: "blur(8px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)", transition: { duration: 0.64, ease: settle, filter: { duration: 0.44, ease: settle } } },
};

/** `play` for trigger "signal": true 480 ms after a match cut, otherwise 160 ms after first paint. */
export function useTitleSignal(matchCut: boolean) {
  const [play, setPlay] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setPlay(true), matchCut ? 480 : 160);
    return () => clearTimeout(t);
  }, [matchCut]);
  return play;
}

/** §10.1.1 Long words: false when any word is wider than the container. `ref.current` is read on every check (the node is swapped at "done"). */
function useWordsFit(ref: React.RefObject<HTMLElement | null>, text: string) {
  const [fits, setFits] = useState(true);
  useLayoutEffect(() => {
    const box = ref.current?.parentElement;
    if (!box) return;
    const probe = document.createElement("span");
    probe.setAttribute("aria-hidden", "true");
    probe.style.cssText = "position:absolute;visibility:hidden;white-space:nowrap;font:inherit;letter-spacing:inherit";
    const check = () => {
      const el = ref.current;
      if (!el) return;
      el.appendChild(probe);
      const widest = Math.max(...text.split(" ").map((w) => { probe.textContent = w; return probe.offsetWidth; }));
      probe.remove();
      setFits(widest <= box.clientWidth);
    };
    check();
    const ro = new ResizeObserver(check);
    ro.observe(box);
    return () => ro.disconnect();
  }, [ref, text]);
  return fits;
}

export type SetHeadingProps = {
  text: string;
  id?: string;
  as?: "h1" | "h2" | "h3" | "p";
  className?: string;
  trigger?: SetTrigger;
  play?: boolean;
  /** Extra props on the element (tabIndex for masthead focus, etc.). */
  tabIndex?: number;
  /** ms before the first letter (default 120). The Press start splash passes 0: its timeline replaces the start delay. */
  startDelay?: number;
};

export function SetHeading({ text, id, as: Tag = "h2", className, trigger = "inView", play = false, tabIndex, startDelay = 120 }: SetHeadingProps) {
  const key = id ?? text;
  const reduce = useCineReduced();
  const ref = useRef<HTMLElement>(null);
  const signal = trigger === "signal";
  const [once] = useState(() => !signal && seen.has(key)); // read once at mount
  const [phase, setPhase] = useState<"idle" | "run" | "done">(once ? "done" : "idle");
  const half = useInView(ref, { amount: 0.5 });
  const any = useInView(ref);
  const fits = useWordsFit(ref, text);
  const wasIn = useRef(false);
  const rec = useRef<{ end: () => void } | null>(null);
  const go = trigger === "inView" ? half : trigger === "mount" || play;
  useEffect(() => {
    if (any) wasIn.current = true;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the idle -> run -> done phase machine is the given §10.1.5 design
    if (go && phase === "idle") setPhase("run");
    else if (phase === "run" && wasIn.current && !any) setPhase("done"); // left the viewport mid-reveal: jump to the end (§4.7)
  }, [go, any, phase]);
  useEffect(() => {
    if (phase === "done") { rec.current?.end(); rec.current = null; if (!signal) seen.add(key); }
  }, [phase, signal, key]);
  const M = motion[Tag] as typeof motion.h2;
  const words = text.split(" ");
  const n = graphemeCount(text);
  const step = letterStep(n);
  let i = 0;
  const p = Tag === "p";
  // Letter spans in every state so the hover wipe also works on a revealed or reduced-motion heading.
  const spans = (animated: boolean) => words.map((w, wi) => (
    <Fragment key={wi}>
    {wi > 0 ? " " : null}
    <span aria-hidden className="inline-block whitespace-nowrap">
      {graphemes(w).map((c) => {
        const k = i++;
        return animated
          ? <motion.span key={k} variants={letter} className="set-letter inline-block" style={{ ["--i" as string]: k }}>{c}</motion.span>
          : <span key={k} className="set-letter inline-block" style={{ ["--i" as string]: k }}>{c}</span>;
      })}
    </span>
    </Fragment>
  ));
  // aria-label is ignored on <p>; render the text in an sr-only span and hide the letters.
  const label = p ? {} : { "aria-label": text };
  const sr = p ? <span className="sr-only">{text}</span> : null;
  if (!fits) return <M ref={ref as never} {...label} tabIndex={tabIndex} className={className} style={{ overflowWrap: "anywhere" }} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.2 }}>{text}</M>;
  if (reduce) return <M ref={ref as never} {...label} tabIndex={tabIndex} className={className} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ duration: 0.2 }}>{sr}{spans(false)}</M>;
  if (phase === "done") { const T = Tag as "h2"; return <T ref={ref as never} {...label} tabIndex={tabIndex} className={className} style={{ fontKerning: "none" }}>{sr}{spans(false)}</T>; }
  return (
    <M ref={ref as never} {...label} tabIndex={tabIndex} className={className} style={{ fontKerning: "none" }}
      initial="hidden" animate={phase === "run" ? "show" : "hidden"}
      onAnimationStart={(def) => { if (def === "show" && !rec.current) rec.current = startMove("letterSet", 120 + step * Math.max(0, n - 1) + 640); }}
      onAnimationComplete={(def) => def === "show" && setPhase("done")}
      variants={parent} custom={{ n, startDelay: startDelay / 1000 }}>
      {sr}{spans(true)}
    </M>
  );
}
