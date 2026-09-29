"use client";
import { Tooltip as BaseTooltip } from "@base-ui/react/tooltip";
import type { ReactElement, ReactNode } from "react";
import { Keycap } from "./Keycap";

/** §7.2: paper.2 band, 1 px rule.2, caption ink.100, 6 x 8 px padding, after 500 ms hover and at once on keyboard focus. */
export function Tooltip({ label, shortcut, children }: { label: ReactNode; shortcut?: string; children: ReactElement<Record<string, unknown>> }) {
  return (
    <BaseTooltip.Provider delay={500}>
      <BaseTooltip.Root>
        <BaseTooltip.Trigger delay={500} render={children} />
        <BaseTooltip.Portal>
          <BaseTooltip.Positioner sideOffset={6} style={{ zIndex: 50 }}>
            <BaseTooltip.Popup className="type-caption flex items-center gap-2 border border-rule-2 bg-paper-2 px-2 py-1.5 text-ink-100" data-stock="raised">
              {label}
              {shortcut ? <Keycap combo={shortcut} /> : null}
            </BaseTooltip.Popup>
          </BaseTooltip.Positioner>
        </BaseTooltip.Portal>
      </BaseTooltip.Root>
    </BaseTooltip.Provider>
  );
}

/** Wraps `children` in a Tooltip only when there is a reason to show. */
export function MaybeTip({ reason, children }: { reason?: string; children: ReactElement<Record<string, unknown>> }) {
  return reason ? <Tooltip label={reason}>{children}</Tooltip> : children;
}
