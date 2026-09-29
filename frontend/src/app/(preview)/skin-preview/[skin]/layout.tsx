import type { Viewport } from "next";
import type { ReactNode } from "react";
import { notFound } from "next/navigation";
import { AppearanceBootScript } from "@/features/preferences/appearance-boot";
import { skins } from "@/skins";
import "../../../globals.css";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  interactiveWidget: "resizes-content",
  colorScheme: "dark",
  themeColor: "#000000",
};

/** Second root layout: a skin rendered from the URL, with no Providers and no Shell (cinematic §8.30.3). */
export default async function SkinPreviewLayout({
  children,
  params,
}: {
  children: ReactNode;
  params: Promise<{ skin: string }>;
}) {
  const { skin } = await params;
  if (skin !== "cinematic" && skin !== "glass") notFound();
  return (
    <html lang="en" data-skin={skin} className={skins[skin].fontClassName} suppressHydrationWarning>
      <head>
        <AppearanceBootScript />
      </head>
      <body>{children}</body>
    </html>
  );
}
