"use client";

import { useEffect, useSyncExternalStore } from "react";
import { WORDMARK_SVG } from "@/skins/cinematic/wordmark.generated";
import { GhostPillButton } from "@/components/premium/GhostPillButton";
import { PrimaryPillButton } from "@/components/premium/PrimaryPillButton";
import { StatusScreen } from "@/components/layout/status-screen";
import "./globals.css";

interface GlobalErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

/**
 * Last resort: the ROOT LAYOUT itself threw, so `app/error.tsx` never got to
 * render and this replaces the whole document — which is why it emits its own
 * `<html>`/`<body>`.
 *
 * It styles itself from `globals.css` (so it is still Eclipse Warm) but does
 * NOT load the web fonts or mount any provider: at this point the thing that
 * broke may be exactly one of those, and a fallback that depends on the failure
 * is not a fallback. Recovery is a real navigation rather than a client-side
 * one for the same reason.
 */
const noSubscribe = () => () => {};
const cinematicCookie = () => /(?:^|;\s*)(?:mm-skin|mm-skin-debug)=cinematic(?:;|$)/.test(document.cookie);

/** Cinematic or legacy by the two skin cookies (the layout that stamps `data-skin` is the thing that failed). */
export default function GlobalError(props: GlobalErrorProps) {
  const cinematic = useSyncExternalStore(noSubscribe, cinematicCookie, () => false);
  return cinematic ? <CinematicRootError {...props} /> : <LegacyRootError {...props} />;
}

const BONE = "#F3F0E8";
const btn = { minHeight: 44, padding: "0 24px", borderRadius: 0, border: "1px solid " + BONE, background: BONE, color: "#000000", font: "600 15px system-ui, sans-serif", cursor: "pointer" } as const;

/** Pure HTML with inline styles on #000: no fonts, no providers, nothing that could be the thing that broke (§8.32). */
function CinematicRootError({ error, reset }: GlobalErrorProps) {
  useEffect(() => { console.error("Root layout error:", error); }, [error]);
  return (
    <html lang="en" style={{ background: "#000000", colorScheme: "dark" }}>
      <body style={{ margin: 0, background: "#000000", color: BONE }}>
        <main style={{ minHeight: "100dvh", display: "flex", flexDirection: "column", justifyContent: "center", padding: "0 max(24px, 8vw)", gap: 20, maxWidth: 720 }}>
          <svg role="img" aria-label="ManhwaManiacs" viewBox={WORDMARK_SVG.viewBox} style={{ width: 240, height: "auto" }} dangerouslySetInnerHTML={{ __html: WORDMARK_SVG.inner }} />
          <h1 style={{ margin: 0, font: "700 40px/1.1 Georgia, 'Times New Roman', serif", color: BONE }}>ManhwaManiacs failed to start.</h1>
          <p style={{ margin: 0, font: "400 16px/1.5 system-ui, sans-serif", color: "#9A978F", maxWidth: "48ch" }}>The app shell didn&apos;t render. Reloading usually fixes it; if it doesn&apos;t, check that the server is running.</p>
          <div style={{ display: "flex", gap: 12, flexWrap: "wrap" }}>
            <button type="button" style={btn} onClick={reset}>Try again</button>
            <button type="button" style={btn} onClick={() => window.location.assign("/")}>Reload the app</button>
          </div>
          {error.digest ? <p style={{ margin: 0, font: "400 12px ui-monospace, monospace", color: "#9A978F" }}>REF {error.digest}</p> : null}
        </main>
      </body>
    </html>
  );
}

function LegacyRootError({ error, reset }: GlobalErrorProps) {
  useEffect(() => {
    console.error("Root layout error:", error);
  }, [error]);

  return (
    <html lang="en">
      <body>
        <main className="flex min-h-dvh items-center justify-center bg-bg text-fg">
          <StatusScreen
            code="500"
            title="ManhwaManiacs failed to start"
            description={
              <>
                The application shell could not render. Reloading usually clears
                it; if it does not, the backend or the running build is the place
                to look.
              </>
            }
            actions={
              <>
                <PrimaryPillButton onClick={reset} label="Try again" />
                <GhostPillButton
                  onClick={() => window.location.assign("/")}
                  label="Reload the app"
                />
              </>
            }
            footnote={
              error.digest ? (
                <>
                  Reference{" "}
                  <code className="rounded border border-border bg-surface-2 px-1.5 py-0.5 font-mono text-[11px] text-fg">
                    {error.digest}
                  </code>
                </>
              ) : null
            }
          />
        </main>
      </body>
    </html>
  );
}
