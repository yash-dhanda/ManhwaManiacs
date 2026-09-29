import { SourceSeriesDetailView } from "@/features/sources";
import { decodeRouteParam } from "@/lib/route-params";

interface SourceSeriesPageProps {
  params: Promise<{ sourceId: string; seriesKey: string }>;
  /**
   * `chapter` is a chapter KEY to open the contents at — what the novel
   * reader's Contents button links with (`novelContentsHref`). A key, not a
   * number: novel keys are row ordinals and never a printed chapter number.
   */
  searchParams: Promise<{ chapter?: string }>;
}

export default async function SourceSeriesPage({
  params,
  searchParams,
}: SourceSeriesPageProps) {
  const { sourceId, seriesKey } = await params;
  const { chapter } = await searchParams;

  return (
    <SourceSeriesDetailView
      sourceId={decodeRouteParam(sourceId)}
      seriesId={decodeRouteParam(seriesKey)}
      focusChapterKey={chapter?.trim() ? chapter : null}
    />
  );
}
