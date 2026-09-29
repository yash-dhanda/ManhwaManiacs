import type { Viewport } from "next";
import type { ReactNode } from "react";
import { notFound } from "next/navigation";
import { AppearanceBootScript } from "@/features/preferences/appearance-boot";
import "../../globals.css";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  interactiveWidget: "resizes-content",
  colorScheme: "dark",
  themeColor: "#000000",
};

/** Third root layout: developer-only pages (never in production), always in Glass. */
export default function DevLayout({ children }: { children: ReactNode }) {
  if (process.env.NODE_ENV === "production") notFound();
  return (
    <html lang="en" data-skin="glass" suppressHydrationWarning>
      <head>
        <AppearanceBootScript />
      </head>
      <body>{children}</body>
    </html>
  );
}
