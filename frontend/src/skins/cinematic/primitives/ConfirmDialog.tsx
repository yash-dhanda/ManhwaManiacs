"use client";
import { useEffect, useRef, useState } from "react";
import { haptic } from "../haptics";
import { Button } from "./Button";
import { Checkbox } from "./Checkbox";
import { Dialog } from "./Dialog";
import { phraseMatches } from "./arm";
import { ArmButton } from "./ArmButton";
import { TextField } from "./TextField";
import { useArm } from "./useArm";

export type ConfirmDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description?: React.ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  /** Destructive confirms open with the committing button disabled for 1000 ms (the arm). */
  destructive?: boolean;
  onConfirm: () => Promise<void> | void;
  error?: string;
  /** Heavy confirms: a typed phrase ("Type RESTORE to confirm", case-insensitive), an acknowledgement, or a typed username. */
  typedPhrase?: string;
  acknowledge?: string;
  typedUsername?: string;
  /** Force the pending state from outside (gallery). */
  pending?: boolean;
  "data-gallery"?: string;
};

/** §7.10 confirm: default, arming, armed, pending, error. Initial focus is on Cancel. */
export function ConfirmDialog({ open, onOpenChange, title, description, confirmLabel, cancelLabel = "Cancel", destructive = false, onConfirm, error, typedPhrase, acknowledge, typedUsername, pending: forcedPending, ...rest }: ConfirmDialogProps) {
  const cancelRef = useRef<HTMLButtonElement>(null);
  const [busy, setBusy] = useState(false);
  const [failure, setFailure] = useState<string | undefined>();
  const [typed, setTyped] = useState("");
  const [ack, setAck] = useState(false);
  const arm = useArm(open && destructive);
  useEffect(() => { if (open) { setTyped(""); setAck(false); setFailure(undefined); setBusy(false); } }, [open]); // eslint-disable-line react-hooks/set-state-in-effect -- reset per open
  const target = typedPhrase ?? typedUsername;
  const conditionMet = (target === undefined || phraseMatches(typed, target)) && (acknowledge === undefined || ack);
  const pending = busy || !!forcedPending;
  const commit = async () => {
    if (destructive ? !arm.canFire(conditionMet) : !conditionMet) return;
    if (destructive) haptic("delete.confirm");
    setBusy(true); setFailure(undefined);
    try { await onConfirm(); onOpenChange(false); } catch (e) { setFailure(e instanceof Error ? e.message : "That did not work. Try again."); } finally { setBusy(false); }
  };
  const phase = destructive ? arm.phase : "armed";
  return (
    <Dialog open={open} onOpenChange={onOpenChange} title={title} description={description} error={error ?? failure} dismissible={!pending} initialFocus={cancelRef} data-gallery={rest["data-gallery"]}
      actions={
        <>
          <button ref={cancelRef} type="button" aria-disabled={pending || undefined} onClick={() => { if (!pending) onOpenChange(false); }}
            className={`type-label inline-flex min-h-12 items-center justify-center px-5 hover:underline hover:underline-offset-4 ${pending ? "text-ink-30" : "text-ink-60"}`}>{cancelLabel}</button>
          {destructive ? (
            <ArmButton phase={phase} ready={conditionMet} pending={pending} filled={!!(typedPhrase || typedUsername || acknowledge)} onPress={commit}>{confirmLabel}</ArmButton>
          ) : (
            <Button variant="primary" loading={pending} disabled={!conditionMet} onClick={commit}>{confirmLabel}</Button>
          )}
        </>
      }>
      {target !== undefined ? (
        <TextField label={typedUsername !== undefined ? `Type your username, ${typedUsername}, to confirm` : `Type ${typedPhrase} to confirm`} value={typed} onChange={(e) => setTyped(e.target.value)} autoComplete="off" />
      ) : null}
      {acknowledge ? <Checkbox checked={ack} onCheckedChange={setAck} label={acknowledge} /> : null}
    </Dialog>
  );
}
