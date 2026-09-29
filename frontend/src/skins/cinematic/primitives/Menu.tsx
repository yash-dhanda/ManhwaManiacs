"use client";
import { Menu as BaseMenu } from "@base-ui/react/menu";
import { Separator } from "@base-ui/react/separator";
import type { ReactElement } from "react";
import { Icon } from "../Icon";
import { Glyph } from "./glyphs";
import { Keycap } from "./Keycap";
import { useDesktopFrame } from "./overlay-hooks";
import type { MenuItemDef } from "./menu-types";

export const MENU_SURFACE = "cine-menu z-(--mm-z-dialog) max-h-[60dvh] min-w-56 overflow-y-auto border border-rule-2 bg-paper-2 text-ink-100 outline-none";

/** The shared item list for Menu and ContextMenu (§7.22): 40 px desktop / 48 px phone, hover and focus fill paper.4 + 2 px ink.100 left bar. */
export function MenuItems({ items }: { items: MenuItemDef[] }) {
  const desktop = useDesktopFrame();
  const h = desktop ? "min-h-10" : "min-h-12";
  return (
    <>
      {items.map((it) => {
        const cls = `group relative flex ${h} w-full cursor-pointer items-center gap-3 px-4 outline-none select-none data-[highlighted]:bg-paper-4 data-[disabled]:cursor-default data-[disabled]:text-ink-30 ${it.destructive ? "text-proof" : "text-ink-100"}`;
        const inner = (
          <>
            <span aria-hidden className="absolute inset-y-0 left-0 w-0.5 bg-ink-100 opacity-0 group-data-[highlighted]:opacity-100" />
            <span className="inline-flex size-5 shrink-0 items-center justify-center">
              {it.checked ? <Glyph name="check" size={20} /> : it.icon ? <Icon name={it.icon} size={20} /> : null}
            </span>
            <span className="type-ui min-w-0 flex-1 text-left">{it.label}</span>
            {it.shortcut ? <Keycap combo={it.shortcut} /> : null}
            {it.submenu ? <Glyph name="caret-right" size={16} /> : null}
          </>
        );
        const label = typeof it.label === "string" ? it.label : it.id;
        return (
          <div key={it.id}>
            {it.separatorBefore ? <Separator className="my-1 h-px bg-rule-1" /> : null}
            {it.submenu ? (
              <BaseMenu.SubmenuRoot>
                <BaseMenu.SubmenuTrigger label={label} className={cls}>{inner}</BaseMenu.SubmenuTrigger>
                <BaseMenu.Portal><BaseMenu.Positioner sideOffset={0}><BaseMenu.Popup data-stock="raised" className={MENU_SURFACE}><MenuItems items={it.submenu} /></BaseMenu.Popup></BaseMenu.Positioner></BaseMenu.Portal>
              </BaseMenu.SubmenuRoot>
            ) : (
              <BaseMenu.Item label={label} disabled={it.disabled} aria-description={it.disabled ? it.disabledReason : undefined} title={it.disabled ? it.disabledReason : undefined}
                onClick={() => it.onSelect?.()} className={cls}>{inner}</BaseMenu.Item>
            )}
          </div>
        );
      })}
    </>
  );
}

/** §7.22 menu. `trigger` is the element that opens it (an IconButton, a Button); arrows, Home/End, type-ahead, Enter, Esc and submenus come from Base UI. */
export function Menu({ trigger, items, open, onOpenChange, align = "end", ...rest }: {
  trigger: ReactElement<Record<string, unknown>>; items: MenuItemDef[]; open?: boolean; onOpenChange?: (o: boolean) => void; align?: "start" | "center" | "end"; "data-gallery"?: string;
}) {
  return (
    <BaseMenu.Root open={open} onOpenChange={onOpenChange}>
      <BaseMenu.Trigger render={trigger} />
      <BaseMenu.Portal>
        <BaseMenu.Positioner align={align} sideOffset={4} className="z-(--mm-z-dialog)">
          <BaseMenu.Popup data-stock="raised" data-gallery={rest["data-gallery"]} className={MENU_SURFACE}><MenuItems items={items} /></BaseMenu.Popup>
        </BaseMenu.Positioner>
      </BaseMenu.Portal>
    </BaseMenu.Root>
  );
}
