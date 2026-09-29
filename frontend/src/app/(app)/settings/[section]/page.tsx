import { DebugEditionPage } from "@/features/skin/DebugEditionPage";
import { renderScreen, type RouteProps } from "@/skins/server";

export default async function Page(props: RouteProps) {
  // The pre-flip edition override row, for every skin (cinematic §8.0.7).
  if ((await props.params).section === "diagnostics") return <DebugEditionPage />;
  return renderScreen("settings", props);
}
