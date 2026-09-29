"use client";

import { Notice } from "../FeatureStates";

export function BookOffline() {
  return <Notice kicker="OFFLINE" headline="This book needs a connection to load." primary={{ label: "Back to the source", href: "/sources" }} />;
}

export function BookError({ sourceHref, onRetry }: { sourceHref: string; onRetry: () => void }) {
  return (
    <Notice
      kicker="CORRECTION"
      headline="Couldn't load this book."
      primary={{ label: "Try again", onClick: onRetry }}
      secondary={{ label: "Back to the source", href: sourceHref }}
    />
  );
}
