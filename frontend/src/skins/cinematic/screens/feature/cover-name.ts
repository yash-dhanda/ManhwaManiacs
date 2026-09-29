/**
 * The shared view-transition name of a series' cover: a poster, cutting, plate
 * or cover anywhere in the app that shows this series wears the same name, so
 * the browser match-cuts between them (§15.2 `mm-match-cut`).
 */
export function coverTransitionName(sourceId: string, seriesKey: string): string {
  let h = 5381;
  for (const ch of `${sourceId}\n${seriesKey}`) h = ((h * 33) ^ ch.codePointAt(0)!) >>> 0;
  return `mm-cover-${sourceId.replace(/[^a-zA-Z0-9_-]/g, "_")}-${h.toString(36)}`;
}
