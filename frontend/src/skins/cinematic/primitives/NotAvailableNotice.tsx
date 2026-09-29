"use client";
import type { NotAvailableKind } from "@/lib/not-available";
import { useCineRouter } from "../shell/use-cine-router";
import { Notice } from "./Notice";

/**
 * §8.0.10 "no longer available": removed and 18+-gated content answer with the same words, so the wording never reveals the gate.
 * Screens pick the variant with `notAvailableKind(error)`.
 */
export function NotAvailableNotice({ kind, title, sourceId }: { kind: NotAvailableKind; title?: string; sourceId?: string }) {
  const router = useCineRouter();
  if (kind === "not-browsable") {
    return <Notice page tone="empty" kicker="NOT IN THIS ISSUE" headline="This source can only be searched, not browsed."
      primary={{ label: "Search it", onPress: () => router.push(sourceId ? `/sources/${encodeURIComponent(sourceId)}?mode=search` : "/search") }}
      quiet={{ label: "Back to Tonight", onPress: () => router.push("/", "section") }} />;
  }
  return (
    <Notice page tone="empty" kicker="NOT IN THIS ISSUE" headline={kind === "source" ? "This source isn't available here any more." : "This series isn't available here any more."}
      deck="It may have been removed from its source."
      primary={{ label: "Back to Tonight", onPress: () => router.push("/", "section") }}
      quiet={{ label: "Search for it", onPress: () => router.push(title ? `/search?q=${encodeURIComponent(title)}` : "/search") }} />
  );
}
