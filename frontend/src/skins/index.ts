// Server-only by convention: client components never import `@/skins` or
// `@/skins/server`; they import `@/skins/types` or their own skin's modules.
// This registry pulls in every skin, the whole legacy UI tree included.
import { cinematic } from "./cinematic";
import { glass } from "./glass";
import { legacy } from "./legacy";
import type { Skin, SkinId } from "./types";

export const skins = { cinematic, glass, legacy } satisfies Record<SkinId, Skin>;
