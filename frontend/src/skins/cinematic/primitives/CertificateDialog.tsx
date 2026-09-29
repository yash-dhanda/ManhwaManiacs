"use client";
import { Dialog as BaseDialog } from "@base-ui/react/dialog";
import { useEffect, useState } from "react";
import { durMs } from "../tokens.generated";
import { Button } from "./Button";
import { Certificate } from "./Certificate";
import { Checkbox } from "./Checkbox";
import { Dialog } from "./Dialog";
import { useDesktopFrame } from "./overlay-hooks";

const BODY = "Adult (18+) sources, series, search results and recommendations will appear throughout ManhwaManiacs for this profile. Only continue if you are of legal age where you live. You can turn this off any time.";

/**
 * §7.24 shell: full screen on the phone frame (a Takeover with its own close), a 560 px Dialog on the desktop frame. The mutation,
 * invalidation, toasts and local filtering are the caller's (web/07). `onConfirm` runs with the button in its loading state, then the stamp plays.
 */
export function CertificateDialog({ open, onOpenChange, profileName, onConfirm, onCancel, ...rest }: {
  open: boolean; onOpenChange: (o: boolean) => void; profileName?: string; onConfirm: () => Promise<void>; onCancel: () => void; "data-gallery"?: string;
}) {
  const desktop = useDesktopFrame();
  const [ok, setOk] = useState(false);
  const [busy, setBusy] = useState(false);
  const [stamped, setStamped] = useState(false);
  const [error, setError] = useState<string | undefined>();
  useEffect(() => { if (open) { setOk(false); setBusy(false); setStamped(false); setError(undefined); } }, [open]); // eslint-disable-line react-hooks/set-state-in-effect -- reset per open
  const title = profileName ? `Show mature content on ${profileName}?` : "Show mature content on this profile?";
  const close = () => { onCancel(); onOpenChange(false); };
  const confirm = async () => {
    setBusy(true); setError(undefined);
    try { await onConfirm(); setStamped(true); setTimeout(() => { setStamped(false); onOpenChange(false); }, durMs.beat + 200); }
    catch (e) { setError(e instanceof Error ? e.message : "That did not work. Try again."); }
    finally { setBusy(false); }
  };
  const content = (
    <div className={`flex gap-6 ${desktop ? "flex-row items-start" : "flex-col items-start"}`}>
      <Certificate stamped={stamped} />
      <div className="flex min-w-0 flex-col gap-3">
        <p className="type-kicker text-proof">RESTRICTED · THIS PROFILE ONLY</p>
        <h2 className={`${desktop ? "type-headline [font-size:0.6em]" : "type-subhead"} text-ink-100`}>{title}</h2>
        <p className="type-body max-w-[48ch] text-ink-60">{BODY}</p>
        <Checkbox checked={ok} onCheckedChange={setOk} label="I am 18 or older" />
        {error ? <p role="alert" className="type-caption text-proof">{error}</p> : null}
      </div>
    </div>
  );
  const actions = (
    <>
      <Button variant="quiet" onClick={close}>Cancel</Button>
      <Button variant="primary" loading={busy} disabled={!ok} disabledReason={!ok ? "Tick the box to continue" : undefined} onClick={confirm}>Enable 18+</Button>
    </>
  );
  if (desktop) {
    return <Dialog open={open} onOpenChange={(o) => { if (!o) close(); else onOpenChange(o); }} title="Mature content" dismissible={!busy} actions={actions} data-gallery={rest["data-gallery"]}>{content}</Dialog>;
  }
  return (
    <BaseDialog.Root open={open} onOpenChange={(o) => { if (!o && !busy) close(); }}>
      <BaseDialog.Portal>
        <BaseDialog.Popup data-stock="raised" data-gallery={rest["data-gallery"]} className="cine-rise fixed inset-0 flex flex-col bg-paper-1 text-ink-100 outline-none" style={{ zIndex: "var(--mm-z-dialog)" }}>
          <header className="flex min-h-14 items-center justify-between px-5"><BaseDialog.Title className="type-kicker text-ink-45">MATURE CONTENT</BaseDialog.Title>
            <BaseDialog.Close className="type-label min-h-(--mm-hit-min) min-w-(--mm-hit-min) px-2 text-ink-60">Close</BaseDialog.Close></header>
          <div className="flex-1 overflow-y-auto px-5 py-4">{content}</div>
          <div className="flex flex-col-reverse gap-2 px-5 pb-6 [&>*]:justify-center">{actions}</div>
        </BaseDialog.Popup>
      </BaseDialog.Portal>
    </BaseDialog.Root>
  );
}
