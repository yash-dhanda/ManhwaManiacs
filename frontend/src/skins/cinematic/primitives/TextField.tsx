"use client";
import { CoreInput, type CoreInputProps } from "./field-core";

/** §7.3 editorial text field. autocomplete, inputMode and type pass through. */
export function TextField(props: CoreInputProps) {
  return <CoreInput {...props} />;
}
