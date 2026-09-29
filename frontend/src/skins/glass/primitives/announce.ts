/** The one visually hidden assertive region (role="alert") every error state writes to. Text stays `ms` (6 s by default). */
let region: HTMLElement | null = null;
let clear: ReturnType<typeof setTimeout> | undefined;

export function announce(text: string, ms = 6000): void {
  if (typeof document === "undefined") return;
  if (!region || !region.isConnected) {
    region = document.createElement("div");
    region.setAttribute("role", "alert");
    region.setAttribute("aria-live", "assertive");
    region.setAttribute("data-glass-announcer", "");
    Object.assign(region.style, { position: "absolute", width: "1px", height: "1px", overflow: "hidden", clip: "rect(0 0 0 0)", whiteSpace: "nowrap" });
    document.body.appendChild(region);
  }
  region.textContent = text;
  clearTimeout(clear);
  clear = setTimeout(() => { if (region) region.textContent = ""; }, ms);
}
