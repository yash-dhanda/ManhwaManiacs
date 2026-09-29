import type { PageBox } from "./still-crop";

const KEY = "mm.dialogue.jump";

export interface DialogueJump {
  sourceId: string;
  seriesKey: string;
  chapterKey: string;
  q: string;
  page: number | null;
  box: PageBox | null;
}

export function writeDialogueJump(jump: DialogueJump): void {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(jump));
  } catch {
    /* storage blocked: the reader just opens at the chapter start */
  }
}

/** Returns the stored jump once, and only for the matching chapter. */
export function takeDialogueJump(sourceId: string, seriesKey: string, chapterKey: string): DialogueJump | null {
  try {
    const raw = sessionStorage.getItem(KEY);
    if (!raw) return null;
    const jump = JSON.parse(raw) as DialogueJump;
    if (jump.sourceId !== sourceId || jump.seriesKey !== seriesKey || jump.chapterKey !== chapterKey) return null;
    sessionStorage.removeItem(KEY);
    return jump;
  } catch {
    return null;
  }
}

const fold = (s: string) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase();

/** First page whose text contains every term of `q` (case and diacritics folded). */
export function findMatchPage(pageTexts: ReadonlyArray<{ page: number; text: string }>, q: string): number | null {
  const terms = fold(q).split(/\s+/).filter(Boolean);
  if (terms.length === 0) return null;
  for (const p of pageTexts) {
    const text = fold(p.text);
    if (terms.every((t) => text.includes(t))) return p.page;
  }
  return null;
}
