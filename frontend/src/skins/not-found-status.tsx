"use client";

import { use } from "react";
import { notFound } from "next/navigation";

/**
 * Turns a missing screen into a real 404 status on the server render, from
 * outside the skin's Shell (see `screenMissing` in ./server). Renders nothing;
 * in the browser the page's own `notFound()` shows the not-found screen.
 */
export function NotFoundStatus({ missing }: { missing: Promise<boolean> }) {
  if (typeof window === "undefined" && use(missing)) notFound();
  return null;
}
