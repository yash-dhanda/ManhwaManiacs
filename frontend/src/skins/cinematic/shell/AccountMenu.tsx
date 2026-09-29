"use client";
import { Avatar } from "../primitives/Avatar";
import { ConfirmDialog } from "../primitives/ConfirmDialog";
import { Menu } from "../primitives/Menu";
import { dip } from "./Overlays";
import { useLogout } from "@/features/auth/hooks";
import { useCineRouter } from "./use-cine-router";
import { useShellState } from "./shell-state";
import { useActiveProfileStore } from "@/features/profiles/store";
import type { User } from "@/features/auth/types";

/** Sign out with the shared confirm (§8.33): "Sign out on this device?", then `useLogout()` and `/login` with a Dip. */
export function useSignOut() {
  const set = useShellState((s) => s.setSignOutOpen);
  return { open: () => set(true) };
}

/** Mounted once in the Shell; the account menu and the palette both open it. */
export function SignOutDialog() {
  const open = useShellState((s) => s.signOutOpen);
  const setOpen = useShellState((s) => s.setSignOutOpen);
  const logout = useLogout();
  const router = useCineRouter();
  const confirm = async () => {
    setOpen(false);
    await dip(async () => { await logout.mutateAsync().catch(() => undefined); router.replace("/login"); });
  };
  return <ConfirmDialog open={open} onOpenChange={setOpen} title="Sign out on this device?" description="You will need your password to come back." confirmLabel="Sign out" destructive onConfirm={confirm} />;
}

/** The profile chip and its account menu: display name, @username, ADMINISTRATOR credit, Switch profile, Settings, Sign out. */
export function AccountMenu({ user, signOut }: { user: User | null | undefined; signOut: ReturnType<typeof useSignOut> }) {
  const profile = useActiveProfileStore((s) => s.activeProfile);
  const router = useCineRouter();
  const name = profile?.name ?? user?.display_name ?? user?.username ?? "Account";
  return (
    <>
      <Menu align="end" trigger={
        <button type="button" aria-label={`Account menu, ${name}`} data-account-chip className="type-ui inline-flex min-h-8 items-center gap-2 px-1 text-ink-100">
          <Avatar presetKey={profile?.avatar_key} size={32} label="" />
          <span className="max-w-32 truncate">{name}</span>
        </button>}
        items={[
          { id: "who", label: <span className="flex flex-col"><span>{user?.display_name || user?.username}</span><span className="type-caption text-ink-45">{user ? `@${user.username}` : ""}</span>{user?.is_admin ? <span className="type-kicker text-spot">ADMINISTRATOR</span> : null}</span>, disabled: true },
          { id: "switch", label: "Switch profile", icon: "circle", separatorBefore: true, onSelect: () => { void dip(() => router.push("/profiles?switch=1")); } },
          { id: "settings", label: "Settings", icon: "settings", onSelect: () => router.push("/settings", "section") },
          { id: "signout", label: "Sign out", icon: "back", destructive: true, separatorBefore: true, onSelect: signOut.open },
        ]} />
    </>
  );
}
