import { renderScreen, type RouteProps } from "@/skins/server";

export default function Page(props: RouteProps) {
  return renderScreen("bookmarks", props);
}
