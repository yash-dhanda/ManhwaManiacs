import { RuleDraw } from "../motion-components";

/** §2.6 Oxford rule: 3 px ink.100 + 2 px gap + 1 px ink.100 on the desktop frame; the 3 px rule.heavy on the phone frame. Drawn after the letters land. */
export function OxfordRule({ delayMs = 0, className = "" }: { delayMs?: number; className?: string }) {
  return (
    <>
      <RuleDraw kind="heavy" delayMs={delayMs} className={`frame:hidden ${className}`} />
      <RuleDraw kind="oxford" delayMs={delayMs} className={`hidden frame:flex ${className}`} />
    </>
  );
}
