"use client";

import Link from "next/link";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { X } from "lucide-react";
import { sourceImageUrl } from "@/features/sources/api";
import { sourcesLimiter, type Priority } from "@/features/sources/standins/request-limiter"; // TODO(web/03)
import type { SourceHealth } from "@/features/sources/types";
import { describeHealth } from "@/features/sources/health";
import { Certificate18 } from "../../icons/glyphs.generated";
import s from "./kit.module.css";

export const cx = (...c: Array<string | false | null | undefined>) => c.filter(Boolean).join(" ");
export { s as kit };

/** Letter reveal: per-letter spans (whole-string fade under reduced motion, via CSS). */
export function RevealText({ text, className }: { text: string; className?: string }) {
  return (
    <span className={className} aria-label={text}>
      {Array.from(text).map((ch, i) => (
        <span key={i} className={s.letter} style={{ ["--i" as string]: Math.min(i, 23) }} aria-hidden>
          {ch}
        </span>
      ))}
    </span>
  );
}

export function Masthead({
  kicker,
  title,
  deck,
  focusRef,
  rule = "oxford",
}: {
  kicker: string;
  title: string;
  deck?: ReactNode;
  focusRef: React.RefObject<HTMLHeadingElement | null>;
  rule?: "oxford" | "heavy";
}) {
  return (
    <header>
      <p className={s.kicker}>
        <RevealText text={kicker} />
      </p>
      <h1 ref={focusRef} tabIndex={-1} className={cx(s.masthead, s.h1focus)}>
        <RevealText text={title} />
      </h1>
      {deck ? <p className={s.deck}>{deck}</p> : null}
      <div className={rule === "oxford" ? s.oxford : s.heavy} />
    </header>
  );
}

export function Notice({
  kicker,
  headline,
  deck,
  tone = "note",
  children,
}: {
  kicker: string;
  headline: ReactNode;
  deck?: ReactNode;
  tone?: "note" | "proof";
  children?: ReactNode;
}) {
  return (
    <section className={cx(s.notice, tone === "proof" && s.noticeProof)} role={tone === "proof" ? "alert" : "status"}>
      <div className={s.noticeKicker}>{kicker}</div>
      <p className={s.noticeHead}>{headline}</p>
      {deck ? <p className={s.noticeDeck}>{deck}</p> : null}
      {children ? <div className={s.noticeActions}>{children}</div> : null}
    </section>
  );
}

export function HealthMark({ health, now, showLabel = true }: { health: SourceHealth | null | undefined; now: number; showLabel?: boolean }) {
  const d = describeHealth(health, now);
  return (
    <span className={cx(s.health, s[`h_${d.state}`])} title={health?.last_error ?? undefined}>
      <span className={s.hmark} aria-hidden />
      {showLabel ? <span>{d.label}</span> : <span className={s.sr}>{d.label}</span>}
    </span>
  );
}

/** Assigns an image src only after the limiter grants a slot (P2 covers/logos, P3 hover and dialogue stills). */
export function useLimitedSrc(url: string | null | undefined, priority: Priority, enabled = true): string | null {
  const [src, setSrc] = useState<string | null>(null);
  useEffect(() => {
    if (!url || !enabled) return;
    const ctl = new AbortController();
    sourcesLimiter
      .acquire(priority, ctl.signal)
      .then((release) => {
        setSrc(url);
        release();
      })
      .catch(() => {});
    return () => ctl.abort();
  }, [url, priority, enabled]);
  return url && enabled ? src : null;
}

export function SourceLogo({ id, name, iconUrl, size = 24 }: { id: string; name: string; iconUrl?: string | null; size?: number }) {
  const src = useLimitedSrc(iconUrl ? sourceImageUrl(iconUrl) : null, "P2");
  return (
    <span className={s.logo} style={{ width: size, height: size, fontSize: size * 0.5 }} data-source={id}>
      {src ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img className={s.logoImg} src={src} alt="" width={size} height={size} />
      ) : (
        name.slice(0, 1).toUpperCase()
      )}
    </span>
  );
}

export function Plate({ className, style, children }: { className?: string; style?: React.CSSProperties; children?: ReactNode }) {
  return (
    <div className={cx(s.plate, s.flicker, className)} style={style} aria-hidden>
      {children}
    </div>
  );
}

export function Poster({
  href,
  title,
  coverUrl,
  folio,
  mature,
  transitionName,
  dataAttr,
}: {
  href: string;
  title: string;
  coverUrl: string | null;
  folio?: string | null;
  mature?: boolean;
  transitionName?: string;
  dataAttr?: string;
}) {
  const src = useLimitedSrc(coverUrl, "P2");
  return (
    <Link href={href} className={cx(s.poster, s.focusable)} data-grid-item="" data-poster={dataAttr ?? ""} style={{ viewTransitionName: transitionName }}>
      <div className={s.posterFrame}>
        {src ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img className={s.posterImg} src={src} alt="" loading="lazy" />
        ) : null}
        {mature ? (
          <span className={s.cert} title="18+">
            <Certificate18 size={16} weight="regular" title="18+" />
          </span>
        ) : null}
      </div>
      <p className={s.posterTitle}>{title}</p>
      {folio ? <p className={cx(s.folio, s.captionOn0)}>{folio}</p> : null}
    </Link>
  );
}

// --- toasts -----------------------------------------------------------------

export function toast(message: string, tone: "info" | "error" = "info") {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent("mm:toast", { detail: { message, tone } }));
}

export function ToastHost() {
  const [items, setItems] = useState<Array<{ id: number; message: string; tone: string }>>([]);
  useEffect(() => {
    let n = 0;
    const on = (e: Event) => {
      const { message, tone } = (e as CustomEvent).detail;
      const id = (n += 1);
      setItems((v) => [...v, { id, message, tone }]);
      setTimeout(() => setItems((v) => v.filter((t) => t.id !== id)), tone === "error" ? 6000 : 3600);
    };
    window.addEventListener("mm:toast", on);
    return () => window.removeEventListener("mm:toast", on);
  }, []);
  return (
    <div className={s.toastHost} role="status" aria-live="polite">
      {items.map((t) => (
        <div key={t.id} className={cx(s.toast, t.tone === "error" && s.toastError)}>
          {t.message}
        </div>
      ))}
    </div>
  );
}

/** Column panel on desktop, bottom sheet on phones. */
export function Sheet({ open, onClose, kicker, title, children }: { open: boolean; onClose: () => void; kicker?: string; title: string; children: ReactNode }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const prev = document.activeElement as HTMLElement | null;
    ref.current?.focus();
    const on = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", on);
    return () => {
      window.removeEventListener("keydown", on);
      prev?.focus?.();
    };
  }, [open, onClose]);
  if (!open) return null;
  return (
    <div className={s.scrim} onClick={onClose}>
      <div ref={ref} tabIndex={-1} className={s.sheet} role="dialog" aria-modal="true" aria-label={title} onClick={(e) => e.stopPropagation()}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "start" }}>
          <div>
            {kicker ? <div className={s.kicker}>{kicker}</div> : null}
            <h2 className={s.sheetTitle}>{title}</h2>
          </div>
          <button type="button" className={s.iconBtn} onClick={onClose} aria-label="Close">
            <X size={20} aria-hidden />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function LeaderDial({ big }: { big?: boolean }) {
  return <span className={cx(s.dial, big && s.dialBig)} role="progressbar" aria-label="Loading" />;
}
