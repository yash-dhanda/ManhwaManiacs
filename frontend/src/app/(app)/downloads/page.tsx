import type { Metadata } from "next";
import { renderScreen, type RouteProps } from "@/skins/server";

export const metadata: Metadata = {
  title: "Downloads · ManhwaManiacs",
  description: "Chapters saved on this device, and what they cost in storage.",
};

export default function Page(props: RouteProps) {
  return renderScreen("downloads", props);
}
