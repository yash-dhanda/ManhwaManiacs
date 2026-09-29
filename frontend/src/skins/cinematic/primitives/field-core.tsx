"use client";
import { useId, useState, type InputHTMLAttributes, type ReactNode, type Ref } from "react";
import { cn } from "@/lib/cn";
import { useHold } from "./hooks";
import { LeaderDial } from "./Progress";
import { Glyph } from "./glyphs";

export type FieldShared = {
  label: string;
  helper?: string;
  error?: string;
  success?: boolean;
  /** Async validation running. */
  loading?: boolean;
  disabled?: boolean;
  className?: string;
  trailing?: ReactNode;
  "data-gallery"?: string;
};

/** The editorial field frame (§7.3): kicker label, text line, 1 px rule.2 underline that draws to 2 px spot on focus, helper or error line. */
export function FieldFrame({ id, label, helper, error, success, loading, disabled, focused, className = "", trailing, align = "left", children }: FieldShared & { id: string; focused: boolean; align?: "left" | "right"; children: ReactNode }) {
  const ok = useHold(success, 1600);
  const msgId = `${id}-msg`;
  return (
    <div className={`group flex flex-col ${className}`}>
      <label htmlFor={id} className={`type-kicker mb-2 ${focused ? "text-ink-100" : "text-ink-45"}`}>{label}</label>
      <div className="relative flex min-h-12 items-end gap-2 pb-4" style={{ textAlign: align }}>
        {children}
        <span className="flex items-center gap-2 pb-0.5">
          {loading ? <LeaderDial size={16} immediate /> : null}
          {ok && !loading ? <span className="text-set"><Glyph name="check" size={16} /></span> : null}
          {trailing}
        </span>
        <span aria-hidden className={cn("absolute inset-x-0 bottom-0 transition-colors duration-(--mm-dur-beat)", disabled && "border-b border-dotted border-rule-2", !disabled && error && "h-0.5 bg-proof", !disabled && !error && "h-px bg-rule-2 group-hover:bg-ink-45")} />
        {!disabled && !error ? <span aria-hidden className="absolute inset-x-0 bottom-0 h-0.5 origin-left bg-spot transition-transform duration-(--mm-dur-line) ease-settle" style={{ transform: `scaleX(${focused ? 1 : 0})` }} /> : null}
      </div>
      {error || helper ? (
        <p id={msgId} role={error ? "alert" : undefined} className={`type-caption mt-2 flex gap-1 ${error ? "text-proof" : "text-ink-45"}`}>
          {error ? <span aria-hidden>‸</span> : null}{error ?? helper}
        </p>
      ) : null}
    </div>
  );
}

export const INPUT_CLASS = "type-ui w-full min-w-0 text-ink-100 outline-none placeholder:text-ink-45 disabled:text-ink-30";

export type CoreInputProps = FieldShared & Omit<InputHTMLAttributes<HTMLInputElement>, "className" | "id"> & { ref?: Ref<HTMLInputElement>; inputClass?: string; align?: "left" | "right"; suffix?: string; inputId?: string };

/** One input inside a FieldFrame; shared by TextField, PasswordField and NumberField. */
export function CoreInput({ label, helper, error, success, loading, disabled, className, trailing, inputClass = "", align = "left", suffix, ref, inputId, "data-gallery": gallery, ...input }: CoreInputProps) {
  const auto = useId();
  const id = inputId ?? auto;
  const [focused, setFocused] = useState(false);
  return (
    <FieldFrame id={id} label={label} helper={helper} error={error} success={success} loading={loading} disabled={disabled} focused={focused} className={className} trailing={trailing} align={align}>
      <input ref={ref} id={id} data-gallery={gallery} disabled={disabled} aria-invalid={error ? true : undefined} aria-describedby={error || helper ? `${id}-msg` : undefined}
        {...input} onFocus={(e) => { setFocused(true); input.onFocus?.(e); }} onBlur={(e) => { setFocused(false); input.onBlur?.(e); }}
        className={`${INPUT_CLASS} ${inputClass}`} style={{ caretColor: "var(--mm-color-spot)", textAlign: align, outline: "none", boxShadow: "none" }} />
      {suffix ? <span className="type-ui pb-0.5 text-ink-45">{suffix}</span> : null}
    </FieldFrame>
  );
}
