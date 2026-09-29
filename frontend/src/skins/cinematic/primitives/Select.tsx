"use client";
import { Select as BaseSelect } from "@base-ui/react/select";
import { useState } from "react";
import { haptic } from "../haptics";
import { Glyph } from "./glyphs";
import { MENU_SURFACE } from "./Menu";
import { useDesktopFrame } from "./overlay-hooks";
import { Radios } from "./Radio";
import { Sheet } from "./Sheet";

export type SelectOption = { value: string; label: string; disabled?: boolean };

/** §7.3 select row: editorial underline field with caret-down 16. Desktop opens a menu-styled popup; the phone frame opens a Sheet of radio rows. */
export function Select({ value, onValueChange, options, label, placeholder = "Choose", disabled = false, className = "", ...rest }: {
  value: string; onValueChange: (v: string) => void; options: SelectOption[]; label: string; placeholder?: string; disabled?: boolean; className?: string; "data-gallery"?: string;
}) {
  const desktop = useDesktopFrame();
  const [open, setOpen] = useState(false);
  const current = options.find((o) => o.value === value)?.label;
  const field = `type-ui flex min-h-(--mm-hit-min) w-full items-center justify-between gap-3 border-b text-left ${disabled ? "border-rule-1 text-ink-30" : "border-ink-45 text-ink-100 hover:border-ink-100"}`;
  const face = (<><span className={current ? "" : "text-ink-45"}>{current ?? placeholder}</span><Glyph name="caret-down" size={16} /></>);
  return (
    <div className={className}>
      <p className="type-kicker text-ink-45">{label}</p>
      {desktop ? (
        <BaseSelect.Root value={value} onValueChange={(v) => { haptic("select"); onValueChange(String(v)); }} disabled={disabled}>
          <BaseSelect.Trigger aria-label={label} data-gallery={rest["data-gallery"]} className={field}>{face}</BaseSelect.Trigger>
          <BaseSelect.Portal>
            <BaseSelect.Positioner sideOffset={4} className="z-(--mm-z-dialog)">
              <BaseSelect.Popup data-stock="raised" className={MENU_SURFACE}>
                <BaseSelect.List>
                  {options.map((o) => (
                    <BaseSelect.Item key={o.value} value={o.value} label={o.label} disabled={o.disabled}
                      className="group relative flex min-h-10 cursor-pointer items-center gap-3 px-4 outline-none data-[highlighted]:bg-paper-4 data-[disabled]:text-ink-30">
                      <span aria-hidden className="absolute inset-y-0 left-0 w-0.5 bg-ink-100 opacity-0 group-data-[highlighted]:opacity-100" />
                      <span className="inline-flex size-5 items-center justify-center"><BaseSelect.ItemIndicator><Glyph name="check" size={20} /></BaseSelect.ItemIndicator></span>
                      <BaseSelect.ItemText className="type-ui">{o.label}</BaseSelect.ItemText>
                    </BaseSelect.Item>
                  ))}
                </BaseSelect.List>
              </BaseSelect.Popup>
            </BaseSelect.Positioner>
          </BaseSelect.Portal>
        </BaseSelect.Root>
      ) : (
        <>
          <button type="button" aria-haspopup="dialog" aria-disabled={disabled || undefined} data-gallery={rest["data-gallery"]} onClick={() => { if (!disabled) setOpen(true); }} className={field}>{face}</button>
          <Sheet open={open} onOpenChange={setOpen} title={label} kicker="CHOOSE ONE">
            <Radios label={label} value={value} onValueChange={(v) => { onValueChange(v); setOpen(false); }} options={options} />
          </Sheet>
        </>
      )}
    </div>
  );
}
