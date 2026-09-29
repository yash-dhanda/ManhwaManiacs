"use client";

import Link from "next/link";
import { useState } from "react";
import { downloadMarkState } from "@/features/offline/download-mark";
import { Glyph } from "../Glyph";
import { Menu, type MenuEntry } from "../Menu";
import { DownloadMark } from "../downloads/DownloadMark";
import type { ChapterRow } from "../chapter-rows";
import type { SeriesPage } from "../use-series-page";
import { useReaderEntry } from "../reader-entry";
import { useSwipeRow } from "../swipe-row";
import s from "../feature.module.css";
import t from "../type.module.css";

/** §7.16 chapter row, 56 px: number, title + caption, progress, download mark. */
export function ScheduleRow({
  page,
  row,
  current,
  focused,
  index,
}: {
  page: SeriesPage;
  row: ChapterRow;
  current: boolean;
  focused: boolean;
  index: number;
}) {
  const { picker } = page;
  const enter = useReaderEntry();
  const href = page.chapterHref(row.id);
  const [menu, setMenu] = useState(false);
  const swipe = useSwipeRow({ enabled: page.online && !picker.selecting, onCommit: () => page.markOne(row.id), onLongPress: () => setMenu(true) });
  const selected = picker.selecting && picker.isSelected(row.id);
  const dlState = picker.stateOf(row.id);
  const saved = dlState === "saved";
  const mark = downloadMarkState(picker.downloads.saved.get(row.id), dlState === "queued");
  const need = page.online ? undefined : "Needs a connection.";

  const entries: MenuEntry[] = [
    { label: "Mark read", disabled: !page.online, title: need, onSelect: () => page.markOne(row.id) },
    { label: "Mark read up to here", disabled: !page.online, title: need, onSelect: () => page.markUpTo(row.id) },
    { label: "Mark unread", disabled: !page.online, title: need, onSelect: () => void page.markUnread(row.id) },
    { label: "Download", onSelect: () => void picker.downloads.download([row.id]) },
  ];

  const open = (e: React.MouseEvent) => {
    if (picker.selecting) {
      e.preventDefault();
      if (!saved) picker.pick(row.id, e.shiftKey);
      return;
    }
    e.preventDefault();
    enter(href);
  };

  const cls = [
    s.row,
    row.completed ? s.rowRead : "",
    current ? s.rowCurrent : "",
    selected ? s.rowSelected : "",
    picker.selecting && saved ? s.rowDisabled : "",
  ].join(" ");

  return (
    <div role="listitem" className={s.swipeWrap} data-row={index} data-focused={focused || undefined} data-swiping={swipe.swiping || undefined} onContextMenu={(e) => { e.preventDefault(); setMenu(true); }}>
      {swipe.swiping ? (
        <div aria-hidden="true" className={s.slab} style={{ width: swipe.slab }}>
          <Glyph name="check" />
        </div>
      ) : null}
      <div className={cls} style={swipe.style} {...swipe.handlers}>
        <Link
          href={href}
          className={s.rowMain}
          aria-current={current ? "location" : undefined}
          onClick={open}
          onPointerDown={() => page.prefetchP1(row.id)}
          onMouseEnter={() => page.hover.enter(row.id)}
          onMouseLeave={() => page.hover.leave()}
          onFocus={() => page.hover.enter(row.id)}
          onBlur={() => page.hover.leave()}
        >
          <span className={`${t.folioLg} ${s.num}`}>
            {picker.selecting ? (
              <span className={`${s.check} ${selected || saved ? s.checkOn : ""} ${saved ? s.checkDim : ""}`} aria-hidden="true" style={{ marginRight: 12 }} />
            ) : null}
            {row.ordinal ?? "·"}
          </span>
          <span className={s.rowTitle}>
            <div className={t.title}>
              {row.title ?? (row.ordinal ? `Chapter ${row.ordinal}` : "Chapter")}
              {current ? <span className={`${t.micro} ${s.badge}`}>READING</span> : null}
            </div>
            <div className={`${t.caption} ${s.rowCap} ${mark.kind === "failed" ? s.err : ""}`}>
              {[row.date, row.pages > 0 ? `${row.pages} PAGES` : null].filter(Boolean).join(" · ")}
            </div>
          </span>
          <span className={t.folio}>
            {row.completed ? (
              <span className={`${t.micro} ${s.readMark}`}>READ</span>
            ) : row.inProgress && row.pages > 0 ? (
              <span className={s.progress}>{row.page}/{row.pages}</span>
            ) : null}
          </span>
        </Link>
        <span className={s.rowTools}>
          {!row.completed && !picker.selecting ? (
            <button type="button" className={`${s.icon} ${s.hoverTool}`} aria-label={`Mark chapter ${row.ordinal ?? ""} read`} title={need ?? "Mark read"} disabled={!page.online} onClick={() => page.markOne(row.id)}>
              <Glyph name="check" size={20} />
            </button>
          ) : null}
          <DownloadMark
            state={mark}
            onPress={() => void picker.downloads.download([row.id])}
            disabled={picker.downloads.unavailable}
          />
          <Menu entries={entries} label={`Chapter ${row.ordinal ?? ""} actions`} open={menu} onOpenChange={setMenu} />
        </span>
      </div>
    </div>
  );
}
