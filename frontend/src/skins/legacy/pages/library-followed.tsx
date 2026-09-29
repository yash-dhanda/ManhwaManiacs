import { SeriesDetailView } from "@/features/library/components/SeriesDetailView";

interface SeriesPageProps {
  params: Promise<{ followedId: string }>;
}

export default async function SeriesPage({ params }: SeriesPageProps) {
  const { followedId } = await params;
  return <SeriesDetailView seriesId={Number(followedId)} />;
}
