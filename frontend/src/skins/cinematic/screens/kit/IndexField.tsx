"use client";

import { forwardRef, useState } from "react";
import { useTyped } from "./motion";
import { cx, kit as s } from "./Kit";

interface Props {
  value: string;
  onChange: (v: string) => void;
  onEnter?: () => void;
  placeholder: string;
  label: string;
  variant?: "index" | "compact";
  typedPlaceholder?: boolean;
  onEscape?: () => void;
}

/** §7.4 search field. `index` = Bodoni Italic, turns Roman as it becomes a query; `compact` = the plain filter field. */
export const IndexField = forwardRef<HTMLInputElement, Props>(function IndexField(
  { value, onChange, onEnter, onEscape, placeholder, label, variant = "index", typedPlaceholder = true },
  ref,
) {
  const [focused, setFocused] = useState(false);
  const showGhost = variant === "index" && typedPlaceholder && value === "" && !focused;
  const ghost = useTyped(placeholder, showGhost);
  return (
    <label className={s.field}>
      <span className={s.sr}>{label}</span>
      {showGhost ? (
        <span className={cx(s.ghost, ghost.length < placeholder.length && s.caret)} aria-hidden>
          {ghost}
        </span>
      ) : null}
      <input
        ref={ref}
        type="search"
        enterKeyHint="search"
        autoComplete="off"
        spellCheck={false}
        aria-label={label}
        placeholder={placeholder}
        value={value}
        className={cx(s.fieldInput, value !== "" && s.typed, variant === "compact" && s.compact)}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter") onEnter?.();
          if (e.key === "Escape") {
            e.stopPropagation();
            if (value !== "") onChange("");
            else (e.target as HTMLInputElement).blur();
            onEscape?.();
          }
        }}
      />
      {value !== "" ? (
        <button type="button" className={cx(s.quiet, s.clear)} onClick={() => onChange("")}>
          Clear
        </button>
      ) : null}
    </label>
  );
});
