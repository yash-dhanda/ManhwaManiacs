/**
 * Spoken folios (cinematic §7.29): the visual text is aria-hidden, the spoken form goes on aria-label.
 * Rules are ordered; the first match wins.
 */
const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;
const unit = (u: string) => ({ H: "hour", D: "day", MIN: "minute", M: "month", W: "week", S: "second" })[u] ?? u.toLowerCase();
const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

const RULES: [RegExp, (m: RegExpExecArray) => string][] = [
  [/^18\+?$/i, () => "Mature, 18 plus"],
  [/^CH\s+(\d+)\s*·\s*(\d+)%$/i, (m) => `Chapter ${m[1]}, ${m[2]} percent read`],
  [/^CH\s+(\d+)\s+OF\s+(\d+)$/i, (m) => `Chapter ${m[1]} of ${m[2]}`],
  [/^NEXT\s*·\s*CH\s+(\d+)$/i, (m) => `Next, chapter ${m[1]}`],
  [/^(\d+)\s+NEW$/i, (m) => `${plural(Number(m[1]), "new chapter")}`],
  [/^PAUSED\s+(\d+)\s+([A-Z]+)$/i, (m) => `Paused ${plural(Number(m[1]), unit(m[2].toUpperCase()))}`],
  [/^(\d+)\s+([HDW]|MIN|S)$/i, (m) => `${plural(Number(m[1]), unit(m[2].toUpperCase()))}${/^MIN$/i.test(m[2]) ? "" : " ago"}`],
  [/^CH\s+(\d+)$/i, (m) => `Chapter ${m[1]}`],
  [/^p\.\s*(\d+)$/i, (m) => `page ${m[1]}`],
  [/^(.+?)\s*[⁽(]\s*(\d+)\s*[⁾)]$/, (m) => `${cap(m[1].toLowerCase())}, ${m[2]}`],
];

/** Spoken form of a visual folio. A label plus a raised count is `READING¹²`; pass it as `label` and `count`. */
export function folioLabel(visual: string, count?: number): string {
  const text = visual.trim();
  if (count !== undefined) return `${cap(text.toLowerCase())}, ${count}`;
  const sup = /^(.+?)([⁰¹²³⁴⁵⁶⁷⁸⁹]+)$/.exec(text);
  if (sup) {
    const digits = sup[2].split("").map((c) => "⁰¹²³⁴⁵⁶⁷⁸⁹".indexOf(c)).join("");
    return `${cap(sup[1].trim().toLowerCase())}, ${digits}`;
  }
  for (const [re, f] of RULES) { const m = re.exec(text); if (m) return f(m); }
  return text;
}

/** Compose a full sentence of folios, e.g. the split button: "Continue, chapter 143, page 12". */
export function folioLabelJoin(label: string, folio: string): string {
  const spoken = folio.split("·").map((p) => p.trim()).filter(Boolean).map((p) => {
    const s = folioLabel(p).replace(/^Chapter/, "chapter");
    return s;
  });
  return [label, ...spoken].join(", ");
}
