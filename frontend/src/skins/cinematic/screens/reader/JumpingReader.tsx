"use client";

import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
// TODO(web/12): the Cinematic reader body replaces this legacy host.
// eslint-disable-next-line no-restricted-imports
import { SourceReader } from "@/features/reader/components/SourceReader";
import { useOcrChapter } from "@/features/ocr/hooks";
import { findMatchPage, takeDialogueJump, type DialogueJump } from "@/features/ocr/dialogue-jump";
import { ToastHost } from "../kit/Kit";
import { announceDialogueJump, BubblePulse } from "./BubblePulse";

interface Props {
  sourceId: string;
  seriesKey: string;
  chapterKey: string;
  routePage: number;
}

/** Opens the reader on the page a dialogue hit matched, pulses the bubble, and toasts. */
export function JumpingReader({ sourceId, seriesKey, chapterKey, routePage }: Props) {
  // undefined = not read yet, null = no jump for this chapter.
  const [jump, setJump] = useState<DialogueJump | null | undefined>(undefined);
  const taken = useRef(false);
  useEffect(() => {
    if (taken.current) return;
    taken.current = true;
    setJump(takeDialogueJump(sourceId, seriesKey, chapterKey));
  }, [sourceId, seriesKey, chapterKey]);

  const needsLookup = !!jump && jump.page === null;
  const ocr = useOcrChapter(needsLookup ? { sourceId, seriesKey, chapterKey } : null);
  const lookingUp = needsLookup && ocr.isPending;
  const page = jump ? (jump.page ?? (ocr.data ? findMatchPage(ocr.data.page_texts, jump.q) : null)) : null;
  const ready = jump !== undefined && !lookingUp;

  const announced = useRef(false);
  useEffect(() => {
    if (!ready || !jump || announced.current) return;
    announced.current = true;
    announceDialogueJump(page);
  }, [ready, jump, page]);

  const [host, setHost] = useState<HTMLElement | null>(null);
  useEffect(() => {
    if (!ready || page === null || !jump?.box) return;
    let tries = 0;
    const id = setInterval(() => {
      const el = document.getElementById(`reader-page-${page}`);
      if (el) {
        el.style.position = "relative";
        setHost(el);
        clearInterval(id);
      } else if ((tries += 1) > 40) clearInterval(id);
    }, 150);
    return () => clearInterval(id);
  }, [ready, page, jump]);

  return (
    <>
      {ready ? (
        <SourceReader
          key={`${sourceId}:${seriesKey}:${chapterKey}`}
          sourceId={sourceId}
          seriesKey={seriesKey}
          chapterKey={chapterKey}
          initialPage={page ?? routePage}
        />
      ) : null}
      {host && jump?.box ? createPortal(<BubblePulse box={jump.box} onDone={() => setHost(null)} />, host) : null}
      <ToastHost />
    </>
  );
}
