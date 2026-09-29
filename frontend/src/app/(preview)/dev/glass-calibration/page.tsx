import { notFound } from "next/navigation";
import { Calibration } from "@/skins/glass/dev/Calibration";

export const metadata = { title: "Glass calibration" };

/** Developer-only checkerboard page for the Glass material (glass/DESIGN.md 15.8). Never in production. */
export default async function GlassCalibrationPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  if (process.env.NODE_ENV === "production") notFound();
  const q = await searchParams;
  const one = (v: string | string[] | undefined) => (Array.isArray(v) ? v[0] : v);
  return (
    <div data-skin="glass">
      <Calibration renderer={one(q.renderer)} section={one(q.section)} />
    </div>
  );
}
