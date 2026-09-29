"use client";

import { use } from "react";
import { useSeries } from "@/features/library/hooks";
import type { ScreenProps } from "../../../types";
import { FeatureView } from "./FeatureView";
import { Galley, NotAvailable } from "./FeatureStates";

/** ScreenId `featureByFollow`: `/library/:followedId`, the same page by follow row. */
export default function FeatureByFollowScreen({ params }: ScreenProps) {
  const p = use(params);
  const id = Number(p.followedId);
  const row = useSeries(Number.isFinite(id) ? id : null);
  if (row.isLoading) return <Galley />;
  if (!row.data) return <NotAvailable />;
  return <FeatureView sourceId={row.data.source_id} seriesKey={row.data.series_key} followedId={row.data.id} />;
}
