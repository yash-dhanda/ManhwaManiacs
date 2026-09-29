import type { ScreenId } from "../contract.generated";
import Pending from "../pending";
import { PendingShell } from "../pending-shell";
import FeatureByFollowScreen from "./screens/feature/FeatureByFollowScreen";
import FeatureScreen from "./screens/feature/FeatureScreen";
import SetupRedirect from "../setup-redirect";
import type { Screen, Skin } from "../types";

/**
 * Every ScreenId this skin has not built yet. Finishing a screen is two edits
 * in this file: map the id to the real screen below, and delete it from here.
 */
export const PENDING = new Set<ScreenId>([
  "login",
  "register",
  "profiles",
  "profileNew",
  "profileEdit",
  "profilesManage",
  "onboarding",
  "tonight",
  "library",
  "updates",
  "collections",
  "collection",
  "history",
  "bookmarks",
  "picks",
  "numbers",
  "annual",
  "recap",
  "circle",
  "circleMember",
  "discover",
  "sources",
  "source",
  "reader",
  "readAll",
  "novel",
  "downloads",
  "dialogue",
  "index",
  "settings",
  "status",
  "readerLanding",
]);

export const screens = {
  setup: SetupRedirect,
  login: Pending,
  register: Pending,
  profiles: Pending,
  profileNew: Pending,
  profileEdit: Pending,
  profilesManage: Pending,
  onboarding: Pending,
  tonight: Pending,
  library: Pending,
  updates: Pending,
  collections: Pending,
  collection: Pending,
  history: Pending,
  bookmarks: Pending,
  picks: Pending,
  numbers: Pending,
  annual: Pending,
  featureByFollow: FeatureByFollowScreen,
  feature: FeatureScreen,
  recap: Pending,
  circle: Pending,
  circleMember: Pending,
  discover: Pending,
  sources: Pending,
  source: Pending,
  reader: Pending,
  readAll: Pending,
  novel: Pending,
  downloads: Pending,
  dialogue: Pending,
  index: Pending,
  settings: Pending,
  status: Pending,
  readerLanding: Pending,
} satisfies Record<ScreenId, Screen>;

export const cinematic: Skin = { id: "cinematic", fontClassName: "", Shell: PendingShell, screens };
