import { CollectionDetailView } from "@/features/library";

interface CollectionPageProps {
  params: Promise<{ id: string }>;
}

export default async function CollectionPage({ params }: CollectionPageProps) {
  const { id } = await params;
  return <CollectionDetailView collectionId={Number(id)} />;
}
