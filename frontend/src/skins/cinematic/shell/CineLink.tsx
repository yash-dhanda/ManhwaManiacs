"use client";
import Link from "next/link";
import type { ComponentProps } from "react";
import { navCue, transitionTypesFor, type NavKind } from "./use-cine-router";

/** `next/link` carrying the view-transition type: forward (default), back, section (sidebar, thumb index, `g` jumps) or match (a poster with a match-cut name). */
export function CineLink({ nav = "forward", ...rest }: Omit<ComponentProps<typeof Link>, "transitionTypes"> & { nav?: NavKind }) {
  return <Link {...rest} onClick={(e) => { rest.onClick?.(e); if (nav === "section" && !e.defaultPrevented) navCue(); }} transitionTypes={transitionTypesFor(nav)} />;
}
