"use client";

import { useContext, useEffect, useId, useRef, useState, type ChangeEvent, type KeyboardEvent } from "react";
import { GlassHostContext } from "../glass/GlassSurface";
import { Icon } from "./Icon";
import { IconButton } from "./IconButton";
import { Spinner } from "./Progress";
import { shake } from "./shake";

export type FieldForce = "hover" | "focus";
export interface TextFieldProps {
  type?: "text" | "password" | "url" | "number";
  label?: string;
  helper?: string;
  /** the validation message; sets aria-invalid + aria-describedby and the errorRing */
  error?: string | null;
  /** increment on submit: the field shakes at 6 px and the first invalid field takes focus */
  shakeKey?: number;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  /** number / go-to: Enter jumps */
  onGo?: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  loading?: boolean;
  /** url: a spinner while validating, a success check when reachable */
  status?: "validating" | "reachable";
  name?: string;
  autoComplete?: string;
  /** sits on a solid sheet: fill2 instead of fill3 */
  sheet?: boolean;
  forceState?: FieldForce;
  "data-testid"?: string;
}

/** Form fields are content-layer wells, never glass: fill3 on black, fill2 on a sheet, wellOnGlass inside T4/T5 glass (read from the host context). */
export function TextField({ type = "text", label, helper, error, shakeKey, value, defaultValue, onChange, onGo, placeholder, disabled, loading, status, name, autoComplete, sheet, forceState, "data-testid": tid }: TextFieldProps) {
  const id = useId();
  const onGlass = useContext(GlassHostContext);
  const input = useRef<HTMLInputElement>(null);
  const well = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);
  const caret = useRef<[number | null, number | null]>([null, null]);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) { first.current = false; return; }
    if (error && shakeKey) { shake(well.current, 6); input.current?.focus(); }
  }, [shakeKey]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => { const el = input.current; if (el && caret.current[0] !== null) { el.setSelectionRange(caret.current[0], caret.current[1]); } }, [shown]);
  const msgId = `${id}-m`;
  const describedBy = error || helper ? msgId : undefined;
  const isNumber = type === "number";
  const inputType = type === "password" ? (shown ? "text" : "password") : type === "number" ? "text" : type;
  const onKey = (e: KeyboardEvent<HTMLInputElement>) => {
    if (!isNumber) return;
    if (e.key === "Enter") onGo?.(e.currentTarget.value);
    if (e.key === "Escape") { e.currentTarget.value = ""; onChange?.(""); }
  };
  return (
    <div className="g-field" data-type={type} data-error={error ? "" : undefined} data-disabled={disabled ? "" : undefined} data-force={forceState} data-well={onGlass ? "glass" : sheet ? "sheet" : "black"}>
      {label ? <label className="g-field__label" htmlFor={id}>{label}</label> : null}
      <div ref={well} className="g-field__well">
        {type === "url" ? <span className="g-field__lead"><Icon name="globe" size={20} /></span> : null}
        <input
          ref={input} id={id} name={name} type={inputType} value={value} defaultValue={defaultValue} placeholder={placeholder} disabled={disabled}
          autoComplete={autoComplete ?? (type === "password" ? "current-password" : "off")}
          autoCapitalize={type === "url" || name === "username" ? "none" : undefined} spellCheck={false}
          inputMode={type === "url" ? "url" : isNumber ? "decimal" : undefined}
          aria-invalid={error ? true : undefined} aria-describedby={describedBy} data-testid={tid}
          onChange={(e: ChangeEvent<HTMLInputElement>) => onChange?.(e.target.value)} onKeyDown={onKey}
        />
        {loading ? <span className="g-field__trail"><Spinner size={16} /></span> : null}
        {type === "url" && status === "validating" ? <span className="g-field__trail"><Spinner size={16} /></span> : null}
        {type === "url" && status === "reachable" ? <span className="g-field__trail" style={{ color: "var(--mm-color-success)" }}><Icon name="check" size={16} weight="fill" /></span> : null}
        {type === "password" ? (
          <IconButton variant="plain" icon={shown ? "eye-slash" : "eye"} label="Show password" pressed={shown} tone="iris" disabled={disabled}
            onPress={() => { const el = input.current; caret.current = [el?.selectionStart ?? null, el?.selectionEnd ?? null]; setShown((s) => !s); el?.focus(); }} />
        ) : null}
      </div>
      {error ? <p id={msgId} className="g-field__msg" data-tone="error"><Icon name="warning-circle" size={16} color="var(--mm-color-danger)" /> {error}</p> : helper ? <p id={msgId} className="g-field__msg">{helper}</p> : null}
    </div>
  );
}
