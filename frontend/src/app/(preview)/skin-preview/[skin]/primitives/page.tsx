import { notFound } from "next/navigation";
import { Gallery } from "@/skins/cinematic/gallery/Gallery";

/** Development-only gallery of the Cinematic primitives: /skin-preview/cinematic/primitives. */
export default async function PrimitivesGallery({ params }: { params: Promise<{ skin: string }> }) {
  const { skin } = await params;
  if (skin !== "cinematic" || process.env.NODE_ENV === "production") notFound();
  return <Gallery />;
}
