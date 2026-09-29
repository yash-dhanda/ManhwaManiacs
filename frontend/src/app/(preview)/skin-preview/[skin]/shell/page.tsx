import { notFound } from "next/navigation";
import { ShellGallery } from "@/skins/cinematic/gallery/ShellGallery";

/** Development-only gallery of the Cinematic shell: /skin-preview/cinematic/shell. */
export default async function ShellGalleryPage({ params }: { params: Promise<{ skin: string }> }) {
  const { skin } = await params;
  if (skin !== "cinematic" || process.env.NODE_ENV === "production") notFound();
  return <ShellGallery />;
}
