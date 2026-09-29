import { readHapticsEnabled, webHapticsAvailable } from "@/features/preferences/feedback";
import type { HapticEvent } from "../contract.generated";
import { hapticsWeb } from "./tokens.generated";

/** Web vibration for Cinematic's five events (cinematic §5). Every other event is a no-op. */
export function haptic(event: HapticEvent): void {
  const pattern = (hapticsWeb as Partial<Record<HapticEvent, readonly number[]>>)[event];
  if (!pattern || !webHapticsAvailable() || !readHapticsEnabled()) return;
  navigator.vibrate([...pattern]);
}
