"use client";
import { useDuotone } from "../../duotone";
import { Button } from "../Button";
import { CineImage } from "../CineImage";

/** §7.6 letter: duotone cover strip 3:2 on the left, kicker `FROM RIYA`, title, the note in quotes, action slots. New = a spot square before the kicker. */
export function LetterCard({ from, title, note, src, duo, isNew, onRead, onAdd, onKeep, onDismiss, "data-gallery": g }: {
  from: string; title: string; note: string; src?: string | null; duo?: string; isNew?: boolean; onRead?: () => void; onAdd?: () => void; onKeep?: () => void; onDismiss?: () => void; "data-gallery"?: string;
}) {
  const filter = useDuotone(duo ?? "#B8B2A4");
  return (
    <article className="cine-poster flex gap-4" data-gallery={g} aria-label={`Letter from ${from}: ${title}`}>
      <div className="relative aspect-[3/2] w-1/3 shrink-0 overflow-hidden bg-paper-1" style={{ filter }}><CineImage src={src} alt="" title={title} /></div>
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <p className="type-kicker flex items-center gap-2 text-ink-45">{isNew ? <span aria-label="New" className="size-2 bg-spot" /> : null}{`FROM ${from.toUpperCase()}`}</p>
        <h3 className="type-subhead text-ink-100">{title}</h3>
        <p className="type-body-italic text-ink-60">&ldquo;{note}&rdquo;</p>
        <div className="mt-2 flex flex-wrap gap-1">
          <Button size="sm" variant="secondary" onClick={onRead}>Read</Button>
          <Button size="sm" variant="quiet" onClick={onAdd}>Add</Button>
          <Button size="sm" variant="quiet" onClick={onKeep}>Keep</Button>
          <Button size="sm" variant="quiet" onClick={onDismiss}>Dismiss</Button>
        </div>
      </div>
    </article>
  );
}
