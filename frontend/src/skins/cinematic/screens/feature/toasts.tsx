"use client";

import { useCallback, useRef, useState } from "react";
import s from "./feature.module.css";

// TODO(web/07): stand-in for the Cinematic toast host; replace with it.
export interface Toast {
  id: number;
  text: string;
  action?: { label: string; run: () => void };
}

export function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const next = useRef(1);
  const dismiss = useCallback((id: number) => setToasts((t) => t.filter((x) => x.id !== id)), []);
  const push = useCallback(
    (text: string, action?: Toast["action"], holdMs = action ? 8000 : 3600) => {
      const id = next.current++;
      setToasts((t) => [...t.slice(-2), { id, text, action }]);
      setTimeout(() => dismiss(id), holdMs);
    },
    [dismiss],
  );
  return { toasts, push, dismiss };
}

export function ToastStack({ toasts, dismiss }: { toasts: Toast[]; dismiss: (id: number) => void }) {
  return (
    <div className={s.toasts} role="status" aria-live="polite">
      {toasts.map((t) => (
        <div key={t.id} className={s.toast}>
          <span>{t.text}</span>
          {t.action ? (
            <button
              type="button"
              className={s.quiet}
              onClick={() => {
                t.action!.run();
                dismiss(t.id);
              }}
            >
              {t.action.label}
            </button>
          ) : null}
        </div>
      ))}
    </div>
  );
}
