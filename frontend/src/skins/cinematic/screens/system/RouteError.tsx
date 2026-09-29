"use client";
import { useEffect } from "react";
import { isNetworkUnreachableError } from "@/features/offline/session-gate";
import { Notice } from "../../primitives/Notice";

/** §8.32 route error (`app/(app)/error.tsx` renders it under the Shell): CORRECTION, or OFFLINE EDITION when the server never answered. */
export default function RouteError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => { console.error("Route error:", error); }, [error]);
  const offline = isNetworkUnreachableError(error);
  return (
    <div className="cine-inset" data-status="route-error">
      <Notice page tone={offline ? "offline" : "error"} kicker={offline ? "OFFLINE EDITION" : "CORRECTION"}
        headline={offline ? "The server didn't answer." : "Something broke on this page."}
        deck={offline ? "It may still be starting, or the connection dropped. Your library is untouched." : "Nothing was lost; trying again usually fixes it."}
        primary={{ label: "Try again", onPress: reset }} quiet={{ label: "Back to Tonight", onPress: () => { window.location.assign("/"); } }} />
      {error.digest ? <p className="mt-4"><kbd className="type-folio border border-ink-30 px-2 py-1 text-ink-60">REF {error.digest}</kbd></p> : null}
    </div>
  );
}
