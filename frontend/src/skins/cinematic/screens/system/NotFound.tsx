"use client";
import { Button } from "../../primitives/Button";
import { Keycap } from "../../primitives/Keycap";
import { TypedHeadline } from "../../primitives/TypedHeadline";
import { useCineRouter } from "../../shell/use-cine-router";

/** §8.32 in-frame 404: a folio numeral `p. 404`, kicker `NOT IN THIS ISSUE`, typed h1, two actions. Renders inside the Shell's App frame. */
export default function NotFound() {
  const router = useCineRouter();
  return (
    <section className="cine-inset py-16" data-status="not-found" style={{ paddingTop: "15vh" }}>
      <p aria-hidden className="type-numeral text-ink-30" style={{ fontSize: "calc(var(--mm-type-numeral-size) * 1.5)", lineHeight: 1 }}>p. 404</p>
      <p className="type-kicker mt-6 text-ink-45">NOT IN THIS ISSUE</p>
      <TypedHeadline as="h1" text="This page doesn't exist." className="type-headline mt-3 text-ink-100" />
      <p className="type-deck mt-4 hidden max-w-[48ch] text-ink-60 frame:block">It may have been renamed, or the series it pointed to left your library. Press <Keycap combo="mod+k" /> to search everything.</p>
      <p className="type-deck mt-4 max-w-[48ch] text-ink-60 frame:hidden">It may have been renamed, or the series it pointed to left your library. Search everything from <button type="button" className="underline underline-offset-[3px] text-ink-100" onClick={() => router.push("/search")}>Discover</button>.</p>
      <div className="mt-8 flex flex-wrap items-center gap-3">
        <Button variant="primary" onClick={() => router.push("/", "section")}>Back to Tonight</Button>
        <Button variant="quiet" onClick={() => router.push("/library", "section")}>Open library</Button>
      </div>
    </section>
  );
}
