"use client";

import { useState } from "react";
import { Button } from "../../primitives/Button";
import { AppUpdateCapsule } from "../../primitives/AppUpdateCapsule";
import { InlineNotice } from "../../primitives/InlineNotice";
import { NewChaptersCapsule } from "../../primitives/NewChaptersCapsule";
import { StatusCapsule } from "../../primitives/StatusCapsule";
import { Row } from "../Grounds";

const covers = [1, 2, 3].map((n) => `/dev-covers/cover-0${n}.svg`);

/** web/27 I: inline notices, status capsules, and the two queued capsules (they wait behind a menu, see `menus`). */
export function BannersSection() {
  const [chapters, setChapters] = useState(false);
  const [update, setUpdate] = useState(false);
  return (
    <div>
      <Row label="Inline notices">
        <InlineNotice tone="info">Your library syncs every 15 minutes.</InlineNotice>
        <InlineNotice tone="warning" action={{ label: "Retry", onPress: () => {} }}>Some sources are slow right now.</InlineNotice>
        <InlineNotice tone="danger">Couldn&apos;t reach the server.</InlineNotice>
        <InlineNotice tone="success">All caught up.</InlineNotice>
      </Row>
      <Row label="Status capsules">
        <StatusCapsule kind="offline" />
        <StatusCapsule kind="saved" savedAge="2 h" />
        <StatusCapsule kind="syncing" />
        <StatusCapsule kind="busy" retryIn={12} />
        <StatusCapsule kind="offline" inGroup />
      </Row>
      <Row label="Queued capsules">
        <Button variant="secondary" size="M" label="New chapters" onPress={() => setChapters(true)} data-testid="chapters-open" />
        <Button variant="secondary" size="M" label="App update" onPress={() => setUpdate(true)} data-testid="update-open" />
      </Row>
      <NewChaptersCapsule show={chapters} covers={covers} text="5 new chapters in 3 series" onView={() => setChapters(false)} onDismiss={() => setChapters(false)} data-testid="chapters-capsule" />
      <AppUpdateCapsule show={update} onReload={() => setUpdate(false)} data-testid="update-capsule" />
    </div>
  );
}
