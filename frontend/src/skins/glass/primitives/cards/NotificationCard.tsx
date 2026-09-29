"use client";

import { Chip } from "../Chip";
import { CardBase } from "./CardBase";

/** One per series: cover 44 x 66, series title `headline`, "3 new · Ch 141–143" `footnote` `iris400`, time `caption1` `label3`, chapter chips that each open the reader. */
export function NotificationCard({ title, cover, chapters, time, onOpen, onChapter }: { title: string; cover: string; chapters: readonly number[]; time: string; onOpen: () => void; onChapter: (n: number) => void }) {
  const range = chapters.length > 1 ? `Ch ${chapters[0]}–${chapters[chapters.length - 1]}` : `Ch ${chapters[0]}`;
  return (
    <CardBase label={`${title}, ${chapters.length} new, ${range}, ${time}`} onPress={onOpen} className="g-notif">
      <img className="g-notif__cover" src={cover} alt="" draggable={false} />
      <div className="g-notif__text">
        <div className="g-notif__top"><h4 className="type-headline">{title}</h4><span className="type-caption1 g-notif__time">{time}</span></div>
        <p className="type-footnote g-notif__new">{chapters.length} new · {range}</p>
        <div className="g-notif__chips">{chapters.slice(0, 6).map((n) => <Chip key={n} label={`Ch ${n}`} onPress={() => onChapter(n)} />)}</div>
      </div>
    </CardBase>
  );
}
