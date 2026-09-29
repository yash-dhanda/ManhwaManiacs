"use client";
import { useId, useState, type TextareaHTMLAttributes } from "react";
import { FieldFrame, INPUT_CLASS, type FieldShared } from "./field-core";

/** §7.3: faint 1 px rule.1 lines every line height, grows to 6 lines then scrolls. */
export function Textarea({ label, helper, error, success, loading, disabled, className, trailing, "data-gallery": gallery, ...ta }: FieldShared & Omit<TextareaHTMLAttributes<HTMLTextAreaElement>, "className" | "id">) {
  const id = useId();
  const [focused, setFocused] = useState(false);
  return (
    <FieldFrame id={id} label={label} helper={helper} error={error} success={success} loading={loading} disabled={disabled} focused={focused} className={className} trailing={trailing}>
      <textarea id={id} data-gallery={gallery} disabled={disabled} rows={ta.rows ?? 2} aria-invalid={error ? true : undefined} aria-describedby={error || helper ? `${id}-msg` : undefined}
        {...ta} onFocus={(e) => { setFocused(true); ta.onFocus?.(e); }} onBlur={(e) => { setFocused(false); ta.onBlur?.(e); }}
        onInput={(e) => { const el = e.currentTarget; el.style.height = "auto"; el.style.height = `${Math.min(el.scrollHeight, 120)}px`; ta.onInput?.(e); }}
        className={`${INPUT_CLASS} resize-none overflow-y-auto`}
        style={{ caretColor: "var(--mm-color-spot)", lineHeight: "20px", maxHeight: 120, outline: "none", boxShadow: "none", backgroundImage: "repeating-linear-gradient(to bottom, transparent 0, transparent 19px, var(--mm-color-rule-1) 19px, var(--mm-color-rule-1) 20px)" }} />
    </FieldFrame>
  );
}
