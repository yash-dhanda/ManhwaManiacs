"use client";

import { useCallback, useEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { useContentMode } from "@/features/content-mode/use-content-mode";
import { useSuggestAvailability } from "@/features/library/hooks";
import { useOcrAvailable } from "@/features/ocr/hooks";
import { parseDiscoverScope, type DiscoverScope } from "@/features/sources/search-scope";
import { useDebouncedValue } from "@/lib/use-debounced-value";
import { IndexField } from "../kit/IndexField";
import { ToastHost, kit as s } from "../kit/Kit";
import { useScreenChrome } from "../kit/use-screen";
import { AskScope } from "./AskScope";
import { DiscoverIdle } from "./DiscoverIdle";
import { DiscoverResults } from "./DiscoverResults";
import { DiscoverKeys } from "./keys";
import { ScopeTabs, visibleScopes } from "./ScopeTabs";
import d from "./discover.module.css";

function subscribeHash(cb: () => void) {
  window.addEventListener("hashchange", cb);
  return () => window.removeEventListener("hashchange", cb);
}
function readGenreHash(): string | null {
  const m = /genre=([^&]+)/.exec(window.location.hash);
  return m ? decodeURIComponent(m[1]) : null;
}

export default function DiscoverScreen() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const { mode } = useContentMode();
  const ai = useSuggestAvailability().data?.available === true;
  const ocr = useOcrAvailable();
  const caps = useMemo(() => ({ aiAvailable: ai, dialogueAvailable: ocr && mode === "manga" }), [ai, ocr, mode]);
  const scope = parseDiscoverScope(params.get("scope"), caps);
  const scopes = visibleScopes(caps);

  const [raw, setRaw] = useState(params.get("q") ?? "");
  const [debounced] = useDebouncedValue(raw, 300);
  // Enter and Recent chips search at once: `forced` beats the debounce while it still equals the field.
  const [forced, setForced] = useState<string | null>(null);
  const q = forced !== null && forced === raw ? forced : debounced;
  const [asked, setAsked] = useState(0);
  const input = useRef<HTMLInputElement>(null);
  const focusField = useCallback(() => input.current?.focus(), []);
  const h1 = useScreenChrome("Discover", focusField);
  const hash = useSyncExternalStore(subscribeHash, readGenreHash, () => null);

  const write = useCallback(
    (nextQ: string, nextScope: DiscoverScope) => {
      const sp = new URLSearchParams();
      if (nextQ) sp.set("q", nextQ);
      if (nextScope !== "all") sp.set("scope", nextScope);
      const qs = sp.toString();
      router.replace(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [router, pathname],
  );
  useEffect(() => {
    if ((params.get("q") ?? "") !== q.trim()) write(q.trim(), scope);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);
  const setScope = (next: DiscoverScope) => write(raw.trim(), next);

  const trimmed = q.trim();
  const asking = scope === "ask";
  const label = asking ? "Describe what you feel like reading" : "Search every source";

  return (
    <main className={s.page} style={{ position: "relative" }}>
      <div className={s.grade} aria-hidden />
      <div className={`${s.frame} ${s.rel}`}>
        <DiscoverKeys
          scopes={scopes}
          onScope={setScope}
          focusField={focusField}
          firstResult={() => document.querySelector<HTMLElement>("[data-poster]")?.focus()}
        />
        <p className={s.kicker}>No. 04 — DISCOVER</p>
        <h1 ref={h1} tabIndex={-1} className={`${s.sr} ${s.h1focus}`}>Discover</h1>
        <div style={{ maxWidth: "calc(8 / 12 * 100%)", minWidth: "min(100%, 320px)" }}>
          <IndexField
            ref={input}
            value={raw}
            onChange={setRaw}
            onEnter={() => {
              setForced(raw);
              if (asking) setAsked((n) => n + 1);
            }}
            placeholder={asking ? label : "Search every source"}
            label={label}
          />
        </div>
        <div className={d.scopeRow}>
          <ScopeTabs scopes={scopes} value={scope} onChange={setScope} />
        </div>
        {asking ? (
          <AskScope prompt={raw} submitted={asked} onSearchInstead={() => write(raw.trim(), "all")} />
        ) : trimmed === "" ? (
          scope === "dialogue" ? null : (
            <DiscoverIdle aiAvailable={ai} dialogueAvailable={caps.dialogueAvailable} onSearch={(t) => {
                setRaw(t);
                setForced(t);
              }} openGenre={hash} />
          )
        ) : (
          <DiscoverResults
            q={trimmed}
            scope={scope as "all" | "library" | "sources" | "dialogue"}
            dialogueAvailable={caps.dialogueAvailable}
            aiAvailable={ai}
            onAsk={() => write(raw.trim(), "ask")}
          />
        )}
      </div>
      <ToastHost />
    </main>
  );
}
