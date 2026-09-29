import type { ReactNode } from "react";
import type { IconRole } from "../icons/roles.generated";

/** Shared by Menu, ContextMenu, row menus and Quick look (§7.22). */
export type MenuItemDef = {
  id: string;
  label: ReactNode;
  icon?: IconRole;
  /** Keycap combo shown trailing, e.g. "b". */
  shortcut?: string;
  destructive?: boolean;
  checked?: boolean;
  disabled?: boolean;
  disabledReason?: string;
  separatorBefore?: boolean;
  onSelect?: () => void;
  submenu?: MenuItemDef[];
};
