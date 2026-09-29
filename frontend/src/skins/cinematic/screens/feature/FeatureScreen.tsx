import { decodeRouteParam } from "@/lib/route-params";
import type { ScreenProps } from "../../../types";
import { FeatureView } from "./FeatureView";

/** ScreenId `feature`: `/sources/:sourceId/series/:seriesKey`. */
export default async function FeatureScreen({ params, searchParams }: ScreenProps) {
  const p = await params;
  const q = await searchParams;
  const chapter = typeof q.chapter === "string" && q.chapter.trim() ? q.chapter : null;
  return (
    <FeatureView
      sourceId={decodeRouteParam(String(p.sourceId))}
      seriesKey={decodeRouteParam(String(p.seriesKey))}
      followedId={null}
      focusChapterKey={chapter}
    />
  );
}
