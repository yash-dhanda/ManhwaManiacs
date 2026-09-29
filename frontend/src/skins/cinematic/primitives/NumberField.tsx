"use client";
import { CoreInput, type CoreInputProps } from "./field-core";

/** §7.3: type.folio.lg, right-aligned, unit suffix in ink.45 ("min", "GB"). */
export function NumberField({ unit, ...props }: CoreInputProps & { unit?: string }) {
  return <CoreInput {...props} type="number" inputMode="numeric" align="right" inputClass="type-folio-lg" suffix={unit} />;
}
