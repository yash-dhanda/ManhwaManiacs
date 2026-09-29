"use client";

import { useRef, useState } from "react";
import { Alert } from "../../primitives/Alert";
import { Button } from "../../primitives/Button";
import { confirmAlert } from "../../primitives/confirmAlert";
import { HoldToConfirm } from "../../primitives/HoldToConfirm";
import { Row } from "../Grounds";

type Which = null | "source" | "centre" | "stack" | "pending" | "error" | "box";

/** web/27 C: every alert form, launched from a source control or from the centre. */
export function AlertsSection() {
  const [which, setWhich] = useState<Which>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const src = useRef<HTMLButtonElement | null>(null);
  const [result, setResult] = useState("none");
  const open = (w: Which) => { setPending(false); setError(null); setWhich(w); };
  const close = () => { if (!pending) setWhich(null); };
  return (
    <div>
      <Row label="Launch">
        <Button ref={src} variant="secondary" size="M" label="From this button" onPress={() => open("source")} data-testid="alert-open-source" />
        <Button variant="secondary" size="M" label="From the centre" onPress={() => { src.current = null; open("centre"); }} data-testid="alert-open-centre" />
        <Button variant="secondary" size="M" label="Three buttons (stacked)" onPress={() => open("stack")} data-testid="alert-open-stack" />
        <Button variant="secondary" size="M" label="With a warning box" onPress={() => open("box")} data-testid="alert-open-box" />
        <Button variant="secondary" size="M" label="Pending" onPress={() => { open("pending"); }} data-testid="alert-open-pending" />
        <Button variant="secondary" size="M" label="Error" onPress={() => open("error")} data-testid="alert-open-error" />
      </Row>
      <Row label="Standalone hold to confirm: a click opens confirmAlert">
        <HoldToConfirm mode="standalone" label="Delete this collection" icon="trash" onConfirm={() => setResult("confirmed")} data-testid="alert-hold" />
        <Button variant="secondary" size="M" label="confirmAlert() from code" onPress={() => void confirmAlert({ title: "Remove from library?", body: "Its downloads stay on this device.", confirmLabel: "Remove", destructive: true, source: null }).then((ok) => setResult(ok ? "true" : "false"))} data-testid="alert-code" />
        <span className="gal-readout" data-testid="alert-result">result: {result}</span>
      </Row>

      <Alert open={which === "source"} onOpenChange={close} source={src} title="Delete this list?" body="This can't be undone." secondary="Downloaded chapters stay on this device."
        actions={[{ label: "Cancel", kind: "cancel", onPress: close }, { label: "Delete", kind: "destructive", onPress: close }]} />
      <Alert open={which === "centre"} onOpenChange={close} title="Sign out?" body="You'll need your password to come back."
        actions={[{ label: "Cancel", kind: "cancel", onPress: close }, { label: "Sign out", onPress: close }]} />
      <Alert open={which === "stack"} onOpenChange={close} title="Leave without saving?" body="Choose what happens to your changes."
        actions={[{ label: "Keep editing", kind: "cancel", onPress: close }, { label: "Save draft", onPress: close }, { label: "Discard", kind: "destructive", onPress: close }]} />
      <Alert open={which === "box"} onOpenChange={close} title="Show 18+ series?" body="Turn this on only if you are an adult."
        box={{ tone: "warning", text: "Mature series appear in search and on shelves until you turn this off." }}
        actions={[{ label: "Not now", kind: "cancel", onPress: close }, { label: "Show them", onPress: close }]} />
      <Alert open={which === "pending"} onOpenChange={close} pending={pending} title="Remove this source?" body="Its series leave your library."
        actions={[{ label: "Cancel", kind: "cancel", onPress: close }, { label: "Remove", kind: "destructive", onPress: () => { setPending(true); setTimeout(() => { setPending(false); setWhich(null); }, 2400); } }]} />
      <Alert open={which === "error"} onOpenChange={close} error={error} title="Delete account?" body="This removes your library and history."
        actions={[{ label: "Cancel", kind: "cancel", onPress: close }, { label: "Delete", kind: "destructive", onPress: () => setError("Couldn't delete. Try again.") }]} />
    </div>
  );
}
