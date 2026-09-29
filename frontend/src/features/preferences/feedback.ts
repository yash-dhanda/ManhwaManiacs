export const HAPTICS_KEY = "mm.haptics";

/** Device-global; on unless explicitly "off". */
export function readHapticsEnabled(): boolean {
  try {
    return localStorage.getItem(HAPTICS_KEY) !== "off";
  } catch {
    return true;
  }
}

export function writeHapticsEnabled(on: boolean): void {
  try {
    localStorage.setItem(HAPTICS_KEY, on ? "on" : "off");
  } catch {
    // ignore
  }
}

/** Android Chrome only: never iOS Safari, never desktop. The Feedback row renders only when true. */
export function webHapticsAvailable(): boolean {
  try {
    return "vibrate" in navigator && matchMedia("(pointer: coarse)").matches;
  } catch {
    return false;
  }
}
