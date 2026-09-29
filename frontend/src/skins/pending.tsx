"use client";

import { useEffect, useState } from "react";
import { usePathname } from "next/navigation";
import type { ScreenProps } from "./types";
import styles from "./pending.module.css";

/**
 * The one skin-neutral "not built yet" screen, used for every unbuilt ScreenId
 * of the Cinematic and Glass skins. Plain on purpose: no skin tokens, no motion.
 */
export default function Pending({ screenId }: ScreenProps) {
  const pathname = usePathname();
  const [skin, setSkin] = useState("PREVIEW");

  useEffect(() => {
    const id = document.documentElement.dataset.skin;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- the skin is only known in the browser
    if (id) setSkin(id.toUpperCase());
  }, []);

  function leave() {
    document.cookie = "mm-skin-debug=; Path=/; Max-Age=0; SameSite=Lax; Secure";
    location.reload();
  }

  return (
    <main
      style={{
        minHeight: "100dvh",
        background: "#000000",
        color: "#F5F5F5",
        fontFamily: 'system-ui, -apple-system, "Segoe UI", Roboto, sans-serif',
        padding: 24,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        boxSizing: "border-box",
      }}
    >
      <div style={{ width: "100%", maxWidth: 560, display: "flex", flexDirection: "column", gap: 16 }}>
        <p
          style={{
            margin: 0,
            fontSize: 12,
            lineHeight: "16px",
            fontWeight: 600,
            textTransform: "uppercase",
            letterSpacing: "0.16em",
            color: "rgba(255,255,255,0.64)",
          }}
        >
          {skin} · NOT BUILT YET
        </p>
        <h1 style={{ margin: 0, fontSize: 28, lineHeight: "34px", fontWeight: 600 }}>{screenId}</h1>
        <p style={{ margin: 0, fontSize: 16, lineHeight: "24px", color: "rgba(255,255,255,0.64)" }}>
          This screen hasn&apos;t been built in this edition yet. It arrives in a later step of the redesign.
        </p>
        <code style={{ fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace', fontSize: 13 }}>{pathname}</code>
        <button type="button" className={styles.leave} onClick={leave}>
          Leave the preview
        </button>
      </div>
    </main>
  );
}
