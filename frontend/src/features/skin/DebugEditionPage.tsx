"use client";

import { useEffect, useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import { markSkinRestartStart } from "@/lib/motion-timings";
import { isSkinId, type SkinId } from "@/skins/types";
import { clearSkinCookie, DEBUG_KEY, readCookie, restartInto } from "./skin-storage";
import styles from "./DebugEditionPage.module.css";

// release/00 changes this to ["cinematic", "glass"] when it deletes `legacy`; web/25 expects that.
export const DEBUG_SKINS = ["legacy", "cinematic"] as const;

const FADE_MS = 200;
const RETURN = "/settings/diagnostics?debug=1";
const label = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/** The pre-flip edition override row (cinematic §8.0.7). Skin-neutral; never touches the profile. */
const noop = () => () => {};

/** "<gate>|<rendered skin>|<override>", or null on the server. A string, so the snapshot is stable. */
function snapshot(): string {
  let ok = new URLSearchParams(location.search).get("debug") === "1";
  try {
    ok = ok || sessionStorage.getItem(DEBUG_KEY) === "1";
  } catch {
    // storage blocked: the query alone decides
  }
  const v = document.documentElement.dataset.skin;
  return `${ok ? 1 : 0}|${isSkinId(v) ? v : "legacy"}|${readCookie("mm-skin-debug") ?? ""}`;
}

/** The pre-flip edition override row (cinematic §8.0.7). Skin-neutral; never touches the profile. */
export function DebugEditionPage() {
  const router = useRouter();
  const [status, setStatus] = useState("");
  const [fading, setFading] = useState(false);
  const info = useSyncExternalStore(noop, snapshot, () => null);
  const allowed = info !== null && info.startsWith("1");

  useEffect(() => {
    if (info === null) return;
    if (!info.startsWith("1")) {
      router.replace("/settings");
      return;
    }
    try {
      sessionStorage.setItem(DEBUG_KEY, "1");
    } catch {
      // ignore
    }
  }, [info, router]);

  if (!allowed) return null;
  const [, renderedRaw, overrideRaw] = info.split("|");
  const rendered = renderedRaw as SkinId;
  const override = overrideRaw || null;

  const run = (message: string, then: () => void) => {
    markSkinRestartStart();
    setStatus(message);
    setFading(true);
    window.setTimeout(then, FADE_MS);
  };

  return (
    <main className={styles.page}>
      <h1 className={styles.title}>Edition (debug)</h1>
      <p className={styles.caption}>
        A device override for this browser. It never changes the profile&apos;s edition, and it goes away at the flip.
      </p>
      <p className={styles.line}>Now showing: {rendered}</p>
      <p className={styles.line}>Override: {override ?? "none"}</p>
      <fieldset className={styles.segments}>
        <legend className="sr-only">Edition</legend>
        {DEBUG_SKINS.map((skin) => (
          <label key={skin} className={styles.segment}>
            <input
              className={styles.radio}
              type="radio"
              name="mm-debug-skin"
              value={skin}
              checked={override === skin}
              onChange={() =>
                run(`Restarting in ${label(skin)}…`, () =>
                  restartInto({ cookie: "mm-skin-debug", skin, from: rendered, returnPath: RETURN }),
                )
              }
            />
            {skin.toUpperCase()}
          </label>
        ))}
      </fieldset>
      <button
        type="button"
        className={styles.clear}
        onClick={() =>
          run("Clearing override…", () => {
            clearSkinCookie("mm-skin-debug");
            location.replace(RETURN);
          })
        }
      >
        Clear override
      </button>
      <p className={styles.status} aria-live="polite">
        {status}
      </p>
      <div className={`${styles.overlay} ${fading ? styles.overlayOn : ""}`} aria-hidden="true" />
    </main>
  );
}
