import { decodeRouteParam } from "@/lib/route-params";
import type { ScreenProps } from "@/skins/types";
import { JumpingReader } from "./JumpingReader";

/**
 * TODO(web/12): stand-in Cinematic reader. It hosts the shared source reader
 * and adds the dialogue jump (seek + bubble pulse + toast); web/12 replaces the
 * reader body and keeps `JumpingReader`'s jump logic.
 */
export default async function ReaderScreen({ params, searchParams }: ScreenProps) {
  const p = await params;
  const { page } = await searchParams;
  const chapter = (p.chapterKey as string[]).map(decodeRouteParam).join("/");
  const n = Number(Array.isArray(page) ? page[0] : page);
  return (
    <JumpingReader
      sourceId={decodeRouteParam(p.sourceId as string)}
      seriesKey={decodeRouteParam(p.seriesKey as string)}
      chapterKey={chapter}
      routePage={Number.isFinite(n) && n > 0 ? n : 1}
    />
  );
}
