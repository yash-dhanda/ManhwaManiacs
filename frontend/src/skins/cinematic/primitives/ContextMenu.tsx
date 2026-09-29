"use client";
import { ContextMenu as BaseContextMenu } from "@base-ui/react/context-menu";
import { Menu as BaseMenu } from "@base-ui/react/menu";
import type { ReactNode } from "react";
import { MENU_SURFACE, MenuItems } from "./Menu";
import type { MenuItemDef } from "./menu-types";

/** Desktop right-click menu at the pointer (§7.22). Wrap the target; the menu carries the same items as the row's overflow menu. */
export function ContextMenu({ items, children, className = "", ...rest }: { items: MenuItemDef[]; children: ReactNode; className?: string; "data-gallery"?: string }) {
  return (
    <BaseContextMenu.Root>
      <BaseContextMenu.Trigger className={className} data-gallery={rest["data-gallery"]}>{children}</BaseContextMenu.Trigger>
      <BaseMenu.Portal>
        <BaseMenu.Positioner className="z-(--mm-z-dialog)">
          <BaseMenu.Popup data-stock="raised" className={MENU_SURFACE}><MenuItems items={items} /></BaseMenu.Popup>
        </BaseMenu.Positioner>
      </BaseMenu.Portal>
    </BaseContextMenu.Root>
  );
}
