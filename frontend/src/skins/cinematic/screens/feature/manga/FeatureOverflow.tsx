"use client";

import { updatesApi } from "@/features/updates/api";
import { Menu, type MenuEntry } from "../Menu";
import type { SeriesPage } from "../use-series-page";

const STATUSES: [string, string][] = [
  ["reading", "Reading"],
  ["plan_to_read", "Plan to read"],
  ["on_hold", "On hold"],
  ["completed", "Done"],
  ["dropped", "Dropped"],
];

/** §8.17 D5: the overflow menu, shared by the Feature and Book pages. */
export function FeatureOverflow({
  page,
  seriesUrl,
  onViewCover,
  onAddToShelf,
  onTags,
  onMove,
}: {
  page: SeriesPage;
  seriesUrl?: string | null;
  onViewCover: () => void;
  onAddToShelf: () => void;
  onTags: () => void;
  onMove: () => void;
}) {
  const followed = page.followedId !== null;
  const status = page.follow?.reading_status;
  const mature = page.follow?.mature_override;
  const need = "Needs a connection.";
  const entries: MenuEntry[] = [
    { label: "View cover", onSelect: onViewCover },
    { label: "Add to shelf", onSelect: onAddToShelf, disabled: !followed },
    ...(followed
      ? ([
          ...STATUSES.map(([id, label]) => ({
            label: `Set reading status: ${label}`,
            radio: true,
            checked: status === id,
            onSelect: () => page.patch({ reading_status: id }),
          })),
        ] as MenuEntry[])
      : []),
    { label: "Tags…", onSelect: onTags },
    ...(followed
      ? ([
          { sep: true },
          { label: "Treat as 18+", radio: true, checked: mature === true, onSelect: () => page.setMature(true) },
          { label: "Treat as not 18+", radio: true, checked: mature === false, onSelect: () => page.setMature(false) },
          { label: "Use the source's rating", radio: true, checked: mature == null, onSelect: () => page.setMature(null) },
          { sep: true },
          {
            label: "Check for new chapters",
            disabled: !page.online,
            title: page.online ? undefined : need,
            onSelect: () => {
              void updatesApi.checkFollowed(page.followedId!);
              page.toasts.push(`Checking ${page.title}.`);
            },
          },
        ] as MenuEntry[])
      : []),
    ...(seriesUrl ? ([{ label: "Open the source's page ↗", href: seriesUrl, external: true }] as MenuEntry[]) : []),
    { label: "Find it on another source", href: `/discover?q=${encodeURIComponent(page.title)}` },
    ...(followed
      ? ([
          {
            label: "Move to another source…",
            disabled: !page.online,
            title: page.online ? undefined : "Moving needs a connection.",
            onSelect: onMove,
          },
        ] as MenuEntry[])
      : []),
    {
      label: "Share link",
      onSelect: () => {
        void navigator.clipboard?.writeText(window.location.href);
        page.toasts.push("Link copied.");
      },
    },
    ...(followed
      ? ([{ sep: true }, { label: "Unfollow", danger: true, onSelect: () => void page.toggleFollow() }] as MenuEntry[])
      : []),
  ];
  return <Menu entries={entries} label="More" />;
}
