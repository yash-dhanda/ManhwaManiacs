import { notFound } from "next/navigation";
import { DownloadMarksGallery } from "@/skins/cinematic/screens/feature/downloads/DownloadMarksGallery";

/** Cinematic web/11: the seven per-chapter download marks (§7.18) with their tooltips. */
export default async function Page({ params }: { params: Promise<{ skin: string }> }) {
  if ((await params).skin !== "cinematic") notFound();
  return <DownloadMarksGallery />;
}
