"use client";

import { Tooltip as BaseTooltip } from "@base-ui/react/tooltip";
import { useEffect, useState, type ReactElement, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";

/** Hover delay by level: 600 ms everywhere, 150 ms for the dock and the collapsed sidebar. Keyboard focus opens at once (Base UI). */
export const TOOLTIP_DELAY = { default: 600, bar: 150 } as const;

/**
 * A `glassThin` T2 capsule (a live surface in the budget), min height 36, padding 9 12, `footnote`, 8 px from its target.
 * WCAG 1.4.13 comes from Base UI: the popup is hoverable (a safe polygon across the 8 px gap), Esc closes it without moving
 * focus or the pointer, and it never disappears on its own while the target is hovered or focused.
 */
export function Tooltip({ label, level = "default", disabled = false, children }: { label: ReactNode; level?: "default" | "bar"; disabled?: boolean; children: ReactElement }): ReactElement {
  const [container, setContainer] = useState<HTMLElement | null>(null);
  useEffect(() => { setContainer(document.querySelector<HTMLElement>('[data-skin="glass"]') ?? document.body); }, []);
  if (label == null || label === "") return children;
  return (
    <BaseTooltip.Root disabled={disabled}>
      <BaseTooltip.Trigger delay={TOOLTIP_DELAY[level]} closeDelay={0} render={children} />
      <BaseTooltip.Portal container={container}>
        <BaseTooltip.Positioner sideOffset={8} className="g-tooltip-pos">
          <BaseTooltip.Popup
            className="g-tooltip"
            render={(props) => (
              <GlassSurface {...props} tier="t2" capsule finish="regular" layer="overlays" className="g-tooltip" data-glass-tooltip="">
                <span className="g-label">{props.children}</span>
              </GlassSurface>
            )}
          >
            {label}
          </BaseTooltip.Popup>
        </BaseTooltip.Positioner>
      </BaseTooltip.Portal>
    </BaseTooltip.Root>
  );
}
