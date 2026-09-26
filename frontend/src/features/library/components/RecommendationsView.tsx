"use client";

import type { ReactNode } from "react";
import { Heart, TriangleAlert } from "lucide-react";
import { SearchResultCardSkeleton } from "@/features/library/components/GlobalSearchResultCard";
import { SuggestionPromptBox } from "@/features/library/components/SuggestionPromptBox";
import { WorldTitleCard } from "@/features/library/components/WorldTitleCard";
import { suggestionsSubtitle } from "@/features/library/suggestions";
import {
  useSuggestAvailability,
  useWorldRecommendations,
  useWorldSuggest,
} from "@/features/library/hooks";
import type { WorldItem } from "@/features/library/types";
import { EmptyState } from "@/components/ui/empty-state";
import { OfflineState } from "@/components/ui/offline-state";
import { apiErrorMessage, resolveViewState } from "@/lib/view-state";

const GRID_CLASS = "grid gap-3 md:grid-cols-2 xl:grid-cols-3";

function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-muted">
      {children}
    </h2>
  );
}

function WorldGrid({ items }: { items: WorldItem[] }) {
  return (
    <div className={GRID_CLASS}>
      {items.map((item) => (
        <WorldTitleCard key={item.anilist_id} item={item} />
      ))}
    </div>
  );
}

function SkeletonGrid({ count }: { count: number }) {
  return (
    <div className={GRID_CLASS}>
      {Array.from({ length: count }).map((_, i) => (
        <SearchResultCardSkeleton key={i} />
      ))}
    </div>
  );
}

/**
 * "Find something to read": titles from the whole world, not just what this
 * server's sources happen to have cached.
 *
 * Each card says whether one of the reader's sources carries the title — if
 * one does, it opens there; if none does, the reader still learns what it is,
 * how far along it is and how it rates, and gets a search and the official
 * platform instead of a dead tap.
 *
 * The genre chips that used to sit at the bottom are gone: they searched
 * titles for a genre word and returned noise.
 */
export function RecommendationsView() {
  const worldQuery = useWorldRecommendations();
  const availabilityQuery = useSuggestAvailability();
  const suggest = useWorldSuggest();

  // An unconfigured server is a deployment state, not something to put in
  // front of a reader: the box is simply absent and the picks remain.
  const canAsk = availabilityQuery.data?.available === true;
  const suggestions = suggest.data?.items ?? [];

  const forYou = worldQuery.data?.for_you ?? [];
  const sections = (worldQuery.data?.sections ?? []).filter((s) => s.items.length > 0);
  const unavailableReason = worldQuery.data?.unavailable_reason ?? null;

  const viewState = resolveViewState({
    isLoading: worldQuery.isLoading,
    error: worldQuery.error,
    isEmpty: forYou.length === 0 && sections.length === 0,
  });

  return (
    <div className="page-shell">
      <div className="page-container">
        <div className="mb-8">
          <h1 className="page-title">Find something to read</h1>
          <p className="page-subtitle">
            {suggestionsSubtitle(canAsk, availabilityQuery.data?.reason)}
          </p>
        </div>

        {canAsk ? (
          <SuggestionPromptBox
            onSubmit={(prompt) => suggest.mutate({ prompt })}
            isPending={suggest.isPending}
            remainingToday={availabilityQuery.data?.remaining_today}
          />
        ) : null}

        {suggest.isPending ? (
          <div className="mb-10">
            <SkeletonGrid count={4} />
          </div>
        ) : suggest.isError ? (
          <div className="mb-10">
            <EmptyState
              tone="error"
              icon={TriangleAlert}
              title="Couldn't suggest anything"
              description={apiErrorMessage(suggest.error, "Try describing it differently.")}
            />
          </div>
        ) : suggestions.length > 0 ? (
          <div className="mb-10">
            <WorldGrid items={suggestions} />
          </div>
        ) : null}

        {/* Quiet on purpose: the catalogue being unreachable is not the
            reader's problem to solve, and the rest of the page still works. */}
        {unavailableReason ? (
          <p className="mb-6 text-sm text-muted">{unavailableReason}</p>
        ) : null}

        {viewState === "loading" ? (
          <section>
            <SectionTitle>For you</SectionTitle>
            <SkeletonGrid count={6} />
          </section>
        ) : viewState === "offline" ? (
          <OfflineState
            reason="Recommendations need a connection to load."
            onRetry={() => void worldQuery.refetch()}
          />
        ) : viewState === "error" ? (
          <EmptyState
            tone="error"
            icon={TriangleAlert}
            title="Couldn't load recommendations"
            description={apiErrorMessage(worldQuery.error, "Something went wrong.")}
            action={{ label: "Try again", onClick: () => void worldQuery.refetch() }}
          />
        ) : viewState === "empty" ? (
          // Empty with a reason means the catalogue was unreachable, which
          // the notice above already says; empty without one means there is
          // no reading history to start from yet.
          unavailableReason ? null : (
            <EmptyState
              icon={Heart}
              title="Nothing to go on yet"
              description="Read or follow a few series first — picks here start from what you read."
              action={{ label: "Browse Sources", href: "/sources" }}
            />
          )
        ) : (
          <div className="space-y-10">
            {forYou.length > 0 ? (
              <section>
                <SectionTitle>For you</SectionTitle>
                <WorldGrid items={forYou} />
              </section>
            ) : null}
            {sections.map((section) => (
              <section key={`${section.because.source_id}:${section.because.series_key}`}>
                <SectionTitle>Because you read {section.because.title}</SectionTitle>
                <WorldGrid items={section.items} />
              </section>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
