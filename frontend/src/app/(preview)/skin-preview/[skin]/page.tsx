import Pending from "@/skins/pending";

// web/18 replaces this with the skin's real Tonight over the demo-feed fixture (cinematic §8.30.3).
export default function SkinPreviewPage() {
  return <Pending screenId="tonight" params={Promise.resolve({})} searchParams={Promise.resolve({})} />;
}
