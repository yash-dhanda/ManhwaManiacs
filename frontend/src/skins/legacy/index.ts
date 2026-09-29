import { createElement } from "react";
import { notFound } from "next/navigation";
import { AppShell } from "@/components/layout/app-shell";
import type { ScreenId } from "../contract.generated";
import type { Screen, ScreenProps, Skin } from "../types";
import { legacyFontClassName } from "./fonts";
import AdminStatus from "./pages/admin-status";
import Bookmarks from "./pages/bookmarks";
import Collection from "./pages/collection";
import Collections from "./pages/collections";
import Dialogue from "./pages/dialogue";
import Discover from "./pages/discover";
import Downloads from "./pages/downloads";
import Feature from "./pages/feature";
import History from "./pages/history";
import IndexHub from "./pages/index-hub";
import Library from "./pages/library";
import LibraryBrowse from "./pages/library-browse";
import LibraryFollowed from "./pages/library-followed";
import Login from "./pages/login";
import Novel from "./pages/novel";
import Numbers from "./pages/numbers";
import Picks from "./pages/picks";
import Profiles from "./pages/profiles";
import ProfilesManage from "./pages/profiles-manage";
import ReadAll from "./pages/read-all";
import Reader from "./pages/reader";
import ReaderLanding from "./pages/reader-landing";
import Register from "./pages/register";
import Settings from "./pages/settings";
import Source from "./pages/source";
import Sources from "./pages/sources";
import Updates from "./pages/updates";

/**
 * Today's UI as a skin: each ScreenId that exists today maps to its moved page
 * body. Screens that are new in the redesign are absent. Deleted at the flip.
 *
 * The page bodies type their own `params` narrowly (`{ seriesKey: string }`),
 * which the wide route props always satisfy at runtime; `page` erases that.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const page = (component: (props: any) => unknown) => component as Screen;

const library: Screen = (props: ScreenProps) =>
  createElement(props.variant === "browse" ? LibraryBrowse : Library);

// `/settings/anything` stays a 404 for legacy users, as it was before the
// `[section]` route existed. The one exception, `/settings/diagnostics` (the debug
// row), is answered by the route file and let through by `src/proxy.ts`.
const settings: Screen = async ({ params }: ScreenProps) => {
  if ((await params).section !== undefined) notFound();
  return createElement(Settings);
};

const screens: Partial<Record<ScreenId, Screen>> = {
  login: page(Login),
  register: page(Register),
  profiles: page(Profiles),
  profilesManage: page(ProfilesManage),
  library,
  featureByFollow: page(LibraryFollowed),
  collections: page(Collections),
  collection: page(Collection),
  history: page(History),
  bookmarks: page(Bookmarks),
  picks: page(Picks),
  numbers: page(Numbers),
  discover: page(Discover),
  sources: page(Sources),
  source: page(Source),
  feature: page(Feature),
  readerLanding: page(ReaderLanding),
  reader: page(Reader),
  readAll: page(ReadAll),
  novel: page(Novel),
  updates: page(Updates),
  downloads: page(Downloads),
  dialogue: page(Dialogue),
  index: page(IndexHub),
  settings,
  status: page(AdminStatus),
};

export const legacy: Skin = { id: "legacy", fontClassName: legacyFontClassName, Shell: AppShell, screens };
