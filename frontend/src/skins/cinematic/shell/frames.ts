/** The six frames of §8.0.1 (Desktop and Phone are the two CSS layouts of "app"; they are never chosen in JS). */
export type Frame = "bare" | "takeover" | "reader" | "page" | "app";

const seg = (p: string) => p.split("?")[0].split("/").filter(Boolean);

/** Pure: which frame a pathname lives in. */
export function frameFor(pathname: string): Frame {
  const s = seg(pathname);
  const [a, b, c] = s;
  if (a === "login" || a === "register") return "bare";
  if (a === "profiles" && s.length === 1) return "takeover";
  if (a === "welcome" || a === "recap") return "takeover";
  if (a === "library" && b === "statistics" && c === "annual") return "takeover";
  if (a === "read-all") return "reader";
  if (a === "reader" && s.length >= 4) return "reader";
  if (a === "novels") return "page";
  return "app";
}

/** Frames that render no app chrome. */
export const isChromeless = (f: Frame) => f !== "app";
