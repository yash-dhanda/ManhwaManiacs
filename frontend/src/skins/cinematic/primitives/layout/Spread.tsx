"use client";
import type { ReactNode } from "react";
import { Grain } from "../../Grain";
import { Drift } from "../../motion-components";
import { Grid, col } from "./Grid";

/** The 5 + 7 column composition (§7.28): text on 5 columns, art on 7 bleeding off the right edge on the desktop frame, the cover copy at blur-bleed filling the art columns, scrim-gutter over the 2 columns where they meet, Grain and Drift on the art only. On the phone frame it stacks cover then text. */
export function Spread({ art, children }: { art: ReactNode; children: ReactNode }) {
  return (
    <Grid className="items-stretch">
      <div className="relative order-1 col-span-full frame:order-2 frame:[grid-column:6/span_7] frame:-mr-(--mm-grid-margin)" style={{ minHeight: 240 }}>
        <div aria-hidden className="blur-bleed absolute inset-0 hidden overflow-hidden frame:block"><Drift className="size-full">{art}</Drift></div>
        <div className="relative size-full overflow-hidden"><Drift className="size-full">{art}</Drift><Grain /></div>
        <div aria-hidden className="scrim-gutter pointer-events-none absolute inset-y-0 left-0 hidden w-1/4 frame:block" />
      </div>
      <div className="order-2 col-span-full frame:order-1" style={col(1, 5)}>{children}</div>
    </Grid>
  );
}
