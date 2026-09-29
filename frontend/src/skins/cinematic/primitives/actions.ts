import type { IconRole } from "../icons/roles.generated";
import type { MenuItemDef } from "./menu-types";

/** §7.22 standard action ids, labels and icons, in menu order. Callers pass the subset that applies plus the handlers. */
export const ACTIONS = [
  { id: "open", label: "Open", icon: "external" },
  { id: "continue", label: "Continue", icon: "play" },
  { id: "previously-on", label: "Previously on", icon: "history" },
  { id: "add-to-collection", label: "Add to collection", icon: "collections" },
  { id: "favourite", label: "Favourite", icon: "favourite" },
  { id: "mark-read", label: "Mark read", icon: "select" },
  { id: "download-next-5", label: "Download next 5", icon: "download" },
  { id: "recommend", label: "Recommend to…", icon: "recommend" },
  { id: "not-for-me", label: "Not for me", icon: "close" },
  { id: "remove-from-row", label: "Remove from row", icon: "delete" },
  { id: "unfollow", label: "Unfollow", icon: "following", destructive: true },
] as const satisfies readonly { id: string; label: string; icon: IconRole; destructive?: boolean }[];
export type ActionId = (typeof ACTIONS)[number]["id"];

/** Build menu items from the subset of actions that applies, in the standard order. */
export function actionItems(handlers: Partial<Record<ActionId, () => void>>, disabled: Partial<Record<ActionId, string>> = {}): MenuItemDef[] {
  return ACTIONS.filter((a) => a.id in handlers).map((a) => ({
    id: a.id, label: a.label, icon: a.icon, destructive: "destructive" in a ? a.destructive : undefined,
    separatorBefore: a.id === "unfollow", disabled: !!disabled[a.id], disabledReason: disabled[a.id], onSelect: handlers[a.id],
  }));
}
