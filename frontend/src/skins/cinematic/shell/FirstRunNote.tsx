"use client";
import { usePathname } from "next/navigation";
import { useFollowedIndex } from "@/features/library/hooks";
import { shouldShowFirstRunHint } from "@/features/library/first-run";
import { Button } from "../primitives/Button";
import { BannerStrip } from "../primitives/BannerStrip";
import { frameFor } from "./frames";
import { isHeldRoute } from "./nav-map";
import { useCineRouter } from "./use-cine-router";

const SKIP = new Set(["/", "/library", "/library/browse", "/search", "/sources"]);
/** Pure: App-frame screens except Tonight, Library, Discover, Sources and feature/book pages. */
export function firstRunNoteApplies(pathname: string): boolean {
  if (frameFor(pathname) !== "app") return false;
  const p = pathname.split("?")[0];
  if (SKIP.has(p) || isHeldRoute(p)) return false;
  if (/^\/sources\/[^/]+$/.test(p)) return false;
  return true;
}

export function FirstRunNoteView({ onDiscover }: { onDiscover: () => void }) {
  return (
    <div role="note" data-first-run>
      <BannerStrip kicker="NOTHING FOLLOWED YET" tone="note" actions={<Button variant="quiet" size="sm" onClick={onDiscover}>Discover</Button>}>Follow a series from Discover to start your shelf.</BannerStrip>
    </div>
  );
}

/** web/05's `BannerStrip` under the running head; not dismissible; shown while the profile follows nothing. */
export function FirstRunNote() {
  const pathname = usePathname() ?? "/";
  const router = useCineRouter();
  const idx = useFollowedIndex();
  const count = idx.isSuccess ? idx.index.size : null;
  if (!firstRunNoteApplies(pathname) || !shouldShowFirstRunHint({ followedCount: count, pathname: "/x" })) return null;
  return <FirstRunNoteView onDiscover={() => router.push("/search", "section")} />;
}
