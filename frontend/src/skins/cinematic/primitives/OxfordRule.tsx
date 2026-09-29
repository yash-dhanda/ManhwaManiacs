import { RuleDraw } from "../motion-components";

/** §2.6 Oxford rule: 3 px ink.100 + 2 px gap + 1 px ink.100 on the desktop frame; the 3 px rule.heavy on the phone frame. Drawn after the letters land. */
export function OxfordRule({ delayMs = 0, className = "", spotLead = false }: { delayMs?: number; className?: string; spotLead?: boolean }) {
  return (
    <>
      <RuleDraw kind="heavy" spotLead={spotLead} delayMs={delayMs} className={`frame:hidden ${className}`} />
      <RuleDraw kind="oxford" spotLead={spotLead} delayMs={delayMs} className={`hidden frame:flex ${className}`} />
    </>
  );
}
