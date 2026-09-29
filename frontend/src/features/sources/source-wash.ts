import { fnv1a32 } from "./standins/fnv1a32"; // TODO(web/03): import from ./cover-transition-name
export const sourceWashHue = (sourceId: string): number => fnv1a32(sourceId) % 360;
