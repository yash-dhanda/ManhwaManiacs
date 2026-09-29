"use client";
import Link from "next/link";
import type { ComponentProps } from "react";
import { transitionTypesFor, type NavKind } from "./use-cine-router";

/** `next/link` carrying the view-transition type: forward (default), back, section (sidebar, thumb index, `g` jumps) or match (a poster with a match-cut name). */
export function CineLink({ nav = "forward", ...rest }: Omit<ComponentProps<typeof Link>, "transitionTypes"> & { nav?: NavKind }) {
  return <Link {...rest} transitionTypes={transitionTypesFor(nav)} />;
}
