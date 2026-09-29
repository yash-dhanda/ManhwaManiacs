import type { ReactNode } from "react";

/** Placeholder frame for a skin whose Shell is not built yet (Cinematic: web/06, Glass: web/29). */
export function PendingShell({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
