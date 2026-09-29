"use client";

import { useContext, useEffect, useId, useLayoutEffect, useRef, type KeyboardEvent } from "react";
import { GlassHostContext } from "../glass/GlassSurface";
import { Icon } from "./Icon";
import { Spinner } from "./Progress";
import { shake } from "./shake";
import type { FieldForce } from "./TextField";

const LINE = 22, PAD = 12;
export interface TextAreaProps {
  label?: string;
  helper?: string;
  error?: string | null;
  shakeKey?: number;
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
  /** the AI prompt: Enter submits, Shift+Enter inserts a newline */
  submitOnEnter?: boolean;
  onSubmit?: (value: string) => void;
  maxLength?: number;
  placeholder?: string;
  disabled?: boolean;
  loading?: boolean;
  sheet?: boolean;
  forceState?: FieldForce;
  "data-testid"?: string;
}

/** Min 3 rows (about 96 px), grows with its content up to 8 rows, then scrolls; the counter shows from 80 % of the limit and turns `warning` at 95 %. */
export function TextArea({ label, helper, error, shakeKey, value, defaultValue, onChange, submitOnEnter, onSubmit, maxLength, placeholder, disabled, loading, sheet, forceState, "data-testid": tid }: TextAreaProps) {
  const id = useId();
  const onGlass = useContext(GlassHostContext);
  const ta = useRef<HTMLTextAreaElement>(null);
  const well = useRef<HTMLDivElement>(null);
  const count = useRef<HTMLSpanElement>(null);
  const grow = () => {
    const el = ta.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(8 * LINE + 2 * PAD, Math.max(3 * LINE + 2 * PAD, el.scrollHeight))}px`;
    el.style.overflowY = el.scrollHeight > 8 * LINE + 2 * PAD ? "auto" : "hidden";
    if (count.current && maxLength) {
      const n = el.value.length, f = n / maxLength;
      count.current.hidden = f < 0.8;
      count.current.textContent = `${n}/${maxLength}`;
      if (f >= 0.95) count.current.dataset.warn = ""; else delete count.current.dataset.warn;
    }
  };
  useLayoutEffect(grow, [value]);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) { first.current = false; return; }
    if (error && shakeKey) { shake(well.current, 6); ta.current?.focus(); }
  }, [shakeKey]); // eslint-disable-line react-hooks/exhaustive-deps
  const msgId = `${id}-m`;
  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (submitOnEnter && e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) { e.preventDefault(); onSubmit?.(e.currentTarget.value); }
  };
  return (
    <div className="g-field" data-type="textarea" data-error={error ? "" : undefined} data-disabled={disabled ? "" : undefined} data-force={forceState} data-well={onGlass ? "glass" : sheet ? "sheet" : "black"}>
      {label ? <label className="g-field__label" htmlFor={id}>{label}</label> : null}
      <div ref={well} className="g-field__well" data-multiline="">
        <textarea ref={ta} id={id} rows={3} value={value} defaultValue={defaultValue} placeholder={placeholder} disabled={disabled} maxLength={maxLength}
          aria-invalid={error ? true : undefined} aria-describedby={error || helper ? msgId : undefined} data-testid={tid}
          onChange={(e) => { onChange?.(e.target.value); grow(); }} onKeyDown={onKey} />
        {loading ? <span className="g-field__trail" data-corner=""><Spinner size={16} /></span> : null}
        {maxLength ? <span ref={count} className="g-field__count" hidden aria-hidden="true" /> : null}
      </div>
      {error ? <p id={msgId} className="g-field__msg" data-tone="error"><Icon name="warning-circle" size={16} color="var(--mm-color-danger)" /> {error}</p> : helper ? <p id={msgId} className="g-field__msg">{helper}</p> : null}
    </div>
  );
}
