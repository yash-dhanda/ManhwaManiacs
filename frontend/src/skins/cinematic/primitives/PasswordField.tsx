"use client";
import { useId, useState } from "react";
import { CoreInput, type CoreInputProps } from "./field-core";

/** §7.3: a quiet Show/Hide text button at the right end, directly after the field in tab order, aria-pressed with the fixed label. */
export function PasswordField(props: CoreInputProps) {
  const [shown, setShown] = useState(false);
  const id = useId();
  return (
    <CoreInput {...props} inputId={id} type={shown ? "text" : "password"} autoComplete={props.autoComplete ?? "current-password"}
      trailing={
        <button type="button" aria-pressed={shown} aria-label="Show password" aria-controls={id} onClick={() => setShown((s) => !s)}
          className="type-label min-h-(--mm-hit-min) px-1 text-ink-60 hover:text-ink-100 hover:underline hover:underline-offset-4">
          {shown ? "Hide" : "Show"}
        </button>
      } />
  );
}
