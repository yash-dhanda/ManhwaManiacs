"use client";

import Link from "next/link";
import { useLimitedSrc, kit as s, cx } from "./Kit";

export interface Book {
  href: string;
  title: string;
  coverUrl: string | null;
  author: string | null;
  chapters: number;
  status: string | null;
  credit: string;
  blurb: string | null;
  transitionName?: string;
}

function BookRow({ b }: { b: Book }) {
  const src = useLimitedSrc(b.coverUrl, "P2");
  const credits = [b.chapters > 0 ? `${b.chapters} CHAPTERS` : null, b.status?.toUpperCase() ?? null, b.credit.toUpperCase()].filter(Boolean).join(" · ");
  return (
    <Link href={b.href} className={cx(s.bookRow, s.focusable)} data-grid-item="" style={{ viewTransitionName: b.transitionName }}>
      <span className={s.bookPlate} aria-hidden>
        {src ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={src} alt="" />
        ) : (
          b.title.slice(0, 1).toUpperCase()
        )}
      </span>
      <span className={s.bookText}>
        <span className={s.bookTitle}>{b.title}</span>
        {b.author ? <span className={s.bookBy}>{`by ${b.author}`}</span> : null}
        <span className={s.folio}>{credits}</span>
        {b.blurb ? <span className={s.bookBlurb}>{b.blurb}</span> : null}
      </span>
    </Link>
  );
}

/** TODO(web/09): stand-in for the §8.9.1 book list (novels mode); web/09 owns the shared component. */
export function BookList({ books, ...rest }: { books: Book[] } & React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={s.bookList} {...rest}>
      {books.map((b) => (
        <BookRow key={b.href} b={b} />
      ))}
    </div>
  );
}
