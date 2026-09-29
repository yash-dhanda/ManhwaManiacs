/** Free storage the device must still have before a chapter is queued unasked. */
export const AUTO_QUEUE_MIN_FREE_BYTES = 1_500_000_000;

export interface AutoQueueInput {
  medium: "manga" | "novel";
  /** An active profile, so saved chapters have an owner. */
  hasProfileScope: boolean;
  serviceWorkerSupported: boolean;
  /** `capabilities.client_downloads` from `GET /settings`. */
  capabilityOn: boolean;
  hasNextChapter: boolean;
  /** The next chapter is already in the offline index (any status). */
  nextSaved: boolean;
  /** This open has already queued the next chapter. */
  alreadyQueued: boolean;
  /** The profile's `mm.downloads.save-next` switch. */
  switchOn: boolean;
  /** `navigator.storage.estimate()` quota minus usage; null when unknown. */
  freeBytes: number | null;
}

/** Whether opening this chapter should queue the one after it. Pure. */
export function shouldAutoQueueNext(i: AutoQueueInput): boolean {
  return (
    i.medium === "manga" &&
    i.hasProfileScope &&
    i.serviceWorkerSupported &&
    i.capabilityOn &&
    i.hasNextChapter &&
    !i.nextSaved &&
    !i.alreadyQueued &&
    i.switchOn &&
    // Unknown storage counts as enough.
    (i.freeBytes === null || i.freeBytes >= AUTO_QUEUE_MIN_FREE_BYTES)
  );
}
