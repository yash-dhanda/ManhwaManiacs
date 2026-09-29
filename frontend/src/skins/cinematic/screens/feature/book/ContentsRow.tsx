"use client";

import Link from "next/link";
import { useRef, useState } from "react";
import { downloadMarkState } from "@/features/offline/download-mark";
import { tocEntry } from "@/features/novels/book";
import { formatChapterLength } from "@/features/novels/reading-time";
import { Glyph } from "../Glyph";
import { Menu, type MenuEntry } from "../Menu";
import { DownloadMark } from "../downloads/DownloadMark";
import type { ChapterRow } from "../chapter-rows";
import { useReaderEntry } from "../reader-entry";
import type { SeriesPage } from "../use-series-page";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §7.16 contents row, 48 px: ordinal, title, dot leaders, length, state mark. */
export function ContentsRow({
  page,
  row,
  words,
  narrated,
  focused,
  index,
}: {
  page: SeriesPage;
  row: ChapterRow;
  words: number | undefined;
  narrated: boolean;
  focused: boolean;
  index: number;
}) {
  const { picker } = page;
  const enter = useReaderEntry();
  const href = page.chapterHref(row.id);
  const [menu, setMenu] = useState(false);
  const long = useRef<ReturnType<typeof setTimeout> | null>(null);
  const entry = tocEntry({ number: row.number, title: row.title });
  const selected = picker.selecting && picker.isSelected(row.id);
  const dl = picker.stateOf(row.id);
  const saved = dl === "saved";
  const mark = downloadMarkState(picker.downloads.saved.get(row.id), dl === "queued");
  const need = page.online ? undefined : "Needs a connection.";
  const length = formatChapterLength(words)?.split(" · ")[1]?.replace("~", "").toUpperCase();

  const entries: MenuEntry[] = [
    { label: "Mark read", disabled: !page.online, title: need, onSelect: () => page.markOne(row.id) },
    { label: "Mark read up to here", disabled: !page.online, title: need, onSelect: () => page.markUpTo(row.id) },
    { label: "Mark unread", disabled: !page.online, title: need, onSelect: () => void page.markUnread(row.id) },
    { label: "Download", onSelect: () => void picker.downloads.download([row.id]) },
  ];

  return (
    <div
      role="listitem"
      id={`toc-${row.id}`}
      data-row={index}
      className={`${s.menuAnchor} ${focused ? s.tocFocus : ""}`}
      aria-current={focused ? "location" : undefined}
      onContextMenu={(e) => {
        e.preventDefault();
        setMenu(true);
      }}
      onTouchStart={() => (long.current = setTimeout(() => setMenu(true), 450))}
      onTouchEnd={() => long.current && clearTimeout(long.current)}
      onTouchMove={() => long.current && clearTimeout(long.current)}
    >
      <div className={`${s.row} ${row.completed ? s.rowRead : ""} ${selected ? s.rowSelected : ""}`} style={{ gridTemplateColumns: "1fr auto", minHeight: 48 }}>
        <Link
          href={href}
          className={s.tocRow}
          onClick={(e) => {
            e.preventDefault();
            if (picker.selecting) {
              if (!saved) picker.pick(row.id, e.shiftKey);
            } else enter(href);
          }}
          onMouseEnter={() => page.hover.enter(row.id)}
          onMouseLeave={() => page.hover.leave()}
        >
          <span className={`${t.folio} ${s.num}`} style={{ color: "inherit" }}>
            {picker.selecting ? <span className={`${s.check} ${selected || saved ? s.checkOn : ""}`} aria-hidden="true" /> : entry.ordinal ?? "·"}
          </span>
          <span className={s.tocTitle}>{entry.title ?? `Chapter ${entry.ordinal ?? ""}`}</span>
          <span className={s.leader} aria-hidden="true" />
          <span className={t.folio}>{length ?? ""}</span>
          <span className={t.folio}>
            {row.completed ? (
              <span className={s.readMark}>READ</span>
            ) : row.inProgress ? (
              <span className={s.progress}>{row.pages > 0 ? Math.round((row.page / row.pages) * 100) : 0}%</span>
            ) : null}
            {narrated ? <span title="Narrated" style={{ marginLeft: 6, display: "inline-flex", width: 16, verticalAlign: "middle" }}><Glyph name="headphones" /></span> : null}
          </span>
        </Link>
        <span className={s.rowTools}>
          <DownloadMark state={mark} onPress={() => void picker.downloads.download([row.id])} disabled={picker.downloads.unavailable} />
          <Menu entries={entries} label={`Chapter ${entry.ordinal ?? ""} actions`} open={menu} onOpenChange={setMenu} />
        </span>
      </div>
    </div>
  );
}
