"use client";

import { useSyncExternalStore } from "react";

/**
 * `confirmAlert` (glass 7.11): opens the Glass alert and resolves `true` (confirm) or `false` (cancel, Esc). It is the default
 * `onRequestConfirm` of a standalone HoldToConfirm, so a click on a hold button always reaches an explicit confirm button.
 * The `AlertHost` mounted by the Shell (and by the gallery) renders whatever is queued here, one alert at a time.
 */
export interface ConfirmAlertOptions {
  title: string;
  body?: string;
  confirmLabel?: string;
  cancelLabel?: string;
  destructive?: boolean;
  /** the control that opened it: the alert blooms out of it and focus returns to it */
  source?: HTMLElement | null;
  /** async work run by the confirm button: the alert shows pending, and stays open with the error if it throws */
  onConfirm?: () => Promise<void> | void;
}

export interface ConfirmRequest extends ConfirmAlertOptions { id: number; resolve: (ok: boolean) => void }

let seq = 0;
let queue: ConfirmRequest[] = [];
const subs = new Set<() => void>();
const emit = () => { queue = [...queue]; subs.forEach((s) => s()); };

export function confirmAlert(opts: ConfirmAlertOptions): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    queue = [...queue, { ...opts, id: ++seq, resolve }];
    emit();
  });
}

export function settleConfirm(id: number, ok: boolean): void {
  const r = queue.find((q) => q.id === id);
  if (!r) return;
  queue = queue.filter((q) => q.id !== id);
  emit();
  r.resolve(ok);
}

const subscribe = (cb: () => void) => (subs.add(cb), () => void subs.delete(cb));
/** The alert to show now (the oldest queued one). */
export const useConfirmRequest = (): ConfirmRequest | null => useSyncExternalStore(subscribe, () => queue[0] ?? null, () => null);
