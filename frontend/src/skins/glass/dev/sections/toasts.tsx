"use client";

import { useState } from "react";
import { Button } from "../../primitives/Button";
import { showToast, undoLast, dismissToast } from "../../primitives/Toast";
import { Row } from "../Grounds";

/** web/27 D: info, success, warning, error, action, two-line, Undo (drains its rim) and queued toasts. */
export function ToastsSection() {
  const [undone, setUndone] = useState(0);
  return (
    <div>
      <Row label="Kinds">
        <Button variant="secondary" size="M" label="Info" onPress={() => showToast({ kind: "info", text: "Library synced" })} data-testid="toast-info" />
        <Button variant="secondary" size="M" label="Success" onPress={() => showToast({ kind: "success", text: "Added to your library" })} />
        <Button variant="secondary" size="M" label="Warning" onPress={() => showToast({ kind: "warning", text: "Sources are slow right now" })} />
        <Button variant="secondary" size="M" label="Error" onPress={() => showToast({ kind: "error", text: "Couldn't save that", action: { label: "Retry", onPress: () => {} } })} data-testid="toast-error" />
        <Button variant="secondary" size="M" label="Two lines" onPress={() => showToast({ kind: "info", text: "Chapter 143 downloaded", secondary: "Ready to read offline" })} />
        <Button variant="secondary" size="M" label="Wraps at large text" onPress={() => showToast({ kind: "info", text: "Your reading history has been moved to the new profile and merged with the old one" })} />
      </Row>
      <Row label="Undo (10 s, the rim drains) and the queue">
        <Button variant="secondary" size="M" label="Undo toast" onPress={() => showToast({ kind: "success", text: "Removed from history", undo: () => setUndone((n) => n + 1) })} data-testid="toast-undo-open" />
        <Button variant="secondary" size="M" label="Two toasts" onPress={() => { showToast({ text: "First toast" }); setTimeout(() => showToast({ text: "Second toast" }), 250); }} data-testid="toast-two" />
        <Button variant="secondary" size="M" label="Run undoLast()" onPress={() => undoLast()} />
        <Button variant="secondary" size="M" label="Dismiss all" onPress={() => dismissToast()} />
        <span className="gal-readout" data-testid="toast-undone">undone: {undone}</span>
      </Row>
    </div>
  );
}
