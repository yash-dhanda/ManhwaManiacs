import { notFound } from "next/navigation";
import { Gallery } from "@/skins/glass/dev/Gallery";

export const metadata = { title: "Glass primitives" };

/** Developer-only primitives gallery (web/26). Never in production. */
export default async function GlassPrimitivesPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  if (process.env.NODE_ENV === "production") notFound();
  const q = await searchParams;
  const section = Array.isArray(q.section) ? q.section[0] : q.section;
  return (
    <div data-skin="glass">
      <Gallery section={section} />
    </div>
  );
}
