"use client";

import Link from "next/link";
import { useEffect, useId, useRef, useState, type ReactNode } from "react";
import { Glyph } from "./Glyph";
import s from "./feature.module.css";

export type MenuEntry =
  | { sep: true }
  | {
      label: string;
      onSelect?: () => void;
      href?: string;
      external?: boolean;
      disabled?: boolean;
      danger?: boolean;
      /** Radio items: shows the check mark. */
      checked?: boolean;
      radio?: boolean;
      title?: string;
    };

/** §7.22 popover menu: arrows, Home/End, type-ahead, Esc; opens on click or externally. */
export function Menu({
  entries,
  label,
  trigger,
  open: openProp,
  onOpenChange,
}: {
  entries: MenuEntry[];
  label: string;
  trigger?: ReactNode;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
}) {
  const [inner, setInner] = useState(false);
  const open = openProp ?? inner;
  const setOpen = (v: boolean) => {
    setInner(v);
    onOpenChange?.(v);
  };
  const id = useId();
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const first = box.current?.querySelector<HTMLElement>('[role^="menuitem"]:not([aria-disabled="true"])');
    first?.focus();
    const away = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) {
        setInner(false);
        onOpenChange?.(false);
      }
    };
    document.addEventListener("mousedown", away);
    return () => document.removeEventListener("mousedown", away);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const items = () =>
    [...(box.current?.querySelectorAll<HTMLElement>('[role^="menuitem"]:not([aria-disabled="true"])') ?? [])];

  const onKey = (e: React.KeyboardEvent) => {
    const list = items();
    const i = list.indexOf(document.activeElement as HTMLElement);
    if (e.key === "Escape") {
      e.stopPropagation();
      setOpen(false);
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      list[(i + 1) % list.length]?.focus();
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      list[(i - 1 + list.length) % list.length]?.focus();
    } else if (e.key === "Home") {
      e.preventDefault();
      list[0]?.focus();
    } else if (e.key === "End") {
      e.preventDefault();
      list[list.length - 1]?.focus();
    } else if (e.key.length === 1) {
      const from = list.slice(i + 1).concat(list.slice(0, i + 1));
      from.find((el) => el.textContent?.trim().toLowerCase().startsWith(e.key.toLowerCase()))?.focus();
    }
  };

  return (
    <div className={s.menuAnchor} ref={box}>
      {trigger === undefined ? (
        <button
          type="button"
          className={s.icon}
          aria-label={label}
          title={label}
          aria-haspopup="menu"
          aria-expanded={open}
          aria-controls={open ? id : undefined}
          onClick={() => setOpen(!open)}
        >
          <Glyph name="dots" />
        </button>
      ) : (
        trigger
      )}
      {open ? (
        <div className={s.menu} id={id} role="menu" aria-label={label} onKeyDown={onKey}>
          {entries.map((e, k) =>
            "sep" in e ? (
              <hr key={k} />
            ) : e.href ? (
              e.external ? (
                <a key={k} role="menuitem" href={e.href} target="_blank" rel="noreferrer noopener" onClick={() => setOpen(false)}>
                  {e.label}
                </a>
              ) : (
                <Link key={k} role="menuitem" href={e.href} onClick={() => setOpen(false)}>
                  {e.label}
                </Link>
              )
            ) : (
              <button
                key={k}
                type="button"
                role={e.radio ? "menuitemradio" : "menuitem"}
                aria-checked={e.radio ? Boolean(e.checked) : undefined}
                aria-disabled={e.disabled || undefined}
                title={e.title}
                className={e.danger ? s.danger : undefined}
                onClick={() => {
                  if (e.disabled) return;
                  setOpen(false);
                  e.onSelect?.();
                }}
              >
                {e.radio ? <span aria-hidden="true" style={{ width: 16 }}>{e.checked ? "●" : ""}</span> : null}
                {e.label}
              </button>
            ),
          )}
        </div>
      ) : null}
    </div>
  );
}
