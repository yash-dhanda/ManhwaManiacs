import { Suspense } from "react";
import { SearchView } from "@/features/library/components/SearchView";

export default function SearchPage() {
  return (
    // The view seeds its box from `?q=`, and `useSearchParams` has to sit
    // under a Suspense boundary or it opts the whole route out of static
    // rendering.
    <Suspense fallback={<div className="p-6 text-muted">Loading search…</div>}>
      <SearchView />
    </Suspense>
  );
}
