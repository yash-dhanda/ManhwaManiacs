/** Long-form audio in progress; UI sounds stay silent while any of it plays. */
const active = new Set<"narration" | "soundscape">();

export function setAudioActivity(kind: "narration" | "soundscape", on: boolean): void {
  if (on) active.add(kind);
  else active.delete(kind);
}

export const isOtherAudioActive = (): boolean => active.size > 0;
